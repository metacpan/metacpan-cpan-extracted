package IOC::Slinky::Container;
use strict;
use warnings;
use IOC::Slinky::Container::Item::Ref;
use IOC::Slinky::Container::Item::Native;
use IOC::Slinky::Container::Item::Constructed;
use Carp ();

our $VERSION = '0.1001';

sub new {
    my ($class, %args) = @_;
    my $self = bless { }, $class;
    $self->{typeof} = { };
    if (exists $args{config}) {
        $self->configure( delete $args{config} );
    }
    $self;
}

sub typeof { 
    $_[0]->{typeof};
}

sub configure {
    my ($self, $conf) = @_;
    (ref($conf) eq 'HASH')
        or Carp::croak("Expected 'container' key as hash reference");
    (exists $conf->{'container'})
        or Carp::croak("Expected 'container' key");
    my $container = delete $conf->{'container'};
    foreach my $k (keys %$container) {
        # skip existing keys 
        next if (exists $self->{typeof}->{$k});
        my $v = delete $container->{$k};
        $self->wire($container, $v, $k);
    }
}

sub wire {
    my ($self, $container, $v, $k) = @_;
    my $oinst;
    my @k_aliases = ();
    if (defined $k) {
        push @k_aliases, $k
    }
    if (ref($v)) {
        if (ref($v) eq 'HASH') {
            if (exists $v->{'_ref'}) {
                # reference to existing types
                my $lookup = $v->{'_ref'};
                # look-ahead: if the ref points to a lookup_id NOT YET in lookup table BUT still in the config
                if ((not exists $self->{typeof}->{$lookup}) and (exists $container->{$lookup})) {
                    my $vv = delete $container->{$lookup};
                    $self->wire($container, $vv, $lookup);
                }
                $oinst = tie $_[2], 'IOC::Slinky::Container::Item::Ref', $self, $v->{'_ref'};
            }
            elsif (exists $v->{'_class'}) {
                # object!
                my $ns = delete $v->{'_class'};
                my $new = delete $v->{'_constructor'} || 'new';
                my $ctor = delete $v->{'_constructor_args'} || [ ];
                my $ctor_passthru = delete $v->{'_constructor_passthru'} || 0;

                my $singleton = 1;
                if (exists $v->{'_singleton'}) {
                    $singleton = delete $v->{'_singleton'};
                }
                $self->wire($container, $ctor);

                my $alias = delete $v->{'_lookup_id'};
                if (defined $alias) {
                    push @k_aliases, $alias;
                }
                $oinst = tie $_[2], 'IOC::Slinky::Container::Item::Constructed', $self, $ns, $new, $ctor, $ctor_passthru, $v, $singleton;
            }
            else {
                # plain hashref ... traverse first
                foreach my $hk (keys %$v) {
                    if ($hk eq '_lookup_id') {
                        push @k_aliases, delete($v->{$hk});
                        next;
                    }
                    $self->wire($container, $v->{$hk});
                }
                $oinst = tie $v, 'IOC::Slinky::Container::Item::Native', $v;
            }
        }
        elsif (ref($v) eq 'ARRAY') {
            # arrayref are to be traversed for refs
            my $count = scalar(@$v)-1;
            for(0..$count) {
                $self->wire($container, $v->[$_]);
            }
            $oinst = tie $v, 'IOC::Slinky::Container::Item::Native', $v;
        }
        else {
            # other ref types
            $oinst = tie $v, 'IOC::Slinky::Container::Item::Native', $v;
        }
    }
    else {
        # literal
        $oinst = tie $v, 'IOC::Slinky::Container::Item::Native', $v;
    }

    if (scalar @k_aliases) {
        foreach my $ok (@k_aliases) {
            $self->typeof->{$ok} = $oinst;
        }
    }
    return $v;
}



sub lookup {
    my ($self, $key) = @_;
    return if (not defined $key);
    return if (not exists $self->typeof->{$key});
    return $self->typeof->{$key}->FETCH;
}


1;

__END__

=head1 NAME

IOC::Slinky::Container - an alternative dependency-injection container

=head1 SYNOPSIS

    # in myapp.yml
    ---
    container:
        db_dsn: "DBI:mysql:database=myapp"
        db_user: "myapp"
        db_pass: "myapp"
        logger:
            _class: FileLogger
            _constructor_args:
                filename: "/var/log/myapp/debug.log"
        myapp:
            _class: "MyApp"
            _constructor_args:
                dbh:
                    _class: "DBI"
                    _constructor: "connect"
                    _constructor_args:
                        - { _ref => "db_dsn" }
                        - { _ref => "db_user" }
                        - { _ref => "db_pass" }
                        - { RaiseError => 1 }
                logger:
                    _ref: logger

    # in myapp.pl
    # ...
    use IOC::Slinky::Container;
    use YAML qw/LoadFile/;

    my $c = IOC::Slinky::Container->new( config => LoadFile('myapp.yml') );
    my $app = $c->lookup('myapp');
    $app->run;


=head1 DESCRIPTION

This module aims to be a (1) transparent and (2) simple dependency-injection (DI) 
container; and usually preconfigured from a configuration file.

A DI-container is a special object used to load and configure other 
components/objects. Each object can then be globally resolved
using a unique lookup id. 

