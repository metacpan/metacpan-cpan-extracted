use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Helper;
use experimental qw( signatures postderef );
use Alien::Build::Wizard;
use Alien::Build::Wizard::Questions qw( :all );

%Alien::Build::Wizard::Chrome::ask = (
  QUESTION_URL()        => ['corpus/alien_build_wizard/auto-1.2.3.tar'],
  QUESTION_CLASS_NAME() => [ 'Alien::libfrooble', 'Alien::auto' ],
  QUESTION_HUMAN_NAME() => [ 'libfrooble', 'auto' ],
  QUESTION_PKG_NAMES()  => ['baz  frooble', 'bar foo'],
);

%Alien::Build::Wizard::Chrome::choose = (
  QUESTION_BUILD_SYSTEM() => ['cmake','autoconf'],
  QUESTION_ALIEN_TYPE()   => ['tool', 'xs'],
  QUESTION_LATEST()       => ['latest'],
);

is(
  Alien::Build::Wizard->new,
  object {
    call [ isa => 'Alien::Build::Wizard' ] => T();
    call detect => object {
      call [ isa => 'Alien::Build::Wizard::Detect' ] => T();
    };
    call class_name => 'Alien::libfrooble';
    call human_name => 'libfrooble';
    call pkg_names => ['baz','frooble'];
    call build_type => 'cmake';
    call extract_format => 'tar';
    call generate_content => hash {
      field 'lib/Alien/libfrooble.pm' => match qr/^package Alien::libfrooble;/;
      field 'alienfile'               => match qr/^use alienfile;/;
      field 't/alien_libfrooble.t'    => match qr/^use Test[2]::V0;/;
      end;
    };
    call sub ($wiz) {
      my %content = $wiz->generate_content->%*;
      foreach my $name (sort keys %content)
      {
        note "[$name]";
        note $content{$name};
      }
      1;
    } => 1;
  },
);

done_testing;
