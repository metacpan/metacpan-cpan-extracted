use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist qw();

our $DEFS = '';

# Attempt to avoid the incorrect 'FAIL' reports from Chris Williams' broken NetBSD smoker(s).
# Comment out the 'exit 0;' (26 lines further down) if this causes problems.

if($Config{osname} eq 'netbsd') {

  my($inc, $cc) = ('', undef);

  if(@ARGV) {
    for my $arg(@ARGV) {
      $inc = (split /=/, $arg)[1] if $arg =~ /^inc=/i;
      $cc = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
    }
  }

  $inc =~ s/'//g;
  $inc =~ s/"//g;

  unless(defined($cc)) {
    $cc = defined($Config{cc}) ? $Config{cc} : 'cc';
  }

  my $opt = $Config{optimize};

  my $out = `$cc $opt $inc $Config{ccflags} -o quad.exe -x c quad.in 2>&1`;

  if($out =~ /quadmath\.h: No such file or directory/i) {
    print "Aborting: Got\n$out\n";
    exit 0;
  }
}

my $defines = $] < 5.008 ? "-DOLDPERL" : "-DNEWPERL";

$defines .= $Config{byteorder} =~ /^1234/ ? " -DWE_HAVE_LENDIAN" : " -DWE_HAVE_BENDIAN";

$defines .= " -DLONGLONG2IV_IS_OK"
  if $Config{ivsize} >= $Config{longlongsize};

$defines .= " -DLONG2IV_IS_OK"
  if $Config{ivsize} >= $Config{longsize};

$defines .= " -DNV_IS_DOUBLE"
  if $Config{nvtype} eq 'double';

if($Config{nvtype} eq 'long double') {
  $defines .= " -DNV_IS_LONG_DOUBLE";
  if(defined($Config{longdblkind})) {
    if($Config{longdblkind} != 3 && $Config{longdblkind} != 4) {
      $defines .= " -DINF_CAST_BUG_ABSENT";
    }
  }
}


# Default version of Liblist strips -l params it can't find
# in lib-path, which strips -l params that might be "compiler provided"
# https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/277
# https://rt.cpan.org/Ticket/Display.html?id=116520
#
# This simply assumes any such stripping is wrong and optimisitically
# reinserts them -  unless (as of version 0.15) $^O is MSWin32.
if ( defined(&ExtUtils::Liblist::ext) && $^O !~ /MSWin/ ) {
  warn "Patching ExtUtils::Liblist::ext\n";
  my $orig = \&ExtUtils::Liblist::ext;
  no warnings 'redefine';
  *ExtUtils::Liblist::ext = sub {
      my ( @result ) = $orig->(@_);
      # Always make sure -lm is there as we anchor in front of -lm
      if ( $result[2] !~ /-lm/ ) {
        warn "Reinserting stripped -lm\n";
        $result[2] .= ' -lm';
      }
      # Then insert -lquadmath in front of any such -lm
      if ( $result[2] !~ /-lquadmath/ ) {
        warn "Reinserting stripped -lquadmath\n";
        $result[2] =~ s{-lm}{-lquadmath -lm};
      }
      return @result;
  };
}

if($^O =~ /MSWin32/i && $] < 5.022) {
  $defines .= " -D_WIN32_BIZARRE_INFNAN";
}

####################################
# Next, we check to see whether there's some unhelpful beaviour regarding
# the setting of the POK flag.
# This typically occurs in versions of perl prior to 5.22.0, but it can
# arise elsewhere, eg:
# http://www.cpantesters.org/cpan/report/dc17e330-900b-11ec-bfc9-d1f1448276d4
# This procedure is stolen from:
# https://metacpan.org/release/HAARG/Sub-Quote-2.006006/source/t/quotify.t
# Thank you, Haarg.

use B qw(svref_2object);

my %flags;
{
  no strict 'refs';
  for my $flag (qw(
    SVf_IOK
    SVf_NOK
    SVf_POK
    SVp_IOK
    SVp_NOK
    SVp_POK
            )) {
    if (defined &{'B::'.$flag}) {
      $flags{$flag} = &{'B::'.$flag};
    }
  }
}

sub flags {
  my $flags = B::svref_2object(\($_[0]))->FLAGS;
  join ' ', sort grep $flags & $flags{$_}, keys %flags;
}

my $pv_nv_bug = 0;
my $test_nv = 1.3;
my $buggery = "$test_nv";
my $f = flags($test_nv);

if($f =~ /SVf_POK/) {
  print "Dealing with unhelpful setting of POK flag\n";
  $pv_nv_bug = 1;
}

if($pv_nv_bug) {
  $defines .= " -DF128_PV_NV_BUG";
  $DEFS    .= " -DF128_PV_NV_BUG";
  print "Defining F128_PV_NV_BUG\n\n";
}
else {
  print "Not defining F128_PV_NV_BUG\n\n";
}
####################################

my %options = %{
{
  NAME => 'Math::Float128',
  DEFINE => $defines,
  LIBS => [
    '-lquadmath -lm'
  ],
  INC => '',
  LICENSE  => 'perl',
  VERSION_FROM => 'Float128.pm',
  clean   => { FILES => 'quad.exe' },
  META_MERGE => {
   'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url => 'https://github.com/sisyphus/math-float128.git',
        web => 'https://github.com/sisyphus/math-float128',
      },
    },
  },
}
};
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
