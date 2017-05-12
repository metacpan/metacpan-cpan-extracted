package Linux::Kernel::Build;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Net::Ping;
use Getopt::Std;

require Exporter;

@ISA = (Exporter);
@EXPORT = qw();

use vars qw($VERSION $SUBVERSION);
$VERSION = 2014.0623_00;

BEGIN { }


use constant DEBUGALITTLE => 1;                                                  #
use constant DEBUGALOT => 1;                                                     #

my $commandLineDisabled = undef;                                                 #
my $scriptName = 'kernelMaker.pl';                                               #
my $scriptVersion = '0.1-alpha';                                                 #
my $kernelFileType = 'bz2';
my $kernelFile = 'linux-2.6.11-rc2.tar.bz2';
my $proxyEnableFlag = '0';
my $proxy = '';
my $proxyUser = '';
my $proxyPassword = '';
my $kernelSourceHostDirectoryURL = 'http://www.kernel.org/pub/linux/kernel/v2.6/testing/';
my $maximumTries = '1';
my $destinationDirectory = '/home/adutko/';
my $timeout = '50';


######################################################################################
######################################################################################
## WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! ##
######################################################################################
######################################################################################
##                                                                                  ##
## Unless you know EXACTLY what you're doing it's best you ONLY modify the options  ##
## preceeding this warning or pass options to the script on the command line.       ##
##                                                                                  ##
######################################################################################
######################################################################################
## WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! WARNING! ##
######################################################################################
######################################################################################


##################################################################################
###############################   SUBROUTINES    #################################
##################################################################################
sub showMenu() {

   print "usage: kernelMaker.pl [-help -type -file -proxy -user -passwd -url -tries -dir -timeout]

-help        : Show this help menu.
-type        : Specify the type of file compression.
-file        : Specify the name of the compressed kernel file.
-enableproxy : Specify whether to enable proxy or not.
-proxy       : Specify a proxy.
-user        : Specify a proxy user.
-passwd      : Specify a proxy password (WARNING :: PLAIN TEXT).
-url         : Specify the URL for the directory where the -file can be found.
-tries       : Specify the maximum number of times wget tries to retrieve -file from -url.
-dir         : Specify where to save the generated package.
-timeout     : Specify the timeout for wget.
   \n";

   print "example: kernelMaker.pl -type=bz2 -file=kernel-2.6-1.tar.bz2 -proxy=0 -url=http://kernel.org/ARCHIVE/ -tries=2 -dir=/tmp -timeout=10\n";

};

