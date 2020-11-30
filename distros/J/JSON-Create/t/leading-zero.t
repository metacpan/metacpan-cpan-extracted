use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use JSON::Create 'create_json';
# Get a PV value into $h{b} with leading zeros.
my %h = (a => '1', b => '00', c => '01');
# Get an IV value into $h{b} by forcing it to integer.
#my $dummy = sprintf ("%d", $h{b});
my $j = create_json (\%h);
#print $h{b}, "\n";
#TODO: {
#    local $TODO = 'Get leading zeros from strings right';
#    print "$j\n";
    like ($j, qr/"b":"00"/);
    like ($j, qr/"c":"01"/);
#};


done_testing ();
