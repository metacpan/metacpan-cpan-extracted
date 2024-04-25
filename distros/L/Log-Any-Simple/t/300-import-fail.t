use Test2::V0;

eval "use Log::Any::Simple 'default'";
like($@, qr/Unknown parameter/, 'default is not :default');

done_testing;
