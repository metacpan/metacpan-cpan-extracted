#!/usr/local/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use File::Spec;
use File::Temp qw(:POSIX);
use English    qw(-no_match_vars);
use vars qw($THIS_TEST_HAS_TESTS $THIS_BLOCK_HAS_TESTS);

$THIS_TEST_HAS_TESTS = 13;

plan( tests => $THIS_TEST_HAS_TESTS );

    use_ok('File::BSED');
File::BSED->import(qw(gbsed binary_file_matches));

my $test_binary = File::Spec->catfile($Bin, 'testbinary');

ok(!  binary_file_matches(), 'binary_file_matches() without args');

eval 'binary_file_matches("0xff")';
like( $EVAL_ERROR, qr/Missing filename argument to binary_file_matches/,
     'binary_file_matches() without filename arg.'
);


eval 'gbsed()';
like( $EVAL_ERROR, qr/Argument to File::BSED::binary_search_replace must be hash reference/,
    'gbsed() arg must be hash. test: no arg'
);

eval 'gbsed([])';
like( $EVAL_ERROR, qr/Argument to File::BSED::binary_search_replace must be hash reference/,
    'gbsed() arg must be hash. test: with array-ref'
);

ok(! File::BSED::string_to_hexstring(),
    'string_to_hexstring() with empty scalar'
);
is( File::BSED::string_to_hexstring('ask'), '61736b',
    'string_to_hexstring(ask) == 61736b'
);

my $ret1 = binary_file_matches('0xff', $test_binary);
is ($ret1,  743, 'Binary_file_matches');
ok(!File::BSED->errno(),          'File::BSED->errno');
is( File::BSED->errtostr(), undef, 'File::BSED->errtostr');

my $tempfile = tmpnam();

$THIS_BLOCK_HAS_TESTS = 3;
SKIP: {
    eval qq{
        open my \$fh, '>', "$tempfile" or die \$OS_ERROR;
        unlink "$tempfile"
    };
    if ($EVAL_ERROR) {
        skip(
            "Couldn't write to $tempfile: $EVAL_ERROR",
            $THIS_BLOCK_HAS_TESTS
        );
    }

    my $matches = gbsed({
        infile  => $test_binary,
        outfile => $tempfile,
        
        search  => '0xff',
        replace => '0x00',
    });

    is( $matches, 743, 'gbsed({ ... })');
    ok(!File::BSED->errno(),              'File::BSED->errno'     );
    is( File::BSED->errtostr, undef,    'File::BSED->errtostr'  );

    unlink $tempfile;

}
    
    







