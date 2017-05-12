#
# This file is part of Dist-Zilla-PluginBundle-Git-CheckFor
#
# This software is Copyright (c) 2012 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts;
our $AUTHORITY = 'cpan:RSRCHBOY';
$Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts::VERSION = '0.014';
use strict;
use warnings;

# ABSTRACT: Check your repo for merge-conflicted files
use Moose;
use autodie qw(:io);
use namespace::autoclean;
use List::Util 1.33 qw(any);

with
    'Dist::Zilla::Role::BeforeRelease',
    'Dist::Zilla::Role::Git::Repo::More',
        #-excludes => [ qw { _build_version_regexp _build_first_version } ],
    ;

has merge_conflict_patterns => (
    is => 'ro',
    isa => 'ArrayRef[RegexpRef]',
    lazy => 1,
    default => sub {
        my $self = shift;
        my $repo = $self->_repo;
        my ($branch) = $repo->branch;
        return [
            qr/^=======/,
            qr/^<<<<<<< Updated upstream/,
            qr/^>>>>>>> Stashed changes/,
            qr/^<<<<<<< HEAD/,
            qr/^>>>>>>> \Q$branch\E/,
        ];
    },
);

has ignore => (
    is => 'ro',
    isa => 'ArrayRef[Str]',
    predicate => 'has_ignore',
);

sub mvp_multivalue_args { qw( ignore ) }

sub before_release {
    my $self = shift;

    my %error_files;
    FILE:
    foreach my $file ( @{ $self->zilla->files } ) {
        next FILE
            if $file->can('encoding') and $file->encoding eq 'bytes';

        next FILE
            if $self->has_ignore
            and any { $file->name eq $_ } @{ $self->ignore };

        my $text = $file->content;
        foreach my $re ( @{ $self->merge_conflict_patterns } ) {
            foreach my $line (split $/, $text) {
                if ( $line =~ m/($re)/ ) {
                    push @{ $error_files{ $file->name } }, "matched $re at line $.";
                }
            }
        }
    }

    if (%error_files) {
        my $error_msg = "Aborting release; found merge conflict markers:\n";
        while ( my ($filename, $error) = each %error_files ) {
            $error_msg .= "$filename $_\n" for @$error;
        }
        $self->log_fatal( $error_msg );
    }

    $self->log('No merge conflict markers found; OK to release');
    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Chris Weyl Christian Doherty Etheridge Karen Mengué Mike Olivier Walde

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts - Check your repo for merge-conflicted files

=head1 VERSION

This document describes version 0.014 of Dist::Zilla::Plugin::Git::CheckFor::MergeConflicts - released October 10, 2016 as part of Dist-Zilla-PluginBundle-Git-CheckFor.

=head1 SYNOPSIS

    ; in dist.ini
    [Git::CheckFor::MergeConflicts]

=head1 DESCRIPTION

This is a simple L<Dist::Zilla> plugin to check that the gathered files
contain no merge conflict markers.

=for Pod::Coverage before_release mvp_multivalue_args

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Dist::Zilla::PluginBundle::Git::CheckFor|Dist::Zilla::PluginBundle::Git::CheckFor>

=item *

L<Dist::Zilla>

=item *

L<Dist::Zilla::Plugin::Git::CheckFor>

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

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Chris Weyl.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
