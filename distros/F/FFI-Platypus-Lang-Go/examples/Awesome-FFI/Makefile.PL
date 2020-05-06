use strict;
use warnings;
use ExtUtils::MakeMaker;
use FFI::Build::MM;

my $fbmm = FFI::Build::MM->new;

WriteMakefile($fbmm->mm_args(
  ABSTRACT => 'Awesome Go Extension',
  DISTNAME => 'Awesome-FFI',
  NAME     => 'Awesome::FFI',
  VERSION  => '1.00',
));

sub MY::postamble {
  $fbmm->mm_postamble;
}
