package Lingua::ZH::CEDICT;

# Copyright (c) 2002-2005 Christian Renz <crenz@web42.com>
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

# $Id: CEDICT.pm,v 1.5 2002/08/13 19:06:07 crenz Exp $

use 5.006;
use bytes;
use strict;
use warnings;
use vars qw($VERSION @ISA);

$VERSION = '0.04';
@ISA = ();

sub new {
    my $class = shift;
    my $self = +{@_};

    $self->{source} ||= 'Storable';

    # load data interface module
    my $if = "$class\::$self->{source}";
    (my $file = $if) =~ s|::|/|g;
    require "$file.pm";

    # let others do the blessing
    return $if->new(%{$self});
}

sub exportData {
    my ($self) = @_;
    my $data;

    foreach (qw(version entry keysZh keysPinyin keysEn)) {
        $data->{$_} = $self->{$_};
    }

    return $data;
}

sub numEntries {
    my ($self) = @_;

    return scalar @{$self->{entry}};
}

sub version {
    my ($self) = @_;

    return $self->{version};
}

sub generateKeywords {
    my ($self) = @_;

    $self->{keysZh} = {};
    $self->{keysPinyin} = {};
    $self->{keysEn} = {};

    my ($zh, $p, $en);

    foreach (0..($self->numEntries - 1)) {
        my $e = $self->{entry}->[$_];
        push @{$self->{keysZh}->{$e->[0]}}, $_; $zh++;
        if (defined($e->[1]) && ($e->[1])) {
            push @{$self->{keysZh}->{$e->[1]}}, $_;
            $zh++;
        }
        push @{$self->{keysPinyin}->{$e->[3]}}, $_; $p++;

        foreach my $k ($self->englishToKeywords($e->[4])) {
            push @{$self->{keysEn}->{$k}}, $_;
            $en++;
        }
    }
}

sub applyPinyinFormat {
    my ($self, $sub) = @_;

    $sub ||= \&utf8Pinyin;

    foreach (0..($self->numEntries - 1)) {
        $self->{entry}->[$_]->[2] =
            &$sub($self->{entry}->[$_]->[2]);
    }
}

sub applyEnglishFormat {
    my ($self, $sub) = @_;

    $sub ||= \&formatEnglish;

    foreach (0..($self->numEntries - 1)) {
        $self->{entry}->[$_]->[4] =
            &$sub($self->{entry}->[$_]->[4]);
    }
}

sub addSimpChar {
    my ($self) = @_;

    $self->{HanConvert} ||= "Lingua::ZH::CEDICT::HanConvert";
    (my $filename = $self->{HanConvert} . ".pm") =~ s|::|/|g;
    my $lib = $self->{HanConvert};

    require $filename;
    import $lib 'simple';


    foreach (@{$self->{entry}}) {
        my $s = simple($_->[0]);
        $_->[1] = $s unless ($s eq $_->[0]);
    }
}

# just for completeness' sake, should not really be necessary
sub addTradChar {
    my ($self) = @_;

    $self->{HanConvert} ||= "Lingua::ZH::HanConvert";
    (my $filename = $self->{HanConvert} . ".pm") =~ s|::|/|g;
    my $lib = $self->{HanConvert};

    require $filename;
    import $lib 'trad';

    foreach (@{$self->{entry}}) {
        my $t = trad($_->[0]);
        if ($t ne $_->[0]) {
            $_->[1] = $_->[0];
            $_->[0] = $t;
        }
    }
}

# Functions for accessing the dictionary ************************************

sub entry {
    my ($self, $num) = @_;
    return $self->{entry}->[$num];
}

sub keysEn {
    my ($self) = @_;

    return $self->{keysEn};
}

sub keysZh {
    my ($self) = @_;

    return $self->{keysZh};
}

sub keysPinyin {
    my ($self) = @_;

    return $self->{keysPinyin};
}

sub startMatch {
    my ($self, $term) = @_;

    $self->{_matchPos} = 0;
    $self->{_matchTerm} = $term;
}

