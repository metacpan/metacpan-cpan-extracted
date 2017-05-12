package Dist::Zilla::Plugin::EnsureChangesHasContent;

use v5.10;

use strict;
use warnings;
use autodie;
use namespace::autoclean;

our $VERSION = '0.02';

use CPAN::Changes;

use Moose;

has filename => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Changes',
);

with 'Dist::Zilla::Role::BeforeRelease';

sub before_release {
    my $self = shift;

    $self->log('Checking Changes');

    $self->zilla->ensure_built_in;

    my $filename = $self->filename;
    my $file     = $self->zilla->built_in->child($filename);

    if ( !-e $file ) {
        $self->log_fatal("No $filename file found");
    }
    elsif ( $self->_get_changes($file) ) {
        $self->log("$filename file has content for release");
    }
    else {
        $self->log_fatal(
            "$filename has no content for " . $self->zilla->version );
    }

    return;
}

sub _get_changes {
    my $self = shift;
    my $file = shift;

    my $changes = CPAN::Changes->load($file);
    my $release = $changes->release( $self->zilla->version )
        or return;
    my $all = $release->changes
        or return;

    return 1 if grep { @{ $all->{$_} // [] } } keys %{$all};
    return 0;
}

__PACKAGE__->meta->make_immutable;

1;

# ABSTRACT: Checks Changes for content using CPAN::Changes

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::EnsureChangesHasContent - Checks Changes for content using CPAN::Changes

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  [EnsureChangesHasContent]
  filename = Changelog

=head1 DESCRIPTION

This is a C<BeforeRelease> phase plugin that ensures that the changelog file
I<in your distribution> has at least one change listed for the version you are
releasing.

It is an alternative to L<Dist::Zilla::Plugin::CheckChangesHasContent> that
uses L<CPAN::Changes> to parse the changelog file. If your file follows the
format described by L<CPAN::Changes::Spec>, then this method of checking for
changes is more reliable than the ad hoc parsing used by
L<Dist::Zilla::Plugin::CheckChangesHasContent>.

=head1 CONFIGURATION

This plugin offers one configuration option:

=head2 filename

The filename in the distribution containing the changelog. This defaults to
F<Changes>.

=head1 SUPPORT

Bugs may be submitted at L<http://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-EnsureChangesHasContent> or via email to L<bug-dist-zilla-plugin-ensurechangeshascontent@rt.cpan.org|mailto:bug-dist-zilla-plugin-ensurechangeshascontent@rt.cpan.org>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Dist-Zilla-Plugin-EnsureChangesHasContent can be found at L<https://github.com/houseabsolute/Dist-Zilla-Plugin-EnsureChangesHasContent>.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time (let's all have a chuckle at that together).

To donate, log into PayPal and send money to autarch@urth.org, or use the
button at L<http://www.urth.org/~autarch/fs-donation.html>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
