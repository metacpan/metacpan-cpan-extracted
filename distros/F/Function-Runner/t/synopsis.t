# t/synopsis.t v0.0.1-1
use strict; use warnings; use utf8; use 5.10.0;
use Test::More;
use Data::Dumper;

use lib qw(lib ../lib);
use Function::Runner;

BEGIN {
    use_ok( 'Function::Runner' ) || print "Bail out!\n";
}

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

# Hello World
sub greet {
    print "Hello ". ($_[0] || 'World') ."\n";
    return ('ok',$_[0]);
}
my $defn = {                                # Definition is just a hashref
    '/hello' => '&greet'                    #   The /hello step,
};                                          #     calls the &greet function

my $fn = Function::Runner->new($defn);      # Create a greeter
$fn->run('/hello','Flash');                 # Hello Flash

$msg = 'Call function works';
$got = join ':', $fn->run('/hello','Flash');
$exp = 'ok:Flash';
is($got, $exp, $msg);


my $switch = {                              # Define a switch
    '/checkSwitch' => {                     #
        'run'  => '&checkSwitch',           # Check the switch
        ':on'  => '&bye',                   #   If it's on, leave
        ':off' => '/turnOn',                #   If it's off, turn it on
    },
    '/turnOn'  => {                         # Turn on the switch
        'run'  => '&greet',                 #   Greet the caller
        ':ok' => '/turnOff',                #   Then turn off the switch
    },
    '/turnOff' => '&bye',                   # Turn off the switch and leave
  };
sub bye {
    print "Bye " . ( $_[0] || 'World' ) . "\n";
    return ('ok',$_[0]);
}
sub checkSwitch { return @_ }

$fn = Function::Runner->new($switch);       # Create a switch
$fn->run('/checkSwitch', 'on', 'Flash');    # Bye Flash

$fn->run('/checkSwitch', 'off', 'Hulk');    # Hello Hulk
                                            # Bye Hulk
$msg = 'Passing args works';
$got = join ':', $fn->run('/checkSwitch', 'on', 'Flash');
$exp = 'ok:Flash';
is($got, $exp, $msg);


$msg = 'Steps are logged';
$tmp = $fn->run('/checkSwitch', 'off', 'Hulk');
$got = join ',', map { $_->[0].':'.$_->[2] } @{$fn->steps()};
$exp = '/checkSwitch::off,/turnOn::ok';
is($got, $exp, $msg);


done_testing;

