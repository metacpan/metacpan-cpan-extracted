# $Id$

package Google::Chart::Data::Text;
use Moose;

with 'Google::Chart::Data';

has '+dataset' => (
    isa => 'ArrayRef[Google::Chart::Data::Text::DataSet]',
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
            $dataset = Google::Chart::Data::Text::DataSet->new(data => $dataset)
        }
        push @dataset, $dataset;
    }

    return { %args, dataset => \@dataset }
}

sub parameter_value {
    my $self = shift;
    sprintf('t:%s',
        join( '|', map { $_->as_string } @{ $self->dataset } ) )
}

package  # hide from PAUSE
    Google::Chart::Data::Text::DataSet;
use Moose;
use Moose::Util::TypeConstraints;

subtype 'Google::Chart::Data::Text::DataSet::Value'
    => as 'Num'
    => where {
        ($_ >= 0 && $_ <= 100) || $_ == -1
    }
;

has 'data' => (
    is => 'rw',
    isa => 'ArrayRef[Maybe[Google::Chart::Data::Text::DataSet::Value]]',
    required => 1,
    default => sub { +[] }
);

__PACKAGE__->meta->make_immutable;
    
no Moose;
no Moose::Util::TypeConstraints;

sub as_string {
    my $self = shift;
    return join(',', map { sprintf('%0.1f', $_) } @{$self->data});
}

1;

__END__

=head1 NAME

Google::Chart::Data::Text - Google::Chart Text Encoding

=head1 SYNOPSIS

  Google::Chart->new(
    data => {
      type => "Text",
      dataset => [ .... ]
    }
  );

=head1 METHODS

=head2 parameter_value

=cut