package Dist::Zilla::Role::PluginBundle::Zilla;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Moose::Role;
with 'Dist::Zilla::Role::PluginBundle';

use List::Util qw(first);
use Moose::Util::TypeConstraints qw(class_type);
use Scalar::Util qw(weaken);

use namespace::autoclean;

has name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has zilla => (
    is       => 'ro',
    isa      => class_type('Dist::Zilla'),
    init_arg => undef,
    weak_ref => 1,
    lazy     => 1,
    builder  => '_build_zilla',
);

has logger => (
    is      => 'ro',
    lazy    => 1,
    handles => [qw(log log_debug log_fatal)],
    default => sub {
        $_[0]->zilla->chrome->logger->proxy(
            {
                proxy_prefix => '[' . $_[0]->name . '] ',
            },
        );
    },
);

{
    my %zilla;

    around 'register_component' => sub {
        my ( $orig, $class, $name, $arg, $section ) = @_;

        my @sections       = $section->sequence->sections;
        my ($root_section) = first { $_->name eq q{_} } @sections;
        my $zilla          = $root_section->zilla;

        $zilla{$name} = $zilla;
        weaken( $zilla{$name} );

        return $class->$orig( $name, $arg, $section );
    };

    sub _build_zilla {
        my ($self) = @_;

        my $name = $self->name;

        my $zilla = delete $zilla{$name};
        return $zilla;
    }
}

sub BUILD {
    my ($self) = @_;

    # move the zilla object from our hash to the object
    $self->zilla;

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::PluginBundle::Zilla - adds the zilla object and the logger to your bundles

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

=head2 Dist::Zilla::Role::PluginBundle

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Zilla';

    sub bundle_config {
        my ( $class, $section ) = @_;

        my $self = $class->new($section);
        $self->log('Hello from your friendly bundle! We are running in ' . $self->zilla->root);
        $self->log_fatal('Something went wrong...');

        return;
    }

=head2 Dist::Zilla::Role::PluginBundle::Easy

    package Dist::Zilla::PluginBundle::MyBundle;

    use Moose;
    with 'Dist::Zilla::Role::PluginBundle::Easy';
    with 'Dist::Zilla::Role::PluginBundle::Zilla';

    sub configure {
        my ($self) = @_;

        $self->log('Hello from your friendly bundle! We are running in ' . $self->zilla->root);
        $self->log_fatal('Something went wrong...');

        return;
    }


=head1 DESCRIPTION

This role makes the C<zilla> object available and adds the C<log>,
C<log_fatal>, and C<log_debug> methods to your bundle.

This allows you to use the same logging procedure in your bundle that plugins
use.

If you use L<Dist::Zilla::Role::PluginBundle::Easy> you have to import these
two roles with two separate calls to C<with> because both roles declare the
name attribute.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Dist-Zilla-Role-PluginBundle-Zilla/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Dist-Zilla-Role-PluginBundle-Zilla>

  git clone https://github.com/skirmess/Dist-Zilla-Role-PluginBundle-Zilla.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=head1 SEE ALSO

L<Dist::Zilla::Role::PluginBundle>,
L<Dist::Zilla::Role::PluginBundle::Easy>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
