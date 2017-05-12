package DZT::Sample;
# ABSTRACT: Sample DZ Dist

use strict;
use warnings;

# This { {comment}} should be unchanged.

# RECOMMEND PREREQ: Foo::Bar 1.00
# RECOMMEND PREREQ: Foo::Baz

our $VERSION = '0.04';
# This file is part of {{$dist}} {{$dist_version}} ({{$date}})

# File: {{$filename}}
# Path: {{$pathname}}

=attr bogus

Don't have this.

=method return_arrayref_of_values_passed

blah

=cut

sub return_arrayref_of_values_passed {
  my $invocant = shift;
  return \@_;
}

1;

=head1 DEPENDENCIES

DZT::Sample requires {{$t->dependency_link('Bloofle')}} and
{{$t->dependency_link('Foo::Bar')}}.

=cut
