use strict;
use warnings;
use Test::More 0.96;

my $mod = 'Dist::Metadata';
eval "require $mod" or die $@;

{
  foreach my $test (
    [
      {
        buzzwords => {
          file    => 'lib/buzzwords.pm',
          version => '0.1',
        },
      },
      {
        buzzwords => '0.1',
      }
    ],
    [
      {
        fulfillment_issues => {
          file => 'lib/fulfillment_issues.pm'
        }
      },
      {
        fulfillment_issues => undef,
      }
    ],
    [
      {
        'Design::Patterns' => {
          file    => 'lib/Design/Patterns.pm',
          version => 0.2
        },
        'Paradigm::Shift' => {
          file    => 'lib/Paradigm/Shift.pm',
          version => 'v1.3.5',
        }
      },
      {
        'Design::Patterns' => 0.2,
        'Paradigm::Shift'  => 'v1.3.5',
      },
    ],
  ){

    my ($provides, $exp) = @$test;

    is_deeply($mod->package_versions($provides), $exp, 'package_versions');
  }
}

done_testing;
