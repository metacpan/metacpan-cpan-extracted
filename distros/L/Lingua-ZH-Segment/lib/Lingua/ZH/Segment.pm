# $Id: Segment.pm 1211 2005-03-10 14:10:14Z clsung $

package Lingua::ZH::Segment;
use strict;

use Encode::Guess;
our @ISA    = qw(Exporter);
our @EXPORT = qw(segment);
our $VERSION	= '0.02';

=head1 NAME

Lingua::ZH::Segment - Chinese Text Segmentation

=head1 VERSION

This document describes version 0.01 of Lingua::ZH::Segment, released
March 10, 2005.

=head1 SYNOPSIS

    use Lingua::ZH::Segment;

    print segment('降龍18掌'); # 降 龍 18 掌


=head1 DESCRIPTION

This module currently only break chinese text into single
character (Chinese word), it will not break up any alphabet.

=head1 METHODS

Currently, only C<segment> is available.

=cut

sub segment { 
    my $word = shift;
    my $decoder = guess_encoding ($word, qw/ utf8 big5 /);
    $word = $decoder->decode($word);
    my @segs = split /([A-z|\d]+|\S)/, $word;
    $word = join " ",@segs;
    $word =~ s/\s{2,}/ /g;
    $word =~ s/(^\s|\s$)//g;
    $word = $decoder->encode($word);
    return $word;
}

sub CLONE { }
sub DESTROY { }

1;

=head1 SEE ALSO

L<Encode::Guess>

=head1 AUTHORS

Cheng-Lung Sung E<lt>clsung@tw.freebsd.orgE<gt>

=head1 KUDOS

Hsin-Chan Chien for inspiring me about L<Encode::Guess>.

=head1 COPYRIGHT

Copyright 2005 by Cheng-Lung Sung E<lt>clsung@tw.freebsd.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
