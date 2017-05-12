#
# Building Makefile for Embperl
#
# (C) 1997-2001 G.Richter (richter@dev.ecos.de) / ECOS
#
# $Id: Makefile.PL,v 1.56 2002/03/12 05:05:16 richter Exp $
#


use ExtUtils::MakeMaker;
use Cwd qw {abs_path cwd} ;
use Config ;
use File::Basename ;
use Data::Dumper ;

$win32 = ($Config{osname} =~ /win32/i) ;
$aix = ($Config{osname} =~ /aix/i);
$dynlib = {};
print "\nRunning on Win 32\n" if ($win32) ;

$EP2 = -f "epcmd2.c" ; 

## ----------------------------------------------------------------------------



%neededmodules =
    ( 
      'mod_perl.c' => { name	    => 'perl_module', 
			path	    => ['$apache_src/modules/perl/libperl.so', '$EPBINDIR/modules/libperl.so', '$apache_src/mod_perl.so'],
			win32path   => ['$mpdll', '$mpdll/apachemoduleperl.dll', '$mpdll/mod_perl.so', '$EPBINDIR/modules/apachemoduleperl.dll', '$EPBINDIR/modules/mod_perl.so'],
			file	    => ['libperl.so', 'apachemoduleperl.dll', 'mod_perl.so'],
			filetext    => 'libperl.so or mod_perl.so',
			win32filetext   => 'ApacheModulePerl.dll or mod_perl.so',
		      },
      'mod_dir.c'  => { name	    => 'dir_module', 
			path	    => ['$apache_src/modules/standard/mod_dir.so', '$EPBINDIR/modules/mod_dir.so', '$apache_src/mod_dir.so'],
			win32path   => ['$apache_src/modules/standard/apachemoduledir.dll', '$EPBINDIR/modules/apachemoduledir.dll', '$EPBINDIR/modules/mod_dir.so'],
			file	    => ['mod_dir.so', 'apachemoduledir.dll'],
			win32filetext   => 'ApacheModuleDir.dll or mod_dir.so',
		      },

      'mod_env.c'  => { name	    => 'env_module', 
			path	    => ['$apache_src/modules/standard/mod_env.so', '$EPBINDIR/modules/mod_env.so', '$apache_src/mod_env.so'],
			win32path   => ['$apache_src/modules/standard/apachemoduleenv.dll', '$EPBINDIR/modules/apachemoduleenv.dll', '$EPBINDIR/modules/mod_env.so'],
			file	    => ['mod_env.so', 'apachemoduleenv.dll'],
			win32filetext   => 'ApacheModuleEnv.dll or mod_env.so',
		      },

      'mod_mime.c'  => { name	    => 'mime_module', 
			path	    => ['$apache_src/modules/standard/mod_mime.so', '$EPBINDIR/modules/mod_mime.so', '$apache_src/mod_mime.so'],
			win32path   => ['$apache_src/modules/standard/apachemodulemime.dll', '$EPBINDIR/modules/apachemodulemime.dll', '$EPBINDIR/modules/mod_mime.so'],
			file	    => ['mod_mime.so', 'apachemodulemime.dll'],
			win32filetext   => 'ApacheModuleMime.dll or mod_mime.so',
		      },

      'mod_alias.c'  => { name	    => 'alias_module', 
			path	    => ['$apache_src/modules/standard/mod_alias.so', '$EPBINDIR/modules/mod_alias.so', '$apache_src/mod_alias.so'],
			win32path   => ['$apache_src/modules/standard/apachemodulealias.dll', '$EPBINDIR/modules/apachemodulealias.dll', '$EPBINDIR/modules/mod_alias.so'],
			file	    => ['mod_alias.so', 'apachemodulealias.dll'],
			win32filetext   => 'ApacheModuleAlias.dll or mod_alias.so',
		      },

      'mod_cgi.c'  => { name	    => 'cgi_module', 
			path	    => ['$apache_src/modules/standard/mod_cgi.so', '$EPBINDIR/modules/mod_cgi.so', '$apache_src/mod_cgi.so'],
			win32path   => ['$apache_src/modules/standard/apachemodulecgi.dll', '$EPBINDIR/modules/apachemodulecgi.dll', '$EPBINDIR/modules/mod_cgi.so'],
			file	    => ['mod_cgi.so', 'apachemodulecgi.dll'],
			win32filetext   => 'ApacheModuleCgi.dll or mod_cgi.so',
		      },

      'mod_actions.c'  => { name	    => 'action_module', 
			path	    => ['$apache_src/modules/standard/mod_actions.so', '$EPBINDIR/modules/mod_actions.so', '$apache_src/mod_actions.so'],
			win32path   => ['$apache_src/modules/standard/apachemoduleactions.dll', '$EPBINDIR/modules/apachemoduleactions.dll', '$EPBINDIR/modules/mod_actions.so'],
			file	    => ['mod_actions.so','apachemoduleactions.dll'],
			win32filetext   => 'ApacheModuleActions.dll or mod_actions.so',
		      },


    ) ;




## ----------------------------------------------------------------------------


sub MY::test_via_harness 
	{
	my ($txt) = shift -> MM::test_via_harness (@_) ;
	$txt =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/ ;
	#$txt =~ s/\$\(FULLPERL\)/\$\(FULLPERL\) \-T / ;
	$txt =~ s/\$\(FULLPERL\)/SET PATH=\$\(PATH\)\;$EPENVPATH\n\t\$\(FULLPERL\)/ if ($win32) ;
	return $txt ;
	}

