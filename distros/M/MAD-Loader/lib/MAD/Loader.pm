package MAD::Loader;
$MAD::Loader::VERSION = '3.001003';
use Moo;
extends 'Exporter';

use Carp;
use Const::Fast;

const our $MODULE_NAME_REGEX => qr{^[_[:upper:]]\w*(::\w+)*$};

our @EXPORT_OK = qw{
  fqn
  load_module
  build_object
  load_and_new
};

has 'prefix' => (
    is  => 'ro',
    isa => sub {
        Carp::croak "Invalid prefix '$_[0]'"
          unless '' eq $_[0] || $_[0] =~ $MODULE_NAME_REGEX;
    },
    default => sub {
        return '';
    },
);

has 'builder' => (
    is      => 'ro',
    default => sub {
        return 'new';
    },
);

has 'set_inc' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'set_inc must be an ArrayRef or "undef"'
          if defined $_[0] && 'ARRAY' ne ref $_[0];
    },
    default => sub {
        return;
    },
);

has 'add_inc' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'add_inc must be an ArrayRef or "undef"'
          if defined $_[0] && ref $_[0] ne 'ARRAY';
    },
    default => sub {
        return;
    },
);

has 'inc' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'inc must be an ArrayRef'
          unless 'ARRAY' eq ref $_[0];
    },
    lazy    => 1,
    builder => 1,
);

has 'args' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'options must be an ArrayRef'
          unless 'ARRAY' eq ref $_[0];
    },
    default => sub {
        return [];
    },
);

has 'on_error' => (
    is  => 'ro',
    isa => sub {
        Carp::croak 'on_error must be an CodeRef'
          unless 'CODE' eq ref $_[0];
    },
    default => sub {
        return \&Carp::croak;
    },
);

sub load {
    my ( $self, @modules ) = @_;

    my %result;
    foreach my $module (@modules) {
        $result{$module} = load_module(
            module   => $module,
            prefix   => $self->prefix,
            on_error => $self->on_error,
            inc      => $self->inc,
        );
    }

    return \%result;
}

sub build {
    my ( $self, @modules ) = @_;

    my %result;
    foreach my $module (@modules) {
        $result{$module} = build_object(
            module  => $module,
            builder => $self->builder,
            args    => $self->args,
        );
    }

    return \%result;
}

sub load_and_build {
    my ( $self, @modules ) = @_;

    my $loaded = $self->load(@modules);
    my $built  = $self->build( @{$loaded}{@modules} );

    return $built;
}

sub fqn {
    my $module = shift || '';
    my $prefix = shift;

    $module = $prefix . q{::} . $module
      if $prefix;

    return $module =~ $MODULE_NAME_REGEX ? $module : '';
}

sub load_module {
    my (%args) = @_;

    local @INC = @{ $args{inc} };

    my $module = fqn( $args{module}, $args{prefix} );
    my $on_error = $args{on_error} || \&Carp::croak;
    my $error;
    {
        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        local $@ = '';
        eval "use $module;";
        $error = $@;
        ## use critic
    }

    if ($error) {
        $module = '';
        $on_error->($error);
    }

    return $module;
}

sub build_object {
    my (%args) = @_;

    my $module   = $args{module};
    my $builder  = $args{builder};
    my @args     = @{ $args{args} };
    my $on_error = $args{on_error} || \&Carp::croak;

    my ( $instance, $error );
    {
        ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
        local $@ = '';
        eval { $instance = $module->$builder(@args); };
        $error = $@;
        ## use critic
    }

    if ($error) {
        $on_error->($error);
    }

    return $instance;
}

sub load_and_new {
    my (%args) = @_;

    return build_object(
        module => load_module(
            module => $args{module},
            prefix => $args{prefix},
            inc    => [@INC],
        ),
        builder => 'new',
        args    => $args{args},
    );
}

sub _build_inc {
    my ($self) = @_;

    my @inc = ();
    if ( defined $self->set_inc ) {
        push @inc, @{ $self->set_inc };
    }
    elsif ( defined $self->add_inc ) {
        push @inc, @{ $self->add_inc }, @INC;
    }
    else {
        push @inc, @INC;
    }

    return \@inc;
}

1;

#ABSTRACT: A tiny module loader

__END__

=pod

=encoding UTF-8

=head1 NAME

MAD::Loader - A tiny module loader

=head1 VERSION

version 3.001003

=head1 SYNOPSIS

MAD::loader is a module loader and object builder for situations when you
want several modules being loaded dynamically.

