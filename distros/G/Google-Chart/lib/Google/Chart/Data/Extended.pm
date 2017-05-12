# $Id$

package Google::Chart::Data::Extended;
use Moose;
use Scalar::Util qw(looks_like_number);

with 'Google::Chart::Data';

has 'max_value' => (
    is => 'rw', 
    isa => 'Num',
    required => 1,
);

has 'min_value' => (
    is => 'rw', 
    isa => 'Num',
    required => 1,
    default => 0,
);

has '+dataset' => (
    isa => 'ArrayRef[Google::Chart::Data::Extended::DataSet]',
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub BUILDARGS {
    my $self = shift;

    # A dataset must be an array of arrays or array of values
    my @dataset;
    my @dataargs;
    my %args;

    if (@_ == 1 && ref $_[0] eq 'ARRAY') {
        @dataargs = @{$_[0]};
    } else {
        %args = @_;
        @dataargs = @{ delete $args{dataset} || [] };
    }

    if (! ref $dataargs[0] ) {
        @dataargs = ([ @dataargs]);
    }

    foreach my $dataset ( @dataargs ) {
        if (! Scalar::Util::blessed $dataset) {
            $dataset = Google::Chart::Data::Extended::DataSet->new(data => $dataset)
        }
        push @dataset, $dataset;
    }

    return { %args, dataset => \@dataset }
}

sub parameter_value {
    my $self = shift;
    my $max = $self->max_value;
    my $min = $self->min_value;
    sprintf('e:%s',
        join( ',', map { $_->as_string({max => $max, min => $min}) } @{ $self->dataset } ) );
}

package # hide from PAUSE
    Google::Chart::Data::Extended::DataSet;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Google::Chart::Data::Extended::DataSet::Value'
    => as 'Num';

has 'data' => (
    is => 'rw',
    isa => 'ArrayRef[Maybe[Google::Chart::Data::Extended::DataSet::Value]]',
    required => 1,
    default => sub { +[] },
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

my @map = ('A'..'Z', 'a'..'z', 0..9, '-', '.');

sub as_string {
    my ($self, $args) = @_;
    my $max = $args->{max};
    my $min = $args->{min};
    my $map_size = scalar @map;
    my $scale    = $map_size ** 2  - 1;
    my $result = '';
    for my $data (@{$self->data}) {
        my $v = '__';
#        if (defined $data && looks_like_number($data)) {
            my $normalized = int((($data - $min) * $scale) / abs($max - $min));
            if ($normalized < 0) {
                $normalized = 0;
            } elsif ($normalized >= $scale) {
                $normalized = $scale - 1;
            }

            $v = $map[ int($normalized / $map_size)  ] . $map[ int($normalized % $map_size) ];
#        }

        $result .= $v;
    }
    return $result;
}

1;

__END__

=head1 NAME

Google::Chart::Data::Extended - Google::Chart Extended Data Encoding

=head1 SYNOPSIS

=head1 METHODS

=head2 parameter_value

=cut