sub MY::test_via_script 
	{
	my ($txt) = shift -> MM::test_via_script (@_) ;
	$txt =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/ ;
	#$txt =~ s/\$\(FULLPERL\)/\$\(FULLPERL\) \-T / ;
	$txt =~ s/\$\(FULLPERL\)/SET PATH=\$\(PATH\)\;$EPENVPATH\n\t\$\(FULLPERL\)/ if ($win32) ;

	$txt =~ s/\$\(TEST_FILE\)/\$(TEST_FILE) \$(TESTARGS)/g ;

	return $txt ;
	}
	

sub MY::test

	{
	my ($txt) = shift -> MM::test (@_) ;


        $txt .= qq{

testdbinit : pure_all
\t\@echo set args -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE) \$(TESTARGS) > dbinitembperl

testdbbreak : pure_all
\t\@echo set args -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE) --dbgbreak \$(TESTARGS) > dbinitembperl
\t\@echo r >> dbinitembperl


testddd : testdbinit
\tPERL_DL_NONLAZY=0 ddd -x dbinitembperl \$(FULLPERL)  

testgdb : testdbinit
\tPERL_DL_NONLAZY=0 gdb -x dbinitembperl \$(FULLPERL)  

testdddb : testdbbreak
\tPERL_DL_NONLAZY=0 ddd -x dbinitembperl \$(FULLPERL)  

testgdbb : testdbbreak
\tPERL_DL_NONLAZY=0 gdb -x dbinitembperl \$(FULLPERL)  

start : pure_all
\tPERL_DL_NONLAZY=0 \$(FULLPERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE) --start -m \$(TESTARGS)

stop : pure_all
\tPERL_DL_NONLAZY=0 \$(FULLPERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE) --kill -m \$(TESTARGS)


} ;
	$txt =~ s/\tPERL_DL_NONLAZY=0 /\tSET PATH=\$\(PATH\)\;$EPENVPATH\n\t/g if ($win32) ;
        
        $txt =~ s/\@cd/\n#\t\@cd/ ;  # remove tests for subdirs

	$txt =~ s/\r\n/\n/g ;  # make doesn't like \r\n!

        
        return $txt ;
        }



sub MY::xs_c 
	{
	my ($txt) = shift -> MM::xs_c (@_) ;
	$txt =~ s/\&\&/\n\t/ if ($win32) ;
	return $txt ;
	}

sub MY::dist_test 
	{
	my $self = shift ;
        
        my $txt = $self -> MM::dist_test (@_) ;
	$txt =~ s/-I\$\(PERL_ARCHLIB\) -I\$\(PERL_LIB\)// ;
	$txt =~ s/\$\(PERL\)/\$\(PERLDT\)/ ;
	
        $main::perlbinpath = $self -> {FULLPERL} ;
        
        return $txt ;
	}
	
sub MY::dynamic 
	{
	my $self = shift ;
        
        my $txt = $self -> MM::dynamic (@_) ;

        $txt .= "\tcd crypto && \$(MAKE) SSL_BASE=$sslbase\n" if ($epc_enable) ;
        
        return $txt ;
	}

sub MY::c_o
	{
	my $self = shift ;
        
        my $txt = $self -> MM::c_o (@_) ;
        my $opt = $win32?'Fo':'o ' ;

        $txt =~ s/\$\*/-$opt\$*\$(OBJ_EXT) \$*/g ;
        my @txt = split (/\n/, $txt) ;
        my $cpp = 0 ;
        foreach (@txt)
            {
            if (/\$\*\.cpp/)
                {
                s/\$\(CCCMD\)/\$(CPPCMD) \$(CPPFLAGS)/ ;
                }
            }
        $txt = join ("\n", @txt) ;

        return $txt ;
	}



sub MY::cflags 
	{
	my $self = shift ;
        
        my $txt = $self -> MM::cflags (@_) ;
	$txt =~ s/CCFLAGS\s*=/CCFLAGS = $ccdebug / ;
        
        return $txt ;
	}

$MY::cccmd_seen = 0 ;
sub MY::const_cccmd 
	{
	my $self = shift ;
        
        my $txt = $self -> MM::const_cccmd (@_) ;
        return $txt if ($MY::cccmd_seen++) ;

	my $txt2 = $txt ;
        $txt2 =~ s/\$\(CC\)/\$(CPP)/ ;
        $txt2 =~ s/CCCMD/CPPCMD/ ;

        return "$txt\n\n$txt2"  ;
	}


	
 sub MY::post_initialize
        {
        my $self = shift ;

        # move docs to the right place
         
        my $pm = $self -> {PM} ;
        my $k ;
        my $v ;
        while (($k, $v) = each (%$pm))
            {
            if (($k =~ /\.pod$/) && !($k =~ /^Embperl/) )
                {
                $v =~ s#^(.*/)(.*?)\.pod$#$1Embperl/$2.pod# ;
                $pm -> {$k} = $v ;
                }
            }
                                 
        my $man = $self -> {MAN3PODS} ;
        while (($k, $v) = each (%$man))
            {
            if (!($v =~ /::Embperl/))
                {
                $v =~ s#HTML::#HTML::Embperl::# ;
                $man -> {$k} = $v ;
                }
            }

       $self -> MM::post_initialize (@_) ;
       }


 sub MY::post_constants
       {
       my $self = shift ;


       my $txt = $self -> MM::post_constants (@_) ;

       $txt .= "\n# Change name of dynamic lib, in case we need two of them (with and w/o Apache support)\nINST_DYNAMIC = \$(INST_ARCHAUTODIR)\\\$(DLBASE).NoApache.\$(DLEXT)\n" if ($EPNOAPACHELIB) ;

       return $txt ;

       }