sub optionVerifier($;$) {

   my $optionsToVerify = shift || die "Didn't get options to verify in optionVerifier().\n";
   my $typeOfOptionsToVerify = shift || "Didn't get if you are using commandline options or manual options.\n";

   ##################################################################################
   ###############################  OPTION VERIFIER    ##############################
   ##################################################################################

   ## Passed options in a more useable form.
   my %optionsToBeVerified = %{$optionsToVerify};

   ## Command line variable values.
   my @options = ("-type","-file","-enableproxy","-proxy","-user","-passwd","-url","-tries","-dir","-timeout");

   ## My verified options.
   my $goodOptions = ();

   ##################################################################################
   ################################  KERNEL ME UP    ################################
   ##################################################################################
   my $kernelFileCompression = undef;
   my $kernelFileDefinedType = undef;
   my $kernelFileToUse = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

      $kernelFileDefinedType = $kernelFileType;
      $kernelFileToUse = $kernelFile;

   } else {

      $kernelFileDefinedType = $optionsToBeVerified{$options[0]};
      (my $file, my $kernelFileSplit) = split(/-file=/,$optionsToBeVerified{$options[1]},2);
   	  $kernelFileToUse = $kernelFileSplit;

   };

   if ( $kernelFileDefinedType =~ /gz/ ) {

      print "KERNEL FILE TYPE SET :::::>>>>> gz \n" if DEBUGALOT;

	  push(@{$goodOptions},'gz');
	  push(@{$goodOptions},$kernelFileToUse);

   } elsif ( $kernelFileDefinedType =~ /bz2/ ) {

	  print "KERNEL FILE TYPE SET :::::>>>>> bz2 \n" if DEBUGALOT;

	  push(@{$goodOptions},'bz2');
	  push(@{$goodOptions},$kernelFileToUse);

   } elsif ( $kernelFileDefinedType =~ /tgz/ ) {

	  print "KERNEL FILE TYPE SET :::::>>>>> tgz \n" if DEBUGALOT;

	  push(@{$goodOptions},'tgz');
	  push(@{$goodOptions},$kernelFileToUse);

   } elsif ( $kernelFileDefinedType =~ /tar/ ) {

	  print "KERNEL FILE TYPE SET :::::>>>>> tar \n" if DEBUGALOT;

	  push(@{$goodOptions},'tar');
      push(@{$goodOptions},$kernelFileToUse);

   } else {

	  die "You need to set \$kernelFileType to a recognized filetype before continuing...\n";

   };

   ##################################################################################
   #############################   END KERNEL ME UP    ##############################
   ##################################################################################

   ##################################################################################
   ################################  WGET OPTIONS    ################################
   ##################################################################################

   my $noProxy = undef;
   my $proxyFlag = undef;
   my $proxyToUse = undef;
   my $proxyUserToUse = undef;
   my $proxyPasswordToUse = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

      $proxyFlag = $proxyEnableFlag;
      $proxyToUse = $proxy;
      $proxyUserToUse = $proxyUser;
      $proxyPasswordToUse = $proxyPassword;

   } else {

   	  (my $proxyCruft, my $proxyEnabledFlag) = split(/-enableproxy=/,$optionsToBeVerified{$options[2]},2);
      $proxyFlag = $proxyEnabledFlag;

      if ( $proxyFlag && $proxyFlag == '1' ) {

         (my $proxyProxyCruft, my $proxyPassedProxy) = split(/-proxy=/,$optionsToBeVerified{$options[3]},2);
         $proxyToUse = $proxyPassedProxy;
         (my $proxyUserCruft, my $proxyPassedUser) = split(/-user=/,$optionsToBeVerified{$options[4]},2);
         $proxyUserToUse = $proxyPassedUser;
         (my $proxyPasswordCruft, my $proxyPassedPassword) = split(/-password=/,$optionsToBeVerified{$options[5]},2);
         $proxyPasswordToUse = $proxyPassedPassword;

      };

   };

   if ( $proxyFlag == '0' ) {

      $noProxy = '--no-proxy';
      push(@{$goodOptions},$noProxy);
      print "No proxy enabled so using --no-proxy for wget.\n" if DEBUGALOT;

   } elsif ( $proxyFlag == '1' ) {

	  if ($proxyToUse && $proxyToUse ne '') {

	     push(@{$goodOptions},$proxyToUse);
         print "Proxy verified and set...\n" if DEBUGALITTLE;

	  } else {

         die "Please check the value of \$proxy.\n";

	  };

	  if ($proxyUserToUse && $proxyUserToUse ne '') {

         push(@{$goodOptions},$proxyUserToUse);
         print "Proxy user verified and set...\n" if DEBUGALITTLE;

	  } else {

         die "Please check the value of \$proxyUser.\n";

      };

      if ($proxyPasswordToUse && $proxyPasswordToUse ne '') {

	     push(@{$goodOptions},$proxyPasswordToUse);
	     print "Proxy password verified and set...\n" if DEBUGALITTLE;

	  } else {

         die "Please check the value of \$proxyPassword.\n";

	  };

   } else {

      die "Please set the \$proxyEnableFlag field to either 0 or 1.\n";

   };

   ##################################################################################
   ##############################  END WGET OPTIONS    ##############################
   ##################################################################################

   #######################################
   #### KERNEL FILE HOST VERIFICATION ####
   #######################################
   my $kernelFullURL = undef;
   my $verifyHost = undef;
   my $kernelURL = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

   	   $kernelURL = $kernelSourceHostDirectoryURL;

   } else {

      (my $flag, my $kernelPassedURL) = split(/-url=/,$optionsToBeVerified{$options[6]},2);
      $kernelURL = $kernelPassedURL;

   };

   print "KERNEL FULL PATH =====>>>>> $kernelURL \n" if DEBUGALITTLE;

   if( !defined($kernelURL) ) {

      print "So tell me how you're supposed to run this script without kernel source?\n";
      print "You need to set \$kernelURL to a valid URL before proceeding.\n";
      exit;

   };

   ## Get the actual host from $kernelURL
   (my $http, my $kernelSourceHost) = split("http://",$kernelURL,2);
   print "TRIMMED FULL PATH ======>>>>> $kernelSourceHost \n" if DEBUGALOT;
   ($kernelSourceHost, my $leftover) = split("/",$kernelSourceHost,2);
   print "PING =====>>>>> $kernelSourceHost :: LEFTOVER =====>>>>> $leftover\n" if DEBUGALOT;

   $verifyHost = Net::Ping->new();
   if ( $verifyHost->ping($kernelSourceHost) ) {

      $kernelFullURL = $kernelSourceHost . '/' . $kernelFile;
      $verifyHost->close();

      push(@{$goodOptions},$kernelFullURL);

      print "\$kernelSourceHost verified and set...\n" if DEBUGALITTLE;
	  print "$kernelSourceHost responded to ping!\n" if DEBUGALOT;

   } else {

      print "ERROR :::::>>>>> Please verify \$kernelSourceHostDirectoryURL.\n";
	  print "                 It must be set to the directory where the kernel source file is located.\n";
	  print "                 It cannot represent the full path of the kernel file.\n";

      exit(1);

   };
   #######################################
   ## END KERNEL FILE HOST VERIFICATION ##
   #######################################

   #######################################
   ######  MAXIMUM TRY VERIFICATION ######
   #######################################
   my $maxTries = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

   	   $maxTries = $maximumTries;

   } else {

      (my $tries, my $triesPassed) = split(/-tries=/,$optionsToBeVerified{$options[7]},2);
      $maxTries = $triesPassed;

   };

   ## IS IT A NUMBER?
   if ( !( $maxTries =~ /^-?\d/) ) {

      die "Please set \$maxTries to a numeric value equal to or greater than 1.\n";

   } else {

      print "\$maxTries verified and set...\n" if DEBUGALITTLE;
      push(@{$goodOptions},$maxTries);

   };

   #######################################
   ##### END MAXIMUM TRY VERIFICATION ####
   #######################################

   ##########################################
   #   DESTINATION DIRECTORY VERIFICATION   #
   ##########################################
   my $destDir = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

   	   $destDir = $destinationDirectory;

   } else {

      (my $dir, my $dirPassed) = split(/-dir=/,$optionsToBeVerified{$options[8]},2);
      $destDir = $dirPassed;

   };

   if ( !( -d $destDir) ) {

      die "Please set \$destDir to a valid system directory.\n";

   } else {

      my $trailingSlash = substr($destDir,0,-1);

      if ($trailingSlash ne "/") {

         die "Please add a trailing slash to \$destDir.\n";

      } else {

         print "\$destDir verified and set...\n" if DEBUGALITTLE;
         push(@{$goodOptions},$destDir);

      };

   };

   ##########################################
   # END DESTINATION DIRECTORY VERIFICATION #
   ##########################################

   #######################################
   ######    TIMEOUT VERIFICATION   ######
   #######################################
    my $setTimeout = undef;

   if ( $typeOfOptionsToVerify eq "TRUE" ) {

   	   $setTimeout = $timeout;

   } else {

      (my $timeout, my $timeoutPassed) = split(/-timeout=/,$optionsToBeVerified{$options[9]},2);
      $setTimeout = $timeoutPassed;

   };

   if ( !( $setTimeout =~ /^-?\d/) ) {

      die "Please set \$setTimeout to a numeric value equal to or greater than 1.\n";

   } else {

      print "\$setTimeout verified and set...\n" if DEBUGALITTLE;
      push(@{$goodOptions},$setTimeout);

   };

   #######################################
   ####   END TIMEOUT VERIFICATION   #####
   #######################################

   ##################################################################################
   #############################  END OPTION VERIFIER   #############################
   ##################################################################################

   return $goodOptions;

};

