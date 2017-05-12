use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
use strict;
use 5.006;   # builds on 5.005, but Slaven Rezic got strange testresults
use Config;

use Getopt::Long;
my %options;

my @whichcand = qw(/bin/which /usr/bin/which);

my @KRB5_CONFIG_TRIES = (

    '/usr/kerberos/bin/krb5-config',   # for use with CentOS,  as suggested by Mark Hedges in https://rt.cpan.org/Ticket/Display.html?id=48732
    '/usr/bin/krb5-config',            # always worth a try ;-)

);


my $LINE = "\n\n----------------------------------------------------------\n";
&GetOptions(\%options , "gssapiimpl=s",  "help", "gssapi_libs=s", "gssapi_inc=s", "gssapi_lddlflags=s");

open(MANIFEST, "MANIFEST")	or die "$0: Unable to open MANIFEST: $!";
my $otherxs = join " ",
		map { substr($_, 0, -1) }
		grep { m:^xs/: }
		<MANIFEST>;
close(MANIFEST);



if ($options{'help'}){
print <<HELP;

==================================================================
BUILDING HELP
==================================================================

Hello - you obviously need Help! :-)

This additional command line options are available
for adjusting:

(1) --gssapiimpl /bla/local/heimdal
  This tells me where to look for your installed
  GSSAPI installation MIT or Heimdal.
  This must be the directory that contains
  the ./bin/krb5_config utility.

(2) --gssapi_libs='-L/bla/local/mitkrb/lib -lgss_all'
  The precise location of the libraries with -L and the libraries needed with -l.

(3) --gssapi_inc -I/bla/local/mitkrb/include
  The exact location of the header files.

(4) --gssapi_lddlflags='-shared -Wl,--enable-new-dtags -Wl,-rpath -Wl/bla/local/mitkrb/lib'
  Allows for any flags to be passed to the linker, for instance if WriteMakefile ignores
  entries in LIBS.

Option (1) is preferred, use (2),(3) and (4) only if needed and you know what you
are doing. If any of (2),(3) or (4) is supplied, (1) will be ignored.

HELP
;
  exit;
}

#-------------------------------------------------------------
print "\n Welcome to GSSAPI.pm setup! \n\n ($0 Version 0.03) \n";
print qq{\n run "perl Makefile.PL --help" to see further installation options\n};

#---------------------------------------------------------------
my @GSSLIBS = ();
my @LDDLFLAGS = ();
my $incconf = '';
my @EXTRADEFINES;
#---------------------------------------------------------------

if (exists $options{gssapi_libs} || exists $options{gssapi_inc} || exists $options{gssapi_lddlflags} ) {
    if ($options{gssapi_libs}) {
	push @GSSLIBS, $options{gssapi_libs}
    } else {
	die 'if options gssapi_inc or gssapi_lddlflags are provided, then gssapi_libs must be as well';
    }
    if ($options{gssapi_inc}) {
	$incconf = $options{gssapi_inc}
    } else {
	die 'if options gssapi_libs or gssapi_lddlflags are provided, then gssapi_inc must be as well';
    }
    if ($options{gssapi_lddlflags}) {
	if ( $Config{lddlflags} ) {
	    print "$LINE Adding from your Perlinstallation (\$Config{lddlflags}) to LDDLFLAGS \n",
	          $Config{lddlflags};
        }
	push @LDDLFLAGS, 'LDDLFLAGS',
	                 join ' ', $Config{lddlflags}, $options{gssapi_lddlflags};
    }
} else {
    print $LINE, ' Searching krb5-config command... ';
    my $krb5cmd = find_krb5config_cmd($options{'gssapiimpl'} );
    unless ($krb5cmd) {
	print 'NOT FOUND!';
        print "\n\n seems this is a missing prerequirement.",
              "\n The README file shipped with this module provides\n more information regarding prerequirements. \n\n";
        exit 0; # send no automated FAIL testreport
    } else {
      print "\n\n using krb5-config command '$krb5cmd'.";
    }
    #---------------------------------------------
    my $implementation = krb5_version( $krb5cmd  );
    print $LINE, " using GSSAPI implementation \n $implementation";
    #---------------------------------------------
    my $libconf =  krb5_libconfig( $krb5cmd );
    unless ($libconf) {
       die "$krb5cmd does not respond libconf!";
    } else {
      if ($libconf =~ /Unknown/ && $implementation =~ /Solaris Kerberos/) {
            $libconf = "-L/usr/lib -R/usr/lib -lgss";
      }

      my ($gsslibs, $otherparm) = find_libs_in_krb5config_string( $libconf  );

      #
      # LIBS accepts only -L and -l flags and ignores others.
      # but we need them at linktime!
      # so all the output of krb5-config --libs gssapi
      # has to be passed into LDDLFLAGS,
      # und only -L and -l params to LIBS (to avoid warnings)
      # <http://sourceforge.net/mailarchive/forum.php?thread_id=9655729&forum_id=47637>
      #
      if ( @{$otherparm} > 0 ) {
         my $lddflagstring = join ' ', $Config{lddlflags},  @{$otherparm};
	 if ( $Config{lddlflags} ) {
	    print $LINE,
	          ' Adding from your Perlinstallation ($Config{lddlflags}) to LDDLFLAGS', "\n\n ",
	          $Config{lddlflags};
         }
         print $LINE, " Bypassing to LDDLFLAGS \n\n $lddflagstring";
         push @LDDLFLAGS, 'LDDLFLAGS', $lddflagstring ;
      }
      #--------------------------------------
      push @GSSLIBS,  join ' ', @{$gsslibs};
    }

    #---------------------------------------------------------------
    $incconf =  krb5_cflags( $krb5cmd  );
    unless ( $incconf ) {
       #
       # krb5-conf does not respond -I/usr/include
       # on Fedora and RHL.
       # Thanks to Dax Kelson <dax@gurulabs.com>
       #
       $incconf = '-I/usr/include';
    }
    if ($incconf =~ /Unknown/ && $implementation =~ /Solaris Kerberos/) {
          $incconf = "-I/usr/include/kerberosv5";
          push @EXTRADEFINES,  '-DSEAM';
    }
    #---------------------------------------------------------------
    if ( is_heimdal($krb5cmd) ) {
       push @EXTRADEFINES,  '-DHEIMDAL';
    }

    if ( is_mit_1_2($krb5cmd) ) {
        #
        # activate Workaround to support
        # MIT Kerberos 1.2.x
        # (constants in old lowercase-style)
        #
        push @EXTRADEFINES,  '-DMITKERB12';
    }
}

