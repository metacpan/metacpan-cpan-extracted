package HPC::Runner::Command::Utils::Traits;

use strict;
use warnings;

use MooseX::Types -declare => [qw( ArrayRefOfStrs  )];
use MooseX::Types::Moose qw( ArrayRef Str  );

=head1 HPC::Runner::Command::Utils::Traits

=head2 Utils

=cut

subtype ArrayRefOfStrs, as ArrayRef [Str];

coerce ArrayRefOfStrs, from Str, via { [ split( ',', $_ ) ] };

1;
