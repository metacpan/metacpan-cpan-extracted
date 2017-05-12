use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
no warnings 'once';

BEGIN { use_ok 'Devel::DidYouMean' }
throws_ok { Dumpr({ foo => 'bar' }) } qr/Did you mean Dumper/, 'Imported sub';
throws_ok { prnt('just a test') } qr/Did you mean print/, 'builtin function';
throws_ok { Data::Dumper::Dumber({ foo => 'bar' }) } qr/Did you mean Dumper/, 'Class sub';
is $Devel::DidYouMean::DYM_MATCHING_SUBS->[0], 'Dumper', 'Dumper is stored in global var';

done_testing();
