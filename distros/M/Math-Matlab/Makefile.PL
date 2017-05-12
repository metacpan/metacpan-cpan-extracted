use ExtUtils::MakeMaker;

sub write_makefile {
	# See lib/ExtUtils/MakeMaker.pm for details of how to influence
	# the contents of the Makefile that is written.
	WriteMakefile(
		'NAME'			=> 'Math-Matlab',
		'PREREQ_PM'		=> { Test::More => 0.01 },
		'VERSION_FROM'	=> 'lib/Math/Matlab.pm', # finds $VERSION
	);
}

my $conf_file = 'matlab.config';

if ( -f $conf_file ) {
	my $ans = lc get_input( "It appears you already have a $conf_file file.\n" .
						'Would you like to use it?', 'Y');
	
	unless ($ans eq 'y') {
		eval{ unlink( $conf_file ) };
	}
}

use vars qw( $MATLAB_CMD $HAVE_LOCAL_MATLAB );

if ( -f $conf_file ) {
	require "$conf_file";
} else {
	$MATLAB_CMD = get_input( "Enter command to execute Matlab", '/usr/local/bin/matlab -nodisplay -nojvm');
	print "Attempting to run Matlab ... ";
	my $result = `$MATLAB_CMD -r quit`;
	$HAVE_LOCAL_MATLAB = $result && $result =~ /MathWorks/ ? 1 : 0;
	if ($HAVE_LOCAL_MATLAB) {
		print " OK\n";
	} else {
		print "\n\n'$MATLAB_CMD' does not start Matlab, tests with local Matlab will be skipped.\n";
	}
	
	open( CONF, "> $conf_file" ) || die "Cannot open $conf_file for writing! Error: $!";
print CONF <<EOF;
\$MATLAB_CMD = '$MATLAB_CMD';
\$HAVE_LOCAL_MATLAB = $HAVE_LOCAL_MATLAB;

1;
EOF
	close CONF;
	chmod 0600, $conf_file;
}

write_makefile();

print <<EOF;

Most of the tests for the Server and Remote classes of the the
Math::Matlab package are not run by default.

In order to test them, you will need to set up a server according to the
instructions in the INSTALL file, then edit the 'server.config' file
with the appropriate values and re-run 'make test'.

EOF

sub get_input {
	my ( $prompt, $default ) = @_;
	my $val;

	do {
		print $prompt . " [ " . (defined $default ? $default : 'no default') . " ] : ";
		$val = <STDIN>;
		chomp $val;
		$val = $default		if $val =~ /^\s*$/; 
	} until ( defined $val );

	($val) = $val =~ /^\s*(.*)\s*$/;

	return $val;
}
