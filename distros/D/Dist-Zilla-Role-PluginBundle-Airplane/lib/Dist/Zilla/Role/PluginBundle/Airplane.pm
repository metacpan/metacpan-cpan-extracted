package Dist::Zilla::Role::PluginBundle::Airplane;
our $VERSION = '0.001';
use Moose::Role;

# ABSTRACT: A role for building packages with Dist::Zilla in an airplane

use Dist::Zilla::Util;

requires 'build_network_plugins';

has airplane => (
    is       => 'ro',
    isa      => 'Bool',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_airplane_mode',
);

has network_plugins => (
    is       => 'ro',
    isa      => 'ArrayRef',
    init_arg => undef,
    lazy     => 1,
    builder  => 'build_network_plugins',
);

sub _build_airplane_mode {
    return $ENV{DZIL_AIRPLANE} // $_[0]->payload->{airplane} // 0;
}

sub _get_network_plugins {
    my ($self) = @_;

    my %network_plugins;
    for (@{$self->network_plugins}) {
        $network_plugins{$self->_plugin_to_name($_)} = 1;
    }
    return \%network_plugins;
}

sub _plugin_to_name {
    my ($self, $plugin) = @_;
    return Dist::Zilla::Util->expand_config_package_name($plugin);
}

around add_plugins => sub {
    my $orig    = shift;
    my $self    = shift;
    my @plugins = @_;


    if ($self->airplane) {
        my $plugins = $self->_get_network_plugins();
        @plugins = grep {
            not exists $plugins->{
                $self->_plugin_to_name(
                    !ref $_ ? $_ : ref eq 'ARRAY' ? $_->[0] : die "unable")
            };
        } @plugins;


        # halt release after pre-release checks, but before ConfirmRelease
        push @plugins, 'BlockRelease';
    }

    $orig->($self, @plugins);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginBundle::Airplane - A role for building packages with Dist::Zilla in an airplane

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    package Dist::Zilla::PluginBundle::Author::EXAMPLE;
    use Moose;

    with 'Dist::Zilla::Role::PluginBundle::Airplane';

    sub build_airplane_mode {
        return [qw(
            PromptIfStale
            Test::Pod::LinkCheck
            Test::Pod::No404s
            Git::Remote::Check
            CheckPrereqsIndexed
            CheckIssues
            UploadToCPAN
            UploadToStratopan
            Git::Push
        )];
    };

    sub configure {
        my $self = shift;

        my @plugins = ['PromptIfStale'];

        $self->add_plugins(@plugins);
    }

=head1 DESCRIPTION

Enables airplane mode for your dzil plugin bundle. This means all network
plugins are removed from loading and aborts a release via the plugin
L<Dist::Zilla::Plugin::BlockRelease>.

    # In your dist.ini
    [@Author::EXAMPLE]
    airplane = 1 ; or DZIL_AIRPLANE=1 in your shell

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