# returns a reference to the first/following entry that matches
sub match {
    my ($self) = @_;
    my $term = $self->{_matchTerm};

    while ($self->{_matchPos} < $self->numEntries) {
        $self->{_matchPos}++;
        my $e = $self->{entry}->[$self->{_matchPos} - 1];
        return $e
            if (($e->[0] =~ /$term/) or
                ($e->[1] =~ /$term/) or
                ($e->[2] =~ /\b$term\b/i) or
                ($e->[3] =~ /\b$term\b/i) or
                ($e->[4] =~ /\b$term\b/i));
    }

    # nothing found
    return undef;
}

sub startFind {
    my ($self, $term) = @_;

    $self->{_findPos} = 0;
    $self->{_findTerm} = $term;
}

# returns a reference to the first/following entry that matches
sub find {
    my ($self) = @_;
    my $term = $self->{_findTerm};

    while ($self->{_findPos} < $self->numEntries) {
        $self->{_findPos}++;
        my $e = $self->{entry}->[$self->{_findPos} - 1];
        return $e
            if (($e->[0] eq $term) or
                ($e->[1] eq $term) or
                ($e->[2] =~ /^$term$/i) or
                ($e->[3] =~ /^$term$/i) or
                ($e->[4] =~ /^$term$/i));
    }

    # nothing found
    return undef;
}

# Formatting ****************************************************************

my %xlat =
    (a1    => "ā", e1    => "ē", i1    => "ī",
     o1    => "ō", u1    => "ū", 'v1'  => "ǖ",
     a2    => "á", e2    => "é", i2    => "í",
     o2    => "ó", u2    => "ú", 'v2'  => "ǘ",
     a3    => "ǎ", e3    => "ě", i3    => "ǐ",
     o3    => "ǒ", u3    => "ǔ", 'v3'  => "ǚ",
     a4    => "à", e4    => "è", i4    => "ì",
     o4    => "ò", u4    => "ù", 'v4'  => "ǜ",
     a5    => 'a',  e5    => 'e',  i5    => 'i',
     o5    => 'o',  u5    => 'u',  'v5'  => 'ü');

sub utf8Pinyin {
    my ($self, $p) = @_;
    $p = $self unless ref($self);

    # normalize u: and v to v
    $p =~ s/u:/v/g;

    $p =~ s/([iuv]?)([aeiouv])([a-z]*)([1-5])/$1$xlat{"$2$4"}$3/g;
    return $p;
}

