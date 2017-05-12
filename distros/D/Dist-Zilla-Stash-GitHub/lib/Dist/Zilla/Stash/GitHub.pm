#
# This file is part of Dist-Zilla-Stash-GitHub
#
# This software is Copyright (c) 2015 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Stash::GitHub;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 2e7a1cf
$Dist::Zilla::Stash::GitHub::VERSION = '0.001';

# ABSTRACT: The great new Dist::Zilla::Stash::GitHub!

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

sub mvp_aliases { { user => 'username', id => 'username', token => 'password' } }


has username => (is => 'rwp', isa => 'Str', required => 1);
has password => (is => 'rwp', isa => 'Str', required => 1);

with 'Dist::Zilla::Role::Stash::Login';

__PACKAGE__->meta->make_immutable;
!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Stash::GitHub - The great new Dist::Zilla::Stash::GitHub!

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Stash::GitHub - released May 10, 2015 as part of Dist-Zilla-Stash-GitHub.

=head1 SYNOPSIS

    # in your ~/.dzil/config.ini
    [%GitHub]
    username = RsrchBoy
    password = la la la la la

=head1 DESCRIPTION

Right now, a bog-standard, simple little stash to keep one github token in a
central location...  As everything seems to be looking for one in different
places, or keeping their own somewhere.

Ideally, this will be less zombie-like in the not-too-distant future, and if
the id/token information is not embedded in one's C<~/.dzil/config.ini> it
will be looked for in the usual suspect locations.

=head1 ATTRIBUTES

=head2 username

String, read-write-private, required.

The GitHub username.  'user' or 'id' will be accepted as aliases.

=head2 password

String, read-write-private, required.

The user's password.  Or, B<preferably>, a distinct identity token.  Seriously.

'token' will be accepted as an alias.

=for Pod::Coverage mvp_aliases

=head1 TODO

* "Get smarter" about looking up our github id/token.

* Keep our id/token in a distinct config file (optionally?)

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Role::Stash::Login|Dist::Zilla::Role::Stash::Login>

=item *

L<https://github.com/settings/tokens|https://github.com/settings/tokens>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/RsrchBoy/dist-zilla-stash-github/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-github&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-GitHub&tags=%22RsrchBoy's%20Dist-Zilla-Stash-GitHub%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-stash-github&title=RsrchBoy's%20CPAN%20Dist-Zilla-Stash-GitHub&tags=%22RsrchBoy's%20Dist-Zilla-Stash-GitHub%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
