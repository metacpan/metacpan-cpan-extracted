#
# This file is part of Dist-Zilla-Plugin-NoSmartCommentsTests
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::Test::NoSmartComments;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Dist::Zilla::Plugin::Test::NoSmartComments::VERSION = '0.009';
# ABSTRACT: Make sure no Smart::Comments escape into the wild

use Moose;
use namespace::autoclean;

extends 'Dist::Zilla::Plugin::NoSmartCommentsTests';

__PACKAGE__->meta->make_immutable;
!!42;

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Plugin::Test::NoSmartComments - Make sure no Smart::Comments escape into the wild

=head1 VERSION

This document describes version 0.009 of Dist::Zilla::Plugin::Test::NoSmartComments - released October 09, 2016 as part of Dist-Zilla-Plugin-NoSmartCommentsTests.

=head1 SYNOPSIS

    ; In C<dist.ini>:
    [Test::NoSmartComments]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/no-smart-comments.t - test to ensure no Smart::Comments

=head1 NOTE

The name of this plugin has turned out to be somewhat misleading, I'm afraid:
we don't actually test for the _existance_ of smart comments, rather we
ensure that Smart::Comment is not used by any file checked.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::NoSmartCommentsTests|Dist::Zilla::Plugin::NoSmartCommentsTests>

=item *

L<Smart::Comments|Smart::Comments>

=item *

L<Test::NoSmartComments|Test::NoSmartComments>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/dist-zilla-plugin-nosmartcommentstests/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-plugin-nosmartcommentstests&title=RsrchBoy's%20CPAN%20Dist-Zilla-Plugin-NoSmartCommentsTests&tags=%22RsrchBoy's%20Dist-Zilla-Plugin-NoSmartCommentsTests%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-plugin-nosmartcommentstests&title=RsrchBoy's%20CPAN%20Dist-Zilla-Plugin-NoSmartCommentsTests&tags=%22RsrchBoy's%20Dist-Zilla-Plugin-NoSmartCommentsTests%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut

__DATA__