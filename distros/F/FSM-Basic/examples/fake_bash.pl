#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename qw(basename);
use FindBin;
use FSM::Basic;
use JSON qw(from_json);
use POSIX qw(strftime tzset);
use Term::ReadLine;
my $DEBUG = 0;
my ( $srcip, $srcport, $dstip, $dstport ) = ( split( /\s+/, $ENV{SSH_CONNECTION} ) );
my $epoch = time;
my $date  = localtime($epoch);

my %to_subst = (
    __ENPROMPT__ => 'Admin#',
    __PROMPT__   => $srcip . '=>' . $dstip . '>',
    __DSTIP__    => $dstip,
    __SRCIP__    => $srcip,
    __DSTPORT__  => $dstport,
    __SRCPORT__  => $srcport,
    __DATE__     => $date,
    __EPOCH__    => $epoch,
);

my $basename = basename $0 , '.pl';
my $debug_file = glob('~/.bash.debug');
my $log_fd;
my $log_level = 0;
my $log_filter;
if ( -f $debug_file ) {
    $DEBUG = 1;
    open( my $debug_fd, $debug_file );
    my $log_file = <$debug_fd>;
    chomp $log_file;
    $log_level = <$debug_fd> // 0;
    chomp $log_level;
    $log_filter = <$debug_fd>;
    chomp $log_filter;
    close $debug_file, open $log_fd, '>>', $log_file;
    select( ( select($log_fd), $| = 1 )[0] );
}

my $file_def = -f $ENV{HOME} . "/$dstip.json" ? $ENV{HOME} . "/$dstip.json" : "$FindBin::Bin/$dstip.json";
my $json = slurp_file($file_def);
$json = subst($json);

my $file_subst = -f $ENV{HOME} . "/subst_rules.json" ? $ENV{HOME} . "/subst_rules.json" : "$FindBin::Bin/subst_rules.json";
if ( -f $file_subst ) {
    my $subst_json  = slurp_file($file_subst);
    my $subst_rules = from_json($subst_json);
    if ( exists $subst_rules->{all} ) {
        foreach my $subst ( keys %{ $subst_rules->{all} } ) {
            $json =~ s/$subst/$subst_rules->{all}{$subst}/g;
        }
    }
    if ( exists $subst_rules->{$dstip} ) {
        foreach my $subst ( keys %{ $subst_rules->{$dstip} } ) {
            $json =~ s/$subst/$subst_rules->{$dstip}{$subst}/g;
        }
    }
}

my $states       = from_json($json);
my $history_file = glob('~/.bash.history');
my $prompt       = $to_subst{__PROMPT__};
my $term         = Term::ReadLine->new('bash');
my $attribs      = $term->Attribs->ornaments(0);
$term->using_history();
$term->read_history($history_file);
$term->clear_signals();
my $fsm = FSM::Basic->new( $states, 'prompt' );
my $final = 0;
my $out;
my $line;

while ( defined( $line = $term->readline($prompt) ) ) {

    ( $final, $out ) = $fsm->run($line);
    if ( $log_filter ) {
        print $log_fd '[' . scalar(localtime) . "] $srcip => $dstip line=<$line> out=<$out> final=<$final> state=<$fsm->{state}> \n" if $DEBUG && ( $log_filter eq $srcip ||$log_filter eq $dstip) ;
    } else{ 
        print $log_fd '[' . scalar(localtime) . "] $srcip => $dstip line=<$line> out=<$out> final=<$final> state=<$fsm->{state}> \n" if $DEBUG;
    }
    if ( $out =~ s/(\N*)$//s ) {
        $prompt = $1;
    }
    $out = subst($out);
    print $out;
    $term->write_history($history_file);
    last if $final;
}

sub slurp_file {
    my ( $file, $chomp ) = @_;
    my $data = do { local ( @ARGV, $/ ) = $file; <> };
    chomp $data if $chomp;
    return wantarray ? split /\n/, $data : $data;
}

sub subst {
    my ($data) = @_;
    print $log_fd "DATA=$data\n" if $log_level > 0;
    while ( $data =~ /(__DATE(\((.*)\))?([+-]?\d+)?__)/mg ) {
        #__DATE5__
        #__DATE+5__
        #__DATE-5__
        #__DATE(%F %H:%M:%S)__
        #__DATE(%F %H:%M:%S)6__
        #__DATE(%F %H:%M:%S)-6__
        my $fmt   = $3 // '';
        my $tag   = $1 // '';
        my $delta = $4 // 0;
        my $new_tag;
        if ($fmt) {
            $new_tag = strftime( $fmt, localtime( $epoch + ( $delta * 86400 ) ) );
        } else {
            $new_tag = localtime( $epoch + ( $delta * 86400 ) );
        }
        $data =~ s/\Q$tag/$new_tag/mg;
    }
    foreach my $subst ( keys %to_subst ) {
        $data =~ s/\Q$subst\E/$to_subst{$subst}/g;
    }
    print $log_fd "DATANEW=$data\n" if $log_level > 0;
    return $data;
}