For each module loaded this way a builder method may be called with
or without arguments. You may also control where the loader will search for
modules, you may prefix the module names with a custom namespace and you
may change how it will behave on getting errors.

    ## Procedural interface, for handling one module each time
    use MAD::Loader qw{ fqn load_module build_object };
    
    my $fqn = fqn( 'My::Module', 'My::Prefix' );
    # $fqn is 'My::Prefix::My::Module'
    
    my $module = load_module(
        module      => 'Bar',
        prefix      => 'Foo',
        inc         => [ 'my/local/lib' ],
        on_error    => \&error_handler,
    );
    # $module is 'Foo::Bar' if Foo::Bar was successfully loaded
    # error_handler() will be called in case of error
    
    my $object = build_object(
        module      => 'Foo::Bar',
        builder     => 'new',
        args        => [ 123, 456 ],
        on_error    => \&error_handler,
    );
    # Foo::Bar must be already loaded
    # $object = Foo::Bar->new( 123, 456 );
    
    ## OO interface, for handling many modules each time
    use MAD::Loader;

    my $loader = MAD::Loader->new(
        prefix      => 'Foo',
        set_inc     => [ 'my/module/dir' ],
        builder     => 'new',
        args        => [ 123, 456 ],
        on_error    => \&error_handler,
    );
    
    my $loaded = $loader->load( qw{ Bar Etc 123 } );
    # Same as:
    use Foo::Bar;
    use Foo::Etc;
    use Foo::123;
    
    my $built = $loader->build( qw{ Foo::Bar Foo::Etc Foo::123 } );
    # Same as:
    my $built = {
        Foo::Bar => Foo::Bar->new( 123, 456 ),
        Foo::Etc => Foo::Etc->new( 123, 456 ),
        Foo::123 => Foo::123->new( 123, 456 ),
    }
    
    my $built = $loader->load_and_build( qw{ Bar Etc 123 } );
    # Same as:
    use Foo::Bar;
    use Foo::Etc;
    use Foo::123;
    
    my $built = {
        Foo::Bar => Foo::Bar->new( 123, 456 ),
        Foo::Etc => Foo::Etc->new( 123, 456 ),
        Foo::123 => Foo::123->new( 123, 456 ),
    }

=head1 FUNCTIONS

=head2 fqn( $module [, $prefix] )

This method is used to validate the full name of a C<$module>. If an optional
C<$prefix> is given, it will be prepended to the C<$module> before being
validated.

The fqn is validated against the regular expression in C<$MODULE_NAME_REGEX>
which is C<qr{^[_[:upper:]]\w*(::\w+)*$}>.

If a valid fqn can not be found then an empty string is returned.

Note that only the non-ascii characters recognized by C<[:upper:]> and C<\w>
can be part of the module name or prefix.

Numbers are valid except for the B<first character> of the fqn.

=head2 load_module( %args )

Tries to load a single module.

Receives as argument a hash containing the following keys:

=head3 module (Mandatory)

The module name.

=head3 inc (Mandatory)

An ArrayRef with the list of directories where to look for the module. This
replaces locally the array @INC.

=head3 prefix (Optional)

A namespace to prefix the module name. Defaults to C<''>.

=head3 on_error (Optional)

An error handler to be executed when found errors. Defaults to
C<\&Carp::croak>.

=head2 build_object( %args )

Tries to build an object from a loaded module.

Receives as argument a hash containing the following keys:

=head3 module (Mandatory)

The module name.

=head3 builder (Mandatory)

The name of method used to build the object.

=head3 args (Optional)

An ArrayRef of parameters to be passed to the builder method.

=head3 on_error (Optional)

An error handler to be executed when found errors. Defaults to
C<\&Carp::croak>.

=head2 load_and_new( %args )

A shortcut for C<load_module> then C<build_object> with some predefined
args.

C<inc> is set to C<@INC> and c<builder> to C<'new'>. It is expected to deal
only with module, prefix and builder args.

=head1 METHODS

=head2 new( %params )

Creates a loader object.

You may provide any optional arguments: B<prefix>, B<builder>,
B<args>, B<add_inc>, B<set_inc> and B<on_error>.

=head3 prefix

The namespace that will be prepended to the module names.

The default value is '' (empty string) meaning that no prefix will be used.

    my $loader = MAD::Loader->new( prefix => 'Foo' );
    $loader->load(qw{ Bar Etc 123 });
    
    ## This will load the modules:
    ##  * Foo::Bar
    ##  * Foo::Etc
    ##  * Foo::123

=head3 builder

The name of the method used to create a new object or to initialize the
module.

The default value is C<''> (empty string).

When an C<builder> is defined the loader will try to call it like as a
constructor passing the array C<args> as argument.

The code below:

    my $loader = MAD::Loader->new(
        builder => 'init',
        args    => [ 1, 2, 3 ],
    );
    $loader->load( 'Foo' );
    $loader->build( 'Foo' );

