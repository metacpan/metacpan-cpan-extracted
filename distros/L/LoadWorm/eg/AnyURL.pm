
package AnyURL;
# Author: Glenn Wood, C<glenwood@alumni.caltech.edu>.

1;


sub Check { my ($Link, $Content) = @_;
	
	open TMP, "<$Content";
	while ( <TMP> )
	{
		if ( /<HEAD><TITLE>Request Failed<\/TITLE><\/HEAD>/ )
		{
			my $rslt = "500 $_";
			while ( <TMP> ) { $rslt .= $_; }
			$main::Errors{$Link} = $rslt;
			return 0;
		};
	};
#	push @{ $main::AlreadyVisited{$Link} }, "I thought I\'d just throw this one in, just for the heck of it!";
	1; # Normal, "continue", return.
}

