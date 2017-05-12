# test barcodegen command-line script
use strict;
use Test::More;

# currently this script has to be run from directory that contains
# the "t" directory. Run as: perl  t/test_gen.t, or make test

my $cmd1 = "blib/script/barcodegen";
my $cmd2 = "bin/barcodegen";
my $cmd = undef;

$cmd = $cmd2 if ( -x $cmd2  );
$cmd = $cmd1 if ( -x $cmd1  );

if ( $cmd  ) { # if( $^O eq 'linux' )
    plan tests => 10;
}
else {
    plan skip_all => "Test: Unable to find executable $cmd1 or $cmd2";
}

my $output;

#-----------------------
# print STDERR "Debug: $output\n";
$output = qx{$cmd --help};
ok( $output =~ /Usage:/, 'help' );

TODO: {
    local $TODO = "'$cmd --man' works in local directory, fails when installing from CPAN, needs to be tested later";
    $output = qx{$cmd --man};
    ok( $output =~ /barcodegen - create barcode images/, 'man' );
}

$output = qx{$cmd --verbose --type Code39 "ABC123" 2>&1 1>/dev/null};
ok( $output =~ /Type.*Code39/, 'created Code39 barcode' );

$output = qx{$cmd --verbose --border 10 --type Code39 "ABC123" 2>&1 1>/dev/null};
ok( $output =~ /Border.*10x10/, 'border size 10' );

$output = qx{$cmd --verbose --border 10x20 --type Code39 "ABC123" 2>&1 1>/dev/null};
ok( $output =~ /10x20/, 'border size 10x20' );

$output = qx{$cmd --verbose --type Code39 "abc123" 2>&1 1>/dev/null};
ok( $output =~ /Error.*Invalid Characters/, 'correct error on invalid characters' );

$output = qx{$cmd --verbose --type QRcode "//com/" 2>&1 1>/dev/null};
ok( $output =~ /Type.*QRcode/, 'created QRcode barcode' );

$output = qx{$cmd --verbose --qrecc Q --type QRcode "//com/" 2>&1 1>/dev/null};
ok( $output =~ /QRcode Error Correction.*Q/, 'QRcode ecc Q' );

$output = qx{$cmd --verbose --qrsize 3 --type QRcode "//example.com/" 2>&1 1>/dev/null};
ok( $output =~ /QRcode Module Size.*3/, 'QRcode module size 3' );

$output = qx{$cmd --verbose -qrversion 4 --type QRcode "//com/" 2>&1 1>/dev/null};
ok( $output =~ /QRcode Version.*4/, 'QRcode version 4' );
#-----------------------
