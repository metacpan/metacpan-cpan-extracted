#!/usr/bin/perl
#-------------------------------------------------------------------------------
# List of languages and ISO 639 language codes supported by Google Translate
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc, 2017
#-------------------------------------------------------------------------------

package Google::Translate::Languages;
our $VERSION = '20190811';
use v5.8.0;
use warnings FATAL => qw(all);
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use ISO::639 v20171214;
use utf8;
use strict;

&generate unless caller;

#1 Languages and codes                                                          # [Language name, ISO639 2 character code, and ISO639 3 character code] in English for languages supported by Google Translate

sub supportedLanguages                                                          #S [Language name, ISO639 2 character code, and ISO639 3 character code] in English for languages supported by Google Translate
 {@{&languages}
 }

#0

sub splitListsOfLanguages($)                                                    ## Insert single languages from lists of languages
 {my ($l) = @_;                                                                 # Hash of language name lists to code
  for my $languages(keys %$l)
   {if ($languages =~ m([;,]))
     {my @l = split /\s*[;,]\s*/, $languages;
      for my $language(@l)
       {$l->{$language} = $l->{$languages};
       }
     }
   }
 }

sub additional2CharCodes
 {my ($l) = @_;                                                                 # Hash of language name lists to code
  $l->{Cebuano}        = "cb";                                                  # https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes - not present so I made it up
  $l->{Filipino}       = "tl";                                                  # https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes tagalog
  $l->{Frisian}        = "fy";                                                  # Only 2 char version
  $l->{Hawaiian}       = "hw";                                                  # https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes - not present so I made it up
  $l->{Hmong}          = "hm";                                                  # https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes - not present so I made it up
  $l->{Khmer}          = "km";
  $l->{Norwegian}      = "nb";                                                  # Could be nb or nn but Aws::Polly::Select uses nb so we do here too for consistency
  $l->{"Scots Gaelic"} = "gd";
  $l->{Sesotho}        = "st";                                                  # Only 2 char version
 }

sub additional3CharCodes
 {my ($l) = @_;                                                                 # Hash of language name lists to code
  $l->{Frisian}        = "fry";                                                 # Chosen from 3 because there is a corresponding two char code
  $l->{Khmer}          = "khm";
  $l->{"Scots Gaelic"} = "gla";
  $l->{Sesotho}        = "sot";                                                 # Chosen from 2 because there is a corresponding two char code
 }

sub generate                                                                    ## Generate the language code tables from the raw data
 {my @l  = map{trim($_)} split /\n/, &raw;                                      # Split the raw data into lines of <td>

  my %c2 = %{&ISO::639::languageFromCode2};
  my %c3 = %{&ISO::639::languageFromCode3};

  splitListsOfLanguages($_) for \%c2, \%c3;

  additional2CharCodes(\%c2);
  additional3CharCodes(\%c3);

  my @L;
  for my $languageName(@l)
   {my $c2 = $c2{$languageName};
    my $c3 = $c3{$languageName};
    !$c2 and warn "No 2 character code for $languageName";
    !$c3 and warn "No 3 character code for $languageName";
    push @L, [$languageName =~ s(\s+) ()gsr, $c2, $c3];                         # Remove blanks from language names
   }

  my $d = dump(\@L);
  $d =~ s(\n) ( )gs;

  my $s = <<END;
sub languages{$d}
END
  say STDERR "New version written to:\n", owf("zzz.data", $s);                  # Write new table for manual replacement in this file at: sub languages just below as
 }

