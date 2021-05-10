# t/basic.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;
use Data::Dumper;

use lib qw(lib ../lib);
use Function::Runner;

# HELPER
my $PEEK_LEVEL = 5; ## Disallow peeks below this level
sub peek {      # ( $level, $res ) --> $res
    ## If $level is at least PEEK_LEVEL, print content of $res
    my ($level, $res) = @_;
    return $res if $level < $PEEK_LEVEL;

    my $file = (caller(0))[1];
    my $line = (caller(0))[2];
    say "$file line $line: ". Dumper $res;
    return $res;
}


my ($sub, $got, $exp, $msg, $tmp, $tmp1, $tmp2, $tmp3);

$msg = 'Basic test -- Ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);

BEGIN {
    use_ok( 'Function::Runner' ) || print "Bail out!\n";
}

$msg = 'peek stores message into $LOG';
Function::Runner::peek(3, 'test message');
$tmp = peek 0, Dumper Function::Runner::_log_fetch()->[0];
$got = $tmp =~ /basic.t.*pkg:main.*line.*test message/s ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);

$msg = 'peek stores obj into $LOG';
Function::Runner::_log_clear();
Function::Runner::peek(3, ['test message']);
$tmp = peek 0, Dumper Function::Runner::_log_fetch()->[0];
$got = $tmp =~ /basic.t.*pkg:main.*line.*test message/s ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);


done_testing();