sub getSource($;$) {

   my $getdir = shift || die "Didn't get a directory to download source for getSource().\n";
   my $getsrc = shift || die "Didn't get a source URL.\n";
   my $getOptions = shift || die "Didn't get any wget options.\n";

   my $retriever = 'wget ';
   my $flatOptions = undef;
   my $wgetSrc = undef;

   for my $individualWGETOption (@{$getOptions}) {

      $flatOptions = ' ' . $individualWGETOption . ' ';

   };

   $wgetSrc = 'wget' . $flatOptions . '-P ' . $getdir . ' ' . $getsrc;

   my $geterror = `$wgetSrc`;

   if( $geterror eq "") {

      return("GOT KERNEL SOURCE!","TRUE");

   } else {

      return("FAILED TO GET KERNEL SOURCE!","FALSE");

   };

};

sub expandSource($;$) {

   my $curdir = shift || die "Didn't get a directory to expand the kernel source into for expandSource().\n";
   my $srcfile = shift || die "Didn't get a kernel source file for expandSource().\n";

   my $expander = 'tar -xzvf ';
   my $expandcmd = $expander . $srcfile . ' -C ' . $curdir;

   my $mkdir = 'mkdir ' . $curdir;

   my $mkdirerror = `$mkdir`;

   if( $mkdirerror eq "" ) {

      my $expanderror = `$expandcmd`;

      if( $expanderror ne "" ) {

         return("EXPANDED KERNEL SOURCE!","TRUE");

      } else {

         return("FAILED TO EXPAND KERNEL SOURCE!","FALSE");

      };

   } else {

      return("FAILED TO CREATE THE KERNEL DESTINATION DIRECTORY!","FALSE");

   };

};

