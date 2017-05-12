use ExtUtils::MakeMaker;
my $VERSION = '3.03'; # major number equals that of underlying lp_solve library

# the underlying C library
my $lp_solve_dist = 'lp_solve_3.2';
my $liblpk        = "$lp_solve_dist/liblpk.a";
my $tarball       = "$lp_solve_dist.tar.gz";

# check for the lp_solve distribution in the current dir
if(-d $lp_solve_dist) {
    warn "*** I see you have a subdirectory $lp_solve_dist. Nice!\n",
         "*** I will use that directory for getting liblpk.a.\n";
}
else {
    warn "*** You do not have a $lp_solve_dist directory yet.\n",
         "*** I will extract it for you from $tarball.\n";
    if(! -f $tarball) {
	warn "*** But first I need to download $tarball to the current directory.\n";
	FetchDistribution("ftp://ftp.ics.ele.tue.nl/pub/lp_solve/$tarball");
    }
    ExtractDistribution($tarball);
}

# compile lp_solve if needed
if(-e $liblpk) {
    warn "*** I see you already have have $liblpk. Nice!\n",
         "*** Just be sure it is compiled for position independent code (with the -fPIC\n",
         "*** flag when using gcc). Otherwise the installation will fail later on.\n";
}
else {
    warn "*** You do not have $liblpk yet.\n",
         "*** I will attempt to compile it for you.\n";
    my @make_flags = ( 
       # These compilation flags will be tried in succession, until one combination works.
       # If none of these work for you, but you do find a valid combination for the
       # platform you are working on, please mail them to wimv@cpan.org. I will incorporate
       # them in the next release of Math::LP::Solve.
       {MATHLIB => '-lm', LEX => 'lex', YACC => 'yacc'}, # works for HP-UX, Solaris, Digital, IRIX
       {MATHLIB => '-lm', LEX => 'flex -l', LEXLIB => '-lfl'}, # works for Linux
       {MATHLIB => '-lm'}, # just the minimally required compilation flags for any platform
    );
    while(1) {
	my $rh_flags = shift @make_flags or
	    die "*** Aargh! I found no way of compiling $lp_solve_dist\n",
	        "*** You will need to try this yourself. Just make sure you generate\n",
                "*** position independent code (e.g. with -fPIC when using gcc)\n";
	eval { CompileDistribution($lp_solve_dist, %$rh_flags) };
	if($@) {
	    warn "*** Oops! Compilation failed.\n",
	         "*** I will cleanup and recompile with other flags if available ...\n";
	    CleanDistribution($lp_solve_dist);
	}
	else { # compilation succeeded
	    warn "*** Nice! I succeeded in compiling $lp_solve_dist/liblpk.a.\n";
	    last;
	}
    }
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Math::LP::Solve',
    ($] > 5.004) ? (
      'ABSTRACT'  => 'perl wrapper for the lp_solve linear program solver',
      'AUTHOR'    => 'Wim Verhaegen <wimv@cpan.org>',
    ) : (),
    #'VERSION'   => $VERSION, 
    'VERSION_FROM' => 'Solve.pm',
    'LIBS'	=> ["-lfl -ll -L$lp_solve_dist -llpk"],  
    'DEFINE'	=> '',
    'INC'	=> "-I$lp_solve_dist",
    'EXE_FILES' => [],

    # for developers only
    'dist'      => { # CVS support
	CI        => 'cvs ci',
	RCS_LABEL => 'cvs tag Math-LP-Solve-$(VERSION_SYM)' 
    }, 
    'depend' => { 
	'Solve.c' => "Solve.i\n" # rule for generating the XS code, simultaneously generates the .pm file
	    . "\tswig -perl5 -module Math__LP__Solve -package Math::LP::Solve -dascii -o Solve.c Solve.i\n" # runs swig with proper options
	    . "\t\$(PERL) -p -e '/^(package|bootstrap)\\b/ && s/__/::/g' Math__LP__Solve.pm > Solve.pm\n" # makes a clean .pm file which fits into the module hierarchy
            . "\t\$(PERL) contrib/export_swigged_symbols.pl --swig-docfile=Solve_wrap.doc --pm-file=Solve.pm\n" # tags all swigged symbols for exporting
	    . "\t\$(PERL) contrib/add_pm_version_number.pl --package=Math::LP::Solve --version=$VERSION --pm-file=Solve.pm\n" # writes the version number to Solve.pm
	    . "\t\$(RM) Math__LP__Solve.pm Solve_wrap.doc\n", # removes temporary files
    },
    'realclean' => {
         FILES => $lp_solve_dist, # removes the C library, which is entirely incorporated in the extension after installation anyway
    },
);

