use Log::Any qw($log);
use Test::More;
use IO::File;
use IO::String;

plan tests => 5;

{ 
	my $str = IO::String->new();
	Log::Any->set_adapter('FileHandle', fh=>$str);
	$log->info("test");

	is(${$str->string_ref},"[info] test\n", "Testing to in memory IO::String filehandle");
}
{ 
	my $str = IO::String->new();
	Log::Any->set_adapter('FileHandle', fh=>$str, format=>"|%s| %s");
	$log->info("test");

	is(${$str->string_ref},"|info| test", "Testing to in memory IO::String filehandle & Format");
}
{
	
	my $fh = IO::File->new_tmpfile();
	Log::Any->set_adapter('FileHandle', fh=>$fh);
	$log->info("test");
	$fh->seek(0,0);
	my $message = $fh->getline;
	
	is($message,"[info] test\n","Message to temporary file");
	$fh->close();
}

{
	my $fh = IO::File->new_tmpfile();
	Log::Any->set_adapter('FileHandle', fh=>$fh);

	ok($fh->autoflush, "Testing autoflush is turned on");
}

{
	my $fh = IO::File->new_tmpfile();
	Log::Any->set_adapter('FileHandle', fh=>$fh, no_autoflush=>1);

	ok(! $fh->autoflush, "Testing autoflush is turned off");
}