sub makeSource($;$;$) {

   my $configdir = shift || die "Didn't get a directory to 'make config' for makeSource().\n";
   my $exitdir = shift || die "Didn't get a directory leave for makeSource().\n";
   my $kernelSourceFileName = shift || die "Didn't get the name of the kernel directory for makeSource().\n";
   my $intodir = $configdir . $kernelSourceFileName . '/';
   my $kernelmakerconfig = 'Y | make -C ' . $intodir . ' config';
   my $kernelmakermake = 'make -C ' . $intodir;
   my $kernelmakerclean = 'make -C ' . $intodir . ' clean';

   my $kernelmakerconfigerror = `$kernelmakerconfig`;

   if( $kernelmakerconfigerror ne "" ) {

      my $kernelmakermakeerror = `$kernelmakermake`;

      if( $kernelmakermakeerror ne "" ) {

         my $kernelmakercleanerror = `$kernelmakerclean`;

         if( $kernelmakercleanerror ne "" ) {

               return("MADE THE KERNEL!","TRUE");

         } else {

            return("MAKE CLEAN KERNEL FAILED!","FALSE");

         };

      } else {

         return("ERROR IN MAKING KERNEL","FALSE");

      };

   } else {

      return("ERROR MAKING CONFIG FOR KERNEL","FALSE");

   };

};

sub installKernel() {



};

sub cleanSource($;$) {

   my $rmdir = shift || die "Didn't get a directory to cleanSource().\n";
   my $rmfiledir = shift || die "Didn't get a file to cleanSource().\n";

   my $removedircmd = 'rm -rf ' . $rmdir;
   my $removefilecmd = 'rm -f ' . $rmfiledir . $kernelFile;

   my $removeerror = `$removedircmd`;
   my $removefileerror = `$removefilecmd`;

   if( ($removeerror eq "") && ($! eq "") ) {

      if( ($removefileerror eq "") && ($! eq "") ) {

         return ("REMOVED DIRECTORY AND SOURCE FILE","TRUE");

      } else {

         return("ERROR REMOVING SOURCE FILE","FALSE");

      };

   } else {

      return ("ERROR REMOVING DIRECTORY","FALSE");

   };

};

sub getHostName() {
   my $prog = '/bin/hostname';
   my $hostname = `$prog`;
   my @HOST_PARTS = split /\./, $hostname;

   return ($HOST_PARTS[0]);
};

