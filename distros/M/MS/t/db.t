#!/usr/bin/perl

use strict;
use warnings;

use 5.012;

use BioX::Seq::Stream;
use FindBin;
use Net::Ping;
use Test::More;

use MS::Search::DB;

chdir $FindBin::Bin;

my $test_ftp = 'ftp://ftp.ncbi.nlm.nih.gov/genomes/Viruses/enterobacteria_phage_phix174_sensu_lato_uid14015/NC_001422.faa';
my $test_http = 'https://ftp.ncbi.nlm.nih.gov/genomes/Viruses/enterobacteria_phage_phix174_sensu_lato_uid14015/NC_001422.faa';
my $test_file = 'corpus/fer.fa';

require_ok ("MS::Search::DB");

ok( my $db = MS::Search::DB->new(), "new DB" );

ok( $db->add_from_file( $test_file ), "add from file" );

my $added = 1;

if ( network_available() ) {

    ok( $db->add_from_url(  $test_ftp  ), "add from FTP" );
    ok( $db->add_from_url(  $test_http ), "add from HTTP" );
    $added += 22;

}

ok( $db->add_decoys(
    type => 'reverse',
    prefix => 'REV_',
), "add decoys" );

my $n_seqs = get_db_size( $db );
ok( $n_seqs == $added*2, "db size 1" );

if ( network_available() ) {

    ok( $db->add_crap, "add cRAP" );
    $n_seqs = get_db_size( $db );
    ok( $n_seqs > $added*2+10, "db size 2" );

}

done_testing();

sub get_db_size {

    my ($db) = @_;

    my $pipe;
    open my $fh, '>', \$pipe;
    $db->write(fh => $fh);
    close $fh;

    open $fh, '<', \$pipe;
    my $p = BioX::Seq::Stream->new($fh);
    my $n_seqs = 0;
    while ($p->next_seq) {
        ++$n_seqs;
    }
    close $fh;

    return $n_seqs;

}

sub network_available {

    my $ping = Net::Ping->new();
    my $ret = 0;
    if ( $ping->ping('google.com' ) ) {
        $ret = 1;
    }
    $ping->close();
    return $ret;

}