sub FetchDistribution { # gets a tarball by ftp and puts it in the current directory
    my $url = shift;
    warn "Fetching $url ...\n";

    # load the ftp module
    eval "require Net::FTP";
    if($@) {
	die "It seems you do not have the package Net::FTP installed.\n",
	    "Please download $url manually and restart the installation.\n",
	    "NOTE: Net::FTP is only needed for automatically installing\n",
	    "      Math::LP::Solve, and not for using Math::LP::Solve in\n",
	    "      your scripts.\n";
    }

    # parse the url
    my($host,$path,$file);
    $url =~ s{^.*://}{}; # strips of 'ftp://' or 'http://'
    $url =~ s{([^/]*)}{} and $host = $1;
    $url =~ s{(.*)/}{}   and $path = $1;
    $file = $url;
    
    # fetch the file
    my $ftp = Net::FTP->new($host);
    $ftp->login() or die "Anonymous login to host `$host' failed.\n";
    $ftp->cwd($path) or die "Failed to cd to `$path' at host `$host'\n";
    $ftp->hash(1); # prints hash marks for each 1024 bytes
    $ftp->get($file) or die "Failed to get file `$file' from host `$host'\n";
    $ftp->quit();
}

sub ExtractDistribution { # extracts a tarball in the current directory
    my $tarball = shift;
    warn "Extracting $tarball ...\n";

    # load the untarring module
    eval "require Archive::Tar";
    if($@) {
	die "It seems you do not have the package Archive::Tar installed.\n",
            "Please untar $tarball manually and restart the installation.\n",
            "NOTE:: Archive::Tar is only needed for automatically installing\n",
            "       Math::LP::Solve, and not for using Math::LP::Solve in\n",
	    "       your scripts.\n";
    }

    Archive::Tar->extract_archive($tarball) or die "Could not untar `$tarball'\n";
}

sub CompileDistribution {
    my $dist = shift;
    my %make_flags = @_;

    # derive flags for make
    use Config;
    $make_flags{CC}      = $Config{cc}; # use the C compiler perl itself is compiled with
    $make_flags{CFLAGS} .= ' '. $Config{optimize};   # for optimized code
    $make_flags{CFLAGS} .= ' '. $Config{cccdlflags}; # for position independent code
    
    # run make
    use Cwd;
    my $cwd = cwd();
    my $make = $Config{make};
    (my $target = $liblpk) =~ s{.*/}{};
    $cmd = join ' ', $make, $target, map { "$_=\"" . $make_flags{$_} . "\"" } sort keys %make_flags;
    $cmd = "cd $dist && $cmd && cd $cwd";
    warn "Compiling in $dist with `$cmd' ...\n";
    my $rc = 0xffff & system $cmd;

    die "ERROR: Compilation of $dist failed\n",
        "       Please try compiling by hand\n" if $rc != 0;
    warn "Compilation OK.\n";
}

sub CleanDistribution { # runs make clean
    my $dist = shift;
    use Cwd;
    my $cwd = cwd();
    my $cmd = "cd $dist && make clean && cd $cwd";
    warn "Cleaning up with `$cmd' ...\n";
    my $rc = 0xffff & system $cmd;
    die "ERROR: cleaning up of $dist failed\n" if $rc != 0;
}

