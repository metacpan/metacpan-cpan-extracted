use 5.006001;
use strict;
use warnings;
use ExtUtils::MakeMaker 6.46;

use Config '%Config';
use File::Spec;

# It's a weirdness in ExtUtils::MakeMaker that, when searching for xsubpp,
# it searches @INC for $path/ExtUtils/xsubpp instead of looking for an
# executable in the $PATH or whatever.
# EU::MM will pick up whatever xsubpp is found first in @INC.
# Thus, we must at least warn the user when we're about to install a new
# xsubpp to a location that may be shadowed by an old one.

my $whereto = ($] > 5.010001 ? 'site' : 'perl');
my $instdir = $whereto eq 'site' ? $Config{installsitelib} : $Config{installprivlib};
$instdir = File::Spec->canonpath($instdir);

my $target_xsubpp = File::Spec->catfile($instdir, 'ExtUtils', 'xsubpp');
my @shadowing_xsubpps;
foreach my $dir (grep !ref, @INC) {
  my $cpath = File::Spec->canonpath($dir);
  my $test_xsubpp = File::Spec->catdir($cpath, 'ExtUtils', 'xsubpp');
  last if $cpath eq $instdir or $target_xsubpp eq $test_xsubpp;
  if (-r $test_xsubpp) {
    push @shadowing_xsubpps, $test_xsubpp;
  }
}
if (@shadowing_xsubpps) {
  my $problems = join("\n  ", @shadowing_xsubpps);
  warn <<HERE;

==========================================================
 WARNING WARNING WARNING WARNING WARNING WARNING WARNING
==========================================================
I detected that an old version of 'xsubpp' will shadow the
new, to-be-installed 'xsubpp' (which you need to install
XS modules) after installation.
This is likely because an old version was installed
wrongly or because your vendor patched your perl. You can
continue with the installation but afterwards, you may
have to remove all copies of 'xsubpp' that shadow this
one for future module installations. Failure to do so may
result in your being unable to install XS modules.
But as long as you keep this in mind, nothing is going to
break your system if you do nothing.

Problematic copies of 'xsubpp' found:
  $problems

==========================================================
 WARNING WARNING WARNING WARNING WARNING WARNING WARNING
==========================================================

HERE
  sleep 2;
}

WriteMakefile(
  'NAME' => 'ExtUtils::ParseXS',
  'VERSION_FROM' => 'lib/ExtUtils/ParseXS.pm',
  'PREREQ_PM' => {
    'Carp' => 0,
    'Cwd' => 0,
    'DynaLoader' => 0,
    'Exporter' => '5.57',
    'ExtUtils::CBuilder' => 0,
    'File::Basename' => 0,
    'File::Spec' => 0,
    'Symbol' => 0,
    'Test::More' => '0.47',
    'ExtUtils::MakeMaker' => '6.46',
  },
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.46',
  },
  META_MERGE => {
    resources => {
      bugtracker => 'http://rt.perl.org/rt3/',
      repository => 'git://perl5.git.perl.org/gitroot/perl.git',
    },
  },
  ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM  => 'lib/ExtUtils/ParseXS.pod',
     AUTHOR         => 'Ken Williams <ken@mathforum.org>') : ()),
  'INSTALLDIRS' => $whereto,
  'EXE_FILES' => ['lib/ExtUtils/xsubpp'],
  'PL_FILES' => {}
);
