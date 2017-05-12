use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config qw(%Config);
use Getopt::Long qw(GetOptions);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $name = 'Math::Histogram';
my $define = '';

GetOptions(
  'debug:i'  => \(my $DEBUG),
  #'gdb'      => \(my $USE_GDB),
  'valgrind' => \(my $USE_VALGRIND),
);

my $USE_GDB; # WARNING! DOESN'T WORK INTERACTIVELY
if ($USE_VALGRIND and $USE_GDB) {
  die "Can only use valgrind or gdb, not both at the same time.";
}
elsif ($USE_VALGRIND or $USE_GDB) {
  $DEBUG = 1 if $DEBUG < 1;
  my $fh;
  open $fh, ">", "USE_GDB" if $USE_GDB; # HACK :(
  open $fh, ">", "USE_VALGRIND" if $USE_VALGRIND; # HACK :(
}

if (not $DEBUG) {
  $define .= ' -O2';
}
else {
  if ($DEBUG) {
    $define .= ' -Wall -Wextra -O0 -ggdb -DDEBUG';
  }
  if ($DEBUG > 1) {
    $define .= ' -pedantic';
  }
}

my @test_cfiles;
my @test_exefiles;
if ($DEBUG) {
  my $ctest_dir = 'ctest';
  @test_cfiles = glob("$ctest_dir/*.c");
  foreach my $file (@test_cfiles) {
    (my $exefile = $file) =~ s/\.c$/$Config{exe_ext}/;
    push @test_exefiles, $exefile;
  }
  print "Debug mode. Will build C tests:\n  ",
    join("\n  ", @test_exefiles), "\n";
}

WriteMakefile(
    NAME              => $name,
    VERSION_FROM      => 'lib/Math/Histogram.pm', # finds $VERSION
    PREREQ_PM         => {
      'ExtUtils::ParseXS' => '2.21',
      'Test::More'        => '0.94',
      'File::Spec'        => '0',
      'Capture::Tiny'     => '0',
      'Getopt::Long'      => '0', # FIXME move to CONFIGURE_REQUIRES at some point
      'JSON::XS'          => '0',
      'Data::Dumper'      => '0',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Math/Histogram.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
    LIBS              => ['-lm'],
    DEFINE            => $define,
    INC               => '-I.',
    OBJECT            => '$(O_FILES)', # link all the C files too
    clean => {FILES => "@test_exefiles USE_VALGRIND USE_GDB"}
);


sub MY::postamble {
  if ($DEBUG) {
    my $make_frag = <<MAKE_FRAG;
linkext :: ctests

ctests:
MAKE_FRAG
    foreach my $i (0..$#test_cfiles) {
      my $file = $test_cfiles[$i];
      my $exefile = $test_exefiles[$i];
      $make_frag .= "\t\$(CC) $define -I. $file mh*.o -lm -o $exefile\n";
    }
    return $make_frag;
  }
  else {
    return "\n";
  }
}

