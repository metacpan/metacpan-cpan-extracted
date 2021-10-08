package Helper;

use strict;
use warnings;

package Alien::Build::Wizard::Chrome {

  use Moose;
  use experimental qw( signatures postderef );
  use namespace::autoclean;

  our $use_default;
  our %ask;
  our %choose;

  sub ask ($self, $prompt, $default=undef) {
    die "bad self" unless ref $self eq 'Alien::Build::Wizard::Chrome';
    Test2::V0::note(" [ask] $prompt");
    Test2::V0::note(" [default] $default") if defined $default;
    unless($ask{$prompt})
    {
      if($use_default)
      {
        # ...
      }
      else
      {
        die "unknown prompt: $prompt";
      }
    }
    my $expected_default = $ask{$prompt}->[1];
    die "unexpected default: $default (expected $expected_default)" if defined $expected_default && $expected_default ne $default;
    my $answer = $ask{$prompt}->[0] // $default;
    Test2::V0::note(" > $answer");
    $answer;
  }

  sub choose ($self, $prompt, $options, $default=undef) {
    die "bad self" unless ref $self eq 'Alien::Build::Wizard::Chrome';
    Test2::V0::note(" [choose] $prompt");
    Test2::V0::note(" [options] @{$options}");
    Test2::V0::note(" [default] @{[ $default->@* ]}") if defined $default;
    unless($choose{$prompt})
    {
      if($use_default)
      {
      }
      else
      {
        die "unknown prompt: $prompt" unless $choose{$prompt};
      }
    }
    my $expected_default = $choose{$prompt}->[1];
    die "unexpected default: @{[ $default->@* ]} (expected $expected_default)" if defined $expected_default && $expected_default ne $default->[0];
    my $answer = $choose{$prompt}->[0] // $default->[0];
    Test2::V0::note(" > $answer");
    ref $answer ? @$answer : $answer;
  }

  sub say ($self, $string) {
    Test2::V0::note(" [say] $string");
  }

}

1;
