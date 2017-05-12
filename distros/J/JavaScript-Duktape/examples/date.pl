use strict;
use warnings;
use lib './lib';
use JavaScript::Duktape;
use Data::Dumper;

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->eval(q{
    var today = new Date();
    print(today.getMinutes());
    var unixTimestamp = Date.now();
    print(unixTimestamp);
});

my $date = $js->get_object('Date');

my $birthday = $date->new();
my $minutes = $birthday->getMinutes(_);
print $minutes, "\n";

$birthday->setMinutes(55);
$minutes = $birthday->getMinutes(_);
print $minutes, "\n"; # 55


my $unixTimestamp = $date->now->();
print $unixTimestamp, "\n";
print time(), "\n";
