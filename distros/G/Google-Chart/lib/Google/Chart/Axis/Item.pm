# $Id$

package Google::Chart::Axis::Item;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Axis::Style;

enum 'Google::Chart::Axis::Location' => qw(x y r t);

subtype 'Google::Chart::Axis::StyleList'
    => as 'ArrayRef[Google::Chart::Axis::Style]'
;

coerce 'Google::Chart::Axis::StyleList'
    => from 'ArrayRef[HashRef]'
    => via { 
        my @list;
        foreach my $h (@$_) {
            push @list, Google::Chart::Axis::Style->new(%$h);
        }
        return \@list;
    }
;

has 'location' => (
    is => 'rw',
    isa => 'Google::Chart::Axis::Location',
);

has 'labels' => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    auto_deref => 1,
);

has 'label_positions' => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    auto_deref => 1,
);

has 'range' => (
    is => 'rw',
    isa => 'ArrayRef[Num]',
    auto_deref => 1,
);

has 'styles' => (
    is => 'rw',
    isa => 'Google::Chart::Axis::StyleList',
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

1;

__END__

=head1 NAME

Google::Chart::Axis::Item - Google::Chart Axis Item

=cut