sub formatEnglish {
    my ($self, $en) = @_;
    $en = $self unless ref($self);

    my $separator = " · ";
#    my $separator = "/";

#    $en =~ s|/|$separator|g;
#    return $en;

    my @terms = split m|/|, $en;

    foreach (0..$#terms) {
        $terms[$_] =~ s|\(([^(]+)\)$|<i>$1</i>|;
    }

    return join($separator, @terms);
}

sub removePinyinTones {
    my ($self, $p) = @_;

    $p =~ s/[12345]//g;
    $p =~ s/(u:|v)/u/g;

    return $p;
}

sub englishToKeywords {
    my ($self, $en) = @_;
    my @kw;

    foreach (split(m|/|, $en)) {
        next if /^\([^()]+\)$/;

        # remove trailing explanation in brackets
        s/\s+\([^(]+\)$//;
        s/^\(?(to|the|a|an|to be)\)?\s+//i;

        # remove characters we don't like in keywords
        s|[^-a-zA-Z0-9 /.]||g;
        s|^\.+||;
#        s!(\w|\d|\s|-|/)!!g;

        # remove leading and trailing and multiple whitespace
        s/^\s+//;
        s/\s+$//;
        s/\s\s+/ /g;

        # definitions like "(a sense of) uncertainty"
        if (/^\((.+?)\)\s+(.+)$/) {
            push @kw, uc($2);
            push @kw, uc("$1 $2");
        } else {
            push @kw, uc($_);
        }
    }

    # return non-empty keywords
    return grep /\w/, @kw;
}

1;
__END__

=head1 NAME

Lingua::ZH::CEDICT - Interface for CEDICT, a Chinese-English dictionary

=head1 SYNOPSIS

  use Lingua::ZH::CEDICT;

  my $dict = Lingua::ZH::CEDICT->new();
  $dict->init();

  $dict->startMatch('house');
  while (my $e = $dict->match()) {
      #      trad    simp    pinyin pinyin w/o tones  english
      print "$e->[0] $e->[1] [$e->[2] / $e->[3]] $e->[4]\n";
  }

=head1 DESCRIPTION

Lingua::ZH::CEDICT is an interface for CEDICT.b5, a Chinese-English dictionary file that may be freely used for non-commercial purposes.
This is an alpha release; API and features are not finalized. If you intend to use this package, please contact me so I can acommodate your needs.

The dictionary is included as a Storable v2.4 file. Please see the bin/ directory in the distribution to see how to import a new version of the dictionary.

=head1 CONSTRUCTOR

=head2 C<new>

C<new(%hash)> will create a new dictionary object. It accepts the following
keys:

=over 4

=item C<source>

(Default: Storable) Type of input for the module. Currently available interfaces are C<Textfile>, C<Storable> and C<MySQL>. See the POD for these modules for details on their configuration.

=item C<HanConvert>

(Default: Lingua::ZH::CEDICT::HanConvert) The module used for the conversion of simple to traditional characters and vice versa.

=back


=head1 METHODS

=over 4

=item C<numEntries()>

Returns the number of entries in the dictionary. One entry is a unique (characters, pinyin) pair with english translations.

=item C<version()>

Returns the version string from the dictionary file used.

=back

=head2 RETRIEVING DATA

=over 4

=item C<entry($number)>

Returns the $number entry in the dictionary (0-based, of course).

=item C<startMatch($key)>

Starts an inexact search using the searchkey $key.

=item C<match()>

Returns a reference to the next matching entry.

=item C<startFind($key)>

Starts an exact search using the searchkey $key.

=item C<find()>

Returns a reference to the next exactly matching entry.

=item C<exportData()>

Returns a list of hashes of all the data in the dictionary.

=back

=head2 MANIPULATING DATA AND FORMATTING

=over 4

=item C<addSimpChar>

Call the C<simple> method of the C<HanConvert> module specified to add a conversion to simplified characters to each entry.

=item C<addTradChar>

Call the C<trad> method of the C<HanConvert> module specified to add a conversion to traditional characters to each entry.

=item C<applyPinyinFormat($coderef)>

Formats the pinyin for all entries. If no code ref is supplied, uses utf8Pinyin.

=item C<applyEnglishFormat($coderef)>

Formats the English translation for all entries. If no code ref is supplied, uses formatEnglish.

=item C<utf8Pinyin($text)>

Changes tone numbers to UTF-8-encoded tone marks.

=item C<removePinyinTones>

Removes the (numeric, not UTF-8) tone marks from a pinyin string.

=item C<formatEnglish($text)>

Changes '/' to a dot as delimiter and HTML-italicizes comments in brackets.

=item C<englishToKeywords>

Attempts to create a keyword list out of the English definition.

=back

=head2 KEYWORD METHODS

For some applications, a concept of keywords is useful. A keyword is a unique entry in the dictionary. For example, for the pinyin keywords the tonemarks are removed. The keyword "zi" encompasses all translations of a character with the pronunciation zi[1-5].

=over 4

=item C<generateKeywords()>

Generate the keywords hashes. Use before you apply formatting.

=item C<keysEn()>

Return a hash with the keys being the english keywords and the values references to an array of indizes of the entries where the keyword is mentioned.

=item C<keysPinyin()>

Return a hash with the keys being the pinyin keywords and the values references to an array of indizes of the entries where the same pronunciation is used (without tones).

=item C<keysZh()>

Return a hash with the keys being the Chinese character keywords and the values references to an array of indizes of the entries where this term is translated. If the data contains both traditional and simplified characters, this hash will include both forms.

=back

=head1 AUTHOR

Christian Renz, E<lt>crenz@web42.comE<gt>

=head1 LICENSE

Copyright (C) 2002-2005 Christian Renz. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Lingua::ZH::CEDICT::Textfile|Lingua::ZH::CEDICT::Textfile>
L<Lingua::ZH::CEDICT::Storable|Lingua::ZH::CEDICT::Storable>
L<Lingua::ZH::CEDICT::MySQL|Lingua::ZH::CEDICT::MySQL>
L<Lingua::ZH::CEDICT::HanConvert|Lingua::ZH::CEDICT::HanConvert>
L<http://www.mandarintools.com/cedict.html>.
L<http://www.web42.com/zidian/>.

=cut
