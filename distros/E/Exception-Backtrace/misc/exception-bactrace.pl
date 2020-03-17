use strict;
use warnings;
use Scalar::Util qw/weaken/;
use Exception::Backtrace;

my $trace;
my $obj = bless {} => 'Some::package';
my $obj2 = bless {} => 'Some::package2';

sub fn0 {
    $trace = Exception::Backtrace::create_backtrace()->to_string;
}

sub fn1 {
    my @args = @_;
    shift @args;
    fn0(@args);
}

sub fn2 {
    weaken($obj2);
    fn1(@_);
}

my $ref = 'referenced';
fn2(5, 'ztring',  $obj, \$ref, \&fn0, [], {}, $obj2);

print "trace1 = ", $trace // 'n/a', "\n";

sub do_log { $trace = Exception::Backtrace::create_backtrace()->to_string; }
sub call_with_args {
    my ($arg_hash, $func) = @_;
    $func->(@{$arg_hash->{'args'}});
}

my $h = {};
# Deleting the undef makes it all work again!
my $arg_hash = {'args' => [undef]};
call_with_args($arg_hash, sub { $arg_hash->{'args'} = []; do_log(sub { $h; }); });

print "trace2 = ", $trace // 'n/a', "\n";
