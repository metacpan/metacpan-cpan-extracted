package Dist::Zilla::Plugin::Code::FileMunger;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.007';

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::FileMunger';

use Carp qw(confess);
use Config::MVP 2.200012 ();    # https://github.com/rjbs/Config-MVP/issues/13
use MooseX::Types::Moose qw(CodeRef);

has munge_file => (
    is     => 'ro',
    isa    => 'CodeRef',
    reader => '_munge_file',
);

has munge_files => (
    is     => 'ro',
    isa    => 'CodeRef',
    reader => '_munge_files',
);

sub BUILD {
    my ($self) = @_;

    confess 'Attribute (munge_file) or (munge_files) is required at constructor ' . __PACKAGE__ . '::new' if !defined $self->_munge_file && !defined $self->_munge_files;

    return;
}

sub munge_file {
    my $self = shift;

    my $code_ref = $self->_munge_file;
    return if !defined $code_ref;
    return $self->$code_ref(@_);
}

around munge_files => sub {
    my $next = shift;
    my $self = shift;

    my $code_ref = $self->_munge_files;
    return $self->$code_ref() if defined $code_ref;
    return $self->$next();
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Code::FileMunger - something that munges files within the distribution

=head1 VERSION

Version 0.007

=head1 SYNOPSIS

=head2 Dist::Zilla::Role::PluginBundle (munge_file)

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle';

    sub bundle_config {
        my ( $class, $section ) = @_;

        my @plugins;
        push @plugins, [
            'SomeUniqueName',
            'Dist::Zilla::Plugin::Code::FileMunger',
            {
                munge_file => sub {
                    my ($self) = @_;
                    $self->log('Hello world');
                },
            },
        ];

        return @plugins;
    }

=head2 Dist::Zilla::Role::PluginBundle (munge_files)

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle';

    sub bundle_config {
        my ( $class, $section ) = @_;

        my @plugins;
        push @plugins, [
            'SomeUniqueName',
            'Dist::Zilla::Plugin::Code::FileMunger',
            {
                munge_files => sub {
                    my ($self) = @_;
                    $self->log('Hello world');
                },
            },
        ];

        return @plugins;
    }

=head2 Dist::Zilla::Role::PluginBundle::Easy (munge_file)

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';

    sub configure {
        my ( $self ) = @_;

        $self->add_plugins([
            'Code::FileMunger',
            {
                munge_file => sub {
                    my ($self) = @_;
                    $self->log('Hello world');
                },
            },
        ]);

        return;
    }

=head2 Dist::Zilla::Role::PluginBundle::Easy (munge_files)

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';

    sub configure {
        my ( $self ) = @_;

        $self->add_plugins([
            'Code::FileMunger',
            {
                munge_files => sub {
                    my ($self) = @_;
                    $self->log('Hello world');
                },
            },
        ]);

        return;
    }

=head1 DESCRIPTION

This plugin implements the L<Dist::Zilla::Role::FileMunger> role.

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

L<Dist::Zilla>, L<Dist::Zilla::Role::FileMunger>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
