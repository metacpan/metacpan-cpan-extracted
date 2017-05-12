use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;

#TODO FIXME

require './t/helper.pl';

my $js = JavaScript::Duktape->new();
my $duk = $js->duk;

{
    my $i = 0;
    my $p = $duk->push_fixed_buffer(32);
    my @p = split '', $p;
    printf("fixed:");

    for ($i = 0; $i < 32; $i++) {
        printf(" %d", int $p[$i]);
    }
}

printf("\n");

{
    my $i = 0;
    my $p = $duk->push_dynamic_buffer(32);
    my @p = split '', $p;
    printf("dynamic:");

    for ($i = 0; $i < 32; $i++) {
        printf(" %d", int $p[$i]);
    }

}

printf("\n");

test_stdout();

__DATA__
fixed: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
dynamic: 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0