sub main() {

   my $hostname = getHostName();

   ## Manual variable values.
   my $manualKernelFileType = undef;
   my $manualKernelFile = undef;
   my $manualKernelSourceHostDirectoryURL = undef;
   my $manualProxyEnableFlag = undef;
   my $manualProxy = undef;
   my $manualProxyUser = undef;
   my $manualProxyPassword = undef;
   my $manualMaximumTries = undef;
   my $manualDestinationDirectory = undef;
   my $manualTimeout = undef;

   ## Valid command line options.
   my %options = (
      -help => undef,         # Show this help menu.
      -type => undef,         # Specify the type of file compression.
      -file => undef,         # Specify the name of the compressed kernel file.
      -enableproxy => undef,  # Specify whether to enable proxy or not.
      -proxy => undef,        # Specify a proxy.
      -user => undef,         # Specify a proxy user.
      -passwd => undef,       # Specify a proxy password (WARNING :: PLAIN TEXT).
      -url => undef,          # Specify the URL for the directory where the -file can be found.
      -tries => undef,        # Specify the maximum number of times wget tries to retrieve -file from -url.
      -dir => undef,          # Specify where to save the generated package.
      -timeout => undef,      # Specify the timeout for wget.
   );

   ## Manual variable storage.
   my $manualVariableStore = ();

   if (!@ARGV) {

      print "Initializing $scriptName v.$scriptVersion on $hostname...\n" if DEBUGALITTLE;
	  print "NO command line options specified.\n" if DEBUGALITTLE;

	  $commandLineDisabled = "TRUE";

      ###############################################################################
	  ############################  MANUAL CONFIG OPTIONS  ##########################
	  ###############################################################################
	  $manualKernelFileType = $kernelFileType;                                      #
	  $manualKernelFile = $kernelFile;                                              #
	  $manualKernelSourceHostDirectoryURL = $kernelSourceHostDirectoryURL;          #
	  $manualProxyEnableFlag = $proxyEnableFlag;                                    #
	  $manualProxy = $proxy;                                                        #
	  $manualProxyUser = $proxyUser;                                                #
	  $manualProxyPassword = $proxyPassword;                                        #
	  $manualMaximumTries = $maximumTries;                                          #
	  $manualDestinationDirectory = $destinationDirectory;                          #
	  $manualTimeout = $timeout;                                                    #
	  ###############################################################################
	  #############################  END CONFIG OPTIONS  ############################
	  ###############################################################################

   } else {

      print "Initializing $scriptName v.$scriptVersion on $hostname...\n" if DEBUGALITTLE;
	  print "Command line options specified.\n" if DEBUGALITTLE;

      $commandLineDisabled = "FALSE";

	  ##################################################################################
	  ##############################  CML CONFIG OPTIONS  ##############################
	  ##################################################################################

	  my $argument = undef;

	  print "ALL ARGUMENTS :::::>>>>> @ARGV \n" if DEBUGALOT;

	  foreach $argument (@ARGV) {

	     print "ARGUMENT :::::>>>>> $argument\n" if DEBUGALITTLE;

		 ## Does each argument have a - in front of it?
		 if ($argument !~ /^-/) {

		    die "Unknown option $argument.  Please make sure you've prepended each argument with a single dash.\n";

		 };

		 (my $argumentField,my $argumentValue) = split(/=/,$argument,2);

         if ( $argumentField eq "-help" ) {

            print "CALLING HELP MENU :::::>>>>> \n" if DEBUGALOT;

			showMenu();

			exit(1);

	     };

	   };

	};

	##################################################################################
	############################  END CML CONFIG OPTIONS  ############################
	##################################################################################

   if ( $commandLineDisabled eq "TRUE" ) {

      print "Initializing $scriptName v.$scriptVersion on $hostname...\n";

      print "Using the following manual parameters to generate your kernel package:
         -type        => $manualKernelFileType
         -file        => $manualKernelFile
         -enableproxy => $manualProxyEnableFlag
         -proxy       => $manualProxy
         -user        => $manualProxyUser
         -passwd      => $manualProxyPassword
         -url         => $manualKernelSourceHostDirectoryURL
         -tries       => $manualMaximumTries
         -dir         => $manualDestinationDirectory
         -timeout     => $manualTimeout
	  \n";

      print "Verifying manual configuration options...\n" if DEBUGALITTLE;

      ## Translate manual options to a hash.
      my %manualOptions = (
         -type        => $manualKernelFileType,
         -file        => $manualKernelFile,
         -enableproxy => $manualProxyEnableFlag,
         -proxy       => $manualProxy,
         -user        => $manualProxyUser,
         -passwd      => $manualProxyPassword,
         -url         => $manualKernelSourceHostDirectoryURL,
         -tries       => $manualMaximumTries,
         -dir         => $manualDestinationDirectory,
         -timeout     => $manualTimeout,
      );

      my $validManualOptions  = optionVerifier(\%manualOptions,$commandLineDisabled);

   	  print "All options verified... @{$validManualOptions} \n";

   	  #if( (-f $manualOptions{"-dir"} . $manualOptions{"-file"}) ) {

      #   print "Hrmm...I'm thinking cleanSource() failed b/c my source file still exists from the previous run...\n";
      #   print "Removing...\n";

      #   `rm -rf $directory`;
      #   `rm -f $directoryparent$kernelfile*`;

      #};


   } elsif ( $commandLineDisabled eq "FALSE" ) {

      print "Initializing $scriptName v.$scriptVersion on $hostname...\n";

      print "Using the following command line parameters to generate your kernel package: \n";

      my %commandLineOptions = ();

      for my $lineOption (@ARGV) {

         if ( $lineOption =~ /-enableproxy/ ) {

            ## Translate command line options to a hash.
            %commandLineOptions = (
               -type        => $ARGV[0],
               -file        => $ARGV[1],
               -enableproxy => $ARGV[2],
               -proxy       => $ARGV[3],
               -user        => $ARGV[4],
               -passwd      => $ARGV[5],
               -url         => $ARGV[6],
               -tries       => $ARGV[7],
               -dir         => $ARGV[8],
               -timeout     => $ARGV[9],
            );

         } else {

         	## Translate command line options to a hash.
            %commandLineOptions = (
               -type        => $ARGV[0],
               -file        => $ARGV[1],
               -enableproxy => $ARGV[2],
               -url         => $ARGV[3],
               -tries       => $ARGV[4],
               -dir         => $ARGV[5],
               -timeout     => $ARGV[6],
            );

         };

      };

      ## Let's verify all passed options are actual options.
      while( (my $optionKey, my $optionValue) = (each %commandLineOptions) ) {

         if( $optionValue ) {

            print "KEY :: $optionKey -- VALUE :: $optionValue \n" if DEBUGALOT;

         } else {

            print "KEY :: $optionKey -- VALUE :: NULL \n" if DEBUGALOT;

         };

      };

      print "Verifying command line configuration options...\n" if DEBUGALITTLE;

      my $validCommandLineOptions  = optionVerifier(\%commandLineOptions,$commandLineDisabled);

   	  print "All options verified... @{$validCommandLineOptions} \n";

   } else {

      print "There is something really wrong b/c \$commandLineDisabled isn't set properly.\n";

   };

###########
##  STOP ##
###########

};


