use 5.10.0;
use strict;
use warnings;

package Dist::Iller::DocType::Dist;

our $AUTHORITY = 'cpan:CSSON'; # AUTHORITY
our $VERSION = '0.1408';

use Dist::Iller::Elk;
with qw/
    Dist::Iller::DocType
    Dist::Iller::Role::HasPrereqs
    Dist::Iller::Role::HasPlugins
/;

use Types::Standard qw/HashRef ArrayRef Str Int Bool/;
use PerlX::Maybe qw/maybe provided/;
use List::Util qw/any/;

has name => (
    is => 'rw',
    isa => Str,
    predicate => 1,
    init_arg => undef,
);
has author => (
    is => 'rw',
    isa => (ArrayRef[Str])->plus_coercions(Str, sub { [$_] }),
    init_arg => undef,
    traits => ['Array'],
    default => sub { [ ] },
    coerce => 1,
    handles => {
        all_authors => 'elements',
        map_authors => 'map',
        add_author => 'push',
        has_author => 'count',
    },
);
has license => (
    is => 'rw',
    isa => Str,
    predicate => 1,
    init_arg => undef,
);
has copyright_holder => (
    is => 'rw',
    isa => Str,
    predicate => 1,
    init_arg => undef,
);
has copyright_year => (
    is => 'rw',
    isa => Int,
    predicate => 1,
    init_arg => undef,
);
has add_prereqs_as_authordeps => (
    is => 'rw',
    isa => Bool,
    default => 0,
);


sub filename { 'dist.ini' }

sub phase { 'before' }

sub comment_start { ';' }

sub parse {
    my $self = shift;
    my $yaml = shift;
    if(exists $yaml->{'add_prereqs_as_authordeps'}) {
        $self->add_prereqs_as_authordeps(delete $yaml->{'add_prereqs_as_authordeps'});
    }
    $self->parse_header($yaml->{'header'});
    $self->parse_default_prereq_versions($yaml->{'default_prereq_versions'});
    $self->parse_prereqs($yaml->{'prereqs'});
    $self->parse_plugins($yaml->{'plugins'});
}

around qw/parse_header  parse_prereqs  parse_default_prereq_versions/ => sub {
    my $next = shift;
    my $self = shift;
    my $yaml = shift;

    return if !defined $yaml;
    $self->$next($yaml);
};

sub parse_header {
    my $self = shift;
    my $yaml = shift;

    foreach my $setting (qw/name author license copyright_holder copyright_year/) {
        my $value = $yaml->{ $setting };
        my $predicate = "has_$setting";

        if(!$self->$predicate && $value) {
            $self->$setting($value);
        }
    }
}

sub parse_default_prereq_versions {
    my $self = shift;
    my $yaml = shift;

    # prereqs added from this point forward checks defaults
    foreach my $default (@{ $yaml }) {
        $self->set_default_prereq_version((keys %$default)[0], (values %$default)[0]);
    }
    # check prereqs already added
    foreach my $prereq ($self->all_prereqs) {
        my $default_version = $self->get_default_prereq_version($prereq->module);
        if($default_version && !$prereq->version) {
            $prereq->version($default_version);
        }
    }
}

sub parse_prereqs {
    my $self = shift;
    my $yaml = shift;

    foreach my $phase (qw/build configure develop runtime test/) {
        foreach my $relation (qw/requires recommends suggests conflicts/) {

            MODULE:
            foreach my $module (@{ $yaml->{ $phase }{ $relation } }) {
                my $module_name = ref $module eq 'HASH' ? (keys %$module)[0] : $module;
                my $version     = ref $module eq 'HASH' ? (values %$module)[0] : 0;

                $self->add_prereq(Dist::Iller::Prereq->new(
                    module => $module_name,
                    phase => $phase,
                    relation => $relation,
                    version => $version,
                ));
            }
        }
    }
}

# to_hash does not translate prereqs into [Prereqs / *Phase*Requires] plugins
sub to_hash {
    my $self = shift;

    my $header = {
        provided $self->has_author, author => $self->author,
                              maybe name => $self->name,
                              maybe license => $self->license,
                              maybe copyright_holder => $self->copyright_holder,
                              maybe copyright_year => $self->copyright_year,

    };
    my $hash = {
        header => $header,
        prereqs => $self->prereqs_to_hash,
        default_prereq_versions => [ map { +{ $_->[0] => $_->[1] } } $self->all_default_prereq_versions ],
        plugins => $self->plugins_to_hash,
    };

    return $hash;
}

