use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use lib 't/lib';
use Helper;
use Alien::Build::Wizard::Questions qw( :all );
use Alien::Build::Wizard;
use URI;
use Path::Tiny qw( path );

skip_all 'Test only runs in CI'
  unless defined $ENV{CIPSOMETHING} && $ENV{CIPSOMETHING} eq 'true';

%Alien::Build::Wizard::Chrome::ask = (
  QUESTION_URL()        => [ 'https://github.com/PerlAlien/dontpanic/archive/1.02.tar.gz' ],
  QUESTION_CLASS_NAME() => [ 'Alien::libdontpanic'                                        ],
  QUESTION_HUMAN_NAME() => [ 'libdontpanic'                                               ],
  QUESTION_PKG_NAMES()  => [                                                              ],
);

%Alien::Build::Wizard::Chrome::choose = (
  QUESTION_BUILD_SYSTEM() => [ 'autoconf' ],
  QUESTION_ALIEN_TYPE()   => [ 'xs'       ],
  QUESTION_LATEST()       => [ 'specific' ],
);

alien_subtest 'autoconf xs' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ 'xs' ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf ffi' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ 'ffi' ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf xs + ffi' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ ['ffi', 'xs'] ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf tool + xs + ffi' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ ['tool', 'ffi', 'xs'] ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf tool + ffi' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ ['tool', 'ffi' ] ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf tool + xs' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ ['tool', 'xs' ] ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'autoconf tool' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_ALIEN_TYPE()} = [ ['tool'] ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'no pkg-config' => sub {

  my $alienfile_text = Alien::Build::Wizard->new(
    pkg_names => [],
  )->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'probe for one .pc' => sub {

  local $Alien::Build::Wizard::Chrome::ask{QUESTION_PKG_NAMES()} = [ 'libarchive' ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'probe for two .pc' => sub {

  local $Alien::Build::Wizard::Chrome::ask{QUESTION_PKG_NAMES()} = [ 'libarchive libffi' ];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'fetch latest' => sub {

  local $Alien::Build::Wizard::Chrome::choose{QUESTION_LATEST()} = [ 'latest' ];
  my $alienfile_text = Alien::Build::Wizard->new(
    # TODO: should be smarter about fetching from GitHub + Latest
    start_url => URI->new('https://github.com/PerlAlien/dontpanic/releases'),
  )->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

alien_subtest 'cmake' => sub {

  local $Alien::Build::Wizard::Chrome::ask{QUESTION_URL()} = [path('corpus/alien_build_wizard__ci/libpalindrome.tar.gz')->absolute->stringify];
  local $Alien::Build::Wizard::Chrome::choose{QUESTION_BUILD_SYSTEM()} = ['cmake'];
  my $alienfile_text = Alien::Build::Wizard->new->generate_content->{'alienfile'};
  note $alienfile_text;
  alienfile_ok $alienfile_text;
  alien_build_ok;

};

done_testing;
