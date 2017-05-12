# $Id$

use Mac::PropertyList;
use Time::HiRes;

printf "%10s   %10s  %10s  %s\n", 
	"Bytes", "Seconds", "bytes / sec ", "File";

foreach my $file ( @ARGV )
	{
	unless( open FILE, $file )
		{
		warn( "Could not open $file" );
		next;
		}
		
	my $data = do { local $/; <FILE> };
	close FILE;

	my $b = length $data;

	my $time1 = [ Time::HiRes::gettimeofday() ];
	my $plist = Mac::PropertyList::parse_plist( $data );
	my $time2 = [ Time::HiRes::gettimeofday() ];

	my $elapsed = Time::HiRes::tv_interval( $time1, $time2 );
	printf "%10d   %10.4f   %10.0f   %s\n", $b, $elapsed, 
		eval { $b / $elapsed }, $file;
	}
