#!/usr/bin/perl

# use to automatically generate the Lingua::StopWords::XX modules.
use lib qw( lib );
use strict;
use Lingua::StopWords;
use Lingua::Stem::Snowball qw( stemmers );
use Encode qw( from_to );
use Text::Wrap qw( wrap );
use Getopt::Long;

# tabs are evil
$Text::Wrap::unexpand = 0;

# snowdir should be the snowball_all directory
my $snowdir;
GetOptions( 'snowdir=s' => \$snowdir );
die "Usage ./bin/gen_modules.plx --snowdir=SNOWDIR"
    unless -d $snowdir;

die "Usage of this script is DEPRECATED."

my $template = <<'END_MODULE';
package Lingua::StopWords::#ISO#;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw( getStopWords ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our $VERSION = #VERSION#;

sub getStopWords {
    if ( @_ and $_[0] eq 'UTF-8' ) {
        # adding U0 causes the result to be flagged as UTF-8
        my %stoplist = map { ( pack("U0a*", $_), 1 ) } qw(
#UTF8#
        );
        return \%stoplist;
    }
    else {
        my %stoplist = map { ( $_, 1 ) } qw(
#PLAIN#
        );
        return \%stoplist;
    }
}

1;
END_MODULE

my %languages = (
    DA => "danish",
    NL => "dutch",
    EN => "english",
    FI => "finnish",
    FR => "french",
    DE => "german",
    HU => "hungarian",
    IT => "italian",
    NO => "norwegian",
    PT => "portuguese",
    RU => "russian",
    ES => "spanish",
    SV => "swedish",
);

while ( my ( $iso, $lang ) = each %languages ) {
    my $file = "$snowdir/algorithms/$lang/stop.txt";
        print STDERR "Generating '$lang' stopword list module\n";

    # extract stoplists from snowball source files; parse
    my @words;
    open( SNOWBALL_STOPFILE, "<", $file )
        or die "Couldn't open file '$file': $!";
    while (<SNOWBALL_STOPFILE>) {
        s/\|.*//g;
        next unless length;
        my @these_words = split;
        s/\s*// for @these_words;
        push @words, @these_words;
    }

    # translate to UTF-8
    my $plain = join(' ', @words);
    $plain = wrap('            ', '            ', @words);
    my $source_enc = $lang eq 'ru' ? 'koi8-r' : 'iso-8859-1';
    from_to($_, $source_enc, 'UTF-8') for @words;
    my $utf8 = join(' ', @words);
    $utf8 = wrap('            ', '            ', @words);

    # sub in the lists
    my $mod = $template;
    $mod =~ s/#VERSION#/$Lingua::StopWords::VERSION/g;
    $mod =~ s/#ISO#/$iso/g;
    $mod =~ s/#PLAIN#/$plain/g;
    $mod =~ s/#UTF8#/$utf8/g;

    # blast it out
    open(F, ">lib/Lingua/StopWords/$iso.pm");
    print F $mod;
    close(F);
}
