#!/usr/bin/perl

use strict;
use feature qw( say );
use IO::All;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use FindBin;
use JSON;
use Term::ReadLine;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;

my ( $srcip, $srcport, $dstip, $dstport ) = ( split( /\s+/, $ENV{SSH_CONNECTION} ) );
my %to_subst = (
    __ENPROMPT__ => 'Admin# ',
    __PROMPT__   => $srcip . '> '
);

my $basename = basename $0 , '.pl';

my $file_def = "$FindBin::Bin/$basename" . '_' . $srcip . '_' . $dstip . '.json';
$file_def = "$FindBin::Bin/$basename.json" if ( !-f $file_def );
my $json = io( $file_def )->slurp;
foreach my $subst ( keys %to_subst )
{
    $json =~ s/$subst/$to_subst{$subst}/g;
}

my $states       = from_json( $json );
my $history_file = glob( '~/.bash.history' );
my $prompt       = $to_subst{__PROMPT__};
my $line;
my $term    = new Term::ReadLine 'bash';
my $attribs = $term->Attribs->ornaments( 0 );
$term->using_history();
$term->read_history( $history_file );
$term->clear_signals();
my $fsm   = FSM::Basic->new( $states, 'prompt' );
my $final = 0;
my $out   = $prompt;
my $more;

while ( defined( $line = $term->readline( $out ) ) )
{
    ( $final, $out, $more ) = $fsm->run( $line );
  #  say "<$out>";
#    say "more=<$more> lines nbr:".`/usr/bin/tput lines`;
    $term->write_history( $history_file );
    last if $final;
}

