use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MP3::Splitter',
    VERSION_FROM      => 'Splitter.pm', # finds $VERSION
    PREREQ_PM         => {MPEG::Audio::Frame => 0.04}, # e.g., Module::Name => 1.1
    clean	      => { FILES => '0*_test.mp3 test.mp3' },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'Splitter.pm', # retrieve abstract from module
       AUTHOR         => 'Ilya Zakharevich <cpan@ilyaz.org>') : ()),
);
unless (-f 'test.mp3') {
  open F, '< frame1.mp3' or die;
  binmode F;
  read F, my $ctx, 0x1000 or die;
  close F or die;

  open F, '< Xing.mp3' or die;
  binmode F;
  read F, my $Xing, 0x1000 or die;
  close F or die;

  $ctx x= 5500;		# Make longer
  open F, '> test.mp3' or die;
  binmode F;
  print F $Xing or die;
  print F $ctx or die;
  close F or die;
}
