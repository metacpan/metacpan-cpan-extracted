use strict;
use warnings;
use Data::Dumper;
use lib './lib';
use JavaScript::Duktape;
use Test::More;
use Data::Dumper;

my $object = {
    hi => [
        {
            hi => [
                {
                    hi => [
                        {
                            final => [
                                {
                                    num    => 1,
                                    string => 'string',
                                    obj    => {},
                                    arr    => []
                                }
                            ]
                        }
                    ]
                }
            ]
        }
    ]
};

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

$js->set( 'process',      {} );
$js->set( 'process.test', {} );
$js->set(
    'process.test.perl',
    sub {
        my $obj = shift;
        is_deeply $obj, $object;
    }
);

$duk->eval_string('process.test.perl');
$duk->push_perl($object);
$duk->call(1);

done_testing(1);
