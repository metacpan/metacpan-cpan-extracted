use 5.006;
use ExtUtils::MakeMaker;

my $LLVER="UNKNOWN";
my $LDflags="";

$CC=$ExtUtils::MakeMaker::Config{"cc"};

#
# I hope this bit works out the base LoadLeveler version.
# Can't use the variables in the llapi.h file because the version number is the
# same for 3.1 & 3.2!  I am sure there is a very good reason for this, I don't know
# what it is, but i'm sure it must be a very good reason.
#

if ( $^O eq "linux" )
{
    $LoadL="/opt/ibmll/LoadL/full";
    # Quit if no llapi.h file (for CPAN testers)
    if ( ! -f "$LoadL/include/llapi.h")
    {
		print STDERR "Unable to find LoadLeveler include file\n";
		exit 0;
    }
    #$ExtraLibs="-lstdc++"; # stops load failure with error undefined symbol: __gxx_personality_v0
    $LLVER=llver();
    if ($LLVER eq "UNKNOWN" )
    {
    	#
	# If getting the version from llstatus -v failed, try the old way
	# of using the package information in the rpm database
	#
        # Using rpm information is a hack, you can get something like:
    	#
    	# LoadL-full-SLES10-X86-3.5.0.1-0
    	# LoadL-full-SLES10-X86_64-3.5.1.2-0
    	# LoadL-full-license-SLES10-X86-3.5.0.1-0
    	#
    	# So the loop searches for the highest version and uses that
    	# 
        my $rpm = "";
    	$rpm = "/usr/bin/rpm" if -f "/usr/bin/rpm";
    	$rpm = "/bin/rpm"     if -f "/bin/rpm";
    	my @packages=`$rpm -qa`;
    
    	foreach $package (@packages)
    	{
			next unless $package=~/LoadL.*-([\d.]+)-/;
			#print "$package ----> $1\n";
			my $ver=string_to_num($1);
			$LLVER=$ver if $ver > $LLVER;
    	}
    	if ( ! $LLVER eq "UNKNOWN" )
    	{
		print STDERR "Unable to extract LoadLeveler version\n";
		exit 0;
    	}
    }
    # 64 bit required on PowerPC
    if ( ! defined $ExtUtils::MakeMaker::Config{"use64bitall"} && $ExtUtils::MakeMaker::Config{"archname"} =~ /ppc-linux/)
    {
    	print "I'm not totally sure but I think you are trying to build with a 32 bit version of Perl, the llapi is 64 bit\n";	
		print "This is probably going to end very badly. Sorry\n\n";
    }
}
elsif  ( $^O eq "aix" )
{
    $LoadL="/usr/lpp/LoadL/full";
    # Quit if no llapi.h file (for CPAN testers)
    if ( ! -f "$LoadL/include/llapi.h")
    {
		print STDERR "Unable to find LoadLeveler include file\n";
		exit 0;
    }
    $ExtraLibs="";
    $LDflags="-b32";
    $LLVER=llver();
    if ($LLVER eq "UNKNOWN" )
    {
	    #
	    # The code extracts the package version using lslpp.
	    #
    	open(LLVER,"/usr/bin/lslpp -Ou -qlc LoadL.full |");
    	$_=<LLVER>;
    	$_=~/^[^:]+:[^:]+:([^:]+):/;
    	close(LLVER);
    	$LLVER=string_to_num($1);
    }
}
else
{
    # Return a value that CPAN testers might like
    # http://cpantest.grango.org/cgi-bin/pages.cgi?act=wiki-page&pagename=CPANAuthorNotes
    print STDERR "OS unsupported\n";
    print STDERR "LoadLevler is only supported on Linux and AIX. Found $^O\n";
    exit 0;
}

print "Building for version $LLVER on $^O\n\n";

process_defs();

