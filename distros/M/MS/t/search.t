#!/usr/bin/perl

use strict;
use warnings;

use BioX::Seq::Stream;
use FindBin;
use Test::Fatal;
use Test::More;
use MS::Search::DB;
use File::Temp;

require_ok ("MS::Search::DB");

chdir $FindBin::Bin;

my $fn = 'corpus/fer.fa';

ok( my $db = MS::Search::DB->new($fn), "new()" );

#TODO: FTP download not working in CI
# ok( $db->add_crap(), "add_crap()" );

ok( $db->add_decoys(prefix => 'FOO_'), "add_decoys()" );
my $str_fh;
open my $fh, '>', \$str_fh;
ok( $db->write(fh => $fh), "write()" );
close $fh;
open $fh, '<', \$str_fh;
my $p = BioX::Seq::Stream->new($fh);
my $total  = 0;
my $decoys = 0;
while (my $seq = $p->next_seq) {
    ++$total;
    ++$decoys if ($seq->id =~ /^FOO_/);
}
ok( $total >= 2, "db size" ); # not exact, cRAP db may change
ok( $total/2 == $decoys, "decoy count" );

done_testing();
