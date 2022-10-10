use Test::More;
use IO::FD;
use Fcntl;


{
	#Make a temp file
	my $path=IO::FD::mktemp("TEMP_XXXXXX");
	IO::FD::sysopen my $fd, $path, O_CREAT|O_RDWR;

	#Fill it with data
	my $out_data="Data1Data2Data3";
	ok defined(IO::FD::syswrite($fd,$out_data)), "Write to file";
	
	#Slurp entire file
	local $/=undef;
	IO::FD::sysseek($fd, 0, 0);
	while(my $data=IO::FD::readline($fd)){

		ok $out_data eq $data, "Slurp ok";
	}

	#Read records
	local $/=\5;
	IO::FD::sysseek($fd, 0, 0);
	my @comparision=qw<Data1 Data2 Data3>;
	my $i=0;
	while(my $data=IO::FD::readline($fd)){
		ok $comparision[$i] eq $data, "Record equal";
		$i++;
	}

	#attempt to split line and fail
	local $/="\n";
	local $@=undef;
	my $res=eval {
		IO::FD::readline($fd);
	};

	ok !defined($res) and $@, "Readline failed ok";
	

	#Close and check for error
	ok defined(IO::FD::close($fd)), "File close";


	local $/=undef;
	ok !defined(IO::FD::readline($fd));

	local $/=\23;
	ok !defined(IO::FD::readline($fd));

	#Cleanup
	unlink $path;
}

done_testing;