For more information about the benefits of the technique, see 
L<Dependency Injection|http://en.wikipedia.org/wiki/Dependency_Injection>.

=head1 METHODS

=over

=item CLASS->new( config => $conf )

Returns an container instance based on the configuration specified
by the hashref C<$conf>. See L</CONFIGURATION> for details.

=item $container->lookup($key)

Returns the C<$obj> if C<$key> lookup id is found in the container,
otherwise it returns undef.

=back

=head1 CONFIGURATION

=head2 Rules

The configuration should be a plain hash reference.

A single top-level key C<container> should be a hash reference;
where its keys will act as global namespace for all objects to be resolved.

    # an empty container
    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
            }
        }
    );

A container value can be one of the following:

=over

=item Native

These are native Perl data structures.

    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
                null        => undef,
                greeting    => "Hello World",
                pi          => 3.1416,
                plain_href  => { a => 1 },
                plain_aref  => [ 1, 2, 3 ],
            }
        }
    );

=item Constructed Object

These are objects/values returned via a class method call, 
typically used for object construction. A constructed 
object is specified by a hashref with special
meta fields:

C<_class> = when present, the container then treats 
this hashref as a constructed object spec. Otherwise 
this hash reference will be treated as a native value.

C<_constructor> = optional, overrides the method name to call,
defaults to "new"

C<_constructor_args> = optional, can be a scalar, hashref or an arrayref.
Hashrefs and arrayrefs are dereferenced as hashes and lists respectively. 
Scalar values are passed as-is. Nesting is allowed.

C<_constructor_passthru> = optional, boolean, default to 0 (false)
when this is TRUE, pass the _constructor_args as is without doing any
automatic dereference of hashrefs and arrayrefs.

C<_singleton> = optional, defaults to 1, upon lookup, the 
object is instantiated once and only once in the lifetime
of the container.

C<_lookup_id> = optional, alias of this object.

The rest of the hashref keys will also be treated as method calls, 
useful for attribute/setters initialization immediately after
the constructor was called. (I<Setter Injection>)

    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
                # constructor injection
                dbh => {
                    _class              => "DBI",
                    _constructor        => "connect",
                    _constructor_args   => [
                        "DBD:SQLite:dbname=/tmp/my.db",
                        "user",
                        "pass",
                        { RaiseError => 1 },
                    ],
                },
                # setter injection
                y2k => {
                    _singleton          => 0,
                    _class              => "DateTime",
                    year                => 2000,
                    month               => 1,
                    day                 => 1,
                },
            }
        }
    );
    
    my $dbh = $c->lookup('dbh');

    # is roughly equivalent to (though this is a singleton):
    # my $dbh = DBI->connect(
    #   "DBI:SQlite:dbname=/tmp/my.db",
    #   "user",
    #   "pass",
    #   { RaiseError => 1 }
    # );

    my $y2k = $c->lookup('y2k');

    # is equivalent to:
    # my $y2k = DateTime->new;
    # $y2k->year( 2000 );
    # $y2k->month( 1 );
    # $y2k->day( 1 );

=item Reference

References are "pointers" to the globally accessible container values.
References are defined by a hashref with a special meta field C<_ref>,
the value of which will be used to lookup when requested.

    $c = IOC::Slinky::Container->new( 
        config => {
            container => {
                dsn     => "DBI:mysql:database=myapp",
                user    => "myapp",
                pass    => "myapp_password",
                dbh     => {
                    _class => "DBI",
                    _constructor => "connect",
                    _constructor_args => [
                        { _ref => "dsn" },
                        { _ref => "user" },
                        { _ref => "pass" },
                    ],
                }, 
            }
        }
    );

    my $dbh = $c->lookup('dbh');
    # is roughly equivalent to:
    # $dbh = DBI->connect( 
    #   $c->lookup('dsn'),
    #   $c->lookup('user'),
    #   $c->lookup('pass'),
    # );
    

=back

=head2 Recommended Practices

=over

L<IOC::Slinky::Container>'s configuration is simply a hash-reference 
with a specific structure. It can come from virtually anywhere.
Our recommended usage then is to externalize the configuration 
(e.g. in a file), and to use L<YAML> for conciseness and ease-of-editing.

    use IOC::Slinky::Container;
    use YAML qw/LoadFile/;
    my $c = IOC::Slinky::Container->new( config => LoadFile("/etc/myapp.yml") );
    # ...

As a best practice, L<IOC::Slinky::Container> should NOT be used as a
service locator (see L<Service Locator Pattern|http://en.wikipedia.org/wiki/Service_locator_pattern>).
The container should only be referenced at the integration/top-level
code. Most of your modules/classes should not even see or bother about 
the container in the first place. The goal is to have a modular, pluggable,
reusable set of classes.


=back

=head1 SEE ALSO

L<Bread::Broad> - a Moose-based DI framework

L<IOC> - the ancestor of L<Bread::Board>

L<Peco::Container> - another DI container

L<http://en.wikipedia.org/wiki/Dependency_Injection>

L<YAML> - for externalized configuration syntax

=head1 AUTHOR

Dexter Tad-y, <dtady@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Dexter Tad-y

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.