## ----------------------------------------------------------------------------

sub GetString
	{
	my ($prompt, $default) = @_ ;

	printf ("%s [%s]", $prompt, $default) ;
	chomp ($_ = <STDIN>) ;
	s/\s+$//;
        if (!/^\s*$/)
	    {return $_ ;}
	else
    	{
        if ($_ eq "")
	        {return $default ;}
	    else
            { return "" ; }
    
        }
    }

## ----------------------------------------------------------------------------

sub GetYesNo
	{
	my ($prompt, $default) = @_ ;
	my ($value) ;

	do
	    {
	    $value = lc (GetString ($prompt . "(y/n)", ($default?"y":"n"))) ;
	    }
	until (($value cmp "j") == 0 || ($value cmp "y") == 0 || ($value cmp "n" ) == 0) ;

	return ($value cmp "n") != 0 ;
	}


## ----------------------------------------------------------------------------

sub search_config

    {
    my ($key, $path) = @_ ;


    open CFGFH, $path or return undef ;

    while (<CFGFH>)
        {
        return $1 if (/^$key\s*(?:=|\s)\s*(.*?)$/) ;
        }

    close CFGFH ;
    return undef ;
    }

## ----------------------------------------------------------------------------


sub cnvpath

    {
    my $path = shift ;
    
    $path =~ s/\//\\/g if ($win32) ;

    return $path ;
    }

## ----------------------------------------------------------------------------


sub cnvpath2unix

    {
    my $path = shift ;
    
    $path =~ s#\\#/#g if ($win32) ;

    return $path ;
    }

## ----------------------------------------------------------------------------


sub start

    {
    my ($cmd) = @_ ;


    $cmd =~ s/\//\\/g if ($win32) ;

    
    open STFH, "$cmd|" or die "\nCannot start $cmd\nPlease make sure you have build Apache and mod_perl before makeing Embperl\n" ;

    my @x = <STFH> or die "\nCannot start $cmd\nPlease make sure you have build Apache and mod_perl before makeing Embperl\n" ;

    close STFH ;
    return @x ;
    }


## ----------------------------------------------------------------------------


sub start_errcode

    {
    my ($cmd) = @_ ;


    $cmd =~ s/\//\\/g if ($win32) ;

    
    open STFH, "$cmd|" or return 1 ;

    my @x = <STFH> ;

    #print "@x" ;

    my $code = close STFH ;
    #print "Code = $code ; ? = $?\n" ;

    return $? ;
    }


## ----------------------------------------------------------------------------
#
# Check if required modules present
#


sub CheckModule

    {
    my ($mod, $text) = @_ ;

    eval "require $mod" ;
    if ($@)
        {
        print "$mod not installed on this system\n" ;
        print "$text\n" ;
        return undef ;
        }
    else
        {
        my $ver = ${"$mod\:\:VERSION"} ;
        print "Found $mod  Version $ver\n" ;
        return $ver ;
        }
    }
         


## ----------------------------------------------------------------------------
#
# Check if known config
#


$apache = 0 ;
$b = 0 ;

$optdebug = '' ;
$ccdebug = '' ;
$lddebug = '' ;
$libs    = '' ;
$d       = '' ;

if ($ARGV[0] eq 'debug')
    {
    shift @ARGV;
    $optdebug = '-g -O0' ;
    if ($win32)
        {
        $ccdebug = '-Zi -W3' ;
        $lddebug = '-debug -map -profile' ;
        }
    else
        {
        $ccdebug = '-ggdb -O0' ;
        $lddebug = '-g' ;
        }
    }

if ($ARGV[0] eq 'dmalloc')
    {
    shift @ARGV;
    if ($win32)
        {
        }
    else
        {
        $libs .= '-L/usr/local/lib -ldmalloc' ;
        $d    .= '-DDMALLOC' ;
        }
    }

if (defined ($ARGV[0]) && ($ARGV[0] =~ /^\W/))
    {
    $apache = 2 ;
    $b = 1 ;
    $apache_src = shift @ARGV ;
    }
elsif (defined ($ENV{APACHE_SRC}))
    {
    $apache = 2 ;
    $b = 1 ;
    $apache_src = $ENV{APACHE_SRC} ;
    $apache_src = '' if ($apache_src eq '-') ;
    }

if (!$apache && $apache_src eq '')
    {
    eval 'use Apache::MyConfig' ;

    if ($@ eq '')
        { 
        $apache_src = $Apache::MyConfig::Setup{Apache_Src} ; 
        }
    else
        {
        $apache_src = '' ;
        }
    }

eval 'do "test/conf/config.pl"' ;


if (!$apache && $apache_src eq '')
    {
    $apache_src = $EPAPACHESRC ;
    $loadmodules = $EPMODPERL ;
    }

$base = '..' ;
$base = $ENV{'ProgramFiles'} if ($win32) ;


$apache = GetYesNo ("Build with support for Apache mod_perl?", 'y') if (!$apache) ;

