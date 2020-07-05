use strict;
use warnings;
use Test::More;
use Exception::Backtrace;
use lib 't';
use MyTest;

plan skip_all => 'Capture::Tiny required to test'
    unless eval "use Capture::Tiny qw/:all/; 1";

Exception::Backtrace::install();
my $line_no;
my $file = __FILE__;
my $ref = \undef;
my $handler = sub {  $line_no = __LINE__; die \$ref; };
my $obj;

package Destroyer {
    sub DESTROY {
        $handler->();
    }
};
$obj = bless {} => 'Destroyer';

my $err = Capture::Tiny::capture_stderr(sub { $obj = undef; });
like $err, qr/line $line_no/;
like $err, qr/$file/;

done_testing();
