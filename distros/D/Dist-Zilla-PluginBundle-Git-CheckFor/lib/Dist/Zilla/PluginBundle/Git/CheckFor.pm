#
# This file is part of Dist-Zilla-PluginBundle-Git-CheckFor
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::PluginBundle::Git::CheckFor;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.013-5-geacb394
$Dist::Zilla::PluginBundle::Git::CheckFor::VERSION = '0.014';

# ABSTRACT: All Git::CheckFor plugins at once

use Moose;
use namespace::autoclean;

with 'Dist::Zilla::Role::PluginBundle::Easy';

sub configure {
    my ($self) = @_;

    $self->add_plugins(
        [ 'Git::CheckFor::CorrectBranch' => $self->config_slice('release_branch') ],
        'Git::CheckFor::Fixups',
        'Git::CheckFor::MergeConflicts',
    );

    return;
}



__PACKAGE__->meta->make_immutable;

!!42;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Christian Doherty Etheridge Karen Mengué Mike Olivier Walde

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::PluginBundle::Git::CheckFor - All Git::CheckFor plugins at once

=head1 VERSION

This document describes version 0.014 of Dist::Zilla::PluginBundle::Git::CheckFor - released October 10, 2016 as part of Dist-Zilla-PluginBundle-Git-CheckFor.

=head1 SYNOPSIS

    ; in dist.ini
    [@Git::CheckFor]

=head1 DESCRIPTION

This bundles several plugins that do some sanity/lint checking of your git
repository; namely: you're on the right branch and you haven't forgotten any
autosquash commits (C<fixup!> or C<squash!>).

=for Pod::Coverage configure

=for :spelling autosquash

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::Plugin::Git::CheckFor::Fixups>

=item *

L<Dist::Zilla::Plugin::Git::CheckFor::CorrectBranch>

=item *

L<Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts>

=item *

L<Dist::Zilla::PluginBundle::Git>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/RsrchBoy/dist-zilla-pluginbundle-git-checkfor/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Chris Weyl <cweyl@alumni.drew.edu>

=head2 I'm a material boy in a material world

=begin html

<a href="https://gratipay.com/RsrchBoy/"><img src="http://img.shields.io/gratipay/RsrchBoy.svg" /></a>
<a href="http://bit.ly/rsrchboys-wishlist"><img src="http://wps.io/wp-content/uploads/2014/05/amazon_wishlist.resized.png" /></a>
<a href="https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-pluginbundle-git-checkfor&title=RsrchBoy's%20CPAN%20Dist-Zilla-PluginBundle-Git-CheckFor&tags=%22RsrchBoy's%20Dist-Zilla-PluginBundle-Git-CheckFor%20in%20the%20CPAN%22"><img src="http://api.flattr.com/button/flattr-badge-large.png" /></a>

=end html

Please note B<I do not expect to be gittip'ed or flattr'ed for this work>,
rather B<it is simply a very pleasant surprise>. I largely create and release
works like this because I need them or I find it enjoyable; however, don't let
that stop you if you feel like it ;)

L<Flattr|https://flattr.com/submit/auto?user_id=RsrchBoy&url=https%3A%2F%2Fgithub.com%2FRsrchBoy%2Fdist-zilla-pluginbundle-git-checkfor&title=RsrchBoy's%20CPAN%20Dist-Zilla-PluginBundle-Git-CheckFor&tags=%22RsrchBoy's%20Dist-Zilla-PluginBundle-Git-CheckFor%20in%20the%20CPAN%22>,
L<Gratipay|https://gratipay.com/RsrchBoy/>, or indulge my
L<Amazon Wishlist|http://bit.ly/rsrchboys-wishlist>...  If and *only* if you so desire.

=head1 CONTRIBUTORS

=for stopwords Christian Walde Karen Etheridge Mike Doherty Olivier Mengué

=over 4

=item *

Christian Walde <walde.christian@googlemail.com>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Mike Doherty <doherty@cs.dal.ca>

=item *

Olivier Mengué <dolmen@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
