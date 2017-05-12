use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );
use FindBin qw($Bin);
use lib 'lib';
use lib 't';
use lib $Bin;
use lib "$Bin/../lib";

our $THIS_TEST_HAS_TESTS = 7;


eval 'use IO::Capture::Stderr';
if ($EVAL_ERROR) {
    plan( skip_all => 'This test requires IO::Capture::Stderr.' );
}

plan( tests => $THIS_TEST_HAS_TESTS );


@ARGV = qw(The quick -v fox -jumps over -t --lazy=dawg);

use Getopt::LL qw(getoptions opt_String opt_Flag opt_Digit);

@ARGV = qw(-foo FOO -bar 31337 --foobar --help);

my $getopt = Getopt::LL->new({
    '-foo'      => opt_String('The foo option.'    ),
    '-bar'      => opt_Digit( 'The bar option.'    ),
    '--foobar'  => opt_Flag(  'The foobar option.' ),
    '--help'    => opt_Flag(  'This help menu.'    ),
} );
my $options = $getopt->result;

is_deeply($options, {
        '-foo'      => 'FOO',
        '-bar'      => '31337',
        '--foobar'  => 1,
        '--help'    => 1,
}, 'result');

my $cserr = IO::Capture::Stderr->new( );
$cserr->start;
$getopt->show_help( );
$cserr->stop;

my $messages;
while (my $line = $cserr->read ) {
    $messages .= $line;
}

like( $messages, qr/^\-foo\s+The\s+foo\s+option./xms,
    'help for -foo'
);
like( $messages, qr/^\-bar\s+The\s+bar\s+option./xms,
    'help for -bar'
);
like( $messages, qr/^\--foobar\s+The\s+foobar\s+option./xms,
    'help for --foobar'
);
like( $messages, qr/^\--help\s+This\s+help\s+menu./xms,
    'help for --help'
);

$cserr->start;
$getopt->show_usage;
$cserr->stop;
my $usage = $cserr->read;
chomp $usage;
is( $usage, 'Usage: help.t [-foo <n>|-bar <n>|--foobar|--help]',
    'show_usage()'
);

$getopt->options->{program_name} = 'customProgramName';
$cserr->start;
$getopt->show_usage;
$cserr->stop;
$usage = $cserr->read;
chomp $usage;
is( $usage, 'Usage: customProgramName [-foo <n>|-bar <n>|--foobar|--help]',
    'show_usage() with options->program_name'
);

#Usage: help.t [-foo <n>|-bar <n>|--foobar|--help]