###########
## START ##
###########
&main;


=head1 NAME

Linux::Kernel::Build - Custom Linux Kernel Builds

=head1 VERSION

Version 2014.0621_00

=cut


=head1 SYNOPSIS

Linux::Kernel::Build is the namespace for the subroutines 
associated with downloading, building and optionally 
installing new kernels. It is part of the Linux::Kernel 
suite of tools associated with the Linux kernel. Another
tool available via the CPAN that does something similar is
'kif'. The reasoning behind creating the Linux::Kernel 
namespace was to generate a central namespace Kernel related  
operationgs functions and data. As of June 2014, there are 
other modules and distributions in the planning stages that
will take code from existing CPAN modules that either expose
kernel related data to users or enable users to work with 
the Linux kernel, and put the code in other namespaces under
Linux::Kernel.  

Linux::Kernel::Build focuses on the following:

1) Download a compressed and archived kernel.                          
2) Decompress and expand the kernel into a known directory.            
3) make config the kernel.                                             
4) make the kernel.                                                    
5) install the kernel automatically.                                   
6) remove all used directories and files.                              


Perhaps a little code snippet.

    use Linux::Kernel::Build;

    my $kernel = Linux::Kernel::Build->new();
    $kernel->get();
    $kernel->unpack();
    $kernel->config();
    $kernel->build();
    $kernel->install();
    $kernel->clean();

=head1 EXPORT

=head1 SUBROUTINES/METHODS

=head2 showMenu()


=cut

=head2 optionVerifier()


=cut

=head2 getSource()

=cut

=head2 expandSource()

=cut

=head2 makeSource()

=cut

=head2 installKernel()

=cut

=head2 cleanSource()

=cut

=head2 getHostName()

=cut

=head2 main()

=cut


=head1 AUTHOR

Adam M Dutko, C<< <addutko at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-linux-kernel at rt.cpan.org
>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Linux-Ker
nel>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

1) Need to verify all installation options; break out into subroutines.
2) Modify the get, clean, make and install routines.                   
3) Configure to use the users old config.                              

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Linux::Kernel


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Linux-Kernel>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Linux-Kernel>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Linux-Kernel>

=item * Search CPAN

L<http://search.cpan.org/dist/Linux-Kernel/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007-2014 Adam M. Dutko

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


=cut

1; # End of Linux::Kernel

