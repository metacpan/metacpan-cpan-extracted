use Test2::V0 -no_srand => 1;
use lib 't/lib';
use Helper;
use experimental qw( signatures postderef );
use Alien::Build::Wizard;

%Alien::Build::Wizard::Chrome::ask = (
  'What is the class name for your Alien?' => [ 'Alien::libfrooble', 'Alien::auto' ],
  'What is the human project name of the alienized package?' => [ 'libfrooble', 'auto' ],
  'Enter the full URL to the latest tarball (or zip, etc.) of the project you want to alienize.' => ['corpus/alien_build_wizard/auto-1.2.3.tar'],
  'Which pkg-config names (if any) should be used to detect system install?  You may space separate multiple names.' => ['baz  frooble', 'bar foo'],
);

%Alien::Build::Wizard::Chrome::choose = (
  'Choose build system.' => ['cmake','autoconf'],
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
      field 't/basic.t'               => match qr/^use Test[2]::V0;/;
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