if ($apache && $apache_src ne '')
    {
    if ($apache_src =~ /^(.*?)\/$/)
   	{ $apache_src = $1 ; } 

    if ($apache_src =~ /^(.*?)\/main$/)
   	{ $apache_src = $1 ; } 

    if ($apache_src =~ /^(.*?)\/include$/)
   	{ $apache_src = $1 ; } 

    if (-e "$apache_src/httpd.h" || -e "$apache_src/main/httpd.h" || -e "$apache_src/include/httpd.h")
	    {
	    $b = GetYesNo ("Use $apache_src as Apache source", 'y') if (!$b) ;
	    }
    }

while ($apache && !$b)
    {
    print "Searching for Apache sources...\n" ;
    foreach $src_dir ($base,
		      "$base/src",
		      <$base/apache*/src>,
		      <$base\\apache*\\include>,
		      <$base\\apache*\\apache*\\include>,
		      <./src>)
       {
	print "Look at $src_dir\n" ;
	
	if (-e "$src_dir/httpd.h" || -e "$src_dir/main/httpd.h" || -e "$src_dir/include/httpd.h")
		{
		$b = GetYesNo ("Use $src_dir as Apache source", 'y') ;
		if ($b)
			{
			$apache_src = $src_dir ;
			last ;
			}
		}
	}		

    if ($apache_src =~ /^(.*?)\/$/)
   	{ $apache_src = $1 ; } 

    if ($apache_src =~ /^(.*?)\/main$/)
   	{ $apache_src = $1 ; } 

    if ($apache_src =~ /^(.*?)\/include$/)
   	{ $apache_src = $1 ; } 


    if (!$b)
    	{
    	$base = GetString ("Apache source not found, enter path name or q to quit", '') ;
    	if ($base eq 'q')
    		{
    		$apache = 0 ;
    		}
        else
            {
            $base =~ s/\//\\/g if ($win32) ;
            }    	
    	}
    }

