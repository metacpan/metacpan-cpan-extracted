package Dist::Zilla::Plugin::Mercurial;
$Dist::Zilla::Plugin::Mercurial::VERSION = '0.08';
use strict;
use warnings;

1;

# ABSTRACT: A Mercurial plugin for Dist::Zilla

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Mercurial - A Mercurial plugin for Dist::Zilla

=head1 VERSION

version 0.08

=head1 SYNOPSIS

In your F<dist.ini>:

  [@Mercurial]

=head1 DESCRIPTION

This plugin provides Mercurial support for L<Dist::Zilla>. Currently, it
supports checking that the working copy is clean before release, tagging, and
pushing changes to the remote. The tag plugin also checks before tagging to
make sure that the tag it wants to use is unique.

Currently, this plugin does not support committing, so it won't play nice with
plugins that make changes to the working copy before release. Patches are
welcome.

=head1 SUPPORT

Please report any bugs or feature requests to
C<bug-dist-zilla-plugin-mercurial@rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org>. I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
