use strict;
use warnings;
use ExtUtils::MakeMaker;

if($Config::Config{nvsize} > 8) {
  print "  Math::Ryu is currently not usable with this build of perl,\n",
        "  because \$Config{nvsize} ($Config::Config{nvsize}) is greater than 8\n";

  exit 0;
}

my $mycc = '';

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
  print "  Math::Ryu is currently not usable with this build of perl,\n",
        "  because the compiler does not recognize the __uint128_t type";

  exit 0;
}

my %options = (

  NAME => 'Math::Ryu',
  PREREQ_PM    => { 'Test::More' => '0.88', },
  LICENSE      => 'perl',
  VERSION_FROM => 'Ryu.pm',
  clean        => { FILES => '*.exe' },
  OBJECT       => '$(O_FILES)',
  META_MERGE   => {
    'meta-spec'  => { version => 2 },
    resources    => {
      repository   => {
        type         => 'git',
        url          => 'https://github.com/sisyphus/math-ryu.git',
        web          => 'https://github.com/sisyphus/math-ryu',
      },
    },
  },
);
WriteMakefile(%options);

# Remove the Makefile dependency. Causes problems on a few systems.
sub MY::makefile { '' }
