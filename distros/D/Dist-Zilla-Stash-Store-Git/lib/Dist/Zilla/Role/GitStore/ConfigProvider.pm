#
# This file is part of Dist-Zilla-Stash-Store-Git
#
# This software is Copyright (c) 2014 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Role::GitStore::ConfigProvider;
BEGIN {
  $Dist::Zilla::Role::GitStore::ConfigProvider::AUTHORITY = 'cpan:RSRCHBOY';
}
$Dist::Zilla::Role::GitStore::ConfigProvider::VERSION = '0.000005';
# ABSTRACT: Something that provides config info to %Store::Git

use Moose::Role;
use namespace::autoclean;
use MooseX::AttributeShortcuts;


requires 'gitstore_config_provided';

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Role::GitStore::ConfigProvider - Something that provides config info to %Store::Git

=head1 VERSION

This document describes version 0.000005 of Dist::Zilla::Role::GitStore::ConfigProvider - released May 14, 2014 as part of Dist-Zilla-Stash-Store-Git.

=head1 SYNOPSIS

=head1 DESCRIPTION

This role should be consumed by anything (typically a plugin) that B<provides>
information to the L<%Store::Git stash|Dist::Zilla::Stash::Store::Git>.

Note that this role does not indicate that the store is being used in any way,
simply that the plugin makes available some configuration information that the
stash itself may consume when populating L<Dist::Zilla::Stash::Store::Git/dynamic_config>.

=head1 REQUIRED METHODS

=head2 gitstore_config_provided

This required method must return a HashRef of key, value configuration pairs.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Stash::Store::Git|Dist::Zilla::Stash::Store::Git>

=back

=head1 SOURCE

The development version is on github at L<http://https://github.com/RsrchBoy/dist-zilla-stash-store-git>
and may be cloned from L<git://https://github.com/RsrchBoy/dist-zilla-stash-store-git.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-stash-store-git/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://www.gittip.com/RsrchBoy/"><img src="https://raw.githubusercontent.com/gittip/www.gittip.com/master/www/assets/%25version/logo.png" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-store-git&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-Store-Git&tags=%22RsrchBoy's%20Dist-Zilla-Stash-Store-Git%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr this|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-store-git&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-Store-Git&tags=%22RsrchBoy's%20Dist-Zilla-Stash-Store-Git%20in%20the%20CPAN%22>,
L<gittip me|https://www.gittip.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
