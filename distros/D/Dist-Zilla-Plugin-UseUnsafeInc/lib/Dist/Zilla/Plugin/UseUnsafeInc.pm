use strict;
use warnings;
package Dist::Zilla::Plugin::UseUnsafeInc; # git description: f69f5d2
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Indicates the value of PERL_USE_UNSAFE_INC to use during installation
# KEYWORDS: metadata PERL_USE_UNSAFE_inc distribution testing compatibility environment

our $VERSION = '0.001';

use Moose;
with 'Dist::Zilla::Role::MetaProvider',
  'Dist::Zilla::Role::AfterBuild',
  'Dist::Zilla::Role::BeforeRelease';

use namespace::autoclean;

has dot_in_INC => (
    is => 'ro', isa => 'Bool',
    required => 1,
);

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        dot_in_INC => $self->dot_in_INC ? 1 : 0,
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
    };

    return $config;
};

sub metadata
{
    my $self = shift;
    +{ x_use_unsafe_inc => $self->dot_in_INC ? 1 : 0 };
}

sub after_build
{
    my $self = shift;

    # this is kind of kludgy but we just need to have this set before TestRunners run.
    $self->log_debug([ 'Setting PERL_USE_UNSAFE_INC = %s for local testing...', $self->dot_in_INC ]);
    $ENV{PERL_USE_UNSAFE_INC} = $self->dot_in_INC;
}

sub before_release
{
    my $self = shift;

    $self->log('DZIL_ANY_PERL set: skipping perl version check'), return
        if $ENV{DZIL_ANY_PERL};

    $self->log_fatal('Perl must be 5.025007 or newer to test with PERL_USE_UNSAFE_INC -- disable check with DZIL_ANY_PERL=1')
        if "$]" < 5.025007;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::UseUnsafeInc - Indicates the value of PERL_USE_UNSAFE_INC to use during installation

=head1 VERSION

version 0.001

=head1 SYNOPSIS

In your F<dist.ini>:

    ; this distribution still requires . to be in @INC
    [UseUnsafeInc]
    dot_in_INC = 1

or:

    ; this distribution does not need . to be in @INC
    [UseUnsafeInc]
    dot_in_INC = 0

=head1 DESCRIPTION

=for Pod::Coverage metadata after_build before_release

This is a L<Dist::Zilla> plugin that populates the C<x_use_unsafe_inc> key in your distribution metadata. This
indicates to components of the toolchain that C<PERL_USE_UNSAFE_INC> should be set to a certain value during
installation and testing, overriding any previous setting e.g. from the environment or from other tools.

The environment variable is also set in L<Dist::Zilla> while building and testing the distribution, to ensure
that local testing behaves in an expected fashion.

Additionally, the release must be performed using a Perl version that supports C<PERL_USE_UNSAFE_INC>, to further
guarantee test integrity.

=head1 CONFIGURATION OPTIONS

=head2 C<use_unsafe_inc>

This configuration value must be set in your F<dist.ini>, to either 0 or 1.  C<PERL_USE_UNSAFE_INC> will be set to
the same value by tools that support it.

=head2 C<DZIL_ANY_PERL>

When this environment variable is true, the Perl version check at release time (see above) is skipped.

=head1 BACKGROUND

=head1 SEE ALSO

=over 4

=item *

L<perldelta/'.' and @INC>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-UseUnsafeInc>
(or L<bug-Dist-Zilla-Plugin-UseUnsafeInc@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-UseUnsafeInc@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

I am also usually active on irc, as 'ether' at C<irc.perl.org>.

=head1 AUTHOR

Karen Etheridge <ether@cpan.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017 by Karen Etheridge.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
