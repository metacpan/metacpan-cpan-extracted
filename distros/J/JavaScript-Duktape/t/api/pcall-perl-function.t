use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;


sub tt2 {
    $duk->require_string(0);
    $duk->dump('2'); #never get here
    return 0;
}


$duk->push_function(\&tt2, 2);
$duk->dump("1");
$duk->pcall(0);
$duk->dump('3');

test_stdout();

__DATA__
1 (top=1): function () { [native code] }
3 (top=1): TypeError: string required, found undefined (stack index 0)
