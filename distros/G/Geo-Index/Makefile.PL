use strict;
use warnings;
use ExtUtils::MakeMaker;

sub check_cc;
sub have_cc;


my %config = (
    NAME                => 'Geo::Index',
    AUTHOR              => q{Alex Kent Hajnal <akh@cpan.org>},
    VERSION_FROM        => 'lib/Geo/Index.pm',
    ABSTRACT_FROM       => 'lib/Geo/Index.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Geo-Index-*' },
  'TYPEMAPS' => [],
  'INC' => '',
#	C=>[], # Uncomment to disable C code completely (don't even try to build)
);

if ( $ENV{FORCE_C} ) {
	# Force attempt to compile C code
	# (no config changes needed)
	
	print STDERR "Will attempt to compile C code (per your request)\n";
	
} elsif ( $ENV{FORCE_NO_C} ) {
	# Do not attempt to compile C code
	$config{C} = [];
	
	print STDERR "Will not attempt to compile C code (per your request)\n";
	
} else {
	# Auto-detect whether C can be used
	
	print STDERR "Auto-detecting whether C can be used\n";
	
	# Verify that a 'C' compiler is available
	if (have_cc()) {
		# C compiler found
		
		print STDERR "\n";
		print STDERR "C compiler found, will attempt to compile C code\n";
		print STDERR "\n";
		print STDERR "If the compilation fails you can fall back to using only Perl code by running:\n";
		print STDERR "FORCE_NO_C=1 perl $0 @ARGV\n";
		print STDERR "\n";
		
		# (no config changes needed)
		
	} else {
		# No C compiler found
		
		print STDERR "\n";
		print STDERR "No C compiler found, falling back to pure Perl version\n";
		print STDERR "\n";
		print STDERR "You can force a compilation attempt by running:\n";
		print STDERR "FORCE_C=1 perl $0 @ARGV\n";
		print STDERR "\n";
		
		# Disable C code completely (don't even try to build)
		$config{C} = [];
	}
} 

WriteMakefile( %config );

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }


# Subroutines used to check for a 'C' compiler

sub check_cc
{
    require File::Spec;
 
    my $cmd = $_[0];
    if (-x $cmd or MM->maybe_command($cmd)) {
        return (1);       # CC command found
    }
    for my $dir (File::Spec->path(), '.') {
        my $abs = File::Spec->catfile($dir, $cmd);
        if (-x $abs or MM->maybe_command($abs)) {
            return (1);   # CC command found
        }
    }
    return;
}
 
sub have_cc
{
    eval { require Config_m; };     # ExtUtils::FakeConfig (+ ActivePerl)
    if ($@) {
        eval { require Config; };   # Everyone else
    }
    my @chunks = split(/ /, $Config::Config{cc});
    # $Config{cc} may contain args; try to find out the program part
    while (@chunks) {
        if (check_cc("@chunks")) {
            return (1);   # CC command found
        }
        pop(@chunks);
    }
    return;
}