if ($b && $apache && $apache_src ne '')
    {
    $apache_src = abs_path ($apache_src) ;

    print "Will use $apache_src for Apache Headers\n" ;

    #### look in which subdir the include files resides ####
    
    if (-e "$apache_src/httpd.h")
         {
         $inc_dir = $apache_src ;
         }
    elsif (-e "$apache_src/main/httpd.h")
         {
         $inc_dir = "$apache_src/main" ;
         }
    elsif (-e "$apache_src/include/httpd.h")
         {
         $inc_dir = "$apache_src/include" ;
         }
    elsif (-e "$ENV{APACHE_HDR}/httpd.h")
         {
         $inc_dir = "$ENV{APACHE_HDR}" ;
         }
        

    if ($win32)
	{ 
        $i = "-I. -I\"$inc_dir\" -I\"$apache_src/regex\" -I\"$apache_src/os/win32\"" ;
        
        foreach (
                    "$apache_src/libexec",
                    "$apache_src/../libexec",
                    "$apache_src/CoreD",
                    "$apache_src/CoreR",
                    "$apache_src/Debug",
                    "$apache_src/Release",
                    $EPHTTPDDLL)
            {
            if (-e "$_/ApacheCore.lib")
                {
                $EPHTTPDDLL = $_ ;
                $o = " \"$_/ApacheCore.lib\"" ;
                last ;
                }
            }

        if (!$o)
            {
            my $oo ;
            while (1)
                {
                $oo = GetString ("ApacheCore.lib not found, please enter path", $o) ;
                $oo .= '/ApacheCore.lib' if ($oo !~ /\.lib$/i) ;
                if (-e $oo)
                    {
                    $oo =~ s#\\#/#g ;
                    $oo =~ s#//#/#g ;
                    $EPHTTPDDLL = $1 if ($o =~ /^(.*)\//) ;
                    $o = " \"$oo\"" ;
                    last ;
                    }
                }
            }

        }
    else
	{
        $i = "-I$inc_dir -I$apache_src/regex -I$apache_src/os/unix" ; 
        $o = '' ;
        }
    $d .= ' -DAPACHE' ;
    $EPNOAPACHELIB = 0 ;
    }
else
    {
    $apache = 0 ;
    if ($win32 && ($EPAPACHESRC || $EPNOAPACHELIB) && -f 'blib/arch/auto/HTML/Embperl/Embperl.dll')
        {
        print "\nYou have already build Embperl with support for Apache mod_perl\n" ;
        $EPNOAPACHELIB = GetYesNo ("Do you want to build a separate dynamic library for use without Apache?", 'y') ;
        }


    print "Will build without mod_perl support\n" ;
    $i = '' ;
    $o = '' ;
    }
		

if ($win32 && $apache)
    {	# borrowed from mod_perl
    local *DEFH;
    open DEFH, ">dirent.h" || die "can't write dirent.h $!";
    print DEFH <<EOF;
/* major kludge to workaround conflict(s) between perl's dirent.h and apache's readdir.h */

#ifdef WIN32

#define _INC_DIRENT
#define DIR void

#endif

EOF
    close DEFH;

    if ($ENV{APACHE_PERL_DLL})
	{
	$mpdll = $ENV{APACHE_PERL_DLL} ;
	}
    elsif ($EPMODPERL =~ /^LoadModule perl_module (.*?)$/)
	{
	$mpdll = $1 ;
	}
    }

#
# Check to see which user to use for httpd tests
#
$loadmodules = $EPMODPERL ;
$EPPATH    = cwd ;
$EPMODPERL = '' ;
$EPSTARTUP ='startup.pl' ;

if ($b && $apache)
    {
    $EPPORT  = 8531 ;
    if (!$win32)
        {
        $EPUSER  = getpwuid($>) ||  $> ;
        $EPGROUP = getgrgid($)) || $) ;
        if ($EPUSER eq 'root')
            {
            my $nobody = (getpwnam('nobody'))[0] ;
            $EPUSER = $nobody if $nobody ;
            }

        if ($EPUSER eq 'root')
            {
            print "Cannot run test httpd as User $EPUSER\n" ;
            $EPUSER = GetString ("User to run httpd", 'nobody') ;
            $EPGROUP = GetString ("Group to run httpd", $EPGROUP) ;
            }
        
        $EPHTTPD = "$apache_src/httpd" ;
        $EPHTTPD = $ENV{EPHTTPD} if (defined ($ENV{EPHTTPD})) ;
        $EPHTTPD = "$apache_src/httpsd" if (!-e $EPHTTPD && -e "$apache_src/httpsd") ;
        
        if (!-e $EPHTTPD)
            {
            $EPHTTPD = GetString ("Enter path and file to start as httpd", "$EPHTTPD") ;
            }
	
	$EPMODPERL="" ;
        }
    else
        {
        if (!$EPHTTPD || !-e $EPHTTPD)
            {
            $EPHTTPD = "$EPHTTPDDLL/Apache.exe" ;
            $EPHTTPD =~ s#core([rd])/Apache.exe#Apache$1/Apache.exe#i ;
            $EPHTTPD =~ s#libexec/Apache.exe#Apache.exe#i ;
            }
        $EPUSER  = 'www' ; # dummy value
        $EPGROUP = 'www' ;
        if (!-e $EPHTTPD)
            {
            $EPHTTPD = GetString ("Enter path and file to start as Apache.exe", "$EPHTTPD") ;
            }
        $EPHTTPDPATH = $EPHTTPD ;
        $EPHTTPDPATH =~ s/Apache.exe//i ;
        }
    

    ### check the apache version ###
                                
    $EPENVPATH = ";$Config{bin};$EPHTTPDDLL;$EPHTTPDPATH;$EPHTTPDDLL/../os/win32/release;$EPHTTPDDLL/../os/win32/debug" ;
    $ENV{PATH} .= $EPENVPATH if ($win32) ;
    
    @EPAPACHEVERSION = start ("\"$EPHTTPD\" -v") ;
    @modules         = start ("\"$EPHTTPD\" -l") ;

    chomp ($EPAPACHEVERSION[0]) ;
    print "Apache Version $EPAPACHEVERSION[0]\n" ;

    $EPSTRONGHOLD = ($EPAPACHEVERSION[0] =~ /stronghold/i) ;
    $EPAPACHE_SSL = grep (/apache_ssl.c/, @modules) ;
    $EPMOD_SSL    = !$EPSTRONGHOLD && grep (/mod_ssl.c/, @modules) ;

    $EPBINDIR	  = dirname ($EPHTTPD) ;    
    $EPMODPERL	  = '' ;
    
    $addmodpath = '' ;
    while (($mod, $opt) = each %neededmodules)
	{
	if (!grep (/$mod/, @modules))
	    { # module not linked staticly
	    $paths = $win32?$opt->{win32path}:$opt->{path} ;
	    $modfile = $win32?$opt->{win32file}:$opt->{file}[0] ;
	    $modfiletext = ($win32?$opt->{win32filetext}:$opt->{filetext}) || $modfile ;
	    $found = 2 ;
	    searchmod:
            while ($found == 2)
		{
		$found = 0 ;
		if ($addmodpath)
		    {
                    foreach $modfile (@{$opt->{file}})
                        {
		        $path = cnvpath ("$addmodpath/$modfile") ;
		        #print "path = $_ -> $path\n" ;
		        if (-f $path)
			    { ## module fould
	    		    $EPMODPERL .= "\r\nLoadModule $opt->{name} \"$path\"" ;
			    print " + Load dynamic module $mod\n   ($path)\n" ;
			    $found = 1 ;
			    last searchmod ;
			    }
		        }
                    }
		foreach (@$paths)
		    {
		    $path = cnvpath (eval "\"$_\"") ;
		    #print "path = $_ -> $path\n" ;
		    if (-f $path)
			{ ## module fould
	    		$EPMODPERL .= "\r\nLoadModule $opt->{name} \"$path\"" ;
			print " + Load dynamic module $mod\n   ($path)\n" ;
			$found = 1 ;
			last ;
			}
		    }
                if (!$found && $loadmodules)
                    {		
                    if ($loadmodules =~ /LoadModule $opt->{name} \"(.*?)\"$/)
                        {
                        $path = $1 ;
		        if (-f $path)
			    { ## module fould
	    		    $EPMODPERL .= "\r\nLoadModule $opt->{name} \"$path\"" ;
			    print " + Load dynamic module $mod\n   ($path)\n" ;
			    $found = 1 ;
			    last ;
			    }
                        }
                    }                            
                
                if (!$found)
		    {
		    my $w32msg = '' ;
		    $w32msg = "\nPlease enter full path including the drive letter!! " if ($win32) ;
		    $addmodpath = GetString ("Library for $mod not found, please enter path to $modfiletext $w32msg", "") ;
		    $found = 2 ;
		    }
		}			    
	    }
	}


		    

    $use_dso = 0 ;
    if (!$win32 && ($EPMODPERL =~ /perl_module/))
	{
        print " + mod_perl was build with USE_DSO\n" ;
	$use_dso = 1 ;
        }

    require Apache::src;
    $dynlib->{'OTHERLDFLAGS'} = Apache::src->new->otherldflags if (defined (&Apache::src::otherldflags)) ;


    if ($EPSTRONGHOLD) 
        {
        $i .= " -I$apache_src/../ssl/include" ;
        $d .= " -DSTRONGHOLD" ;
        print " + found Stronghold\n" ;
        }
    elsif ($EPAPACHE_SSL)
        {
        $d .= " -DEPAPACHE_SSL" ;
        print " + found Apache SSL\n" ;
        }
    elsif ($EPMOD_SSL)
        {
        $sslbase = search_config ('SSL_BASE', "$apache_src/Configuration.apaci") ;
        $sslbase = search_config ('SSL_BASE', "$apache_src/Configuration") if (!$sslbase) ;
        print " + found mod_ssl\n" ;
        $EPSSLDISABLE = !start_errcode ("\"$EPHTTPD\" -t -f $EPPATH/test/conf/ssldisable.conf") ;
        }



    if ($EPSTRONGHOLD)
        {
        my $conf = "$apache_src/../conf/httpd.conf";
        if(-e $conf) 
            {
	    open FH, $conf;
	    while(<FH>)
                {
	        if(/^StrongholdKey/)
                    {
                    chomp ;
		    $EPSTRONGHOLDKEY = $_;
		    last;
	            }
	        }
	    close FH;
            }
        }
    else
        {
        $EPSTRONGHOLDKEY = '' ;
        }

    $epc_enable = search_config ('\s*#define\s+EPC_ENABLE', "crypto/epcrypto_config.h") ;
    if ($epc_enable)
        {
        $sslbase = search_config ('SSL_BASE', "$apache_src/Configuration.apaci") if (!$sslbase) ;
        $sslbase = search_config ('SSL_BASE', "$apache_src/Configuration") if (!$sslbase) ;
        $sslbase = '/usr/local/ssl' if (!$sslbase) ;
        $libs .= " -L$sslbase/lib -lcrypto" ;
        $o    .= ' crypto/epcrypto$(OBJ_EXT) ' ;
        print "Enable crypted sourcefiles\n" ;
        }

    if ($sslbase) 
        {
        $i .= " -I$sslbase/include" 
        }

    print "Test start $EPHTTPD\n" ;
    print "Test httpd will run as user $EPUSER and group $EPGROUP\n" if (!$win32) ;
    print "Test httpd will listen on port $EPPORT\n" ;
    print "Test will use $EPSTRONGHOLDKEY\n" if($EPSTRONGHOLDKEY) ;


    ### check for required modules ###
    
    if (($MPVer = CheckModule ("mod_perl", "-> Cannot build for mod_perl without mod_perl installed!!")))
        {
        if ($win32 && $MPVer lt "1.12")
            {
            print "-> Please upgrade to an higher version of mod_perl on Win32\n" ;
            }
        if ($use_dso && $MPVer lt "1.22")
            {
            print "-> You MUST upgrade to mod_perl 1.22 or higher when mod_perl is build with USE_DSO!!\n" ;
            $EPSTARTUP ='startup_dso.pl' ;
            }
        if ($aix && $MPVer lt "1.22")
            {
            print "-> You MUST upgrade to mod_perl 1.22 or higher to use Embperl on AIX!!\n" ;
            $EPSTARTUP ='startup_dso.pl' ;
            }
        }

    if (CheckModule ("LWP::UserAgent", "-> Cannot test mod_perl and CGI mode"))
        {
        CheckModule ("HTML::HeadParser", "-> Is required by LWP::UserAgent");
        }

    $SessVer = CheckModule ("Apache::Session", "-> Disable tests for persistent data storage") || '' ;

    if ($SessVer && !($SessVer >= 1.00))
        {
        if ($SessVer && !($SessVer =~ /0\.17/))
            {
            print "-> Embperl works only with Apache::Session 1.00 and higher\n" ;
            print "-> Disable tests for persistent data storage\n" ;
            $SessVer = '0' ;
            }
        else
            {
            print "-> Embperl does not support Apache::Session 0.17.x anymore.\n" ;
            print "-> Please upgrade to 1.50 or higher.\n" ;
            print "-> Disable tests for persistent data storage.\n" ;
            $SessVer = '0' ;
            }
        }

    $SessXVer = CheckModule ("Apache::SessionX", "-> Disable tests for persistent data storage") || '' if ($SessVer) ;
    $SessVer ||= 0 ;

    if (($FSVer = CheckModule ("File::Spec", "-> Required for EmbperlObject, make test will fail whithout File::Spec")) < 0.8)
        {
        print "-> EmbperlObject requires File::Spec 0.8 or higher, found $FSVer, please upgrade!\n" ;
        }
        
    CheckModule ("CGI", "-> File Upload will not work without CGI.pm installed") ;

    ### write out test configuration file ###

    open FH, ">$EPPATH/test/conf/config.pl" or die "Cannot open $EPPATH/test/conf/config.pl" ;
    print FH "# This file is automaticly generated by Makefile.PL, do not edit\n" ;
    print FH "\$EPPATH='" . cnvpath($EPPATH) . "' ;\n" ;
    print FH "\$EPUSER='$EPUSER' ;\n" ;
    print FH "\$EPGROUP='$EPGROUP' ;\n" ;
    print FH "\$EPPORT=$EPPORT ;\n" ;
    print FH "\$EPHTTPD='" . cnvpath($EPHTTPD) . "' ;\n" ;
    print FH "\$EPHTTPDDLL='" . cnvpath($EPHTTPDDLL) . "' ;\n" ;
    print FH "\$EPWIN32='$win32' ;\n" ;
    print FH "\$EPAPACHESRC='" . cnvpath($apache_src) . "' ;\n" ;
    print FH "\$EPAPACHE_SSL='" . $EPAPACHE_SSL . "' ;\n" ;
    print FH "\$EPSTRONGHOLD='$EPSTRONGHOLD' ;\n" ;
    print FH "\$EPSSLDISABLE='$EPSSLDISABLE' ;\n" ;
    print FH "\$EPSTRONGHOLDKEY='$EPSTRONGHOLDKEY' ;\n" ;
    print FH "\$EPMODPERL='" . cnvpath2unix($EPMODPERL) . "';\n" ;
    print FH "\$EPSTARTUP='" . cnvpath($EPSTARTUP) . "';\n" ;
    print FH "\$EPAPACHEVERSION='$EPAPACHEVERSION[0]';\n" ;
    print FH "\$EPSESSIONVERSION='$SessVer';\n" ;
    print FH "\$EPSESSIONXVERSION='$SessXVer';\n" ;
    print FH "\$EP2='$EP2';\n" ;
    print FH "\$EPMODPERLVERSION='$MPVer';\n" ;
    print FH "\$EPC_ENABLE='$epc_enable';\n" ;
    print FH "\$EPNOAPACHELIB='$EPNOAPACHELIB';\n" ;
    if ($win32)
        {
        print FH "\$EPNULL='nul';\n" ;
        }
    else
        {
        print FH "\$EPNULL='/dev/null';\n" ;
        }



    }
