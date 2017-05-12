# $Id: Makefile.PL,v 1.3 2005/03/05 14:15:20 guy Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'CONFIGURE'    => \&set_paths,
    'NAME'         => 'Mail::Ezmlm',
    'VERSION_FROM' => 'Ezmlm.pm', # finds $VERSION
    'PREREQ_PM'    => { 'File::Copy' => 0, 'Crypt::GPG' => 0 },
    'DISTNAME'     => 'Ezmlm',
    'dist'         => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    'clean'        => { FILES => 'ezmlmtmp' }
);

sub set_paths {
   my ($qmail_path, $ezmlm_path, $gpg_ezmlm_path, $gpg_ezmlm_requested);
   my ($gpg_bin, $gpg_bin_requested);

   # special case to handle the FreeBSD ports system
   if ($ENV{BSD_BATCH_INSTALL}) {
      print STDERR "\$BSD_BATCH_INSTALL is set in your environment, assuming port defaults\n";
      return {};
   }

   print << 'EOM';

We now need to know where some things live on your system. I'll try and make
some intelligent guesses - if I get it right, please just press enter at the
prompt. If I get them wrong, please type in the correct path for me and then
press enter.

First I need to know where the Ezmlm binaries live (ie where I can find
ezmlm-make, ezmlm-sub, etc).

EOM

   *prompt = \&ExtUtils::MakeMaker::prompt;
   
   # guess default
   $ezmlm_path = '/usr/local/bin/ezmlm';
   $ezmlm_path = '/usr/local/bin/ezmlm-idx' unless (-e "$ezmlm_path/ezmlm-make");
   $ezmlm_path = '/usr/local/bin' unless (-e "$ezmlm_path/ezmlm-make");
   $ezmlm_path = '/usr/bin/ezmlm' unless (-e "$ezmlm_path/ezmlm-make");
   $ezmlm_path = '/usr/bin/ezmlm-idx' unless (-e "$ezmlm_path/ezmlm-make");
   $ezmlm_path = '/usr/bin' unless (-e "$ezmlm_path/ezmlm-make");
   # return to default, if nothing can be found
   $ezmlm_path = '/usr/local/bin/ezmlm' unless (-e "$ezmlm_path/ezmlm-make");

   foreach (1..10) {
      $ezmlm_path = prompt('Ezmlm binary directory?', "$ezmlm_path");
      last if (-e "$ezmlm_path/ezmlm-make");
      print "I can't find $ezmlm_path/ezmlm-make. Please try again\n";
   }
	unless (-e "$ezmlm_path/ezmlm-make") {
		print STDERR "Warning: No correct input after $_ attempts.  Continuing with warnings ...\n";
	}
	unless (system(("$ezmlm_path/ezmlm-make", "-V")) == 0) {
		print STDERR "Warning: your version of ezmlm-make does not support the '-V' argument. Please upgrade to ezmlm-idx v0.400 or above.\n";
	}


   print << 'EOM';

Now I need to know where Qmail resides on your system. The Qmail base 
directory is the one in which the Qmail bin, control, etc directories
live in.

EOM

   foreach (1..10) {
      $qmail_path = prompt('Qmail base directory?', '/var/qmail');
      last if (-e "$qmail_path/control");
      print "I can't find $qmail_path/control. Please try again\n";   
   }
   if (! -e "$qmail_path/control") {
      print STDERR "Warning: No correct input after $_ attempts. Continuing with warnings ...\n";
   }


	# check if gpg-ezmlm is installed (for Mail::Ezmlm::GpgEzmlm)
	$gpg_ezmlm_requested = prompt('Is gpg-ezmlm installed for encrypted mailing list support? (y/N)', "n");
	$gpg_ezmlm_requested = ($gpg_ezmlm_requested =~ /^y/i);
	if ($gpg_ezmlm_requested) {
		undef $gpg_ezmlm_path;
		foreach ('/usr/local/bin', '/usr/bin', '/usr/local/bin/gpg-ezmlm',
				'/usr/bin/gpg-ezmlm') {
			if (-e "$_/gpg-ezmlm-manage.pl") {
			   $gpg_ezmlm_path = $_;
			   last;
			}
		}
		$gpg_ezmlm_path = '/usr/bin' unless (defined($gpg_ezmlm_path));
		# ask the user to confirm our guessing
		foreach (1..10) {
			$gpg_ezmlm_path = prompt('gpg-ezmlm installation directory?',
					"$gpg_ezmlm_path");
			last if (-e "$gpg_ezmlm_path/gpg-ezmlm-manage.pl");
			print "I can't find $gpg_ezmlm_path/gpg-ezmlm-manage.pl. "
					. "Please try again\n";
		}
		unless (-e "$gpg_ezmlm_path/gpg-ezmlm-manage.pl") {
			print STDERR "Warning: No correct input after $_ attempts. "
					. "Continuing with warnings ...\n";
		}
	}

	# check if gpg is installed (for Mail::Ezmlm::GpgKeyRing)
	$gpg_bin_requested = prompt('Is gnupg installed (for keyring support in encrypted mailing lists)? (y/N)', "n");
	$gpg_bin_requested = ($gpg_bin_requested =~ /^y/i);
	if ($gpg_bin_requested) {
		undef $gpg_bin;
		foreach ('/usr/local/bin/gpg', '/usr/bin/gpg', '/bin/gpg',
				'/usr/local/bin/gpg2', '/usr/bin/gpg2', '/bin/gpg2') {
			if (-x "$_") {
			   $gpg_bin = $_;
			   last;
			}
		}
		$gpg_bin = '/usr/bin' unless (defined($gpg_bin));
		# ask the user to confirm our guessing
		foreach (1..10) {
			$gpg_bin = prompt('Path to the gpg or gpg2 binary?', "$gpg_bin");
			last if (-x "$gpg_bin");
			print "I can't find $gpg_bin. Please try again\n";
		}
		unless (-x "$gpg_bin") {
			print STDERR "Warning: No correct input after $_ attempts. "
					. "Continuing with warnings ...\n";
		}
	}

   # check if mysql support is necessary
   if(`strings $ezmlm_path/ezmlm-sub | grep -i 'MySQL'`) {

      print << 'EOM';

It appears you have compiled MySQL support into your version of Ezmlm. If
this is correct, I now need to know where the MySQL client (mysql) lives on
your machine.

Please leave this blank if you do not want to enable MySQL support in the
Mail::Ezmlm module.

EOM

	$mysql_path = '/usr/bin';
	$mysql_path = '/usr/local/bin' unless (-e "$mysql_path/mysql");
	# return to default - if nothing works
	$mysql_path = '/usr/bin' unless (-e "$mysql_path/mysql");
	  
      foreach (1..10) {
         $mysql_path = prompt('MySQL binary directory?', "$mysql_path");
         last if (-e "$mysql_path/mysql" || $mysql_path eq '');
         print "I can't find $mysql_path/mysql. Please enter the full path\n";
         print "or leave this option blank if you don't want to use MySQL\n";
         }
		unless ((-e "$mysql_path/mysql") || ($mysql_path eq '')) {
			print STDERR "Warning: No correct input after $_ attempts.  Continuing with warnings ...\n";
		}

   }

   print << 'EOM';

Thank you. I will use this information to configure Mail::Ezmlm for you

EOM

   # set the variables in Ezmlm.pm
   # Back up file
   open(EZMLM, '<Ezmlm.pm') or die "Unable to open Ezmlm.pm for read: $!";
   open(TMP, ">Ezmlm.pm.tmp.$$") or die "Unable to create temp file: $!";
   while(<EZMLM>) { print TMP; }
   close TMP; close EZMLM;
   # Do variable substitution
   open(EZMLM, '>Ezmlm.pm') or die "Unable to open Ezmlm.pm for write: $!";
   open(TMP, "<Ezmlm.pm.tmp.$$") or die "Unable to read temp file: $!";
   while(<TMP>) {
      s{^\$EZMLM_BASE\s*=\s*['"].+?['"]\s*;\s*(#.*|)$}{\$EZMLM_BASE = '$ezmlm_path'; #Autoinserted by Makefile.PL};
      s{^\$QMAIL_BASE\s*=\s*['"].+?['"]\s*;\s*(#.*|)$}{\$QMAIL_BASE = '$qmail_path'; #Autoinserted by Makefile.PL}; 
      s{^\$MYSQL_BASE\s*=\s*['"].*?['"]\s*;\s*(#.*|)$}{\$MYSQL_BASE = '$mysql_path'; #Autoinserted by Makefile.PL}; 
     print EZMLM;
   }
   close TMP; close EZMLM;
   unlink "Ezmlm.pm.tmp.$$";

   if ($gpg_ezmlm_requested) {
	   # set the variables in GpgEzmlm.pm
	   # Back up file
	   open(GPGEZMLM, '<Ezmlm/GpgEzmlm.pm')
		   or die "Unable to open Ezmlm/GpgEzmlm.pm for read: $!";
	   open(TMP, ">Ezmlm/GpgEzmlm.pm.tmp.$$") or die "Unable to create temp file: $!";
	   while(<GPGEZMLM>) { print TMP; }
	   close TMP; close GPGEZMLM;
	   # Do variable substitution
	   open(GPGEZMLM, '>Ezmlm/GpgEzmlm.pm')
		   or die "Unable to open Ezmlm/GpgEzmlm.pm for write: $!";
	   open(TMP, "<Ezmlm/GpgEzmlm.pm.tmp.$$")
		   or die "Unable to read temp file: $!";
	   while(<TMP>) {
		  s{^\$GPG_EZMLM_BASE\s*=\s*['"].+?['"]\s*;\s*(#.*|)$}{\$GPG_EZMLM_BASE = '$gpg_ezmlm_path';	# Autoinserted by Makefile.PL};
		  s{^\$GPG_BIN\s*=\s*['"].+?['"]\s*;\s*(#.*|)$}{\$GPG_BIN = '$gpg_bin';	# Autoinserted by Makefile.PL} if ($gpg_bin_requested);
		 print GPGEZMLM;
	   }
	   close TMP; close GPGEZMLM;
	   unlink "Ezmlm/GpgEzmlm.pm.tmp.$$";
   }

   # set the variables in GpgKeyRing.pm
   if ($gpg_bin_requested) {
	   # Back up file
	   open(GPGKEYRING, '<Ezmlm/GpgKeyRing.pm')
		   or die "Unable to open Ezmlm/GpgKeyRing.pm for read: $!";
	   open(TMP, ">Ezmlm/GpgKeyRing.pm.tmp.$$") or die "Unable to create temp file: $!";
	   while(<GPGKEYRING>) { print TMP; }
	   close TMP; close GPGKEYRING;
	   # Do variable substitution
	   open(GPGKEYRING, '>Ezmlm/GpgKeyRing.pm') or die "Unable to open Ezmlm/GpgKeyRing.pm for write: $!";
	   open(TMP, "<Ezmlm/GpgKeyRing.pm.tmp.$$") or die "Unable to read temp file: $!";
	   while(<TMP>) {
		  s{^\$GPG_BIN\s*=\s*['"].+?['"]\s*;\s*(#.*|)$}{\$GPG_BIN = '$gpg_bin';	# Autoinserted by Makefile.PL};
		 print GPGKEYRING;
	   }
	   close TMP; close GPGKEYRING;
	   unlink "Ezmlm/GpgKeyRing.pm.tmp.$$";
	}

   return {};

}

