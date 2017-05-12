#
# This file is part of Dist-Zilla-Plugin-NoSmartCommentsTests
#
# This software is Copyright (c) 2011 by Chris Weyl.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Dist::Zilla::Plugin::NoSmartCommentsTests;
our $AUTHORITY = 'cpan:RSRCHBOY';
# git description: 0.008-9-g4f29d74
$Dist::Zilla::Plugin::NoSmartCommentsTests::VERSION = '0.009';

# ABSTRACT: Make sure no Smart::Comments escape into the wild

use Moose;
use namespace::autoclean;
use MooseX::AttributeShortcuts;

use autobox::Core;

extends 'Dist::Zilla::Plugin::InlineFiles';

with
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [qw { :InstallModules :ExecFiles :TestFiles }],
    },
    'Dist::Zilla::Role::TextTemplate',
    'Dist::Zilla::Role::PrereqSource',
    ;


sub register_prereqs {
    my $self = shift @_;

    $self->zilla->register_prereqs(
        { phase => 'develop' },
        'Test::NoSmartComments' => 0,
    );

    return;
}

around merged_section_data => sub {
    my ($orig, $self) = (shift, shift);

    ### invoke the original to get the sections...
    my $data = $self->$orig(@_);

    ### bail if no data...
    return unless $data;

    ### munge each section with our template engine...
    my %stash = ( files => [ map { $_->name } $self->found_files->flatten ] );
    do { $data->{$_} = \( $self->fill_in_string(${$data->{$_}}, { %stash }) ) }
        for $data->keys;

    ### $data
    return $data;
};

__PACKAGE__->meta->make_immutable;
!!42;

=pod

=encoding UTF-8

=for :stopwords Chris Weyl

=for :stopwords Wishlist flattr flattr'ed gittip gittip'ed

=head1 NAME

Dist::Zilla::Plugin::NoSmartCommentsTests - Make sure no Smart::Comments escape into the wild

=head1 VERSION

This document describes version 0.009 of Dist::Zilla::Plugin::NoSmartCommentsTests - released October 09, 2016 as part of Dist-Zilla-Plugin-NoSmartCommentsTests.

=head1 SYNOPSIS

    ; In C<dist.ini>:
    [Test::NoSmartComments]

=head1 DESCRIPTION

This is an extension of L<Dist::Zilla::Plugin::InlineFiles>, providing the
following file:

  xt/release/no-smart-comments.t - test to ensure no Smart::Comments

=head1 METHODS

=head2 register_prereqs

Registers a 'develop' phase requirement for L<Test::NoSmartComments> with the
L<Dist::Zilla> object.

=head1 NOTE

The name of this plugin has turned out to be somewhat misleading, I'm afraid:
we don't actually test for the _existance_ of smart comments, rather we
ensure that Smart::Comment is not used by any file checked.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

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
___[ xt/release/no-smart-comments.t ]___
#!/usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

eval "use Test::NoSmartComments";
plan skip_all => 'Test::NoSmartComments required for checking comment IQ'
    if $@;

{{ foreach my $file (@files) { $OUT .= qq{no_smart_comments_in("$file");\n} } }}
done_testing();