else
    {
    ### check for required modules ###

    $SessVer = CheckModule ("Apache::Session", "-> Disable tests for persistent data storage") || '' ;

    if ($SessVer && $SessVer lt "0.17")
        {
        print "-> Please upgrade to Apache::Session 0.17 or higher\n" ;
        print "-> Disable tests for persistent data storage\n" ;
        $SessVer = 0 ;
        }

    $SessXVer = CheckModule ("Apache::SessionX", "-> Disable tests for persistent data storage") || '' if ($SessVer) ;
    $SessVer ||= 0 ;

    ### write out test configuration file ###

    open FH, ">$EPPATH/test/conf/config.pl" or die "Cannot open $EPPATH/test/conf/config.pl" ;
    print FH "# This file is automaticly generated by Makefile.PL, do not edit\n" ;
    print FH "\$EPPATH='$EPPATH' ; \n" ;
    print FH "\$EPENVPATH='$EPENVPATH' ; \n" ;
    print FH "\$EPHTTPD='' ;\n" ;
    print FH "\$EPWIN32='$win32' ;\n" ;
    print FH "\$EPSESSIONVERSION='$SessVer';\n" ;
    print FH "\$EPSESSIONXVERSION='$SessXVer';\n" ;
    print FH "\$EPSSLDISABLE='$EPSSLDISABLE' ;\n" ;
    print FH "\$EP2='$EP2';\n" ;
    print FH "\$EPNOAPACHELIB='$EPNOAPACHELIB';\n" ;
    print FH "\$EPC_ENABLE='$epc_enable';\n" ;
    print FH "\$EPHTTPD='" . cnvpath($EPHTTPD) . "' ;\n" ;
    print FH "\$EPHTTPDDLL='" . cnvpath($EPHTTPDDLL) . "' ;\n" ;
    print FH "\$EPWIN32='$win32' ;\n" ;
    print FH "\$EPAPACHESRC='" . cnvpath($EPAPACHESRC) . "' ;\n" ;
    print FH "\$EPMODPERL='" . cnvpath2unix($loadmodules) . "';\n" ;
    }

