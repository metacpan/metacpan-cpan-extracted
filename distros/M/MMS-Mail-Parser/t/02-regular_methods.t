#!perl -T

use Test::More tests => 11;
use MMS::Mail::Parser;
use MIME::Parser;

use MMS::Mail::Provider;

my $errors = [];
my $mmsparser = new MMS::Mail::Parser;
my $parser= new MIME::Parser;
my $providermailparser = new MMS::Mail::Provider;

is($mmsparser->output_dir('/tmp/'),'/tmp/');
is($mmsparser->output_dir,'/tmp/');
is($mmsparser->mime_parser($parser),$parser);
is($mmsparser->mime_parser,$parser);
is($mmsparser->provider($providermailparser),$providermailparser);
isa_ok($mmsparser->provider(),'MMS::Mail::Provider');
is($mmsparser->debug(1),1);
is($mmsparser->debug,1);
is_deeply($mmsparser->errors,$errors);
is($mmsparser->last_error,undef);
is($mmsparser->strip_characters("\r\n"),"\r\n");
