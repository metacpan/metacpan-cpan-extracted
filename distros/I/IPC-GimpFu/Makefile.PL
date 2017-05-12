use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

# Avoid false positives from CPAN Testers:
my $binary = 'gimp';
my $bypass_name = 'BYPASS_MISSING_GIMP';
my $bypass_value = '1';
if (`which $binary 2>/dev/null` eq '') {
  print "Unable to find the $binary binary\n";
  if ($ENV{$bypass_name} && $ENV{$bypass_name} eq $bypass_value) {
    print "bypassed ($bypass_name=$bypass_value); continuing\n";
  }
  else {
    print "aborting; set $bypass_name=$bypass_value to bypass this check\n";
    exit 0;
  }
}

WriteMakefile(
    (MM->can('signature_target') ? (SIGN => 1) : ()),
    NAME                => 'IPC::GimpFu',
    AUTHOR              => q{Cyril Brulebois <kibi@debian.org>},
    VERSION_FROM        => 'lib/IPC/GimpFu.pm',
    ABSTRACT_FROM       => 'lib/IPC/GimpFu.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Carp'           => 0,
        'Cwd'            => 0,
        'IO::Socket::IP' => 0,
        'Proc::Daemon'   => 0,
        'Proc::Killall'  => 0,
        'Test::More'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IPC-GimpFu-*' },
);