sub packages_for_plugin {
    return sub {
        my $plugin = shift;

        my $name = $plugin->has_base ? $plugin->base : $plugin->plugin_name;
        $name =~ m{^(.)};
        my $first = $1;

        my $clean_name = $name;
        $clean_name =~ s{^[-%=@]}{};

        my $packages = [];
        push @{ $packages } => $first eq '%' ? { version => $plugin->version, package => sprintf 'Dist::Zilla::Stash::%s', $clean_name }
                            :  $first eq '@' ? { version => $plugin->version, package => sprintf 'Dist::Zilla::PluginBundle::%s', $clean_name }
                            :  $first eq '=' ? { version => $plugin->version, package => sprintf $clean_name }
                            :                  { version => $plugin->version, package => sprintf 'Dist::Zilla::Plugin::%s', $clean_name }
                            ;
        return $packages;
    };
}

sub add_plugins_as_prereqs {
    my $self = shift;
    my $packages_for_plugin = shift;
    my @plugins = @_;

    for my $plugin (@plugins) {
        if($plugin->has_prereqs) {
            $self->add_prereq($_) for $plugin->all_prereqs;
        }
        my $packages = $packages_for_plugin->($plugin);

        for my $package (@{ $packages }) {
            $self->add_prereq(Dist::Iller::Prereq->new(
                module => $package->{'package'},
                phase => 'develop',
                relation => 'requires',
                version => $package->{'version'},
            ));
        }
    }
    $self->add_prereq(Dist::Iller::Prereq->new(
        module => 'Dist::Zilla::Plugin::Prereqs',
        phase => 'develop',
        relation => 'requires',
        version => '0',
    ));
}

sub to_string {
    my $self = shift;

    for my $phase (qw/build configure develop runtime test/) {
        RELATION:
        for my $relation (qw/requires recommends suggests conflicts/) {

            my $plugin_name = sprintf '%s%s', ucfirst $phase, ucfirst $relation;

            # in case to_string is called twice, don't add this again
            next RELATION if $self->find_plugin(sub { $_->plugin_name eq $plugin_name });

            my @prereqs = $self->filter_prereqs(sub { $_->phase eq $phase && $_->relation eq $relation });
            next RELATION if !scalar @prereqs;

            $self->add_plugin({
                plugin_name => $plugin_name,
                base => 'Prereqs',
                parameters => { map { $_->module => $_->version } @prereqs },
            });
        }
    }

    my @strings = ();
    push @strings => sprintf 'name = %s', $self->name if $self->name;

    if($self->has_author) {
        push @strings => $self->map_authors(sub { qq{author = $_} });
    }
    push @strings => sprintf 'license = %s', $self->license if $self->has_license;
    push @strings => sprintf 'copyright_holder = %s', $self->copyright_holder if $self->has_copyright_holder;
    push @strings => sprintf 'copyright_year = %s', $self->copyright_year if $self->has_copyright_year;
    push @strings => '' if scalar @strings;

    foreach my $plugin ($self->all_plugins) {
        push @strings => $plugin->to_string, '';
    }

    {
        my $has_author_deps = 0;
        my $previous_module = '';

        my @phases = ('develop', $self->add_prereqs_as_authordeps ? (qw/runtime test/) : ());
        my @filtered_prereqs = $self->filter_prereqs(sub {
            my $prereq = $_;
            $prereq->relation eq 'requires' && $prereq->module ne 'perl' && (any { $prereq->phase eq $_ } @phases);
        });

        AUTHORDEP:
        foreach my $authordep (sort { $a->module cmp $b->module } @filtered_prereqs) {
            next AUTHORDEP if $authordep->module eq $previous_module;
            push @strings => sprintf '; authordep %s = %s', $authordep->module, $authordep->version;
            $has_author_deps = 1;
            $previous_module = $authordep->module;
        }
        push @strings => '' if $has_author_deps;
    }

    return join "\n" => @strings;

}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Iller::DocType::Dist

=head1 VERSION

Version 0.1408, released 2016-03-12.

=head1 SOURCE

L<https://github.com/Csson/p5-Dist-Iller>

=head1 HOMEPAGE

L<https://metacpan.org/release/Dist-Iller>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
