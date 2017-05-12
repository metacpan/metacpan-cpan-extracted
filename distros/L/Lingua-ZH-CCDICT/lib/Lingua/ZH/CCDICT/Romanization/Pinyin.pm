package Lingua::ZH::CCDICT::Romanization::Pinyin;

use strict;
use warnings;

use base 'Lingua::ZH::CCDICT::Romanization';

my $umlaut_u = chr(252);

my %PinyinUnicode =
    ( a1 => chr(257),
      e1 => chr(275),
      i1 => chr(299),
      o1 => chr(333),
      u1 => chr(363),
      "${umlaut_u}1" => chr(470),

      a2 => chr(225),
      e2 => chr(233),
      i2 => chr(237),
      o2 => chr(243),
      u2 => chr(250),
      "${umlaut_u}2" => chr(472),

      a3 => chr(462),
      e3 => chr(283),
      i3 => chr(464),
      o3 => chr(466),
      u3 => chr(468),
      "${umlaut_u}3" => chr(474),

      a4 => chr(224),
      e4 => chr(232),
      i4 => chr(236),
      o4 => chr(242),
      u4 => chr(249),
      "${umlaut_u}4" => chr(476),
    );


sub new
{
    my $self = shift->SUPER::new(@_);

    # handle errors found in parent class
    return unless defined $self->{syllable};

    # there are a bunch of lX, mX, and nX, as well as one ng3
    return if $self->{syllable} =~ /^(?:l|m|n|ng)\d$/;

    $self->{ascii} = $self->{syllable};
    $self->{syllable} =~ s/uu/$umlaut_u/g;

    $self->_make_unicode_version();

    return $self;
}

sub as_ascii { $_[0]->{ascii} }

sub _make_unicode_version
{
    my $self = shift;

    my @syls = split /(?<=\d)/, $self->{syllable};

    $self->{pinyin_unicode} =
        join '', map { $self->_pinyin_as_unicode($_) } @syls;

    return $self;
}

sub _pinyin_as_unicode
{
    my $self = shift;
    my $syl = shift;

    my $num = chop $syl;

    unless ( $num =~ /[12345]/ )
    {
        warn "Bad pinyin (tone): $self->{syllable}\n" if $ENV{DEBUG_CCDICT_SOURCE};
        return;
    }

    # no tone marking
    return $syl if $num == 5;

    my @letters = split //, $syl;

    my $vowel_to_change;
    for ( my $x = 0; $x <= $#letters; $x++ )
    {
        if ( $letters[$x] =~ /[aeiou$umlaut_u]/ )
        {
            $vowel_to_change = $x;
            last;
        }
    }

    unless ( defined $vowel_to_change )
    {
        warn "Bad pinyin (no vowel to mark): $self->{syllable}\n" if $ENV{DEBUG_CCDICT_SOURCE};
        return;
    }

    if ( $letters[$vowel_to_change + 1] &&
         $letters[$vowel_to_change + 1] =~ /[aeiou$umlaut_u]/ )
    {
        # handle multiple vowels properly
        $vowel_to_change++
            unless ( $letters[$vowel_to_change + 1] eq 'u' ||
                     $letters[$vowel_to_change + 1] eq 'o' );
    }

    $letters[$vowel_to_change] = $PinyinUnicode{ $letters[$vowel_to_change] . $num };

    return join '', @letters;
}

sub as_unicode { $_[0]->{pinyin_unicode} }


1;

__END__


=head1 NAME

Lingua::ZH::CCDICT::Romanization::Pinyin - A pinyin romanization of a Chinese character

=head1 SYNOPSIS

  print $pinyin->syllable();
  print $pinyin->as_ascii();
  print $pinyin->as_unicode();

=head1 DESCRIPTION

The C<Lingua::ZH::CCDICT::Romanization::Pinyin> class is used for the
return values of the C<Lingua::ZH::CCDICT::ResultItem> class's
C<tongyong> method, and provides the following additional methods:

=head2 $pinyin->syllable()

This returns the syllable with the tone markings appended as a number
at the end, but it may contain a u with an umlaut.

=head2 $pinyin->as_ascii()

Returns the syllable as ascii. The tone is appended as a number, and a
u with an umlaut is represented as two u's in row.

=head2 $pinyin->as_unicode()

The syllable with the tone marking represented as diacritics using
Unicode characters.

=head1 AUTHOR

David Rolsky <autarch@urth.org>

=head1 COPYRIGHT

Copyright (c) 2002-2007 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut
