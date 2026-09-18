package Developer::Dashboard::Pax::HotRegionJIT;

our $VERSION = '4.45';

use strict;
use warnings;
use JSON::XS ();

sub new {
    my ($class, %args) = @_;
    return bless {
        threshold => $args{threshold} // 2,
    }, $class;
}

sub decision {
    my ($self, %args) = @_;
    my $unit = $args{ssa_unit} // {};
    my $profile = $args{profile} // {};
    my $dispatches = $profile->{dispatches} // 0;
    my $shape = $unit->{native_shape} // $unit->{source}{native_shape} // {};
    my $has_native_shape = %$shape ? 1 : 0;

    if (!$has_native_shape) {
        return {
            status => 'barrier',
            reason => 'region has no native lowering shape',
            hot => JSON::XS::false(),
        };
    }

    if ($dispatches + 1 >= $self->{threshold}) {
        return {
            status => 'promote',
            reason => 'profile threshold reached',
            hot => JSON::XS::true(),
            tier => 'tier-1',
        };
    }

    return {
        status => 'observe',
        reason => 'profile threshold not reached',
        hot => JSON::XS::false(),
        tier => 'interpreter',
    };
}

sub retirement {
    my ($self, %args) = @_;
    return {
        status => 'retire',
        reason => $args{reason} // 'native region retired',
        region_id => $args{region_id},
        region_name => $args{region_name},
    };
}

1;

__END__

=pod

=head1 NAME

Developer::Dashboard::Pax::HotRegionJIT - hot-region promotion planner

=head1 SYNOPSIS

  use Developer::Dashboard::Pax::HotRegionJIT;

  my $obj = Developer::Dashboard::Pax::HotRegionJIT->new(...);
  my $result = $obj->decision(...);

=head1 DESCRIPTION

Decides when a profiled region is hot enough to justify promotion into a native or JIT-oriented execution path.

=head1 METHODS

=head2 new, decision, retirement

These are the public entrypoints exposed by this module's current interface.

=head1 PURPOSE

This module exists to keep the hot-region promotion planner logic in one place so the CLI, build
pipeline, and runtime can reuse the same behavior instead of duplicating it.

=head1 WHY IT EXISTS

PAX uses this module when it needs hot-region promotion planner. Keeping that behavior isolated here
makes the surrounding compiler and packaging stages easier to reason about and
safer to evolve.

=head1 WHEN TO USE

Edit this file when a change affects hot-region promotion planner, the data contract this module
returns, or the conditions under which callers choose this path.

=head1 HOW TO USE

Load the module through the normal PAX call path, pass explicit arguments rather
than ambient global state, and keep project-specific behavior out of this file
so the implementation stays neutral across arbitrary Perl applications.

=head1 WHAT USES IT

This module is used by the PAX CLI, the build pipeline, standalone packaging,
and the test suite paths that cover hot-region promotion planner.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::Pax::HotRegionJIT -e 1

Confirm that the module loads from a source checkout.

Example 2:

  prove -lr t

Run the repository test suite after changing the behavior this module owns.

=cut
