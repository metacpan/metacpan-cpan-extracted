use strict;
use warnings;
use ExtUtils::MakeMaker;
use Cwd;

# A cpantester's build of perl is/was specifying "LIBS=-lquadmath" in the Perl_MM_OPT
# envirnoment variable - which overrides the assignemt to $options{LIBS} below,
# at line 115.
# See https://www.cpantesters.org/cpan/report/243224aa-6c9a-1014-a249-f265ef72f936 .
# The following substitution regex works around the problem.
{
  no warnings 'uninitialized'; # It doesn't matter if $ENV{PERL_MM_OPT} is uninitialized.
  $ENV{PERL_MM_OPT} =~ s/\sLIBS=\-lquadmath|^LIBS=\-lquadmath//;
}

# We need to know whether the __uint128_t type is available.
my $defines = '';
my $ccflags = $Config::Config{ccflags}; # Below, we will append '-std=c99' to the
                                        # CCFLAGS, if we detect that it's necessary.
my $mycc    = '';
my $avoid_generic_128 = 0;
$avoid_generic_128 = 1
  if ($Config::Config{make} eq 'dmake');

$defines .= ' -DAVOID_GENERIC_128'
  if $avoid_generic_128;

if(@ARGV) {
  for my $arg(@ARGV) {
    $mycc   = (split /=/, $arg)[1] if $arg =~ /^cc=/i;
  }
}

unless($mycc) {
  $mycc = defined($Config::Config{cc}) ? $Config::Config{cc} : 'cc';
}

my $out = `$mycc -o have_uint128_t.exe -x c have_uint128_t.in 2>&1`;

unless(-e 'have_uint128_t.exe') {
  print "  The __uint128_t type is unavailable\n";
  if($Config::Config{nvsize} != 8) {
    print "  We are unable to continue for this perl configuration ($Config::Config{archname}).\n";
    exit 0;
  }
}
else {
  $defines .= " -DCOMPILER_HAS_UINT128_T";
}

# In Ryu.pm we define the constant MAX_DEC_DIG.
# Here (following the same procedure)  we set the XS symbol of the same name, to the same value.
if($Config::Config{nvsize} == 8)               { $defines .= ' -DMAX_DEC_DIG=17' }
elsif($Config::Config{nvtype} eq '__float128') { $defines .= ' -DMAX_DEC_DIG=36' }
elsif(defined($Config::Config{longdblkind})
      && $Config::Config{longdblkind} < 3)     { $defines .= ' -DMAX_DEC_DIG=36' }
else                                           { $defines .= ' -DMAX_DEC_DIG=21' }

my $top_dir = getcwd();
$top_dir =~ s/\\/\//g;

my $lib_loc = 'Ryu_Library/ryu';

$defines .= ' -Dinline=__inline'
   if ($^O eq 'MSWin32' && $Config::Config{cc} eq 'cl');

if($defines =~ /\-DCOMPILER/ && !$avoid_generic_128) {
  ## BUILD RYU LIBRARY ##
  if(chdir "./$lib_loc") {
    my $make = $Config::Config{make};
    my $cc = $Config::Config{cc};
    my @flags = ("CC=$cc");
    if($Config::Config{cccdlflags} =~ /\-fPIC/) {
      push(@flags, "CFLAGS=-fPIC -std=c99");
      $ccflags .= ' -std=c99' unless $ccflags =~ /\-std=c99/;
    }
    $ccflags .= '-KPIC' if $Config::Config{cccdlflags} =~ /\-KPIC/; # Might fix (?) solaris failure:
                                                                    # https://www.cpantesters.org/cpan/report/7e6176b8-d7b0-11ee-ae74-376db46fd3dd
    system($make, @flags);
  }

  chdir $top_dir;
  die "Can't find libryu.a"
    unless -e "./${lib_loc}/libryu.a";
}

my %options = (

  NAME => 'Math::Ryu',
  PREREQ_PM    => { 'Test::More' => '0.88', },
  DEFINE       => $defines,
  CCFLAGS      => $ccflags,
  LICENSE      => 'perl',
  INC          => "-I${top_dir}/${lib_loc}",
  VERSION_FROM => 'Ryu.pm',
  clean        => { FILES => "./${lib_loc}/*.o ./*.o ./${lib_loc}/*.a *.exe" },
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-ryu-l.git',
        web          => 'https://github.com/sisyphus/math-ryu-l',
      },
    },
  },
);

if($defines !~ /\-DCOMPILER/ || $avoid_generic_128) {
  # Compile f2s.c, d2s.c, s2d.c and d2fixed.c
  # NOTE: The current Ryu_Library/ryu/Makefile
  #       won't work with 'nmake' and 'dmake'.
  $options{OBJECT} = '$(O_FILES)';
  #$ENV{INCLUDE} .= ";${top_dir}/${lib_loc};";
}
else {
  # Build libryu.a and build against it
  $options{LIBS} = [ "-L${top_dir}/${lib_loc} -lryu" ];
}
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