WriteMakefile(
    'NAME'		     => 'IBM::LoadLeveler',
    'VERSION_FROM'	 => 'LoadLeveler.pm',
    'PREREQ_PM'		 => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'LoadLeveler.pod', # retrieve abstract from module
       AUTHOR        => 'Mike Hawkins <mike\@pink-pit.com>') : ()),
       'PM'          => { 'llapi.ph'        => '$(INST_LIBDIR)/llapi.ph',
		     	  'LoadLeveler.pm'  => '$(INST_LIBDIR)/LoadLeveler.pm'
			   },		   
    'MAN3PODS'	     => { 'LoadLeveler.pod' => '$(INST_MAN3DIR)/LoadLeveler.$(MAN3EXT)',
			  'DataAccess.pod'  => '$(INST_MAN3DIR)/LoadLeveler::DataAccess.$(MAN3EXT)',
			  'Submit.pod'      => '$(INST_MAN3DIR)/LoadLeveler::Submit.$(MAN3EXT)',
			  'Query.pod'       => '$(INST_MAN3DIR)/LoadLeveler::Query.$(MAN3EXT)',
			  'Workload.pod'    => '$(INST_MAN3DIR)/LoadLeveler::Workload.$(MAN3EXT)',
			  'Reservation.pod' => '$(INST_MAN3DIR)/LoadLeveler::Reservation.$(MAN3EXT)',
			  'Error.xsh'       => '$(INST_MAN3DIR)/LoadLeveler::Error.$(MAN3EXT)',
			  'FairShare.xsh'   => '$(INST_MAN3DIR)/LoadLeveler::Fairshare.$(MAN3EXT)',
			   },
    'LIBS'	=> ["-L$LoadL/lib -lllapi $ExtraLibs"], # e.g., '-lm'
    'DEFINE'	=> "-DLLVER=$LLVER",
    'INC'	=> "-I$LoadL/include",
    'OBJECT'	=> '$(O_FILES) ',
    'MYEXTLIB'  => 'ct.a',  # Fake Library to con MakeMaker into building C tests
    'CC'        => $CC,
    'macro'	=> { LoadL => "$LoadL" },
    'clean'     => { FILES => "defs.h llapi.ph ct.a ct/version ct/data_access ct/int_types *.html" },
    'depend'    => { "LoadLeveler.c" => "Reservation.xsh Configuration.xsh Workload.xsh Error.xsh FairShare.xsh Query.xsh Submit.xsh DataAccess.xsh" },
    'dynamic_lib' => { OTHERLDFLAGS => $LDflags }
);
sub MY::postamble {
    my $postamble = <<'END';
llapi.ph: $(LoadL)/include/llapi.h
	( cd $(LoadL)/include ; h2ph -d /tmp llapi.h )
	cat /tmp/llapi.ph | sed -e /require.*/d > $(INST_LIB)/../../llapi.ph
	rm /tmp/llapi.ph
html: LoadLeveler.pm DataAccess.pod Reservation.pod Submit.pod Query.pod Workload.pod Error.xsh FairShare.xsh LoadLeveler.pod Configuration.xsh
	pod2html --flush --noindex --podpath=. --htmlroot=. --outfile=DataAccess.html DataAccess.pod
	pod2html --noindex --podpath=. --htmlroot=. --outfile=Reservation.html Reservation.pod
	pod2html --noindex --podpath=. --htmlroot=. --outfile=Submit.html Submit.pod
	pod2html --noindex --podpath=. --htmlroot=. --outfile=Query.html Query.pod
	pod2html --noindex --podpath=. --htmlroot=. --outfile=Workload.html Workload.pod
	pod2html --noindex --podpath=. --htmlroot=. --title="Error Handling API" --outfile=Error.html Error.xsh
	pod2html --noindex --podpath=. --htmlroot=. --title "Fair Share Scheduling API" --outfile=FairShare.html FairShare.xsh
	pod2html --noindex --podpath=. --htmlroot=. --outfile=LoadLeveler.html LoadLeveler.pod
	pod2html --noindex --podpath=. --htmlroot=. --title="Configuration API" --outfile=Configuration.html Configuration.xsh
ct.a:	ct/version ct/data_access ct/int_types
	ar r ct.a	
ct/version: ct/version.c
	$(CC) -o $@ $(CCFLAGS) $(INC) $@.c $(EXTRALIBS) 	
ct/data_access: ct/data_access.c
	$(CC) -o $@ $(CCFLAGS) $(INC) $@.c $(EXTRALIBS) 	
ct/int_types: ct/int_types.c
	$(CC) -o $@ $(CCFLAGS) $(INC) $@.c $(EXTRALIBS) 	
END
    $postamble;
}