# $d .= ' -DPERL_IS_5_6 ' if $] >= 5.006;

if ($win32)
    { 
    # check for inclusion of malloc.h and signal.h
    if ($Config{usemultiplicity})
        {
        $d .= ' -D_INC_MALLOC -D_INC_SIGNAL ';
        }

    # Check for winsock2api
    
    my $os_h = "$inc_dir/os.h" ;
    $os_h = "$inc_dir/../os/win32/os.h" if (!-e $os_h) ;
    
    if (open FH2, $os_h )
        {
        my @conf = <FH2> ;
        close FH2 ;

        if (grep (/winsock2\.h/, @conf))
            {
            $d .= ' -D_WINSOCK2API_ -D_MSWSOCK_ ' ;
            }
        elsif (open FH2, "$inc_dir/ap_config.h")
            {
            @conf = <FH2> ;
            close FH2 ;

            if (grep (/winsock2\.h/, @conf))
                {
                $d .= ' -D_WINSOCK2API_ ' ;
                }
            }
        }
    
    $d .= ' -D_WINDOWS ';
    $d .= ' -DMULTIPLICITY' if ($Config{usemultiplicity}) ;

    }

$d .= ' -DEP2' if ($EP2) ;

$dynlib->{'OTHERLDFLAGS'} .= " $lddebug" ;

# 
# See if we need to link to any other libraries
#