#--------------------------------------------------------------
print "$LINE Adding own DEFINEs \n\n @EXTRADEFINES" if( scalar(@EXTRADEFINES) );
print "$LINE Using LIBS\n\n @GSSLIBS",
      "$LINE Using INC includeconfiguration\n\n $incconf",
      $LINE;
#--------------------------------------------------------------


WriteMakefile(
    'AUTHOR'            => 'Achim Grolms <perl@grolmsnet.de>',
    'ABSTRACT_FROM'     => 'GSSAPI.pm',
    'LICENSE'           => 'perl',
    'LIBS'              => join (' ', @GSSLIBS),
    'NAME'		=> 'GSSAPI',
    'VERSION_FROM'	=> 'GSSAPI.pm',
#    'CCFLAGS'           => '-Wall',
    'PREREQ_PM'		=> { 'Test::More' => 0 },
    @LDDLFLAGS,
    'DEFINE'            => join (' ', @EXTRADEFINES),
    'INC'               => $incconf,
    'macro'		=> { OTHER_XS => $otherxs },
    'depend'		=> { 'GSSAPI.c' => '$(OTHER_XS)' }
);

#--------------------------------------------------------------
#-------------------------------------------------
sub find_which_command {
    foreach (@whichcand) {
       return $_ if ( -e $_);
    }
    return undef;
}
#-------------------------------------------------
sub find_krb5config_cmd {
   my ($expl_path) = @_;
   my $r = undef;
   unless ($expl_path) {
      #my $whichcmd =  find_which_command() || die 'cannot locate which command';
      $r = `which krb5-config 2>/dev/null`;

      chomp $r;
      unless ( $r ) {
          my $n = 1;
          print "\n krb5-config NOT found in \$PATH... now doing some guesswork: \n";
          foreach $r ( @KRB5_CONFIG_TRIES ) {
              print "\n $n. trying $r ...";
              if ( -e $r ) {
                  print 'found.';
                  return $r;
              }
              else {
                 print 'not found.';
              }
              $n++;
          }
      }
   } else {
      my $supposed = join '/', $expl_path, 'bin', 'krb5-config';
      if ( -e $supposed ) {
         $r = $supposed ;
      }
   }
   return $r;
}
#-------------------------------------------------
sub krb5_libconfig {
   my ($cfgcmd) = @_;
   $cfgcmd || die 'no $cfgcmd ';
   return `$cfgcmd --libs gssapi`;
}
#-------------------------------------------------
#-------------------------------------------------
sub krb5_cflags  {
   my ($cfgcmd) = @_;
   $cfgcmd || die 'no $cfgcmd ';
   return `$cfgcmd --cflags gssapi`;
}
#-------------------------------------------------
sub krb5_version {
   my ($cfgcmd) = @_;
   $cfgcmd || die 'no $cfgcmd ';
   return `$cfgcmd --version`;
}
#-------------------------------------------------
#-------------------------------------------------
sub is_heimdal {
   my ($cfgcmd) = @_;
   my $r = undef;
   my @vinfo = krb5_version( $cfgcmd );
   FOUND: {
      foreach ( @vinfo) {
         if ( m/eimdal/) {
            $r = 1;
	    last FOUND;
         }
       }
   }
   return $r;
}
#-------------------------------------------------
sub is_mit_1_2 {
   my ($cfgcmd) = @_;
   my $r = undef;
   my @vinfo = krb5_version( $cfgcmd );
   FOUND: {
      foreach ( @vinfo) {
         if ( m/Kerberos 5 release 1\.2/ && !m/Solaris Kerberos/) {
            $r = 1;
	    last FOUND;
         }
       }
   }
   return $r;
}
#-------------------------------------------------

sub find_libs_in_krb5config_string {
   my ( $confstringstring ) = @_;
   my (@libs, @others);
   foreach ( split ' ',  $confstringstring ) {
      #if ( m/(-(Wl,-R|[LlR])[^ ]*)/) {
      if ( m/(^-(Wl,-R|[LlR])[^ ]*)/) {
        push @libs, $1
      } else {
        push @others, $_;
      }
   }
   return (\@libs, \@others);
}
#-------------------------------------------------

