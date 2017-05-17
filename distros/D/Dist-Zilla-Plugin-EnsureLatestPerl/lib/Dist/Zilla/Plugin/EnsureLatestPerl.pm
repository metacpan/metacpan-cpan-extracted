use strict;
use warnings;
package Dist::Zilla::Plugin::EnsureLatestPerl; # git description: v0.002-4-g892b77d
# vim: set ts=8 sts=4 sw=4 tw=115 et :
# ABSTRACT: Ensure the author is releasing using the latest Perl
# KEYWORDS: plugin release develop author perl version latest

our $VERSION = '0.003';

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use Module::CoreList;
use List::Util 'first';
use namespace::autoclean;

around dump_config => sub
{
    my ($orig, $self) = @_;
    my $config = $self->$orig;

    $config->{+__PACKAGE__} = {
        blessed($self) ne __PACKAGE__ ? ( version => $VERSION ) : (),
        'Module::CoreList' => Module::CoreList->VERSION,
    };

    return $config;
};

sub before_release
{
    my $self = shift;

    $self->log('DZIL_ANY_PERL set: skipping perl version check'), return
        if $ENV{DZIL_ANY_PERL};

    # we cannot know in advance the release schedule of Module::CoreList in order to check the latest perl
    # releases, but we can make a guess -- development releases are made once a month.  We'll assume that any
    # Module::CoreList older than 2 months old is out of date, and lean on modules like [PromptIfStale] to confirm
    # against the PAUSE index.

    my $delta = 2 * 30 * 24 * 60 * 60;
    my @gmtime = gmtime(time() - $delta);
    my $expected_version = sprintf('5.%04d%02d%02d', $gmtime[5] + 1900, $gmtime[4] + 1, $gmtime[3]);

    my $error_suffix = 'disable check with DZIL_ANY_PERL=1';

    if (not eval { Module::CoreList->VERSION($expected_version); 1 })
    {
        $self->log_fatal([ 'Module::CoreList is not new enough to check if this is the latest Perl (expected at least %s) -- %s',
            $expected_version, $error_suffix ]);
    }

    # sort perl releases in reverse order
    my @all_perl_releases = reverse sort keys %Module::CoreList::released;

    my $latest_stable_perl = first { /^5\.(\d{3})/; defined $1 and $1 % 2 == 0 } @all_perl_releases;
    my $latest_dev_perl = first { /^5\.(\d{3})/; defined $1 and $1 % 2 == 1 } @all_perl_releases;

    $self->log_fatal([ 'current perl (%s) is neither the current stable nor development perl (%s, %s) -- %s',
            $], $latest_stable_perl, $latest_dev_perl, $error_suffix ])
        if "$]" ne $latest_stable_perl and "$]" ne $latest_dev_perl;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::EnsureLatestPerl - Ensure the author is releasing using the latest Perl

=head1 VERSION

version 0.003

=head1 SYNOPSIS

In your F<dist.ini>:

    [EnsureLatestPerl]

=head1 DESCRIPTION

=for Pod::Coverage before_release

This is a L<Dist::Zilla> plugin that aborts the C<dzil release> process unless the latest perl is being used for
the release. "Latest" here is calculated as the latest point release in the latest stable or development Perl
lines -- for example, 5.24.1 (latest in the 5.24 series) or 5.25.12 (latest in the 5.25 series).

=head1 CONFIGURATION OPTIONS

=head2 C<DZIL_ANY_PERL>

When this environment variable is true, the check is skipped.  Therefore, it is safe to keep this plugin enabled in
your plugin bundle, and you can disable it temporarily as needed for a particular release without changing any
local files.

=head1 SEE ALSO

=over 4

=item *

L<Module::CoreList>

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureLatestPerl>
(or L<bug-Dist-Zilla-Plugin-EnsureLatestPerl@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-EnsureLatestPerl@rt.cpan.org>).

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
