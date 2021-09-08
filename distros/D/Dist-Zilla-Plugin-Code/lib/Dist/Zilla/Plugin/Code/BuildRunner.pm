package Dist::Zilla::Plugin::Code::BuildRunner;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.007';

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::BuildRunner';

use Config::MVP 2.200012 ();    # https://github.com/rjbs/Config-MVP/issues/13
use MooseX::Types::Moose qw(CodeRef);

has build => (
    is       => 'ro',
    isa      => 'CodeRef',
    reader   => '_build',
    required => 1,
);

sub build {
    my $self = shift;

    my $code_ref = $self->_build;
    return $self->$code_ref(@_);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Code::BuildRunner - something used as a delegating agent during 'dzil run'

=head1 VERSION

Version 0.007

=head1 SYNOPSIS

=head2 Dist::Zilla::Role::PluginBundle

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle';

    sub bundle_config {
        my ( $class, $section ) = @_;

        my @plugins;
        push @plugins, [
            'SomeUniqueName',
            'Dist::Zilla::Plugin::Code::BuildRunner',
            {
                build => sub {
                    my ( $self, $build_dir ) = @_;
                    $self->log('Hello world');
                },
            },
        ];

        return @plugins;
    }

=head2 Dist::Zilla::Role::PluginBundle::Easy

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';

    sub configure {
        my ( $self ) = @_;

        $self->add_plugins([
            'Code::BuildRunner',
            {
                build => sub {
                    my ( $self, $build_dir ) = @_;
                    $self->log('Hello world');
                },
            },
        ]);

        return;
    }

=head1 DESCRIPTION

This plugin implements the L<Dist::Zilla::Role::BuildRunner> role.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Plugin-Code/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Plugin-Code>

  git clone https://github.com/skirmess/Dist-Zilla-Plugin-Code.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020-2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla>, L<Dist::Zilla::Role::BuildRunner>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