# Language table goes here
sub languages{[   ["Afrikaans", "af", "afr"],   ["Albanian", "sq", "alb"],   ["Amharic", "am", "amh"],   ["Arabic", "ar", "ara"],   ["Armenian", "hy", "arm"],   ["Azerbaijani", "az", "aze"],   ["Basque", "eu", "baq"],   ["Belarusian", "be", "bel"],   ["Bengali", "bn", "ben"],   ["Bosnian", "bs", "bos"],   ["Bulgarian", "bg", "bul"],   ["Burmese", "my", "bur"],   ["Catalan", "ca", "cat"],   ["Cebuano", "cb", "ceb"],   ["Chichewa", "ny", "nya"],   ["Chinese", "zh", "chi"],   ["Corsican", "co", "cos"],   ["Croatian", "hr", "hrv"],   ["Czech", "cs", "ces"],   ["Danish", "da", "dan"],   ["Dutch", "nl", "dum"],   ["English", "en", "enm"],   ["Esperanto", "eo", "epo"],   ["Estonian", "et", "est"],   ["Filipino", "tl", "fil"],   ["Finnish", "fi", "fin"],   ["French", "fr", "fro"],   ["Frisian", "fy", "fry"],   ["Galician", "gl", "glg"],   ["Georgian", "ka", "geo"],   ["German", "de", "goh"],   ["Greek", "el", "ell"],   ["Gujarati", "gu", "guj"],   ["HaitianCreole", "ht", "hat"],   ["Hausa", "ha", "hau"],   ["Hawaiian", "hw", "haw"],   ["Hebrew", "he", "heb"],   ["Hindi", "hi", "hin"],   ["Hmong", "hm", "hmn"],   ["Hungarian", "hu", "hun"],   ["Icelandic", "is", "ice"],   ["Igbo", "ig", "ibo"],   ["Indonesian", "id", "ind"],   ["Irish", "ga", "sga"],   ["Italian", "it", "ita"],   ["Japanese", "ja", "jpn"],   ["Javanese", "jv", "jav"],   ["Kannada", "kn", "kan"],   ["Kazakh", "kk", "kaz"],   ["Khmer", "km", "khm"],   ["Korean", "ko", "kor"],   ["Kurdish", "ku", "kur"],   ["Kyrgyz", "ky", "kir"],   ["Lao", "lo", "lao"],   ["Latin", "la", "lat"],   ["Latvian", "lv", "lav"],   ["Lithuanian", "lt", "lit"],   ["Luxembourgish", "lb", "ltz"],   ["Macedonian", "mk", "mac"],   ["Malagasy", "mg", "mlg"],   ["Malay", "ms", "msa"],   ["Malayalam", "ml", "mal"],   ["Maltese", "mt", "mlt"],   ["Maori", "mi", "mri"],   ["Marathi", "mr", "mar"],   ["Mongolian", "mn", "mon"],   ["Nepali", "ne", "nep"],   ["Norwegian", "nb", "nno"],   ["Pashto", "ps", "pus"],   ["Persian", "fa", "peo"],   ["Polish", "pl", "pol"],   ["Portuguese", "pt", "por"],   ["Punjabi", "pa", "pan"],   ["Romanian", "ro", "ron"],   ["Russian", "ru", "rus"],   ["Samoan", "sm", "smo"],   ["ScotsGaelic", "gd", "gla"],   ["Serbian", "sr", "srp"],   ["Sesotho", "st", "sot"],   ["Shona", "sn", "sna"],   ["Sindhi", "sd", "snd"],   ["Sinhala", "si", "sin"],   ["Slovak", "sk", "slk"],   ["Slovenian", "sl", "slv"],   ["Somali", "so", "som"],   ["Spanish", "es", "spa"],   ["Sundanese", "su", "sun"],   ["Swahili", "sw", "swa"],   ["Swedish", "sv", "swe"],   ["Tajik", "tg", "tgk"],   ["Tamil", "ta", "tam"],   ["Telugu", "te", "tel"],   ["Thai", "th", "tha"],   ["Turkish", "tr", "ota"],   ["Ukrainian", "uk", "ukr"],   ["Urdu", "ur", "urd"],   ["Uzbek", "uz", "uzb"],   ["Vietnamese", "vi", "vie"],   ["Welsh", "cy", "cym"],   ["Xhosa", "xh", "xho"],   ["Yiddish", "yi", "yid"],   ["Yoruba", "yo", "yor"],   ["Zulu", "zu", "zul"], ]}

# Raw data from inside table goes here
sub raw {<<END}
Afrikaans
Albanian
Amharic
Arabic
Armenian
Azerbaijani
Basque
Belarusian
Bengali
Bosnian
Bulgarian
Burmese
Catalan
Cebuano
Chichewa
Chinese
Corsican
Croatian
Czech
Danish
Dutch
English
Esperanto
Estonian
Filipino
Finnish
French
Frisian
Galician
Georgian
German
Greek
Gujarati
Haitian Creole
Hausa
Hawaiian
Hebrew
Hindi
Hmong
Hungarian
Icelandic
Igbo
Indonesian
Irish
Italian
Japanese
Javanese
Kannada
Kazakh
Khmer
Korean
Kurdish
Kyrgyz
Lao
Latin
Latvian
Lithuanian
Luxembourgish
Macedonian
Malagasy
Malay
Malayalam
Maltese
Maori
Marathi
Mongolian
Nepali
Norwegian
Pashto
Persian
Polish
Portuguese
Punjabi
Romanian
Russian
Samoan
Scots Gaelic
Serbian
Sesotho
Shona
Sindhi
Sinhala
Slovak
Slovenian
Somali
Spanish
Sundanese
Swahili
Swedish
Tajik
Tamil
Telugu
Thai
Turkish
Ukrainian
Urdu
Uzbek
Vietnamese
Welsh
Xhosa
Yiddish
Yoruba
Zulu
END
# podDocumentation

=pod

=encoding utf-8

=head1 Name

Google::Translate::Languages - The languages supported by Google Translate.

=head1 Synopsis

Produces a list of all the languages currently supported by Google Translate.

 my @l = grep {$$_[0] =~ m(spanish)i}
         &Google::Translate::Languages::supportedLanguages;

 say STDERR dump(@l);

 # ["Spanish", "es", "spa"]

Returns an array of:

 [Language name, ISO639 2 character code, and ISO639 3 character code]

describing the languages currently supported by Google Translate as listed on:

 https://en.wikipedia.org/wiki/Google_Translate#Supported_languages

The language codes corresponding to each language are produced via: L<ISO::639>

=head1 Description

The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Languages and codes

[Language name, ISO639 2 character code, and ISO639 3 character code] in
English for languages supported by Google Translate

=head2 supportedLanguages()

[Language name, ISO639 2 character code, and ISO639 3 character code] in
English for languages supported by Google Translate


This is a static method and so should be invoked as:

  Google::Translate::Languages::supportedLanguages



=head1 Index


1 L<supportedLanguages|/supportedLanguages>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard L<Module::Build> process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
# podDocumentation
__DATA__
use warnings FATAL=>qw(all);
use strict;
use Test::More tests=>1;

binModeAllUtf8;

is_deeply ["Spanish", "es", "spa"], grep {$$_[0] =~ m(spanish)i}  &Google::Translate::Languages::supportedLanguages;