sub process_defs
{

    my %enums=();
    my @values=();

    print "Building list of current ll_get_data specifications\n";
    open(LLAPI,"$LoadL/include/llapi.h") || die "Can't open $LoadL/include/llapi.h $!";
    # Speed through the file till we find
    # the LLAPI_Specification enum
    while ( <LLAPI> )
    {
		last if /LLAPI_Specification/;
    }
    my $count=0;
    while ( <LLAPI> )
    {
		last if /}/;

		if ( /Unused_LL/ )
		{
			$count++;
			next;
		}
		next unless /LL/;
		chomp;
		# Don't bother with anything that doesn't have a comma in it.
		next unless /([^,]*),(.*)/;

		my $before=$1;
		my $after=$2;

		# If the version of C we are using does not support Designated Initializers
		# we need the enum id number. boo hiss btw
		$count = $1 if /=\s*(\d+),/;

		# Process the enum
		# remove leading whitespace
		$before=~s/^\s+//;
		# remove everything after a white space
		$before=~s/\s+.*//;
		# remove everything after and including an =
		$before=~s/=.*//;
	
		# Process the definition

		$after="NONE" if $after=~/^\s*$/;

		# remove anything up to the start of a type def
		$after=~s|^.*/\*\s*||;
		# remove everything after a :
		$after=~s|:.*||;
		# or a (
		$after=~s|\(.*||;
		# remove anything after a *
		$after=~s|\*\s+.*|\*|;
		# strip out C end comments
		$after=~s|\*/||;
		$after= uc($after);
		$after=~s/\s*$//g;
		$after=~s/\*/_STAR/g;
		$after=~s/ /_/g;
		$after=~s/_+/_/g;
		$after="LL_$after";
		#print "$count $before  -> $after  ($_)\n";

		$enums{$before}=$after;
		$values[$count++]=$before;
    }
    close(LLAPI);

    print "Generating new definitions array\n";
    open(DEFS,"defs.h.in") || die "Can't open defs.h.in $!";
    open(OUT,"> defs.h.new")|| die "Can't open defs.h.new $!";

    #
    # C99 introduced Designated Initalizers for arrays, meaning you
    # can do things like:
    # static int defs[]={
    #       [LL_StepCheckpointing] = LL_BOOLEAN_STAR,
    #       [LL_MachineName] = LL_CHAR_STAR,
    #                   };
    # Which is very nice since the alternative is to build a very nasty array.
    #
    # For now I don't know how to work out if C supports this feature, I do know it
    # doesn't work on my version of AIX though...
    #
    my $UseDesignatedInitializers = 0;

    $UseDesignatedInitializers = 0 if $^O eq "aix";

    # Copy everything out until we get to the array definition
    while( <DEFS> )
    {
		print OUT $_;
		last if ( $_ =~ /\[\]/ );
    }

    #
    # We are now pointing at the definitions in the template array
    # What I want to do at this point is to read the defs.h.in file
    # and if I find a line like
    #       [LL_StepCheckpointing] = LL_BOOLEAN_STAR,
    # then see if the LL_ thingie was defined in the
    # include file, if it is write it out, if not don't.
    #
    # However this will only work if the Designated Initializers
    # are supported, otherwise a fully defined array needs to be built
    #
    # So, suck my handcranked defs in from the defs.h.in file
    # and then loop through all enums as slurped out of the
    # system llapi.h file, @values contains a number to LL_ thingie
    # which can be used to see if there is anything to print.
    #

    my %defs=();
    while ( <DEFS> )
    {
		last if ( $_ !~ /\[.*\]/ );
		# slurp the definition from the file into a hash
		next unless $_=~/\[(.*)\]\s*=\s*(\S+)\s*\,/;
		$defs{$1}=$2;
    }

    for(my $i=0;$i<$count;$i++)
    {
		if ( exists $defs{$values[$i]})
		{
		    if ( $UseDesignatedInitializers)
	    	{
				print OUT "\t\[$values[$i]\] = $defs{$values[$i]},\n";
			#	print "\t\[$values[$i]\] = $defs{$values[$i]},\n";
	    	}
	    	else
	    	{
				print OUT "$defs{$values[$i]},\n";
	    	}
	    	delete $enums{$values[$i]};
	    	delete $defs{$values[$i]};
		}
		else
		{
	    	print OUT "LL_NONE,\n" if ! $UseDesignatedInitializers;
		}
    }

    # Close the array
    print OUT "};\n";
    print OUT "\n";
    close(OUT);
    close(DEFS);


    if  ( scalar keys %enums > 0 )
    {
		print "Current llapi.h has the following definitions, add them to defs.h at your own risk:\n\n";
		foreach my $key ( keys %enums)
		{
		    print "[$key] = $enums{$key},\n";
		}
		print "\n";
    	}
    	if  ( scalar keys %defs > 0 )
    	{
		print "defs.h.in has the following definitions not seen in your system llapi.h file.  They have been removed from defs.h:\n\n";
		foreach my $key ( keys %defs)
		{
		    print "[$key] = $defs{$key},\n";
		}
		print "\n";
    }

    if ( -s "defs.h.new" )
    {
		unlink "defs.h.old" if ( -f "defs.h.old");
		rename "defs.h","defs.h.old" if ( -f "defs.h" );
		rename "defs.h.new","defs.h";
    }
}

#
# Try and use llstatus to determine version
#

sub llver
{
	my $version = "UNKNOWN";
	
	if ( -x "$LoadL/bin/llstatus" )
	{
		my $status=`$LoadL/bin/llstatus -v`;
		$version=string_to_num($1) if $status=~/\S+\s+(\S+)/;
	}
	return $version;
}

#
# The code converts the package version to a number, eg
# String is 3.1.0.16
# 	doubles any single digits:      03.01.00.16
#       removes the dots:               03010016
#	removes the leading 0 (octal):  3010016
# The final number is used in #ifdef statements
#
# The 1 while ..... construct repeatedly runs the doubling search. This is needed
# because if you match one .0. then the start for the next search is the first digit
# in the next number. See Page 155 of Camel V3. Alternativly just trust me that it works :)
#

sub string_to_num
{
	my $version = shift;
	
	1 while $version=~s/\.(\d)\./.0$1./g;
	$version=~s/\.(\d)$/.0$1/;
	$version=~s/\.//g;
	$version=~s/^0(\d+)/$1/;
	
	return $version;
}
