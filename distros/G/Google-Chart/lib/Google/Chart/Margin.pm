package Google::Chart::Margin;
use Moose;
use Moose::Util::TypeConstraints;

use constant parameter_name => 'chma';

with 'Google::Chart::QueryComponent::Simple';

coerce 'Google::Chart::Margin'
    => from 'ArrayRef'
    => via {
        my $aref = $_;

        return Google::Chart::Margin->new(
            left     => $aref->[0],
            right    => $aref->[1],
            top      => $aref->[2],
            bottom   => $aref->[3],
            legend_x => $aref->[4],
            legend_y => $aref->[5],
        );
    }
;

has 'left' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has 'right' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has 'top' => (
    is => 'rw',
    isa => 'Int',
   required => 1
);

has 'bottom' => (
    is => 'rw',
    isa => 'Int',
    required => 1
);

has 'legend_x' => (
    is => 'rw',
    #isa => 'Int',
    required => 0
);

has 'legend_y' => (
    is => 'rw',
    #isa => 'Int',
    required => 0
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;

    my $str = 
    join(',', $self->left, $self->right, $self->top, $self->bottom );

    if($self->legend_x) {
        $str .= "|" . $self->legend_x . "," . $self->legend_y;
    }

    return $str;
}

1;

__END__

=head1 NAME

Google::Chart::Margin - Google::Chart Margin

=cut
