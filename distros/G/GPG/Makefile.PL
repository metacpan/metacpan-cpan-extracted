use ExtUtils::MakeMaker qw/prompt WriteMakefile/;
use strict;

  my $orig_gpg_path = '/usr/local/bin';
  my $gpg_path = $orig_gpg_path;
  my $ok = 0;
  while (!-f "$gpg_path/gpg") {
    my @which = `which gpg`;
    chomp(@which);
    $which[0] =~ s/\/gpg$//;
    $gpg_path = prompt("PATH to your gnupg ('gpg') executable ?",$which[0]);
  }
  if ($gpg_path ne $orig_gpg_path) {
    `perl -pi.bak -e 's{$orig_gpg_path}{$gpg_path}' GPG.pm`;
  }

  my @uname = 'uname -a';
  if ($uname[0] =~ /solaris/ || $uname[0] =~ /hpux/) {
    print qq{
      Warning for Solaris and HP-UX : 
      for the test suite, your gnupg probably use "entropy", 
      you must link \${HOME}/.gnupg/entropy to ./test/entropy
      else your test will failed on step #2 and other.\n
    };
  }

  eval "use IO::Handle";
  if ($@) {
    print qq{
      You don't have installed the IO::Handle module, which is
      required for building this package. Missing modules are available
      from any CPAN mirror, for example\n
      ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module\n
    };
    exit 1;
  }

  eval "use IPC::Open3";
  if ($@) {
    print qq{
      You don't have installed the IPC::Open3 module, which is
      required for building this package. Missing modules are available
      from any CPAN mirror, for example \n
      ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module\n
    };
    exit 1;
  }

  eval "use Data::Dumper";
  if ($@) {
    print qq{
      Warning :
      You don't have installed the Data::Dumper module, which is
      required for testing this package. Missing modules are available
      from any CPAN mirror, for example \n
      ftp://ftp.funet.fi/pub/languages/perl/CPAN/modules/by-module\n
    };
  }

  if (!-d "./test") {
    `mkdir -p test`;
  }


  WriteMakefile( 
    'NAME'         => 'GPG',
    'VERSION_FROM' => 'GPG.pm',
    'AUTHOR'       => 'Philippe Froidevaux (miles@users.sourceforge.net)',
    'ABSTRACT'     => 'Perl Interface to GnuPG (http://www.gnupg.org)',
    'PREREQ_PM'    => {'IO::Handle' => 0,
                       'IPC::Open3' => 0 }
  );

# End of 'Makefile.PL'.
