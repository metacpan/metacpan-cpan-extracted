use Test::More;
use IO::File;
use IO::String;


plan tests => 1;

my $buf = IO::String->new();
# TODO: automatically extract this from the module?
eval q{ 
	
	use Log::Any qw($log);
	use Log::Any::Adapter;

	# Send all logs to Log::Any::Adapter::FileHandle
	Log::Any::Adapter->set('FileHandle', fh=>$buf);

	$log->info("Hello world");
};
die $@ if $@;

is(${$buf->string_ref},"[info] Hello world\n", "Testing example in SYOPSIS")


