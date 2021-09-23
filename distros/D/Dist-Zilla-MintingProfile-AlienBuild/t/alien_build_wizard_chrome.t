use Test2::V0 -no_srand => 1;
use Alien::Build::Wizard::Chrome;

is(
  Alien::Build::Wizard::Chrome->new,
  object {
    call [ isa => 'Alien::Build::Wizard::Chrome' ] => T();
  },
);

done_testing;
