use Full::Script qw(:v1);
use Test::More;

isnt(ref($log), 'Log::Any::Proxy::Null', 'the Log::Any adapter is not null');

done_testing;
