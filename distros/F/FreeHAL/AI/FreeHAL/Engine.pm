#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::FreeHAL::Engine;

=head1 NAME

AI::FreeHAL::Engine - Engine of FreeHAL, a self-learning conversation simulator which uses semantic nets to organize its knowledge.

=head1 SYNOPSIS

  runner.pl shell
  
=head1 DESCRIPTION

FreeHAL is a self-learning conversation simulator which uses semantic nets to organize its knowledge.

FreeHAL uses a semantic network, pattern matching, stemmers, part of speech databases, part of speech taggers, and Hidden Markov Models, in order to imitate a very close human behavior within conversations. Online- as Download-Versions are supporting the synthesing of the speech. Through communicating (via keyboard) the program enhances his knowledge-database.
It supports the languages German and English.

In opposite to the most free and commercial chatbots FreeHAL learns self-reliant conception of causal relations on its own.

FreeHAL runs on Microsoft Windows, GNU/Linux, Unix, BSD and Mac and is licensed under the GNU GPL v3.


This package contains:

=over 4

=item 1. AI::Util
=item 2. AI::SemanticNetwork
=item 3. AI::POS
=item 4. AI::Selector
=item 5. AI::FreeHAL::Module::Tagger

=back

=head1 FUNCTIONS

=cut

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    @ISA = qw(Exporter);

    # functions
    @EXPORT      = qw();
    %EXPORT_TAGS = ();     # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw();
}

local $| = 1;

use strict;
use warnings;

unshift @INC, ( '.', 'lib', 'site/lib' );

use Socket;
use threads;
use threads::shared;

use Data::Dumper;
use List::Util 'shuffle';
use AI::FreeHAL::Config;
use IO::Socket;
use Lingua::DE::Tagger;
use Lingua::EN::Tagger;
#use YAML::Tiny;
use File::Copy::Recursive qw{dircopy};
use Storable qw(dclone);
use Algorithm::Diff qw(diff);
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Storable qw(store retrieve freeze thaw dclone nfreeze);
use XML::RSS::Parser::Lite;
use LWP::Simple;

eval 'use Compress::Zlib;';
warn $@ if $@;

use AI::Util;
use AI::SemanticNetwork;
use AI::POS;
use AI::Selector;
#use AI::Tagger;

our $temp_selector =
  AI::Selector->new( get_time_measurements => \&get_time_measurements );

our $data = AI::Util::get_data();

#*AI::Tagger::data = *data;
*AI::Util::data   = *data;

$data->{functions} = {};

$data->{const}{NO_POS}       = 1;
$data->{const}{POS_UNKNOWN}  = 2;
$data->{const}{VERB}         = 3;
$data->{const}{NOUN}         = 4;
$data->{const}{ADJ}          = 5;
$data->{const}{PREP}         = 6;
$data->{const}{PP}           = 7;
$data->{const}{ART}          = 8;
$data->{const}{QUESTIONWORD} = 9;
$data->{const}{KOMMA}        = 10;
$data->{const}{SPO}          = 11;
$data->{const}{UNIMPORTANT}  = 12;
$data->{const}{LINKING}      = 13;
$data->{const}{INTER}        = 14;

use vars qw($VERSION);

$VERSION                      = "71";
$data->{intern}{FULL_VERSION} = $VERSION;
$data->{intern}{NAME}         = 'FreeHAL rev. ' . $data->{intern}{FULL_VERSION};
no strict;
$data->{intern}{dir}                    = $::dir                    || './';
$data->{intern}{cgi_mode_but_superuser} = $::cgi_mode_but_superuser || 0;
$data->{intern}{in_cgi_mode}            = $::in_cgi_mode            || 0;
$data->{intern}{unix_shell_mode}        = $::unix_shell_mode        || 0;
use strict;

$data->{modes}{batch}                   = (-f 'do-batch') || (-f './do-batch') || $AI::Util::batch || $::batch || $main::batch || 0;

#use Devel::Size qw(size total_size);
#use Devel::DumpSizes qw/dump_sizes/;

opendir my $usr_local_perl_dir, '/usr/local/share/perl';
push @INC, ( '/usr/local/share/perl', readdir $usr_local_perl_dir );
closedir $usr_local_perl_dir;

if ( !-d $data->{intern}{dir} . '/lang_de' ) {
    foreach my $directory (@INC) {
        if ( -d $directory . '/lang_de' ) {
            $data->{intern}{dir} = $directory;
            $data->{intern}{dir} .= '/' if $data->{intern}{dir} !~ /\/$/;
            last;
        }
    }
}

$data->{intern}{config_file} = '';
my $home =
    $ENV{'HOME'}
  ? $ENV{'HOME'}
  : $ENV{'HOMEPATH'};

print "Directory:   $data->{intern}{dir}\n" if !$data->{intern}{in_cgi_mode};
if ( not mkdir $home . '/.jeliza' ) {
    warn( 'Cannot create config directory "' . $home . '/.jeliza": ' . $! )
      if ( $! !~ /exists/ );
}

$data->{intern}{config_file} = $home . '/.jeliza/jeliza.cfg';
if ( !-d $home . '/.jeliza/' ) {
    $data->{intern}{config_file} = './jeliza.cfg';
}

print "Checking if $home/.jeliza/ exists: " if !$data->{intern}{in_cgi_mode};
if (   -d $home . '/.jeliza/'
    && !$data->{intern}{in_cgi_mode}
    && $data->{intern}{unix_shell_mode} )
{
    print "OK\n" if !$data->{intern}{in_cgi_mode};
    if ( $data->{intern}{dir} !~ /^\./ ) {

        my ${is_already_there} =
          (      ( -d $home . '/.jeliza/lang_de' )
              && ( -d $home . '/.jeliza/lang_en' ) );

        my $success1 = $data->{lang}{is_already_there}
          || dircopy( $data->{intern}{dir} . '/lang_de',
            $home . '/.jeliza/lang_de' )
          || $!;
        my $success2 = $data->{lang}{is_already_there}
          || dircopy( $data->{intern}{dir} . '/lang_en',
            $home . '/.jeliza/lang_en' )
          || $!;

        if ( $success1 || $success2 ) {
            $data->{intern}{dir} = $home . '/.jeliza/';

            opendir( my $dir_handle, $data->{intern}{dir} );
            foreach my $filename ( readdir $dir_handle ) {
                next if $filename =~ /^\./;
                opendir( my $dir_handle_sub,
                    $data->{intern}{dir} . '/' . $filename );
                foreach my $filename_2 ( readdir $dir_handle_sub ) {
                    next if $filename_2 =~ /^\./;
                    chmod 0777,
                      $data->{intern}{dir} . '/' . $filename . '/' . $filename_2
                      or warn 'Cannot change permission of '
                      . $data->{intern}{dir} . '/'
                      . $filename . '/'
                      . $filename_2;
                }
                closedir $dir_handle_sub;
            }
            closedir $dir_handle;
        }
        else {
            warn "Cannot copy lang_xx files: $success1 $success2";
        }
    }
}
else {
    print "No.\n" if !$data->{intern}{in_cgi_mode};
}

if ($data->{modes}{batch}) {
    $data->{intern}{config_file} = 'jeliza.cfg';
}

print "Config file: $data->{intern}{config_file}\n"
  if !$data->{intern}{in_cgi_mode};
print "Directory:   $data->{intern}{dir}\n" if !$data->{intern}{in_cgi_mode};

if ( not( -f $data->{intern}{config_file} ) ) {
    open my $handle, ">", $data->{intern}{config_file};
    close $handle;
}

read_config $data->{intern}{config_file} => our %config;

#$data->{data}{yaml} = YAML::Tiny->new;

$data->{caches}{cache_noun_or_not} = ();

$data->{connection}{connected_clients}       = 0;
$data->{connection}{working_client_requests} = 0;

$data->{modes}{do_filter_results} = 1;

$data->{connection}{client_info} = {};
$data->{abilities} = {};

$data->{caches}{cache_semantic_net_get_key_for_item} = {};

$data->{persistent} = {};

$data->{batch}{batch_timeout}   = ( 25 * 60 ) + time;
our $batch_timeout = $data->{batch}{batch_timeout};
$data->{batch}{batch_starttime} = time;

$data->{lang}{is_inacceptable_questionword} = {
    "wenn"     => 1,
    "wer"      => 1,
    "who"      => 1,
    "falls"    => 1,
    "sobald"   => 1,
    "waehrend" => 1,
    "if"       => 1,
    "when"     => 1,
    "why"      => 1,
    "warum"    => 1,
    "wieso"    => 1,
    "weshalb"  => 1,
    "because"  => 1,
    "weil"     => 1,
    "dass"     => 1,

    #"welche"  => 1,
    #"welches" => 1,
    #"welcher" => 1,
    #"welchem" => 1,
    #"welchen" => 1,
};

$data->{lang}{is_linking} = {
    "und"  => 1,
    "or"   => 1,
    "and"  => 1,
    "oder" => 1,
    "&"    => 1,
};

$data->{lang}{is_linking_but_not_divide} = { "&" => 1, };

$data->{lang}{is_be} = {
    "am"     => 1,
    "is"     => 1,
    "are"    => 1,
    "be"     => 1,
    "was"    => 1,
    "were"   => 1,
    "bin"    => 1,
    "bist"   => 1,
    "ist"    => 1,
    "sein"   => 1,
    "war"    => 1,
    "sind"   => 1,
    "seid"   => 1,
    "heisst" => 1,
};

$data->{lang}{adverbs_of_time} = [
    qw{
      vorhin nachher vorher spaeter
      eben nun schon
      auch noch etwa ungefaehr ca
      mal
      denn
      dann

      gerne
      spaet
      frueh
      frueher
      spaeter
      fast

      eben endlich anfangs bald damals dann eher
      heutzutage mittlerweile neulich nun seitdem
      zugleich zuletzt schlieÃŸlich seither heute
      morgen gestern inzwischen jetzt Ã¼bermorgen
      vorerst vorhin abends danach frÃ¼her beizeiten
      hÃ¤ufig oft oftmals manchmal gelegentlich bisweilen
      zuweilen mitunter selten einmal zweimal dreimal
      mehrmals abends normalerweise nachts dienstags
      lange immer noch zeitlebens stets ewig
      always

      schon

      bisher

      weitgehend

      erstmals

      nahe

      lately
      never
      often
      rarely

      woanders

      kuenftig

      recently
      sometimes
      soon
      today

      tomorrow
      usually
      yesterday
      }
];

$data->{lang}{is_adverb_of_time} =
  { map { $_ => 1 } @{ $data->{lang}{adverbs_of_time} } };

$data->{lang}{is_if_word} = { map { $_ => 1 } qw{if wenn when falls sobald} };
$data->{lang}{is_something} = {
    map { $_ => 1 }
      qw{etwas es ihn er sie ihm ihr something someone anything anyone jemand jemanden it
      a b c d e f g h j}
};

$data->{lang}{is_not_acceptable_as_everything} =
  { map { $_ => 1 }
      qw{ kenne kennst kennen kenn finde find findest findst fand is am are be }
  };

#our $builtin_table = { };

$data->{lang}{constant_to_string} = {};

$data->{lang}{is_verb_prefix} =
  { map { $_ => 1 }
      qw {auf hin rauf herauf hinab hinunter an ab zusammen vor nach zurueck weg zer her zu in ueber unter neben herunter mit zwischen um durch aus fest ent frei er}
  };

$data->{lang}{regex_str_verb_prefixes} =
  join( '|', keys %{ $data->{lang}{is_verb_prefix} } );

$data->{lang}{string_to_constant} = {
    'prep'    => $data->{const}{PREP},
    'fw'      => $data->{const}{QUESTIONWORD},
    'verb'    => $data->{const}{VERB},
    'vt'      => $data->{const}{VERB},
    'vi'      => $data->{const}{VERB},
    'n'       => $data->{const}{NOUN},
    'f,m'     => $data->{const}{NOUN},
    'f,n'     => $data->{const}{NOUN},
    'f,n,m'   => $data->{const}{NOUN},
    'f,m,n'   => $data->{const}{NOUN},
    'm,f'     => $data->{const}{NOUN},
    'm,n'     => $data->{const}{NOUN},
    'm,f,n'   => $data->{const}{NOUN},
    'm,n,f'   => $data->{const}{NOUN},
    'm,'      => $data->{const}{NOUN},
    'f,'      => $data->{const}{NOUN},
    'n,'      => $data->{const}{NOUN},
    'inter'   => $data->{const}{INTER},
    'n,pl'    => $data->{const}{NOUN},
    'adj'     => $data->{const}{ADJ},
    'adv'     => $data->{const}{ADJ},
    'pron'    => $data->{const}{PP},
    'ppron'   => $data->{const}{NOUN},
    'nothing' => $data->{const}{UNIMPORTANT},
    'art'     => $data->{const}{ART},
};

$data->{lang}{build_builtin_table_cache} = {};

=head2 build_builtin_table($language)

Returns a hash reference containing word <-> part of speech pairs.

$language is a language string, e.g. "en" or "de".

=cut

sub build_builtin_table {
    my $lang = shift || 'de';

    if ($lang) {
        if ( $data->{lang}{build_builtin_table_cache}{$lang} ) {
            return $data->{lang}{build_builtin_table_cache}{$lang};
        }
    }

    my @numbers = (
        qw(
          eins zwei drei vier fuenf sechs sieben acht neun zehn elf zwoelf dreizehn vierzehn fuenfzehn sechzehn siebzehn
          achtzehn neunzehn zwanzig
          dreissig vierzig fuenfzig sechzig siebzig achzig neunzig hundert tausend zehntausend hunderttausend million millionen
          milliarde milliarden hunderte tausende

          erste zweite dritte vierte fuenfte sechste siebte achte neunte zehnte elfte zwoelfte dreizehnte vierzehnte fuenfzehnte sechzehnte
          siebzehnte achtzehnte neunzehnte zwanzigste
          )
    );

    my $builtin_table = {
        (
            map { $_ => $data->{const}{QUESTIONWORD} } (
                qw{was wer wie wo wen wem wieso weshalb warum wann welche welcher welchen welchem welches welch how why when whether if what which
                  who where },
                keys %{ $data->{lang}{is_inacceptable_questionword} }
            )
        ),
        'kann'             => $data->{const}{VERB},
        'anstatt'          => $data->{const}{QUESTIONWORD},
        'nachdem'          => $data->{const}{QUESTIONWORD},
        'weltweit'         => $data->{const}{ADJ},
        'zusammen'         => $data->{const}{ADJ},
        'stark'            => $data->{const}{ADJ},
        'intelligent'      => $data->{const}{ADJ},
        'ohne'             => $data->{const}{PREP},
        'liegt'            => $data->{const}{VERB},
        'liegst'           => $data->{const}{VERB},
        'liegen'           => $data->{const}{VERB},
        'liege'            => $data->{const}{VERB},
        'weder'            => $data->{const}{PREP},
        'bilden'           => $data->{const}{VERB},
        'bestehen'         => $data->{const}{VERB},
        'druesenendstueck' => $data->{const}{NOUN},
        'noch'             => $data->{const}{PREP},
        'tiere'            => $data->{const}{NOUN},
        'ab'               => $data->{const}{PREP},
        'intakt'           => $data->{const}{ADJ},
        'jeweils'          => $data->{const}{PREP},
        'wird'             => $data->{const}{VERB},
        'wirst'            => $data->{const}{VERB},
        'werden'           => $data->{const}{VERB},
        'sowohl'           => $data->{const}{PREP},
        'sowie'            => $data->{const}{PREP},
        'beruht'           => $data->{const}{VERB},
        'beruhen'          => $data->{const}{VERB},
        'gehirn'           => $data->{const}{NOUN},
        'hirn'             => $data->{const}{NOUN},
        'bilden'           => $data->{const}{VERB},
        'bildet'           => $data->{const}{VERB},
        'bilde'            => $data->{const}{VERB},
        'hackt'            => $data->{const}{VERB},
        'tal'              => $data->{const}{NOUN},
        'wohne'            => $data->{const}{VERB},
        'wohnst'           => $data->{const}{VERB},
        'wohnt'            => $data->{const}{VERB},
        'werde'            => $data->{const}{VERB},
        'geht'             => $data->{const}{VERB},
        'sondern'          => $data->{const}{PREP},
        'meinen'           => $data->{const}{VERB},
        'meint'            => $data->{const}{VERB},
        'gross'            => $data->{const}{ADJ},
        'klein'            => $data->{const}{ADJ},
        'beispielsweise'   => $data->{const}{ADJ},
        'beschlossen'      => $data->{const}{VERB},
        'barock'           => $data->{const}{NOUN},
        'barocke'          => $data->{const}{ADJ},
        'beiderseits'      => $data->{const}{ADJ},
        'ebenfalls'        => $data->{const}{ADJ},
        'aber'             => $data->{const}{QUESTIONWORD},
        'jedoch'           => $data->{const}{QUESTIONWORD},
        'wohingegen'       => $data->{const}{QUESTIONWORD},
        'uebernahm'        => $data->{const}{VERB},
        'benachbart'       => $data->{const}{ADJ},
        'benachbarte'      => $data->{const}{ADJ},
        'teils'            => $data->{const}{PREP},
        'insoweit'         => $data->{const}{ADJ},
        'existiert'        => $data->{const}{VERB},
        'io'               => $data->{const}{NOUN},
        'schneller'        => $data->{const}{ADJ},
        'besonders'        => $data->{const}{ADJ},
        'besonderes'       => $data->{const}{ADJ},
        'besonderen'       => $data->{const}{ADJ},
        'besonderer'       => $data->{const}{ADJ},
        'besonderem'       => $data->{const}{ADJ},
        'besondere'        => $data->{const}{ADJ},
        'offenbar'         => $data->{const}{ADJ},
        'hauptstadt'       => $data->{const}{NOUN},
        'en'               => $data->{const}{NOUN},
        'seit'             => $data->{const}{PREP},
        'gern'             => $data->{const}{ADJ},
        'folgende'         => $data->{const}{ADJ},
        'stirbt'           => $data->{const}{VERB},
        'kalte'            => $data->{const}{ADJ},
        'kalt'             => $data->{const}{ADJ},
        'mund'             => $data->{const}{NOUN},
        '='                => $data->{const}{VERB},
        '=='               => $data->{const}{VERB},
        '=>'               => $data->{const}{VERB},
        '?=>'              => $data->{const}{VERB},
        '!=>'              => $data->{const}{VERB},
        'f=>'              => $data->{const}{VERB},
        'q=>'              => $data->{const}{VERB},
        'heisst'           => $data->{const}{VERB},
        'heisse'           => $data->{const}{VERB},
        'heissen'          => $data->{const}{VERB},
        'wegen'            => $data->{const}{PREP},
        'viel'             => $data->{const}{ADJ},
        'viele'            => $data->{const}{ADJ},
        'vieler'           => $data->{const}{ADJ},
        'vielen'           => $data->{const}{ADJ},
        'vieles'           => $data->{const}{ADJ},
        'vielen'           => $data->{const}{ADJ},
        'china'            => $data->{const}{NOUN},
        'schnecke'         => $data->{const}{NOUN},
        'schnecken'        => $data->{const}{NOUN},
        'tag'              => $data->{const}{NOUN},
        'macht'            => $data->{const}{VERB},
        'angst'            => $data->{const}{NOUN},
        'your'             => $data->{const}{ART},
        'my'               => $data->{const}{ART},
        'our'              => $data->{const}{ART},
        'their'            => $data->{const}{ART},
        'am' =>
          ( LANGUAGE() eq 'de' ? $data->{const}{PREP} : $data->{const}{VERB} ),
        'are'          => $data->{const}{VERB},
        'be'           => $data->{const}{VERB},
        'is'           => $data->{const}{VERB},
        'do'           => $data->{const}{VERB},
        'did'          => $data->{const}{VERB},
        'must'         => $data->{const}{VERB},
        'have'         => $data->{const}{VERB},
        'has'          => $data->{const}{VERB},
        'done'         => $data->{const}{ADJ},
        'beiden'       => $data->{const}{ADJ},
        "und"          => $data->{const}{LINKING},
        "oder"         => $data->{const}{LINKING},
        "or"           => $data->{const}{LINKING},
        "and"          => $data->{const}{LINKING},
        "&"            => $data->{const}{LINKING},
        'uebt'         => $data->{const}{VERB},
        'ueben'        => $data->{const}{VERB},
        'uebst'        => $data->{const}{VERB},
        'uebe'         => $data->{const}{VERB},
        'biszu'        => $data->{const}{PREP},
        'bis'          => $data->{const}{PREP},
        'bisauf'       => $data->{const}{PREP},
        'bisin'        => $data->{const}{PREP},
        "keine"        => $data->{const}{ADJ},
        "kein"         => $data->{const}{ADJ},
        'bleib'        => $data->{const}{VERB},
        'dicht'        => $data->{const}{ADJ},
        "keines"       => $data->{const}{ADJ},
        "keiner"       => $data->{const}{ADJ},
        "keinem"       => $data->{const}{ADJ},
        "keinen"       => $data->{const}{ADJ},
        'frei'         => $data->{const}{ADJ},
        'andererseits' => $data->{const}{ADJ},
        'einerseits'   => $data->{const}{ADJ},
        'bloss'        => $data->{const}{ADJ},
        'nehme'        => $data->{const}{VERB},
        'spd'          => $data->{const}{NOUN},
        'doch'         => $data->{const}{INTER},
        'cdu'          => $data->{const}{NOUN},
        'offiziell'    => $data->{const}{ADJ},
        'atomaren'     => $data->{const}{ADJ},
        'atomar'       => $data->{const}{ADJ},
        'spricht'      => $data->{const}{VERB},
        'berg'         => $data->{const}{NOUN},
        'bern'         => $data->{const}{NOUN},
        "anderen"      => $data->{const}{ADJ},
        "denselben"    => $data->{const}{ADJ},
        "dengleichen"  => $data->{const}{ADJ},
        "XXtoXX"       => $data->{const}{QUESTIONWORD},
        "xxtoxx"       => $data->{const}{QUESTIONWORD},
        "_to_"         => $data->{const}{QUESTIONWORD},
        'aussen'       => $data->{const}{ADJ},
        'innen'        => $data->{const}{ADJ},
        "wem"          => $data->{const}{QUESTIONWORD},
        "wen"          => $data->{const}{QUESTIONWORD},
        "was"          => ( LANGUAGE() eq 'de' )
        ? $data->{const}{QUESTIONWORD}
        : $data->{const}{VERB},
        "wie"          => $data->{const}{QUESTIONWORD},
        "komma"        => $data->{const}{KOMMA},
        'arena'        => $data->{const}{NOUN},
        'uhr'          => $data->{const}{NOUN},
        'german'       => $data->{const}{ADJ},
        'man'          => $data->{const}{NOUN},
        'fuer'         => $data->{const}{PREP},
        "der"          => $data->{const}{ART},
        "die"          => $data->{const}{ART},
        "das"          => $data->{const}{ART},
        "die"          => $data->{const}{ART},
        "des"          => $data->{const}{ART},
        "der"          => $data->{const}{ART},
        "des"          => $data->{const}{ART},
        "der"          => $data->{const}{ART},
        "dem"          => $data->{const}{ART},
        "der"          => $data->{const}{ART},
        "dem"          => $data->{const}{ART},
        "den"          => $data->{const}{ART},
        "den"          => $data->{const}{ART},
        "die"          => $data->{const}{ART},
        "das"          => $data->{const}{ART},
        "die"          => $data->{const}{ART},
        "ein"          => $data->{const}{ART},
        "eine"         => $data->{const}{ART},
        "eines"        => $data->{const}{ART},
        "einer"        => $data->{const}{ART},
        "einem"        => $data->{const}{ART},
        "einen"        => $data->{const}{ART},
        "eine"         => $data->{const}{ART},
        "the"          => $data->{const}{ART},
        'mond'         => $data->{const}{NOUN},
        'mein'         => $data->{const}{ART},
        'meine'        => $data->{const}{ART},
        'meiner'       => $data->{const}{ART},
        'meinen'       => $data->{const}{ART},
        'meinem'       => $data->{const}{ART},
        'meins'        => $data->{const}{NOUN},
        'dein'         => $data->{const}{ART},
        'deine'        => $data->{const}{ART},
        'deiner'       => $data->{const}{ART},
        'deinen'       => $data->{const}{ART},
        'deinem'       => $data->{const}{ART},
        'deins'        => $data->{const}{NOUN},
        'sein'         => $data->{const}{ART},
        'seine'        => $data->{const}{ART},
        'seiner'       => $data->{const}{ART},
        'seinem'       => $data->{const}{ART},
        'seinen'       => $data->{const}{ART},
        'seins'        => $data->{const}{NOUN},
        'name'         => $data->{const}{NOUN},
        'war'          => $data->{const}{VERB},
        'ihr'          => $data->{const}{ART},
        'ihre'         => $data->{const}{ART},
        'ihrer'        => $data->{const}{ART},
        'ihrem'        => $data->{const}{ART},
        'ihren'        => $data->{const}{ART},
        'ihres'        => $data->{const}{NOUN},
        'user'         => $data->{const}{ART},
        'unseres'      => $data->{const}{ART},
        'unsere'       => $data->{const}{ART},
        'unserem'      => $data->{const}{ART},
        'unseren'      => $data->{const}{ART},
        'euer'         => $data->{const}{ART},
        'euers'        => $data->{const}{ART},
        'eueres'       => $data->{const}{ART},
        'eueren'       => $data->{const}{ART},
        'eures'        => $data->{const}{ART},
        'euren'        => $data->{const}{ART},
        'eurem'        => $data->{const}{ART},
        'sind'         => $data->{const}{VERB},
        'ich'          => $data->{const}{NOUN},
        'du'           => $data->{const}{NOUN},
        'mich'         => $data->{const}{NOUN},
        'dich'         => $data->{const}{NOUN},
        'mir'          => $data->{const}{NOUN},
        'dir'          => $data->{const}{NOUN},
        'er'           => $data->{const}{NOUN},
        'sie'          => $data->{const}{NOUN},
        'es'           => $data->{const}{NOUN},
        'wir'          => $data->{const}{NOUN},
        'sie'          => $data->{const}{NOUN},
        'uns'          => $data->{const}{NOUN},
        'euch'         => $data->{const}{NOUN},
        'sich'         => $data->{const}{NOUN},
        'bin'          => $data->{const}{VERB},
        'bist'         => $data->{const}{VERB},
        'ist'          => $data->{const}{VERB},
        'mag'          => $data->{const}{VERB},
        'magst'        => $data->{const}{VERB},
        'an'           => $data->{const}{PREP},
        'vielleicht'   => $data->{const}{ADJ},
        'gegenueber'   => $data->{const}{PREP},
        'sein'         => $data->{const}{VERB},
        'hast'         => $data->{const}{VERB},
        'habe'         => $data->{const}{VERB},
        'will'         => $data->{const}{VERB},
        'willst'       => $data->{const}{VERB},
        'allgemein'    => $data->{const}{ADJ},
        'allgemeinen'  => $data->{const}{ADJ},
        'allgemeine'   => $data->{const}{ADJ},
        'allgemeiner'  => $data->{const}{ADJ},
        'allgemeinem'  => $data->{const}{ADJ},
        'allgemeines'  => $data->{const}{ADJ},
        'linken'       => $data->{const}{ADJ},
        'rechten'      => $data->{const}{ADJ},
        'linke'        => $data->{const}{ADJ},
        'rechte'       => $data->{const}{ADJ},
        'linker'       => $data->{const}{ADJ},
        'rechter'      => $data->{const}{ADJ},
        'linkes'       => $data->{const}{ADJ},
        'rechtes'      => $data->{const}{ADJ},
        'linkem'       => $data->{const}{ADJ},
        'rechtem'      => $data->{const}{ADJ},
        'heisse'       => $data->{const}{VERB},
        'heise'        => $data->{const}{VERB},
        'heisst'       => $data->{const}{VERB},
        'ueber'        => $data->{const}{PREP},
        'wenigerals'   => $data->{const}{PREP},
        'mehrals'      => $data->{const}{PREP},
        'dick'         => $data->{const}{ADJ},
        'heute'        => $data->{const}{ADJ},
        'gestern'      => $data->{const}{ADJ},
        'morgen'       => $data->{const}{ADJ},
        'ob'           => $data->{const}{QUESTIONWORD},
        'nothing'      => $data->{const}{NOUN},
        'now'          => $data->{const}{ADJ},
        'dir'          => $data->{const}{NOUN},
        'mir'          => $data->{const}{NOUN},
        'es'           => $data->{const}{NOUN},
        'nicht'        => $data->{const}{ADJ},
        'not'          => $data->{const}{ADJ},
        'aus'          => $data->{const}{PREP},
        'braucht'      => $data->{const}{VERB},
        'mehr'         => $data->{const}{ADJ},
        'wohnt'        => $data->{const}{VERB},
        'weil'         => $data->{const}{QUESTIONWORD},
        'woher'        => $data->{const}{QUESTIONWORD},
        'wohin'        => $data->{const}{QUESTIONWORD},
        'worauf'       => $data->{const}{QUESTIONWORD},
        'woran'        => $data->{const}{QUESTIONWORD},
        'worum'        => $data->{const}{QUESTIONWORD},
        'dass'         => $data->{const}{QUESTIONWORD},
        'obschon'      => $data->{const}{QUESTIONWORD},
        'film'         => $data->{const}{NOUN},
        'beruehmt'     => $data->{const}{ADJ},
        'beruehmte'    => $data->{const}{ADJ},
        'beruehmtest'  => $data->{const}{ADJ},
        'beruf'        => $data->{const}{NOUN},
        'berufen'      => $data->{const}{VERB},
        'beschaedigt'  => $data->{const}{ADJ},
        'bescheiden'   => $data->{const}{ADJ},
        'beschaeftigt' => $data->{const}{ADJ},
        'besetzt'      => $data->{const}{ADJ},
        'beste'        => $data->{const}{ADJ},
        'best'         => $data->{const}{ADJ},
        'grundlegend'  => $data->{const}{ADJ},
        'zu'           => $data->{const}{PREP},
        'gehoeren'     => $data->{const}{VERB},
        'gehoert'      => $data->{const}{VERB},
        'mitten'       => $data->{const}{PREP},
        'unreif'       => $data->{const}{ADJ},
        'unreifer'     => $data->{const}{ADJ},
        'unreifen'     => $data->{const}{ADJ},
        'unreifes'     => $data->{const}{ADJ},
        'unreifem'     => $data->{const}{ADJ},
        'unreife'      => $data->{const}{ADJ},
        '='            => $data->{const}{VERB},
        'bereits'      => $data->{const}{ADJ},
        'enden'        => $data->{const}{VERB},
        'heisser'      => $data->{const}{ADJ},
        'sehr'         => $data->{const}{ADJ},
        'cooles'       => $data->{const}{ADJ},
        'muede'        => $data->{const}{ADJ},
        'muedes'       => $data->{const}{ADJ},
        'mueder'       => $data->{const}{ADJ},
        'mueden'       => $data->{const}{ADJ},
        'muedem'       => $data->{const}{ADJ},
        'keineswegs'   => $data->{const}{ADJ},
        'schenkte'     => $data->{const}{VERB},
        'schenke'      => $data->{const}{VERB},
        'gab'          => $data->{const}{VERB},
        'frankreich'   => $data->{const}{NOUN},
        'freehal'      => $data->{const}{NOUN},
        'jedes'        => $data->{const}{ADJ},
        'jeder'        => $data->{const}{ADJ},
        'jedem'        => $data->{const}{ADJ},
        'jeden'        => $data->{const}{ADJ},
        'jede'         => $data->{const}{ADJ},

        'darf'    => $data->{const}{VERB},
        'duerfen' => $data->{const}{VERB},
        'duerfte' => $data->{const}{VERB},
        'darfst'  => $data->{const}{VERB},

        'rueckwaerts' => $data->{const}{ADJ},
        'vorwaerts'   => $data->{const}{ADJ},
        'rechts'      => $data->{const}{ADJ},
        'links'       => $data->{const}{ADJ},

        'schneidet'     => $data->{const}{VERB},
        'schneiden'     => $data->{const}{VERB},
        'farbe'         => $data->{const}{NOUN},
        'zeichen'       => $data->{const}{NOUN},
        'suche'         => $data->{const}{VERB},
        'suchst'        => $data->{const}{VERB},
        'zwischen'      => $data->{const}{PREP},
        'bei'           => $data->{const}{PREP},
        'wollte'        => $data->{const}{VERB},
        'wolltest'      => $data->{const}{VERB},
        'interessierst' => $data->{const}{VERB},
        'interessieren' => $data->{const}{VERB},
        'interessiere'  => $data->{const}{VERB},
        'dieser'        => $data->{const}{ART},
        'diese'         => $data->{const}{ART},
        'diesem'        => $data->{const}{ART},
        'diesen'        => $data->{const}{ART},
        'dieses'        => $data->{const}{ART},
        'dies'          => $data->{const}{ART},
        'zum'           => $data->{const}{QUESTIONWORD},
        'zur'           => $data->{const}{QUESTIONWORD},
        'erfunden'      => $data->{const}{ADJ},
        'falsche'       => $data->{const}{ADJ},
        'setzen'        => $data->{const}{VERB},
        '>>>'           => $data->{const}{VERB},
        'neu'           => $data->{const}{ADJ},
        'neue'          => $data->{const}{ADJ},
        'neuer'         => $data->{const}{ADJ},
        'neuen'         => $data->{const}{ADJ},
        'neues'         => $data->{const}{ADJ},
        'neuem'         => $data->{const}{ADJ},
        'hand'          => $data->{const}{NOUN},
        'page'          => $data->{const}{NOUN},
        'pages'         => $data->{const}{NOUN},
        'natural'       => $data->{const}{ADJ},
        'tree'          => $data->{const}{NOUN},
        'trees'         => $data->{const}{NOUN},
        'grosses'       => $data->{const}{ADJ},
        'bett'          => $data->{const}{NOUN},
        'deutsche'      => $data->{const}{ADJ},
        'hautfarbe'     => $data->{const}{NOUN},
        'hautfarben'    => $data->{const}{NOUN},
        'vereinigten'   => $data->{const}{ADJ},
        'beschlagnahmt' => $data->{const}{ADJ},
        'schlecht'      => $data->{const}{ADJ},
        'gute'          => $data->{const}{ADJ},
        'gut'           => $data->{const}{ADJ},
        'gutes'         => $data->{const}{ADJ},
        'guter'         => $data->{const}{ADJ},
        'guten'         => $data->{const}{ADJ},
        'gutem'         => $data->{const}{ADJ},
        'hase'          => $data->{const}{NOUN},
        'leichtes'      => $data->{const}{ADJ},
        'leichte'       => $data->{const}{ADJ},
        'leichter'      => $data->{const}{ADJ},
        'leichten'      => $data->{const}{ADJ},
        'leichtem'      => $data->{const}{ADJ},
        'leicht'        => $data->{const}{ADJ},
        'online'        => $data->{const}{ADJ},
        'offline'       => $data->{const}{ADJ},
        'jung'          => $data->{const}{ADJ},
        'junger'        => $data->{const}{ADJ},
        'jungen'        => $data->{const}{ADJ},
        'jungem'        => $data->{const}{ADJ},
        'junges'        => $data->{const}{ADJ},
        'baut'          => $data->{const}{VERB},
        'erbaut'        => $data->{const}{VERB},
        'waschen'       => $data->{const}{VERB},
        'verwendet'     => $data->{const}{VERB},
        'bewahren'      => $data->{const}{VERB},
        'zone'          => $data->{const}{NOUN},
        'zonen'         => $data->{const}{NOUN},
        'beruf'         => $data->{const}{NOUN},
        'berufe'        => $data->{const}{VERB},
        'berufen'       => $data->{const}{VERB},
        'berufst'       => $data->{const}{VERB},
        'verfuegbar'    => $data->{const}{ADJ},
        'bringen'       => $data->{const}{VERB},
        'bringt'        => $data->{const}{VERB},
        'bringst'       => $data->{const}{VERB},
        'bring'         => $data->{const}{VERB},
        'universitaet'  => $data->{const}{NOUN},
        'untertauchen'  => $data->{const}{VERB},
        'untertaucht'   => $data->{const}{VERB},
        'untertauchst'  => $data->{const}{VERB},
        'untertauche'   => $data->{const}{VERB},
        'tauchen'       => $data->{const}{VERB},
        'taucht'        => $data->{const}{VERB},
        'tauchst'       => $data->{const}{VERB},
        'tauche'        => $data->{const}{VERB},
        'allerdings'    => $data->{const}{ADJ},
        'wichtig'       => $data->{const}{ADJ},
        'wichtiger'     => $data->{const}{ADJ},
        'wichtigen'     => $data->{const}{ADJ},
        'wichtigem'     => $data->{const}{ADJ},
        'wichtiges'     => $data->{const}{ADJ},
        'wichtige'      => $data->{const}{ADJ},
        'erste'         => $data->{const}{ADJ},
        'erstes'        => $data->{const}{ADJ},
        'erster'        => $data->{const}{ADJ},
        'ersten'        => $data->{const}{ADJ},
        'erstem'        => $data->{const}{ADJ},
        'zweite'        => $data->{const}{ADJ},
        'zweites'       => $data->{const}{ADJ},
        'zweiter'       => $data->{const}{ADJ},
        'zweiten'       => $data->{const}{ADJ},
        'zweitem'       => $data->{const}{ADJ},
        'dritte'        => $data->{const}{ADJ},
        'dritter'       => $data->{const}{ADJ},
        'drittes'       => $data->{const}{ADJ},
        'dritten'       => $data->{const}{ADJ},
        'drittem'       => $data->{const}{ADJ},
        'wuerden'       => $data->{const}{VERB},
        'meisten'       => $data->{const}{ADJ},
        'meiste'        => $data->{const}{ADJ},
        'monoton'       => $data->{const}{ADJ},
        'monotone'      => $data->{const}{ADJ},
        'monotones'     => $data->{const}{ADJ},
        'monotoner'     => $data->{const}{ADJ},
        'monotonen'     => $data->{const}{ADJ},
        'monotonem'     => $data->{const}{ADJ},
        'gratis'        => $data->{const}{ADJ},
        'hat'           => $data->{const}{VERB},
        'haben'         => $data->{const}{VERB},
        'habe'          => $data->{const}{VERB},
        'hast'          => $data->{const}{VERB},
        'ab'            => $data->{const}{PREP},
        'bekannt'       => $data->{const}{ADJ},
        'soll'          => $data->{const}{VERB},
        'halben'        => $data->{const}{ADJ},
        'findet'        => $data->{const}{VERB},
        'statt'         => $data->{const}{PREP},
        'unterwegs'     => $data->{const}{ADJ},
        'wien'          => $data->{const}{NOUN},
        'nur'           => $data->{const}{ADJ},
        'jeweils'       => $data->{const}{ADJ},
        'anhalten'      => $data->{const}{VERB},
        'anhalte'       => $data->{const}{VERB},
        'anhaeltst'     => $data->{const}{VERB},
        'doppelt'       => $data->{const}{ADJ},
        'soviel'        => $data->{const}{ADJ},
        'ueberhaupt'    => $data->{const}{ADJ},
        'ca'            => $data->{const}{ADJ},
        'eingenommen'   => $data->{const}{VERB},
        'voll'          => $data->{const}{ADJ},
        'volle'         => $data->{const}{ADJ},
        'muessten'      => $data->{const}{VERB},
        'alle'          => $data->{const}{ADJ},
        'aerobe'        => $data->{const}{NOUN},
        'tief'          => $data->{const}{ADJ},
        'berg'          => $data->{const}{NOUN},
        'essen'         => $data->{const}{VERB},

        (
            ( LANGUAGE() eq 'en' )
            ? (

                'a'    => $data->{const}{ART},
                'an'   => $data->{const}{ART},
                'the'  => $data->{const}{ART},
                'but'  => $data->{const}{PREP},
                'than' => $data->{const}{PREP},
                'see'  => $data->{const}{VERB},

              )
            : ( 'a' => $data->{const}{NOUN}, )
        ),
        (
            map { $_ => $data->{const}{ADJ} }
              @{ $data->{lang}{adverbs_of_time} }
        ),
        ( map { $_ => $data->{const}{ADJ} } @numbers ),
        ( map { $_ => $data->{const}{NOUN} } qw{a b c d e f h j} ),
        (
            map { $_ => $data->{const}{PREP} }
              qw{in auf to im unter ueber neben mit gegen against on of about nach um vor nach als durch von

              on of in  by per between for
              }
        ),
        (
            map { $_ => $data->{const}{ADJ} }
              ( @{ $data->{lang}{adverbs_of_time} }, 'alt' )
        ),
        (
            map { $_ => $data->{const}{ADJ} }
              qw{gelb rot blau gruen schwarz weiss
              alt arg arm bar barsch bieder bitter blank blass blind bloed bloß brav breit boes derb deutsch dicht dick doof dreist dumm dumpf dunkel duenn duerr duester eben echt edel eigen elend eng ernst fade fahl fair falsch faul feig fein fern fesch fest fett feucht fidel fies finster fix flach flau flink forsch frech fremd froh fromm frueh ganz geil gemein genau gesamt gesund glatt gleich grob groß gut halb hager harsch hart hehr heikel heil heiser heiter heiß hell herb hoch (hoh) hohl hold huebsch jaeh jeck jung kahl kalt kaputt karg kess keusch klamm klar klein klug knapp krank krass kraus krude krumm kurz kuehl kuehn lahm lang lasch lau laut lauter lax leck leer leicht leise licht lieb lind link locker mager mies mild morsch munter muede muerbe nackt nah nass nett neu nieder oede offen plump prall pur rank rar rasch rau rauh recht rege reich rein roh rund sacht sanft satt sauber sauer scharf scheel schick schief schier schlaff schlank schlapp schlau schlecht schlimm schmal schmuck schnell schnoede schoen schrill schroff schraeg schuechtern schuetter schwach schwanger schwer schwul schwuel selbe selten sicher simpel spitz sproede spaet stark starr stet steif steil still stolz streng stumm stumpf stur sueß tapfer taub teuer tief toll tot treu trocken traege trueb tumb uebel viel voll wach wacker wahr warm weh weich weise weit welk welsch wenig wert wild wirr wohl wund wuest zahm zart zaeh

              }
        ),
        (
            map { $_ => $data->{const}{VERB} }
              qw{haette haetten haettest hattest hatte hatte habe wollte wuerde wuerdest wuerden wurde wurdest wurden waere waerst waerest
              moechte moechtest moechten mochte mochtest mochten moegen magst mag
              pulls}
        ),
        (
            map { $_ => $data->{const}{VERB} }
              qw{geh gehe gehst seh sehe siehst}
        ),

        ( map { $_ => $data->{const}{VERB} } ( '->', '=', 'reasonof', ), ),
        ( map { $_ => $data->{const}{ART} } ( 'this', 'that',, ), ),
        (
              ( LANGUAGE() eq 'de' )
            ? ( 'simple' => $data->{const}{ADJ}, )
            : ()
        ),
        'unter' => $data->{const}{PREP},
    };

  WORD:
    foreach my $key ( keys %$builtin_table ) {

        my $key_without_prefix = $key;
        foreach my $prefix ( keys %{ $data->{lang}{is_verb_prefix} } ) {

            $key_without_prefix =~ s/^$prefix//m;
            if ( $key_without_prefix ne $key
                && !$builtin_table->{$key_without_prefix} )
            {

                $builtin_table->{$key_without_prefix} ||=
                  $builtin_table->{$key};

                next WORD;
            }
        }
    }

    foreach my $key ( keys %$builtin_table ) {
        part_of_speech_get_memory()->{$key}{'type'} =
          $data->{lang}{constant_to_string}{ $builtin_table->{$key} };
        part_of_speech_get_memory()->{ ucfirst $key }{'type'} =
          $data->{lang}{constant_to_string}{ $builtin_table->{$key} };
        part_of_speech_get_memory()->{$key}{rtime} = 'not_new';
        part_of_speech_get_memory()->{ ucfirst $key }{rtime} = 'not_new';
    }

    foreach my $key ( keys %{ $data->{lang}{string_to_constant} } ) {
        $data->{lang}{constant_to_string}
          { $data->{lang}{string_to_constant}{$key} } = $key;
    }

    $data->{lang}{build_builtin_table_cache}{$lang} = $builtin_table;

    return $builtin_table;
}

=head2 get_verb_conjugation_table()

Returns an array containing arrays of two words, e.g.:

  [
    [ 'am', 'are' ]
  ]

=cut

sub get_verb_conjugation_table {
    my @verb_conjugation_table =
      LANGUAGE() eq 'de'
      ? (
        [ 'will',     'willst' ],
        [ 'kannst',   'kann' ],
        [ 'heisst',   'heisse' ],
        [ 'musst',    'muss' ],
        [ 'magst',    'mag' ],
        [ 'nimmst',   'nehme' ],
        [ 'weisst',   'weiss' ],
        [ 'sollst',   'soll' ],
        [ 'wirst',    'werde' ],
        [ 'hast',     'habe' ],
        [ 'sehe',     'siehst' ],
        [ 'weisst',   'weiss' ],
        [ 'finde',    'findest' ],
        [ 'wollte',   'wolltest' ],
        [ 'faehrst',  'fahre' ],
        [ 'isst',     'esse' ],
        [ 'sprichst', 'spreche' ],
      )
      : ( [ 'am', 'are' ], );

    return @verb_conjugation_table;
}

$data->{lang}{is_modal_verb} = {
    map { $_ => 1 }
      split /[|]/,
q{hat|habe|hast|haben|bist|bin|ist|sind|will|wollen|kann|kannst|willst|muss|musst|muessen|koennen|hatte|waere|wolle|sei|muessten|wollten|waere|waeren}
};

$data->{lang}{is_anrede} = {
    map { $_ => 1 } (
        'herr',    'frau', 'mr.',       'miss',
        'mrs.',    'mrs',  'mr',        'stueck',
        'mount',   'grad', 'millionen', 'milliarden',
        'tausend', 'bad',
    )
};

$data->{lang}{is_a_name} = {};

#our $config{'modes'}{'online_mode'} = 1;
if ( !defined $config{'modes'}->{'offline_mode'} ) {
    $config{'modes'}{'offline_mode'} = 0;
}

#$config{'modes'}{'online_mode'} = $config{'modes'}->{'online_mode'};
$config{'modes'}{'speech_mode'} = 1
  if !defined $config{'modes'}{'speech_mode'};
$config{'modes'}{'verbose'} = 0
  if !defined $config{'modes'}{'verbose'};

$config{'modes'}{'memory'} = 'bigmem'
  if 1 || !defined $config{'modes'}{'memory'};

$config{'mysql'}{'user'} = ''
  if !defined $config{'mysql'}{'user'} || $data->{modes}{batch};
$config{'mysql'}{'password'} = ''
  if !defined $config{'mysql'}{'password'} || $data->{modes}{batch};
$config{'mysql'}{'database'} = ''
  if !defined $config{'mysql'}{'database'} || $data->{modes}{batch};

if ( !$config{'mysql'}{'host'} ) {
    $config{'mysql'}{'host'} = 'freehal.selfip.net';
}

$config{'features'}{'news'} = 0
  if !defined $config{'features'}{'news'};
$config{'features'}{'download_news'} = 1
  if !defined $config{'features'}{'download_news'};

$config{'features'}{'news'} = 1
  if $data->{modes}{batch} == 1;
$config{'features'}{'download_news'} = 0
  if $data->{modes}{batch} == 1;
$config{'features'}{'monitoring'} = 1;
$config{'features'}{'monitoring'} = 0
  if $config{'mysql'}{'user'};

$config{'modes'}{'low-latency'} = 1
  if !defined $config{'modes'}{'low-latency'};

$config{'features'}{'tagger'} = 1
  if !defined $config{'features'}{'tagger'};

###if ( lc($^O) =~ /win/i ) {

    $config{'servers'}{'port_tagger'} = 'none';
    $config{'servers'}{'host_tagger'} = 'none';

###}
###else {
###    $config{'servers'}{'host_tagger'} = '127.0.0.1'
###      if !defined $config{'servers'}{'host_tagger'};
###    $config{'servers'}{'port_tagger'} = '5174'
###      if !defined $config{'servers'}{'port_tagger'};
###}
if ($data->{modes}{batch}) {
    $config{'servers'}{'port_tagger'} = 'none';
    $config{'servers'}{'host_tagger'} = 'none';
}

print "batch-mode: ", ( $data->{modes}{batch} || 0 ), "\n";

$data->{modes}{use_sql} =
  (      $config{'mysql'}{'user'}
      && $config{'mysql'}{'password'}
      && $config{'mysql'}{'database'}
      && !$data->{modes}{batch} );
print "use_sql:    ", ( $data->{modes}{use_sql} || 0 ), "\n";

write_config %config, $data->{intern}{config_file};

$AI::SemanticNetwork::getlang = \&LANGUAGE;

#*AI::Tagger::data = *data;
*AI::Util::data   = *data;

*AI::Tagger::config = *config;


#sub tie_semantic_net {
#print "tieing...\n";
##    eval   'use Tie::RDBM;'
##         . 'tie %$data->{persistent}{semantic_net}, \'Tie::RDBM\', \'mysql:'
##                    . $config{'mysql'}{'database'}
##                    . '\', { table => \'semantic_net\', user=>\''
##                   . $config{'mysql'}{'user'} . '\', password => \''
##                    . $config{'mysql'}{'password'} . '\', create => 1, autocommit=>1,};'
##        ;
##eval 'use DBM::Deep; $data->{persistent}{semantic_net} = DBM::Deep->new( file => "semantic_net.db", max_buckets => 64, autoflush => 0, num_txns => 4 );';

##    eval    'use Tie::MLDBM; use Tie::MLDBM::Lock::Null; tie %$data->{persistent}{semantic_net}, \'Tie::MLDBM\', {'
##          . '  \'Lock\'      =>  \'Null\', \'Serialise\' =>  \'Storable\', \'Store\'     =>  \'DBI\' }, {'
##          . '  \'db\'        =>  "mysql:dbname=@{[ \'' . $config{'mysql'}{'database'} . '\' ]}", \'table\'     =>  \'semantic_net\', '
##          . '  \'key\'       =>  \'id\', \'user\'      =>  \'' . $config{'mysql'}{'user'} . '\','
##          . '  \'password\'  =>  \'' . $config{'mysql'}{'password'} . '\', '
##          . '  \'CLOBBER\'   =>  3, create => 1, autocommit=>1 } ; print $!, "\n"; ';

#eval     'use Tie::MLDBM; use Fcntl; use Tie::MLDBM::Lock::Null; use Tie::MLDBM::Lock::File; tie %$data->{persistent}{semantic_net}, \'Tie::MLDBM\', {'
#. ' Lock => \'File\', \'Serialise\' =>  \'Storable\', \'Store\'     =>  \'DB_File\''
#. ' }, \'' . $data->{intern}{dir} . 'semantic_net.dbm\', O_CREAT|O_RDWR, 0640; print $!, "\n"; ';

#print $@, "\n";
#print "tied!\n";

#}

#if ( $data->{modes}{use_sql} ) {
#tie_semantic_net();
#}

use LWP::UserAgent;
use HTTP::Request;
use LWP::Protocol;
use LWP::Protocol::http;
our $ua = LWP::UserAgent->new( timeout => 5 );
$ua->agent(
"Mozilla/5.0 (X11; U; Linux i686; de; rv:1.8.1.10) Gecko/20071213 Firefox/2.0.0.12"
);

=head2 is_verbose()

Returns a boolean whether FreeHAL should be verbose.

=cut

sub is_verbose {
    return $config{'modes'}{'verbose'};
}

=head2 load_pos()

Detect part of speech files (lang_XY/*.{brain,memory}) and load them.

=cut

sub load_pos {
    print ">> loading word types\n";

    part_of_speech_init(
        usage   => $config{'modes'}{'memory'},
        basedir => $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/'
    );

    if ( !$data->{modes}{use_sql} ) {

        part_of_speech_init(
            usage => $config{'modes'}{'memory'},
            files => [
                get_pos_files('base'),
                get_pos_files('brain'),
                get_pos_files('memory'),
            ],
            basedir => $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/',
        );

        part_of_speech_load(
            files => [
                get_pos_files('base'), get_pos_files('brain'),
                get_pos_files('memory'),
            ]
        );

        print '<br /><br />' if $data->{intern}{in_cgi_mode};

        print '<br />' if $data->{intern}{in_cgi_mode};

    }
    else {
        eval q{
        use DBI;

        my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
        if ( $config{'mysql'}{'host'} ) {
            $db_string .= ';host=' . $config{'mysql'}{'host'};
        }
        my $user      = $config{'mysql'}{'user'};
        my $password  = $config{'mysql'}{'password'};
        my $dbh       = DBI->connect( $db_string, $user, $password )
          or say(
            "not connected to ",
            $config{'mysql'}{'database'},
            ", user ",
            $config{'mysql'}{'user'},
            ", password ",
            $config{'mysql'}{'password'},
            ", db_string ",
            $db_string,
            ": "
          );

        my $sql =
qq{create table part_of_speech (word varbinary(120), type char(3), genus char(1))};
        $dbh->prepare($sql)->execute();
        $sql = qq{ALTER TABLE `part_of_speech` ADD PRIMARY KEY ( `word` )};
        $dbh->prepare($sql)->execute();

        $sql = qq{SELECT word FROM part_of_speech};
        my $sth = $dbh->prepare($sql);
        $sth->execute();

        my $count_of_words = $sth->rows;
        say($sth );

        #while ( $sth && ( my $data = $sth->fetchrow_arrayref ) ) {
        #    $count_of_words += 1;
        #}

        if ( !$count_of_words ) {
            my $pid = undef;

            #            if ( !( $pid = fork() ) ) {
            if ( !( $dbh = DBI->connect( $db_string, $user, $password ) ) ) {
                print "Cannot make connection\n";
                exit 0;
            }

            part_of_speech_init(
                usage => 'bigmem',
                files => [
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.base',
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.brain',
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.memory'
                ],
            );

            part_of_speech_load(
                at    => 'init',
                files => [
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.base',
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.brain',
                    $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.memory'
                ],
            );

            my %parts_of_speech_temp = %{ part_of_speech_get_memory() };
            while ( my ( $word, $value ) = each %parts_of_speech_temp ) {
                my $sql =
                  'INSERT INTO part_of_speech( word, type, genus ) VALUES ( \''
                  . $word
                  . '\', \''
                  . ( $value->{type} || '' )
                  . '\', \''
                  . ( $value->{genus} || '' ) . '\' )';
                print $sql, "\n";
                my $sth = $dbh->prepare($sql);

                $sth->execute();
                $sth->finish();
            }

            $dbh->disconnect();

            #exit 0;
            #            }
            #            exit 0 if $pid == 0 && defined $pid;
        }

        say( '   Loaded by SQL: ', $count_of_words );
        print '<br />' if $data->{intern}{in_cgi_mode};

        $dbh->disconnect();
        } if !$data->{modes}{batch};
    }

    #&Devel::DumpSizes::dump_sizes();
    say(`free`);

    my $count = 0;

    delete part_of_speech_get_memory()->{''};
    delete part_of_speech_get_memory()->{' '};
    foreach my $key ( keys %{ part_of_speech_get_memory() } ) {
        delete part_of_speech_get_memory()->{$key}
          if $key =~ /['"*+\-)(]|(^[\s_])/
              || $key !~ /^[a-zA-Z0-9_\s]+$/;
    }

    part_of_speech_get_memory()->{'es'}      = { 'genus' => 's' };
    part_of_speech_get_memory()->{'er'}      = { 'genus' => 'm' };
    part_of_speech_get_memory()->{'ihm'}     = { 'genus' => 'm' };
    part_of_speech_get_memory()->{'ihn'}     = { 'genus' => 'm' };
    part_of_speech_get_memory()->{'ihr'}     = { 'genus' => 'f' };
    part_of_speech_get_memory()->{'sie'}     = { 'genus' => 'f' };
    part_of_speech_get_memory()->{'nothing'} = { 'genus' => 's' };
}

my %has_no_genus = map { $_ => 1 }
  qw{du ich ihm ihr etwas i you dir mir mich dich du dir ich mir nothing etwas something jemand niemand nichts};

=head2 try_use_lowlatency_mode()

Returns nothing.

First it checks whether low-latency mode is enabled.
If success, $data->{abilities}->{'tagger'} is set to 2 and part-of-speech files are loaded.

=cut

sub try_use_lowlatency_mode {
    if ( $config{'modes'}{'low-latency'} && $data->{abilities}->{'tagger'} < 2 )
    {
        load_pos();
        $data->{abilities}->{'tagger'} = 2;
    }
}




sub correct_time {
    my ($sentence) = @_;

    my @s = ( '$1:$2:00 ', '$1:$2:$3', '$1:00:$2', '$1:00:00 ' );
    my @p1 = (
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+([0-9]+?)[\s,.;]*?Min[\w]*?[\s,.;]+und[\s,.;]*?([0-9]+?)[\s,.;]+sekunden',
            1
        ],
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+([0-9]+?)[\s,.;]*?[Min]*?[\w]*?[\s,.;]+und,;.-][\s,.;]*?([0-9]+?)[\s,.;]+sekunden',
            1
        ],
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+und[\s,.;]+([0-9]+?)[\s,.;]+M\w+([\s,.;]|$)',
            0
        ],
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+,;][\s,.;]+([0-9]+?)[\s,.;]+M\w+([\s,.;]|$)',
            0
        ],
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+und[\s,.;]+([0-9]+?)[\s,.;]+Se\w+([\s,.;]|$)',
            2
        ],
        [
'([0-9]+?)[\s,.;]+Uhr[\s,.;]+,;][\s,.;]+([0-9]+?)[\s,.;]+Se\w+([\s,.;]|$)',
            2
        ],
        [ '([0-9]+?)[_,.;]([0-9]+?)[_,.;]([0-9]+?)[\s,.;]+Uhr([\s,.;]|$)', 1 ],
        [ '([0-9^_]+?)[_;,.]([0-9]+?)[\s,.;]+Uhr([\s,.;]|$)',              0 ],
        [ '([0-9]+?)[\s,.;]+Uhr[\s,.;]+([0-9]+?)([\s,.;]|$)',              0 ],
        [ '([0-9]+?)[\s,.;]+Uhr([\s,.;]|$)',                               3 ],

        [ '[\s,.;]([0-9])_([0-9]+?)_([0-9]+?)', 4 ],
        [ '([0-9]+?)_([0-9])_([0-9]+?)',        5 ],
        [ '([0-9]+?)_([0-9]+?)_([0-9])(.*?)',   6 ],

        [ '00',                                 7 ],
        [ '_0',                                 8 ],
        [ '_00([0-9][0-9])',                    9 ],
        [ '_0([0-9][0-9])',                     9 ],
        [ '_0([0-9][0-9])',                     9 ],
        [ '([0-9][0-9]_[0-9][0-9]_[0-9][0-9])', 10 ],
    );

    $sentence =~ s/^\s//igm;
    $sentence =~ s/\s$//igm;
    $sentence =~ s/[,]\s/,/gm;
    $sentence =~ s/\s[,]/,/gm;
    $sentence =~ s/[,]/ , /gm;
    $sentence =~ s/[:]/_/igm;

    foreach my $items_ref (@p1) {
        my ( $pattern, $string ) = @$items_ref;
        $sentence =~ "  " . $sentence . "  ";

        if ( $string =~ /[0-9]+/ ) {
            $sentence =~ s/$pattern/$1:$2:00 /igm   if $string == 0;
            $sentence =~ s/$pattern/$1:$2:$3/igm    if $string == 1;
            $sentence =~ s/$pattern/$1:00:$2/igm    if $string == 2;
            $sentence =~ s/$pattern/$1:00:00 /igm   if $string == 3;
            $sentence =~ s/$pattern/ 0$1:$2:$3/igm  if $string == 4;
            $sentence =~ s/$pattern/$1:0$2:$3/igm   if $string == 5;
            $sentence =~ s/$pattern/$1:$2:0$3$4/igm if $string == 6;
            $sentence =~ s/$pattern/0/igm           if $string == 7;
            $sentence =~ s/$pattern/:00/igm         if $string == 8;
            $sentence =~ s/$pattern/:$1/igm         if $string == 9;
            $sentence =~ s/$pattern/$1 Uhr/igm      if $string == 10;
        }
        else {
            $sentence =~ s/$pattern/$string/igme;
        }

        $sentence =~ s/[:]/_/igm;

        $sentence =~ s/^\s//igm;
        $sentence =~ s/\s$//igm;

        say 'new sentence: ', $sentence;
    }

    $sentence =~ s/[,]\s/,/gm;
    $sentence =~ s/\s[,]/,/gm;
    $sentence =~ s/[,]/, /gm;

    $sentence =~ s/Uhr Uhr/Uhr/igm;
    $sentence =~ s/Uhr/Uhr /igm;
    $sentence =~ s/Uhr zeit/Uhrzeit /igm;
    $sentence =~ s/  / /igm;

    my @time = localtime();

   #    print "(year,month,day,hour,min,sec,weekday(Monday=0),yearday,dls-flag)"
    my $time_in_sentence = $sentence . '';
    $time_in_sentence =~ s/(.*?)([0-9][0-9]_[0-9][0-9]_[0-9][0-9])(.*)/$2/igm;
    say '$time_in_sentence: ', $time_in_sentence;
    say 'localtime: ', join ', ', @time;
    my @time_in_sentence = split /[_]/, $time_in_sentence;
    my $is_now = 0;
    if ( scalar @time_in_sentence == 3 ) {
        if (   $time_in_sentence[0] =~ /^\d+$/
            && $time_in_sentence[1] =~ /^\d+$/
            && $time_in_sentence[2] =~ /^\d+$/ )
        {
            if ( $time_in_sentence[1] == 0 ) {
                if (   $time_in_sentence[0] == $time[2]
                    || $time_in_sentence[0] - 12 == $time[2]
                    || $time_in_sentence[0] == $time[2] - 12 )
                {
                    $is_now = 1;
                }
            }
            else {
                if (   $time_in_sentence[0] == $time[2]
                    || $time_in_sentence[0] - 12 == $time[2]
                    || $time_in_sentence[0] == $time[2] - 12 )
                {
                    if ( $time_in_sentence[1] == $time[1] ) {
                        $is_now = 1;
                    }
                }
            }
        }
    }

    say "is_now: ", $is_now;
    if ($is_now) {
        my $pattern = join ':', $time_in_sentence;
        $sentence =~ s/$pattern Uhr/NOW Uhr/igm;
        $sentence =~ s/$pattern/NOW Uhr/igm;
        $pattern = join '_', $time_in_sentence;
        $sentence =~ s/$pattern Uhr/NOW Uhr/igm;
        $sentence =~ s/$pattern/NOW Uhr/igm;
    }
    say 'new sentence: ', $sentence;
    return $sentence;
}

sub hash_to_facts {
    my @subclauses = @{ $_[0] || [] };
    my $sentence_ref = shift @subclauses;

    my @advs = @{ $sentence_ref->{'advs'} || [] };
    my $advs_str = join ';', sort @advs;

    if ( not @subclauses ) {
        push @subclauses,
          {
            'verbs'        => [''],
            'subjects'     => [''],
            'objects'      => [''],
            'questionword' => '',
            'description'  => '',
            'advs'         => [],
          };
    }

    return if $sentence_ref->{'questionword'};

    $sentence_ref->{'verb'} = lc $sentence_ref->{'verb'};

    my @facts = ();    # empty

    my @arrays_subclauses = ();

    say 'Subclauses:', Dumper \@subclauses;

    foreach my $subclause_ref (@subclauses) {

        #		$subclause_ref = remove_advs_to_list($subclause_ref);
        my $advs_subclause_str = join ';', sort @{ $subclause_ref->{'advs'} };

        foreach my $sub_2 ( join ' ',
            ( sort_linking( @{ $subclause_ref->{'subjects'} } ) ) )
        {
            $sub_2 = '' if is_array($sub_2) || $sub_2 =~ /array[(]/i;
            $sub_2 =~ s/^(und|oder|or|and)\s//igm;

            my @arr_objs = ();

            foreach my $obj ( join ' ',
                sort_linking(@{ $subclause_ref->{'objects'} }) )
            {
                next if $obj =~ /(und|oder|or|and)/ && length $obj < 5;
                $obj =~ s/^(und|oder|or|and)\s//igm;

                chomp $obj;
                $obj = 'nothing' if ( !$obj );
                my @arr_objs_temp =
                  map { my $new_one = $_ . '' } @arr_objs;
                @arr_objs = ();

                say 'obj: ', $obj;
                $obj =~ s/\soder\s/ und /igm;
                $obj =~ s/\sand\s/ und /igm;
                $obj =~ s/\sor\s/ und /igm;
                $obj =~ s/\sund\s/ und /igm;    # big and small (i)
                my @arr_obj = split /\sund\s/, $obj;

                #								say Dumper @arr_obj;
                for my $item (@arr_obj) {
                    $item =~ s/^\s//igm;
                    $item =~ s/\s$//igm;
                    foreach my $temp (@arr_objs_temp) {
                        push @arr_objs, $temp . ' ' . $item;
                    }
                    if ( not(@arr_objs_temp) ) {
                        push @arr_objs, $item;
                    }
                }

            }

            foreach my $obj_2 (@arr_objs) {
                $obj_2 = '' if is_array($obj_2) || $obj_2 =~ /array[(]/i;
                $obj_2 =~ s/^(und|oder|or|and)\s//igm;
                foreach my $verb_2 (
                    ( join ' ', sort @{ $subclause_ref->{'verbs'} }, ), )
                {
                    $verb_2 =~ s/^\s//igm;
                    $verb_2 =~ s/\s$//igm;
                    next if $verb_2 eq 'nothing';

                    $verb_2 =~ s/nothing//igm;
                    $verb_2 =~ s/  / /igm;

                    $obj_2 =~ s/\s+nothing\s*$//i;
                    $sub_2 =~ s/\s+nothing\s*$//i;

                    if ( !$verb_2 ) {
                        $verb_2 ||= lc $sub_2;
                        $sub_2 = q{} if ($verb_2);
                    }

                    push @arrays_subclauses,
                      [
                        lc $verb_2,
                        lc $sub_2,
                        lc $obj_2,
                        lc $advs_subclause_str,
                        lc $subclause_ref->{'questionword'},
                        lc $subclause_ref->{'description'},
                      ];
                }
            }
        }
    }

  MAKEHASH:
    foreach my $_sub ( join ' ', sort_linking(@{ $sentence_ref->{'subjects'} }) )
    {
        $_sub =~ s/^(und|oder|or|and)\s//igm;

        #        $_sub =~ s/(und|oder|or|and)//igm;
        next if !$_sub;
        my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
        foreach my $sub (@arr_sub) {
            next if $sub =~ /^(und|oder|or|and)$/;

            my @arr_objs = ();

            foreach
              my $obj ( join ' ', sort_linking(@{ $sentence_ref->{'objects'} }) )
            {
                next if $obj =~ /(und|oder|or|and)/ && length $obj < 5;
                $obj =~ s/^(und|oder|or|and)\s//igm;

                chomp $obj;
                $obj = 'nothing' if ( !$obj );
                my @arr_objs_temp =
                  map { my $new_one = $_ . '' } @arr_objs;
                @arr_objs = ();

                say 'obj: ', $obj;
                $obj =~ s/\soder\s/ und /igm;
                $obj =~ s/\sand\s/ und /igm;
                $obj =~ s/\sor\s/ und /igm;
                $obj =~ s/\sund\s/ und /igm;    # big and small (i)
                my @arr_obj = split /\sund\s/, $obj;

                #								say Dumper @arr_obj;
                for my $item (@arr_obj) {
                    $item =~ s/^\s//igm;
                    $item =~ s/\s$//igm;
                    foreach my $temp (@arr_objs_temp) {
                        push @arr_objs, $temp . ' ' . $item;
                    }
                    if ( not(@arr_objs_temp) ) {
                        push @arr_objs, $item;
                    }
                }

            }

            foreach my $obj (@arr_objs) {
                say '$obj:: ', $obj;
                foreach
                  my $verb ( ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ),
                  )
                {
                    say '$verb:: ', $verb;
                    next if $verb eq 'nothing';
                    $verb = lc $verb;
                    next if $verb eq 'st' || $verb eq 'e';

                    $verb =~ s/nothing//igm;
                    $verb =~ s/  / /igm;

                    my $prio = 50;

                    $obj =~ s/\s+nothing\s*$//i;
                    $sub =~ s/\s+nothing\s*$//i;

                    # filter
                    if ( ( $sub . ' ' . $verb . ' ' . $obj ) =~
/(^|\s)((ich|bin|mir|mich|me|my|i|am|jeliza|freehal|(mein name)|(es\s+ist.*?uhr))($|\s))|(mein)/i
                      )
                    {
                        if ( $data->{intern}{in_cgi_mode}
                            && !$data->{intern}{cgi_mode_but_superuser} )
                        {
                            say 'Not learning.';
                            last MAKEHASH;
                        }

                        $prio = 100;
                    }

                    next if !$verb;

                    push @facts,
                      [
                        lc $verb, lc $sub, lc $obj, lc $advs_str,
                        \@arrays_subclauses, $prio,
                      ];

                    say Dumper \@facts;
                }
            }
        }
    }

    return @facts;
}

sub variable_random {
    my ($var) = @_;

    #print Dumper @_;
    #select undef, undef, undef, 4;

    if ( $var =~ /name/i ) {
        my @facts = (
            @{ semantic_net_get_key_for_item( 'was-', 'facts' ) || [] },
            @{
                semantic_net_get_key_for_item( strip_to_base_word('wa-'),
                    'facts' )
                  || []
              },
            @{
                semantic_net_get_key_for_item( strip_to_base_word('war'),
                    'facts' )
                  || []
              },
            @{
                semantic_net_get_key_for_item( strip_to_base_word('war-'),
                    'facts' )
                  || []
              },
            @{
                semantic_net_get_key_for_item( strip_to_base_word('was'),
                    'facts' )
                  || []
              },
        );

        #print Dumper $data->{persistent}{semantic_net}->{'was-'};
        #print Dumper semantic_net_get_key_for_item(
        #            'was-', 'facts' );

        #print Dumper \@facts;
        my @names = map { $_->{subj}->{name} } @facts;
        return $names[ rand @names ] if @names;
    }

    return LANGUAGE() eq 'de'
      ? 'jemand'
      : 'someone';
}

sub resolve_time_date_variables {
    my ($sentence) = @_;

    #  0    1    2     3     4    5     6     7     8
    my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) =
      localtime(time);

    $year += 1900;

    my $now = scalar localtime;
    $sentence =~ s/now uhr/$now/igm;
    $sentence =~ s/[^a-zA-Z]now[^a-zA-Z]/$now/igm;
    $sentence =~ s/[^a-zA-Z]now[^a-zA-Z]/$now/igm;

    my @abbr_months =
      LANGUAGE() eq 'de'
      ? qw( Januar Februar Maerz April Mai Juni Juli August September October November Dezember )
      : map { lc }
      qw( January February March April May June July August September October November December );

    my @abbr_weekday =
      LANGUAGE() eq 'de'
      ? qw( Sonntag Montag Dienstag Mittwoch Donnerstag Freitag Samstag )
      : map { lc }
      qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

    $sentence =~ s/\$\$month\$\$/$abbr_months[$mon]/igm;
    $sentence =~ s/\$\$mday\$\$/$mday/igm;
    $sentence =~ s/\$\$wday\$\$/$abbr_weekday[$wday]/igm;
    $sentence =~ s/\$\$year\$\$/$year/igm;
    $sentence =~ s/\$\$yday\$\$/$yday/igm;
    $sentence =~ s/\$\$time\$\$/$hour:$min:$sec/igm;
    $sentence =~ s/\$\$anyone\$\$/man/igm if LANGUAGE() eq 'de';
    $sentence =~ s/\$\$anyone\$\$/someone/igm
      if LANGUAGE() eq 'en' && $sentence !~ /not/;
    $sentence =~ s/\$\$anyone\$\$/anyone/igm
      if LANGUAGE() eq 'en' && $sentence =~ /not/;
    $sentence =~ s/(^|\s|[;])_(\s|$)/$1man$2/igm if LANGUAGE() eq 'de';
    $sentence =~ s/(^|\s|[;])_(\s|$)/$1someone$2/igm
      if LANGUAGE() eq 'en' && $sentence !~ /not/;
    $sentence =~ s/(^|\s|[;])_(\s|$)/$1anyone$2/igm
      if LANGUAGE() eq 'en' && $sentence =~ /not/;
    $sentence =~ s/\$\$random(.+?)\$\$/variable_random( $1 => 1 )/igme;

    return $sentence;
}

sub phrase {
    my ( $CLIENT_ref, $verb, $subj, $obj, $advs, $facts ) = @_;

    my @verbs = ( split /[_\s]/, lc $verb );
    my @verbs_cath_1 = grep {
        $_ =~
/^(bist|bin|ist|sind|will|wollen|kann|kannst|willst|muss|musst|muessen|koennen|hatte|waere|wolle|sei|wird|wurde|wurden|werden|werde|wirst|soll|sollen|sollte|solltest|sollten|sollt|solltet|brauchst|brauche|braucht|brauchen|moechte|moechten|moechtest)$/
    } @verbs;
    my @verbs_cath_2 = grep { $_ =~ /^(hat|habe|hast|haben)$/ } @verbs;
    my @verbs_cath_3 = grep {
        $_ !~
/^(hat|habe|hast|haben|bist|bin|ist|sind|will|wollen|kann|kannst|willst|muss|musst|muessen|koennen|hatte|waere|wolle|sei|wird|wurde|wurden|werden|werde|wirst|soll|sollen|sollte|solltest|sollten|sollt|solltet|brauchst|brauche|braucht|brauchen|moechte|moechten|moechtest)$/
    } @verbs;
    if ( !@verbs_cath_1 ) {
        @verbs_cath_1 = @verbs_cath_2;
        @verbs_cath_2 = ();
    }
    if ( !@verbs_cath_2 ) {
        @verbs_cath_2 = @verbs_cath_3;
        @verbs_cath_3 = ();
    }
    if ( !@verbs_cath_1 ) {
        @verbs_cath_1 = @verbs_cath_2;
        @verbs_cath_2 = ();
    }

    my @sentence = ();
    push @sentence,
      (
        (
            map { $_ ne '_' ? $_ : ( LANGUAGE() eq 'de' ? 'man' : 'someone' ) }
              (
                length($subj) > 1
                ? split( /[_\s]/, lc $subj )
                : lc $subj
              )
        ),
        @verbs_cath_1,
        (
            grep { /(nicht|immer)/ && length $obj >= 6 } split /\s|[;]/,
            lc $advs
        ),
        ( split /\s/, lc $obj ),
        (
            grep { !/(nicht|immer)/ || length $obj < 6 } split /\s|[;]/,
            lc $advs
        ),
        @verbs_cath_2,
      );

    foreach my $fact (@$facts) {

        # say 'SUBCLAUSE:';
        #        print Dumper $fact;
        my ( $verb_2, $subj_2, $obj_2, $advs_2, $questionword, $descr ) =
          @$fact;

        $questionword ||= '';
        chomp $questionword;

        if ( $verb_2 || $subj_2 ) {
            push @sentence,
              (
                (','),
                ( split /[_\s]/, lc $questionword ),
                ( split /[_\s]/, lc $descr ),
                ( split /[_\s]/, lc $subj_2 ),
                ( split /[_\s]/, lc $obj_2 ),
                ( split /[_\s]/, lc $verb_2 ),
                ( split /[_\s]/, lc $advs_2 ),
              ) if $questionword;
            push @sentence,
              (
                (','),
                ( split /[_\s]/, lc $subj_2 ),
                ( split /[_\s]/, lc $verb_2 ),
                ( split /[_\s]/, lc $obj_2 ),
                ( split /[_\s]/, lc $advs_2 ),
              ) if !$questionword;
        }
    }

    #    print Dumper \@sentence;
    @sentence = grep { defined } map { split /(\s+)|([_]+)/, $_ } @sentence;

    #    print Dumper \@sentence;

    my $index           = -1;
    my @sentence_do_say = ();
    while ( defined( my $word = shift @sentence ) ) {
        $index += 1;

        next if $word eq 'nothing';

        if ( LANGUAGE() ne 'en' ) {

            #my $wt = pos_of( $CLIENT_ref, ucfirst $word,
            #    0, 1, 1, ( join ' ', @sentence ) )
            #    || 0;
            my $wt =
              $data->{lang}{string_to_constant}
              { part_of_speech_get_memory()->{ ucfirst $word }{'type'} || '' }
              || 0;
            if ( $wt == $data->{const}{NOUN} ) {
                $word = ucfirst $word;
            }
        }
        push @sentence_do_say, $word;
    }

    my $sentence = join ' ', @sentence_do_say;
    $sentence =~ s/XXtoXX/zu/igm if LANGUAGE() eq 'de';
    $sentence =~ s/XXtoXX/to/igm if LANGUAGE() eq 'en';

    $sentence =~ s/ biszu / bis zu /igm           if LANGUAGE() eq 'de';
    $sentence =~ s/ mehrals / mehr als /igm       if LANGUAGE() eq 'de';
    $sentence =~ s/ wenigerals / weniger als /igm if LANGUAGE() eq 'de';

    $sentence =~ s/_/ /gm;
    $sentence =~ s/\s+/ /gm;
    $sentence =~ s/[,]/, /gm;
    $sentence =~ s/ [,]/,/gm;
    $sentence =~ s/^\s+//igm;
    $sentence =~ s/\s+$//igm;

    $sentence = resolve_time_date_variables($sentence);

    $sentence =~ s/\s+/ /igm;
    $sentence =~ s/[,]\s+to\s/ to /igm;
    $sentence =~ s/\s+in\s+dem\s+/ im /igm;
    $sentence =~ s/\s+an\s+dem\s+/ am /igm if LANGUAGE() eq 'de';

    my @clauses = split /[,]/, $sentence;
    foreach my $sentence_sub (@clauses) {
        $sentence_sub =~
s/\s(kein|keine|keinen|keiner|keinem|nicht)\skein(|e|en|er|em)\s/ kein$2 /im;
        $sentence_sub =~
          s/\s(kein|keine|keinen|keiner|keinem|nicht)\snicht\s/ $1 /im;

        if (   $sentence_sub =~ /(\s|_|^)nicht(\s|[,]|_|$)/i
            && $sentence_sub =~ /(\s|^)(ein|eine|einen|einer|einem)\s/ )
        {
            $sentence_sub =~ s/(\s|_|^)nicht(\s|[,]|_|$)/$2/igm;
            if ( $sentence_sub =~
/(^|\s)(ein|eine|einen|einer|einem)\s(.+?)\s(ein|eine|einen|einer|einem)\s/
              )
            {
                $sentence_sub =~
s/(^|\s|[;])(ein|eine|einen|einer|einem)\s(.+?)\s(ein|eine|einen|einer|einem)\s/$1$2 $3 k$4 /im;
            }
            else {
                $sentence_sub =~
                  s/(^|\s|[;])(ein|eine|einen|einer|einem)\s/$1k$2 /im;
            }
        }

        if (   $sentence_sub =~ /(\s|_|^)nicht(\s|[,]|_|$)/i
            && $sentence_sub =~ /(\s|^)(etwas)(\s|$)/i )
        {
            $sentence_sub =~ s/(\s|_|^)nicht(\s|[,]|_|$)/$2/igm;
            $sentence_sub =~ s/(^|\s|[;])(etwas)(\s|$)/$1nichts$3 /im;
        }

        if ( $sentence_sub =~ /(^|\s)du(\s|$)/i ) {
            $sentence_sub =~ s/(^|\s|[;])sich(\s|$)/$1dich$1/igm;
        }
        if ( $sentence_sub =~ /(^|\s)ich(\s|$)/i ) {
            $sentence_sub =~ s/(^|\s|[;])sich(\s|$)/$1mich$1/igm;
        }
    }
    $sentence = join ',', @clauses;

    #    say '--> ' . ucfirst $sentence;

    return ucfirst $sentence . '.';
}

sub phrase_question {
    say 'phrase_question: ', ( join ', ', @_ );
    my ( $CLIENT_ref, $verb, $subj, $obj, $advs, $facts, $questionword ) = @_;

    no strict;
    no warnings;
    if ( \@$questionword == $questionword ) {    # eq 'ARRAY' ) {
        $facts        = $questionword;
        $questionword = '';
    }
    use warnings;
    use strict;

    $questionword = q{}                          # empty
      if !$questionword;

    $questionword = 'warum' if $questionword =~ /weil/i;

    my @verbs = ( split /[_\s]/, lc $verb );
    my @verbs_cath_1 = grep {
        $_ =~
/^(hat|habe|hast|haben|bist|bin|ist|sind|will|wollen|kann|kannst|willst|muss|musst|muessen|koennen|hatte|waere|wolle|sei)$/
    } @verbs;
    my @verbs_cath_2 = grep {
        $_ !~
/^(hat|habe|hast|haben|bist|bin|ist|sind|will|wollen|kann|kannst|willst|muss|musst|muessen|koennen|hatte|waere|wolle|sei)$/
    } @verbs;

    if ( !@verbs_cath_1 ) {
        @verbs_cath_1 = @verbs_cath_2;
        @verbs_cath_2 = ();
    }

    my @sentence = ();
    push @sentence, (
        $questionword,
        @verbs_cath_1,
        (
            map {
                    $_ ne '_'
                  ? $_
                  : ( LANGUAGE() eq 'de' ? 'jemand' : 'something' )
              } ( split /[_\s]/, lc $subj )
        ),
        ( split /\s/,     lc $obj ),
        ( split /\s|[;]/, lc $advs ),
        @verbs_cath_2,
    );

    foreach my $fact (@$facts) {

        # say 'SUBCLAUSE:';
        #print Dumper $fact;
        my ( $verb_2, $subj_2, $obj_2, $advs_2, $questionword, $descr ) =
          @$fact;
        if ( $verb_2 && $subj_2 ) {    # && $subj_2 ne 'nothing' ) {
             # say Dumper [$verb_2, $subj_2, $obj_2, $advs_2, $questionword, $descr ];
            push @sentence,
              (
                (','),
                ( split /[_\s]/, lc $questionword ),
                ( split /[_\s]/, lc $descr ),
                ( split /[_\s]/, lc $subj_2 ),
                ( split /[_\s]/, lc $obj_2 ),
                ( split /[_\s]/, lc $verb_2 ),
                ( split /[_\s]/, lc $advs_2 ),
              );
        }
    }

    @sentence = grep { defined } map { split /(\s+)|([_]+)/, $_ } @sentence;

    my $index           = -1;
    my @sentence_do_say = ();
    while ( defined( my $word = shift @sentence ) ) {
        $index += 1;

        next if $word eq 'nothing';
        next if !$word;

        if ( LANGUAGE() ne 'en' ) {
            my $wt =
              $data->{lang}{string_to_constant}
              { part_of_speech_get_memory()->{ ucfirst $word }{'type'} || '' }
              || 0;
            if ( $wt == $data->{const}{NOUN} ) {
                $word = ucfirst $word;
            }
        }
        push @sentence_do_say, $word;
    }

    my $sentence = join ' ', @sentence_do_say;
    say '--> ' . ucfirst $sentence;
    $sentence =~ s/XXtoXX/zu/igm if LANGUAGE() eq 'de';
    $sentence =~ s/XXtoXX/to/igm if LANGUAGE() eq 'en';
    $sentence =~ s/_/ /gm;
    $sentence =~ s/\s+/ /gm;
    $sentence =~ s/[,]/, /gm;
    $sentence =~ s/ [,]/,/gm;
    $sentence =~ s/^\s+//igm;
    $sentence =~ s/\s+$//igm;

    $sentence = resolve_time_date_variables($sentence);

    $sentence =~ s/\s+in\s+dem\s+/ im /igm;
    $sentence =~ s/\s+an\s+dem\s+/ am /igm if LANGUAGE() eq 'de';

    my @clauses = split /[,]/, $sentence;
    foreach my $sentence_sub (@clauses) {
        $sentence_sub =~
s/\s(kein|keine|keinen|keiner|keinem|nicht)\skein(|e|en|er|em)\s/ kein$2 /im;
        $sentence_sub =~
          s/\s(kein|keine|keinen|keiner|keinem|nicht)\snicht\s/ $1 /im;
        if (   $sentence_sub =~ /(\s|_|^)nicht(\s|[,]|_|$)/i
            && $sentence_sub =~ /(\s|^)(ein|eine|einen|einer|einem)\s/i )
        {
            $sentence_sub =~ s/(\s|_|^)nicht(\s|[,]|_|$)/$2/igm;
            $sentence_sub =~
              s/(^|\s|[;])(ein|eine|einen|einer|einem)\s/$1k$2 /im;
        }

        if (   $sentence_sub =~ /(\s|_|^)nicht(\s|[,]|_|$)/i
            && $sentence_sub =~ /(\s|^)(etwas)(\s|$)/i )
        {
            $sentence_sub =~ s/(\s|_|^)nicht(\s|[,]|_|$)/$2/igm;
            $sentence_sub =~ s/(^|\s|[;])(etwas)(\s|$)/$1nichts$3 /im;
        }

        if ( $sentence_sub =~ /(^|\s)du(\s|$)/i ) {
            $sentence_sub =~ s/(^|\s|[;])sich(\s|$)/$1dich$1/igm;
        }
        if ( $sentence_sub =~ /(^|\s)ich(\s|$)/i ) {
            $sentence_sub =~ s/(^|\s|[;])sich(\s|$)/$1mich$1/igm;
        }
    }
    $sentence = join ',', @clauses;

    say '--> ' . ucfirst $sentence;

    return ucfirst $sentence;
}

sub noun_synonyms {
    my ( $subj, $no_synonyms, $use_examples, $helper_function ) = @_;

    $subj =~
      s/^(der|die|das|den|des|dem|den|kein|ein|eine|einer|einem|eines) //igm;

    $subj = lc $subj;

    return {} if !$subj;

    #say $subj;

    if ( $subj eq 'nothing' ) {

        return {
            $subj => 1,
            (
                '___'            => [       { $subj => 1 } ],
                '_main'          => { $subj => 1 },
                '_main_original' => $subj,
                '_count'         => 1,
                'words_relevant' => [$subj],
                'from_3'         => 1,
            )
        };
    }

    if ( !$helper_function ) {
        my %synonyms = ();

        %{ $data->{lang}{is_time_measurement} } =
          map { $_ => 1 } get_time_measurements();

        #$subj =~ s/^(.ein.?.?)\s/$1qq/igm;
        my @words = split /\s+/, $subj;
        my @words_relevant = map { strip_to_base_word($_) } grep {
            $_ !~
/^(ein|der|die|das|den|dem|des|ein|eine|einer|einen|einem|eines|kein|keine|keinen|keines|keiner|a|an|the)(\s|$)/i
              && !$data->{lang}->{is_time_measurement}{$_}
        } @words;
        say join ', ', @words;
        say join ', ', @words_relevant;
        my @table_words = ();

        my %characters = map { $_ => 1 } ( 'a' .. 'h' );

        if ( $characters{$subj} ) {
            @words_relevant = ();
        }

        foreach my $word (@words_relevant) {
            my $noun_synonyms_inner =
              noun_synonyms( $word, $no_synonyms, $use_examples, 1 );
            push @table_words, $noun_synonyms_inner;
        }

        #say Dumper \@table_words;

        %synonyms = (
            %synonyms,
            (
                '___'   => \@table_words,
                '_main' => $table_words[-1] || { $subj => 1 },
                '_main_original' =>
                  strip_to_base_word( @words ? $words[-1] : '' ),
                '_count'         => ( scalar @words_relevant ),
                'words_relevant' => \@words_relevant,
                'from_1'         => 1,
            )
        );

        if ( $characters{$subj} ) {
            %synonyms = (
                (
                    '___'            => [       { $subj => 1 } ],
                    '_main'          => { $subj => 1 },
                    '_main_original' => $subj,
                    '_count'         => 1,
                    'words_relevant' => [$subj],
                    'from_2'         => 1,
                )
            );
        }

        if (is_verbose) {
            say;
            say 'generating synonym detect hash:';
            say '    _main_original:           ', $synonyms{'_main_original'};
            say '    _count:                   ', $synonyms{'_count'};
            say '    relevant words:           ', Dumper \@words_relevant;
            say;
        }

        return \%synonyms;
    }

    return {} if $subj =~ /^noth/;

    my $original_subj = $subj;

    $subj = strip_to_base_word($subj);

    my $overall_subj = $subj;

    my %synonyms = (
        lc $subj => 1,
        ( download_synonyms( lc $original_subj ) )
    );
    $synonyms{'mich-'} = 1 if ( lc $subj eq 'ich-' );
    $synonyms{'ich-'}  = 1 if ( lc $subj eq 'mich-' );
    $synonyms{'dich-'} = 1 if ( lc $subj eq 'du-' );
    $synonyms{'du-'}   = 1 if ( lc $subj eq 'dich-' );

    $synonyms{'sich-'} = 1 if ( $subj =~ /^(mich|dich)-$/ );

    %synonyms = ( %synonyms, %{ $data->{lang}{is_something} } )
      if ( $data->{lang}{is_something}{ lc $subj } );

    my @endings = ( qw{en e s n es r er in innen es}, '' );

    my %synonyms_nothing_new       = ();
    my %not_search_in_examples_for = ();
    my %not_search_in_synonyms_for = ();

    #	my %synonyms_no_new_endings = ();

  LOOP_1:
    foreach my $num_dummy ( 0 .. 2 ) {
      LOOP_2:
        foreach my $num ( 0 .. 3 ) {
            if ( scalar keys %synonyms > 450 ) {
                last LOOP_1;
            }

            #say ',';

         #		%synonyms = (
         #			%synonyms,
         #			(
         #				map { $_->[2] => 1 } (
         #					grep { $data->{lang}{is_be}{ $_->[0] } && $synonyms{ $_->[1]] } }
         #					  @$fact_database
         #				)
         #			)
         #		);

            #my %tmp = %synonyms;
            while ( my ( $subj, $_dummy ) = each %synonyms ) {
                next if $synonyms_nothing_new{$subj};

                #			my $add_to_synonyms_nothing_new = 1;
                #
                #				say '$subj: ', $subj;
                #				say '$no_synonyms: ', $no_synonyms;
                my $temp_ref = $data->{persistent}{noun_synonym_of}{$subj};
                if (   $temp_ref
                    && !$no_synonyms
                    && !$not_search_in_synonyms_for{$subj} )
                {
                    foreach my $item (@$temp_ref) {
                        next if $item =~ /^kein.?.?\s/;
                        next if $item =~ /nothing/;
                        next
                          if $data->{persistent}{no_noun_synonym_of}{$subj}
                              {$item};
                        $item =~
s/^(der|die|das|den|des|dem|den|ein|eine|einer|einem|eines) //igm;
                        next
                          if $data->{persistent}{no_noun_synonym_of}{$subj}
                              {$item};
                        $synonyms{$item}                   = 1;
                        $not_search_in_examples_for{$item} = 1;

                   # say 'new synonym: ', $item if $num_dummy == 0 && $num == 0;

                        if ( scalar keys %synonyms > 450 ) {
                            last LOOP_1;
                        }
                        ###say $item;
                     #foreach my $syn (
                     #resolve_hashes(
                     #map {   $overall_subj ne $_
                     #? [ noun_synonyms ( $_,  $no_synonyms, $use_examples, 1) ]
                     #: 0 } split /\s+/, $item
                     #) ) {

                        #$synonyms{$syn} = 1;
                        #}

                        #						say $item;

                        #					$add_to_synonyms_nothing_new = 0;
                    }
                }

                if ( $use_examples && !$not_search_in_examples_for{$subj} ) {
                    $temp_ref = $data->{persistent}{example_of}{$subj};

                    #print Dumper $temp_ref;
                    if ( $temp_ref && !$no_synonyms ) {
                        foreach my $item (@$temp_ref) {
                            next if $item =~ /^kein.?.?\s/;
                            next if $item =~ /nothing/;
                            next
                              if $data->{persistent}{no_noun_synonym_of}{$subj}
                              {$item};
                            $item =~
s/^(der|die|das|den|des|dem|den|ein|eine|einer|einem|eines) //igm;
                            next
                              if $data->{persistent}{no_noun_synonym_of}{$subj}
                              {$item};
                            $synonyms{$item}                   = 1;
                            $not_search_in_examples_for{$item} = 1;
                            $not_search_in_synonyms_for{$item} = 1;
                            $synonyms_nothing_new{$subj}       = 1;

                    #say 'new example: ', $item if $num_dummy == 0 && $num == 0;

                            if ( scalar keys %synonyms > 450 ) {
                                last LOOP_1;
                            }

                            #						say $item;

                            #					$add_to_synonyms_nothing_new = 0;
                        }
                    }
                }

                #if ( length $subj > 3 ) {
                #foreach my $ending (@endings) {
                #if ( $subj =~ /$ending$/ ) {
                #my $subj_2 = $subj;
                #$subj_2 =~ s/$ending$//igm if $subj_2 !~ /dt$/;
                #$synonyms{$subj_2} = 1;

                #foreach my $ending (@endings) {
                #my $subj_3 = $subj_2 . $ending;
                #$synonyms{$subj_3} = 1;

                #$synonyms_nothing_new{$subj_3} = 1
                #if !( $data->{persistent}{noun_synonym_of}{$subj_3} );
                #}

                ##						$add_to_synonyms_nothing_new = 0;
                #}
                #}
                #}

                $synonyms_nothing_new{$subj} = 1;

              # select undef, undef, undef, 10  if $num_dummy == 0 && $num == 0;
            }
        }

        #	my %tmp = %synonyms;
        #	foreach my $subj ( keys %tmp ) {
        #		next if $synonyms_no_new_endings{ $subj };
        #
        #		foreach my $ending (@endings) {
        #			if ( ( not $subj =~ /$ending$/ ) || ( not $ending ) ) {
        #				my $subj_2 = $subj . $ending;
        #				$synonyms{$subj_2} = 1;
        #			}
        #		}
        #
        #		$synonyms_no_new_endings{ $subj } = 1;
        #	}
    }

    #say '.';

    ## my %tmp = %synonyms;
#foreach my $old ( keys %synonyms ) {
#my $subj = $old;
#$subj =~ s/_/ /g;
#if ( $old ne $subj ) {
#$synonyms{$subj} = 1;
#}
#if ( $subj
#!~ /^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines)/i
#)
#{
#foreach my $article (
#qw{der die das den des dem den ein eine kein keine keiner keinem keinen einer einem eines}
#)
#{
#$synonyms{ $article . ' ' . $subj } = 1;
#}
#}
#$subj =~ s/ /_/g;
#if ( $old ne $subj ) {
#$synonyms{$subj} = 1;
#}
#if ( $subj
#!~ /^(der|die|das|den|des|dem|den|ein|eine|einer|einem|eines)/i )
#{
#foreach my $article (
#qw{der die das den des dem den ein eine einer einem eines})
#{
#$synonyms{ $article . ' ' . $subj } = 1;
#}
#}
#}

    while ( my ( $syn, $_dummy ) = each %synonyms ) {
        $synonyms{ strip_to_base_word($syn) } = 1;
        if ( $syn =~ /kuenstlich/ ) {

            #say $syn;
            #say strip_to_base_word( $syn );
            #select undef, undef, undef, 8;
        }
    }

    #say '.';

    #%tmp = %synonyms;
    while ( my ( $subj, $_dummy ) = each %synonyms ) {
        my $subj_2 = $subj;
        $subj_2 =~ s/.+?[_\s]//im
          if $subj_2 !~ /^(([dms]ein)|your|my)/;    # no 'g', only once!
        $synonyms{$subj_2} = 1 if $subj ne $subj_2;
        $subj_2 =~ s/.+?[_\s]//im
          if $subj_2 !~ /^(([dms]ein)|your|my)/;    # no 'g', only once!
        $synonyms{$subj_2} = 1 if $subj ne $subj_2;
        $subj_2 =~ s/.+?[_\s]//im
          if $subj_2 !~ /^(([dms]ein)|your|my)/;    # no 'g', only once!
        $synonyms{$subj_2} = 1 if $subj ne $subj_2;
    }

    while ( my ( $key, $val ) = each %synonyms ) {
        if ( $key =~ /^[.]/ ) {
            delete $synonyms{$key};
        }
        if ( $key =~ /nothing/ ) {
            delete $synonyms{$key};
        }
    }

    delete $synonyms{''};

    $synonyms{'du'} = 0
      if lc $subj eq 'ich' || lc $subj eq 'mich' || lc $subj eq 'mir';
    $synonyms{'ich'} = 0
      if lc $subj eq 'du' || lc $subj eq 'dich' || lc $subj eq 'dir';

    #	say 'noun synonyms: ', join ', ', keys %synonyms;

    #    say '$synonyms{\'du\'} = '
    #        . ( $synonyms{'du'} || 0 )
    #        . ', $subj = '
    #        . $subj;
    #    say '$synonyms{\'ich\'} = '
    #        . ( $synonyms{'ich'} || 0 )
    #        . ', $subj = '
    #        . $subj;
    #    say '$synonyms{\'menschen\'} = '
    #        . ( $synonyms{'menschen'} || 0 )
    #        . ', $subj = '
    #        . $subj;

    say '.', scalar %synonyms;
    return \%synonyms;
}

$data->{lang}{verb_family_1} =
  { map { $_ => 1 }
      ( keys %{ $data->{lang}{is_be} }, qw{heissen heisst heisse} ) };
$data->{lang}{verb_family_2} =
  { map { $_ => 1 }
      ( 'hat', 'haben', 'habe', 'hab', 'hast', 'has', 'have', 'had' ) };

%{ $data->{lang}{is_general_verb} } = map { $_ => 1 }
  qw{macht machen mache machst tun tust tuen tut do does did magst mag };

sub verb_synonyms {
    my ($subj) = @_;

    if ( $subj =~ /\s/ ) {
        my @words = grep { $_ } split /\s+/, $subj;

        my @synonyms = map { [ keys %{ verb_synonyms($_) } ] } @words;

        my @synonyms_all = @{ shift @synonyms || [] };

        my $hash = {};

        while ( $synonyms[0] ) {
            my @synonyms_all_shorter = @synonyms_all;
            @synonyms_all = ();

            foreach my $verb ( @{ shift @synonyms || [] } ) {
                chomp $verb;
                return {} if !$verb;

                print 'verb:', $verb;

                if ( $verb eq 'everything' ) {
                    $hash->{$verb} = 1;
                }

                push @synonyms_all,
                  map { $_ . ' ' . $verb } @synonyms_all_shorter;
            }
        }

        #        if ( $subj =~ /gefallen/ ) {
        #            print Dumper \@synonyms_all;
        #
        #            exit 0;
        #        }
        %$hash = ( %$hash, map { $_ => 1 } @synonyms_all );
        return $hash;
    }

    my %synonyms = ( lc $subj => 1, );

    $synonyms{'hab'}  = 1 if ( lc $subj eq 'habe' );
    $synonyms{'habe'} = 1 if ( lc $subj eq 'hab' );
    $synonyms{'dich'} = 1 if ( lc $subj eq 'du' );
    $synonyms{'du'}   = 1 if ( lc $subj eq 'dich' );

    %synonyms = ( %synonyms, %{ $data->{lang}{verb_family_1} } )
      if ( $data->{lang}->{verb_family_1}{ lc $subj } );
    %synonyms = ( %synonyms, %{ $data->{lang}{verb_family_2} } )
      if ( $data->{lang}->{verb_family_2}{ lc $subj } );
    %synonyms = ( %synonyms, keys %{ $data->{lang}{is_general_verb} } )
      if ( $data->{lang}->{is_general_verb}{ lc $subj } );

    foreach my $prefix ( keys %{ $data->{lang}{is_verb_prefix} } ) {
        ( my $subj_2 = $subj ) =~ s/^$prefix//i;
        %synonyms =
          ( %synonyms, map { $prefix . $_ } %{ $data->{lang}{verb_family_2} } )
          if $subj_2 ne $subj
              && ( $data->{lang}->{verb_family_2}{ lc $subj_2 } );
    }

    my @endings =
      ( qw{en t be st s sst tst ste sse sst ssen n e et test est}, '' );
    my %synonyms_nothing_new = ();

    while ( my ( $subj, $_dummy ) = each %synonyms ) {
        if ( $subj =~ /seh/ ) {
            ( my $subj_2 = $subj ) =~ s/seh/sieh/igm;
            $synonyms{$subj_2} = 1;
        }
        if ( $subj =~ /sieh/ ) {
            ( my $subj_2 = $subj ) =~ s/sieh/seh/igm;
            $synonyms{$subj_2} = 1;
        }
    }

    foreach my $num ( 0 .. 2 ) {
        while ( my ( $subj, $_dummy ) = each %synonyms ) {
            next if $synonyms_nothing_new{$subj};

            foreach my $ending (@endings) {
                if ( $subj =~ /$ending$/ ) {
                    my $subj_2 = $subj;
                    $subj_2 =~ s/$ending$//igm;
                    $synonyms{$subj_2} = 1;

                    #					$synonyms_nothing_new{$subj_2} = 1;
                }
                if ( ( $subj !~ /$ending$ending$/ ) || ( !$ending ) ) {
                    my $subj_2 = $subj . $ending;
                    $synonyms{$subj_2}             = 1;
                    $synonyms_nothing_new{$subj_2} = 1;
                }
            }
        }
    }

    while ( my ( $verb, $_dummy ) = each %synonyms ) {
        if ( $data->{lang}->{is_general_verb}{$verb} ) {
            $synonyms{'everything'} = 1;
        }
    }

    if (   lc $subj eq 'heisst'
        || lc $subj eq 'heisse'
        || lc $subj eq 'heissen' )
    {
        %synonyms = ( %synonyms, %{ $data->{lang}{verb_family_1} } );
    }

    $synonyms{'machen'} = 1;

    return \%synonyms;
}

%{ $data->{lang}{is_names_and_nouns_obj} } =
  map { $_ => 1 }
  ( 'ein name', 'ein nomen', 'eine bezeichnung', 'a noun', 'a name' );

our @names_and_nouns = ();

%{ $data->{lang}{is_time_measurements_obj} } = map { $_ => 1 } (
    'zeitangaben',          'eine zeitangabe',
    'a_time_measurement',   'a time_measurement',
    'time_measurements',    'a time measurement',
    'a time specification', 'a time_specification',
    'a_time_specification', 'time_specifications'
);

$data->{lang}->{acticles} =
  [qw{a an ein einen eine einer einem eines der die das dem den des}];

sub get_time_measurements {
    return ( @{ $data->{lang}->{adverbs_of_time} },
        @{ $data->{lang}->{acticles} } );
}

sub add_automatically {
    my ( $is_init, $facts ) = @_;

    $facts ||= [];
    @$facts = map { $_->[1] } @{
        semantic_network_get_by_key(
            as     => 'array',
            'keys' => [ keys %{ $data->{lang}{is_names_and_nouns_obj} } ]
        )
      };

    srand(time);
    %{ $data->{lang}{is_acceptable_verb} } =
      map { $_ => 1 } ( 'is', 'ist', 'are', 'sind' );

    my @names =
      grep { $_ !~ /nothing/ }
      grep { $_ }
      map  { lc $_->[1] . '' }
      grep { $_ }
      grep {
             ( $data->{lang}->{is_time_measurements_obj}{ $_->[2] } )
          && ( $data->{lang}->{is_acceptable_verb}{ $_->[0] } )
      } @$facts;

    foreach my $name (@names) {
        $name =~ s/_/ /igm;
        $name =~ s/\s+/ /igm;
        $name =~ s/(^\s+)|(\s+$)//igm;
    }
    push @{ $data->{lang}->{adverbs_of_time} }, @names;

    srand(time);
    %{ $data->{lang}{is_acceptable_verb} } =
      map { $_ => 1 } ( 'is', 'ist' );

    my @names_2 =
      grep { $_ !~ /nothing/ }
      grep { $_ }
      map  { lc $_->[1] . '' }
      grep {
             ( $data->{lang}{is_acceptable_verb}{ $_->[0] } )
          && ( $data->{lang}{is_names_and_nouns_obj}{ $_->[2] } )
      } @$facts;

    foreach my $name (@names_2) {
        $name =~ s/_/ /igm;
        $name =~ s/\s+/ /igm;
        $name =~ s/(^\s+)|(\s+$)//igm;
    }

    #print Dumper $facts;
    #print Dumper \@names_2;
    push @names_and_nouns, @names_2;
}

sub get_user_names {
    srand(time);
    %{ $data->{lang}{is_acceptable_subj} } =
      map { $_ => 1 } ( 'du', 'dein name' );

    %{ $data->{lang}{is_acceptable_verb} } =
      map { $_ => 1 } ( 'heisst', 'heist', 'heissst', 'heissen' );

    my @facts =
      grep {
        my @words = ( split /[\s_]/, $_->[1] );
        $_->[3] !~ /nicht|not/
          && (
            (
                $data->{lang}{is_acceptable_verb}{ $_->[0] }
                && lc $_->[1] eq 'du'
            )
            || (
                $data->{lang}{is_be}{ $_->[0] }
                && (   lc $_->[1] eq 'dein name'
                    || lc $_->[1] eq 'your name' )
            )
            || (   $data->{lang}{is_be}{ $_->[0] }
                && lc $_->[1] eq 'du'
                && @words == 1 )
            || ( $data->{lang}{is_be}{ $_->[0] }
                && lc $_->[1] eq 'you' )
          )
      } ();    #@$fact_database;

    my @names =
      grep { $_ !~ /^\d+/ }
      grep { $_ !~ /^kein/ }
      grep { $_ !~ /nicht/ }
      grep {
        my @arr = ( split /[\s_]/, $_ );
        1 <= scalar @arr && 4 > scalar @arr
      }
      grep { length($_) > 2 }
      grep { $_ }
      grep { $_ !~ /nothing/ }
      map  { $_->[2] } @facts;

    foreach my $name (@names) {
        $name =~ s/^[a-zA-Z]*ein.*?\s//igm if LANGUAGE() eq 'de';
        $name =~ s/^not\s//igm             if LANGUAGE() eq 'de';
        $name =~ s/^((nicht|gar|der|die|das|den|dem)\s)+//igm
          if LANGUAGE() eq 'de';
        $name =~ s/^[a-zA-Z]*ein.*?\s//igm if LANGUAGE() eq 'en';
        $name =~ s/^not\s//igm             if LANGUAGE() eq 'en';
        $name =~ s/^nicht\s//igm           if LANGUAGE() eq 'en';

        $name = ucfirst $name;
    }

    return @names;
}

#sub check_if_clause_helper {
#my ( $CLIENT_ref, $sub, $obj, $description, $advs, $is_subj_noun_synonym,
#$is_obj_noun_synonym, $clause, $num )
#= ( shift, shift, shift, shift, shift, shift, shift, shift, pop );
#my @facts                 = @_;
#my @results               = ();
#my @results_second_choice = ();

#my @advs = @$advs;

#my @is_obj_noun_synonym  = @$is_obj_noun_synonym;
#my @is_subj_noun_synonym = @$is_subj_noun_synonym;

#while ( my $result_ref = shift @facts ) {
#next if ( join ' <> ', @$clause ) eq ( join ' <> ', @$result_ref );

##        say 4 if is_verbose;
#my $can_use_result = 0;

####        say( 'obj: ', $obj, "\t" . '$result_ref->[2]: ', $result_ref->[2] ) if is_verbose;
#$result_ref->[2] =~ s/[)(]//igm;
#$obj             =~ s/[)(]//igm;
#if ( $obj && $obj !~ /nothing/ ) {
#if (   !( $result_ref->[2] =~ /nothing/ )
#&& $result_ref->[2]
#&& ( $result_ref->[2] =~ /(^|_|\s)$obj(\s|_|[;]|$)/i
#|| scalar grep { $_{ $result_ref->[2]] } }
#@is_obj_noun_synonym )
#)
#{
#$can_use_result = 1;
#}
#}
#else {
#$can_use_result = 1;
#}
#if ( $obj =~ /nothing/ ) {
#$can_use_result = 1;
#}
#if ( $data->{lang}{is_something}{$obj} ) {
#$can_use_result = 1;
#}

#my @facts_sub = ();

#next if ref $result_ref->[4] ne 'ARRAY';

#if ((   grep { ref($_) eq 'ARRAY' && $data->{lang}{is_if_word}{ $_->[4] || '' } }
#@{ $result_ref->[4] }
#)
#&& $can_use_result
#)
#{
#my ( $success, $results_ref ) =
#check_if_clause( $CLIENT_ref, $result_ref, $num + 1 );

#if ( !$success ) {
#next;
#}

#say join ' <> ', @$result_ref if is_verbose;

#my @results_matching = ();

#foreach my $res (@$results_ref) {
#next
#if ( !scalar grep { $_{ $res->[1]] } }
#@is_subj_noun_synonym
#&& !scalar grep { $_{ $res->[2]] } }
#@is_subj_noun_synonym );
#push @results_matching, $res;
#}
#foreach my $res (
#(@results_matching) ? @results_matching : @$results_ref )
#{
#my $result_ref = dclone($result_ref);
####                say join ' <> ', @$res if is_verbose; # the statement that makes it true

#my ( $subj_2, $obj_2, $advs_2 ) = ( \'', \'', \'' );
#foreach my $subcl (
#grep { ref($_) eq 'ARRAY' && $data->{lang}{is_if_word}{ $_->[4]] } }
#@{ $result_ref->[4] } )
#{
#( $subj_2, $obj_2, $advs_2 ) =
#( \$subcl->[1], \$subcl->[2], \$subcl->[3] )
#;    # from the if clause from @facts
#}

#my ( $res_subj, $res_obj ) = ( \'', \'' );
#foreach my $subcl (
#grep { ref($_) eq 'ARRAY' && $data->{lang}{is_if_word}{ $_->[4]] } }
#@{ $res->[4] } )
#{
#( $res_subj, $res_obj ) = ( \$subcl->[1], \$subcl->[2] );
#}

#my %replaced_to = ();

#if ( $$subj_2 eq $result_ref->[1] ) {
#$replaced_to{ $result_ref->[1] } = $res->[1];
#$result_ref->[1]                 = $res->[1];
#$$subj_2                         = $result_ref->[1];
#}

#if ( $$obj_2 eq $result_ref->[2] ) {
#$replaced_to{ $result_ref->[2] } = $res->[2];
#$result_ref->[2]                 = $res->[2];
#$$obj_2                          = $result_ref->[2];
#}

#if ( $$advs_2 =~ /\s+$result_ref->[1]($|[;])/ ) {
#my $repl = $$advs_2;
#$repl
#=~ s/(.*?\s+)($result_ref->[1])($|[;]).*?/$1(.+?)$3/igm;
#$repl =~ s/\s+/\\s+/igm;
####                    say 'repl (1):  ', $repl if is_verbose;
####                    say '$res->[3]: ', $res->[3] if is_verbose;
#my $word = $res->[3];
#$word =~ s/$repl/$1/igmx;
#$$advs_2
#=~ s/(.*?\s+)($result_ref->[1])($|[;]).*?/$1$word$3/igm;
#$result_ref->[1] = $word;
#}

#if ( $$advs_2 =~ /\s+$result_ref->[2]($|[;])/ ) {
#my $repl = $$advs_2;
#$repl
#=~ s/(.*?\s+)($result_ref->[2])($|[;]).*?/$1(.+?)$3/igm;
#$repl =~ s/\s+/\\s+/igm;
####                    say 'repl (2):  ', $repl if is_verbose;
####                    say '$res->[3]: ', $res->[3] if is_verbose;
#my $word = $res->[3];
#$word =~ s/$repl/$1/igmx;
#$$advs_2
#=~ s/(.*?\s+)($result_ref->[2])($|[;]).*?/$1$word$3/igm;
#$result_ref->[2] = $word;
#}

#if (   $$subj_2 ne $res->[1]
#|| $data->{lang}{is_something}{ $res->[1] } )
#{
#if (   $data->{lang}{is_something}{ $result_ref->[1] }
#|| $result_ref->[1]
#=~ /(^|\s)(es|sie|er|ihn|ihr|ihm)(\s|$)/i )
#{
#$result_ref->[1] = $res->[1];
#}
#if (   $data->{lang}{is_something}{ $result_ref->[2] }
#|| $result_ref->[2]
#=~ /(^|\s)(es|sie|er|ihn|ihr|ihm)(\s|$)/i )
#{
#$result_ref->[2] = $res->[1];
#}
#}
#if (   $$obj_2 ne $$res_obj
#|| $data->{lang}{is_something}{ $res->[1] } )
#{
#if (   $data->{lang}{is_something}{ $result_ref->[1] }
#|| $result_ref->[1]
#=~ /(^|\s)(es|sie|er|ihn|ihr|ihm)(\s|$)/i )
#{
#$result_ref->[1] = $res->[2];
#}
#if (   $data->{lang}{is_something}{ $result_ref->[2] }
#|| $result_ref->[2]
#=~ /(^|\s)(es|sie|er|ihn|ihr|ihm)(\s|$)/i )
#{
#$result_ref->[2] = $res->[2];
#}
#}

#$$subj_2 = $res->[1];
#$$obj_2  = $res->[2];

#push @facts_sub, $results_ref;
#}

####            say join ' <> ', @$result_ref if is_verbose;
#}
#my $can_use_result_from_before_check_advs = $can_use_result;

#if (@facts_sub) {
#push @facts, @facts_sub;
#next;
#}

#foreach my $adv_b (@advs) {
#my $adv = $adv_b;
#if ( $adv =~ /\s+[a-z]$/i ) {
#$adv =~ s/\s+[a-z]$/ .*?/i;
#}
#chomp $adv;
#$adv = lc $adv;
#foreach my $adverb_of_time (@adverbs_of_time) {
#$adv =~ s/^$adverb_of_time\s+//igm;
#$adv =~ s/\s+$adverb_of_time$//igm;
#$adv =~ s/\s+$adverb_of_time\s+//igm;
#}
#if (   $result_ref->[2] !~ /$adv/i
#&& $result_ref->[3] !~ /$adv/i
#&& $result_ref->[1] !~ /$adv/i )
#{
####                say 'not containing ' . $adv . ': ' . $result_ref->[3] if is_verbose;
#$can_use_result                        = 0;
#$can_use_result_from_before_check_advs = 0;
#}
#}

#if ( $description && $can_use_result ) {
#$description    = lc $description;
#$can_use_result = 0;
#$can_use_result = 1
#if $result_ref->[1] =~ /(^|\s)$description(\s|_|[;]|$)/i;
#$can_use_result = 1
#if $result_ref->[2] =~ /(^|\s)$description(\s|_|[;]|$)/i;
#$can_use_result = 1
#if $result_ref->[3] =~ /(^|\s)$description(\s|_|[;]|$)/i;
#if ( $description =~ /^lang[e]?/ ) {
#foreach my $adv (@adverbs_of_time) {
#$can_use_result = 1
#if $result_ref->[3] =~ /(^|\s)$adv(\s|_|[;]|$)/i;
#}
#}

##							foreach my $descr (keys %{$data->{lang}{is_description_synonym)}}{
##								$can_use_result = 1
##							  		if $result_ref->[3] =~ /$descr/i;
##								last if $can_use_result;
##							}
#}

#push @results_second_choice, $result_ref
#if $can_use_result
#|| $can_use_result_from_before_check_advs;

##		if ( !$description ) {
##			if ($can_use_result) {
##				my @word_count =
##				  split( / /, scalar $result_ref->[2] );
##				if ( @word_count > 1 ) {
##					$can_use_result = 0;
##				}
##			}
##		}

#push @results, $result_ref
#if $can_use_result;

####        say '$can_use_result:                        ', $can_use_result if is_verbose;
####        say '$can_use_result_from_before_check_advs: ',
##            $can_use_result_from_before_check_advs if is_verbose;

##					print Dumper $result_ref;
#}

#return ( \@results, [] );
#}

sub set_percent {
    my ( $CLIENT_ref, $percent ) = @_;
    my $CLIENT = $$CLIENT_ref;

    return if $percent > 100;

    print $CLIENT 'PERCENT:', $percent, "\n" if !eof($CLIENT);
}


sub search_facts_in_semantic_net_normal {
    my (
        $CLIENT_ref,                   $is_verb_synonym_ref,
        $is_subj_noun_synonym_ref,     $is_obj_noun_synonym_ref,
        $is_description_synonym_ref,   $find_entries_with_variables,
        $search_for_something_entries, $search_for_any_entries,
    ) = @_;

    # 0: never
    # 1: when necessary
    # 2: always
    $search_for_something_entries = 1
      if !defined $search_for_something_entries;

    # initialize selector
    my $selector = AI::Selector->new(
        is_subj => $is_subj_noun_synonym_ref,
        is_obj  => $is_obj_noun_synonym_ref,
    );
    my $selector_for_description_as_subject = AI::Selector->new(
        is_subj => $is_description_synonym_ref,
        is_obj  => $is_obj_noun_synonym_ref,
    );
    my $selector_for_description_as_object = AI::Selector->new(
        is_subj => $is_subj_noun_synonym_ref,
        is_obj  => $is_description_synonym_ref,
    );

    my @facts_style_semantic_net      = ();
    my @facts_style_semantic_net_subj = ();
    my @facts_style_semantic_net_obj  = ();

    my $count_facts_with_right_subject = 0;
    my $something_is_subject =
      $selector->modern_match( or => [ { su => 'a' }, { ob => 'a' }, ] );
    ## AI::Selector::traditional_match( $is_subj_noun_synonym_ref, 'a' )
    ## || AI::Selector::traditional_match( $is_obj_noun_synonym_ref, 'a' );

    semantic_network_connect(
        dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
        config => \%config
    );

    if ( !$find_entries_with_variables ) {

        # all words to search for in semantic net
        my @all_words = ();

        my $i = 0;
        foreach my $hash_ref_2 (
            @{$is_subj_noun_synonym_ref},
            @{$is_obj_noun_synonym_ref},
            $data->{lang}{is_description_synonym_ref}
          )
        {
            $i += 1;

#set_percent( $CLIENT_ref, (50 * $i / scalar @{ $data->{lang}{is_subj_noun_synonym_ref}}) ) if $i % 50 == 0;

            foreach my $hash_ref ( @{ $hash_ref_2->{'___'} } ) {
                foreach my $synonym ( keys %$hash_ref ) {
                    $synonym = '$$anything$$' if $synonym =~ /^[a-h][-~]?$/;
                    say '=> ', $synonym if is_verbose;

                    push @all_words, $synonym;
                }
            }
        }

        my %hash_all_words = map { $_ => 1 } @all_words;
        @all_words = keys %hash_all_words;

        if ( $data->{caches}{cache_semantic_net_get_key_for_item}
            { Dumper \@all_words } )
        {
            return;
        }
        my $result_from_net =
          semantic_net_get_key_for_item( \@all_words, 'facts' );
        $data->{caches}{cache_semantic_net_get_key_for_item}
          { Dumper \@all_words } = $result_from_net;

        if ($result_from_net) {
            foreach my $fact ( @{$result_from_net} ) {
                if ( !$fact ) {
                    next;
                }

                if ( $fact->{verb} eq '=' ) {
                    next;
                }

                #print Dumper $fact;

                if (
                    (
                           !$is_verb_synonym_ref->{ $fact->{verb} }
                        && !scalar grep { $is_verb_synonym_ref->{ $_->{verb} } }
                        @{ $fact->{subclauses} || [] }
                    )
                  )
                {
                    next;
                }
                if ( $is_verb_synonym_ref->{'everything'} ) {
                    if (   $data->{lang}{is_be}{ $fact->{verb} }
                        || $fact->{verb} eq 'hat'
                        || $fact->{verb} eq 'haben'
                        || $fact->{verb} eq 'have'
                        || $fact->{verb} eq 'has'
                        || $fact->{verb} eq 'mag'
                        || $fact->{verb} eq 'magst' )
                    {
                        next;
                    }
                }

                if (
                    $data->{lang}{is_be}{ $fact->{verb} }
                    && (  !$fact->{obj}->{name}
                        || $fact->{obj}->{name} =~ /nothing/ )
                  )
                {
                    next;
                }

                if (
                    $selector->modern_match(
                        and => [
                            { su => $fact->{subj}->{name} },
                            { ob => 'nothing' },
                        ]
                    )
                    || $selector->modern_match(
                        and => [
                            { su => $fact->{subj}->{name} },
                            { ob => $fact->{obj}->{name} },
                        ]
                    )
                  )
                {
                    push @facts_style_semantic_net_subj,
                      format_convert_hash_to_array( fact => $fact );
                    $count_facts_with_right_subject += 1
                      if !$something_is_subject;

                    say 'added ok';
                }

                elsif (
                    $selector->modern_match(
                        and => [
                            { su => $fact->{obj}->{name} },
                            { ob => 'nothing' },
                        ]
                    )
                    || $selector->modern_match(
                        and => [
                            { su => $fact->{obj}->{name} },
                            { ob => $fact->{subj}->{name} },
                        ]
                    )
                  )
                {
                    $count_facts_with_right_subject += 1
                      if !$something_is_subject;

                    push @facts_style_semantic_net_subj,
                      format_convert_hash_to_array( fact => $fact );

                    say 'added ok';
                }
                elsif (
                    $selector_for_description_as_subject->modern_match(
                        and => [
                            { su => $fact->{obj}->{name} },
                            { ob => 'nothing' },
                        ]
                    )
                    || $selector_for_description_as_subject->modern_match(
                        and => [
                            { su => $fact->{obj}->{name} },
                            { ob => $fact->{subj}->{name} },
                        ]
                    )
                  )
                {
                    push @facts_style_semantic_net_subj,
                      format_convert_hash_to_array( fact => $fact );
                }
                elsif (
                    $selector_for_description_as_object->modern_match(
                        and => [
                            { su => $fact->{obj}->{name} },
                            { ob => $fact->{subj}->{name} },
                        ]
                    )
                  )
                {
                    push @facts_style_semantic_net_subj,
                      format_convert_hash_to_array( fact => $fact );
                }
            }
        }

    }
    else {
        push @facts_style_semantic_net,
          map { format_convert_hash_to_array( fact => $_ ) }
          grep { $is_verb_synonym_ref->{ $_->{verb} } }
          @{ semantic_net_get_variable_dialog_features() }
          if semantic_net_get_variable_dialog_features();
    }

    my @facts_style_semantic_net_with_variables = ();
    my @facts_style_semantic_net_with_all_facts = ();

    #say 91;

    if (   $search_for_something_entries == 1
        || $search_for_something_entries == 2
        || $search_for_any_entries )
    {
        say '$search_for_any_entries: ', $search_for_any_entries
          if is_verbose;
        say '$count_facts_with_right_subject: ', $count_facts_with_right_subject
          if is_verbose;

#foreach my $synonym ( (join '', ('a' .. 'h')), keys %{$data->{lang}{is_something}}) {
#unshift @facts_style_semantic_net_with_all_facts,
#@{ semantic_net_get_key_for_item( $synonym,
#'facts_variables' ) }
#if semantic_net_get_key_for_item( $synonym,
#'facts_variables' )
#&& $search_for_any_entries
#&& !@facts_style_semantic_net_with_all_facts;
#unshift @facts_style_semantic_net_with_variables,
#@{ semantic_net_get_key_for_item( $synonym, 'facts' ) }
#if semantic_net_get_key_for_item( $synonym, 'facts' )
#&& !@facts_style_semantic_net_with_variables;
#}
        say '@facts_style_semantic_net_with_all_facts: ',
          scalar @facts_style_semantic_net_with_all_facts
          if is_verbose;

        #select undef, undef, undef, 5;
    }

    #say 92;
    if ($find_entries_with_variables) {

        #@facts_style_semantic_net_subj
        #= grep { $_->{verb} =~ /[=][>]/ }
        #@facts_style_semantic_net_subj;
        #@facts_style_semantic_net
        #= grep { $_->{verb} =~ /[=][>]/ }
        #@facts_style_semantic_net;
    }
    else {
        @facts_style_semantic_net_subj = grep {
            !grep { $_->[0] =~ /[=][>]/ }
              @{ $_->[4] }
        } @facts_style_semantic_net_subj;
        @facts_style_semantic_net = grep {
            !grep { $_->[0] =~ /[=][>]/ }
              @{ $_->[4] }
        } @facts_style_semantic_net;
    }

    #say 94;
    if (@facts_style_semantic_net_subj) {

        #say 95;
        @facts_style_semantic_net = @facts_style_semantic_net_subj;
    }

    #print 3, Dumper @facts_style_semantic_net_subj;

    my @facts_style_normal = ();

    my %facts_style_semantic_net_hash =
      map { $_ => $_ } @facts_style_semantic_net;
    @facts_style_semantic_net = values %facts_style_semantic_net_hash;

    #print 4, Dumper @facts_style_semantic_net_subj;

    my %facts_style_semantic_net_with_variables_hash =
      map { $_ => $_ } @facts_style_semantic_net_with_variables;
    @facts_style_semantic_net_with_variables =
      values %facts_style_semantic_net_with_variables_hash;

    #unshift @facts_style_semantic_net,
    #    @facts_style_semantic_net_with_variables
    #    if ( !$search_for_any_entries );
    #
    #unshift @facts_style_semantic_net,
    #    @facts_style_semantic_net_with_all_facts
    #    if (   $count_facts_with_right_subject == 0
    #        && $search_for_any_entries );

    my $i = 0;
    foreach my $fact (@facts_style_semantic_net) {
        $i += 1;

        next if $fact->[4] =~ /wenn|if|falls|when/;

        next
          if !$is_verb_synonym_ref->{ $fact->[0] }
              && ( !scalar grep { $is_verb_synonym_ref->{ $_->[0] } }
                  @{ $fact->[4] || [] } )
              && (  !$is_verb_synonym_ref->{'everything'}
                  || $data->{lang}{is_be}{ $fact->[0] }
                  || $data->{lang}{is_not_acceptable_as_everything}
                  { $fact->[0] } );

        next
          if $data->{lang}{is_names_and_nouns_obj}{ $fact->[2] }
              || $data->{lang}{is_time_measurements_obj}{ $fact->[2] };

        push @facts_style_normal, $fact;
    }

    return @facts_style_normal;
}

sub format_convert_hash_to_array {

    # parameters
    my %arg = ();
    %arg = ( %arg, @_ );

    # better names
    my $fact = $arg{fact};

    return if !$fact;

    my $new_fact = [
        $fact->{verb}, $fact->{subj}->{name},
        $fact->{obj}->{name}, ( join ';', @{ $fact->{advs} } ),
        [], $fact->{prio},
    ];
    foreach my $sub_clause ( @{ $fact->{subclauses} } ) {
        push @{ $new_fact->[4] },
          [
            $sub_clause->{verb},
            $sub_clause->{subj}->{name},
            $sub_clause->{obj}->{name},
            ( join ';', @{ $sub_clause->{advs} } ),
            $sub_clause->{questionword},
          ];
    }

    %{ $arg{fact} } = ();
    undef $arg{fact};
    delete $arg{fact};

    return $new_fact;
}

#use Memoize;
#memoize('search_facts_in_semantic_net_normal');
#memoize('search_semantic');

sub remove_something_words_from {
    my $item = join ' ', @_;
    foreach my $something_word ( keys %{ $data->{lang}{is_something} } ) {
        $item =~ s/\s+$something_word\s+/ /igm;
        $item =~ s/\s+$something_word[;]/;/igm;
        $item =~ s/^$something_word\s+//igm;
        $item =~ s/^$something_word[;]//igm;
        $item =~ s/\s+$something_word$/ /igm;
        $item =~ s/\s+$something_word$/;/igm;
        $item =~ s/^$something_word$//igm;
        $item =~ s/^$something_word$//igm;
    }
    return $item;
}

my $variable_solutions_not_found_hash = {};

sub solve_variable_problems {
    my (
        $CLIENT_ref,                  $is_verb_synonym_ref,
        $is_subj_noun_synonym_ref,    $is_obj_noun_synonym_ref,
        $sentence_ref,                $description,
        $is_description_synonym_ref,  $sub,
        $obj,                         $advs_ref,
        $find_entries_with_variables, $is_question,
        $do_not_skip,                 $times,
    ) = @_;

    say '#################################################';
    say ' Starting       solve_variable_problems';
    say '#################################################';

    $times ||= 0;

    $variable_solutions_not_found_hash = {} if !$times;

    $data->{lang}{is_subj_noun_synonym_ref} = [ noun_synonyms( $sub, 0, 1 ) ];
    $data->{lang}{is_obj_noun_synonym_ref}  = [ noun_synonyms( $obj, 0, 1 ) ];

    my @is_verb_synonym_array;    # = ( $is_verb_synonym_ref, );
    my @is_subj_synonym_array;    # = ( $is_subj_noun_synonym_ref, );
    my @is_obj_synonym_array;     # = ( $is_obj_noun_synonym_ref, );
    my @sentence_array;           # = ( $sentence_ref, );
    my @description_array;        # = ( $description, );
    my @description_syn_array;    # = ( $is_description_synonym_ref, );
    my @sub_array;                # = ( $sub, );
    my @obj_array;                # = ( $obj, );
    my @advs_array;               # = ( $advs_ref, );

    my $VAR1 = undef;
    eval Dumper $is_verb_synonym_ref;
    my @is_verb_synonym_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $is_subj_noun_synonym_ref;
    my @is_subj_synonym_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $is_obj_noun_synonym_ref;
    my @is_obj_synonym_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $sentence_ref;
    my @sentence_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $description;
    my @description_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $is_description_synonym_ref;
    my @description_syn_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $sub;
    my @sub_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $obj;
    my @obj_array_base = $VAR1;
    undef $VAR1;
    eval Dumper $advs_ref;
    my @advs_array_base = $VAR1;

#say Dumper $is_subj_synonym_array[-1]->[0]->{'___'}->[-1];
#say Dumper grep { /kuenst/ } keys %{ $is_subj_synonym_array[-1]->[0]->{'___'}->[-1] };
#select undef, undef, undef, 15;

    my @is_verb_synonym_array_second = ( $is_verb_synonym_ref, );
    my @is_subj_synonym_array_second = ( $is_subj_noun_synonym_ref, );
    my @is_obj_synonym_array_second  = ( $is_obj_noun_synonym_ref, );
    my @sentence_array_second        = ( $sentence_ref, );
    my @description_array_second     = ( $description, );
    my @description_syn_array_second = ( $is_description_synonym_ref, );
    my @sub_array_second             = ( $sub, );
    my @obj_array_second             = ( $obj, );
    my @advs_array_second            = ( $advs_ref, );

    return [ [], [] ]
      if (
        $variable_solutions_not_found_hash->{ md5 Dumper $data->{lang}
                {is_subj_noun_synonym_ref}
              . md5 Dumper $data->{lang}{is_obj_noun_synonym_ref}
              . md5 Dumper $data->{lang}{is_verb_synonym_ref}
              . md5 Dumper $advs_ref
        }
      );

    semantic_network_connect(
        dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
        config => \%config
    );

    # solve:
    my @variable_terms = ();
    foreach my $synonym ( ('$$anything$$') ) {
        unshift @variable_terms,
          @{ semantic_net_get_key_for_item( $synonym, 'facts' ) }
          if semantic_net_get_key_for_item( $synonym, 'facts' );
    }

    foreach my $term (
        $data->{lang}{is_question}

# && !(lc $sentence_ref->{'questionword'} eq 'was' && $is_verb_synonym_ref->{'ist'} )
        ? reverse @variable_terms
        : ()
      )
    {
        if ( ref($term) ne 'HASH' ) {
            say 'no hash.';
            next;
        }

        print Dumper $term if Dumper($term) =~ /durchmesser/i;

        my @if_clauses = grep {
            ( ref($_) eq 'HASH'
                  && $data->{lang}{is_if_word}{ $_->{questionword} || '' } )
        } @{ $term->{subclauses} || [] };
        my $if_clause = shift @if_clauses;
        while ( !$if_clause && defined $if_clause ) {
            $if_clause = shift @if_clauses;
        }
        if ( !$if_clause ) {

            #say 'no if-clause in: ', Dumper $term;
            next;
        }

        ( $term, $if_clause ) = ( $if_clause, $term );

        if ( !$is_verb_synonym_ref->{ $if_clause->{verb} } ) {
            say 'verb not matching: ',
              $if_clause->{verb};    #, Dumper ($if_clause, $term);
            next;
        }
        else {
            say 'verb matching: ', $if_clause->{verb};
        }

        #say 11112;

        map { s/\s+$//igm; } @{ $if_clause->{advs} };
        map { s/^\s+//igm; } @{ $if_clause->{advs} };
        @{ $if_clause->{advs} } =
          grep { $_ !~ /nothing/ } grep { $_ } @{ $if_clause->{advs} };

        my $advs_found = 0;
        my $advs_max   = @{ $if_clause->{advs} };
        if ($advs_max) {
            foreach my $adv ( @{ $if_clause->{advs} } ) {

                $adv =~ s/[;]/ /igm;

                if ( $data->{lang}{is_adverb_of_time}{$adv} ) {
                    $advs_found += 1;
                }

                elsif ( $adv =~ /(nicht|not)/i ) {
                    $advs_found += 1;
                }

                elsif ( ( join ' ', @{$advs_ref} ) =~ /$adv/i ) {
                    $advs_found += 1;
                }

                elsif ( $description =~ /$adv/i ) {
                    $advs_found += 1;
                }
            }
            if ( $advs_found < $advs_max ) {
                next;
            }
        }

        $advs_found = 0;
        $advs_max   = @{$advs_ref};
        if ($advs_max) {
            foreach my $adv ( @{$advs_ref} ) {

                $adv =~ s/[;]/ /igm;

                if ( $data->{lang}{is_adverb_of_time}{$adv} ) {
                    $advs_found += 1;
                }

                elsif ( ( join ' ', @{ $if_clause->{advs} } ) =~ /$adv/i ) {
                    $advs_found += 1;
                }

                elsif ( $adv =~ /(nicht|not)/i ) {
                    $advs_found += 1;
                }

            }
            if ( $advs_found < $advs_max ) {
                next;
            }
        }

        say 11113;
        say $sub;
        push @is_verb_synonym_array, $is_verb_synonym_ref;
        push @is_subj_synonym_array, $is_subj_noun_synonym_ref;
        push @is_obj_synonym_array,  $is_obj_noun_synonym_ref;
        push @sentence_array,        $sentence_ref;
        push @description_array,     $description;
        push @description_syn_array, $is_description_synonym_ref;
        push @sub_array,             $sub;
        push @obj_array,             $obj;
        push @advs_array,            $advs_ref;

        my $advs_ok = 0;

        my $term_3 = join ';', @{ $term->{advs} };

        my $changed_something_relevant = 0;

        #say 11114;
        if (   $data->{lang}{is_something}{ $if_clause->{subj}->{name} }
            && $if_clause->{subj}->{name} eq $term->{obj}->{name} )
        {

            # if clause: from variable db
            #
            # this       | if-clause ||      term
            # ------------------------------------
            # known      | A         || ...
            # known      | ...       || A

            $is_obj_synonym_array[-1] = $is_subj_noun_synonym_ref;
            $obj_array[-1] = $is_subj_noun_synonym_ref->[0]{'_main_original'};
            say 2121;
            $is_obj_synonym_array[-1] = [ noun_synonyms( $obj_array[-1] ) ];
            $changed_something_relevant = 1;
        }

        if (   $data->{lang}{is_something}{ $if_clause->{subj}->{name} }
            && $if_clause->{subj}->{name} eq $term->{subj}->{name} )
        {

            # if clause: from variable db
            #
            # this       | if-clause ||      term
            # ------------------------------------
            # known      | A         || A
            # known      | ...       || ...

# $sub_array[-1]             = $is_subj_noun_synonym_ref->[0]{'_main_original'};
            say 2122;
            $is_subj_synonym_array[-1]  = [ noun_synonyms( $sub_array[-1] ) ];
            $obj_array[-1]              = $term->{obj}->{name};
            $is_obj_synonym_array[-1]   = [ noun_synonyms( $obj_array[-1] ) ];
            $changed_something_relevant = 1;
        }

        #say 11115;
        my $if_clause_subj = $if_clause->{subj}->{name};
        if (   $data->{lang}{is_something}{ $if_clause->{subj}->{name} }
            && $term_3 =~ /(^|[\s_,;])$if_clause_subj([\s_,;]|$)/i )
        {

            my @term_3_array =
              split /(^|(?<=^[\s_,;]))$if_clause_subj(?=[\s_,;]|$)/i, $term_3;
            my $tr = $is_subj_noun_synonym_ref->[0]{'_main_original'};
            $tr = '' if ( $data->{lang}{is_something}{$tr} );
            $advs_array[-1] = [ join $tr, @term_3_array ];
            $advs_array[-1]->[0] =
              remove_something_words_from( $advs_array[-1]->[0] );
            $advs_ok                    = 1;
            $changed_something_relevant = 1;
        }

        if (   $data->{lang}{is_something}{ $if_clause->{obj}->{name} }
            && $if_clause->{obj}->{name} eq $term->{subj}->{name} )
        {

            $is_subj_synonym_array[-1] = $is_obj_noun_synonym_ref;

 # $sub_array[-1]             = $is_obj_noun_synonym_ref->[0]{'_main_original'};
            $sub_array[-1] = $obj_array[-1];
            say 2123;
            $is_subj_synonym_array[-1] = [ noun_synonyms( $sub_array[-1] ) ];
            $changed_something_relevant = 1;
        }

        if (   $obj_array[-1] eq 'nothing'
            && $term->{obj}->{name} ne 'nothing' )
        {

            $is_obj_synonym_array[-1] =
              [ noun_synonyms( $term->{obj}->{name} ) ];
            $obj_array[-1] = $term->{obj}->{name};

            $advs_ok                    = 1;
            $changed_something_relevant = 1;
        }

        #say 11116;
        my $if_clause_obj = $if_clause->{obj}->{name};
        say '$term_3 =~ /(^|[\s_,;])$if_clause_obj([\s_,;]|$)/i:', "\n",
          ' ' x 4, ( $term_3 =~ /(^|[\s_,;])$if_clause_obj([\s_,;]|$)/i );
        if (   $data->{lang}{is_something}{ $if_clause->{obj}->{name} }
            && $term_3 =~ /(^|[\s_,;])$if_clause_obj([\s_,;]|$)/i )
        {
            my @term_3_array =
              split /(^|(?<=^[\s_,;]))$if_clause_obj(?=[\s_,;]|$)/i, $term_3;
            my $tr = $is_obj_synonym_array[-1]->[0]->{'_main_original'};
            $tr = '' if ( $data->{lang}{is_something}{$tr} );
            $advs_array[-1] = [ join $tr, @term_3_array ];
            $advs_array[-1]->[0] =
              remove_something_words_from( $advs_array[-1]->[0] );

            $is_obj_synonym_array[-1] =
              [ noun_synonyms( $term->{obj}->{name} ) ];

            $advs_ok                    = 1;
            $changed_something_relevant = 1;
        }

        my $description_found_in_if_clause = 0;

        if ( !$advs_ok || $description ) {

            my $descr = '' . $description;
            say 'descr: ', $descr;

            #$changed_something_relevant = 1;

            #say (join ';', @{$if_clause->{advs}}) =~ /$description_array[-1]/i;
            if (   !$advs_ok
                && ( join ';', @{ $if_clause->{advs} } ) =~ /$descr/i
                && $descr )
            {
                $description_found_in_if_clause = 1;
                $changed_something_relevant = 1 if !$advs_ok && $descr;

                $description_array[-1] = $term_3;
                $advs_array[-1]        = [$term_3];
                $advs_array[-1]->[0] =
                  remove_something_words_from( $advs_array[-1]->[0] );
                my @description_words = split /[_\s]+/, $description_array[-1];
                my $description_last_word = $description_words[-1];
                say "pos_of( $CLIENT_ref, $description_last_word ):";
                say '    ',
                  pos_of( $CLIENT_ref, ucfirst $description_last_word, 0, 0,
                    0 );

                if (
                    pos_of( $CLIENT_ref, ucfirst $description_last_word,
                        0, 0, 0 ) == $data->{const}{NOUN}
                    || pos_of( $CLIENT_ref, lc $description_last_word ) ==
                    $data->{const}{NOUN}
                  )
                {
                    $description_syn_array[-1] =
                      noun_synonyms( $description_array[-1], 0, 1 );
                }
                else {
                    $description_syn_array[-1] =
                      { $description_array[-1] => 1 };
                }

                $advs_ok = 1;

                #say $description_array[-1];
                #exit 0;
                #### $description_array[-1] = '';
            }
            elsif ( $advs_ok
                && ( join ' ', @{ $if_clause->{advs} } ) =~ /$descr/i )
            {
                $description_found_in_if_clause = 1;
                #### $description_array[-1] = '';
            }
        }

        if ($description_found_in_if_clause) {
            $description_array[-1] = '';
            %{ $description_syn_array[-1] } = ();
        }

        $is_verb_synonym_array[-1] = verb_synonyms( $term->{verb} )
          if !$is_verb_synonym_array[-1]->{ $term->{verb} }
              && $term->{verb};
        say $term->{verb};

        #$sub_array[-1] = $is_subj_synonym_array[-1]->[0]->{'_main_original'};
        #$obj_array[-1] = $is_obj_synonym_array[-1]->[0]->{'_main_original'};

        my $already_indexed = 0;

        foreach my $index ( 0 .. scalar @is_subj_synonym_array - 2 ) {
            say( join ' ', @{ $advs_array[-1] } );
            say( join ' ', @{ $advs_array[$index] } );
            if (
                (
                    scalar grep {
                        $_->{'_main_original'} eq
                          $is_subj_synonym_array[-1]->[0]->{'_main_original'}
                    } grep { $_ }
                    map { @$_ } ( $is_subj_synonym_array[$index], )
                )
                && (
                    scalar grep {
                        say q{$_->{'_main_original'}: }, $_->{'_main_original'};
                        say
q{$is_obj_synonym_array[-1]->[0]->{'_main_original'}: },
                          $is_obj_synonym_array[-1]->[0]->{'_main_original'};
                        say q{$_->{'_main_original'} eq
                            $is_obj_synonym_array[-1]->[0]->{'_main_original'}: },
                          $_->{'_main_original'} eq
                          $is_obj_synonym_array[-1]->[0]->{'_main_original'};
                        $is_obj_synonym_array[-1]->[0]->{'_main_original'} ||=
                          'nothing';
                        $_->{'_main_original'} eq
                          $is_obj_synonym_array[-1]->[0]->{'_main_original'}
                    } grep { $_ }
                    map { @$_ } ( $is_obj_synonym_array[$index], )
                )
                && (
                    scalar
                    grep { $_->{ ( keys %{ $is_verb_synonym_array[-1] } )[0] } }
                    ( $is_verb_synonym_array[$index], )
                )
                && ( ( join ' ', @{ $advs_array[-1] } ) eq
                    ( join ' ', @{ $advs_array[$index] } ) )
              )
            {

                $already_indexed = 1 if @is_verb_synonym_array > 1;
                say '$already_indexed = 1;';
                last;
            }
        }

        if (  !$changed_something_relevant
            || $already_indexed
            || !( keys %{ $is_verb_synonym_array[-1] } ) )
        {

           #            say;
           #            say '$changed_something_relevant: ',
           #                $changed_something_relevant;
           #            say '$already_indexed:            ', $already_indexed;
           #            #say join ', ', keys %{$is_verb_synonym_array[-1]};
           #            say $is_subj_synonym_array[-1]->[0]->{'_main_original'};
           #            say $is_obj_synonym_array[-1]->[0]->{'_main_original'};
           #            say Dumper $advs_array[-1];
           #            say 'advs_ok: ', $advs_ok;
           #            say Dumper $if_clause;
           #            say $description_array[-1];

            push @is_verb_synonym_array_second, pop @is_verb_synonym_array;
            push @is_subj_synonym_array_second, pop @is_subj_synonym_array;
            push @is_obj_synonym_array_second,  pop @is_obj_synonym_array;
            push @sentence_array_second,        pop @sentence_array;
            push @description_array_second,     pop @description_array;
            push @description_syn_array_second, pop @description_syn_array;
            push @sub_array_second,             pop @sub_array;
            push @obj_array_second,             pop @obj_array;
            push @advs_array_second,            pop @advs_array;
            next;
        }

        $obj_array[-1] ||= 'nothing';

        $is_subj_synonym_array[-1] = [ noun_synonyms( $sub_array[-1], 0, 1 ) ];
        $is_obj_synonym_array[-1]  = [ noun_synonyms( $obj_array[-1], 0, 1 ) ];

        say Dumper $if_clause;

    }

    if ( $times && !grep { $_ } @is_subj_synonym_array ) {
        say '#################################################';
        say ' Finishing       solve_variable_problems';
        say '#################################################';
        return [ [], [] ];
    }

    while ( grep { $_ } @is_verb_synonym_array
        && !( keys %{ $is_verb_synonym_array[0] } )[0] )
    {

        push @is_verb_synonym_array_second, shift @is_verb_synonym_array;
        push @is_subj_synonym_array_second, shift @is_subj_synonym_array;
        push @is_obj_synonym_array_second,  shift @is_obj_synonym_array;
        push @sentence_array_second,        shift @sentence_array;
        push @description_array_second,     shift @description_array;
        push @description_syn_array_second, shift @description_syn_array;
        push @sub_array_second,             shift @sub_array;
        push @obj_array_second,             shift @obj_array;
        push @advs_array_second,            shift @advs_array;
    }

    if ( !$times ) {
        unshift @is_verb_synonym_array, @is_verb_synonym_array_base;
        unshift @is_subj_synonym_array, @is_subj_synonym_array_base;
        unshift @is_obj_synonym_array,  @is_obj_synonym_array_base;
        unshift @sentence_array,        @sentence_array_base;
        unshift @description_array,     @description_array_base;
        unshift @description_syn_array, @description_syn_array_base;
        unshift @sub_array,             @sub_array_base;
        unshift @obj_array,             @obj_array_base;
        unshift @advs_array,            @advs_array_base;
    }

    say "solved:";
    say scalar @is_verb_synonym_array, " different facts generated.";
    say;
    say join ', ',
      map { $_->{'_main_original'} . ' - ' . scalar @{ $_->{'___'} || [] } }
      map { @$_ ? @$_ : $_ } grep { $_ } @is_subj_synonym_array;
    say join ', ', map { $_->{'_main_original'} }
      map { @$_ ? @$_ : $_ } grep { $_ } @is_obj_synonym_array;
    say join '; ', map { join ',', ( keys %$_ )[ 0 .. 1 ] }
      grep { $_ } @is_verb_synonym_array;
    say join ', ', map { join ' - ', (@$_) } grep { $_ } @advs_array;
    say;

    #    say Dumper \@is_obj_synonym_array;
    say;

    my $result = search_semantic(
        $CLIENT_ref,                  \@is_verb_synonym_array,
        \@is_subj_synonym_array,      \@is_obj_synonym_array,
        \@sentence_array,             \@description_array,
        \@description_syn_array,      \@sub_array,
        \@obj_array,                  \@advs_array,
        $find_entries_with_variables, $is_question,
        $do_not_skip,
    );

    say scalar @{ $result->[0] }, ' results found,', "\n",
      scalar @{ $result->[1] }, ' half results found.';

    #select undef, undef, undef, 5 if scalar @is_verb_synonym_array;

    if ( $times > 5 || ( !$data->{lang}{is_question} && $times > 1 ) ) {
        say '#################################################';
        say ' Finishing (1)   solve_variable_problems';
        say '#################################################';
        return [ [], [] ];
    }

    if ( ( !@{ $result->[0] || [] } && @is_verb_synonym_array == 1 ) ) {
        $result = search_semantic(
            $CLIENT_ref,                    \@is_verb_synonym_array_second,
            \@is_subj_synonym_array_second, \@is_obj_synonym_array_second,
            \@sentence_array_second,        \@description_array_second,
            \@description_syn_array_second, \@sub_array_second,
            \@obj_array_second,             \@advs_array_second,
            $find_entries_with_variables,   $is_question,
            $do_not_skip,
        );

        say scalar @{ $result->[0] }, ' results found (second),', "\n",
          scalar @{ $result->[1] }, ' half results found (second).';
    }

    if ( ( !@{ $result->[0] || [] } && @is_verb_synonym_array == 1 ) ) {
        $variable_solutions_not_found_hash
          ->{   md5 Dumper $is_subj_synonym_array[0]
              . md5 Dumper $is_obj_synonym_array[0]
              . md5 Dumper $is_verb_synonym_array[0]
              . md5 Dumper $advs_array[0] } = 1;
        say '#################################################';
        say ' Finishing (2)   solve_variable_problems';
        say '#################################################';
        return [ [], [] ];
    }

    if ( !@{ $result->[0] || [] } && !@{ $result->[1] || [] } ) {
        foreach my $masterindex ( shuffle 0 .. @is_verb_synonym_array ) {
            next if !$is_verb_synonym_array[$masterindex];
            my $key = Dumper [

                $sub_array[$masterindex],
                $obj_array[$masterindex],
                $advs_array[$masterindex],

            ];
            if ( $data->{caches}{cache_semantic_net_get_key_for_item}{$key} ) {
                next;
            }
            $data->{caches}{cache_semantic_net_get_key_for_item}{$key} = 1;

            say 'try with other question...';
            my $new_result = solve_variable_problems(
                $CLIENT_ref,
                $is_verb_synonym_array[$masterindex],
                $is_subj_synonym_array[$masterindex],
                $is_obj_synonym_array[$masterindex],
                $sentence_array[$masterindex],
                '',
                $description_syn_array[$masterindex],
                $sub_array[$masterindex],
                $obj_array[$masterindex],
                $advs_array[$masterindex],
                $find_entries_with_variables,
                $is_question,
                $do_not_skip,
                $times + 1,
            );

            say '#################################################';
            say ' Finishing (3)   solve_variable_problems';
            say '#################################################';
            return $new_result if @{ $new_result->[0] || [] };
        }
    }

    # second try

    #select undef, undef, undef, 5 if scalar @is_verb_synonym_array;

    say '#################################################';
    say ' Finishing (4)   solve_variable_problems';
    say '#################################################';
    return $result;
}

#my %cache_search_semantic = ();

sub search_semantic {
    my (
        $CLIENT_ref,                   $is_verb_synonym_ref_2,
        $is_subj_noun_synonym_ref_2,   $is_obj_noun_synonym_ref_2,
        $sentence_ref_2,               $description_2,
        $is_description_synonym_ref_2, $sub_2,
        $obj_2,                        $advs_ref_2,
        $find_entries_with_variables,  $is_question,
        $do_not_skip,
    ) = @_;

    #    my $cache_search_semantic_key
    #            = join ',', ((Dumper $sub_2),
    #                         (Dumper $obj_2),
    #                         (Dumper $is_verb_synonym_ref_2),
    #                         (Dumper $is_description_synonym_ref_2),
    #                         $find_entries_with_variables,);
    #
    #    if ( $cache_search_semantic{ $cache_search_semantic_key } ) {
    #        return $cache_search_semantic{ $cache_search_semantic_key };
    #    }

    $find_entries_with_variables = 0
      if !defined $find_entries_with_variables;

    say '$find_entries_with_variables:' if is_verbose;
    say '    ', $find_entries_with_variables if is_verbose;

    my $best_to_return = undef;

    foreach my $masterindex ( 0 .. @$is_verb_synonym_ref_2 ) {
        my ${is_subj_noun_synonym_ref} =
          $is_subj_noun_synonym_ref_2->[$masterindex];
        my ${is_obj_noun_synonym_ref} =
          $is_obj_noun_synonym_ref_2->[$masterindex];
        my ${is_verb_synonym_ref} = $is_verb_synonym_ref_2->[$masterindex];
        my $description = $description_2->[$masterindex];
        my ${is_description_synonym_ref} =
          $is_description_synonym_ref_2->[$masterindex];
        my $sub          = $sub_2->[$masterindex];
        my $obj          = $obj_2->[$masterindex];
        my $advs_ref     = $advs_ref_2->[$masterindex];
        my $sentence_ref = $sentence_ref_2->[$masterindex];

        #exit 1 if $is_verb_synonym_ref_2->[$masterindex - 1]->{'hat'};

        my $CLIENT = $$CLIENT_ref;
        next if !$is_verb_synonym_ref;
        next if !$is_subj_noun_synonym_ref;
        my %is_verb_synonym        = %$is_verb_synonym_ref;
        my @is_subj_noun_synonym   = @$is_subj_noun_synonym_ref;
        my @is_obj_noun_synonym    = @$is_obj_noun_synonym_ref;
        my %is_description_synonym = %$is_description_synonym_ref;
        my @advs                   = @$advs_ref;

        next if !@is_subj_noun_synonym;
        next if !scalar grep { $_->{'_main_original'} } @is_subj_noun_synonym;

        say 'description synonyms:' if is_verbose;

#	say join ', ', keys %{$data->{lang}{is_description_synonym;}}        say( $sentence_ref->{'questionword'} =~ /^welch/i ) if is_verbose;

        if ( !$sentence_ref->{questionword} ) {
            @is_subj_noun_synonym = noun_synonyms( $sub, 0, 0 );
            @is_obj_noun_synonym  = noun_synonyms( $obj, 0, 0 );
        }

        #	print Dumper $advs_ref;
        print $description if is_verbose;

        #	exit 0;

        my @results               = ();
        my @results_second_choice = ();

#	say 'keys %{$data->{lang}{is_verb_synonym:}}', join '; ', keys %{$data->{lang}{is_verb_synonym;}}        say $obj =~ /nothing/ if is_verbose;

        #print Dumper \@is_subj_noun_synonym;

        my $what_is_mode = 0;

        my @facts = ();

        ###
        # "what is XYZ?" and "was ist XYZ?"
        ###
        if (
            ( !length($description) || $sub =~ /nothing/ || !$sub )
            && (   lc $sentence_ref->{'questionword'} eq 'was'
                || lc $sentence_ref->{'questionword'} eq 'what' )
            && (   $data->{lang}{is_verb_synonym}{'ist'}
                || $data->{lang}{is_verb_synonym}{'is'}
                || $data->{lang}{is_verb_synonym}{'sind'}
                || $data->{lang}{is_verb_synonym}{'are'} )
            && !$find_entries_with_variables
          )
        {
            $what_is_mode = 1;
            say 2 if is_verbose;
            my $advs_str = join ' ', @advs;
            if ( $sub =~ /nothing/ && $description ) {
                $sub         = $description;
                $description = q{};            # empty

                @is_subj_noun_synonym = ( noun_synonyms( $sub, 1 ), );

                say 80 if is_verbose;
            }
            elsif ( $sub =~ /nothing/ && $advs_str ) {
                $sub      = $advs_str;
                $advs_str = q{};               # empty
                @advs     = ();

                @is_subj_noun_synonym = ( noun_synonyms( $sub, 1 ), );

                say 87 if is_verbose;
            }
            else {
                @is_subj_noun_synonym = ( noun_synonyms( $sub, 1 ), );
            }
            print Dumper \@is_subj_noun_synonym;
            my $sub_spaces = $sub;
            my $obj_spaces = $obj;

            $sub_spaces =~ s/[_]/ /igm;
            $obj_spaces =~ s/[_]/ /igm;

            #		say join ', ', keys %{$data->{lang}{is_subj_noun_synonym;}}
            say 3, $sub;
            say 3, $sub_spaces;
            @facts = ();

            my @all_subjects =
              map { @{ $_->{words_relevant} || [] } } @is_subj_noun_synonym;

            #map { s/[-~]+$//igm; } @all_subjects;
            my @all_objects =
              map { @{ $_->{words_relevant} || [] } } @is_obj_noun_synonym;

            #map { s/[-~]+$//igm; } @all_objects;

            push @all_subjects, $sub_spaces;
            push @all_subjects, $sub;
            push @all_objects,  $obj_spaces;
            push @all_objects,  $obj;

            my @all_keys =
                ( $obj !~ /nothing/ )
              ? ( @all_subjects, @all_objects )
              : (@all_subjects);

            foreach my $key (@all_keys) {
                if ( $key eq 'nothing' ) {
                    $key = '...';
                }
            }
            print Dumper \@all_keys;

            semantic_network_connect(
                dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
                config => \%config
            );

            foreach my $_fact (
                @{
                    semantic_network_get_by_key(
                        as     => 'array',
                        'keys' => \@all_keys
                    )
                }
              )
            {
                print '.';
                next if !$_fact;
                print ';';
                next if ref($_fact) ne 'ARRAY';
                print '!';
                next if $_fact->[0] eq '=';

                if ( ref $_fact ne 'ARRAY' ) {
                    say 'NOT OK! Bug was found in FreeHAL, point 1.';
                }
                my $fact = $_fact->[1];
                if ( ref $fact ne 'ARRAY' ) {
                    say 'NOT OK! Bug was found in FreeHAL, point 2.';
                }
                my $whole_sentence = ' '
                  . $fact->[0] . ' '
                  . $fact->[1] . ' '
                  . $fact->[2] . ' '
                  . $fact->[3] . ' ';

                if ( scalar grep { $_->[4] =~ /^(wenn|if|when|falls)$/ }
                    @{ $fact->[4] } )
                {

                    next;
                }

                if ( $is_verb_synonym_ref->{'everything'} ) {
                    if (   $data->{lang}{is_be}{ $fact->[0] }
                        || $fact->[0] eq 'hat'
                        || $fact->[0] eq 'haben' )
                    {
                        next;
                    }
                }

                say 'obj:', $obj;

                push @facts, $fact
                  if (
                    (
                        (
                            (
                                $obj =~ /nothing/
                                && (
                                    (
                                        AI::Selector::traditional_match(
                                            \@is_subj_noun_synonym, $fact->[1]
                                        )
                                    )
                                    || (
                                        AI::Selector::traditional_match(
                                            \@is_subj_noun_synonym, $fact->[2]
                                        )
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2] . ' '
                                            . $fact->[3]
                                        ) =~ /(^|\s)$sub($|\s)/
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2] . ' '
                                            . $fact->[3]
                                        ) =~ /(^|\s)$sub_spaces($|\s)/
                                    )
                                )
                            )
                            || (
                                $obj !~ /nothing/
                                && (
                                    (
                                        AI::Selector::traditional_match(
                                            \@is_subj_noun_synonym, $fact->[1]
                                        )
                                    )
                                    || (
                                        AI::Selector::traditional_match(
                                            \@is_subj_noun_synonym, $fact->[2]
                                        )
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2]
                                        ) =~ /(^|\s)$sub($|\s)/
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2]
                                        ) =~ /(^|\s)$sub_spaces($|\s)/
                                    )
                                )
                                && (
                                    (
                                        AI::Selector::traditional_match(
                                            \@is_obj_noun_synonym, $fact->[1]
                                        )
                                    )
                                    || (
                                        AI::Selector::traditional_match(
                                            \@is_obj_noun_synonym, $fact->[2]
                                        )
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2]
                                        ) =~ /(^|\s)$obj($|\s)/
                                    )
                                    || (
                                        (
                                              $fact->[0] . ' '
                                            . $fact->[1] . ' '
                                            . $fact->[2]
                                        ) =~ /(^|\s)$obj_spaces($|\s)/
                                    )
                                )
                            )
                        )
                        || (   $fact->[3] =~ /(^|\s)$sub($|\s)/
                            || $fact->[3] =~ /(^|\s)$sub_spaces($|\s)/ )

                    )
                    && $fact->[0] !~ /^(braucht|brauchen|brauchst)$/
                    && (   !$data->{lang}{is_names_and_nouns_obj}{ $fact->[2] }
                        && !$data->{lang}{is_time_measurements_obj}
                        { $fact->[2] } )
                  );

            }

            my @facts_positive = grep { $_->[3] !~ /nicht/ } @facts;
            @facts = @facts_positive if @facts_positive;
        }

        ###
        # normal questions and statements
        ###
        else {

            #print Dumper @is_subj_noun_synonym;
            #print Dumper @is_obj_noun_synonym;
            @facts = search_facts_in_semantic_net_normal(
                $CLIENT_ref,                 \%is_verb_synonym,
                \@is_subj_noun_synonym,      \@is_obj_noun_synonym,
                $is_description_synonym_ref, $find_entries_with_variables,
                1,                           0,
            );

        }

        my @facts_matching      = ();
        my @facts_half_matching = ();

        #	say join ', ', keys %{$data->{lang}{is_subj_noun_synonym;}}
        #print Dumper \@facts;

        foreach my $res (@facts) {
            push @facts_half_matching, $res;
            push @facts_matching,      $res;
        }

        my @facts_with_placeholders =
          grep { length $_->[1] == 1 or length $_->[2] == 1 } @facts;

        @facts = $what_is_mode
          ? @facts

          #        : $find_entries_with_variables && @facts_with_placeholders
          #        ? @facts_with_placeholders

          #						: (@facts_matching)    ? @facts_matching
          : @facts_half_matching ? @facts_half_matching
          :                        @facts;

#my @facts_backup = shuffle @facts;
#@facts = ();
#foreach my $fact (@facts_backup) {
#    if ( AI::Selector::traditional_match( \@is_subj_noun_synonym, $fact->[1] ) ) {
#        unshift @facts, $fact;
#    }
#    else {
#        push @facts, $fact;
#    }
#}
#@facts = shuffle @facts;

        my $can_skip = 0;

        say '$what_is_mode: ', $what_is_mode if is_verbose;
        while ( my $result_ref = shift @facts ) {
            my $this_is_a_something_entry =
              $data->{lang}{is_something}{ $result_ref->[1] };

            my @facts_sub = ('');

            if (    # $this_is_a_something_entry
                !AI::Selector::traditional_match( \@is_subj_noun_synonym,
                    $result_ref->[1] )
                && !AI::Selector::traditional_match( \@is_subj_noun_synonym,
                    $result_ref->[2] )
                && !$find_entries_with_variables
                && !(
                       lc $sentence_ref->{'questionword'} eq 'was'
                    || lc $sentence_ref->{'questionword'} eq 'what'
                )
                && (   $data->{lang}{is_verb_synonym}{'ist'}
                    || $data->{lang}{is_verb_synonym}{'is'}
                    || $data->{lang}{is_verb_synonym}{'sind'} )
              )
            {

# say 'It is a \'something entry\' and no noun from the question equals to no if this entry:' if is_verbose;
# say join ' -- ', @$result_ref if is_verbose;
# say '$find_entries_with_variables:' if is_verbose;
# say '    ', $find_entries_with_variables if is_verbose;
                next;
            }

            #        say 4 if is_verbose;
            my $can_use_result = 0;

            say( 'obj: ', $obj, "\t" . '$result_ref->[2]: ', $result_ref->[2] )
              if is_verbose;
            $result_ref->[2] =~ s/[)(]//igm;
            $obj =~ s/[)(]//igm;
            if (
                   $obj
                && $obj !~ /nothing/
                && AI::Selector::traditional_match(
                    \@is_subj_noun_synonym, $result_ref->[1]
                )
              )
            {
                if (
                       !( $result_ref->[2] =~ /nothing/ )
                    && $result_ref->[2]
                    && ( $result_ref->[2] =~ /(^|_|\s)$obj(\s|_|[;]|$)/i
                        || scalar grep { $_{ $result_ref->[2] } }
                        @is_obj_noun_synonym )
                  )
                {
                    $can_use_result = 1;
                }

            }

            if (
                $obj =~ /nothing/
                && (
                    AI::Selector::traditional_match( \@is_subj_noun_synonym,
                        $result_ref->[1] )
                    || AI::Selector::traditional_match(
                        \@is_subj_noun_synonym, $result_ref->[2]
                    )
                )
              )
            {

                $can_use_result = 1;
                $can_skip += 1
                  if AI::Selector::traditional_match( \@is_subj_noun_synonym,
                          $result_ref->[1] );

                say 'subject is ok.' if is_verbose;
                say AI::Selector::traditional_match(
                    \@is_subj_noun_synonym, $result_ref->[1]
                  ),
                  AI::Selector::traditional_match( \@is_subj_noun_synonym,
                    $result_ref->[2] )
                  if is_verbose;
            }
            if (
                $obj !~ /nothing/
                && (
                    (
                        AI::Selector::traditional_match( \@is_subj_noun_synonym,
                            $result_ref->[1] )
                        && AI::Selector::traditional_match(
                            \@is_obj_noun_synonym, $result_ref->[2]
                        )
                    )
                    || (
                        AI::Selector::traditional_match( \@is_subj_noun_synonym,
                            $result_ref->[2] )
                        && AI::Selector::traditional_match(
                            \@is_obj_noun_synonym, $result_ref->[1]
                        )
                    )
                )
              )
            {

                $can_use_result = 1;
                $can_skip += 1
                  if AI::Selector::traditional_match( \@is_subj_noun_synonym,
                          $result_ref->[1] );

                say 'subject is ok.' if is_verbose;
                say AI::Selector::traditional_match(
                    \@is_subj_noun_synonym, $result_ref->[1]
                  ),
                  AI::Selector::traditional_match( \@is_subj_noun_synonym,
                    $result_ref->[2] )
                  if is_verbose;
            }

            #        if ( $obj =~ /nothing/
            #            && $result_ref->[2] =~ /nothing/ ) {
            #            $can_use_result = 1;
            #        }

            if (   ( length $result_ref->[1] < 2 )
                && ( length $result_ref->[2] < 2 ) )
            {
                $can_use_result = 1;
            }
            if ( $obj =~ /nothing/
                && ( length $result_ref->[2] < 2 ) )
            {
                $can_use_result = 1;
            }

            if ( $find_entries_with_variables
                && length $result_ref->[2] == 1 )
            {
                $can_use_result = 1;
            }
            if ( $find_entries_with_variables
                && length $result_ref->[1] == 1 )
            {
                $can_use_result = 1;
            }

            my $can_use_result_from_before_check_advs = $can_use_result;
            if ($what_is_mode) {
                $can_use_result                        = 1;
                $can_use_result_from_before_check_advs = 1;
            }

            foreach my $adv_b (@advs) {
                my $adv = $adv_b;
                if ( $adv =~ /\s+[a-z]$/i ) {
                    $adv =~ s/\s+[a-z]$/ .*?/i;
                }
                my $result_ref_3_backup = $result_ref->[3];
                if ( $result_ref->[3] =~ /\s+[a-z]$/i ) {
                    $result_ref->[3] =~ s/\s+[a-z]$/ .*?/i;

                    #$result_ref_3_backup =~ s/\s+[a-z]$//i;
                }
                chomp $adv;
                $adv = lc $adv;

                foreach
                  my $adverb_of_time ( @{ $data->{lang}{adverbs_of_time} } )
                {
                    $adv =~ s/^$adverb_of_time\s+//igm;
                    $adv =~ s/\s+$adverb_of_time$//igm;
                    $adv =~ s/\s+$adverb_of_time\s+//igm;
                }
                $adv             =~ s/\s+$//igm;
                $adv             =~ s/^\s+//igm;
                $adv             =~ s/[;\]\[]/ /igm;
                $result_ref->[3] =~ s/[;]/ /igm;
                if (   $result_ref->[2] !~ /(^|[,;\s_)(])$adv($|[,;\s_)(])/i
                    && $result_ref->[3] !~ /(^|[,;\s_)(])$adv($|[,;\s_)(])/i
                    && $adv !~ /(^|[,;\s_)(])$result_ref->[3]($|[,;\s_)(])/i
                    && $result_ref->[1] !~ /(^|[,;\s_)(])$adv($|[,;\s_)(])/i )
                {
                    say 'not containing ' . $adv . ': ' . $result_ref->[3]
                      if is_verbose;
                    $can_use_result = 0;

                    $can_use_result_from_before_check_advs = 0;
                }
                else {
                    say 'containing ' . $adv . ': ' . $result_ref->[3]
                      if is_verbose;
                }
                $result_ref->[3] = $result_ref_3_backup;
            }

            if ( $description && $can_use_result ) {
                $description    = lc $description;
                $can_use_result = 0;

                say 781 if is_verbose;

                my %description_items =
                  map { %$_ } @{ $is_description_synonym_ref->{'___'} };

                say join '; ', keys %description_items;

#            foreach
#                my $descr ( ( $description, keys %{$data->{lang}{is_description_synonym}}) )
#            {
#                $descr =~ s/^(_|\s)+//igm;
#                $descr =~ s/(_|\s)+$//igm;

#                say 'count of %{$data->{lang}{is_description_synonym:}}', scalar (%{$data->{lang}{is_description_synonym,1);}}
                $can_use_result = 1
                  if AI::Selector::traditional_match( \%is_description_synonym,
                          $result_ref->[1] );

                $can_use_result = 1
                  if AI::Selector::traditional_match( \%is_description_synonym,
                          $result_ref->[2] );

                foreach my $adv_part ( split /[;\s]/, $result_ref->[3] ) {
                    $can_use_result = 1
                      if AI::Selector::traditional_match(
                              \%is_description_synonym, $adv_part );
                }

                foreach my $adv_part ( split /[;\s]+/, $result_ref->[3] ) {
                    next if $adv_part =~ /nothing/;
                    if (
                        AI::Selector::traditional_match(
                            \%is_description_synonym, $adv_part, 1
                        )
                      )
                    {
                        say 'found $adv_part in description_synonyms';
                        $can_use_result = 1;
                    }
                    else {
                        say 'not found ', $adv_part, ' in description_synonyms';
                    }
                }

                if ( $description =~ /^lang[e]?/ ) {
                    foreach my $adv ( @{ $data->{lang}{adverbs_of_time} } ) {
                        $can_use_result = 1
                          if $result_ref->[3] =~ /(^|\s)$adv(\s|_|[;]|$)/i;
                        $can_use_result = 1
                          if $result_ref->[2] =~ /(^|\s)$adv(\s|_|[;]|$)/i;
                    }
                }

                $can_use_result = 1
                  if $result_ref->[1] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                $can_use_result = 1
                  if $result_ref->[2] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                $can_use_result = 1
                  if $result_ref->[3] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                say 'description synonym: ', $description
                  if $can_use_result == 1 && is_verbose;

                #                last if $can_use_result == 1;
                #            }
            }

            elsif (
                $description

                #&& !$can_use_result
                && $sentence_ref->{'questionword'} =~ /welch/i
              )
            {
                $description                           = lc $description;
                $can_use_result_from_before_check_advs = 0;

                say 782 if is_verbose;
                print Dumper \%is_description_synonym;

#my $ok = 0;
#            foreach
#                my $descr ( ( $description, keys %{$data->{lang}{is_description_synonym}}) )
#            {
#                $descr =~ s/^(_|\s)+//igm;
#                $descr =~ s/(_|\s)+$//igm;

                $can_use_result_from_before_check_advs = 1
                  if AI::Selector::traditional_match( \%is_description_synonym,
                          $result_ref->[1] );

                $can_use_result_from_before_check_advs = 1
                  if AI::Selector::traditional_match( \%is_description_synonym,
                          $result_ref->[2] );

                foreach my $adv_part ( split /[;\s]/, $result_ref->[3] ) {
                    $can_use_result_from_before_check_advs = 1
                      if AI::Selector::traditional_match(
                              \%is_description_synonym, $adv_part );
                }

                $can_use_result_from_before_check_advs = 1
                  if $result_ref->[1] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                $can_use_result_from_before_check_advs = 1
                  if $result_ref->[2] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                $can_use_result_from_before_check_advs = 1
                  if $result_ref->[3] =~ /(^|\s)$description(\s|_|[;]|$)/i;
                say 'description synonym: ', $description
                  if $can_use_result_from_before_check_advs == 1
                      && is_verbose;

            }

            elsif ( $description && $can_use_result_from_before_check_advs ) {
                $description                           = lc $description;
                $can_use_result_from_before_check_advs = 0;

                say 783 if is_verbose;

                my %description_items =
                  map { %$_ } @{ $is_description_synonym_ref->{'___'} };

                foreach my $descr ( ( $description, keys %description_items ) )
                {
                    $can_use_result = 1
                      if $result_ref->[1] =~ /(^|\s)$descr(\s|_|[;]|$)/i;
                    $can_use_result = 1
                      if $result_ref->[2] =~ /(^|\s)$descr(\s|_|[;]|$)/i;
                    $can_use_result = 1
                      if $result_ref->[3] =~ /(^|\s)$descr(\s|_|[;]|$)/i;
                    say 'description synonym: ', $descr
                      if $can_use_result_from_before_check_advs == 1
                          && is_verbose;
                    last if $can_use_result_from_before_check_advs == 1;
                }
            }

            if ($find_entries_with_variables) {
                foreach my $part ( split /[;\s]/, $result_ref->[3] ) {
                    foreach
                      my $adverb_of_time ( @{ $data->{lang}{adverbs_of_time} } )
                    {
                        $part =~ s/^$adverb_of_time\s+//igm;
                        $part =~ s/\s+$adverb_of_time$//igm;
                        $part =~ s/\s+$adverb_of_time\s+//igm;
                    }
                    if (   $result_ref->[2] !~ /$part/i
                        && $result_ref->[3] !~ /$part/i
                        && $result_ref->[1] !~ /$part/i )
                    {

                        $can_use_result = 0;

                        $can_use_result_from_before_check_advs = 0;
                    }
                }
            }

            push @results_second_choice, $result_ref
              if $can_use_result
                  || $can_use_result_from_before_check_advs;

            say join '##', @$result_ref if is_verbose;
            say '$can_use_result                        : ', $can_use_result
              if is_verbose;
            say '$can_use_result_from_before_check_advs : ',
              $can_use_result_from_before_check_advs
              if is_verbose;
            say '( !length($description)...... : ',
              (     !length($description)
                  && lc $sentence_ref->{'questionword'} eq 'was'
                  && $data->{lang}{is_verb_synonym}{'ist'} )
              if is_verbose;

            #						if ( !$description ) {
            #							if ($can_use_result) {
            #								my @word_count =
            #								  split( / /, scalar $result_ref->[2] );
            #								if ( @word_count > 1 ) {
            #									$can_use_result = 0;
            #								}
            #							}
            #						}

            say '$can_use_result : ', $can_use_result if is_verbose;
            say if is_verbose;

            #(say Dumper $result_ref and exit 0)
            #    if (Dumper $result_ref) =~ /berg.*?welt/i;

            push @results, $result_ref
              if $can_use_result;

            #|| $what_is_mode;

            say join '###', @$result_ref if is_verbose;

            say join ',,,, ', map { $_->[4] }
              grep { $_ ? $data->{lang}{is_if_word}{ $_->[4] } : 0 }
              @{ $result_ref->[4] }
              if is_verbose;
            say $result_ref->[3] if is_verbose;
            say( join ' ', @advs ) if is_verbose;

#select undef, undef, undef, 5 if ( !$result_ref->[3] || (join ' ', (@advs, $description)) =~ /$result_ref->[3]/i );

            chomp $result_ref->[3];

            # because we shuffle, we can skip now
            if (  !$what_is_mode
                && $can_use_result
                && !$do_not_skip
                && $can_skip > 10 )
            {

                #@results = ( $result_ref, );
                last;
            }
        }

        if ( !$what_is_mode ) {
            my @best_results =
              grep {
                AI::Selector::traditional_match( \@is_subj_noun_synonym,
                    $_->[1] )
              } @results;
            if (@best_results) {
                @results = @best_results;
            }
        }

        if ($what_is_mode) {
            @results = shuffle @results;
        }

        my $can_return_it = 1;
        if ( !@results ) {
            $can_return_it = 0;
            @results       = @results_second_choice;
        }

        if ( !$what_is_mode ) {
            my @results_precise_verb =
              grep { $data->{lang}{is_verb_synonym}{ $_->[0] } } @results;
            @results = @results_precise_verb if @results_precise_verb;
        }

        #    my @results_100 = grep {
        #               ( $_->[10] ? $_->[10] : 0 ) == 100
        #            || ( $_->[11] ? $_->[11] : 0 ) == 100
        #            || ( $_->[5]  ? $_->[5]  : 0 )
        #            == 100
        #    } (@results);
        #    @results = @results_100 if @results_100;

        #	print Dumper \@results;
        #	exit 0;

        #say if is_verbose;
        #say join ', ', keys my %is_verb_synonymif is_verbose;
        #say $is_subj_noun_synonym[0]->{'_main'} if is_verbose;
        #say $is_obj_noun_synonym[0]->{'_main'}  if is_verbose;
        #say Dumper [@advs] if is_verbose;
        #say $description if is_verbose;

        $data->{modes}{do_filter_results} = !$what_is_mode;

        if ( @results && $can_return_it ) {
            if (@advs) {
                if ( @results && $can_return_it ) {

                    my $return_value = [
                        \@results,
                        \@results_second_choice,
                        $is_subj_noun_synonym_ref_2->[$masterindex],
                        $is_obj_noun_synonym_ref_2->[$masterindex],
                    ];

       #                    $cache_search_semantic{ $cache_search_semantic_key }
       #                        = $return_value;

                    return $return_value;
                }
            }
            else {
                $best_to_return = [
                    \@results,
                    \@results_second_choice,
                    $is_subj_noun_synonym_ref_2->[$masterindex],
                    $is_obj_noun_synonym_ref_2->[$masterindex],
                  ]
                  if !$best_to_return;
            }
        }
    }

    #    $cache_search_semantic{ $cache_search_semantic_key }
    #        = ($best_to_return || [ [], [], ]);

    return ( $best_to_return || [ [], [], ] );
}

sub answer_sentence_questionword {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref, $sentence ) = @_;

    $sentence_ref = strip_nothings($sentence_ref);

    my @advs = @{ $sentence_ref->{'advs'} };
    my $description = lc $sentence_ref->{'description'} || '';

    $description =~ s/nothing//igm;
    $description =~ s/\s\s/ /igm;
    $description =~ s/^\s//igm;
    $description =~ s/\s$//igm;

    say "description: ", $description;

    my @description_words = split /(\s+)|_/, $description;
    if ( pos_of( $CLIENT_ref, $description_words[0] ) == $data->{const}{PREP} )
    {
        push @advs, shift @description_words;
    }
    $description = join ' ', @description_words;
    my $advs_str               = join ';', sort @advs;
    my $description_last_word  = $description_words[-1];
    my %is_description_synonym = ();
    say "pos_of( $CLIENT_ref, $description_last_word ):";
    say '    ', pos_of( $CLIENT_ref, ucfirst $description_last_word, 0, 0, 0 );
    if ( pos_of( $CLIENT_ref, ucfirst $description_last_word, 0, 0, 0 ) ==
        $data->{const}{NOUN}
        || pos_of( $CLIENT_ref, lc $description_last_word ) ==
        $data->{const}{NOUN} )
    {
        my %is_description_synonym = %{ noun_synonyms( $description, 0, 1 ) };

        #        my %is_description_synonym = map { %$_ } @{ $x{'___'} };
    }
    else {
        my %is_description_synonym = (
            $description => 1,
            '___'            => [ { $description => 1 } ],
            '_main_original' => $description,
            '_main'          => { $description => 1 },
            '_count'         => 1,
            'words_relevant' => [$description],
        );
    }

    #    say Dumper \%{$data->{lang}{is_description_synonym;}}
    #    say '$data->{lang}{is_description_synonym}{\'gelb\'}',
    #        $data->{lang}{is_description_synonym}{'gelb'};

    my $do_not_skip =
      (      lc $sentence_ref->{'questionword'} eq 'wer'
          || lc $sentence_ref->{'questionword'} eq 'was'
          || lc $sentence_ref->{'questionword'} eq 'what'
          || lc $sentence_ref->{'questionword'} eq 'who' );

    my @results               = ();
    my @results_second_choice = ();

    my @is_subj_noun_synonym = ();
    my @is_obj_noun_synonym  = ();

    foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ) {
        say 7;
        my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
        foreach my $sub (@arr_sub) {

            #            next if $sub =~ /nothing/;

            say 8;
            push @is_subj_noun_synonym, noun_synonyms( $sub, 0, 1 );

        }
    }
    my @arr_objs = ();
    foreach my $obj ( @{ $sentence_ref->{'objects'} } ) {
        my @arr_objs_temp =
          map { my $new_one = $_ . '' } @arr_objs;
        @arr_objs = ();

        say 'obj: ', $obj;
        $obj =~ s/\soder\s/ und /igm;
        $obj =~ s/\sand\s/ und /igm;
        $obj =~ s/\sor\s/ und /igm;
        $obj =~ s/\sund\s/ und /igm;    # big and small (i)
        my @arr_obj = split /\sund\s/, $obj;

        #				say Dumper @arr_obj;
        for my $item (@arr_obj) {
            $item =~ s/^\s//igm;
            $item =~ s/\s$//igm;
            foreach my $temp (@arr_objs_temp) {
                push @arr_objs, $temp . ' ' . $item;
            }
            if ( not(@arr_objs_temp) ) {
                push @arr_objs, $item;
            }
        }

    }

    say 5;
    foreach my $obj ( map { lc $_ } @arr_objs ) {
        $obj =~ s/[)(]//igm;
        push @is_obj_noun_synonym, noun_synonyms( $obj, 0, 1 );

  #                foreach my $data->{const}{VERB} (
  #                    ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ), )
  #                {
  #                    next if $data->{const}{VERB} eq 'nothing';
  #                    $data->{const}{VERB} =~ s/nothing//igm;
  #                    $data->{const}{VERB} =~ s/  / /igm;
  #
  #                    say 'verb: ', $data->{const}{VERB};
  #
  #                    my %is_verb_synonym= verb_synonyms($data->{const}{VERB});
  #
  #
  #                }
    }
    my $verb = join ' ', sort @{ $sentence_ref->{'verbs'} };
    my %is_verb_synonym = %{ verb_synonyms($verb) };

    my $sub = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ));
    my $obj = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'objects'} } ));

    my ( $results_sub_ref, $results_second_choice_sub_ref,
        $subj_synonyms, $obj_synonyms, )
      = @{
        solve_variable_problems(
            $CLIENT_ref,              \%is_verb_synonym,
            \@is_subj_noun_synonym,   \@is_obj_noun_synonym,
            $sentence_ref,            $description,
            \%is_description_synonym, $sub,
            $obj,                     \@advs,
            0,                        1,
            $do_not_skip,
        )
      };

    push @results,               @$results_sub_ref;
    push @results_second_choice, @$results_second_choice_sub_ref;

    @results               = grep { $_->[0] ne '=' } @results;
    @results_second_choice = grep { $_->[0] ne '=' } @results_second_choice;

    if ( !@results ) {
        @results = @results_second_choice;
    }

    if ( $data->{modes}{do_filter_results} ) {
        my @results_100 = grep {
                 ( $_->[10] ? $_->[10] : 0 ) == 100
              || ( $_->[11] ? $_->[11] : 0 ) == 100
              || ( $_->[5]  ? $_->[5]  : 0 ) == 100
        } (@results);
        @results = @results_100 if @results_100;
    }

    if ($subj_synonyms) {
        my @best_results =
          grep { AI::Selector::traditional_match( $subj_synonyms, $_->[1] ) }
          @results;
        if (@best_results) {
            @results = @best_results;
        }
    }

    foreach my $res (@results) {
        say join ', ', @$res if is_verbose;
    }

    my @answers        = ();
    my @answers_second = ();
    my @answers_third  = ();
    my @answers_forth  = ();
    my @answers_fifth  = ();
    my @answers_sixth  = ();

    %{ $data->{lang}{is_subject} } =
      map { lc $_ => 1 } @{ $sentence_ref->{'subjects'} };
    my $l = 0;
    foreach my $result (@results) {
        $l += 1;
        print "\rconjugating fact " . $l . "\n";

        next if $result->[1] eq 'es' && !$data->{lang}{is_subject}{'es'};

        #		print Dumper @$result;
        push @answers_sixth, phrase( $CLIENT_ref, @$result )
          if !@answers;
        push @answers_fifth, phrase( $CLIENT_ref, @$result )
          if $result->[2] !~ /nothing/ && !@answers;
        push @answers_forth, phrase( $CLIENT_ref, @$result )
          if $result->[2] !~ /nothing/
              && !@answers
              && ( $result->[10] ? $result->[10] : 0 ) == 100;

        push @answers_second, phrase( $CLIENT_ref, @$result )
          if (
            ( $result->[1] . $result->[2] ) !~ /freehal/i
            && (   lc $sentence_ref->{'questionword'} ne 'wer'
                && lc $sentence_ref->{'questionword'} ne 'who' )
          )
          && !@answers;
        push @answers_second, phrase( $CLIENT_ref, @$result )
          if (
            (
                ( $result->[1] . $result->[2] ) !~ /freehal/i
                && (   lc $sentence_ref->{'questionword'} ne 'wer'
                    && lc $sentence_ref->{'questionword'} ne 'who' )
            )
            || (
                (
                       lc $sentence_ref->{'questionword'} eq 'warum'
                    || lc $sentence_ref->{'questionword'} eq 'wieso'
                    || lc $sentence_ref->{'questionword'} eq 'weshalb'
                    || lc $sentence_ref->{'questionword'} eq 'why'
                )
                && ( scalar grep { $_->[4] eq 'because' || $_->[4] eq 'weil' }
                    @{ $result->[4] } )
            )
          );
        push @answers, phrase( $CLIENT_ref, @$result )
          if (
            (
                ( $result->[1] . $result->[2] ) =~ /freehal/i
                && (   lc $sentence_ref->{'questionword'} eq 'wer'
                    || lc $sentence_ref->{'questionword'} eq 'who' )
            )
          )
          || (
            (
                   lc $sentence_ref->{'questionword'} eq 'warum'
                || lc $sentence_ref->{'questionword'} eq 'wieso'
                || lc $sentence_ref->{'questionword'} eq 'weshalb'
                || lc $sentence_ref->{'questionword'} eq 'why'
            )
            && ( scalar grep { $_->[4] eq 'because' || $_->[4] eq 'weil' }
                @{ $result->[4] } )
          );

    }

    if ( lc $sentence_ref->{'questionword'} eq 'wo' ) {
        my $regex =
qr/[\s;](aus|in|im|from|von|auf|unter|vor|behind|before|(in front of)|innerhalb|an|am)[\s;]/i;
        @answers        = grep { $_ =~ $regex } @answers;
        @answers_second = grep { $_ =~ $regex } @answers_second;
        @answers_third  = grep { $_ =~ $regex } @answers_third;
        @answers_forth  = grep { $_ =~ $regex } @answers_forth;
        @answers_fifth  = grep { $_ =~ $regex } @answers_fifth;
        @answers_sixth  = grep { $_ =~ $regex } @answers_sixth;

    }

    @answers = @answers_second if !@answers;
    @answers = @answers_third  if !@answers;
    @answers = @answers_forth  if !@answers;
    @answers = @answers_fifth  if !@answers;
    @answers = @answers_sixth  if !@answers;

    foreach my $posible_answer (@answers) {
        say( ">> posible answer: ", $posible_answer );
    }

    if ( ( not @answers ) ) {
        no_answers_found($sentence);

        #		my @answers_new_things_wanted_to_know =
        #		  new_things_wanted_to_know($CLIENT_ref);

        #		if (@answers_new_things_wanted_to_know) {
        #			return @answers_new_things_wanted_to_know;
        #		}
        #		else {

        #print Dumper \%{$data->{lang}{is_subject;}}
        my @verbs_to_use = @{ $sentence_ref->{'verbs'} };

        if ( LANGUAGE() eq 'de'
            && $sentence =~ /(^|\s)(du|ich|mich|dich|mir|dir)($|\s)/i )
        {
            if ( !grep { /^(du|ich)$/i } @{ $sentence_ref->{'objects'} } ) {
                @verbs_to_use = conjugate_verb_for( \@verbs_to_use );
            }

            push @answers,
              (
                (
                    $sentence_ref->{'questionword'} eq 'was'
                    ? 'Nein, '
                    : 'Das weiss ich nicht. '
                )
                . lcfirst phrase_question(
                    $CLIENT_ref,
                    ( join ' ', @verbs_to_use ),
                    'du',
                    ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                    ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                    []
                  )
                  . '?',
              ) x 1
              if @verbs_to_use;
        }
        elsif ( LANGUAGE() eq 'de' ) {

            my @verbs_to_use = @{ $sentence_ref->{'verbs'} };

            if ( !grep { /^du$/i } @{ $sentence_ref->{'objects'} } ) {
                @verbs_to_use = conjugate_verb_for( \@verbs_to_use );
            }

            my $subj_string =
              ( join ' ', sort @{ $sentence_ref->{'subjects'} }, );
            $subj_string =~ s/nothing//igm;
            $subj_string =~ s/\s+//igm;

            push @answers,
              (
                (
                    $sentence_ref->{'questionword'} eq 'was'
                    ? 'Ich kann es dir nicht sagen, '
                    : 'Das weiss ich nicht. '
                )
                . lcfirst phrase_question(
                    $CLIENT_ref,
                    ( join ' ', @verbs_to_use ),
                    ( join ' ', sort @{ $sentence_ref->{'subjects'} }, ),
                    ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                    ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                    [],
                    $sentence_ref->{'questionword'},
                  )
                  . '?',
              ) x 1
              if $subj_string && @verbs_to_use;
        }
        if ( LANGUAGE() eq 'de' ) {
            push @answers,
              (
                ( 'Das weiss ich nicht.', ) x 9,
                ( 'Keine Ahnung.', ) x 9,
                'Ich bin erst 2 Jahre alt!',
                'Ich kenne mich damit nicht aus.',
'Das kann ich nicht beantworten, das hat mir niemand beigebracht.',
                'Hm...',
                'Das verstehe ich jetzt nicht.',
                'Alles weiss ich leider auch nicht.',
                'Ich muss noch viel lernen.',
                'Alles kann ich nicht wissen.',
                'Das kann ich dir nicht sagen.',
                'Ich bin erst 2 Jahre alt.',
                'Erklaere es mir.',
                'Fuer alles habe ich nun auch nicht eine Antwort!',
                'Ich weiss es nicht, kannst du es mir bitte erklaeren?',
                'Was tust du, wenn ich es nicht weiss?',
                'Keine Ahnung, sag es mit bitte!',
              );
        }
        elsif ( LANGUAGE() eq 'en' ) {
            push @answers,
              (
                'I do not know.',
                'How should I know?',
                'Figure it out yourself.',
                'It depends.',
                'I can\'t remember.',
              );
        }

        my @answers_suggestions =
          suggestions( $CLIENT_ref, $sentence_ref, $subclauses_ref );
        push @answers, @answers_suggestions foreach ( 0 .. 40 );

        #		}
    }

    if ( LANGUAGE() eq 'en' ) {
        my @names = get_user_names();
        my @old   = @answers;
        push @answers, @answers;
        push @answers, @answers;
        foreach my $answer (@old) {
            chomp $answer;
            next if !$answer;
            push @answers, 'Well, ' . $answer;
            push @answers, 'If I remember correctly, ' . $answer;
            push @answers, 'Don\'t tell me, let me guess. ' . $answer;
            push @answers,
                'Well, '
              . ( (@names) ? $names[ rand(@names) ] . ', ' : '' )
              . $answer;

        }
    }

    if ( LANGUAGE() eq 'de' ) {
        my @names = get_user_names();
        my @old   = @answers;
        push @answers, @answers;
        push @answers, @answers;
        push @answers, @answers;
        foreach my $answer (@old) {
            chomp $answer;
            next if !$answer;
            push @answers, $answer . ' ;)';
            push @answers, $answer . ' :)';

        }
    }

#%{part_of_speech_get_memory()} = %{part_of_speech_get_memory()}_backup if $data->{intern}{in_cgi_mode};

    return @answers;
}

sub be_statements {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref, $sentence ) = @_;

    $sentence_ref = strip_nothings($sentence_ref);

    my @advs = map { lc $_ } @{ $sentence_ref->{'advs'} };
    my $description = lc $sentence_ref->{'description'} || '';
    my $advs_str = join ';', sort @advs;

    $description =~ s/nothing//igm;
    $description =~ s/\s\s/ /igm;
    $description =~ s/^\s//igm;
    $description =~ s/\s$//igm;

    say "description: ", $description;

    my $description_last_word = ( split /[\s_]/, $description )[-1];
    my %is_description_synonym =
      ( pos_of( $CLIENT_ref, $description_last_word ) ) == $data->{const}{NOUN}
      ? %{ noun_synonyms( $description, 0, 1 ) }
      : ( $description => 1 );

    my @results                = ();
    my @results_with_other_obj = ();

    my @is_subj_noun_synonym = ();
    my @is_obj_noun_synonym  = ();

    foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'objects'} } ) ) {
        say 7;
        my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
        foreach my $sub (@arr_sub) {

            #            next if $sub =~ /nothing/;

            push @is_subj_noun_synonym, noun_synonyms( $sub, 0, 1 );

        }
    }
    my @arr_objs = ('nothing');

    foreach my $obj ( map { lc $_ } @arr_objs ) {
        $obj =~ s/[)(]//igm;
        push @is_obj_noun_synonym, noun_synonyms( $obj, 0, 1 );

    }
    my $verb = join ' ', sort @{ $sentence_ref->{'verbs'} };
    my %is_verb_synonym = %{ verb_synonyms('sein') };

    my $sub = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'objects'} } ));
    my $obj = 'nothing';

    if ( $sub =~ /nothing/ || !$sub ) {
        my $sub = join ' ',
          sort_linking(map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ));
    }

    say << "    EOT";
        solve_variable_problems(
            $CLIENT_ref,              \%is_verb_synonym,            \@is_subj_noun_synonym,   \@is_obj_noun_synonym,
            $sentence_ref,            $description,
            \%is_description_synonym, $sub,
            $obj,                     \@advs,
            0,                        0,
            0,
        )
	
    EOT

    my ( $results_sub_ref, $results_second_choice_sub_ref ) = @{
        solve_variable_problems(
            $CLIENT_ref,              \%is_verb_synonym,
            \@is_subj_noun_synonym,   \@is_obj_noun_synonym,
            $sentence_ref,            $description,
            \%is_description_synonym, $sub,
            $obj,                     \@advs,
            0,                        0,
            0,
        )
      };

    push @results,                @$results_sub_ref;
    push @results_with_other_obj, @$results_second_choice_sub_ref;

    my @answers        = ();
    my @answers_second = ();
    my @answers_third  = ();
    my @answers_forth  = ();
    my @answers_fifth  = ();
    my @answers_sixth  = ();

    %{ $data->{lang}{is_subject} } =
      map { lc $_ => 1 } @{ $sentence_ref->{'subjects'} };
    my $l = 0;
    foreach my $result (@results) {
        $l += 1;

        if ( $result->[4] =~ /if|wenn|when|falls/ ) {
            next;
        }

        print "\rconjugating fact " . $l . "\r";

        next if $result->[1] eq 'es' && !$data->{lang}{is_subject}{'es'};

        #		print Dumper @$result;
        push @answers_sixth, phrase( $CLIENT_ref, @$result );
        push @answers_fifth, phrase( $CLIENT_ref, @$result )
          if $result->[2] !~ /nothing/;
        push @answers_forth, phrase( $CLIENT_ref, @$result )
          if $result->[2] !~ /nothing/
              && ( $result->[10] ? $result->[10] : 0 ) == 100;

        push @answers_second, phrase( $CLIENT_ref, @$result )
          if (
            ( $result->[1] . $result->[2] ) !~ /freehal/i
            && (   lc $sentence_ref->{'questionword'} ne 'wer'
                && lc $sentence_ref->{'questionword'} ne 'who' )
          );
        push @answers, phrase( $CLIENT_ref, @$result )
          if (
            (
                ( $result->[1] . $result->[2] ) =~ /freehal/i
                && (   lc $sentence_ref->{'questionword'} eq 'wer'
                    || lc $sentence_ref->{'questionword'} eq 'who' )
            )
          )
          || (
            (
                   lc $sentence_ref->{'questionword'} eq 'warum'
                || lc $sentence_ref->{'questionword'} eq 'wieso'
                || lc $sentence_ref->{'questionword'} eq 'weshalb'
                || lc $sentence_ref->{'questionword'} eq 'why'
            )
            && ( scalar grep { $_->[4] eq 'because' || $_->[4] eq 'weil' }
                @{ $result->[4] } )
          );
    }

    #part_of_speech_write(
    #				file =>#
    #					$data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.memory'
    #			);
    say;

    @answers = @answers_second if !@answers;
    @answers = @answers_third  if !@answers;
    @answers = @answers_forth  if !@answers;
    @answers = @answers_fifth  if !@answers;
    @answers = @answers_sixth  if !@answers;

    foreach my $posible_answer (@answers) {
        say( ">> posible answer: ", $posible_answer );
    }

    my $random_answer = $answers[ rand @answers ];

    return ( $random_answer ? $random_answer : () );
}

sub suggestions {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref, $sentence ) = @_;

    $sentence_ref = strip_nothings($sentence_ref);

    my @advs = map { lc $_ } @{ $sentence_ref->{'advs'} };
    my $description = lc $sentence_ref->{'description'} || '';
    my $advs_str = join ';', sort @advs;

    $description =~ s/nothing//igm;
    $description =~ s/\s\s/ /igm;
    $description =~ s/^\s//igm;
    $description =~ s/\s$//igm;

    say "description: ", $description;

    my $description_last_word = ( split /[\s_]/, $description )[-1];
    my %is_description_synonym =
      ( pos_of( $CLIENT_ref, $description_last_word ) ) == $data->{const}{NOUN}
      ? %{ noun_synonyms( $description, 0, 1 ) }
      : ( $description => 1 );

    my @results                = ();
    my @results_with_other_obj = ();

    my @is_subj_noun_synonym = ();
    my @is_obj_noun_synonym  = ();

    foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ) {
        say 7;
        my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
        foreach my $sub (@arr_sub) {

            #            next if $sub =~ /nothing/;

            say 8;
            push @is_subj_noun_synonym, noun_synonyms( $sub, 0, 1 );

        }
    }
    my @arr_objs = ();
    foreach my $obj ( @{ $sentence_ref->{'objects'} } ) {
        my @arr_objs_temp =
          map { my $new_one = $_ . '' } @arr_objs;
        @arr_objs = ();

        say 'obj: ', $obj;
        $obj =~ s/\soder\s/ und /igm;
        $obj =~ s/\sand\s/ und /igm;
        $obj =~ s/\sor\s/ und /igm;
        $obj =~ s/\sund\s/ und /igm;    # big and small (i)
        my @arr_obj = split /\sund\s/, $obj;

        #				say Dumper @arr_obj;
        for my $item (@arr_obj) {
            $item =~ s/^\s//igm;
            $item =~ s/\s$//igm;
            foreach my $temp (@arr_objs_temp) {
                push @arr_objs, $temp . ' ' . $item;
            }
            if ( not(@arr_objs_temp) ) {
                push @arr_objs, $item;
            }
        }

    }

    say 5;
    foreach my $obj ( map { lc $_ } @arr_objs ) {
        $obj =~ s/[)(]//igm;
        push @is_obj_noun_synonym, noun_synonyms( $obj, 0, 1 );

  #                foreach my $data->{const}{VERB} (
  #                    ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ), )
  #                {
  #                    next if $data->{const}{VERB} eq 'nothing';
  #                    $data->{const}{VERB} =~ s/nothing//igm;
  #                    $data->{const}{VERB} =~ s/  / /igm;
  #
  #                    say 'verb: ', $data->{const}{VERB};
  #
  #                    my %is_verb_synonym= verb_synonyms($data->{const}{VERB});
  #
  #
  #                }
    }
    my $verb = join ' ', sort @{ $sentence_ref->{'verbs'} };
    my %is_verb_synonym = %{ verb_synonyms($verb) };

    my $sub = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ));
    my $obj = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'objects'} } ));

    my ( $results_sub_ref, $results_second_choice_sub_ref ) = @{
        solve_variable_problems(
            $CLIENT_ref,              \%is_verb_synonym,
            \@is_subj_noun_synonym,   \@is_obj_noun_synonym,
            $sentence_ref,            $description,
            \%is_description_synonym, $sub,
            $obj,                     \@advs,
            1,                        0,
            0,
        )
      };

    push @results,                @$results_sub_ref;
    push @results_with_other_obj, @$results_second_choice_sub_ref;

    #print Dumper \@results;

    #select undef, undef, undef, 10;

    #foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ) {
    #my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
    #say 2;
    #foreach my $sub (@arr_sub) {
    #my @arr_objs = ();
    #say 3;

    #%{$data->{lang}{is_subj_noun_synonym}}= noun_synonyms($sub);

    #foreach my $obj ( @{ $sentence_ref->{'objects'} } ) {
##                say 4;
    #my @arr_objs_temp =
    #map { $_ . '' } @arr_objs;
    #@arr_objs = ();

    #say 'obj: ', $obj;
    #$obj =~ s/\soder\s/ und /igm;
    #$obj =~ s/\sand\s/ und /igm;
    #$obj =~ s/\sor\s/ und /igm;
    #$obj =~ s/\sund\s/ und /igm;    # big and small (i)
    #my @arr_obj = split /\sund\s/, $obj;

    #say 5;

    ##				say Dumper @arr_obj;
    #for my $item (@arr_obj) {
    #$item =~ s/^\s//igm;
    #$item =~ s/\s$//igm;
    #foreach my $temp (@arr_objs_temp) {
    #push @arr_objs, $temp . ' ' . $item;
    #}
    #if ( not(@arr_objs_temp) ) {
    #push @arr_objs, $item;
    #}
    #}

    #say 6;
    #}

    #say 7;
    #foreach my $obj ( map { lc $_ } @arr_objs ) {
    #$obj =~ s/[)(]//igm;
    #%{$data->{lang}{is_obj_noun_synonym}}= noun_synonyms($obj);
    #foreach my $data->{const}{VERB} (
    #( join ' ', sort @{ $sentence_ref->{'verbs'} }, ), )
    #{
    #say 8;
    #next if $data->{const}{VERB} eq 'nothing';
    #$data->{const}{VERB} =~ s/nothing//igm;
    #$data->{const}{VERB} =~ s/  / /igm;

    #%{$data->{lang}{is_verb_synonym}}= verb_synonyms($data->{const}{VERB});

#my ( $results_sub_ref, $results_second_choice_sub_ref ) =
#search_semantic(
#$CLIENT_ref,              \%is_verb_synonym,    #\@is_subj_noun_synonym,   \@is_obj_noun_synonym,
#$sentence_ref,            $description,
#\%is_description_synonym, $sub,
#$obj,                     \@advs,
#1,
#1,
#0,
#);

    #push @results, @$results_sub_ref;
    #push @results_with_other_obj,
    #@$results_second_choice_sub_ref;
    #}
    #}
    #}
    #}

    my @answers = ();
    say 'results:';
    say Dumper \@results;
    @answers = grep {
        $data->{lang}{is_verb_synonym}{ $_->[0] }
          && scalar grep { $_->[0] =~ /[=][>]/ }
          @{ $_->[4] }
    } @results;
    say 'answers:';
    say Dumper \@answers;

    push @advs, '' if !@advs;

    my @advs_without_ending_single_characters = @advs;
    map { s/\s+[a-z]$//i } @advs_without_ending_single_characters;

    say '\@advs_without_ending_single_characters: ';
    say( ' ' x 4, join ';', @advs_without_ending_single_characters );

    my @subclauses = grep { $_->[0] =~ /[=][>]/ }
      map {
        my $tmp = $_;
        $tmp->[3] =~ s/nothing//igm;
        ( my $tmp_3_without_ending_single_characters = $tmp->[3] ) =~
          s/\s+[a-z]$//i;
        say(
            scalar grep {
                $tmp_3_without_ending_single_characters =~
                  /(^|[,;\s_)(])$_($|[,;\s_)(])/i
              } @advs
        );
        (
            scalar grep {
                $tmp_3_without_ending_single_characters =~
                  /(^|[,;\s_)(])$_($|[,;\s_)(])/i
              } @advs_without_ending_single_characters
          )
          || ( scalar grep { $tmp->[2] =~ /(^|[,;\s_)(])$_($|[,;\s_)(])/i }
            @advs_without_ending_single_characters )
          || (
            scalar grep {
                ( join ' ', @advs_without_ending_single_characters ) =~
                  /(^|[,;\s_)(])$_($|[,;\s_)(])/i
            }
            split /[;\s]/,
            $tmp_3_without_ending_single_characters
          )
          ? do {
            my @new_arrays = ();
            say Dumper $tmp;
            foreach my $index ( 0 .. @{ $tmp->[4] } ) {
                next if $tmp->[4]->[$index]->[0] !~ /[=][>]/;

                my @subclauses_from_tmp = ();

                my $sub_index = $index + 1;
                while ( $tmp->[4]->[$sub_index]
                    && ( my $subclause = $tmp->[4]->[$sub_index] )->[0] !~
                    /[=][>]/ )
                {

                    push @subclauses_from_tmp, $subclause;

                    $sub_index += 1;
                }

                push @new_arrays, map {
                    [
                        $_->[0],
                        $_->[1],
                        $_->[2],
                        $_->[3],
                        $_->[4],
                        $_->[5],
                        @$tmp,

                        # index 12:
                        \@subclauses_from_tmp,
                    ]
                } $tmp->[4]->[$index];
            }

            #map {
            #[ $_->[0], $_->[1], $_->[2], $_->[3], $_->[4], $_->[5], @$tmp ]
            #} @{ $tmp->[4] }

            @new_arrays;

          }
          : ()
      }
      grep {
        length $_->[1] == 1
          || (
            AI::Selector::traditional_match( \@is_subj_noun_synonym, $_->[1] )
            || AI::Selector::traditional_match( \@is_subj_noun_synonym,
                $_->[2] )
            || AI::Selector::traditional_match( \@is_obj_noun_synonym, $_->[1] )
          )
      } @answers;
    say 'subclauses:';
    say Dumper \@subclauses;
    srand;
    my $subclause = $subclauses[ rand @subclauses ];
    my ${is_question} =
      !scalar grep { $_ eq '!=>' || $_ eq 'f=>' }
      ( split /\s+/, $subclause->[0] );
    $subclause->[0] = join ' ',
      ( grep { $_ !~ /[=][>]/ } ( split /\s+/, $subclause->[0] ) );

    $subclause->[2] = 'nothing' if !$subclause->[2];

    if ( length $subclause->[1] == 1 && length $subclause->[2] > 1 ) {
        if ( $subclause->[1] eq $subclause->[7] )
        {    #  ( length $subclause->[7] == 1 &&
                # subj
            $subclause->[1] =
              ${ $sentence_ref->{'subjects'} }
              [ rand @{ $sentence_ref->{'subjects'} } ];
        }
        elsif ( $subclause->[1] eq $subclause->[8] ) {    # obj
            $subclause->[1] = join ' ', @{ $sentence_ref->{'objects'} };
        }
    }

    elsif ( length $subclause->[2] == 1 && length $subclause->[1] > 1 ) {
        if ( $subclause->[2] eq $subclause->[7] ) {       # subj
            $subclause->[2] =
              ${ $sentence_ref->{'subjects'} }
              [ rand @{ $sentence_ref->{'subjects'} } ];
        }
        elsif ( $subclause->[2] eq $subclause->[8] ) {    # obj
            $subclause->[2] = join ' ', @{ $sentence_ref->{'objects'} };
        }
    }
    elsif ( $subclause->[1] =~ /\s[a-zA-Z]$/ && length $subclause->[2] > 1 ) {
        if ( $subclause->[1] eq $subclause->[7] ) {
            $subclause->[1] =~
s/\s[a-zA-Z]$/' ' . ${ $sentence_ref->{'subjects'} }[ rand @{ $sentence_ref->{'subjects'} } ]/eim;
        }
        elsif ( $subclause->[1] eq $subclause->[8] ) {    # obj
            $subclause->[1] =~
              s/\s[a-zA-Z]$/' ' . join ' ', @{ $sentence_ref->{'objects'} }/eim;
        }
    }

    elsif ( $subclause->[2] =~ /\s[a-zA-Z]$/ && length $subclause->[1] > 1 ) {
        if ( [ split /\s+/, $subclause->[2] ]->[-1] eq $subclause->[7]
            || $subclause->[2] =~ /\s$subclause->[7]$/i )
        {                                                 # subj
            $subclause->[2] =~
s/\s[a-zA-Z]$/' ' . ${ $sentence_ref->{'subjects'} }[ rand @{ $sentence_ref->{'subjects'} } ]/eim;
        }
        elsif ( [ split /\s+/, $subclause->[2] ]->[-1] eq $subclause->[8]
            || $subclause->[2] =~ /\s$subclause->[8]$/i )
        {                                                 # obj
            $subclause->[2] =~
              s/\s[a-zA-Z]$/' ' . join ' ', @{ $sentence_ref->{'objects'} }/eim;
        }
    }

    say '$subclause->[3] =~ /\s[a-zA-Z]([;]|$)/:';
    say $subclause->[3] =~ /\s[a-zA-Z]([;]|$)/;
    say;

    if ( $subclause->[3] =~ /\s[a-zA-Z]([;]|$)/ ) {

        my $last_word_from_subclause_9 = [ split /\s+/, $subclause->[9] ]->[-1];

        say;
        say [ split /\s+/, $subclause->[3] ]->[-1] eq
          $last_word_from_subclause_9;
        say $subclause->[3] =~ /(^|\s)$subclause->[9]([;]|$)/i;
        say $subclause->[3] =~ /(^|\s)$last_word_from_subclause_9([;]|$)/i;
        say;

        if ( [ split /\s+/, $subclause->[3] ]->[-1] eq $subclause->[7]
            || $subclause->[3] =~ /(^|\s)$subclause->[7]([;]|$)/i )
        {    # subj

            $subclause->[3] =~
s/\s[a-zA-Z]([;]|$)/' ' . (${ $sentence_ref->{'subjects'} }[ rand @{ $sentence_ref->{'subjects'} } ]) . $1/eim;
        }
        elsif ( [ split /\s+/, $subclause->[3] ]->[-1] eq $subclause->[8]
            || $subclause->[3] =~ /(^|\s)$subclause->[8]([;]|$)/i )
        {    # obj

            $subclause->[3] =~
s/\s[a-zA-Z]([;]|$)/' ' . (join ' ', @{ $sentence_ref->{'objects'} }) . $1/eim;
        }
        elsif ( [ split /\s+/, $subclause->[3] ]->[-1] eq
               $last_word_from_subclause_9
            || $subclause->[3] =~ /(^|\s)$subclause->[9]([;]|$)/i
            || $subclause->[3] =~ /(^|\s)$last_word_from_subclause_9([;]|$)/i )
        {    # obj

            #( my $adv_template = $subclause->[9] ) =~ s/[;]/ /igm;
            #foreach my $part ( @advs_without_ending_single_characters ) {
            #$adv_template =~ s/\s$part\s/ /igm;
            #}
            #foreach my $part ( @advs_without_ending_single_characters ) {
            #$adv_template =~ s/^$part\s/ /igm;
            #}
            #foreach my $part ( @advs_without_ending_single_characters ) {
            #$adv_template =~ s/\s$part$/ /igm;
            #}

            ( my $adv_template = join ' ', @advs ) =~ s/[;\s]/ /igm;
            foreach my $part ( split /[;\s]/, $subclause->[9] ) {
                $adv_template =~ s/\s$part\s/ /igm;
            }
            foreach my $part ( split /[;\s]/, $subclause->[9] ) {
                $adv_template =~ s/^$part\s/ /igm;
            }
            foreach my $part ( split /[;\s]/, $subclause->[9] ) {
                $adv_template =~ s/\s$part$/ /igm;
            }

            say '$adv_template: ', $adv_template;

            $subclause->[3] =~ s/\s[a-zA-Z]([;]|$)/ $adv_template$1/im;
        }
    }
    elsif ( length $subclause->[1] == 1 && length $subclause->[2] == 1 ) {
        $subclause->[1] =
          ${ $sentence_ref->{'subjects'} }
          [ rand @{ $sentence_ref->{'subjects'} } ]
          if $subclause->[1] eq $subclause->[7];
        $subclause->[1] =
          ${ $sentence_ref->{'objects'} }
          [ rand @{ $sentence_ref->{'objects'} } ]
          if $subclause->[1] eq $subclause->[8];
        $subclause->[2] =
          ${ $sentence_ref->{'subjects'} }
          [ rand @{ $sentence_ref->{'subjects'} } ]
          if $subclause->[2] eq $subclause->[7];
        $subclause->[2] =
          ${ $sentence_ref->{'objects'} }
          [ rand @{ $sentence_ref->{'objects'} } ]
          if $subclause->[2] eq $subclause->[8];
    }

    say '$subclause:';
    say Dumper $subclause;

    foreach
      my $adv (qw{eben nun auch noch etwa eigentlich ungefaehr ca noch also so})
    {
        $subclause->[1] =~ s/(^|\s|[;])$adv(\s|[?!]|$)/$1$2/igm;
        $subclause->[2] =~ s/(^|\s|[;])$adv(\s|[?!]|$)/$1$2/igm;
        $subclause->[3] =~ s/(^|\s|[;])$adv(\s|[?!]|$)/$1$2/igm;
    }
    $subclause->[1] =~ s/^\s+//igm;
    $subclause->[2] =~ s/^\s+//igm;
    $subclause->[1] =~ s/\s+$//igm;
    $subclause->[2] =~ s/\s+$//igm;
    $subclause->[2] =~ s/^(du)$//igm;
    $subclause->[1] =~ s/^ein\s+/das /igm;
    $subclause->[1] =~ s/^eine\s+/die /igm;
    $subclause->[1] =~ s/^einer\s+/die /igm;
    $subclause->[1] =~ s/^einem\s+/der /igm;
    $subclause->[1] =~ s/^eines\s+/das /igm;
    $subclause->[1] =~ s/^einen\s+/der /igm;

    my @verbs = split /\s+/, $subclause->[0];
    @verbs = conjugate_verb_for( lc $subclause->[1], \@verbs )
      if $subclause->[1] !~ /(^|\s|[_])du([_]|\s|$)/i
          && $subclause->[1] !~ /(^|\s|[_])ich([_]|\s|$)/i;
    $subclause->[0] = join ' ', @verbs;

    say Dumper $subclause->[12];

    my $answer = $data->{lang}{is_question}
      ? phrase_question(
        $CLIENT_ref,
        $subclause->[0],    # verb
        $subclause->[1],    # subj
        $subclause->[2],    # obj
        $subclause->[3],    # advs
        $subclause->[12],
        $subclause->[4],    # question word
      )
      : phrase(
        $CLIENT_ref,
        $subclause->[0],    # verb
        $subclause->[1],    # subj
        $subclause->[2],    # obj
        $subclause->[3],    # advs
        $subclause->[12],
      );
    $answer .= '?' if $is_question;

    say 'answer:';
    say $answer;

    my @answers_reason_asking =
      answers_reason_asking( $CLIENT_ref, $sentence_ref, $subclauses_ref );
    my $one_of_them = $answers_reason_asking[ rand @answers_reason_asking ];
    return (
        ( length $answer > 1 ? $answer : q{} ),
        $one_of_them ? $one_of_them : ()
    );
}

sub conjugate_verb_for {
    my ( $subj, $verbs ) = @_;

    if ( !$verbs ) {
        $verbs = $subj;
        $subj  = q{};     # empty
    }

    return @$verbs if LANGUAGE() eq 'en';

    #return @$verbs if $subj !~ /^du$/;

  VERB: foreach my $item (@$verbs) {
        my $old_item = $item;
        foreach my $verb_pair ( get_verb_conjugation_table() ) {
            my $vone = $verb_pair->[0];
            my $vtwo = $verb_pair->[1];

            say "changing in " . $item . ": " . $vone . ' to ' . $vtwo;
            $item =~ s/(.*?)$vone(\s|_|[;]|$)/$1$vtwo$2/igm;
            next VERB if $item ne $old_item;

            say "changing in " . $item . ": " . $vtwo . ' to ' . $vone;
            $item =~ s/(.*?)$vtwo(\s|_|[;]|$)/$1$vone$2/igm;
            next VERB if $item ne $old_item;
        }

        #next if lc $item eq 'ist';
        if ( $subj =~ /^du$/ ) {
            if ( lc $item eq 'ist' ) {
                $item = 'bist';
                next VERB;
            }
        }

        next if LANGUAGE() eq 'en';

        if ( $item =~ /st$/ ) {
            $item =~ s/sst$/ssst/igm;
            $item =~ s/st$/e/igm;
            $item =~ s/zt$/ze/igm;
            $item =~ s/ee$/e/igm;
            $item = 'ist' if lc $item eq 'ie';
        }
        elsif ( $item =~ /e$/ ) {
            $item =~ s/(n|l|m|r|p|b|k|t)te$/$1tee/igm;
            $item =~ s/e$/st/igm;
            $item =~ s/zst$/zt/igm;
            $item =~ s/tst$/test/igm;
        }
        $item =~ s/sss/ss/igm;
    }
    return @$verbs;
}

sub answer_sentence_yes_no {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref, $sentence, $is_question ) = @_;

    $sentence_ref = strip_nothings($sentence_ref);

    #	foreach my $result_ref (@$fact_database) {
    #		say join ', ', @$result_ref;
    #	}

    my @advs = map { lc $_ } @{ $sentence_ref->{'advs'} };
    my $description = lc $sentence_ref->{'description'} || '';
    my $advs_str = join ';', sort @advs;

    $description =~ s/nothing//igm;
    $description =~ s/\s\s/ /igm;
    $description =~ s/^\s//igm;
    $description =~ s/\s$//igm;

    say "description: ", $description;

    my $description_last_word = ( split /[\s_]/, $description )[-1];
    my %is_description_synonym =
      ( pos_of( $CLIENT_ref, $description_last_word ) ) == $data->{const}{NOUN}
      ? %{ noun_synonyms( $description, 0, 1 ) }
      : ( $description => 1 );

    my @results                = ();
    my @results_with_other_obj = ();

    my @is_subj_noun_synonym = ();
    my @is_obj_noun_synonym  = ();

    foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ) {
        say 7;
        my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
        foreach my $sub (@arr_sub) {

            #            next if $sub =~ /nothing/;

            say 8;
            push @is_subj_noun_synonym, noun_synonyms( $sub, 0, 1 );

        }
    }
    my @arr_objs = ();
    foreach my $obj ( @{ $sentence_ref->{'objects'} } ) {
        my @arr_objs_temp =
          map { my $new_one = $_ . '' } @arr_objs;
        @arr_objs = ();

        say 'obj: ', $obj;
        $obj =~ s/\soder\s/ und /igm;
        $obj =~ s/\sand\s/ und /igm;
        $obj =~ s/\sor\s/ und /igm;
        $obj =~ s/\sund\s/ und /igm;    # big and small (i)
        my @arr_obj = split /\sund\s/, $obj;

        #				say Dumper @arr_obj;
        for my $item (@arr_obj) {
            $item =~ s/^\s//igm;
            $item =~ s/\s$//igm;
            foreach my $temp (@arr_objs_temp) {
                push @arr_objs, $temp . ' ' . $item;
            }
            if ( not(@arr_objs_temp) ) {
                push @arr_objs, $item;
            }
        }

    }

    say 5;
    foreach my $obj ( map { lc $_ } @arr_objs ) {
        $obj =~ s/[)(]//igm;
        push @is_obj_noun_synonym, noun_synonyms( $obj, 0, 1 );

  #                foreach my $data->{const}{VERB} (
  #                    ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ), )
  #                {
  #                    next if $data->{const}{VERB} eq 'nothing';
  #                    $data->{const}{VERB} =~ s/nothing//igm;
  #                    $data->{const}{VERB} =~ s/  / /igm;
  #
  #                    say 'verb: ', $data->{const}{VERB};
  #
  #                    my %is_verb_synonym= verb_synonyms($data->{const}{VERB});
  #
  #
  #                }
    }
    my $verb = join ' ', sort @{ $sentence_ref->{'verbs'} };
    my %is_verb_synonym = %{ verb_synonyms($verb) };

    my $sub = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ));
    my $obj = join ' ',
      sort_linking(map { lc $_ } ( @{ $sentence_ref->{'objects'} } ));

    my ( $results_sub_ref, $results_second_choice_sub_ref ) = @{
        solve_variable_problems(
            $CLIENT_ref,              \%is_verb_synonym,
            \@is_subj_noun_synonym,   \@is_obj_noun_synonym,
            $sentence_ref,            $description,
            \%is_description_synonym, $sub,
            $obj,                     \@advs,
            0,                        $is_question,
            0,
        )
      };

    push @results,                @$results_sub_ref;
    push @results_with_other_obj, @$results_second_choice_sub_ref;

    #foreach my $_sub ( map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ) {
    #my @arr_sub = split /\s(und|oder|and|or)\s/i, $_sub;
    #say 2;
    #foreach my $sub (@arr_sub) {
    #my @arr_objs = ();
    #say 3;

    #%{$data->{lang}{is_subj_noun_synonym}}= noun_synonyms($sub);

    #foreach my $obj ( @{ $sentence_ref->{'objects'} } ) {
##                say 4;
    #my @arr_objs_temp =
    #map { $_ . '' } @arr_objs;
    #@arr_objs = ();

    #say 'obj: ', $obj;
    #$obj =~ s/\soder\s/ und /igm;
    #$obj =~ s/\sand\s/ und /igm;
    #$obj =~ s/\sor\s/ und /igm;
    #$obj =~ s/\sund\s/ und /igm;    # big and small (i)
    #my @arr_obj = split /\sund\s/, $obj;

    #say 5;

    ##				say Dumper @arr_obj;
    #for my $item (@arr_obj) {
    #$item =~ s/^\s//igm;
    #$item =~ s/\s$//igm;
    #foreach my $temp (@arr_objs_temp) {
    #push @arr_objs, $temp . ' ' . $item;
    #}
    #if ( not(@arr_objs_temp) ) {
    #push @arr_objs, $item;
    #}
    #}

    #say 6;
    #}

    #say 7;
    #foreach my $obj ( map { lc $_ } @arr_objs ) {
    #$obj =~ s/[)(]//igm;
    #%{$data->{lang}{is_obj_noun_synonym}}= noun_synonyms($obj);
    #foreach my $data->{const}{VERB} (
    #( join ' ', sort @{ $sentence_ref->{'verbs'} }, ), )
    #{
    #say 8;
    #next if $data->{const}{VERB} eq 'nothing';
    #$data->{const}{VERB} =~ s/nothing//igm;
    #$data->{const}{VERB} =~ s/  / /igm;

    #%{$data->{lang}{is_verb_synonym}}= verb_synonyms($data->{const}{VERB});

#my ( $results_sub_ref, $results_second_choice_sub_ref ) =
#search_semantic(
#$CLIENT_ref,              \%is_verb_synonym,    #\@is_subj_noun_synonym,   \@is_obj_noun_synonym,
#$sentence_ref,            $description,
#\%is_description_synonym, $sub,
#$obj,                     \@advs,
#0,
#$is_question,
#0,
#);

    #push @results, @$results_sub_ref;
    #push @results_with_other_obj,
    #@$results_second_choice_sub_ref;
    #}
    #}
    #}
    #}

    my @results_old = @results;
    @results = ();
    @results = grep { $_->[0] == 1 } @results_old;
    @results = @results_old if !@results;

    my @results_with_other_obj_old = @results_with_other_obj;
    @results_with_other_obj = ();
    @results_with_other_obj =
      grep { $_->[0] == 1 } @results_with_other_obj_old;
    @results_with_other_obj = @results_with_other_obj_old
      if !@results_with_other_obj;

    my @results_negative =
      grep { ' ' . ( join @$_ ) . ' ' =~ /(\s(((nicht|not)\s)|kein))/ }
      @results;

    @results = @results_negative if @results_negative;

    #my part_of_speech_get_memory()_backup = {};
    #if ( $data->{intern}{in_cgi_mode} ) {
    #part_of_speech_get_memory()_backup = {%{part_of_speech_get_memory()}};

#my $from_yaml_temp =
#pos_file_read( $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.brain' );

    #%{part_of_speech_get_memory()} = (%{part_of_speech_get_memory()},
    #(
    #defined $from_yaml_temp->[0]
    #? $from_yaml_temp->[0]
    #: {}
    #))
    #;
    #}

    my @answers = ();
    foreach my $result ( ( $results[ rand(@results) ] ) ) {

        #		shift @$result;

        #		print Dumper @$result
        say 'sentence to print:';

        #        print Dumper $result;

        #		print $phr;

        my $phr = phrase( $CLIENT_ref, @$result );

        next if length($phr) <= 4;
        if ( LANGUAGE() eq 'de' ) {
            push @answers,
              ( ( $phr =~ /(nicht|kein|nie)/i ) ? ('Nein, ') : ('Ja, ') )
              . $phr;
            push @answers,
              (
                  ( $phr =~ /(nicht|kein|nie)/i )
                ? ('Nein, ')
                : ('Ja, ')
              ) . $phr;
        }
        else {
            push @answers,
              ( ( $phr =~ /(nicht|kein|nie)/i ) ? ('No, ') : ('Yes, ') ) . $phr;
            push @answers,
              (
                  ( $phr =~ /(nicht|kein|nie)/i )
                ? ('No, ')
                : ('Yes, ')
              ) . $phr;
            push @answers,
              (
                  ( $phr =~ /(nicht|kein|nie)/i )
                ? ('No, I\'m sure, ')
                : ('Yes, ')
              ) . $phr;
        }
    }
    if ( not(@results) ) {
        no_answers_found($sentence);
        if ( !@results_with_other_obj ) {
            my @names = get_user_names();
            if ( LANGUAGE() eq 'de' ) {
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein!';
                push @answers, 'Lerne, logisch zu denken'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein!';
                push @answers, 'Nein.';
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Diese Aussage ist falsch'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Das ist falsch'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Das ist nicht wahr'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '!';
                push @answers, 'Du spinnst'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '!';
                push @answers, 'Diese Aussage ist falsch.';
                push @answers, 'Das ist falsch.';
                push @answers, 'Das ist nicht wahr.';
                push @answers, 'Du luegst.';
                push @answers, 'Niemals!';
                push @answers, 'Auf gar keinen Fall.';
                push @answers, 'Nein, da bin ich mir nicht ganz sicher.';
                push @answers, 'Nein.';
                push @answers, 'Nein'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Nein.';
                push @answers, 'Lerne, logisch zu denken, du Mensch.';
                push @answers, 'Lerne, logisch zu denken'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
            }
            if ( LANGUAGE() eq 'en' ) {
                push @answers, 'Sorry, but I cannot believe that'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Sorry, but I cannot believe what you say'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Sorry, but my opinion is that you are wrong'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'That\'s wrong.';
                push @answers, 'That\'s wrong'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.';
                push @answers, 'Don\'t lie'
                  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '!';
                push @answers, 'Sorry, but I cannot believe that.';
                push @answers, 'Sorry, but I cannot believe what you say.';
                push @answers, 'Sorry, but my opinion is that you are wrong.';
                push @answers, 'That\'s wrong.';
                push @answers, 'That\'s wrong.';
                push @answers, 'You lie.';
                push @answers,
'I\'m sorry to say that, but you are lying without any reason.';
                push @answers,
'I\'m sorry to say that, but perhaps something your mind is wrong...';
            }
        }
        else {
            foreach my $result (
                ( $results_with_other_obj[ rand(@results_with_other_obj) ] ) )
            {

                #				shift @$result;
                if ( LANGUAGE() eq 'en' ) {
                    push @answers, 'Your mind is probably broken. '
                      . phrase( $CLIENT_ref, @$result );
                    push @answers, 'No, ' . phrase( $CLIENT_ref, @$result );
                    push @answers, 'No, but ' . phrase( $CLIENT_ref, @$result );
                    push @answers, 'No, but I know how it is. '
                      . phrase( $CLIENT_ref, @$result );
                    push @answers, 'That\'s wrong, but I know the right fact. '
                      . phrase( $CLIENT_ref, @$result );
                    push @answers,
                      'That\'s wrong, but ' . phrase( $CLIENT_ref, @$result );
                }
                else {
                    push @answers,
                      'Nein, aber ' . phrase( $CLIENT_ref, @$result );
                    push @answers,
                      'Nein! Aber ' . phrase( $CLIENT_ref, @$result );
                }
            }
        }

        push @answers, @answers;
        push @answers, @answers;
        push @answers, @answers;
        push @answers, new_things_wanted_to_know($CLIENT_ref);
    }

    foreach my $posible_answer (@answers) {
        say( ">> posible answer: ", $posible_answer );
    }

    if ( ( not @answers ) ) {
        my @answers_new_things_wanted_to_know =
          new_things_wanted_to_know($CLIENT_ref);

        if ( LANGUAGE() eq 'de'
            && $sentence =~ /(^|\s)(du|ich|mich|dich|mir|dir)($|\s)/i )
        {
            push @answers, ( 'Ja.', 'Nein.', ) x 150;
        }
        elsif ( LANGUAGE() eq 'de' && $sentence =~ /(^|\s)du($|\s)/i ) {

            my @verbs_to_use = @{ $sentence_ref->{'verbs'} };

            if ( !grep { /^du$/i } @{ $sentence_ref->{'objects'} } ) {
                @verbs_to_use = conjugate_verb_for( \@verbs_to_use );
            }

            push @answers, (
                (
                    'Nein, '
                      . lcfirst phrase_question(
                        $CLIENT_ref,
                        ( join ' ', @verbs_to_use ),
                        'du',
                        ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                        []
                      )
                      . '?'
                ) x 7,
                'Ja...',
                'Nein...',
                'Nein.',
                'Ja.',

                #				'Niemals!',
                'Keine Ahnung.',
                'Ich glaube, ich muss noch viel lernen.',
                'Vielleicht sollte ich einmal ein Lexikon zu raten ziehen.',
                'Bei all den Fragen ist es nicht leicht, eine KI zu sein!',
'Du hast mir soeben gezeigt, das ich sehr viel noch nicht weiss...',
                'Fuer alles habe ich nun auch nicht eine Antwort!',
                'Ich weiss es nicht, kannst du es mir bitte erklaeren?',
                'Nicht schimpfen, wenn ich es nicht weiss!',
                'Keine Ahnung, sag es mit bitte...',
            );
        }
        elsif ( LANGUAGE() eq 'de' ) {

            my @verbs_to_use = @{ $sentence_ref->{'verbs'} };

            @verbs_to_use = conjugate_verb_for( \@verbs_to_use );

            my $subj_string =
              ( join ' ', sort @{ $sentence_ref->{'subjects'} }, );
            $subj_string =~ s/nothing//igm;
            $subj_string =~ s/\s+//igm;

            push @answers,
              (
                (
                    'Nein, '
                      . lcfirst phrase_question(
                        $CLIENT_ref,
                        ( join ' ', @verbs_to_use ),
                        ( join ' ', sort @{ $sentence_ref->{'subjects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                        [],
                        $sentence_ref->{'questionword'},
                      )
                      . '?'
                ) x 7
              ) if $subj_string;
            push @answers, (
                'Ja...',
                'Nein...',
                'Nein.',
                'Ja.',

                #				'Niemals!',
                'Keine Ahnung.',
                'Ich glaube, ich muss noch viel lernen.',
                'Vielleicht sollte ich einmal ein Lexikon zu raten ziehen.',
                'Bei all den Fragen ist es nicht leicht, eine KI zu sein!',
'Du hast mir soeben gezeigt, das ich sehr viel noch nicht weiss...',
                'Fuer alles habe ich nun auch nicht eine Antwort!',
                'Ich weiss es nicht, kannst du es mir bitte erklaeren?',
                'Nicht schimpfen, wenn ich es nicht weiss!',
                'Keine Ahnung, sag es mit bitte...',
            );
        }
        if ( LANGUAGE() eq 'en' ) {
            push @answers,
              (
                'I can\'t believe that, human.',
                'That cannot be true.',
                'That can\'t be true.',
                'That cannot be true, I\'m sure!',
                'I do not know much about such topics, human.',
                'Well, if you say that, it has to be true.',
                'Well, if you say that, it must be true.',
                'Why should I answer you?',
              );
            push @answers, @answers;
            push @answers, @answers;
        }
        else {
            push @answers, (

                #				'Nein, das kann ich nicht glauben!',
                #				'Das glaube ich dir nicht.',
                #				'Das kann nicht sein!',
                #				'Das wird niemals so sein!',
                'Ja...',
                'Nein...',
                'Nein.',
                'Ja.',

                #				'Niemals!',
                'Keine Ahnung.',
                'Ich glaube, ich muss noch viel lernen.',
                'Vielleicht sollte ich einmal ein Lexikon zu raten ziehen.',
                'Bei all den Fragen ist es nicht leicht, eine KI zu sein!',
'Du hast mir soeben gezeigt, das ich sehr viel noch nicht weiss...',
                'Fuer alles habe ich nun auch nicht eine Antwort!',
                'Ich weiss es nicht, kannst du es mir bitte erklaeren?',
                'Nicht schimpfen, wenn ich es nicht weiss!',
                'Keine Ahnung, sag es mit bitte...',
            );
            push @answers, @answers;
            push @answers, @answers;
        }
        @answers = $answers[ rand @answers ];
        my @answers_suggestions =
          suggestions( $CLIENT_ref, $sentence_ref, $subclauses_ref );
        push @answers, @answers_suggestions;
        push @answers, @answers_suggestions;
        push @answers, @answers_suggestions;
        push @answers, @answers_suggestions;
        push @answers, $answers_new_things_wanted_to_know[
          rand @answers_new_things_wanted_to_know ];
        say 'posible answers: ', scalar @answers;
    }

#%{part_of_speech_get_memory()} = %{part_of_speech_get_memory()}_backup if $data->{intern}{in_cgi_mode};

    return @answers;
}

sub answers_for_negative_statement {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref ) = @_;

    return if grep { $_ ne 'nothing' } @{ $sentence_ref->{'verbs'} };

    $sentence_ref = strip_nothings($sentence_ref);

    #	foreach my $result_ref (@$fact_database) {
    #		say join ', ', @$result_ref;
    #	}

    my @advs = map { lc $_ } @{ $sentence_ref->{'advs'} };
    my $adv_string = join ' ', @advs;
    $adv_string =~ s/_/ /igm;

    my @answers = ();

    say '$adv_string: ', $adv_string;

    my $all = join ' ', (
        ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ),

        #						( join ' ', map { lc $_ } ( @{ $sentence_ref->{'subjects'} } ) ),
        ( join ' ', map { lc $_ } ( @{ $sentence_ref->{'objects'} } ) ),
        $adv_string,
    );
    my $subj = join ' ', map { lc $_ } ( @{ $sentence_ref->{'subjects'} } );
    my $obj  = join ' ', map { lc $_ } ( @{ $sentence_ref->{'objects'} } );

    if (   $adv_string =~ /((^|\s)(nicht|not|no)(\s|_|$))|((^|\s)kein)/
        || $obj =~ /((^|\s)(nicht|not|no)(\s|_|$))|((^|\s)kein)/ )
    {
        say '$adv_string: ', $adv_string;
        $adv_string =~
          s/((^|\s)nicht(\s|_|$))|((^|\s)kein(|e|er|en|em|es|s))/ /igm;

        foreach my $questionword (
            ( ( LANGUAGE() eq 'de' ) ? (qw{was}) : (qw{what}) ) )
        {
            foreach my $extra (
                (
                      ( LANGUAGE() eq 'de' )
                    ? ( 'denn dann', 'dann', 'denn', 'denn nun', 'dann' )
                    : ('than')
                )
              )
            {
                my $phr = join ' ', (
                    $questionword,
                    ( join ' ', sort @{ $sentence_ref->{'verbs'} }, ),
                    (
                        join ' ',
                        map { lc $_ } ( @{ $sentence_ref->{'subjects'} } )
                    ),
                    $extra,

         #						( join ' ', map { lc $_ } ( @{ $sentence_ref->{'objects'} } ) ),
         #					$adv_string,
                );
                $phr =~ s/nothing//igm;
                $phr =~ s/_/ /igm;
                $phr =~ s/\s\s/ /igm;
                push @answers, ucfirst $phr . ' ?';
            }
        }
    }

    foreach my $sent (@answers) {
        my $index           = -1;
        my @sentence_do_say = ();
        my @words           = split /\s/, $sent;
        while ( my $word = shift @words ) {
            $index += 1;

            next if $word eq 'nothing';

            if ( LANGUAGE() ne 'en' ) {
                my $wt = pos_of( $CLIENT_ref, $word, $index == 0, 1, 1 );
                if ( $wt == $data->{const}{NOUN} ) {
                    $word = ucfirst $word;
                }
            }
            push @sentence_do_say, $word;
        }
        $sent = join ' ', @sentence_do_say;
        $sent =~ s/\s([?!])/$1/igm;
        $sent .= '?';
    }

    if ( $all =~ /(falsch)|(wrong)/ ) {
        if ( LANGUAGE() eq 'de' ) {
            push @answers, 'Was ist dann richtig?';
            push @answers, 'Was ist denn dann richtig?';
            push @answers, 'Was ist denn nicht falsch?';
            push @answers, 'Was denn dann?';
        }
        if ( LANGUAGE() eq 'en' ) {
            push @answers, 'But what <i>is</i> true?';
            push @answers, 'But what <i>is</i> true, human?';
            push @answers,
              'Please explain what is marked as \'true\' in your mind...';
            push @answers, 'Well, you should know it.';
        }
    }

    return @answers;
}

sub answers_reason_asking {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref ) = @_;

    $sentence_ref = strip_nothings($sentence_ref);

    #	foreach my $result_ref (@$fact_database) {
    #		say join ', ', @$result_ref;
    #	}

    my @advs = map { lc $_ } @{ $sentence_ref->{'advs'} };
    my $adv_string = join ' ', @advs;
    $adv_string =~ s/_/ /igm;

    my @answers = ();

    say '$adv_string: ', $adv_string;

    my $subj = join ' ', map { lc $_ } ( @{ $sentence_ref->{'subjects'} } );
    my $obj  = join ' ', map { lc $_ } ( $sentence_ref->{'objects'}[-1] );

    my $verb_synonyms =
      verb_synonyms( join ' ',
        map { lc $_ } ( @{ $sentence_ref->{'verbs'} } ) );

    my $obj_synonyms = noun_synonyms(
        ( join ' ', map { lc $_ } ( $sentence_ref->{'objects'}[-1] ) ),
        0, 1, );

    foreach my $questionword (
        ( ( LANGUAGE() eq 'de' ) ? (qw{warum wieso weshalb}) : (qw{why}) ) )
    {
        my @effects = ();

        # sql query for reason-effect pairs
        my $sth = semantic_network_execute_sql(
            qq{
        		SELECT 
        			`reason_verb`, `reason_noun`, `reason_adv`,
        			`effect_verb`, `effect_noun`, `effect_adv`
        		FROM reason_effect
			}
        );

        # search for reason-effect pairs
        while ( my $entry = $sth->fetchrow_arrayref ) {
            ##foreach my $entry ( @{ $data->{persistent}{semantic_net}->{'_reason_effect'} } ) {

            #print Dumper $entry;
            #say ( $verb_synonyms{
            #$entry->[0] } );
            #say (   (scalar grep {
            #$entry->[1]
            #eq  $_ }
            #@{ $sentence_ref->{'objects'} } )
            #|| ( $entry->[1] eq $obj )
            #|| AI::Selector::traditional_match(
            #\%obj_synonyms,
            #$entry->[1]
            #) );
            #say (
            #$adv_string =~ /$entry->[2]/
            #|| !$entry->[2]
            #|| $entry->[2] =~ /nothing/
            #);
            #select undef, undef, undef, 3 if $entry->[1] =~ /baer/;

            if (
                ( $verb_synonyms->{ $entry->[0] } )
                && (
                    (
                        scalar grep { $entry->[1] eq $_ }
                        @{ $sentence_ref->{'objects'} }
                    )
                    || ( $entry->[1] eq $obj )
                    || AI::Selector::traditional_match(
                        $obj_synonyms, $entry->[1]
                    )
                )
                && (   $adv_string =~ /$entry->[2]/
                    || !$entry->[2]
                    || $entry->[2] =~ /nothing/ )
              )
            {

                # add effect to list
                push @effects,
                  {
                    verb => $entry->[3],
                    noun => $entry->[4],
                    adv  => $entry->[5],
                  };

                # sql query for reason-effect pairs
                my $sth = semantic_network_execute_sql(
                    qq{
						SELECT 
							`reason_verb`, `reason_noun`, `reason_adv`,
							`effect_verb`, `effect_noun`, `effect_adv`
						FROM reason_effect
					}
                );

                # search for reason-effect pairs for this effect
                while ( my $entry_second = $sth->fetchrow_arrayref ) {
                    if (
                           ( $entry->[3] eq $entry_second->[0] )
                        && ( $entry->[4] eq $entry_second->[1] )
                        && (   $entry->[5] =~ /$entry_second->[2]/
                            || !$entry_second->[2]
                            || $entry_second->[2] =~ /nothing/ )
                      )
                    {

                        # add effect to list
                        # pop @effects;
                        push @effects,
                          {
                            verb => $entry_second->[3],
                            noun => $entry_second->[4],
                            adv  => $entry_second->[5],
                          };
                    }
                }
            }
        }

        foreach my $effect_ref (@effects) {

            if ( !$data->{persistent}{semantic_net}->{'_is_negative_effect'}
                { $effect_ref->{noun} . ' ' . $effect_ref->{verb} } )
            {

              #if ( !$effect_ref->{noun} || $effect_ref->{noun} =~ /nothing/ ) {
              #	next;
              #}

                my $phr = join ' ', (

                    phrase_question(
                        $CLIENT_ref,
                        $effect_ref->{verb},
                        $subj,
                        $effect_ref->{noun},
                        $effect_ref->{adv} . ';'
                          . ( LANGUAGE() eq 'de' ? 'nicht' : 'not' ),
                        [],
                        $questionword,
                    )
                );
                push @answers, ucfirst( $phr . ' ?' );

                $phr = join ' ', (

                    phrase(
                        $CLIENT_ref,
                        (
                              LANGUAGE() eq 'en' ? 'should'
                            : $subj      eq 'du' ? 'solltest'
                            : 'sollte'
                          )
                          . ' '
                          . $effect_ref->{verb},
                        $subj,
                        $effect_ref->{noun},
                        $effect_ref->{adv},
                        [],
                    )
                );
                push @answers, ucfirst $phr;
            }
            else {
                my $phr = join ' ', (

                    phrase(
                        $CLIENT_ref,
                        (
                              LANGUAGE() eq 'en' ? 'need'
                            : $subj      eq 'du' ? 'brauchst'
                            : $subj      eq 'du' ? 'brauche'
                            : 'braucht'
                          )
                          . ' '
                          . $effect_ref->{verb},
                        $subj,
                        $effect_ref->{noun},
                        $effect_ref->{adv} . ';'
                          . ( LANGUAGE() eq 'de' ? 'nicht' : 'not' ),
                        [],
                    )
                );
                push @answers, ucfirst $phr;
            }
        }
    }

    foreach my $sent (@answers) {
        my $index           = -1;
        my @sentence_do_say = ();
        my @words           = split /\s/, $sent;
        while ( my $word = shift @words ) {
            $index += 1;

            next if $word eq 'nothing';

            if ( LANGUAGE() ne 'en' ) {
                my $wt = pos_of( $CLIENT_ref, $word, $index == 0, 1, 1 );
                if ( $wt == $data->{const}{NOUN} ) {
                    $word = ucfirst $word;
                }
            }
            push @sentence_do_say, $word;
        }
        $sent = join ' ', @sentence_do_say;
        $sent =~ s/\s([?!])/$1/igm;
    }

    say 'answers_reason_asking:';
    say Dumper \@answers;

    return @answers;
}

sub new_things_wanted_to_know {
    my $CLIENT_ref = shift;
    no strict;
    no warnings;
    my @objects = ();
    foreach my $record ( @{$AI::SemanticNetwork::semantic_net__facts} ) {
        if (   $record->[1]->[2] !~ /^[=]/
            && $record->[1]->[2] =~ /^(ein|eine)\s/i )
        {
            push @objects, $record->[1]->[2];
        }
    }

    use warnings;
    use strict;

    @objects = grep { $_ } @objects;

    return if !@objects;

    my @answers = ();
    foreach my $thing ( ( $objects[ rand(@objects) ], ) ) {
        my $thing_2 = $objects[ rand(@objects) ];

        $thing   =~ s/einen /ein /igm;
        $thing_2 =~ s/einen /ein /igm;
        ( my $thing_akkusativ   = $thing )   =~ s/ein\s/einen /igm;
        ( my $thing_dativ       = $thing )   =~ s/ein\s/einem /igm;
        ( $thing_dativ          = $thing )   =~ s/eine\s/einer /igm;
        ( my $thing_akkusativ_2 = $thing_2 ) =~ s/ein\s/einen /igm;
        ( my $thing_dativ_2     = $thing_2 ) =~ s/ein\s/einem /igm;
        ( $thing_dativ_2        = $thing_2 ) =~ s/eine\s/einer /igm;

        next if lc $thing eq lc $thing_2;

        my $thing_nominativ = $thing;
        $thing_nominativ =~ s/einen /ein /igm;

        #$subj =~ s/die /diesen /igm;
        #$subj =~ s/(der|al|haft|lich|ig|isch|ich) /diesem /igm;
        #$subj =~ s/das /diesem /igm;
        #$subj =~ s/den /diesem /igm;
        #$subj =~ s/des /diesem /igm;
        #$subj =~ s/dem /diesem /igm;
        #$subj = ' ' . $subj . ' ';
        #$subj =~ s/\s(dich|du)\s/ dir /igm;
        #$subj =~ s/\s(mich|ich)\s/ mir /igm;
        #$subj =~ s/^\s//igm;
        #$subj =~ s/\s$//igm;

        next if $thing =~ /nothing/;

        if ( LANGUAGE() eq 'en' ) {
            push @answers,
              'Have you ever heard something about ' . $thing . '?';
            push @answers, 'What is ' . $thing . '?';
            push @answers, 'Do you know what ' . $thing . ' is?';
            push @answers,
              'Has ' . $thing . ' something to do with ' . $thing_2 . '?';
            push @answers,
                'Do you know whether ' 
              . $thing
              . ' has something to do with '
              . $thing_2 . '?';
        }
        else {
            push @answers, 'Was ist ' . $thing_nominativ . '?';
            push @answers, 'Kennst du ' . $thing_akkusativ . '?';
            push @answers, 'Weisst du etwas ueber ' . $thing_akkusativ . '?';
            push @answers,
                'Themawechsel. Was haeltst du von '
              . $thing_dativ
              . ' oder '
              . $thing_dativ_2 . '?';
            push @answers,
              'Themawechsel. Wie denkst du ueber ' . $thing_akkusativ . '?';
            push @answers, 'Themawechsel: ' . $thing_2 . '?';
            push @answers,
              'Ich moechte ueber etwas anderes reden. ' . $thing_2 . '?';
            push @answers,
              'Ich moechte ueber etwas anderes diskutieren. ' . $thing_2 . '?';
            push @answers,
              'Ich will ueber etwas anderes reden. ' . $thing_2 . '?';
            push @answers, 'Das ist langweilig. Wie denkst du ueber '
              . $thing_akkusativ_2 . '?';
            push @answers,
              'Langweilig. Wie denkst du ueber ' . $thing_akkusativ_2 . '?';
            push @answers,
              'Hmm. Wie denkst du ueber ' . $thing_akkusativ_2 . '?';
            push @answers,
              'Tja! Hmm, Wie denkst du ueber ' . $thing_akkusativ_2 . '?';
        }
    }

    foreach my $posible_answer (@answers) {
        say( ">> new posible answer: ", $posible_answer );
    }

    foreach my $answer (@answers) {
        $answer =~ s/([,.!-;])/ $1 /gm;
        $answer =~ s/  / /gm;
        my @sentence        = split / /, $answer;
        my $index           = -1;
        my @sentence_do_say = ();
        while ( my $word = shift @sentence ) {
            $index += 1;

            next if $word eq 'nothing';

            #			print "pos_of( $CLIENT_ref, $word, 0 )\n";
            my $wt = pos_of( $CLIENT_ref, $word, 0, 1, 1 );
            if ( $wt == $data->{const}{NOUN} ) {
                $word = ucfirst $word;
            }
            push @sentence_do_say, $word;
        }

        my $sentence = join ' ', @sentence_do_say;
        $sentence =~ s/[,]/, /gm;
        $sentence =~ s/ [,]/,/gm;
        $sentence =~ s/_/ /gm;
        $answer = $sentence;
    }

    my @default_answers = ();

    my @names = get_user_names();

    push @default_answers, (

        #		'Darueber muss ich noch einmal nachdenken'
        #		  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Nein' . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ja'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Hmmm.',
        'Hmmm. ;)',
        'Hmmm. :)',
        'Hmmm hmmm.',
        'Ich werde mir das merken ;)',
        'Danke!',

        #		'Du bist schlau!',
        'Nein' . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ja'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Hmmm.',
        'Hmmm. ;)',
        'Hmmm. :)',
        'Hmmm hmmm.',
        ';)',
        ':)',
        'Nein.',
        'Nein. :)',
        'Nein. ;)',
        'Nein'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ja'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Rede bitte deutlicher.',

        #		'Ich bin intelligenter als du!',
        #		'Ich bin intelligenter als du! ;)',
        #		'Ich bin intelligenter als du'
        #		  . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . ' ;)',
        'Was machst du?',
        'Nein'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ja'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Was machst du so?',

        #		'Du bist ein Mensch, oder?',
        #		'Du bist ein Mensch?',
        'Hmmm.',
        'Hmmm. ;)',
        'Hmmm. :)',
        'Hmmm hmmm.',

        #		'Du bist ein Mensch? Das kann ich nicht glauben ;)',
        #		'Ich kann nicht glauben, dass du ein Mensch bist ;)',
        'Ich bin intelligenter als du'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ich verstehe nicht.',
        'Danke ;)',
        'Hmm, ich kenne mich damit nicht aus.',
        'Darueber muss ich noch einmal nachdenken...',

      #		'Darueber muss ich noch einmal nachdenken, wenn ich alleine bin... ;)',
      #		'Darueber muss ich noch einmal nachdenken, wenn niemand da ist... ;)',
      #		'Tja, ich bin eben intelligenter als du! ;)',
        'Hmmm.',
        'Hmmm. ;)',
        'Nein'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Ja'
          . ( (@names) ? ', ' . $names[ rand(@names) ] : '' ) . '.',
        'Hmmm. :)',
        'Hmmm hmmm.',

        #		'Tja, ich bin eben intelligenter als du! :)',

    ) if LANGUAGE() eq 'de';

    push @default_answers, (
        'Mmmh.',
        'Yes.',
        'Yes, human.',
        'No.',
        'No, human.',
        'Yes, I can believe.',
        'I cannot believe.',
        'Maybe.',
        'Perhaps.',
        'Yes!',
        'Wait a minute...',
        'Hmmm.',
        'Hmmm. ;)',
        'Hmmm. :)',
        'Hmmm hmmm.',

    ) if LANGUAGE() eq 'en';

    push @answers, @answers;
    push @answers, @default_answers;

    return @answers;
}

sub answer_sentence_statement {
    my $CLIENT_ref = shift;
    my ( $sentence_ref, $subclauses_ref ) = @_;

    my @answers_for_negative_statement =
      answers_for_negative_statement( $CLIENT_ref, $sentence_ref,
        $subclauses_ref );

    if (@answers_for_negative_statement) {
        return @answers_for_negative_statement;
    }

    my @answers_from_yes_no =
      answer_sentence_yes_no( $CLIENT_ref, $sentence_ref, $subclauses_ref, '',
        0 );

    my @answers_new_things_wanted_to_know =
      new_things_wanted_to_know( $CLIENT_ref, $sentence_ref, $subclauses_ref );

    my @answers_suggestions =
      suggestions( $CLIENT_ref, $sentence_ref, $subclauses_ref );

    my @answers_be_statements =
      be_statements( $CLIENT_ref, $sentence_ref, $subclauses_ref );

    my @reason_asking =
      answers_reason_asking( $CLIENT_ref, $sentence_ref, $subclauses_ref );

    say join '. ',
      (
        (
                 $answers_suggestions[ rand @answers_suggestions ]
              || @answers_be_statements,
        ) x 2
      );

    say join '. ',
      (
        (
                 $answers_from_yes_no[ rand @answers_from_yes_no ]
              || @answers_be_statements
              || (),
        ) x 2,
      );

    say join '. ',
      (
        (
            $answers_new_things_wanted_to_know[
              rand @answers_new_things_wanted_to_know ]
              || (),
        ) x 2,
      );

    say join '. ', ( ( @reason_asking, ) x 2, );

    srand;
    return (
        (
                 $answers_suggestions[ rand @answers_suggestions ]
              || @answers_be_statements,
        ) x 200,
        (
                 $answers_from_yes_no[ rand @answers_from_yes_no ]
              || @answers_be_statements
              || (),
          ) x 150,
        (
            $answers_new_things_wanted_to_know[
              rand @answers_new_things_wanted_to_know ]
              || (),
          ) x 15,
        ( @reason_asking, ) x 110,
        (
            LANGUAGE() eq 'de' ? ( 'Interessant!', ) x 3
            : (
                'Don\'t lie to yourself.',
                'That\'s cool.',
                'That\'s interesting.',
                'Well...',
            )
        ),
        (
            LANGUAGE() eq 'de'
            ? (
                (
                    'Aha.', 'Aha...',
                    'Das habe ich mir gemerkt. '
                      . phrase(
                        $CLIENT_ref,
                        ( join ' ', @{ $sentence_ref->{'verbs'} } ),
                        ( join ' ', sort @{ $sentence_ref->{'subjects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                        [],
                      ),
                    'Danke fuer die Information. '
                      . phrase(
                        $CLIENT_ref,
                        ( join ' ', @{ $sentence_ref->{'verbs'} } ),
                        ( join ' ', sort @{ $sentence_ref->{'subjects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'objects'} }, ),
                        ( join ' ', sort @{ $sentence_ref->{'advs'} }, ),
                        [],
                      ),
                ) x 60
              )
            : ()
        ),

    );
}

sub person_modification {
    my ( $CLIENT_ref, $subclause_ref, $subclauses_array_ref ) = @_;

    my $uses_ich_du_i_you = 0;

    foreach my $item (
        @{ $subclause_ref->{'subjects'} },
        @{ $subclause_ref->{'objects'} },
        @{ $subclause_ref->{'advs'} }
      )
    {
        if ( $item =~ /(^|\s)(ich|du|i|you)(\s|_|[;]|$)/i ) {
            $uses_ich_du_i_you = 1;
        }

        my $old_item = $item;

        $item =~ s/(^|\s|[;])mich(\s|_|[;]|$)/ dich /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])dich(\s|_|[;]|$)/ mich /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])mir(\s|_|[;]|$)/ dir /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])dir(\s|_|[;]|$)/ mir /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])mein(.?.?\s)/ dein$2/im;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])dein(.?.?\s)/ mein$2/im;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])unser/ euer/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])euer/ unser/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])dein(\s|_|[;]|$)/ mein /igm if $item !~ /ung/;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])dir(\s|_|[;]|$)/ mir /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])mir(\s|_|[;]|$)/ dir /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])ich(\s|_|[;]|$)/ du /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])du(\s|_|[;]|$)/ ich /igm;
        next if $item ne $old_item;

        $item =~ s/(^|\s|[;])you(\s|_|[;]|$)/ I /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])I(\s|_|[;]|$)/ you /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])me(\s|_|[;]|$)/ you /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])my(\s|_|[;]|$)/ your /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])your(\s|_|[;]|$)/ my /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])mine(\s|_|[;]|$)/ yours /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])yours(\s|_|[;]|$)/ mine /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])yourself(\s|_|[;]|$)/ myself /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])myself(\s|_|[;]|$)/ yourself /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])yourselves(\s|_|[;]|$)/ ourselves /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])ourselves(\s|_|[;]|$)/ yourselves /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])our(\s|_|[;]|$)/ your /igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])us(\s|_|[;]|$)/ you /igm;
        next if $item ne $old_item;
    }

  VERB:
    foreach my $item ( @{ $subclause_ref->{'verbs'} } ) {
        if ( !$uses_ich_du_i_you ) {
            $item = lc $item;

            if ( $item eq 'bin' ) {
                $item = 'ist';
            }
            if ( $item eq 'am' ) {
                $item = 'is';
            }

            next;
        }

        $item = lc $item;
        my $old_item = $item;

        $item =~ s/(^|\s|[;])hab(\s|_|[;]|$)/hast/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])habe(\s|_|[;]|$)/hast/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])hast(\s|_|[;]|$)/habe/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])bin(\s|_|[;]|$)/bist/igm;
        next if $item ne $old_item;
        $item =~ s/(^|\s|[;])bist(\s|_|[;]|$)/bin/igm;
        next if $item ne $old_item;

        foreach my $verb_pair ( get_verb_conjugation_table() ) {
            my $vone = $verb_pair->[0];
            my $vtwo = $verb_pair->[1];

            say "changing in " . $item . ": " . $vone . ' to ' . $vtwo;
            $item =~ s/(.*?)$vone(\s|_|[;]|$)/$1$vtwo$2/igm;
            next VERB if $item ne $old_item;

            say "changing in " . $item . ": " . $vtwo . ' to ' . $vone;
            $item =~ s/(.*?)$vtwo(\s|_|[;]|$)/$1$vone$2/igm;
            next VERB if $item ne $old_item;
        }

        next if lc $item eq 'ist';

        next if LANGUAGE() eq 'en';
        if ( $item =~ /st$/ ) {
            $item =~ s/sst$/ssst/igm;
            $item =~ s/st$/e/igm;
            $item =~ s/zt$/ze/igm;
            $item =~ s/ee$/e/igm;
            $item = 'ist' if lc $item eq 'ie';
        }
        elsif ( $item =~ /e$/ ) {
            $item =~ s/(n|l|m|r|p|b|k|t)te$/$1tee/igm;
            $item =~ s/e$/st/igm;
            $item =~ s/zst$/zt/igm;
            $item =~ s/tst$/test/igm;
        }
        $item =~ s/sss/ss/igm;
    }

    my @tmp = map { $_ !~ /nothing/ } @{ $subclause_ref->{'verbs'} };
    my $there_is_a_verb = @tmp;

    foreach my $item ( @{ $subclause_ref->{'subjects'} },
        @{ $subclause_ref->{'objects'} }, )
    {
        next if !$there_is_a_verb;
        print '$subclauses_array_ref: ', Dumper $subclauses_array_ref;
        print 'Dumper [ grep { $is_if_.... : ',
          Dumper [ grep { $data->{lang}{is_if_word}{ lc $_->{'questionword'} } }
              @$subclauses_array_ref ];
        next
          if
          scalar( grep { $data->{lang}{is_if_word}{ lc $_->{'questionword'} } }
              @$subclauses_array_ref );

        say '$item: ', $item;
        say $item =~ /(^|\s)(er|ihm|ihn)(\s|$)/i
          || lc $item eq 'er'
          || lc $item eq 'ihm'
          || lc $item eq 'ihn';

        if (   $item =~ /(^|\s)(er|ihm|ihn)(\s|$)/i
            || lc $item eq 'er'
            || lc $item eq 'ihm'
            || lc $item eq 'ihn' )
        {
            my $last_word = $config{'history'}{'last_m'};
            $last_word =~ s/^d.?.?[_\s]//igm;
            $last_word =~ s/[_\s]+/ /igm;
            $last_word =~ s/\s$//igm;
            if ($last_word) {
                $item =~ s/(^|\s|[;])(er|ihm|ihn)(\s|$)/ $last_word /igm;
            }
        }
        elsif ($item =~ /(^|\s)(sie|ihr)(\s|$)/i
            || lc $item eq 'sie'
            || lc $item eq 'ihr' )
        {
            my $last_word = $config{'history'}{'last_f'};
            $last_word =~ s/^d.?.?[_\s]//igm;
            $last_word =~ s/[_\s]+/ /igm;
            $last_word =~ s/\s$//igm;
            if ($last_word) {
                $item =~ s/(^|\s|[;])(sie|ihr)(\s|$)/ $last_word /igm;
            }
        }
        else {
            $item =~ s/(^\s+)|(\s+$)//gm;
            $item =~ s/  / /gm;

            my $g = pos_prop( $CLIENT_ref, $item )->{'genus'};

            $config{'history'}{ 'last_' . $g } = $item;
        }
        $item =~ s/(^\s+)|(\s+$)//gm;
    }

    foreach my $item (
        @{ $subclause_ref->{'subjects'} },
        @{ $subclause_ref->{'objects'} },
        @{ $subclause_ref->{'advs'} }
      )
    {
        $item =~ s/(^\s+)|(\s+$)//gm;
        $item =~ s/  / /gm;
    }

    return $subclause_ref;
}

sub weather_check {
    my ( $CLIENT_ref, $sentence_ref ) = @_;

    my $city = join ' ', @{ $sentence_ref->{'advs'} };
    if ( $city !~ /.*?in\s([a-zA-Z]).*?/ ) {
        say 'no city in string: ' . $city;
    }
    $city =~ s/.*?in\s([a-zA-Z]).*?/$1/igm;
    my @words = split / /, $city;

    if (   !$city
        || ( $city eq join ' ', @{ $sentence_ref->{'advs'} } )
        || @words >= 2 )
    {
        return;
    }

    my $CLIENT = $$CLIENT_ref;
    print $CLIENT
"SPEAK:Bitte warte einen Moment. Ich suche jetzt nach dem Wetter im Internet.\n";

    return if $city =~ /^dem /;
    my $dump = Dumper $sentence_ref;
    return
      if $dump !~ /(wetter|feuchtigkeit|warm|kalt|temp|weather|humidity|cold)/i;

    say '>> city: ' . $city;

    $| = 1;
    $city =~ s/\s/%20/igm;

    foreach my $x ( 0 .. 30 ) {
        say $x;

        my $sock = new IO::Socket::INET(
            PeerHost => 'www.accuweather.com',
            PeerPort => '80',
            Proto    => 'tcp',
        );
        if ( !$sock ) {
            say 'Error opening connection to accuweather.com';
            next;
        }

        if ( length( $x . '' ) == 1 ) {
            $x = '0' . $x;
        }

        my $url =
"http://www.accuweather.com/world-index-forecast.asp?partner=forecastfox&locCode=EUR|DE|GM0"
          . $x . "|"
          . ( uc $city ) . "|&u=1";

        #		say $url;
        print $sock "GET " . $url . " HTTP/1.0\n";
        print $sock "Host: www.accuweather.com\n";
        print $sock
"User-Agent: Mozilla/5.0 (X11; U; Linux i686; de; rv:1.8.1.10) Gecko/20071213 Fedora/2.0.0.10-3.fc8 Firefox/2.0.0.10\n";
        print $sock "\n";

        my @lines = <$sock>;

        #		print join '', @lines;
        foreach my $line (@lines) {
            chomp $line;
        }

        my $title = '';
        foreach my $line (@lines) {
            if ( $line =~ /cityTitle/ ) {
                $line =~ s/.*?<.*?><.*?>(.*?)<.*?><.*?>.*?/$1/igm;
                $line =~ s/^\s+//gm;
                $line =~ s/\s+$//gm;
                $title = $line;
            }
        }

        my $weather = '';
        foreach my $line (@lines) {
            if ( $line =~ /quicklook_current_wxtext/ ) {
                $line =~
                  s/[<]div\sid[=]["]quicklook_current_wxtext["][>]/$1/igm;
                $line =~ s/[<][\/]div[>]//igm;
                $line =~ s/^\s+//gm;
                $line =~ s/\s+$//gm;
                $weather = $line;
            }
        }

        my $temperature = '';
        foreach my $line (@lines) {
            if ( $line =~ /quicklook_current_temps/ ) {
                $line =~ s/[<]div\sid[=]["]quicklook_current_temps["][>]/$1/igm;
                $line =~ s/[<][\/]div[>]//igm;
                $line =~ s/[&]deg[;]C/Grad_Celsius/igm;
                $line =~ s/^\s+//gm;
                $line =~ s/\s+$//gm;
                $line =~ s/(\d+)/$1 /gm;
                $line =~ s/\s+/ /gm;
                $temperature = $line;
            }
        }

        my $humidity = '';
        foreach my $line (@lines) {
            if ( $line =~ /Humidity/ ) {
                $line =~ s/Humidity:/$1/igm;
                $line =~ s/[<]br\s*[\/][>]//igm;
                $line =~ s/^\s+//gm;
                $line =~ s/\s+$//gm;
                $humidity = $line;
            }
        }

        print Dumper [ $title, $weather, $temperature, $humidity ];

        select undef, undef, undef, 0.3;

        if ( !$title ) {
            next;
        }

# fact statement in prolog:
#
# fact(verb, subj, obj, advs, questionword, descr, verb_2, subj_2, obj_2, advs_2)

        #@$fact_database = grep {
        #    $_->[0] !~ /wetter|weather|temperatur|humidity|luftfeuchtigkeit/
        #      && $_->[5] ne 'weather'
        #} @$fact_database;

        my @new_facts = (

            [ 'ist', "the weather", $weather, 'in ' . lc $city, [], 'weather' ],
            [ 'is',  "it",          $weather, 'in ' . lc $city, [], 'weather' ],
            [
                'ist',                  "the temperature",
                $temperature . ' warm', 'in ' . lc $city,
                [],                     'weather'
            ],
            [
                'is', "the humidity", $humidity, 'in ' . lc $city, [], 'weather'
            ],

            [ 'ist', "das wetter", $weather, 'in ' . lc $city, [], 'weather' ],
            [ 'ist', "es",         $weather, 'in ' . lc $city, [], 'weather' ],
            [
                'ist', "es",
                $temperature . ' warm',
                'in ' . lc $city,
                [], 'weather'
            ],
            [
                'ist', "es",
                $temperature . ' kalt',
                'in ' . lc $city,
                [], 'weather'
            ],
            [
                'ist',                  "die temperatur",
                $temperature . ' warm', 'in ' . lc $city,
                [],                     'weather'
            ],
            [
                'ist',     "die luftfeuchtigkeit",
                $humidity, 'in ' . lc $city,
                [],        'weather'
            ],

        );

        print Dumper \@new_facts;

        semantic_network_connect(
            dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
            config => \%config
        );

        #push @$fact_database, @new_facts;
        foreach my $fact (@new_facts) {
            semantic_network_put(
                fact               => $fact,
                optional_hook_args => [$CLIENT_ref]
            );

        }
        semantic_network_commit();

        semantic_network_clean_cache();

        #parse_synonyms( $CLIENT_ref, 0, \@new_facts );

        #add_automatically( \@new_facts );

        #foreach my $fact_ref (@new_facts) {
        #$fact_database_by_verb{ $fact_ref->[0] } = []
        #if !( $fact_database_by_verb{ $fact_ref->[0] } );
        #push @{ $fact_database_by_verb{ $fact_ref->[0] } }, $fact_ref;
        #$fact_database_by_verb{ $fact_ref->[6] } = []
        #if !( $fact_database_by_verb{ $fact_ref->[6] } );
        #push @{ $fact_database_by_verb{ $fact_ref->[6] } }, $fact_ref;
        #}

        open my $prolog_database_file, ">>",
          $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/facts.pro";
        foreach my $fact_orig (@new_facts) {
            my $fact = [@$fact_orig];

            print Dumper $fact;

            my $code = join ' <> ',
              (
                ( shift @$fact ),
                ( shift @$fact ),
                ( shift @$fact ),
                ( shift @$fact ),
                '', '',
              );
            my $prio = pop @$fact;
            $code .= join ' ;; ',
              ( map { join ' <> ', @$_ } @{ $fact->[0] || [] } );
            $code .= ' <> ' . $prio;
            print $prolog_database_file $code, "\n";
        }
        close $prolog_database_file;

        last;
    }
}

sub get_index_of_combination {
    my ( $words_in_question_ref, $sentence_str,
        $config_index_of_combination_ref )
      = @_;
    my %config_index_of_combination = %$config_index_of_combination_ref;

    if (  !-f $data->{intern}{dir} 
        . "/lang_"
        . LANGUAGE()
        . '/index_of_combination.cfg' )
    {
        open my $file, ">",
            $data->{intern}{dir} 
          . "/lang_"
          . LANGUAGE()
          . '/index_of_combination.cfg';
        close $file;
    }

    my $answer_mixstring = join '',
      (
        grep  { $_ }
          map { lc $_ }
          map { split /([:)(;,.\-+?!><]|\s)+/, $_ } $sentence_str
      );
    say $answer_mixstring if $answer_mixstring =~ /ki/i;

    my @already_configured = (0);
    my $n_all              = scalar @$words_in_question_ref;
    foreach my $word_in_question (@$words_in_question_ref) {
        if ( defined $config_index_of_combination{$word_in_question} ) {
            if (
                defined $config_index_of_combination{$word_in_question}
                {$answer_mixstring} )
            {
                push @already_configured,
                  $config_index_of_combination{$word_in_question}
                  {$answer_mixstring};
            }
        }
    }

    my $n_is_ok = 1;
    foreach my $j (@already_configured) {
        $n_is_ok += $j;
    }
    my $index = 10 * ( $n_is_ok / scalar @already_configured );

    #say $index;
    return $index;
}

sub add_index_of_combination {
    my ( $type, $question, $answer ) = @_;
    clean_index_of_combination_file();
    read_config $data->{intern}{dir} 
      . "/lang_"
      . LANGUAGE()
      . '/index_of_combination.cfg' => my %config_index_of_combination;

    #    $config{'index_of_combination'}{'last_question'} = $sentence_str;
    #    $config{'index_of_combination'}{'last_answer'} = $answer;

    my $answer_mixstring = join '',
      (
        grep  { $_ }
          map { lc $_ }
          map { split /([;:)(,.\-+?!><]|\s)+/, $_ }
          ( $answer || $config{'index_of_combination'}{'last_answer'} )
      );
    my $words_in_question_ref = [
        grep  { $_ }
          map { lc $_ }
          map { split /([;:)(,.\-+?!><]|\s)+/, $_ }
          ( $question || $config{'index_of_combination'}{'last_question'} )
    ];

    my @already_configured = (0);
    my $n_all              = scalar @$words_in_question_ref;
    foreach my $word_in_question (@$words_in_question_ref) {
        $config_index_of_combination{$word_in_question}{$answer_mixstring} +=
            $type eq '++++' ? 5000
          : $type eq '+++'  ? 500
          : $type eq '++'   ? 50
          : $type eq '+'    ? 5
          :                   -5;
        say '$config_index_of_combination{', $word_in_question, '}{',
          $answer_mixstring, '} = '
          . $config_index_of_combination{$word_in_question}{$answer_mixstring};
    }

    delete $config_index_of_combination{''};
    delete $config_index_of_combination{' '};
    delete $config_index_of_combination{'?'};
    delete $config_index_of_combination{'_'};

    write_config %config_index_of_combination,
        $data->{intern}{dir} 
      . "/lang_"
      . LANGUAGE()
      . '/index_of_combination.cfg';
}

sub clean_index_of_combination_file {
    open my $file, "<",
        $data->{intern}{dir} 
      . "/lang_"
      . LANGUAGE()
      . '/index_of_combination.cfg';
    my @lines = <$file>;
    map { s/\r//igm; } @lines;
    close $file;
    open $file, ">",
        $data->{intern}{dir} 
      . "/lang_"
      . LANGUAGE()
      . '/index_of_combination.cfg';
    print $file grep { !/[>=<][>=<][>=<]/ } @lines;
    close $file;
}

sub answer_sentence {
    my $CLIENT_ref             = shift;
    my @subclauses             = @{ $_[0] };
    my ${is_a_question}        = $_[1];
    my $sentence_str           = $_[2];
    my $no_person_modification = $_[3] || 0;

    if ( !$no_person_modification ) {
        for my $subclause_ref (@subclauses) {
            $subclause_ref =
              person_modification( $CLIENT_ref, $subclause_ref, \@subclauses );
        }
    }

    my $sentence_ref = shift @subclauses;
    if ( not @subclauses ) {
        push @subclauses,
          {
            'verbs'        => [''],
            'subjects'     => [ [ 'nothing', '' ] ],
            'objects'      => [ [ 'nothing', '' ] ],
            'questionword' => '',
            'description'  => '',
            'advs'         => [],
          };
    }

    my @answers;
    if ( $sentence_str eq '+' || $sentence_str eq '-' || $sentence_str eq '++' )
    {
        add_index_of_combination($sentence_str);
        push @answers, 'accepted.';
    }
    elsif ( $data->{lang}{is_a_question} || $sentence_ref->{'questionword'} ) {
        weather_check( $CLIENT_ref, $sentence_ref );

        if ( $sentence_ref->{'questionword'} ) {
            my @answers_here =
              answer_sentence_questionword( $CLIENT_ref, $sentence_ref,
                \@subclauses, $sentence_str );
            push @answers, @answers_here;
        }
        else {
            my @answers_here =
              answer_sentence_yes_no( $CLIENT_ref, $sentence_ref, \@subclauses,
                $sentence_str, 1 );
            push @answers, @answers_here;
        }
    }
    else {
        my @answers_here =
          answer_sentence_statement( $CLIENT_ref, $sentence_ref, \@subclauses );
        push @answers, @answers_here;
    }

    my @shuffled = @answers;
    my @words_in_question = grep { $_ }
      map { lc $_ }
      map { split /([;:)(,.\-+?!><]|\s)+/, $_ } $sentence_str;

    clean_index_of_combination_file();
    read_config $data->{intern}{dir} 
      . "/lang_"
      . LANGUAGE()
      . '/index_of_combination.cfg' => my %config_index_of_combination;

    my @sorted = map {
        [
            $_,
            get_index_of_combination(
                \@words_in_question, $_, \%config_index_of_combination
            )
        ]
    } @shuffled;

    # my $answer   = $shuffled[ int( rand(@shuffled) ) ];
    #@sorted = sort { $a->[1] <=> $b->[2] } @sorted;
    #say Dumper @sorted
    my $biggest     = 0;
    my %sorted_hash = ();
    foreach my $item (@sorted) {

        #say $item->[0], ' -> ', $item->[1];
        $sorted_hash{ $item->[0] } ||= 0;
        $sorted_hash{ $item->[0] } += $item->[1]
          if $item->[1]
              && $sorted_hash{ $item->[0] };
        $sorted_hash{ $item->[0] } = $item->[1]
          if $item->[1]
              && !$sorted_hash{ $item->[0] };

        $biggest = $item->[1]
          if $item->[1] > $biggest;
    }

    #say Dumper \%sorted_hash;
    @sorted = ();
    my $middle                  = 0;
    my $number_to_divide_middle = 0;
    foreach my $key ( keys %sorted_hash ) {
        push @sorted, [ $key, $sorted_hash{$key} ];
        if ( $sorted_hash{$key} < $biggest - 5 ) {
            $middle += $sorted_hash{$key};
            $number_to_divide_middle += 1;
        }
    }
    $number_to_divide_middle ||= 1;
    $middle /= $number_to_divide_middle;
    say 'middle: ', $middle;
    $middle ||= 1;
    $middle = -$middle if $middle < 0;
    $middle = 1        if $middle < 1;

    my @best  = ();
    my @worst = ();
    foreach my $item (@sorted) {
        next if !$item->[0];
        next if $item->[0] =~ /111111/;
        next if $item->[0] eq '1';
        $item->[1] /= sqrt($middle) || 1;

        #$item->[1] /= ( $biggest - $item->[1] + 1 );
        my $c = ( $item->[1]**2 ) / 500 || 1;
        $c = ( 5000 * $middle ) if $c > ( 5000 * $middle );
        $c = 1   if $c < 1         && $c > 0;
        $c = -$c if $item->[1] < 0 && $c > 0;

        #say "push ,  ($item->[0],)  $c             if $c > 0;";
        push @best, ( $item->[0], ) x $c if $c > 0;
        push @worst,
          ( $item->[0], ) x ( ( 100 / -$c ) >= 1 ? ( 100 / -$c ) : 2 )
          if $c < 0;
    }

    if (   $sentence_str eq $config{'last_sentence_from_user'}
        && $data->{intern}{in_cgi_mode} )
    {
        return LANGUAGE() eq 'de'
          ? "Bitte wiederhole nicht immer wieder denselben Satz!"
          : "Please do not write the same sentence again!";
    }
    $config{'last_sentence_from_user'} = $sentence_str;
    if (   $sentence_str =~ /(^|s)(du|dir|dich)(\s|$)/i
        && !$data->{lang}{is_a_question}
        && $data->{intern}{in_cgi_mode} )
    {
        return LANGUAGE() eq 'de'
          ? "In der Online-Demo darf ich wegen meinem Filter keine Fakten ueber mich selbst lernen."
          : "FreeHAL's online demo is not allowed to learn facts about FreeHAL's personality.";
    }

    $config{'nodouble'}{5} = $config{'nodouble'}{4} || '';
    $config{'nodouble'}{4} = $config{'nodouble'}{3} || '';
    $config{'nodouble'}{3} = $config{'nodouble'}{2} || '';
    $config{'nodouble'}{2} = $config{'nodouble'}{1} || '';
    $config{'nodouble'}{1} = $config{'nodouble'}{0} || '';
    my %said = map { lc $_ => 1 } grep { $_ } values %{ $config{'nodouble'} };
    say '%said:';
    print Dumper \%said if is_verbose;

    #    my %best_hash = map { $_ => 1 } @best;
    #    @best = keys %best_hash;
    @best = grep { !/^0+$/ } @best;
    my @best_nodouble = grep { !$said{ lc $_ } } @best;
    @best = @best_nodouble if scalar @best_nodouble;
    if ( !@best ) {
        @best = @worst;

        #        my %best_hash = map { $_ => 1 } @best;
        #        @best = keys %best_hash;
        @best_nodouble = grep { !$said{ lc $_ } } @best;
        @best = @best_nodouble if scalar @best_nodouble;
    }

    #    my %best_hash = map { $_ => 1 } @best;
    #    @best = keys %best_hash;
    say "best:";
    $config{'nodouble'}{0} = $best[ rand(@best) ];
    my $answer = $config{'nodouble'}{0};

    my %best_hash = ();
    foreach my $best (@best) {
        $best_hash{$best} = 1;
    }
    say Dumper \( keys %best_hash );

    $config{'index_of_combination'}{'last_question'} = $sentence_str;
    $config{'index_of_combination'}{'last_answer'}   = $answer;
    delete $config{''};
    delete $config{'synonyms'}{''};
    $config{'synonyms'}{'satellit'} = undef;
    foreach my $value ( values %{ $config{'synonyms'} } ) {
        $value = '' if !$value;
    }
    write_config %config, $data->{intern}{config_file};

    # join the main clause and the sub clauses into one array ref
    return ( ucfirst $answer, [ $sentence_ref, @subclauses ] );
}

sub tan {
    return sin( $_[0] ) / cos( $_[0] );
}

sub cot {
    return cos( $_[0] ) / sin( $_[0] );
}

sub simple_answer {
    my $CLIENT_ref  = shift;
    my ($_question) = @_;
    my $question    = $_question . '';

    my $math = $question;
    $math =~ s/[=?!.]//igm;
    $math =~ s/hoch/**/igm;
    $math =~ s/\^/**/igm;
    $math =~ s/wie//igm;
    $math =~ s/viel//igm;
    $math =~ s/was//igm;
    $math =~ s/ergebnis//igm;
    $math =~ s/von//igm;
    $math =~ s/ist//igm;
    $math =~ s/sind//igm;
    $math =~ s/what//igm;
    $math =~ s/is//igm;
    $math =~ s/does//igm;
    $math =~ s/makes//igm;
    $math =~ s/ergibt//igm;
    $math =~ s/gibt//igm;
    $math =~ s/aus/ /igm;
    $math =~ s/sich/ /igm;
    $math =~ s/der|die|das/ /igm;
    $math =~ s/ plus /+/igm;
    $math =~ s/ half of (\d+)/ ( $1 \/ 2 )/igm;
    $math =~ s/ minus /-/igm;
    $math =~ s/ geteilt durch /\//igm;
    $math =~ s/ dividiert durch /\//igm;
    $math =~ s/ durch /\//igm;
    $math =~ s/ mal /*/igm;
    $math =~ s/x/*/igm;
    $math =~ s/\s+//igm;
    $math =~ s/wurzel/sqrt /igm;
    $math =~ s/[,]/./igm;
    my $value = undef;

    if ( $math =~ /^([\d+\-*.\/\s)(]|(sqrt)|(sin)|(cos)|(tan)|(cot))+$/ ) {
        $math =~ s/(sin|cos|tan|cot)([\d]+)/$1($2)/igm;
        return if length $math == 1;
        eval '$value = ' . $math . ';';
        if ($@) {
            say "\n\n\n";
            say "Error while using eval to compute: " . $@;
            say "\n\n\n";
            return LANGUAGE() eq 'de'
              ? 'Undefiniert: ' . ( join ' ', ($@) )
              : 'Undefined: ' . ( join ' ', ($@) );
        }
        elsif ($value) {
            if ( LANGUAGE() eq 'de' ) {
                $value = '' . $math . ' ergibt <i>' . $value . '</i>!';
            }
            if ( LANGUAGE() eq 'en' ) {
                $value = 'The answer is <i>' . $value . '</i> = ' . $math . '!';
            }
            return $value;
        }
    }
    else {
        say 'No math question: ', $math;
    }

    $question =~ s/([.?!])//igm;

    my @greetings = (
        "guten tag",      "guten morgen",
        "hi",             "hallo",
        "hey",            "huhu",
        "guten abend",    "guten nachmittag",
        "good morning",   "hello",
        "good afternoon", "good night",
        "moygn",          "morygn",
        "morgen",         "moin",
        "moynd",          "gute nacht",
        "gruess dich",
        "gruess",
    );

    foreach my $greeting (@greetings) {
        $question =~ s/jeliza//igm;
        $question =~ s/freehal//igm;
        $question =~ s/\s+/ /igm;
        if ( lc $question =~ /^\s*$greeting(\s|_|[,!?.]|$)/i ) {
            @greetings =
              map { ( ucfirst $_ . '!', ucfirst $_ . '.' ) } @greetings;

            my @localtime_array = localtime;
            my $hour            = $localtime_array[2];

            if ( LANGUAGE() eq 'de' ) {
                return "Wie..? Immer noch wach...?"
                  if $hour >= 0 && $hour < 5;
                return "Guten Morgen!" if $hour >= 5  && $hour < 12;
                return "Guten Tag!"    if $hour >= 12 && $hour < 17;
                return "Guten Abend!"
                  if $hour >= 17 && $hour < 24;
            }
            else {
                return "You should sleep..." if $hour >= 0  && $hour < 5;
                return "Good morning."       if $hour >= 5  && $hour < 12;
                return "Hello!"              if $hour >= 12 && $hour < 17;
                return "Good night!"         if $hour >= 17 && $hour < 24;
            }

        }
    }

    my @interjections =
      LANGUAGE() eq 'de'
      ? qw{ja nein doch juhu juhuu huhu noe wow cool ach egal tja schade achso stimmt klar gut haha hihi hihihi hahaha ha hoho oje mist hmm hm hmmm hmmmm ebenso }
      : qw{yes no right wow cool thank thanks goodbye thanks};

    if ( lc $question =~ /^ja(\s|[,;]|$)/i ) {
        return "Ja.";
    }
    if ( lc $question =~ /^nein(\s|[,;]|$)/i ) {
        return "Doch! ;)";
    }
    if ( lc $question =~ /^doch(\s|[,;]|$)/i ) {
        return "Okay. :)";
    }
    if ( lc $question =~ /^sicher(\s|[,;]|$)/i ) {
        return "Ja.";
    }
    if ( lc $question =~ /^okay(\s|[,;]|$)/i ) {
        return "Gut.";
    }
    if ( lc $question =~ /^ok(\s|[,;]|$)/i ) {
        return "Gut. :)";
    }
    if ( lc $question =~ /^bitte(\s|[,;]|$)/i ) {
        return "Schon gut... ;)";
    }
    if ( lc $question =~ /^schoen(\s|[,;]|$)/i ) {
        return "Schon gut... ;)";
    }
    if ( lc $question =~ /^sehr(\s|[,;]|$)/i ) {
        return "Schon gut... ;)";
    }
    if ( lc $question =~ /^danke(\s|[,;]|$)/i ) {
        return "Bitte! ;)";
    }
    if ( lc $question =~ /^entschuldig(ung|e)(\s|[,;]|$)/i ) {
        return "Schon gut.";
    }
    if ( lc $question =~ /^auf wiedersehen(\s|[,;]|$)/i ) {
        return "Bis bald!";
    }
    if (
        lc $question =~
        /^(richtig|stimmt|(das stimmt)|(das ist richtig))(\s|[,;]|$)/i )
    {
        my @answers = (
            q{Ich bin doch nicht so dumm, wie alle glauben.},
            q{Ich weiss doch mehr, als du dir gedacht hast.},
            q{Staunst du, weil ich so viel weiÃŸ?},
            q{Danke.},
            q{Ich bin eben eine KI.},
            q{Gut.},
        );

        srand(time);
        return $answers[ rand @answers ];
    }
    if ( lc $question =~ /^(h[m]+?)(\s|[,;]|$)/i && LANGUAGE() eq 'de' ) {
        my @answers = (
            "Was ist denn?",
            "An was denkst du gerade?",
            "Was macht dich nachdenklich?",
        );

        srand(time);
        return $answers[ rand @answers ];
    }

    my $first_word = ( split /\s|[,]/, $question )[0];
    my $first_word_is_interjection =
      pos_of( $CLIENT_ref, $first_word, 1, undef, undef, $question ) ==
      $data->{const}{INTER};
    foreach my $interj (@interjections) {
        if ( lc $question =~ /^\s*$interj(\s|_|[,;?!]|$)/i
            || $first_word_is_interjection )
        {
            say 'is interjections: ', $question;

            @interjections =
              map {
                (
                    ucfirst $_ . '!',
                    ucfirst $_ . '.',
                    ucfirst $_ . ' ;)',
                    ucfirst $_ . ' :)'
                  )
              } @interjections;

            push @interjections, new_things_wanted_to_know( $CLIENT_ref, );

            my @shuffled = shuffle(@interjections);
            my $answer   = $shuffled[ int( rand(@shuffled) ) ];
            return $answer;
        }
    }

    return;
}

sub gen_list {
    my ( $CLIENT_ref, $the_only_file_name ) = @_;
    my $CLIENT = $$CLIENT_ref;

    #my part_of_speech_get_memory()_backup = {};
    #if ( $data->{intern}{in_cgi_mode} ) {
    #part_of_speech_get_memory()_backup = {%{part_of_speech_get_memory()}};

#my $from_yaml_temp =
#pos_file_read( $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.brain' );

    #%{part_of_speech_get_memory()} = (%{part_of_speech_get_memory()},
    #(
    #defined $from_yaml_temp->[0]
    #? $from_yaml_temp->[0]
    #: {}
    #))
    #;
    #}

    mkdir $data->{intern}{dir} . '/knowledge';

    my $number = 0;

    foreach my $file ( get_database_files() ) {

        if ($the_only_file_name) {
            if ( $file =~ /$the_only_file_name/ ) {
                say 'File: ', $file, ' matches ', $the_only_file_name;
            }
            else {
                say 'File: ', $file, ' not matches ', $the_only_file_name;
                next;
            }
        }

        open my $h, '<', $file or say 'Error while opening: ', $file;
        my @facts = ();
        my $i     = 0;
        while ( defined( my $fact = <$h> ) ) {
            $fact = lc $fact;
            chomp $fact;
            $fact =~ s/\s+[<][>]\s+[<][>]\s+/ <> nothing <> /gm;
            $fact =~ s/[<][>]/ <> /gm;
            $fact =~ s/\s+/ /gm;
            $fact = [ split /[<][>]/, $fact ];
            foreach my $item (@$fact) {
                $item =~ s/^\s//igm;
                $item =~ s/\s$//igm;
            }

            my ( $verb, $subj, $obj, $advs ) =
              ( shift @$fact, shift @$fact, shift @$fact, shift @$fact );
            my $prio = pop @$fact;

            $fact = join '<>', @$fact;
            $fact = [ split /\s*[;][;]\s*/, $fact ];
            foreach my $clause (@$fact) {
                $clause = [ split /[<][>]/, $clause ];
                foreach my $item (@$clause) {
                    $item =~ s/nothing//igm;
                    $item =~ s/(^\s+)|(\s+$)//igm;
                    chomp $item;
                }
            }
            @$fact = grep { join '', @$_ } @$fact;

            $fact = [ $data->{const}{VERB}, $subj, $obj, $advs, $fact, $prio ];
            push @facts, $fact;
            $i += 1;
        }
        ( my $name_part = $file ) =~ s/.*?\///igm;
        ( my $name_part = $file ) =~ s/.*?\///igm;
        ( my $name_part = $file ) =~ s/.*?\///igm;

        open my $out_file, '>',
          $data->{intern}{dir} . '/knowledge/' . $name_part . '.txt'
          or die 'cannot open: '
          . $data->{intern}{dir}
          . '/knowledge/'
          . $name_part . '.txt';
        my @exps = ();
        foreach my $fact (@facts) {
            push @exps, phrase( $CLIENT_ref, @$fact );
            $number += 1;

            print "\r", $number, " facts...\r" if $number % 50 == 0;
        }
        foreach my $exp ( sort { $a cmp $b } @exps ) {
            print $out_file $exp, "\n";
        }
        close $out_file;
    }

#%{part_of_speech_get_memory()} = %{part_of_speech_get_memory()}_backup if $data->{intern}{in_cgi_mode};

    return ( $number . ' facts written.' );
}

sub better_question {
    my ( $sent, $be_quiet ) = @_;

    my $no_change_pronouns = 0;

    say "better sentence(1): ", $sent if !$be_quiet;

    $sent = ascii($sent);
    say "better sentence(2): ", $sent if !$be_quiet;

    $sent =~ s/[?][=][>]/ questionnext /igm;
    $sent =~ s/[!][=][>]/ factnext /igm;
    $sent =~ s/[=][>]/ questionnext /igm;
    $sent =~ s/[?]/ ?/igm;
    $sent =~ s/^und\s*[,]\s*//igm;
    $sent =~ s/(^|\s|[;])an\s/$1a /igm if LANGUAGE() eq 'en';
    $sent =~ s/\s*[,]\s*(und|oder|or|and)/ $1/igm;
    $sent =~ s/^na\s*[,]\s*//igm;
    $sent =~ s/^naja\s*[,]\s*//igm;
    $sent =~ s/^und[,]\s*//igm;
    $sent =~ s/^na[,]\s*//igm;
    $sent =~ s/^und\s+//igm if length($sent) < 8;
    $sent =~ s/^ok\s+//igm  if length($sent) < 8;
    $sent =~ s/^gut\s+//igm if length($sent) < 8;
    $sent =~ s/^nein\s+//igm;
    $sent =~ s/^ja\s+//igm  if length($sent) > 5;
    $sent =~ s/^oder\s+//igm;
    $sent =~ s/^na\s+/ /igm;
    $sent =~ s/^naja\s+/ /igm;
    $sent =~ s/^h[m]+?\s+/ /igm;
    $sent =~ s/^(wie|was)\s*?[,]\s*?/ /igm;
    $sent =~ s/\s\s/ /igm;
    $sent =~ s/^[,]/ /igm;
    $sent =~ s/\s\s/ /igm;
    $sent =~ s/\s+kein/ nicht ein/gm;
    $sent =~ s/(^|\s|[;])und sonst(\s|$)/ wie geht es dir /igm;
    $sent =~ s/(^|\s|[;])bevor\s/ , bevor /igm;
    $sent =~ s/(^|\s|[;])kurz , bevor\s/ , kurz bevor /igm;
    $sent =~ s/^ ,/ /igm;
    $sent =~ s/^,/ /igm;
    $sent =~ s/ mehr als / mehrals /igm;
    $sent =~ s/ lust zu / lust , zu /igm;
    $sent =~ s/ weisst du was (.*) ist / was ist $1 /igm;
    $sent =~ s/ weisst du / weisst du , /igm if length($sent) < 14;
    $sent =~ s/ weniger als / wenigerals /igm;
    $sent =~ s/ bis zu / biszu /igm;
    $sent =~ s/ bis in / bisin /igm;
    $sent =~ s/ bis auf / bisauf /igm;
    $sent =~ s/^bis zu / biszu /igm;
    $sent =~ s/^bis in / bisin /igm;
    $sent =~ s/^bis auf / bisauf /igm;
    $sent =~ s/^kein(.*)/ein$1 nicht/gm;
    $sent =~ s/wozu braucht man /was ist /gm;
    $sent =~ s/(brauch)(st|e|en)(.*?)zu\s(haben)/$1$2$3 $4/;
    $sent =~ s/\suhr\shaben\swir\s/ ist es /igm;
    $sent =~ s/\suhr\shaben\swir[?]/ ist es?/igm;
    $sent =~ s/aneinander /aneinander/igm;
    $sent =~ s/\shaben\swir\sheute/ haben wir /igm;
    $sent =~ s/welchen\stag\shaben\swir\s/wie ist Tag heute /igm;
    $sent =~ s/welchen\stag\shaben\swir[?]/wie ist Tag heute?/igm;
    $sent =~ s/ hab / habe /igm;

    $sent =~ s/(^|\s)da([r]?)(durch|auf|fuer|an|um) / $3 _das_ /igm;

    $sent =~ s/([0-9])([a-zA-Z])/$1 $2/igm;
    $sent =~ s/([a-zA-Z])([0-9])/$1 $2/igm;
    $sent =~ s/([0-9])\.([a-zA-Z])/$1 $2/igm;
    $sent =~ s/([a-zA-Z])\.([0-9])/$1 $2/igm;

    #    $sent =~ s/welchen\s(.+?)\shaben\swir/wie $1 ist /igm;
    #    $sent =~ s/welchen\s(.+?)\shaben\swir/wie $1 ist /igm;
    $sent =~ s/\smacht man mit\s/ ist /igm;

    #$sent =~ s/\skann man mit\s(.*?)\smachen/ ist $1/igm;
    $sent =~ s/^was\sgeht\s*[?]/wie geht es dir?/igm;
    $sent =~ s/^was\sgeht$/wie geht es dir?/igm;
    $sent =~ s/^was\sgeht\sab\s*[?]/wie geht es dir?/igm;
    $sent =~ s/^was\sgeht\sab$/wie geht es dir?/igm;
    $sent =~ s/Ihnen/dir/igm;
    $sent =~ s/\sdenn\s*?[?]/ ?/igm;
    $sent =~ s/\sdenn[?]/ ?/igm;
    $sent =~ s/\sdann\s*?[?]/ ?/igm;
    $sent =~ s/\sdann[?]/ ?/igm;
    $sent =~ s/St[.]/St/gm;
    $sent =~ s/bitte (sag|erzaehl)/$1/gm;
    $sent =~ s/Kannst du mir sagen[,]+//igm;
    $sent =~ s/Kannst du mir sagen//igm;
    $sent =~ s/nenne mir /was ist /igm;
    $sent =~ s/nenne /was ist /igm;
    $sent =~ s/sage mir /was ist /igm;
    $sent =~ s/sag was /was ist /igm;
    $sent =~ s/sag etwas /was ist /igm;
    $sent =~ s/sag /was ist /igm;
    $sent =~ s/ du heute / du /igm;
    $sent =~ s/(ich glaube) ([a-zA-Z])/$1 , $2/igm;
    $sent =~ s/(ich denke) ([a-zA-Z])/$1 , $2/igm;
    $sent =~ s/stelle mir eine frage/was ist /igm;
    $sent =~ s/stell mir eine frage/was ist /igm;
    $sent =~ s/stelle eine frage/was ist /igm;
    $sent =~ s/stell eine frage/was ist /igm;
    $sent =~ s/Was kannst du mir ueber (.*?) sagen/was ist $1/igm;
    $sent =~ s/Was weisst du ueber (.*?)$/was ist $1/igm;
    $sent =~ s/Was kannst du mir ueber (.*?) erzaehlen/was ist $1/igm;
    $sent =~ s/Was kannst du ueber (.*?) sagen/was ist $1/igm;
    $sent =~ s/Was weisst du alles/was ist/igm;
    $sent =~ s/^.*?Was weisst du.*?$/was ist ?/igm;
    $sent =~ s/^.*?Was du .*? weisst.*?$/was ist ?/igm;
    $sent =~ s/frag mich was/was ist/igm;
    $sent =~ s/frag mich etwas/was ist/igm;
    $sent =~ s/frag mich\s*?[,]//igm;
    $sent =~ s/was ist ([dsmk]?ein)([a-zA-Z]+?)\s/was ist $1 /igm;
    $sent =~ s/was denkst du ueber /was ist /igm;
    $sent =~ s/wie denkst du ueber /was ist /igm;
    $sent =~ s/was haeltst du von /was ist /igm;
    $sent =~ s/was haelst du von /was ist /igm;
    $sent =~ s/erzaehl mir was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehl mir etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle mir was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle mir etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehl mir bitte was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehl mir bitte etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle mir bitte was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle mir bitte etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzael mir was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzael mir etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaele mir was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaele mir etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehl was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehl etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaehle etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzael was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzael etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaele was(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/erzaele etwas(([\s!?.].*)|$)/was ist?/igm;
    $sent =~ s/Erzaehlst du .*/was ist?/igm;

    $sent =~ s/(was machst du).+?$/$1 ?/igm;
    $sent =~ s/sag mir //igm;
    $sent =~ s/sag mir[,]//igm;
    $sent =~ s/^\s*?ob\s//igm;
    $sent =~ s/can you remmember that //igm;
    $sent =~ s/do you know whether //igm;
    $sent =~ s/you know whether //igm;
    $sent =~ s/^woher /wo /igm;
    $sent =~ s/(^|\s)was fuer eine\s/ welche /igm;
    $sent =~ s/(^|\s)was fuer einen\s/ welchen /igm;
    $sent =~ s/(^|\s)was fuer einem\s/ welchem /igm;
    $sent =~ s/(^|\s)was fuer ein\s/ welches /igm;
    $sent =~ s/(^|\s)was fuer\s/ welch /igm;
    $sent =~ s/was (.+?) fuer eine\s(.+)/welche $2 $1/igm;
    $sent =~ s/was (.+?) fuer einen\s(.+)/welchen $2 $1/igm;
    $sent =~ s/was (.+?) fuer einem\s(.+)/welchem $2 $1/igm;
    $sent =~ s/was (.+?) fuer ein\s(.+)/welches $2 $1/igm;
    $sent =~ s/was (.+?) fuer\s(.+)/welch $2 $1/igm;
    $sent =~ s/can you tell me whether\s//igm;
    $sent =~ s/can you tell me (who|how|where|when|if|what)/$1 /igm;
    $sent =~ s/can you tell me\s/what is /igm;
    $sent =~ s/gemacht\s+?[?]/ ?/igm;

    $sent =~ s/\sbei dir\s/ in Frankfurt /igm;
    $sent =~ s/(^|\s|[;])wie wird /$1 wie ist /igm;
    $sent =~ s/^bei dir\s/ in Frankfurt /igm;
    $sent =~ s/Wie ist das Wetter heute/Wie ist das Wetter in Frankfurt /igm;
    $sent =~ s/dir heute/dir /;
    $sent =~ s/ ja / / if length($sent) > 10;

    $sent =~ s/es ist\s*?$/ist es /igm;
    $sent =~ s/es ist\s*?[?]\s*?$/ist es ?/igm;

    say "better sentence(3): ", $sent if !$be_quiet;

    $sent =~ s/Weisst du etwas ueber /was ist /igm;
    $sent =~ s/was weisst du ueber /was ist /igm;
    $sent =~ s/don['`']t/do not/igm;
    $sent =~ s/hasn['`']t/has not/igm;
    $sent =~ s/havn['`']t/have not/igm;
    $sent =~ s/didn['`']t/did not/igm;
    $sent =~ s/mustn['`']t/must not/igm;
    $sent =~ s/n['`']t/ not/igm;
    $sent =~ s/gehts/geht es/igm;
    $sent =~ s/geht's/geht es/igm;
    $sent =~ s/gehtÂ´s/geht es/igm;
    $sent =~ s/gibt es /was ist /igm;
    $sent =~ s/gibt es/was ist/igm;
    $sent =~ s/was ist neues/was gibt es neues/igm;
    $sent .= ' ';
    $sent =~ s/geht es so[?\s]/geht es$1/igm;
    $sent =~ s/wie geht es [?]/wie geht es dir ?/igm;
    $sent =~ s/wie geht es\s*$/wie geht es dir ?/igm;

    say "better sentence(4): ", $sent if !$be_quiet;

    foreach ( 1 .. 20 ) {
        $sent =~
s/([a-zA-Z0-9_]+)\s*[,]\s*([a-zA-Z0-9_]+)\s+(und|oder|or|and)\s*/$1 $3 $2 $3 /igm;
        $sent =~
s/\s*[,]\s*([a-zA-Z0-9_]+\s+[a-zA-Z0-9_]+)\s+(und|oder|or|and)\s*/ $2 $1 $2 /igm;
    }

    $sent =~ s/wie heisst\sdu/wer bist du/igm;
    $sent =~ s/wie heisse\s/wer bin /igm;

    $sent =~ s/Welche\s+Farbe\s+hat\s+/welche Farbe ist /igm;

    #    $sent =~ s/http[:_]\/\//http___/igm;
    $sent =~ s/http[:]+/http_/igm;
    for my $dummy ( 0 .. 20 ) {
        $sent =~ s/http(.*?)\//http$1_/igm;
    }

#    $sent =~ s/http___([^\s^\/]+)(\/*[^\s^\/]*)(\/*[^\s^\/]*)(\/*[^\s^\/]*)(\/*[^\s^\/]*)(\/*[^\s^\/]*)/http___$1$2$3$4$5$6/igm;

    $sent =~ s/wie viel uhr/wie uhr/igm;
    $sent =~ s/wie viel[a-zA-Z]*\s/wie /igm;
    $sent =~ s/wieviel[a-zA-Z]*\s/wie /igm;
    $sent =~ s/wie spaet/wie uhr/igm;
    say $sent if !$be_quiet;
    $sent =~ s/wie frueh/wie uhr/igm;
    $sent =~ s/[=]/ = /igm;
    $sent =~ s/wofuer steht /was ist /igm;
    $sent =~ s/hast du schon mal von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du schon von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du mal von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du schon mal was von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du schon was von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du was von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/hast du was mal von (.*?) gehoert/was ist $1/igm;
    $sent =~ s/^weisst du\s*[,]*\s*//igm
      if $sent !~ /(question|fact)next/ && length($sent) > 24;
    $sent =~ s/^weisst du//igm
      if $sent !~ /(question|fact)next/ && length($sent) > 24;
    $sent = ' ' . $sent . ' ';
    $sent =~ s/\snoch([\s!.;,?]+)/$1/igm;
    $sent =~ s/\setwa([\s!.;,?]+)/$1/igm;
    $sent =~ s/\sungefaehr([\s!.;,?]+)/$1/igm;
    $sent =~ s/\sdenn([\s!.;,?]+)/$1/igm;
    $sent =~ s/\sgerne([\s!.;,?]+)/$1/igm if $sent =~ /[?]/;
    $sent =~
s/\s(kein|keine|keinen|keiner|keinem|nicht)\skein(|e|en|er|em)\s/ kein$2 /igm;
    $sent =~ s/\s(kein|keine|keinen|keiner|keinem|nicht)\snicht\s/ $1 /igm;
    $sent =~ s/(^|\s|[;])k(ein|eine|einen|einer|einem)\s/$1nicht $2 /igm;
    $sent =~ s/\sim\s/ in dem /igm;
    $sent =~ s/\sbeim\s/ bei dem /igm;
    say $sent if !$be_quiet;
    $sent =~ s/\sam\s/ an dem /igm  if LANGUAGE() eq 'de';
    $sent =~ s/\sins\s/ in das /igm if LANGUAGE() eq 'de';
    $sent =~ s/^im\s/ in dem /igm;
    $sent =~ s/^am\s/ an dem /igm   if LANGUAGE() eq 'de';
    $sent =~ s/^ins\s/ in das /igm  if LANGUAGE() eq 'de';

    #    $sent =~ s/\szum\s+([a-zA-Z_]+)\s+?([^,.?!]+?\s+?)/ $2 , zum \l$1 /igm;
    #    $sent =~ s/\szum\s+([a-zA-Z_]+)/ , zum \l$1 , /igm;
    #    $sent =~ s/^zum\s+([a-zA-Z_]+)/ zum \l$1 , /igm;
    if ( $sent =~ /\szu[mr]\s+([a-zA-Z_]+)\s+([a-zA-Z_]+)(\s*?[,.?!]*?\s*?)$/ )
    {
        if ( $2 !~ /t$/ ) {

            $sent =~
s/\szu([mt])\s+([a-zA-Z_]+)\s+([a-zA-Z_]+)(\s*?[,.?!]*?\s*?)$/ zu$1_\l$2_\l$3 $4/igm;
        }
    }
    $sent =~
      s/\szu([mr])\s+([a-zA-Z_]+)\s+([A-Z_][a-zA-Z_]+)/ zu$1_\l$2_\l$3 /igm;
    $sent =~ s/\szu([mr])\s+([a-zA-Z_]+)/ zu$1_\l$2 /igm;
    $sent =~ s/^zu([mr])\s+([a-zA-Z_]+)/ zu$1_\l$2 /igm;
    $sent =~ s/[,]\s+[,]/,/igm;
    $sent =~ s/^wozu\s/wie /igm;
    $sent =~ s/\swozu\s/ wie /igm;

    $sent =~ s/^\s+//igm;
    $sent =~ s/^[,]//igm;
    $sent =~ s/^\s+//igm;

    foreach my $key_b ( keys %{ $data->{persistent}{replace_strings} } ) {
        my $key = $key_b;
        $key =~ s/^_//igm;
        $key =~ s/_$//igm;
        $key =~ s/_/ /igm;
        $key =~ s/\s+/[_\\s]+/igm;
        my $value = $data->{persistent}{replace_strings}{$key_b};
        $value =~ s/^_//igm;
        $value =~ s/_$//igm;
        $value =~ s/_/ /igm;

        #        say $key;
        #        say $value;
        #        say;
        $sent =~ s/$key([_\s]|$)/$value$1/igm;
    }

    %{ $data->{lang}{is_smily} } = map { $_ => 1 } qw{_) ;) :) _( :( ) ( :};

    foreach my $smily_backup ( keys %{ $data->{lang}{is_smily} } ) {
        my $smily = $smily_backup;
        $smily =~ s/([)(])/\\$1/igm;
        $sent  =~ s/$smily/ /igm;
    }

    $sent =~ s/(warum|weshalb|wieso) nicht/$1/igm;
    if ( $sent =~ /warum|weshalb|wieso/i ) {
        if ( $config{'nodouble'}{0} ) {
            $sent                  =~ s/\.\s+$//igm;
            $sent                  =~ s/\.$//igm;
            $config{'nodouble'}{0} =~ s/\.\s+$//igm;
            $config{'nodouble'}{0} =~ s/\.$//igm;
            my @clean_phrase =
              grep { $_ }
              grep { !$data->{lang}{is_smily}{$_} } ( split /\s+/, $sent );
            say 'clean_phrase:' if !$be_quiet;
            say Dumper \@clean_phrase if !$be_quiet;
            if ( scalar @clean_phrase <= 2 ) {
                my $temp = $config{'nodouble'}{0};
                $temp =~ s/Nein[,]?\s+?//igm;
                $temp =~ s/das ist klar//igm;
                $temp =~ s/^\s+//igm;
                $temp =~ s/^[,]+?//igm;
                $temp =~ s/^\s+//igm;
                foreach my $smily_backup ( keys %{ $data->{lang}{is_smily} } ) {
                    my $smily = $smily_backup;
                    $smily =~ s/([)(])/\\$1/igm;
                    $temp  =~ s/$smily/ /igm;
                }
                $sent               = "warum " . $temp . "?";
                $no_change_pronouns = 1;
            }
            $sent =~ s/\.\s+$//igm;
            $sent =~ s/\.$//igm;
        }
    }
    if ( $sent =~ /^weil\s+?/i && $sent !~ /[,]/ ) {
        if ( $data->{persistent}{last_user_sentences}{1} ) {
            $sent                                       =~ s/\.\s+$//igm;
            $sent                                       =~ s/\.$//igm;
            $data->{persistent}{last_user_sentences}{1} =~ s/\.\s+$//igm;
            $data->{persistent}{last_user_sentences}{1} =~ s/\.$//igm;
            $data->{persistent}{last_user_sentences}{1} =~ s/[!?]\s+$//igm;
            $data->{persistent}{last_user_sentences}{1} =~ s/[!?]$//igm;
            my @clean_phrase =
              grep { $_ }
              grep { !$data->{lang}{is_smily}{$_} } ( split /\s+/, $sent );
            say 'clean_phrase:' if !$be_quiet;
            say Dumper \@clean_phrase if !$be_quiet;

            if ( scalar @clean_phrase >= 2 ) {
                my $temp = $data->{persistent}{last_user_sentences}{1};
                $temp =~ s/Nein[,]?\s+?//igm;
                $temp =~ s/das ist klar//igm;
                $temp =~ s/^\s+//igm;
                $temp =~ s/^[,]+?//igm;
                $temp =~ s/^\s+//igm;
                foreach my $smily_backup ( keys %{ $data->{lang}{is_smily} } ) {
                    my $smily = $smily_backup;
                    $smily =~ s/([)(])/\\$1/igm;
                    $temp  =~ s/$smily/ /igm;
                }
                $sent = $temp . ', ' . $sent;
            }
            $sent =~ s/\.\s+$//igm;
            $sent =~ s/\.$//igm;
        }
    }

    foreach my $smily_backup ( keys %{ $data->{lang}{is_smily} } ) {
        my $smily = $smily_backup;
        $smily =~ s/([)(])/\\$1/igm;
        say $smily if !$be_quiet;
        $sent =~ s/$smily/ /igm;
    }

    $sent =~ s/kind of /kind_of_/igm;
    $sent =~ s/ mal n / einen /igm;
    $sent =~ s/ mal nen / einen /igm;
    $sent =~ s/ n / einen /igm;
    $sent =~ s/ nen / einen /igm;
    $sent =~ s/ mal [']n / einen /igm;
    $sent =~ s/ mal [']nen / einen /igm;
    $sent =~ s/ [']n / einen /igm;
    $sent =~ s/ [']nen / einen /igm;
    $sent =~ s/ mal [`]n / einen /igm;
    $sent =~ s/ mal [`]nen / einen /igm;
    $sent =~ s/ [`]n / einen /igm;
    $sent =~ s/ [`]nen / einen /igm;

    say "better sentence(5): ", $sent if !$be_quiet;

    if ( $sent =~ /[?]/ ) {
        $sent =~ s/(^|\s|[;])(nicht|not)(\s)/$1/igm;
    }

    $sent =~ s/sth[.]/something/igm;
    $sent =~ s/sth\s/something /igm;
    $sent =~ s/do you know (what|who|where|how|when|which|whose)/$1/igm;
    $sent =~ s/do you know something about /what is /igm;
    $sent =~ s/ do you do/ are you/igm;
    $sent =~ s/^\s+//igm;
    $sent =~ s/\s+$//igm;
    $sent =~ s/what\s*up\s($|[?])/how are you?/igm;
    $sent =~ s/what[']s\s*up\s($|[?])/how are you?/igm;
    $sent =~ s/whats\s*up\s($|[?])/how are you?/igm;
    $sent =~ s/how are you doing/how are you/igm;

    $sent =~ s/what's /what is /igm;
    $sent =~ s/whats /what is /igm;
    $sent =~ s/whos /what is /igm;
    $sent =~ s/who's /what is /igm;
    $sent =~ s/whore /what is /igm;
    $sent =~ s/who're /what is /igm;
    $sent =~ s/what is your name/who are you/igm;

    $sent =~ s/was ist mit (.*?) los/was ist $1/igm;
    $sent =~ s/was ist ueber (.*?)/was ist $1/igm;
    $sent =~ s/was ist los mit (.*?)/was ist $1/igm;

    $sent =~ s/wie vie[a-zA-Z]+\s/wie /igm;
    $sent =~ s/^hm, / /igm;
    $sent =~ s/^hm , / /igm;
    $sent =~ s/\shm, / /igm;
    $sent =~ s/\shm , / /igm;

    $sent =~ s/in dem (jahr [\d]+)/in dem "$1"/igm;
    $sent =~ s/in dem (jahre [\d]+)/in dem "$1"/igm;

    $sent =~ s/^\s+//igm;
    $sent =~ s/\s+$//igm;
    $sent =~ s/questionnext/q=>/igm;
    $sent =~ s/factnext/f=>/igm;
    $sent =~ s/[?]\s*[=]\s*[>]/?=>/igm;
    $sent =~ s/\s+[?][=][>]/, ?=>/igm;
    $sent =~ s/[!]\s*[=]\s*[>]/!=>/igm;
    $sent =~ s/\s+[!][=][>]/, !=>/igm;
    $sent =~ s/[f]\s*[=]\s*[>]/f=>/igm;
    $sent =~ s/\s+[f][=][>]/, f=>/igm;
    $sent =~ s/[q]\s*[=]\s*[>]/q=>/igm;
    $sent =~ s/\s+[q][=][>]/, q=>/igm;
    $sent =~ s/[=]\s+[>]/=>/igm;
    $sent =~ s/\s+[=][>]/, =>/igm;
    $sent =~ s/[,]+/,/igm;

    say "better sentence(6): ", $sent if !$be_quiet;

    if ( LANGUAGE() eq 'en' ) {
        $sent =~ s/[']s\s/ is /igm;
    }

    say "better sentence: ", $sent if !$be_quiet;

    $data->{persistent}{last_user_sentences}{6} =
      $data->{persistent}{last_user_sentences}{5};
    $data->{persistent}{last_user_sentences}{5} =
      $data->{persistent}{last_user_sentences}{4};
    $data->{persistent}{last_user_sentences}{4} =
      $data->{persistent}{last_user_sentences}{3};
    $data->{persistent}{last_user_sentences}{3} =
      $data->{persistent}{last_user_sentences}{2};
    $data->{persistent}{last_user_sentences}{2} =
      $data->{persistent}{last_user_sentences}{1};
    $data->{persistent}{last_user_sentences}{1} = $sent;

    return ( $sent, $no_change_pronouns );
}

sub ask {
    my $CLIENT_ref              = shift;
    my $sent_everything         = shift;
    my $display_str_ref         = shift;
    my $user                    = shift;
    my $working_client_requests = shift;
    my $only_learn              = shift;

    say(`free`);

    $| = 1;

    build_builtin_table();

    $data->{caches}{cache_semantic_net_get_key_for_item} = {};

    if ( not( -f $data->{intern}{dir} . '/display.cfg' ) ) {
        open my $handle, ">", $data->{intern}{dir} . '/display.cfg';
        close $handle;
    }
    read_config $data->{intern}{dir} . '/display.cfg' => my %config_display;

    if ($$display_str_ref) {
        $config_display{ 'user_' . $user }{'display'} = $$display_str_ref;
    }
    $config_display{ 'user_' . $user }{'display'} = q{}
      if $data->{intern}{in_cgi_mode};

    $CLIENT_ref = $$CLIENT_ref;
    my $CLIENT = ${$CLIENT_ref};

    chomp $sent_everything;
    $sent_everything = correct_time($sent_everything);

    if ( $sent_everything =~ /^set\s"(.+?)"\s([+\-]+)\s"(.+?)"$/ ) {
        my ( $type, $question, $answer ) = ( $2, $1, $3 );

        my $status =
            'type: ' 
          . $type . "<br>"
          . 'question: '
          . $question . "<br>"
          . 'answer: '
          . $answer . "<br>";
        print $CLIENT 'DISPLAY:' . $status . "\n";
        print $CLIENT 'ANSWER:' . $status . "\n";
        print $CLIENT 'SPEAK:' . $status . "\n";

        say $status;

        add_index_of_combination( $type, $question, $answer );

        return 'accepted:<br>' . $status;
    }

    $sent_everything =~ s/(\d)[.]/$1/igm;
    $sent_everything =~ s/[?][=][>]/ questionnext /igm;
    $sent_everything =~ s/[!][=][>]/ factnext /igm;
    $sent_everything =~ s/[=][>]/ questionnext /igm;
    $sent_everything =~ s/[\-][>]/ reasonof /igm;
    $sent_everything =~ s/[=][=]/ == /igm;
    $sent_everything =~ s/([.?!]+)/$1 DOT/igm;
    $sent_everything =~ s/([.?!]+)\sDOT\$/$1\$/gm;

    my $to_say = q{};    # empty

    foreach my $sent ( split /DOT(\s|$)/, $sent_everything ) {
        $sent =~ s/^\s//igm;
        $sent =~ s/\s$//igm;

        $sent =~ s/([.?!]+) DOT/$1/igm;

        %{ $data->{caches}{cache_noun_or_not} } = ();

        my @answers = ();
        $config_display{ 'user_' . $user }{'display'} .=
          '<b>Mensch</b>:: ' . $sent . '<br>';
        $config_display{ 'user_' . $user }{'display'} =~ s/questionnext/?=>/igm;
        $config_display{ 'user_' . $user }{'display'} =~ s/factnext/!=>/igm;

        print $CLIENT 'DISPLAY:'
          . $config_display{ 'user_' . $user }{'display'} . "\n";
        say 'DISPLAY(2):' . $config_display{ 'user_' . $user }{'display'};

        ( $sent, my $no_change_pronouns ) =
          $only_learn ? ( $sent, 0 ) : better_question($sent);

        if ( my $perhaps_answer =
            $only_learn ? '' : simple_answer( $CLIENT_ref, $sent ) )
        {
            $config_display{ 'user_' . $user }{'display'} .=
              '<b>FreeHAL</b>:: ' . $perhaps_answer . '<br>';
            $to_say .= '' . $perhaps_answer . ' ';
        }
        else {

            my ( $sentences, $is_a_question ) = split_sentence $CLIENT_ref,
              $sent;
            my @sentences = @$sentences;

            if ( !$only_learn ) {
                foreach my $sentence_ref (@sentences) {
                    ( my $answer, $sentence_ref ) =
                      answer_sentence( $CLIENT_ref, $sentence_ref,
                        $is_a_question, $sent, $no_change_pronouns );
                    push @answers, $answer;
                    $config_display{ 'user_' . $user }{'display'} .=
                      '<b>FreeHAL</b>:: ' . $answer . '<br>';
                    $to_say .= '' . $answer . ' ';
                }
            }

            if ( not $data->{lang}{is_a_question} ) {
                my @facts = ();    # empty
                foreach my $sentence (@sentences) {
                    push @facts, hash_to_facts($sentence);
                }

                semantic_network_connect(
                    dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
                    config => \%config
                );

                foreach my $fact (@facts) {
                    semantic_network_put(
                        fact               => $fact,
                        optional_hook_args => [$CLIENT_ref],
                        sql_execute        => 1,
                        from_file          => 'facts',
                        execute_hooks      => 1
                    );
                }
                semantic_network_commit();
                if (@facts) {
                    semantic_network_clean_cache();
                }

                #				print 'facts: ' . "\n" . Dumper \@facts;
                #push @$fact_database, @facts;
                #add_automatically( \@facts );

      #foreach my $fact_ref (@facts) {
      #$fact_database_by_verb{ $fact_ref->[0] } = []
      #if !( $fact_database_by_verb{ $fact_ref->[0] } );
      #push @{ $fact_database_by_verb{ $fact_ref->[0] } },
      #$fact_ref;
      #foreach my $data->{const}{VERB} ( map { $_->[0] } @{ $fact_ref->[4] } ) {
      #$fact_database_by_verb{$data->{const}{VERB}} = []
      #if !( $fact_database_by_verb{$data->{const}{VERB}} );
      #push @{ $fact_database_by_verb{$data->{const}{VERB}} }, $fact_ref;
      #}
      #}

                open my $prolog_database_file, ">>",
                  $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/facts.pro"
                  or die 'Cannot write to \''
                  . $data->{intern}{dir}
                  . "/lang_"
                  . LANGUAGE()
                  . "/facts.pro'";
                foreach my $fact_orig (@facts) {
                    my $fact = [@$fact_orig];

                    my $code = join ' <> ',
                      (
                        ( shift @$fact ),
                        ( shift @$fact ),
                        ( shift @$fact ),
                        ( shift @$fact ),
                        ''
                      );
                    my $prio = pop @$fact;

                    $code .= join ' ;; ',
                      ( map { join ' <> ', @$_ } @{ $fact->[0] } );
                    $code .= ' <> ' . $prio;
                    say $code;
                    print $prolog_database_file $code, "\n";
                }

                close $prolog_database_file;

                #say Dumper \@facts;

                say(`free`);

                #parse_synonyms( $CLIENT_ref, 0, \@facts );
                say(`free`);
            }
        }

        print $CLIENT 'DISPLAY:'
          . $config_display{ 'user_' . $user }{'display'} . "\n";
        say 'DISPLAY:' . $config_display{ 'user_' . $user }{'display'};
        print $CLIENT 'SPEAK:' . $to_say . "\n";
        say 'now: SPEAK:' . $to_say . "\n";

        open my $to_say_file, '>', 'for-tts.txt';
        print $to_say_file $to_say;
        close $to_say_file;

        delete $config{''};
        delete $config{'synonyms'}{''};
        $config{'synonyms'}{'satellit'} = undef;
        foreach my $value ( values %{ $config{'synonyms'} } ) {
            $value = '' if !$value;
        }
        write_config %config, $data->{intern}{config_file};

    }

    print $CLIENT "BYE:.\n";

    $data->{connection}{working_client_requests} -= 1;

    write_config %config_display, $data->{intern}{dir} . '/display.cfg';
    $$display_str_ref = $config_display{ 'user_' . $user }{'display'};

    part_of_speech_write( file => $data->{intern}{dir} . 'lang_'
          . LANGUAGE()
          . '/word_types.memory' );

    say(`free`);
    store( $data->{persistent},
        $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/persistent_data.tmp' );

    return $config_display{ 'user_' . $user }{'display'};
}

sub part_of_speech_write {
    if ( !$data->{abilities}->{'tagger'} ) {
        my $sock = ${ connect_to( data => $data, name => 'tagger' ) };

        print {$sock} 'WRITE<;;>' . join( '<;;>', @_ ) . "\n";

        close $sock;
    }
    else {
        part_of_speech_write_memory(@_);
    }
}

# resolves A = B = C
# to:
#   A = B
#   B = C
#   A = C
sub resolve_multi_verb_line {
    my ($line) = @_;

    #say '-> line: ', $line;
    my @words = split /[=]/, $line;
    map { s/^\s+//igm; s/\s+$//igm } @words;

    #say '-> words: ', (join ', ', @words);

    # if more then 2
    if ( scalar @words > 2 ) {

        my @generated_lines = ();

        foreach my $word1 (@words) {
            foreach my $word2 (@words) {
                if ( $word1 ne $word2 ) {
                    push @generated_lines, $word1 . ' = ' . $word2;
                    say '-> generated: ', $generated_lines[-1];
                }
            }
        }

        return @generated_lines;
    }

    # if less then 2
    else {
        return ( $_[0] );
    }
}

sub process_template {
    my ( $prot_file, $pro_file, $CLIENT_ref ) = @_;

    $| = 1;

    my %lines_to_write = ();
    my %all_words      = ();

    my $i = 0;

    # open
    open my $source, '<', $prot_file;
    open my $target, '>', $pro_file;
    close $target;

    $| = 1;

    my $percent;

    # for each sentence
  SENTENCE:
    while ( defined( my $line = <$source> ) ) {

        # for each line

        # if empty
        if ( !$line ) {
            next SENTENCE;
        }

        my $part = 'fact';
        if ( $line =~ /\/\// ) {
            ( $line, $part ) = split /\/\//, $line;
        }

        $lines_to_write{$part} ||= [];

        ( $line, my $no_change_pronouns ) = better_question( ascii($line), 1 );

        foreach my $new_line ( resolve_multi_verb_line($line) ) {
            push @{ $lines_to_write{$part} }, $new_line;
            $new_line =~ tr/.//d;
            $new_line =~ tr/!//d;
            foreach my $word ( ( split /[\s"'.,]+/, $new_line ) ) {
                $all_words{$word} = 1;
            }
        }

        $i += 1;
        if ( $i % 100 == 0 ) {
            $percent = 100 / 50_000 * $i;

            print "\r", $percent, "\r";

            set_percent( $CLIENT_ref, $percent );
        }

        if ( $percent && $percent == 0 ) {

            #select undef, undef, undef, 0.2;
        }
    }

    $i = 0;

    #foreach my $word (@all_words) {
    #pos_prop( $CLIENT_ref, $word );

    #my $lower = lc $word;
    #if ( $word ne $lower ) {
    #pos_of ( $CLIENT_ref,
    #$lower,
    #0,
    #1,
    #0,
    #$lower,
    #LANGUAGE() eq 'de' )
    #}

    #if ( $i > 100 ) {
    #part_of_speech_write(
    #file =>
    #$data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.memory'
    #);
    #$i = 0;
    #}

    #$i += 1;
    #}

    ### tagger begin

    my $mem = part_of_speech_get_memory();

    #while ( my ($key, $val) = each %$mem ) {
    #	if ( !$val->{type} || $val->{type} eq 'q' ) {
    #		$all_words{$key} = 1;
    #	}
    #}

    my @all_words = grep {
            !$mem->{$_}->{'type'}
          || $mem->{$_}->{'type'} eq 'q'
          || !$mem->{$_}->{'genus'}
          || $mem->{$_}->{'genus'} eq 'q'
      }
      map { ($_) } keys %all_words;

    #my $p =
    #LANGUAGE() eq 'en'
    #? new Lingua::EN::Tagger
    #: new Lingua::DE::Tagger;
    #my $readable_text = $p->get_readable(join ' ', @all_words);
    #$readable_text =~ s/[<]\/(.+?)[>]/\/$1 /igm;
    #$readable_text =~ s/[<].+?[>]//igm;
    #$readable_text =~ s/[\-]//igm;
    #my %word_list = map {
    #my @a = split(/\//, $_);
    #if ( $a[0] =~ /____/ ) {
    #$a[0] =~ s/____//igm;
    #$a[1] = 'inter';
    #}
    #@a
    #} split /\s/, $readable_text;

    my $l = 0;

    my $part_of_speech_memory = part_of_speech_get_memory();

    foreach my $word (@all_words) {
        $l += 1;
        eval {
            local $SIG{__DIE__};
            local $SIG{ALRM} = sub { die @_; };

            #alarm(6);

            say 'processing: ', $word;
            if ( $word ne lc $word ) {
                $word = ucfirst lc $word;
            }

            #foreach my $word (keys %word_list) {
            #$l += 1;
            #say 'processing: ', $word;

            #if ( $word ne lc $word ) {
            #$word = ucfirst lc $word;
            #}

            #my $pos_tagged = $word_list{$word}
            #|| $word_list{ lc $word }
            #|| $word_list{ ucfirst $word };
            #next if !$pos_tagged;
            #if ( lc $pos_tagged eq 'nn' && $word =~ /(es|er|en|em)$/ ) {
            #$pos_tagged = 'JJ';
            #}

            #$pos_tagged =
            #$pos_tagged eq 'CD'   ? 3
            #: $pos_tagged eq 'EX'   ? 3
            #: $pos_tagged eq 'IN'   ? 6
            #: $pos_tagged eq 'JJ'   ? 3
            #: $pos_tagged eq 'JJR'  ? 3
            #: $pos_tagged eq 'JJS'  ? 3
            #: $pos_tagged eq 'MD'   ? 1
            #: $pos_tagged eq 'NN'   ? 2
            #: $pos_tagged eq 'NNS'  ? 2
            #: $pos_tagged eq 'NNPS' ? 2
            #: $pos_tagged eq 'NNP'  ? 2
            #: $pos_tagged eq 'PDT'  ? 3
            #: $pos_tagged eq 'PRP'  ? 2
            #: $pos_tagged eq 'PRPS' ? 3
            #: $pos_tagged eq 'RB'   ? 3
            #: $pos_tagged eq 'RBR'  ? 3
            #: $pos_tagged eq 'RBS'  ? 3
            #: $pos_tagged eq 'RP'   ? 3
            #: $pos_tagged eq 'TO'   ? 6
            #: $pos_tagged eq 'UH'   ? 7
            #: $pos_tagged eq 'SYM'  ? 2
            #: $pos_tagged =~ /^VB/ ? 1
            #: $pos_tagged =~ /^W/  ? 5
            #:                              0;

            #my $line = $pos_tagged;

            #my $type_str =
            #$line == 1 ? 'vt'
            #: $line == 2 ? 'n,'
            #: $line == 3 ? 'adj'
            #: $line == 4 ? 'n,'
            #: $line == 5 ? 'fw'
            #: $line == 6 ? 'prep'
            #: $line == 7 ? 'inter'
            #:              'q';

            $part_of_speech_memory->{$word}->{'type'} = undef
              if $part_of_speech_memory->{$word}->{'type'} eq 'q';

            #if ( $part_of_speech_memory->{$word}->{'type'} eq 'q'
            #|| $part_of_speech_memory->{$word}->{'type'} eq 'nothing' ) {

            #$part_of_speech_memory->{$word}->{'type'} = $type_str;
            #}
            #if ( $part_of_speech_memory->{$word}->{'type'} eq 'q'
            #|| $part_of_speech_memory->{$word}->{'type'} eq 'nothing' ) {

            #$part_of_speech_memory->{$word}->{'type'} = 'perhaps_n';
            #}

            my $type_str = pos_of( $CLIENT_ref, $word );
            my ${is_noun} = ( $type_str == $data->{const}{NOUN} );

            if ( LANGUAGE() eq 'en' ) {
                $part_of_speech_memory->{$word}->{'genus'} ||= q{perhaps_s};
            }
            elsif ( ucfirst $word eq $word || $data->{lang}{is_noun} ) {
                pos_prop( $CLIENT_ref, ucfirst lc $word );
                $part_of_speech_memory->{ lc $word }->{'genus'} ||=
                  $part_of_speech_memory->{ ucfirst lc $word }->{'genus'};
            }
            alarm(0);
        };

        if ( $l % 200 == 0 && $data->{modes}{batch} ) {
            alarm(0);
            upload_memory();
        }

    }
    alarm(0);
    part_of_speech_write( file => $data->{intern}{dir} . 'lang_'
          . LANGUAGE()
          . '/word_types.memory' );
    alarm(0);

    ### tagger end

    # close
    close $source;

    $i = 0;

    my $cpu_limit = 100;

    open my $preferences, '<', '../../global_prefs_override.xml'
      or say "Preferences not found!";
    while ( defined( my $line = <$preferences> ) ) {
        if ( $line =~ /cpu_usage_limit/ ) {
            $line =~ m/[>](.*?)\./;
            $cpu_limit = $1 if $1;
            say $line;
        }
        if ( $line =~ /max_ncpus_pct/ ) {
            $line =~ m/[>](.*?)\./;
            $cpu_limit = $1 if $1;
            say $line;
        }
        say $line;
    }
    close $preferences;

    say "CPU LIMIT: ", $cpu_limit;

    # $cpu_limit /= 2;

    foreach my $key ( keys %lines_to_write ) {
        while ( @{ $lines_to_write{$key} } ) {
            process_template_lines(
                $CLIENT_ref,
                $pro_file,
                \$i,
                $key,
                splice(
                    @{ $lines_to_write{$key} },
                    0,
                    ( -f '/novo.txt' ) ? 40
                    : $cpu_limit < 80  ? $cpu_limit * 2
                    : $data->{modes}{batch}         ? 25000
                    : 500
                )
            );
        }
    }

    if ( time() > $data->{batch}{batch_timeout} && $data->{modes}{batch} ) {
        say "Timeout.";
        exit(0);
    }
    if ($data->{modes}{batch}) {
        open my $target, '<', $pro_file;
        while (<$target>) {
            print STDERR $_;
        }
        close $target;

        open my $prot, '>', $prot_file;

        foreach my $j ( 1 .. 4 ) {
            $ua->timeout(5);

            # Create a request
            my $sock = new IO::Socket::INET(
                PeerAddr => "de.wikipedia.org",
                PeerPort => 80,
                Proto    => 'tcp'
            ) || die "Error creating socket: $! ";
            print $sock
"GET http://de.wikipedia.org/wiki/Spezial:Zuf%C3%A4llige_Seite HTTP/1.0\nHost: de.wikipedia.org\nUser-Agent: Mozilla/5.0 (X11; U; Linux i686; de; rv:1.8.1.10) Gecko/20071214 Firefox/2.0.0.13\n\n";
            my $location;
            while ( my $line = <$sock> ) {
                if ( $line =~ /^Location: /i ) {
                    $line =~ s/^Location: //i;
                    chomp $line;
                    $location = $line;
                }
            }
            close($sock);
            say $location;
            my $sock = new IO::Socket::INET(
                PeerAddr => "de.wikipedia.org",
                PeerPort => 80,
                Proto    => 'tcp'
            ) || die "Error creating socket: $! ";
            print $sock
"GET $location HTTP/1.0\nHost: de.wikipedia.org\nUser-Agent: Mozilla/5.0 (X11; U; Linux i686; de; rv:1.8.1.10) Gecko/20071214 Firefox/2.0.0.13\n\n";
            my $wikipedia;
            while ( my $line = <$sock> ) {
                $wikipedia .= $line;
            }
            close($sock);
            print $wikipedia;
            $wikipedia = join( "\n", clean_html_website($wikipedia) );
            print $wikipedia;
            print {$prot} $wikipedia;
        }

        close $prot;

        process_template( $prot_file, $pro_file, $CLIENT_ref );
    }

    #}

    undef %lines_to_write;
}

our @facts_to_send = ();

sub process_template_lines {
    my $CLIENT_ref     = shift;
    my $pro_file       = shift;
    my $i              = shift;
    my $part           = shift;
    my @lines_to_write = @_;

    my $CLIENT = $$CLIENT_ref;

    # for each sentence

    $| = 1;

    semantic_network_connect(
        dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
        config => \%config
    );

    my @facts = ();

    if ( time() > $data->{batch}{batch_timeout} && $data->{modes}{batch} ) {
        say "Timeout.";
        exit(0);
    }

    foreach my $sent (@lines_to_write) {

        if ( time() > $data->{batch}{batch_timeout} && $data->{modes}{batch} ) {

            if (@facts_to_send) {
                open my $no_file, '<', '_no';
                my $no = <$no_file>;
                chomp $no;
                close $no_file;

                my $url = 'part=' . ascii($part) . '&no=' . $no . '&add_fact=';
                $url .= compress( join( '||', @facts_to_send ) );

                $ua->timeout(500);
                my $req =
                  HTTP::Request->new(
                    POST => 'http://jobs.freehal.org/backend/addv18.pl' );
                $req->content_type('application/x-www-form-urlencoded');
                $req->content($url);
                my $res = $ua->request($req);
            }

            say "Timeout.";
            exit(0);
        }

        $$i += 1;
        set_percent( $CLIENT_ref, 100 / @lines_to_write * $$i )
          if $$i % 500 == 0;
        say '-> parsing: ', $sent;

        print $CLIENT 'DISPLAY:', $sent, "\n";

        my @sentences = ();
        eval {
            local $SIG{__DIE__};
            local $SIG{ALRM} = sub { die @_; };

            alarm(20);

            my ( $sentences, $is_a_question ) = split_sentence $CLIENT_ref,
              $sent;
            @sentences = @$sentences;

            #alarm (9999999999999999999999999999999);
            alarm(0);
        };
        say $@ if $@;
        alarm(0);

        my @facts = ();    # empty
        foreach my $sentence (@sentences) {
            push @facts, hash_to_facts($sentence);
        }

        foreach my $fact (@facts) {
            semantic_network_put(
                fact               => $fact,
                optional_hook_args => [$CLIENT_ref],
                sql_execute        => 0,
                from_file          => 'facts',
                execute_hooks      => 1
            );
        }

        say 'parsing ended, inserting ', scalar @facts, ' facts into ',
          $pro_file;
        open my $target, '>>', $pro_file;
        my $o = 0;
        foreach my $fact_orig (@facts) {
            $o += 1;

            if ( $o % 20 == 0 ) {
                close $target;
                open my $target, '>>', $pro_file;
            }

            my $fact = [@$fact_orig];

            my $code = join ' <> ',
              (
                ( shift @$fact ),
                ( shift @$fact ),
                ( shift @$fact ),
                ( shift @$fact ),
                ''
              );
            my $prio = pop @$fact;

            $code .= join ' ;; ', ( map { join ' <> ', @$_ } @{ $fact->[0] } );
            $code .= ' <> ' . $prio;
            say $code;

            # select undef, undef, undef, 4;
            eval {
                if ( *ORIG_STDERR ) {
                    print ORIG_STDERR $code, "\n";
                }
                if ( *main::ORIG_STDERR ) {
                    print main::ORIG_STDERR $code, "\n";
                }
                if ( *::ORIG_STDERR ) {
                    print ::ORIG_STDERR $code, "\n";
                }
            };
            print $target $code, "\n";

            if ( $pro_file =~ /convertthis/ || $data->{modes}{batch} || $pro_file =~/actual|news/ ) {
                ( my $url_code = $code ) =~
                  s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

                push @facts_to_send, $url_code;
                print "BATCH\n";
                print $url_code, "\n";

#                push @urls, $config{urls}{add_fact}
#                   || 'http://jobs.freehal.org/backend/addv18.pl?part='. ascii($part) . '&no='
#                  ## || 'http://freehal.fr.funpic.de/addv18.php?part='. ascii($part) . '&no='
#                  . $no
#                  . '&add_fact=' . $url_code;
            }
        }

        close $target;

    }

    if (@facts_to_send) {
        open my $no_file, '<', '_no';
        my $no = <$no_file>;
        chomp $no;
        close $no_file;

        my $url = 'part=' . ascii($part) . '&no=' . $no . '&add_fact=';
        $url .= join( '||', @facts_to_send );

        $ua->timeout(500);
        my $req =
          HTTP::Request->new(
            POST => 'http://jobs.freehal.org/backend/addv18.pl' );
        $req->content_type('application/x-www-form-urlencoded');
        $req->content($url);
        my $res = $ua->request($req);
    }

    if ( !$data->{modes}{batch} ) {
        semantic_network_commit();
        semantic_network_clean_cache();
    }
}

sub push_hooks {
    push @AI::SemanticNetwork::hooks_for_template_processing, \&process_template;
    push @AI::SemanticNetwork::hooks_for_add, \&parse_synonyms;
    push @AI::SemanticNetwork::hooks_for_more_prot_data, \&load_news;
    push @AI::SemanticNetwork::hooks_for_percent, \&set_percent;
}

sub client_thread {
    my ( $CLIENT_ref, $user, $max_questions ) = @_;
    my $CLIENT = ${$CLIENT_ref};
    print "user: " . $user . "\n";
    print "$max_questions: " . $max_questions . "\n";

    $| = 1;

    print $CLIENT "Smile from the server to $user\n";

    my $commands =
        "OFFLINE_MODE:"
      . ( ( $config{'modes'}{'offline_mode'} ) || 0 ) . "\n"
      . "SPEECH_MODE:"
      . $config{'modes'}{'speech_mode'} . "\n";
    print $CLIENT $commands;
    say $commands;

    $data->{connection}{connected_clients} += 1;

    my $display_str = q{};    # empty

    my @threads = ();

    if ( not( -f $data->{intern}{dir} . '/display.cfg' ) ) {
        open my $handle, ">", $data->{intern}{dir} . '/display.cfg';
        close $handle;
    }
    read_config $data->{intern}{dir} . '/display.cfg' => my %config_display;
    $config_display{ 'user_' . $user }{'display'} = ''
      if !$config{'mysql'}{'user'};
    write_config %config_display, $data->{intern}{dir} . '/display.cfg';

    my $not_initialized = 1;
    while ( $max_questions
        && defined( my $line = get_client_response( $CLIENT_ref, 1 ) ) )
    {
        if ($not_initialized) {
            print $CLIENT "READY:.\n";
            $not_initialized = 0;
        }
        chomp $line;

        #        say $line;
        if ( $line =~ /^QUESTION[:]/ ) {
            print $CLIENT "GOT\n";

            $max_questions -= 1;

            my $sentence = $line;
            $sentence =~ s/^QUESTION[:]//i;
            $sentence =~ s/^\s+//igm;

            if ( $sentence =~ /^QUESTION[:]/ ) {
                next;
            }
            if ( $sentence =~ /^QQUESTION[:]/ ) {
                next;
            }

            my $only_learn = 0;
            if ( $sentence =~ /learn[:]/i ) {
                $only_learn = 1;
                $sentence =~ s/learn[:]//i;
            }

            if ( $sentence =~ /\/STATUS/ ) {
                my $status = status_now();
                print $CLIENT 'DISPLAY:' . $status . "\n";
                print $CLIENT 'ANSWER:' . $status . "\n";
                print $CLIENT 'SPEAK:' . $status . "\n";
            }

            elsif ( $sentence =~ /\/GEN\s+LIST/ ) {
                $sentence =~ s/\/GEN\s+LIST//igm;
                $sentence =~ s/\s+//igm;

                my $status = gen_list( $CLIENT_ref, $sentence );
                print $CLIENT 'DISPLAY:' . $status . "\n";
                print $CLIENT 'ANSWER:' . $status . "\n";
                print $CLIENT 'SPEAK:' . $status . "\n";
            }

            elsif ( $sentence =~ /\/STOP (.+?)$/i ) {

                my $sock = ${ connect_to( data => $data, name => lc $1 ) };

                print {$sock} "EXIT\n";

                close $sock;
            }

            elsif ( $sentence =~ /\/st\s*?$/i ) {

                my $sock = ${ connect_to( data => $data, name => 'tagger' ) };

                print {$sock} "EXIT\n";

                close $sock;
            }

            elsif ($sentence =~ /\/reload\s+knowledge/i
                || $sentence =~ /\/rk\s*?$/i )
            {
                load_database_file( $CLIENT_ref, get_database_files() );

                my $status = 'Ok.';
                print $CLIENT 'DISPLAY:' . $status . "\n";
                print $CLIENT 'ANSWER:' . $status . "\n";
                print $CLIENT 'SPEAK:' . $status . "\n";
            }

            elsif ($sentence =~ /\/define /i
                || $sentence =~ /\/d /i )
            {
                $sentence =~ s/\/define //igm;
                $sentence =~ s/\/d //igm;

                my $status =
'<table><tr><th>Word</th><th>Part of speech</th><th>Genus</th></tr>';
                foreach my $word ( split /\s+/, $sentence ) {
                    $status .=
                        '<tr><td>' 
                      . $word
                      . '</td><td>'
                      . $data->{lang}{constant_to_string}
                      { pos_of( $CLIENT_ref, $word ) }
                      . '</td><td>'
                      . pos_prop( $CLIENT_ref, $word )->{genus}
                      . '</td></tr>';
                }
                $status .= '</table>';

                $status =~ s/\n/<br>/igm;
                $status =~ s/[']//igm;
                $status =~ s/\$VAR1//igm;

                print $CLIENT 'DISPLAY:' . $status . "\n";
                print $CLIENT 'ANSWER:' . $status . "\n";
                print $CLIENT 'SPEAK:' . $status . "\n";
            }

            elsif ( $sentence =~ /^ueberwache\s+/i ) {
                chomp $sentence;
                $sentence =~ s/[?!.,-;_)(]+$//igm;
                $sentence =~ s/^ueberwache\s+//igm;
                my $url = $sentence;
                $url =~ s/^http[:]+[\/]+//igm;

                add_monitoring_url( $CLIENT_ref, $url );
            }

            else {
                $data->{connection}{working_client_requests} += 1;

                #                say "#";
                #                say $sentence;
                #                say "#";

                if ($sentence) {
                    ask( $CLIENT_ref, $sentence, \$display_str, $user,
                        \$data->{connection}{working_client_requests},
                        $only_learn );
                }

            }
        }
    }
    close $CLIENT;

    $data->{connection}{connected_clients} -= 1;
}

sub add_monitoring_url {
    my ( $CLIENT_ref, $url ) = @_;
    my $CLIENT = $$CLIENT_ref;

    read_config $data->{intern}{config_file} => my %config;
    $url =~ s/\s+[=]\s+/=/igm;
    $url =~ s/\s/%20/igm;
    $url =~ s/[=]/EQUAL/gm;
    $url =~ s/[:]+/:/igm;

    $config{'monitoring'}{$url} = 0;
    write_config %config, $data->{intern}{config_file};

    print $CLIENT 'ANSWER:URL added.', "\n";
}

sub download_file {
    my ($url) = @_;

    say 'downloading: ', $url;

    # Create a request
    my $req = HTTP::Request->new( GET => $url );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ( !$res->is_success ) {

        #       print $res->content;
        say 'download_file: Error while Downloading:';
        say $url;
        say $res->status_line;
    }

    return $res->content;
}

sub do_diff {
    my ( $last, $now ) = @_;

    $last =~ s/\r//igm;
    $last =~ s/\s+/ /igm;
    $last =~ s/\n//igm;
    $last =~ s/<\/p>//igm;
    $last =~ s/<p>/<br>/igm;
    $last =~ s/<br\/>/<br>/igm;
    $last =~ s/<br \/>/<br>/igm;
    $last =~ s/<br>/\n/igm;
    $last =~ s/<.+?>//igm;
    my @seq1 = split /<br>/i, $last;

    $now =~ s/\r//igm;
    $now =~ s/\s+/ /igm;
    $now =~ s/\n//igm;
    $now =~ s/<\/p>//igm;
    $now =~ s/<p>/<br>/igm;
    $now =~ s/<br\/>/<br>/igm;
    $now =~ s/<br \/>/<br>/igm;
    $now =~ s/<br>/\n/igm;
    $now =~ s/<.+?>//igm;
    my @seq2 = split /<br>/i, $now;

    my @diffs = diff( \@seq1, \@seq2 );
    @diffs = map { @$_ } @diffs;

    my ( $removed, $added ) = ( '', '' );

    foreach my $pair_ref (@diffs) {
        if ( $pair_ref->[0] eq '+' ) {
            $added .= "<br>" . $pair_ref->[1];
        }
        elsif ( $pair_ref->[0] eq '-' ) {
            $removed .= "<br>" . $pair_ref->[1];
        }
    }

    my $status = '';

    $removed =~ s/^\s+//igm;
    $added   =~ s/^\s+//igm;
    $removed =~ s/\s+$//igm;
    $added   =~ s/\s+$//igm;

    $status .= "Dieser Text wurde entfernt: " . $removed . "<br>"
      if length $removed > 5;
    $status .= "Dieser Text wurde hinzugefuegt: " . $added
      if length $added > 5;

    return $status;
}

sub monitoring_thread {
    my ( $CLIENT_ref, $user ) = @_;
    my $CLIENT = $$CLIENT_ref;

    $| = 1;

    select undef, undef, undef, 8;

    read_config $data->{intern}{dir} . '/display.cfg' => my %config_display;
    $config_display{ 'user_' . $user }{'display'} = '';
    write_config %config_display, $data->{intern}{dir} . '/display.cfg';
    select undef, undef, undef, 3;

    my $status = '';
    while (1) {
        read_config $data->{intern}{config_file} => my %config;
        if ( !$config{'monitoring'} ) {
            $config{'monitoring'} = {};
        }
        my @urls = keys %{ $config{'monitoring'} };

        # say Dumper $config{'monitoring'};

        foreach my $url (@urls) {
            $url =~ s/\s+[=]\s+/=/igm;
            $url =~ s/\s/%20/igm;
            $url =~ s/EQUAL/=/gm;

            my $now = download_file( 'http://' . $url );
            read_config $data->{intern}{config_file} => my %config;
            $config{'monitoring'}{$url} = $config{'monitoring'}{$url}
              || download_file( 'http://' . $url );
            write_config %config, $data->{intern}{config_file};
            my $last = $config{'monitoring'}{$url};
            select undef, undef, undef, 3;

            my $diff = do_diff( $last, $now );

            if ($diff) {
                $status .=
"<b>FreeHAL</b>: Die Website <a href=\"http://$url\">http://$url</a> hat sich geaendert.<br><br>";
                $status .= $diff;
                chomp $diff;
                $status .= "<br><br>" if $diff;

                read_config $data->{intern}{dir}
                  . '/display.cfg' => my %config_display;

                $status =~ s/[:]/::/igm;
                $config_display{ 'user_' . $user }{'display'} .= $status;

                write_config %config_display,
                  $data->{intern}{dir} . '/display.cfg';

                print $CLIENT 'DISPLAY:'
                  . $config_display{ 'user_' . $user }{'display'} . "\n";
                print $CLIENT 'ANSWER:'
                  . $config_display{ 'user_' . $user }{'display'} . "\n";
                print $CLIENT 'SPEAK:'
                  . $config_display{ 'user_' . $user }{'display'} . "\n";

                read_config $data->{intern}{config_file} => my %config;
                $config{'monitoring'}{$url} = $now;
                write_config %config, $data->{intern}{config_file};
            }

            select undef, undef, undef, 2;
        }

        select undef, undef, undef, 300;
    }

    # $config{'monitoring'}{ $url }
}

sub status_now {
    return
        'count of connected users: '
      . $data->{connection}{connected_clients}
      . '<br>count of working requests: '
      . $data->{connection}{working_client_requests} . '<br>';
}

sub r_escape {
    my $s = shift;

    # replace all newlines, CR and % with CGI-style encoded sequences
    $s =~ s/([%\r\n])/sprintf("%%%02X", ord($1))/ge;
    return $s;
}

sub r_unescape {
    my $s = shift;

    # convert back escapes to the original chars
    $s =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    return $s;
}

sub start_ability_tagger {
    my $name = 'tagger';

    $data->{abilities}->{$name} = 1;

    # LOW LATENCY PATCH
    if ( !$config{'modes'}{'low-latency'} ) {
        load_pos();
        $data->{abilities}->{$name} = 2;
    }
}

sub start_service_tagger {
    my $name = 'tagger';

    print ">> forking and connecting as $name ...\n";

    #if (fork == 0) {

    open STDOUT, '>', 'tagger.log';
    open STDERR, '>', 'tagger-err.log';

    $data->{abilities}->{$name} = 1;

    my $port = $config{'servers'}{ 'port_' . $name };

    my $initialized = 0;

    my $n = 0;

    our $CLIENT;
    our $CLIENT_ref;

    say ">> Connected ($name).";

    my $loaded = 0;

    while (1) {

        my $sock = new IO::Socket::INET(
            LocalHost => '',
            LocalPort => '' . $port,
            Proto     => 'tcp',
            Listen    => 100,
            Reuse     => 1,
            Blocking  => 1,
            timeout   => "5",
        );
        die "Could not create socket ($name): $! \n" if not $sock;

        eval {
            local $SIG{'__DIE__'};

            my $client_addr;
            while (1) {
                $CLIENT     = $sock->accept();
                $CLIENT_ref = \$CLIENT;
                print ">> got a connection ($name)\n";

                # LOW LATENCY PATCH
                if ( !$config{'modes'}{'low-latency'} ) {
                    if ( !$loaded ) {
                        $loaded = 1;
                        load_pos();
                        $data->{abilities}->{$name} = 2;
                    }
                }

                eval {
                    local $SIG{'__DIE__'};

                    local $SIG{"ALRM"} = sub {
                        local $SIG{'__DIE__'};
                        say 'alarm! timeout exceeded.';
                        close $CLIENT;
                        undef $CLIENT;
                        die 'alarm';
                    };

                    alarm(6);

                  CLIENT:
                    while ( defined( my $line = <$CLIENT> ) ) {
                        eval {
                            local $SIG{'__DIE__'};

                            chomp $line;
                            my ( $cmd, @param ) =
                              split( /[<][;][;][>]/, $line );

                            print Dumper $cmd;
                            print Dumper \@param;

                            if ( $cmd eq 'EXIT' ) {

                                #kill_all_subprocesses();
                                exit 0;
                            }
                            elsif ( $cmd eq 'WRITE' ) {
                                alarm(999999);
                                part_of_speech_write_memory(@param);

                            }
                            elsif ( $cmd eq 'GET' ) {
                                my $sub_cmd = shift @param;
                                if ( $sub_cmd eq 'type' ) {
                                    $param[0] = $CLIENT_ref;
                                    alarm(10);
                                    my $pos = pos_of(@param);
                                    my $send_this =
                                      r_escape( nfreeze( \$pos ) );
                                    print {$CLIENT} $send_this . "\n";
                                    print 'send_this:', Dumper $send_this;
                                }
                                elsif ( $sub_cmd eq 'genus' ) {
                                    $param[0] = $CLIENT_ref;
                                    alarm(10);
                                    my $prop      = pos_prop(@param);
                                    my $send_this = r_escape( nfreeze($prop) );
                                    print {$CLIENT} $send_this . "\n";
                                    print 'send_this:', Dumper $send_this;
                                }
                                else {
                                    say 'ERROR: $cmd_sub is ' . $sub_cmd;
                                    print {$CLIENT} 'ERROR: $cmd_sub is '
                                      . $sub_cmd . "\n";
                                }
                            }
                            else {
                                say 'ERROR: $cmd is not GET';
                                print {$CLIENT} 'ERROR: $cmd is not GET' . "\n";
                                alarm(999999999999999999);
                            }
                        };
                        if ($@) {
                            say $@;
                        }
                        last CLIENT;
                    }
                    alarm(999999999999999999);
                    say 'closed.';

                    close $CLIENT;
                };
                if ($@) {
                    say $@;
                }
            }
        };
    }
    select undef, undef, undef, 4;
}

sub server_loop {
    print ">> Connecting...\n";
    my $port = 5173;

    my $sock = new IO::Socket::INET(
        LocalHost => '',
        LocalPort => '' . $port,
        Proto     => 'tcp',
        Listen    => 100,
        Reuse     => 1,
        Blocking  => 1,
    );
    die "Could not create socket: $! \n" if not $sock;

    my $initialized = 0;

    # load_database_file( undef, get_database_files() );

    my $n = 0;

    say ">> Connected(1).";

    kill_process_from('freehal-main.pid') if $::gui;
    say ">> Connected(2).";

    my $client_addr;
    while (1) {
        my $CLIENT     = $sock->accept();
        my $CLIENT_ref = \$CLIENT;
        print ">> got a connection\n";

        open my $pidfile, '>', 'freehal-main.pid';
        print $pidfile $$;
        close $pidfile;

        if ( !$initialized ) {
            $initialized = 1;
            client_setup( data => $data, username => 'username' );
            $data->{connection}{client_info}->{clientsocket} = $CLIENT_ref;
            load_database_file( $CLIENT_ref, get_database_files() );
        }

        my $pid = ( lc($^O) =~ /win/i ) ? 0 : fork;

        if ($pid) {

            #$initialized = 1;
            waitpid $pid, 0;
        }
        else {

            print $CLIENT "READY:EVERYTHING_INITIALIZED\n";

            print $CLIENT "READY:EVERYTHING_INITIALIZED\n";

            delete $config{''};
            delete $config{'synonyms'}{''};
            foreach my $value ( values %{ $config{'synonyms'} } ) {
                $value = '' if !$value;
            }
            write_config %config, $data->{intern}{config_file};

            print $CLIENT "client_thread" . "\n";
            print $CLIENT 'JELIZA_FULL_VERSION:'
              . $data->{intern}{FULL_VERSION} . "\n";
            print $CLIENT 'NAME:' . $data->{intern}{NAME} . "\n";
            print $CLIENT "PERL:.\n";
            my $user = <$CLIENT>;
            $user =~ s{USER:}{}i;
            chomp $user;
            my $max_questions = 999999;

            if ( $user =~ /\/([0-9]+?)$/ ) {
                $max_questions = $1;
            }

            client_setup( data => $data, username => $user );
            $data->{connection}{client_info}->{clientsocket} = $CLIENT_ref;

            print $CLIENT "initializing..\n";
            if ( !$initialized ) {
                print $CLIENT "WAIT:100\n";
                $initialized = 1;

                #fork and exit();
            }

            # fork and client_thread( $CLIENT_ref, $user );
            # fork and monitoring_thread( $CLIENT_ref, $user );

            client_thread( $CLIENT_ref, $user, $max_questions );

            if ( $config{'features'}{'monitoring'} ) {
                monitoring_thread( $CLIENT_ref, $user );
            }

            if ( lc($^O) !~ /win/i ) {
                exit 0;
            }
        }
        $n += 1;

        if ( $n > 10 && 0 ) {
            return;
        }
    }
}

#~ sub server_offer {
#~ print ">> Connecting...\n";

#~ open(*STDOUT, '>', 'freehal-offer.log');
#~ open(*STDERR, '>', 'freehal-offer-err.log');

#~ my @offer_to_server = ('freehal.selfip.net', 'freehal.org', 'tobias-schulz.info');
#~ my $masterproxy_port = 5100;

#~ client_setup( username => 'nobody' );

#~ my $initialized = 0;

#~ my $CLIENT;
#~ foreach my $server (@offer_to_server) {
#~ $CLIENT = new IO::Socket::INET(
#~ PeerAddr => $server,
#~ PeerPort => '' . $masterproxy_port,
#~ Proto     => 'tcp',
#~ Blocking  => 1,
#~ Timeout => 5,
#~ );
#~ if ( $CLIENT ) {
#~ last;
#~ }
#~ }

#~ my $CLIENT_ref = \$CLIENT;
#~ $CLIENT or exit(0);
#~ print $CLIENT "OFFER:\n";

#~ my $client_addr;
#~ while ($CLIENT) {

#~ print ">> got a connection\n";

#~ open my $pidfile, '>', 'offer.pid';
#~ print $pidfile $$;
#~ close $pidfile;

#~ print $CLIENT "OFFER:\n" or exit(0);

#~ print $CLIENT "READY:EVERYTHING_INITIALIZED\n";

#~ delete $config{''};
#~ delete $config{'synonyms'}{''};
#~ foreach my $value ( values %{ $config{'synonyms'} } ) {
#~ $value = '' if !$value;
#~ }
#~ write_config %config, $data->{intern}{config_file};

#~ print $CLIENT "client_thread" . "\n";
#~ print $CLIENT 'JELIZA_FULL_VERSION:' . $FULL_VERSION . "\n";
#~ print $CLIENT 'NAME:' . $NAME . "\n";
#~ print $CLIENT "PERL:.\n";
#~ my $user = 'I';
#~ $user =~ s{USER:}{}i;
#~ chomp $user;
#~ my $max_questions = 999999;

#~ client_setup( username => $user );
#~ $data->{connection}{client_info}->{clientsocket} = $CLIENT_ref;

#~ if ( !$initialized ) {
#~ $initialized = 1;
#~ say 'begin load_database_file';
#~ load_database_file( $CLIENT_ref, get_database_files() );
#~ say 'end load_database_file';

#~ #fork and exit();
#~ }

#~ # fork and client_thread( $CLIENT_ref, $user );
#~ # fork and monitoring_thread( $CLIENT_ref, $user );

#~ client_thread( $CLIENT_ref, $user, $max_questions );
#~ }
#~ }

sub get_database_files {
    say $data->{intern}{dir} . "/lang_" . LANGUAGE() . "";
    opendir my $files_listing,
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . "";
    my @files =
      sort map { $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/" . $_ }
      grep     { /(pro|prot)$/ } readdir $files_listing;
    closedir $files_listing;
    opendir my $files_listing,
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/thesaurus";
    push @files,
      sort
      map  { $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/thesaurus/" . $_ }
      grep { /(pro|prot)$/ } readdir $files_listing;
    closedir $files_listing;
    unshift @files,
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . '/actual_news.prot';
    return @files;
}

sub get_pos_files {
    my ($must_contain) = @_;

    opendir my $files_listing,
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . "";
    my @files =
      sort map { $data->{intern}{dir} . "/lang_" . LANGUAGE() . "/" . $_ }
      grep     { /\.($must_contain)$/ } readdir $files_listing;
    closedir $files_listing;

    print "Files containing $must_contain: ", join( ', ', @files ), "\n";

    return @files;
}

sub gen_actual_extradata {
    return (

        #~ [
        #~ 'ist', 'mein wissen', ( scalar @$fact_database ) . ' knoten',
        #~ 'gross', [], 100
        #~ ],
        #~ [
        #~ 'ist',
        #~ 'mein semantisches netz',
        #~ ( scalar @$fact_database ) . ' knoten',
        #~ 'gross', [], 100
        #~ ],
        #~ [
        #~ 'hat',
        #~ 'mein semantisches netz',
        #~ ( scalar @$fact_database ) . ' knoten',
        #~ '', [], 100
        #~ ],
        [
            'habe', 'ich',
            'Die Versionsnummer ' . $data->{intern}{FULL_VERSION},
            '', [], 100
        ],
    );
}

sub load_database_file {
    my $CLIENT_ref = shift;
    my $noinit     = $::unix_shell_mode ? pop : 0;
    my @files      = @_;
    unshift @files,
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . '/actual_news.prot';

    ### persistent data structures

    my $persistent_loaded_successfully =
      -f $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/persistent_data.tmp';
    eval {
        local $SIG{'__DIE__'};
        $data->{persistent} =
          retrieve( $data->{intern}{dir} . 'lang_'
              . LANGUAGE()
              . '/persistent_data.tmp' );
    };
    $data->{persistent} ||= {};

    # everything already here?
    if ( $data->{modes}{use_sql}
        && scalar( keys %{ $data->{persistent}{semantic_net} } ) > 100 )
    {
        return;
    }

    say ">> Loading fact databases: ", ( join ', ', @files );
    print '<br />' if $data->{intern}{in_cgi_mode};

    #@$fact_database = [];
    #foreach my $file (@files) {
    #open my $h, '<', $file or say 'Error while opening: ', $file;
    #my @arr = <$h>;
    #close $h;
    #push @$fact_database,
    #map { lc $_ } grep { $_ !~ /^\s*?[#]/ } grep { defined $_ } @arr;
    #}
    #foreach my $fact (@$fact_database) {
    #chomp $fact;
    #$fact =~ s/\s+[<][>]\s+[<][>]\s+/ <> nothing <> /gm;
    #$fact =~ s/[<][>]/ <> /gm;
    #$fact =~ s/\s+/ /gm;
    #$fact = [ split /[<][>]/, $fact ];
    #foreach my $item (@$fact) {
    #$item =~ s/^\s//igm;
    #$item =~ s/\s$//igm;
    #}

    #my ( $data->{const}{VERB}, $subj, $obj, $advs ) =
    #( shift @$fact, shift @$fact, shift @$fact, shift @$fact );
    #my $prio = pop @$fact;

    #$fact = join '<>', @$fact;
    #$fact = [ split /\s*[;][;]\s*/, $fact ];
    #foreach my $clause (@$fact) {
    #$clause = [ split /[<][>]/, $clause ];
    #foreach my $item (@$clause) {
    #$item =~ s/nothing//igm;
    #$item =~ s/(^\s+)|(\s+$)//igm;
    #chomp $item;
    #}
    #}
    #@$fact = grep { join '', @$_ } @$fact;

    #$fact = [ $data->{const}{VERB}, $subj, $obj, $advs, $fact, $prio ];
    #}
    #@$fact_database =
    #grep { $_->[0] && $_->[0] ne 'st' && $_->[0] ne 'e'; }
    #@$fact_database;

    say ">> Connecting.";
    semantic_network_connect(
        dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
        config => \%config
    );
    say ">> Connectied.";

    say ">> Creating table.";
    semantic_network_execute_sql(
        qq{
    		create table reason_effect
    		(
    			`reason_verb` varchar(70),
    			`reason_noun` varchar(70),
    			`reason_adv` varchar(70),
    			`effect_verb` varchar(70),
    			`effect_noun` varchar(70),
    			`effect_adv` varchar(70),
    			
    			UNIQUE(
					`reason_verb`,
					`reason_noun`,
					`reason_adv`,
					`effect_verb`,
					`effect_noun`,
					`effect_adv`
    			)
    		);
		}
    );
    say ">> Table created.";

    if ( !$noinit || $data->{modes}{batch} ) {
        semantic_network_load(
            files              => \@files,
            optional_hook_args => [$CLIENT_ref],
            execute_hooks => 1,            # !$persistent_loaded_successfully,
            client        => $CLIENT_ref
        );
    }

    add_automatically( 0, [] );

    # parsing synonym lines
    print ">> Parsing Synonyms...\n";

    #parse_synonyms( $CLIENT_ref, 1, $fact_database );
    #add_automatically($fact_database);

    part_of_speech_write( file => $data->{intern}{dir} . 'lang_'
          . LANGUAGE()
          . '/word_types.memory' );

    no strict;
    if ($data->{modes}{batch}) {
        use strict;
        upload_memory();
    }
    use strict;

    open my $FIRST_NAMES, '<',
      $data->{intern}{dir} . "lang_" . LANGUAGE() . "/wsh/names.wsh";
    while ( defined( my $fn = <$FIRST_NAMES> ) ) {
        $fn = lc $fn;
        chomp $fn;

        $fn =~ s/[_]/ /gm;
        $fn =~ s/(^|\s|[;])nothing(\s|_|[;]|$)//igm;
        $fn =~ s/nothing\s//igm;
        $fn =~ s/[mds]ein\s//igm;

        $data->{lang}{is_a_name}{$fn} = 1;
    }
    close $FIRST_NAMES;

    store( $data->{persistent},
        $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/persistent_data.tmp' );

    print ">> Fact database loaded...\n";

    if ($data->{modes}{batch}) {
        kill_all_subprocesses();
    }
}

sub upload_memory {
    return;
    part_of_speech_write( file => $data->{intern}{dir} . 'lang_'
          . LANGUAGE()
          . '/word_types.memory' );
    open my $file, '<',
      $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.memory';
    my $data = join( '', <$file> );
    close $file;
    ( my $url_code = $data ) =~ s/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg;

    my $url = $config{urls}{add_fact}
      || 'http://jobs.freehal.org/backend/addv18.pl';

    open my $no_file, '<', '_no';
    my $no = <$no_file>;
    chomp $no;
    close $no_file;

    $ua->timeout(5);
    my $req = HTTP::Request->new( POST => $url );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content( 'no=' . $no . '&add_posfile=' . $url_code . '' );

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
}

#sub fill_out_in_semantic_net {
#my ( $name, $ref_to_use, $data->{lang}{is_helper}) = @_;

#if ( !defined $data->{persistent}{semantic_net}->{$name} ) {
#$data->{persistent}{semantic_net}->{$name} = $ref_to_use
#|| {
##name              => $name,
#facts             => [],
#'facts_variables' => [],
#}
#;
#}
##    elsif ( $ref_to_use ) {
##        push @{ $data->{persistent}{semantic_net}->{$name}->{facts} },
##            @{ $ref_to_use->{facts} };
##    }

#fill_out_in_semantic_net( strip_to_base_word( $name ), $ref_to_use, 1 )
#if !$data->{lang}{is_helper}&& length $name > 1;

#return $data->{persistent}{semantic_net}->{$name};
#}

#sub add_to_semantic_net {
#my $CLIENT_ref = shift;
#my ${is_initial}= shift;
#my ($facts)    = @_;
#my $CLIENT     = $$CLIENT_ref;

#my @endings =
#sort { length $a > length $b }
#( qw{en e s n in innen es r es er}, '' );
#%{$data->{lang}{is_time_measurement}}= map { $_ => 1 } get_time_measurements();

#my @all_facts = ();

#%{$data->{lang}{is_in_something_hash}}= map { $_ => 1 } 'a' .. 'h';
#%{$data->{lang}{is_in_something_hash}}= ( %{$data->{lang}{is_in_something_hash,}}%{$data->{lang}{is_something}});

##if ( $data->{modes}{use_sql} ) {
##print "untieing...\n";
##eval   'use Tie::RDBM;'
##. 'untie %$data->{persistent}{semantic_net};'
##;
##print $@, "\n";
##print "untied!\n";
##$data->{persistent}{semantic_net} = {};
##}

#my $i = 0;
#foreach my $fact (@$facts) {
#$i += 1;
#print $CLIENT 'PERCENT:', ( 100 * $i / scalar @$facts ), "\n"
#if !eof($CLIENT) && $i % 300 == 0;
#say( 100 * $i / scalar @$facts, '%' ) if $i % 300 == 0;
#print '<br />' if $data->{intern}{in_cgi_mode} && $i % 300 == 0;

#$fact->[1] = lc $fact->[1];
#$fact->[2] = lc $fact->[2];

#my $subject_ref = fill_out_in_semantic_net( $fact->[1] );
#$data->{persistent}{semantic_net}->{ $fact->[1] }->{facts} = []
#if !$data->{persistent}{semantic_net}->{ $fact->[1] }->{facts};

#my $object_ref = fill_out_in_semantic_net( $fact->[2] );
#foreach my $subclause ( @{ $fact->[4] } ) {
#fill_out_in_semantic_net( $subclause->[1] );
#fill_out_in_semantic_net( $subclause->[2] );
#}

#my $new_fact = {
#verb       => $fact->[0],
#subj       => { name => $fact->[1] },
#obj        => { name => $fact->[2] },
#advs       => [ split /[;]/, $fact->[3] ],
#subclauses => [],
#prio       => $fact->[5],
#};
#foreach my $subclause ( @{ $fact->[4] } ) {
#push @{ $new_fact->{subclauses} }, {
#verb => $subclause->[0],
#subj => { name => $subclause->[1] }
#,    #$data->{persistent}{semantic_net}->{ $subclause->[1] },
#obj => { name => $subclause->[2] }
#,    #$data->{persistent}{semantic_net}->{ $subclause->[2] },
#advs         => [ split /[;]/, $subclause->[3] ],
#questionword => $subclause->[4],
#};
#}

##say Dumper $fact if $fact->[2] =~ /freehal/i;

#if ( grep { $_->{verb} =~ /[=][>]/ } @{ $new_fact->{subclauses} } ) {
#$data->{persistent}{semantic_net}->{'=>_answers'} = []
#if !defined $data->{persistent}{semantic_net}->{'=>_answers'};
#push @{ $data->{persistent}{semantic_net}->{'=>_answers'} }, $new_fact;

##say Dumper $data->{persistent}{semantic_net}->{'=>_answers'};
##exit 0;
#}
#else {
### add entry for verb
#fill_out_in_semantic_net( strip_to_base_word( lc $fact->[0] ) );
#my $value_verb = $data->{persistent}{semantic_net}->{ strip_to_base_word( lc $fact->[0] ) };
#push @{ $value_verb->{facts} }, $new_fact;
##say 'verb: ', lc $fact->[0], ' - ', strip_to_base_word( lc $fact->[0] );

### add entry for subject
#my $value_subj = $data->{persistent}{semantic_net}->{ strip_to_base_word( lc $fact->[1] ) };
#push @{ $value_subj->{facts} }, $new_fact;
#$data->{persistent}{semantic_net}->{ strip_to_base_word( lc $fact->[1] ) } = $value_subj;
##say 'push @{ $data->{persistent}{semantic_net}->{ ', lc $fact->[1], ' }->{facts} }, ',
##    ( Dumper $fact), ';'
##    if !$is_initial;

#my $subj_2 = strip_to_base_word( lc $fact->[1] );
#$subj_2 =~ s/[_\s]+/_/igm;
#fill_out_in_semantic_net( $subj_2, $subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ $subj_2 }->{facts} },
##    $new_fact;
#$subj_2 =~ s/^[_]+//igm;
#$subj_2 =~ s/[_]+$//igm;
#fill_out_in_semantic_net( $subj_2, $subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ $subj_2 }->{facts} },
##    $new_fact;

#my $subj_3 = strip_to_base_word( lc $fact->[1] );
#$subj_3 =~ s/[_\s]+/ /igm;
#fill_out_in_semantic_net( $subj_3, $subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ $subj_3 }->{facts} },
##    $new_fact;
#$subj_3 =~ s/^\s+//igm;
#$subj_3 =~ s/\s+$//igm;
#fill_out_in_semantic_net( $subj_3, $subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ $subj_3 }->{facts} },
##    $new_fact;

#my @words = split /\s+/, strip_to_base_word( $subj_3 );
#my @words_relevant = grep {
#$_
#!~ /^(ein|der|die|das|den|dem|des|ein|eine|einer|einen|einem|eines|kein|keine|keinen|keines|keiner|a|an|the)(\s|$)/i
#&& !$data->{lang}{is_time_measurement}{$_}
#} @words;
#if ( scalar @words_relevant > 1
#&& $words_relevant[-1] =~ /^[_].*?[_]$/ )
#{
#pop @words_relevant;
#pop @words;
#}

#fill_out_in_semantic_net( ( join ' ', @words ), $subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ join ' ', @words }->{facts} },
##    $new_fact;
#foreach
#my $word ( scalar @words_relevant >= 2 && @words_relevant )
#{
#fill_out_in_semantic_net($word);

#my $value_word = $data->{persistent}{semantic_net}->{$word};
#push @{ $value_word->{facts} }, $new_fact;
#$data->{persistent}{semantic_net}->{$word} = $value_word;
#}
#fill_out_in_semantic_net( ( join ' ', @words_relevant ),
#$subject_ref );

##push @{ $data->{persistent}{semantic_net}->{ join ' ', @words_relevant }->{facts} },
##    $new_fact;

### add entry for object
#my $value_obj = $data->{persistent}{semantic_net}->{ strip_to_base_word( lc $fact->[2] ) };
#push @{ $value_obj->{facts} }, $new_fact;
#$data->{persistent}{semantic_net}->{ strip_to_base_word( lc $fact->[2] ) } = $value_obj;

#my $obj_2 = strip_to_base_word( lc $fact->[2] );
#$obj_2 =~ s/[_\s]+/_/igm;
#fill_out_in_semantic_net( $obj_2, $object_ref );

##push @{ $data->{persistent}{semantic_net}->{ $obj_2 }->{facts} },
##    $new_fact;
#$obj_2 =~ s/^[_]+//igm;
#$obj_2 =~ s/[_]+$//igm;
#fill_out_in_semantic_net( $obj_2, $object_ref );

##push @{ $data->{persistent}{semantic_net}->{ $obj_2 }->{facts} },
##    $new_fact;

#my $obj_3 = strip_to_base_word( lc $fact->[2] );
#$obj_3 =~ s/[_\s]+/ /igm;
#fill_out_in_semantic_net( $obj_3, $object_ref );

##push @{ $data->{persistent}{semantic_net}->{ $obj_3 }->{facts} },
##    $new_fact;
#$obj_3 =~ s/^\s+//igm;
#$obj_3 =~ s/\s+$//igm;
#fill_out_in_semantic_net( $obj_3, $object_ref );

##push @{ $data->{persistent}{semantic_net}->{ $obj_3 }->{facts} },
##    $new_fact;

#@words = split /\s+/, strip_to_base_word( $obj_3 );
#@words_relevant = grep {
#$_
#!~ /^(ein|der|die|das|den|dem|des|ein|eine|einer|einen|einem|eines|kein|keine|keinen|keines|keiner|a|an|the)(\s|$)/i
#&& !$data->{lang}{is_time_measurement}{$_}
#} @words;
#if ( scalar @words_relevant > 1
#&& $words_relevant[-1] =~ /^[_].*?[_]$/ )
#{
#pop @words_relevant;
#pop @words;
#}

#fill_out_in_semantic_net( ( join ' ', @words ), $object_ref );

##push @{ $data->{persistent}{semantic_net}->{ join ' ', @words }->{facts} },
##    $new_fact;
#foreach
#my $word ( scalar @words_relevant >= 2 && @words_relevant )
#{
#fill_out_in_semantic_net($word);
#my $value_word = $data->{persistent}{semantic_net}->{$word};
#push @{ $value_word->{facts} }, $new_fact;
#$data->{persistent}{semantic_net}->{$word} = $value_word;
#}
#fill_out_in_semantic_net( ( join ' ', @words_relevant ),
#$object_ref );

##push @{ $data->{persistent}{semantic_net}->{ join ' ', @words_relevant }->{facts} },
##    $new_fact;

#push @all_facts, $new_fact
#if $data->{lang}{is_in_something_hash}{ lc $fact->[2] }
#|| $data->{lang}{is_in_something_hash}{ lc $fact->[1] };
#}

#}

##my $value_word = $data->{persistent}{semantic_net}->{ $word };
##push @{ $value_word->{facts} }, $new_fact;
##$data->{persistent}{semantic_net}->{ $word } = $value_word;

#foreach my $subj ( join '', ('a' .. 'h') ) {
#fill_out_in_semantic_net($subj);
#my $value_word = $data->{persistent}{semantic_net}->{$subj};
#push @{ $value_word->{'facts_variables'} }, @all_facts;
#$data->{persistent}{semantic_net}->{$subj} = $value_word;
#}

#say 'scalar keys(%$data->{persistent}{semantic_net}): ', scalar keys(%$data->{persistent}{semantic_net});

#delete $data->{persistent}{semantic_net}->{''};

#print $CLIENT 'PERCENT:', 0, "\n" if !eof($CLIENT);

#if ( !$data->{intern}{in_cgi_mode} ) {
#dump_semantic_net( $CLIENT_ref, $data->{persistent}{semantic_net} );
#}

##if ( $data->{modes}{use_sql} ) {
##say 'tieing again...';
##my ${persistent}{semantic_net}_newer = {};
##%$data->{persistent}{semantic_net}_newer = %$data->{persistent}{semantic_net};

##say 'scalar keys(%$data->{persistent}{semantic_net}): ', scalar grep { defined } values(%$data->{persistent}{semantic_net}_newer);
##tie_semantic_net();

##my ( $key, $value );
##while ( ( ( $key, $value ) = each %$data->{persistent}{semantic_net}_newer ) || (( say Dumper [ $key, $value ] ) && 0) ) {
##$data->{persistent}{semantic_net}->{$key} = $value;
##}
##say 'tied again!';
##say 'scalar keys(%$data->{persistent}{semantic_net}): ', scalar keys(%$data->{persistent}{semantic_net});
##}

#say Dumper $data->{persistent}{semantic_net}->{''};
#}

#sub cgi_fill_out_in_semantic_net {
#my ($name) = @_;

#mkdir $data->{intern}{dir} . '/cache_semantic_net/' . substr( $name,      0, 2 )
#if !-d $data->{intern}{dir} . '/cache_semantic_net/' . substr( $name, 0, 2 );

##    open my $file, '>', $data->{intern}{dir} . '/cache_semantic_net/' . $name . '/name';
##    print $file $name or say( 'Cannot write to: ', $data->{intern}{dir} . '/cache_semantic_net/' . $name . '/name' );
##    close $file;
##    open my $file, '>>', $data->{intern}{dir} . '/cache_semantic_net/' . $name . '/facts';
##    close $file;
##    open my $file, '>>', $data->{intern}{dir} . '/cache_semantic_net/' . $name . '/facts_variables';
##    close $file;
#}

#sub append_on_file {
#my ( $file_str, $ref ) = @_;

##mkdir $data->{intern}{dir} . '/cache_semantic_net/' . $name . '/facts';
#open my $file, '>>', $file_str;

##say( $!, $file_str ) if $!;
#print $file "\n---\n";

##say( $!, $file_str ) if $!;
#print $file Dumper $ref;
#close $file;
#}

sub semantic_net_get_key_for_item {
    my (
        $synonym,     # key
        $key_type,    # "facts" or "facts_synonyms"

    ) = @_;

    if ( $key_type =~ /nothing/ ) {
        return ( [] );
    }

    #print '$synonym: ', Dumper $synonym;

    if ( $key_type eq 'facts' ) {
        if ( ref($synonym) eq 'ARRAY' ) {
            my $r = semantic_network_get_by_key( 'keys' => $synonym );

            return $r;
        }
        my $r = semantic_network_get_by_key( key => $synonym );
        return $r;
    }

    return ( [] );
}

sub semantic_net_get_variable_dialog_features {
    if ( 0 && $data->{intern}{in_cgi_mode} ) {
        return semantic_net_get_key_for_item( '_answers', 'facts' );
    }
    else {
        return semantic_network_get_smalltalk();
    }

}

sub dump_semantic_net {
    my ($CLIENT_ref) = @_;
    my $CLIENT = $$CLIENT_ref;

    my $ok = mkdir $data->{intern}{dir} . "/semantic_net_doc";

    if ( !$ok ) {
        say 'Cannot create directory "'
          . $data->{intern}{dir}
          . "/semantic_net_doc\": $!";
        return;
    }

    my $css = << "    EOT";
    
    <style type="text/css">
    .semtable td, .semtable th {
        border: 1px solid silver;
        padding: 5px;
    }
    .semtable th {
        background-color: grey;
        color: white;
    }
    .semtable {
        border-collapse: collapse;
    }
    
    body {
    	font-family: "Nimbus Sans L", Helvetica, Arial, "Nimbus Sans L Regular", sans-serif !important;
    	font-size: 0.8em !important;
    	line-height:1.8em !important;
    	text-align:left !important;
    	line-height: 25px !important;
    }
    
    td, th {
        border: 1px silver solid !important;
        padding: 2px;
    }
    
    h1 {
        font-size: 1.3em;
    }
    
    </style>
    
    EOT

    my $footnote = << "    EOT";
    
    by $data->{intern}{NAME}, Copyright 2006 - 2008. This semantic network is available under the terms of the GNU General Public License 3, or any later version.
    
    EOT

    my $logo_str = << "    EOT";
    <div align="left" style="clear: right; float: right;">
        <img src="freehal.gif" alt="FreeHAL" />
    </div>
    
    EOT

    open my $index_file, '>',
      $data->{intern}{dir} . "/semantic_net_doc/index.html";

    print $index_file
      '<html><head><title>FreeHAL\'s semantic network - Items</title>';
    print $index_file '</head><body>';
    print $index_file $css;
    print $index_file $logo_str;
    print $index_file '<h1>Items</h1>';

    #my part_of_speech_get_memory()_backup = {};
    #if ( $data->{intern}{in_cgi_mode} ) {
    #part_of_speech_get_memory()_backup = {%{part_of_speech_get_memory()}};

#my $from_yaml_temp =
#pos_file_read( $data->{intern}{dir} . 'lang_' . LANGUAGE() . '/word_types.brain' );

    #%{part_of_speech_get_memory()} = (%{part_of_speech_get_memory()},
    #(
    #defined $from_yaml_temp->[0]
    #? $from_yaml_temp->[0]
    #: {}
    #))
    #;
    #}

    semantic_network_connect(
        dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
        config => \%config
    );

    my $count_of_facts = semantic_network_get_count_of_facts();

    my $i = 0;
    foreach my $record ( sort { $a->[0] cmp $b->[0] }
        @{ semantic_network_get_by_key() } )
    {

        $i += 1;
        print $CLIENT 'PERCENT:', ( 100 * $i / $count_of_facts ), "\n"
          if !eof($CLIENT) && $i % 100 == 0;

        my $thing = $record->[0];

        next if $data->{lang}{is_something}{$thing};
        next if $thing =~ /^[=][>]/;
        next if $thing eq 'nothing';

        $thing =~ s/^\s+//igm;
        $thing =~ s/\s+$//igm;

        print $index_file "<a href='$thing.html'>"
          . ucfirst $thing
          . "</a><br />";

        open my $html_file, '>',
          $data->{intern}{dir} . "/semantic_net_doc/" . $thing . ".html";

        print $html_file '<html><head><title>FreeHAL\'s semantic network - '
          . $thing
          . '</title>';
        print $html_file '</head><body>';
        print $html_file $css;
        print $html_file $logo_str;
        print $html_file "<h1>$thing</h1>\n";
        print $html_file "<a href=\"index.html\">back to index</a>\n";
        print $html_file "<h4>Connections</h4>\n";

        print $html_file "<table class='semtable'>";
        print $html_file
"<tr><th>subject</th><th>verb</th><th>object</th><th>adverbs</th><th>whole sentence</th></tr>";

        #say $thing;
        my @lines = ();
        foreach my $fact ( @{ $record->[1] } ) {

            my $line = q{};    # empty
            $line .= "<tr>";

            $line .=
                "<td><a href='"
              . ( $fact->[1] )
              . ".html'>"
              . ( $fact->[1] )
              . "</a></td>";
            $line .= "<td>" . ( $fact->[0] ) . "</td>";
            $line .=
                "<td><a href='"
              . ( $fact->[2] )
              . ".html'>"
              . ( $fact->[2] )
              . "</a></td>";
            $line .= "<td>" . ( $fact->[3] ) . "</td>";
            $line .= "<td>" . ( phrase( $CLIENT_ref, @$fact ) ) . "</td>";

            $line .= "</tr>";

            push @lines, $line;
        }
        my %hash_lines = map { $_ => 1 } @lines;
        print $html_file sort keys %hash_lines;

        print $html_file "</table>";
        print $html_file "<br />";
        print $html_file "<a href=\"index.html\">back to index</a>\n";
        print $html_file "<br /><br />";

        print $html_file "<hr />$footnote\n";

        close $html_file;
    }

    print $index_file "<br /><br /><hr />$footnote";

    print $CLIENT 'PERCENT:', 0, "\n" if !eof($CLIENT);

#%{part_of_speech_get_memory()} = %{part_of_speech_get_memory()}_backup if $data->{intern}{in_cgi_mode};

    close $index_file;
}

sub parse_synonyms {
    my $tolerate   = pop;
    my $file       = pop;
    my $CLIENT_ref = pop;
    my $is_initial = shift;
    my ($_facts)   = shift;
    my $CLIENT;
    eval 'my $CLIENT     = $$CLIENT_ref;';
    if ( !$CLIENT ) {
        open $CLIENT, '>>', 'client.log';
        close $CLIENT;
    }

    print "Executing hook 1...\n";

    my $hash_string = q{};    # empty
    eval q{
    	open my $file_handle, '<', $file;
		binmode($file_handle);
		$hash_string = md5_hex((join('',<$file_handle>)));
		close $file_handle;
	};
    say $@ if $@;

    $data->{persistent}{initialized_files} ||= {};
    if (   $data->{persistent}{initialized_files}{$hash_string}
        && $file !~ /facts/
        && !$tolerate )
    {
        say 'already initialized: ', $file, ', ', $hash_string;
        return;
    }
    $data->{persistent}{initialized_files}{$hash_string} = 1;

    #	select undef, undef, undef, 5;

    my $facts;
    eval( '$facts = my ' . Dumper $_facts);
    say $@ if $@;

    say "connecting...";
    if ( $is_initial == 2 && @$facts ) {
        semantic_network_connect(
            dir    => $data->{intern}{dir} . 'lang_' . LANGUAGE(),
            config => \%config
        );
    }
    say "connected!";

    foreach my $parts_ref (@$facts) {
        next if $parts_ref->[0] !~ /[>][>][>]/;

        $data->{persistent}{replace_strings}{ $parts_ref->[1] } =
          $parts_ref->[2]
          if $parts_ref->[2] !~ /nothing/;
        $data->{persistent}{replace_strings}{ $parts_ref->[1] } =
          $parts_ref->[3]
          if $parts_ref->[2] =~ /nothing/;
    }

    foreach my $parts_ref (@$facts) {
        if (   $parts_ref->[0] =~ /(^|\s)(brauch|will)/
            && $parts_ref->[3] =~ /nicht/ )
        {

            my @verbs = grep { !/^(brauch|will)/ }
              split /\s+/, $parts_ref->[0];

            next if !@verbs;

            my @words = split /[_\s]+/, $parts_ref->[2];
            %{ $data->{lang}{is_time_measurement} } =
              map { $_ => 1 } get_time_measurements();
            my @words_relevant = grep {
                $_ !~
/^(ein|der|die|das|den|dem|des|ein|eine|einer|einen|einem|eines|kein|keine|keinen|keines|keiner|a|an|the)(\s|$)/i
                  && !$data->{lang}{is_time_measurement}{$_}
            } @words;
            my $noun = lc join ' ', @words_relevant;

            my $index = $noun . ' ' . join ',', @verbs;

            $data->{persistent}{semantic_net}->{'_is_negative_effect'} ||= {};
            $data->{persistent}{semantic_net}->{'_is_negative_effect'}{$index} =
              1;

            #            print 'negative: ';
            #            say $index;
        }
    }

    foreach my $parts_ref (@$facts) {
        next if $parts_ref->[0] !~ /(reasonof)|([=])/;

        my $type_of_fact =
          ( $parts_ref->[0] =~ /(reasonof)/ )
          ? 'reason'
          : 'is';

        if ( $parts_ref->[2] =~ /nothing/ ) {
            $parts_ref->[2] = $parts_ref->[3];
            $parts_ref->[3] = '';
        }

        # reason
        ( my $reason_str = $parts_ref->[1] ) =~ s/(^[_]+)|([_]+$)//igm;

        # effect
        ( my $effect_str = $parts_ref->[2] ) =~ s/(^[_]+)|([_]+$)//igm;

        my @reason      = split /[_]/, $reason_str;
        my $reason_verb = pop @reason;
        my $reason_noun = join ' ', @reason;
        my $reason_adv  = q{};

        #if ( pos_of( $CLIENT_ref,
        #$reason_noun,
        #0,
        #1,
        #0,
        #$reason_noun,
        #0 ) == $data->{const}{ADJ} ) {

        if (
            (
                $data->{lang}{string_to_constant}{
                    part_of_speech_get_memory()->{ lc $reason_verb }->{type}
                      || ''
                }
                || 0
            ) != $data->{const}{VERB}
          )
        {
            next;
        }

        if (
            $data->{lang}{string_to_constant}{
                part_of_speech_get_memory()->{ ucfirst $reason_noun }->{type}
                  || ''
            }
            || 0 == $data->{const}{ADJ}
            || $data->{lang}{string_to_constant}
            { part_of_speech_get_memory()->{ lc $reason_noun }->{type} || '' }
            || 0 == $data->{const}{ADJ}
          )
        {

            $reason_adv  = $reason_noun;
            $reason_noun = q{nothing};
        }

        my @effect      = split /[_]/, $effect_str;
        my $effect_verb = pop @effect;
        my $effect_noun = join ' ', @effect;
        my $effect_adv  = q{};
        if (
            $data->{lang}{string_to_constant}{
                part_of_speech_get_memory()->{ ucfirst $effect_noun }->{type}
                  || ''
            }
            || 0 == $data->{const}{ADJ}
            || $data->{lang}{string_to_constant}
            { part_of_speech_get_memory()->{ lc $effect_noun }->{type} || '' }
            || 0 == $data->{const}{ADJ}
          )
        {

            $effect_adv  = $effect_noun;
            $effect_noun = q{nothing};
        }

        ##say;
        ##say 'reason verb: ', $reason_verb;
        ##say 'reason noun: ', $reason_noun;
        ##say 'reason adv:  ', $reason_adv;
        ##say 'effect verb: ', $effect_verb;
        ##say 'effect noun: ', $effect_noun;
        ##say 'effect adv:  ', $effect_adv;
        ##say;

        semantic_network_execute_sql(
            qq{
        		INSERT 
        	}
              . (
                semantic_network_get_sql_database_type() eq 'sqlite'
                ? ' OR '
                : ''
              )
              . qq{ IGNORE INTO reason_effect
        		(
        			reason_verb, reason_noun, reason_adv,
        			effect_verb, effect_noun, effect_adv
        		)
        		VALUES (
                    "$reason_verb",
        			"$reason_noun",
                    "$reason_adv",
                    "$effect_verb",
                	"$effect_noun",
                    "$effect_adv"
        		);
			}
        );

        #push @{ $data->{persistent}{semantic_net}->{'_reason_effect'} },
        #{
        #reason => {
        #noun => $reason_noun,
        #verb => $reason_verb,
        #adv => $reason_adv,
        #},
        #effect => {
        #noun => $effect_noun,
        #verb => $effect_verb,
        #adv => $effect_adv,
        #},
        #};

        semantic_network_put(
            fact => [
                $effect_verb,
                'd',
                $effect_noun,
                $effect_adv,
                [
                    [
                        $reason_verb,
                        'd',
                        $reason_noun,
                        $reason_adv,
                        LANGUAGE() eq 'de'
                        ? (
                            $type_of_fact eq 'reason'
                            ? 'weil'
                            : 'wenn'
                          )
                        : (
                            $type_of_fact eq 'reason'
                            ? 'because'
                            : 'if'
                        ),
                    ],
                ],
                50
            ],
            execute_hooks      => 0,
            optional_hook_args => [$CLIENT_ref]
        );

        ### it is an IS fact ###

        if ( $type_of_fact eq 'is' ) {

            semantic_network_execute_sql(
                qq{
					INSERT
        	}
                  . (
                    semantic_network_get_sql_database_type() eq 'sqlite'
                    ? ' OR '
                    : ''
                  )
                  . qq{  IGNORE INTO reason_effect
					(
						reason_verb, reason_noun, reason_adv,
						effect_verb, effect_noun, effect_adv
					)
					VALUES (
						"$reason_verb",
						"$reason_noun",
						"$reason_adv",
						"$effect_verb",
						"$effect_noun",
						"$effect_adv"
					);
				}
            );

            #push @{ $data->{persistent}{semantic_net}->{'_reason_effect'} },
            #{
            #reason => {
            #noun => $effect_noun,
            #verb => $effect_verb,
            #adv => $effect_adv,
            #},
            #effect => {
            #noun => $reason_noun,
            #verb => $reason_verb,
            #adv => $reason_adv,
            #},
            #};

            semantic_network_put(
                fact => [
                    $reason_verb,
                    'd',
                    $reason_noun || 'e',
                    $reason_adv,
                    [
                        [
                            $effect_verb,
                            'd',
                            $effect_noun || 'e',
                            $effect_adv,
                            LANGUAGE() eq 'de'
                            ? (
                                $type_of_fact eq 'reason'
                                ? 'weil'
                                : 'wenn'
                              )
                            : (
                                $type_of_fact eq 'reason'
                                ? 'because'
                                : 'if'
                            ),
                        ],
                    ],
                    50
                ],
                execute_hooks      => 0,
                optional_hook_args => [$CLIENT_ref]
            );

            semantic_network_put(
                fact => [
                    $reason_verb,
                    'd',
                    $reason_noun || 'nothing',
                    $reason_adv,
                    [
                        [
                            $effect_verb,
                            'd',
                            $effect_noun || 'nothing',
                            $effect_adv,
                            LANGUAGE() eq 'de'
                            ? (
                                $type_of_fact eq 'reason'
                                ? 'weil'
                                : 'wenn'
                              )
                            : (
                                $type_of_fact eq 'reason'
                                ? 'because'
                                : 'if'
                            ),
                        ],
                    ],
                    50
                ],
                execute_hooks      => 0,
                optional_hook_args => [$CLIENT_ref]
            );
        }

        ### it is a fact that explains a reason of something ###

        elsif ( $type_of_fact eq 'reason' ) {
            semantic_network_put(
                fact => [
                    $reason_verb,
                    'd',
                    $reason_noun || 'nothing',
                    $reason_adv,
                    [
                        [
                            'f=> sollte ' . $effect_verb, 'd',
                            $effect_noun || 'nothing', $effect_adv,
                            '',
                        ],
                    ],
                    50
                ],
                execute_hooks      => 0,
                optional_hook_args => [$CLIENT_ref]
            );
        }
    }

    my $i = 0;

  FACT:
    foreach my $parts_ref (@$_facts) {
        $i += 1;
        print $CLIENT 'PERCENT:', ( 100 * $i / scalar @$facts ), "\n"
          if !eof($CLIENT) && $i % 300 == 0;

        next if $parts_ref->[0] !~ /^sein$/;

        $parts_ref->[0] = '=';

        #my @words;
        #@words = split /[_\s]/, $parts_ref->[1];
        #if ( pos_of( $CLIENT_ref,
        #$words[-1],
        #0,
        #1,
        #0,
        #$words[-1],
        #0 ) == $data->{const}{VERB} ) {
        #next FACT;
        #}
        #@words = split /[_\s]/, $parts_ref->[2];
        #if ( pos_of( $CLIENT_ref,
        #$words[-1],
        #0,
        #1,
        #0,
        #$words[-1],
        #0 ) == $data->{const}{VERB} ) {
        #next FACT;
        #}

        if ( LANGUAGE() eq 'de' ) {

            # form
            #	A = B
            # to
            #	A ist ein anderes Wort fuer B

            my $genus_1 =
                 part_of_speech_get_memory()->{ $parts_ref->[1] }->{genus}
              || part_of_speech_get_memory()->{ ucfirst $parts_ref->[1] }
              ->{genus}
              || 'q';
            my $genus_2 =
                 part_of_speech_get_memory()->{ $parts_ref->[2] }->{genus}
              || part_of_speech_get_memory()->{ ucfirst $parts_ref->[2] }
              ->{genus}
              || 'q';

            semantic_network_put(
                fact => [
                    'ist',
                    (
                          $genus_1 eq 'm' ? 'ein ' . $parts_ref->[1]
                        : $genus_1 eq 'f' ? 'eine ' . $parts_ref->[1]
                        : $parts_ref->[1]
                    ),
                    (
                          $genus_2 eq 'm' ? 'ein ' . $parts_ref->[2]
                        : $genus_2 eq 'f' ? 'eine ' . $parts_ref->[2]
                        : $parts_ref->[2]
                    ),
                    '',
                    [],
                    50
                ],
                execute_hooks      => 0,
                optional_hook_args => [$CLIENT_ref]
            );
        }

        else {

            # form
            #	A = B
            # to
            #	A ist ein anderes Wort fuer B

            semantic_network_put(
                fact => [
                    'is',
                    'a ' . $parts_ref->[1],
                    'a ' . $parts_ref->[2],
                    '', [], 50
                ]
            );
        }
    }

    %{ $data->{lang}{is_acceptable_verb} } = (
        "bin"  => 1,
        "bist" => 1,
        "ist"  => 1,
        "sind" => 1,
        "seid" => 1,
        "be"   => 1,
        "am"   => 1,
        "are"  => 1,
        "is"   => 1,
    );

    if ( $file !~ /thesaurus/ ) {
        $i = 0;
        foreach my $parts_ref (@$facts) {
            $i += 1;
            print $CLIENT 'PERCENT:', ( 100 * $i / scalar @$facts ), "\n"
              if !eof($CLIENT) && $i % 300 == 0;

            my @parts = @$parts_ref;
            $parts[1] = strip_to_base_word( $parts[1] );
            $parts[2] = strip_to_base_word( $parts[2] );
            my ( $subj, $verb, $obj ) = ( $parts[1], $parts[0], $parts[2] );

            $parts[3] =~ s/nothing//igm;
            next if $parts[3];

            #			say Dumper @parts;

            if (
                $data->{lang}{is_acceptable_verb}{ $data->{const}{VERB} }
                && ( $subj . ' ' . $obj ) !~
/(^|_|\s)(es|er|sie|ihn|ihm|dir|mir|mich|dich|i|you)(\s|_|[;]|$)/i
                && ($obj) !~ /(^|_|\s)(ich|du|i|you)(\s|_|[;]|$)/i
                && ($obj) !~ /(_|\s)(das)(\s|_|[;]|$)/i
                && length $obj
                && length $subj
                && ( join ' ', @parts ) !~
                /((^|[_\s])(nicht|not)([_\s]|$))|(kein[_\s])/i
                && (
                    $obj !~ /^(ein|eine|a|an)\s+/i
                    || (   $obj =~ /^(ein|eine|a|an)\s+/i
                        && $subj =~ /^(ein|eine|a|an)\s+/i )
                )
                && $parts[3] !~ /(^|\s|[_])von(\s|[_]|$)/
              )
            {

                if ( ( $subj . $obj ) =~ /(^|\s)mei[\-~] nam[\-~]/ ) {
                    print "i am here (1)\n", ( join ' ', @parts ), "\n";
                }

                $subj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;
                $obj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;

                my $tmp1 = $data->{persistent}{noun_synonym_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }
                push @$tmp1, $obj;

                $data->{persistent}{noun_synonym_of}{$subj} = $tmp1;
                $subj =~ s/\s/_/igm;
                my $tmp1 = $data->{persistent}{noun_synonym_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }
                push @$tmp1, $obj;

                $data->{persistent}{noun_synonym_of}{$subj} = $tmp1;
            }

            @parts    = @$parts_ref;
            $parts[1] = strip_to_base_word( $parts[1] );
            $parts[2] = strip_to_base_word( $parts[2] );
            ( $subj, $data->{const}{VERB}, $obj ) =
              ( $parts[1], $parts[0], $parts[2] );

            if (
                $data->{lang}{is_acceptable_verb}{ $data->{const}{VERB} }
                && ( $subj . ' ' . $obj ) !~
/(^|_|\s)(es|er|sie|ihn|ihm|dir|mir|mich|dich|i|you)(\s|_|[;]|$)/i

                #&& ($obj) !~ /(^|_|\s)(ich|du|i|you)(\s|_|[;]|$)/i
                && ($obj) !~ /(_|\s)(das)(\s|_|[;]|$)/i
                && length $obj
                && length $subj
                && ( join ' ', @parts ) =~
                /((^|[_\s])(nicht|not)([_\s]|$))|(kein[_\s])/i
                && (
                    $obj !~ /^(ein|eine|a|an)\s+/i
                    || (   $obj =~ /^(ein|eine|a|an)\s+/i
                        && $subj =~ /^(ein|eine|a|an)\s+/i )
                )
                && $parts[3] !~ /(^|\s|[_])von(\s|[_]|$)/
              )
            {

                if ( ( $subj . $obj ) =~ /(^|\s)mei[\-~] nam[\-~]/ ) {
                    print "i am here (5)\n", ( join ' ', @parts ), "\n";
                }

                $subj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;
                $obj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;

                my $tmp1 = $data->{persistent}{no_noun_synonym_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = {};
                }
                $tmp1->{$obj} = 1;

                $data->{persistent}{no_noun_synonym_of}{$subj} = $tmp1;
                $subj =~ s/\s/_/igm;
                my $tmp1 = $data->{persistent}{no_noun_synonym_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = {};
                }
                $tmp1->{$obj} = 1;

                $data->{persistent}{no_noun_synonym_of}{$subj} = $tmp1;
            }

            @parts    = @$parts_ref;
            $parts[1] = strip_to_base_word( $parts[1] );
            $parts[2] = strip_to_base_word( $parts[2] );
            ( $subj, $data->{const}{VERB}, $obj ) =
              ( $parts[1], $parts[0], $parts[2] );

            if ( $obj =~ /^(ein|eine|a|an)\s+/i ) {

                #			say 1;
                ( $obj, $data->{const}{VERB}, $subj ) =
                  ( $parts[1], $parts[0], $parts[2] );
            }

            if (
                $data->{lang}{is_acceptable_verb}{ $data->{const}{VERB} }
                && ( $subj . ' ' . $obj ) !~
/(^|_|\s)(es|er|sie|ihn|ihm|dir|mir|mich|dich|i|you)(\s|_|[;]|$)/i

                #&& ($obj) !~ /(^|_|\s)(ich|du|i|you)(\s|_|[;]|$)/i
                && ($obj) !~ /(_|\s)(das)(\s|_|[;]|$)/i
                && length $obj
                && length $subj
                && ( join ' ', @parts ) !~
                /((^|[_\s])(nicht|not)([_\s]|$))|(kein[_\s])/i
              )
            {

                if ( ( $subj . $obj ) =~ /(^|\s)mei[\-~] nam[\-~]/ ) {
                    print "i am here (2)\n", ( join ' ', @parts ), "\n";
                }

                $subj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;
                $obj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;

                my $tmp1 = $data->{persistent}{example_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }

                push @$tmp1, $obj;

                $data->{persistent}{example_of}{$subj} = $tmp1;
                $subj =~ s/\s/_/igm;
                my $tmp1 = $data->{persistent}{example_of}{$subj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }

                push @$tmp1, $obj;

                $data->{persistent}{example_of}{$subj} = $tmp1;
            }

            @parts    = @$parts_ref;
            $parts[1] = strip_to_base_word( $parts[1] );
            $parts[2] = strip_to_base_word( $parts[2] );
            ( $subj, $data->{const}{VERB}, $obj ) =
              ( $parts[1], $parts[0], $parts[2] );

            if ( $obj =~ /^(ein|eine|a|an)\s+/i ) {

                #			say 1;
                ( $obj, $data->{const}{VERB}, $subj ) =
                  ( $parts[1], $parts[0], $parts[2] );
            }

            if (
                $data->{lang}{is_acceptable_verb}{ $data->{const}{VERB} }
                && ( $subj . ' ' . $obj ) !~
/(^|_|\s)(es|er|sie|ihn|ihm|dir|mir|mich|dich|i|you)(\s|_|[;]|$)/i

                #&& ($obj) !~ /(^|_|\s)(ich|du|i|you)(\s|_|[;]|$)/i
                && ($obj) !~ /(_|\s)(das)(\s|_|[;]|$)/i
                && length $obj
                && length $subj
                && ( join ' ', @parts ) !~
                /((^|[_\s])(nicht|not)([_\s]|$))|(kein[_\s])/i
              )
            {

                if ( ( $subj . $obj ) =~ /(^|\s)mei[\-~] nam[\-~]/ ) {
                    print "i am here (3)\n", ( join ' ', @parts ), "\n";
                }

                $subj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;
                $obj =~
s/^(der|die|das|den|des|dem|den|ein|eine|kein|keine|keiner|keinen|keinem|keines|einer|einem|eines|a|an|the) //igm;

                my $tmp1 = $data->{persistent}{example_of}{$obj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }

                push @$tmp1, $subj;

                $data->{persistent}{example_of}{$obj} = $tmp1;
                $subj =~ s/\s/_/igm;
                my $tmp1 = $data->{persistent}{example_of}{$obj};
                if ( !$tmp1 ) {
                    $tmp1 = [];
                }

                push @$tmp1, $subj;

                $data->{persistent}{example_of}{$obj} = $tmp1;
            }
        }
    }

    return 1;
}


sub detect_pos_from_string {
    my ( $CLIENT_ref, $line, $at_beginning ) = @_;
    $line = lc $line;

    say $line;

    return $data->{const}{PREP}  if $line =~ /position/i;
    return $data->{const}{NOUN}  if $line =~ /igennam/i;
    return $data->{const}{NOUN}  if $line =~ /ubstan/i;
    return $data->{const}{NOUN}  if $line =~ /pronomen/i;
    return $data->{const}{NOUN}  if $line =~ /nomen/i;
    return $data->{const}{INTER} if $line =~ /interjektion/i;
    return $data->{const}{ADJ}   if $line =~ /adv/i;
    return $data->{const}{VERB}  if $line =~ /verb/i;
    return $data->{const}{ADJ}   if $line =~ /adj/i;
    return $data->{const}{NO_POS};
}

sub load_news {
    my $CLIENT_ref = pop;
    my $CLIENT     = $$CLIENT_ref;

    if ( LANGUAGE() ne 'de' ) {
        return;
    }

    if ( $data->{intern}{in_cgi_mode} ) {
        return;
    }

    # first define a pro file
    my $file =
      $data->{intern}{dir} . "/lang_" . LANGUAGE() . '/actual_news.pro';
    unlink $file or say 'CANNOT UNLINK: ', $file, $!;

    if ( $config{'features'}{'download_news'} && !$data->{modes}{batch} ) {

        open my $news_pro_file, '>', $file
          or ( print "Cannot open news file: ", $file, "\n" and return );

        my @prot_resources =
          ( "http://resources.freehal.org/resources/get/news.pl", );

        foreach my $resource (@prot_resources) {
            $ua->timeout(5);
            my $res = $ua->get($resource);
            my $pro = $res->content;

            print $resource;
            print $pro;
            print {$news_pro_file} $pro;
        }

        close $news_pro_file;

        return;
    }

    if ( $config{'features'}{'news'} == 0 && !$data->{modes}{batch} ) {
        return;
    }

    if ($CLIENT) {
        my $display_text = 'Lade aktuelle Nachrichten aus dem Internet...<br>';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }

    say "1a";

    # then add a 't' to make a prot file (pro template)
    my $pro_file = $file;
    $file .= 't';
    say "1b";
    open my $news_prot_file, '>', $file
      or print "Cannot open news file: ", $file, "\n" and return;

    say "1c";
    use utf8;
    say "1d";

    my @rss = (

        # currently disabled because of crash bug under Windows

      #    "http://derstandard.at/?page=rss&ressort=Wissenschaft",
      #    "http://www.faz.net/s/Rub/Tpl~Epartner~SRss_~Ahomepageticker~E1.xml",
      #    "http://www.sueddeutsche.de/app/service/rss/alles/rss.xml",
      #    "http://news.google.de/?ned=de&topic=n&output=rss",
    );

    say "1e";

    foreach my $feed (@rss) {
        say "1f";
        eval {
            local $SIG{__DIE__};
            $ua->timeout(5);
            say "1g";
            my $res = $ua->get($feed);
            my $xml = $res->content;
            say "1h";

            $xml =~ s/[<][!]\[CDATA\[//igm;
            $xml =~ s/\]\][>]//igm;
            $xml =~ s/[<][ap][^><]*?[>]//igm;
            $xml =~ s/[<]\/[ap][^><]*?[>]//igm;

            my $rp;
            say "1i";
            eval q{
                $rp = new XML::RSS::Parser::Lite;
                $rp->parse($xml);
            };
            say "1j";
            if ( ( !$rp || $@ ) && !$rp->count() ) {
                eval q{
                    $xml = get($feed);
                    $xml =~ s/[<][!]\[CDATA\[//igm;
                    $xml =~ s/\]\][>]//igm;
                    $xml =~ s/[<][ap][^><]*?[>]//igm;
                    $xml =~ s/[<]\/[ap][^><]*?[>]//igm;
                    $rp = new XML::RSS::Parser::Lite;
                    $rp->parse($xml);
                };
            }
            else {
                $@ = q{};
            }
            say "1k";
            if ( ( !$rp || $@ ) && !$rp->count() ) {
                print 'invalid feed: ', $feed, ' - ', ( $@ || q{} ), "\n";
                print "\n";
                print $xml;
                print "\n";
            }

            say "1l";
            for (
                my $i = 0 ;
                $i < $rp->count() && $i < 600 && $rp->get($i) ;
                $i++
              )
            {
                my $it = $rp->get($i);
                say "1m";
                my $descr = $it->get('description');
                say "1n";

                $descr =~ s/[&]lt[;]/</gm;
                $descr =~ s/[&]gt[;]/>/gm;
                $descr =~ s/[&]amp[;]/&/gm;
                $descr =~ s/[&]nbsp[;]/ /gm;
                $descr =~ s/mehr\.\.\./ /gm;
                $descr =~ s/[<][!].+?[<]/</igm;
                $descr =~ s/[<][!]\[CDATA\[//igm;
                $descr =~ s/.*?font size=-1/</igm;
                $descr =~ s/[<][^><]*?[>]//igm;
                $descr =~ s/[<]+?//igm;
                $descr =~ s/^\s+/ /gm;
                if ( lc($^O) !~ /win/ ) {
                    my $chr1 = chr(8220);
                    $descr =~ s/$chr1/"/gm;
                    my $chr2 = chr(8220);
                    $descr =~ s/$chr2/"/gm;
                    $descr =~ s/\u8220/"/gm;
                    $descr =~ s/\u8222/"/gm;
                    $descr =~ s/\x{8220}/"/gm;
                    $descr =~ s/\x{8222}/"/gm;
                }
                $descr =~ s/^[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~
                  s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~
                  s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~
                  s/^[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s[a-zA-Z0-9]+?\s-\s?$/$1/gm;
                $descr =~ s/^(.*?) \- .*?$/$1/gm;
                $descr =~ s/^(.+?)[.]\s.*?$/$1/igm;
                $descr =~ s/^.*?[:]\s(.+?)$/$1/igm;
                $descr =~ s/\s*?-\s*?/_/igm;
                say "1p";
                print '    News: ', $descr, "\n";
                say "1q";
                $descr = ascii($descr);
                say "1r";
                my @sentences = split /\s*?-\s*?/, $descr;

#				print 'Title: ' . $it->get('title') . "\nURL: " . $it->get('url') . "\nDescription: " .
# $descr . "\n\n";

                print '--> News: ', join( '; ', @sentences ), "\n";
                print {$news_prot_file} join( "\n", @sentences ), "\n";
            }
        };
        if ($@) {
            say $@;
        }
    }

    say "1z";

    use LWP::Simple;

    my $xml = get("http://resources.freehal.org/resources/get/new-prot.pl");

    #my $xml = $res->content;
    print {$news_prot_file} $xml;

    foreach my $j ( 0 .. 4 ) {
        $ua->timeout(5);

        my $wikipedia =
          $ua->get("http://de.wikipedia.org/wiki/Spezial:Zuf%C3%A4llige_Seite")
          ->content;
        $wikipedia = join( "\n", clean_html_website($wikipedia) );
        print $wikipedia;
        print {$news_prot_file} $wikipedia;
    }

    if ( $config{'features'}{'news'} == 2 ) {
        open my $file_handle, '>', $pro_file;
        close $file_handle;
    }

    close $news_prot_file;
}

sub clean_html_website {
    my ($html) = @_;
    $html =~ s/[<](\/?)(a|b|u|strong|i|big|small|span)[^>]*?[>]//igm;
    $html =~
s/[<](script|style|title)[^>]*?[>][^<]*?[<]\/(script|style|title)[^>]*?[>]//igm;
    $html =~
s/[<]div[^>]+?(menu|bar|side|nav|title|script)[^>]*?[>].*?[<]\/div[>]//igm;
    $html =~
s/[<][^>]+?(menu|bar|side|nav|title|script)[^>]*?[>][^<]*?[<][^>]*?[>]//igm;
    $html =~ s/\n|\r//igm;
    $html =~ s/[<](p|div|br)[^>]*?[>]//igm;
    $html =~ s/[<][^>]+?[>]/\n/igm;

    $html =~ s/&auml;/ae/igm;
    $html =~ s/&uuml;/ue/igm;
    $html =~ s/&ouml;/oe/igm;
    $html =~ s/&Auml;/Ae/igm;
    $html =~ s/&Uuml;/Ue/igm;
    $html =~ s/&Ouml;/Oe/igm;
    $html =~ s/&amp;/&/igm;
    $html =~ s/&szlig;/ss/igm;
    $html =~ s/&nbsp;/ /igm;
    $html =~ s/&[a-zA-z]+?;//igm;
    $html =~ s/&[#][0-9]+?;//igm;

    $html =~ s/[(].+?[)]/ /igm;

    $html =~ s/(\d)\s\-\s(\d)/$1-$2/igm;
    $html =~ s/(\d)[)]/\n/igm;
    $html =~ s/(\d).[)]/\n/igm;
    $html =~ s/(\.|\s)([a-z])[)]/\n/igm;
    $html =~ s/(\.|\s)([a-z]).[)]/\n/igm;

    my @items = split /\n|\r|[=*:]|(\s\-\s)|([!.]-)/, $html;
    @items = grep { $_ } @items;
    @items = grep { length($_) > 10 } @items;
    @items = grep {
        ( grep { length($_) > 5 } split( /\s/, $_ ) ) >= 5
    } @items;
    @items = grep { !/on line/ } @items;
    @items = grep { !/[|]/ } @items;
    map { s/^\s+//gm } @items;
    map { s/\s+$//gm } @items;
    map { s/\s+/ /gm } @items;

    @items = map {
        my $sent_everything = $_;
        $sent_everything =~ s/([.?!])[.?!]+/$1/igm;
        $sent_everything =~ s/([a-z0-9_\s"'][.?!]+)/$1 DOT/igm;
        $sent_everything =~ s/([!]+)/DOT /igm;
        $sent_everything =~ s/([.?!]+)\sDOT\$/$1\$/gm;
        $sent_everything =~ s/\s(nr)[.?!]+\sDOT/ Nummer /igm;
        $sent_everything =~ s/\s(no)[.?!]+\sDOT/ Number /igm;

        my @sentences = ();

        foreach my $sent ( split /DOT(\s|$)/, $sent_everything ) {
            $sent =~ s/ DOT//gm;
            $sent =~ s/[!.]$//gm;
            $sent =~ s/[!.]\s//gm;
            push @sentences, $sent;
        }

        @sentences
    } @items;

    map { s/ \/ / /gm } @items;
    map { s/\s+/ /gm } @items;
    map { s/(^|\s)([a-zA-Z0-9_]\/[^\s])(\s|$)/$1"$2"$3/gm } @items;

    @items = grep { $_ } @items;
    @items = grep { length($_) > 10 } @items;
    @items = grep {
        ( grep { length($_) > 2 } split( /\s/, $_ ) ) > 4
    } @items;
    @items = grep {
        !/[,]/
          || ( grep { length($_) > 2 } split( /\s/, $_ ) ) >= 5
    } @items;
    @items = grep { !/[.][.][.]/ } @items;
    @items = grep { !/[?]/ } @items;
    @items = grep { !/\s[A-Z]+\s/ } @items;
    @items = grep { !/^,/ } @items;

    return @items;
}

#*AI::Tagger::download_genus = *download_genus;
#*AI::Tagger::download_pos = *download_pos;



sub run_code {
    print "running code:\n", @_;
    eval ''.$_[0];
    die $@ if $@;
    return $@;
}


$SIG{__DIE__} = 'exit_handler';
$SIG{TERM}    = 'exit_handler';
if ( lc($^O) !~ /win/ ) {
    $SIG{TERM} = 'IGNORE';
}
$SIG{INT} = 'exit_handler';

#$SIG{HUP} = 'exit_handler';
$SIG{QUIT} = 'exit_handler';

#$SIG{__KILL__} = sub { kill_all_subprocesses(); say $@; exit(0); };

if ( lc($^O) !~ /win/ ) {

    #$SIG{CHLD} = sub { wait(); };
}

$SIG{CHLD} = 'IGNORE';

#kill_process_from('proxy.pid');

if ($data->{modes}{batch}) {
    open STDOUT, '>', '../output.txt';
    open STDERR, '>', '../output-err.txt';
}

if ( $::start_proxy == 2 && !$data->{modes}{batch} ) {
    my $pid_1 = fork;
    if ( !$pid_1 ) {
        while (1) {
            my $pid_2 = fork;
            if ( !$pid_2 ) {
                select undef, undef, undef, 10;
                select undef, undef, undef, 200 if $data->{modes}{batch};
                require("jeliza-proxy.pl");
                exit(0);
            }
            else {
                waitpid $pid_2, 0;
            }
            select undef, undef, undef, 5;
        }

        exit(0);
    }
}

{
    mkdir 'temp';
    open my $file, '>', 'temp/no-commit';
    print $file $data->{modes}{batch};
    close $file;
}

1;