Will cause something like this to occur:

    use Foo;
    Foo->init( 1, 2, 3 );

=head3 args

An ArrayRef with the arguments provided to all builders.

Note that although C<args> is an ArrayRef, it will be passed as an B<array>
to C<builder>.

When several modules are loaded together, the same C<args> will be passed
to their builders.

=head3 add_inc

An ArrayRef with directories to be prepended to C<@INC>.

The array C<@INC> will be localized before the loader add these directories,
so the original state of C<@INC> will be preserved out of the loader.

The default value is C<undef> meaning that original value of C<@INC> will be
used.

=head3 set_inc

An ArrayRef of directories used to override C<@INC>.

This option has priority over C<add_inc>, that is, if C<set_inc>
is defined the value of C<add_inc> will be ignored.

Again, C<@INC> will be localized internally so his original values will be
left untouched.

=head3 on_error

An error handler called when a module fails to load or build an object. His
only argument will be the exception thrown.

This is a coderef and the default value is C<\&Carp::croak>.

=head2 load( @modules )

Takes a list of module names and tries to load all of them in order.

For each module that fails to load, the error handler C<on_error> will be
called. Note that the default error handler is an alias to C<Carp::croak> so
in this case at the first fail, an exception will be thrown.

All module names will be prefixed with the provided C<prefix> and the loader
will try to make sure that they all are valid before try to load them. All
modules marked as "invalid" will not be loaded.

The term "invalid" is subject of discussion ahead.

The loader will search for modules into directories pointed by C<@INC> which
may be changed by attributes C<add_inc> and C<set_inc>.

In the end, if no exception was thrown, the method C<load> will return a
HashRef which the keys are the module names passed to it (without prefix)
and the values are the fqn (with prefix) of the module if it was loaded or an
empty string if it was not loaded.

=head2 build( @modules )

Takes a list of modules (fqn) already loaded and for each one, tries to
build an object calling the method indicated by C<builder>, passing to it the
arguments in C<args>.

Returns a HashRef which the keys are the names of the modules and the
values are the objects.

=head2 load_and_build( @modules )

A mix of C<load> and C<build>. Receives a list of modules, tries to prepend
them with C<prefix>, load all and finally build an object for each one.

Returns the same as C<build>.

=head2 prefix

Returns the namespace C<prefix> as described above.

=head2 builder

Returns the name of the C<builder> as described above.

=head2 args

Returns an ArrayRef with the C<args> provided to all builders.

=head2 add_inc

Returns the ArrayRef of directories prepended to C<@INC>.

=head2 set_inc

Returns the ArrayRef of directories used to override C<@INC>.

=head2 inc

Returns the ArrayRef of directories that represents the content of C<@INC>
internally into the loader.

=head2 on_error

Returns the CodeRef of the error handler.

=head1 LIMITATIONS

=head2 Valid Module Names

This module tries to define what is a valid module name. Arbitrarily we
consider a valid module name whatever module that matches with the regular
expression C<qr{^[_[:upper:]]\w*(::\w+)*$}>.

This validation is to avoid injection of arbitrarily code as fake module
names and the regular expression above should be changed in future versions
or a better approach may be considered.

Therefore some valid module names are considered invalid within
C<MAD::Loader> as names with some UTF-8 characters for example.
These modules cannot be loaded by C<MAD::Loader> yet. For now this B<IS>
intentional.

The old package delimiter C<'> (single quote) is also intentionally ignored
in favor of C<::> (double colon). Modules with single quote as package
delimiter cannot be loaded by C<MAD::Loader>.

=head1 CAVEATS

The options C<add_inc> and C<set_inc> are used to isolate the environment
where the search by modules is made, allowing you precisely control where
MAD::Loader will look for modules.

You may use this features when your application must load plugins and you
must assure that only modules within specific directories can be valid
plugins for example.

A collateral effect is that when a module loaded by MAD::Loader tries to
dynamically load another module, this module will be searched only within
the directories known by MAD::Laoder.

If you use the option C<set_inc> to limitate MAD::Loader to search only
within the directory C</my/plugins> for example, and some plugin tries to
load a module placed out of this path, your plugin will fail like this:

    Can't locate SomeModule.pm in @INC (@INC contains: /my/plugins) at
    /my/plugins/Myplugin.pm line 42.

Note that actually this is a feature, not a bug. If you isolate the search
path with MAD::Loader you will be sure that no module will bypass your
limitation, except if it know the search path of his sub-modules by itself
(in this case, there is little to do :) ).

See L<https://github.com/blabos/MAD-Loader/issues/1> for an example.

=head1 AUTHOR

Blabos de Blebe <blabos@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Blabos de Blebe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
