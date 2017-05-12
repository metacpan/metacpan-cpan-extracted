# $Id$

package Google::Chart::Axis;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Axis::Item;

with 'Google::Chart::QueryComponent';

coerce 'Google::Chart::Axis'
    => from 'ArrayRef[HashRef]'
    => via {
        Google::Chart::Axis->new(axes => $_);
    }
;

subtype 'Google::Chart::Axis::ItemList'
    => as 'ArrayRef[Google::Chart::Axis::Item]'
;

coerce 'Google::Chart::Axis::ItemList'
    => from 'ArrayRef'
    => via {
        my @list;
        foreach my $h (@$_) {
            push @list, Google::Chart::Axis::Item->new(%$h);
        }
        return \@list;
    }
;

has 'axes' => (
    is => 'rw',
    isa => 'Google::Chart::Axis::ItemList',
    coerce => 1,
    auto_deref => 1,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub as_query {
    my $self = shift;

    my (@chxt, @chxl, @chxp, @chxr, @chxs);
    my %data = (
        chxl => \@chxl,
        chxp => \@chxp,
        chxr => \@chxr,
        chxs => \@chxs
    );

    foreach my $axis ($self->axes) {
        push @chxt, $axis->location;

        my $index = $#chxt;
        if (my @labels = $axis->labels) {
            push @chxl, join("|", "$index:", @labels);
        }

        if (my @label_positions = $axis->label_positions) {
            push @chxp, join(",", $index, @label_positions);
        }

        if (my @range = $axis->range) {
            push @chxr, join(",", $index, @range);
        }

        if (my @styles = $axis->styles) {
            push @chxs, join(",", $index, map { $_->as_query } @styles);
        }
    }

    foreach my $key (keys %data) {
        $data{$key} = join('|', @{$data{ $key }});
    }
    $data{chxt} = join(',', @chxt);

    return %data;
}

1;

__END__

=head1 NAME

Google::Chart::Axis - Google::Chart Axis Specification 

=head1 METHODS

=head2 as_query

=cut
