#!/usr/bin/perl

use strict;
use feature qw( say );
use IO::All;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use FindBin;
use lib "$FindBin::Bin/../lib";
use FSM::Basic;
use JSON;
use Term::ReadLine;

my %to_subst = (
    __ENPROMPT__ => 'Admin# ',
    __PROMPT__   => 'User> '
);

my $file_def = shift;

my $basename = basename $0 , '.pl';

$file_def = "$FindBin::Bin/$basename.json" if ( -e "$FindBin::Bin/$basename.json" && !$file_def );

my $json = io( $file_def )->slurp;
foreach my $subst ( keys %to_subst )
{
    $json =~ s/$subst/$to_subst{$subst}/g;
}

my $states = from_json( $json );
#say Dumper($states);
my $history_file = glob( '~/.bash.history' );
my $prompt       = '> ';
my $line;
my $term    = new Term::ReadLine 'bash';
my $attribs = $term->Attribs->ornaments( 0 );
$term->using_history();
$term->read_history( $history_file );
$term->clear_signals();
my $fsm = FSM::Basic->new( $states, 'prompt' );
my $final = 0;
my $out = "User> ";

while ( defined( $line = $term->readline( $prompt ) ) )
{
    ( $final, $out ) = $fsm->run( $line );
    $out =~ s/(\N*)$/$1/s;
    $prompt= $1
    print $out;

    $term->write_history( $history_file );
    last if $final;
    #  print $out;
}
