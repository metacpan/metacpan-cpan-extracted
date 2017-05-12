use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$duk->peval_file_noresult("./t/test.js");
$duk->push_string('cool');

my $perl = $js->get('perl');
print Dumper $perl;

if ($perl->{falseVal}){
    die $perl->{falseVal};
}

my $ret = $perl->{func}->(9);
print Dumper $ret;
$duk->dump();