my $makemacros = {} ;
if ($EP2)
    {
    opendir DH, "driver" or die "Cannot open directory driver ($!)" ;
    my @files = readdir DH ;
    closedir DH ;
    my @makefiles = grep (/\.MAKEPL$/, @files) ;

    foreach my $makepl (@makefiles)
        {
        #print "Exec driver/$makepl\n" ;
        my $result = do "driver/$makepl" ;
        if ($@)
            {
            print $@ ;
            next ;
            }
        if (ref $result)
            {
            #while (my ($k, $v) = each %$result)
            #    {
            #    print "$k = $v\n" ;
            #    }
            $libs .= ' ' . $result->{libs} ;
            $i    .= ' ' . $result->{cflags} ;
            $d    .= ' ' . $result->{defines} ;
            $o    .= ' ' . $result->{objects} ;
            $makemacros->{CPP} = $result->{cpp} if ($result->{cpp}) ;
            $makemacros->{CPPFLAGS} = $result->{cppflags} if ($result->{cppflags}) ;
            if ($result->{save})
                {
                while (($k, $v) = each (%{$result->{save}}))
                    {
                    print FH "$k='" . $v . "';\n" ;
                    }
                }           
            }
        }

    }


close FH ;

$i .= " -I$EPPATH/xs" ;

%MMARGS = (
    'LIBS'	   => [$libs || ''],   			 
    'DEFINE'	   => "$d \$(DEFS)", 			 
    'INC'	   => "-I$EPPATH $i",     			 
    'VERSION'      => undef,
    'VERSION_FROM' => "$EPPATH/Embperl.pm",
    $optdebug?('OPTIMIZE' => $ccdebug):(),
    ) ;


if ($EP2)
    {
    open FH, ">xs/mmargs.pl" or die "Cannot open xs/mmargs.pl ($!)" ;
    print FH Data::Dumper -> Dump ([\%MMARGS], ['MMARGS']) ;
    close FH ;
    }

my $sublibs .= ' ' . 
join ('$(OBJ_EXT) ', qw{
xs/Embperl/App/App
xs/Embperl/App/Config/Config
xs/Embperl/Component/Component
xs/Embperl/Component/Config/Config
xs/Embperl/Component/Param/Param
xs/Embperl/Component/Output/Output
xs/Embperl/Req/Req
xs/Embperl/Req/Config/Config
xs/Embperl/Req/Param/Param
xs/Embperl/Thread/Thread
xs/Embperl/Syntax/Syntax
}) . '$(OBJ_EXT)';

$sublibs =~ s/\//\\/g if ($win32) ;
$o .= $sublibs if ($EP2) ;

WriteMakefile(
    'NAME'	   => 'HTML::Embperl',
    'VERSION_FROM' => 'Embperl.pm', 		# finds $VERSION
    'OBJECT'       => 'Embperl$(OBJ_EXT) epmain$(OBJ_EXT) epio$(OBJ_EXT) epchar$(OBJ_EXT) eputil$(OBJ_EXT) epeval$(OBJ_EXT) epapinit$(OBJ_EXT) ' . 
                       ($EP2?'epmem$(OBJ_EXT) epinit$(OBJ_EXT) epcgiinit$(OBJ_EXT) epcmd2$(OBJ_EXT) epparse$(OBJ_EXT) epdom$(OBJ_EXT) epcomp$(OBJ_EXT) epcache$(OBJ_EXT) epprovider$(OBJ_EXT)':'epcmd$(OBJ_EXT) ') . $o,
    'LIBS'	   => [$libs || ''],   			 
    'DEFINE'	   => "$d \$(DEFS)", 			 
    'INC'	   => $i,     			 
    'EXE_FILES'    => [ 'embpexec.pl' ],
    'clean'        => { FILES => 'dirent.h test/conf/httpd.conf test/tmp/* Embperl.c' },
    'realclean'    => { FILES => 'embpexec.pl embpexec.bat embpcgi.pl embpcgi.test.pl embpcgi.bat test/conf/config.pl' },
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz'},
    'dynamic_lib'  => $dynlib,
    'PREREQ_PM'    => { 'File::Spec' => 0.8 },
    'ABSTRACT'     => 'Embed Perl code in HTML documents',
    'AUTHOR'       => 'Gerald Richter <richter@dev.ecos.de>',
    'macro'        => $makemacros,
    $EP2?('depend'       => { 'Embperl.c' => 'Embperl.xs DOM.xs Cmd.xs Syntax.xs Old.xs' }):(),
);



#
# Change path to perl binary
#

@bins = ('embpexec.pl','embpexec.bat', 
         'embpcgi.pl', 'embpcgi.test.pl', 'embpcgi.bat',
	 'embpfastcgi.pl', 
         'epocgi.pl', 'epocgi.test.pl', 'epocgi.bat',
         $EP2?('embpmsgid.pl'):(),
         
         ) ;


die "Missing path to perl binary" if (!$perlbinpath) ;


foreach $f (@bins)
	{
	open IN, "<$f.templ" or die "Cannot open $f.templ" ;
	open OUT, ">$f" or die "Cannot open $f" ;
	my $l = 1 ;
        while (<IN>)
		{
		if ($l++ < 10)
                    {
		    #if ($win32)
		    #	{
                    #	s/^\#\!.*?perl.*?\s(.*?)/#!perl $1/ ;
		    #	}
		    #else
		    #	{
                    	s/^\#\!.*?perl.*?\s(.*?)/#!$perlbinpath $1/ ;
		    #	}
		    s/^.*?perl.*?\s-x/$perlbinpath -x/ ;
                    }
		print OUT $_ ;
		}
	close IN ;
	close OUT ;
	chmod 0755, $f or die "Cannot set executable $f" ;
	}

unlink ('Embperl.c') ;

