use strict;
use 5.6.1;
use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @ppd;

if ($] >= 5.00503) {
  @ppd = (
    ABSTRACT     => 'Perl extension that gives read access to GRIB weather data files',
    AUTHOR       => 'Frank Cox <frank.l.cox@gmail.com>',
  );
}

## check to see if they called for an alternate compiler on the command line
my $ALT_CC = 0;
foreach ( @ARGV ) {
    if ( m/cc=(\w*)/ ) {
        $ALT_CC = $1;
        last;
    }
}

# Used to check for a 'C' compiler
# code stolen from 'threads' module, thank you J Hedden!
sub check_cc {
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

sub have_cc {
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

if (  not have_cc and not $ALT_CC ) {
    print STDERR <<EOF;
    #--------------------------- shucks! ---------------------------------
    #
    # A C compiler is required by this installer. Your Perl was built with
    # the '$Config::Config{cc}' compiler but I can't find it in your path.
    #
    # Sorry about that.
    #
    # If you use another compiler you can try running Makfile.PL again 
    # like this:
    #
    #     perl Makefile.PL cc=My_Compiler
    #
    #     where "My_Compiler" is the name of your compiler.
    #
    # If this dosn't work, you can post a bug by sending email to: 
    #
    #     bug-Geo-ReadGRIB\@rt.cpan.org
    #
    # Please mention the compiler you use and the options required to 
    # compile a simple, single file, C program if you know them. It would 
    # also be helpful if you are able to help with testing. Particularly 
    # if your compiler isn't free and/or the maintainers don't have easy
    # access to your OS.
    #
    #---------------------------------------------------------------------

EOF

    print "//\$Config{cc}: $Config{cc} : ALT_CC: $ALT_CC//\n";
    die "OS unsupported";
}


WriteMakefile(
    NAME         => 'Geo::ReadGRIB',
    VERSION_FROM => 'lib/Geo/ReadGRIB.pm', # finds $VERSION
    PREREQ_PM    => {}, # e.g., Module::Name => 1.1
    LICENSE      => 'perl',
    SKIP         => [qw(static static_lib dynamic_lib)],
    clean        => {FILES => "wgrib.exe"},
    @ppd,
);

sub MY::dynamic {
    if ( $Config{cc} eq 'cc' or  $Config{cc} =~ m|/cc$| or $ALT_CC eq 'cc' ) {
    return
'
dynamic :: $(INST_LIB)/Geo/wgrib.exe
	@$(NOOP)

$(INST_LIB)/Geo/wgrib.exe: $(C_FILES)
	$(CC) -o $(INST_LIB)/Geo/wgrib.exe wgrib.c -lm
';
    }
    else {
        return
'
dynamic :: $(INST_LIB)/Geo/wgrib.exe
	@$(NOOP)

$(INST_LIB)/Geo/wgrib.exe: $(C_FILES)
	$(CC) -o $(INST_LIB)/Geo/wgrib.exe wgrib.c
';
    }

}

sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}

