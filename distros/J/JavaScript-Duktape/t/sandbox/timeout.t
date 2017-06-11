use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new( timeout => 1 );

my $time = 0;
$js->set( reset => sub { $time = time() } );
$js->set( check => sub { if (time - $time > 3) { die "died from perl" } } );

my $duk = $js->duk;

eval {
    $js->eval(q{
        reset()
        while(1){ check() }
    });
};

ok $@ =~ /timeout/;

$duk->set_timeout(2);

eval {
    $duk->eval_string(q{
        reset()
        while(1){ check() }
    });
};

ok $@ =~ /timeout/;

$duk->set_timeout(0);

eval {
    $duk->eval_string(q{
        reset();
        while (1){ check() }
    });
};

ok $@ =~ /died from perl/;

done_testing();
