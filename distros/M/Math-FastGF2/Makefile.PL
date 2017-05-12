use 5.006000;
use ExtUtils::MakeMaker;

use Config;

# Attempt to divine the size of the native C data types and set up
# -DDEFINES to change how the gf2_u16 and gf2_u32 types are defined
# during compilation.
my @defines=();
sub find_right_type {
  my $size=shift;
  if ($Config{shortsize} == $size) {
    return "SHORT";
  } elsif ($Config{intsize}  == $size) {
    return "INT";
  } elsif ($Config{longsize} == $size) {
    return "LONG";
  } elsif (exists($Config{d_longlong}) and
	   $Config{d_longlong} eq "HAS_LONG_LONG" and
	   $Config{longlongsize} == $size) {
    return "LONGLONG";		# long (long) shot
  } else {
    return "NOTHING";
  }
}

if (scalar(@ARGV) > 0 and $ARGV[0] =~ "USE_CUSTOM_TYPEDEFS") {
  warn "OK, skipping attempt to divine proper typedefs from \$Config\n";
  push @defines,"-DUSE_CUSTOM_TYPEDEFS";
  shift @ARGV;
} else {
  foreach my $size (2,4) {
    my $what=find_right_type($size);
    if ($what eq "NOTHING") {
      warn "Couldn't find a C data type on this machine with $size bytes\n";
      warn "You will have to edit the file clib/FastGF2.h manually\n";
      warn "Then re-run with USE_CUSTOM_TYPEDEFS as the first parameter\n";
      exit 0;
    }
    push @defines,"-D${what}_HAS_" . ($size << 3) ."_BITS";
  }
}

WriteMakefile(
 NAME              => 'Math::FastGF2',
 VERSION_FROM      => 'lib/Math/FastGF2.pm',
 PREREQ_PM         => {}, # e.g., Module::Name => 1.1
 ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
  (ABSTRACT_FROM  => 'lib/Math/FastGF2.pm', # retrieve abstract from module
   AUTHOR         => 'Declan Malone <idablack@users.sourceforge.net>') :
  ()),
 LIBS              => [''], # e.g., '-lm'
 DEFINE            => (join ' ', @defines),
 INC               => '-I.', # e.g., '-I. -I/usr/include/other'
# DIR               => ['clib'],
 MYEXTLIB          => 'clib/libfastgf2$(LIB_EXT)',
# Un-comment this if you add C files to link with later:
# OBJECT            => 'FastGF2.o', # link all the C files too
# OBJECT            => '$(O_FILES)', # link all the C files too
 EXE_FILES          => ['bin/benchmark-Math-FastGF2.pl',
			'bin/shamir-combine.pl',
			'bin/shamir-split.pl'],
);

sub MY::postamble {
# See perlxstut. This also passes any -DDEFINEs along to recursive make
'$(MYEXTLIB): clib/Makefile
	cd clib && perl Makefile.PL DEFINE="' .
(join ' ', @defines) . '"&& $(MAKE) $(PASSTHRU)

# Add dependency to ensure files are rebuilt if perlsubs.c changes
FastGF2.c : perlsubs.c
';
}
