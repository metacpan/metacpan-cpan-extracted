package Google::Chart::Color;
use Moose;
use Moose::Util::TypeConstraints;

use constant parameter_name => 'chco';

with 'Google::Chart::QueryComponent::Simple';

coerce 'Google::Chart::Color'
    => from 'ArrayRef'
    => via {
        Google::Chart::Color->new(values => $_);
    }
;
coerce 'Google::Chart::Color'
    => from 'HashRef'
    => via {
        Google::Chart::Color->new(%{$_});
    }
;
coerce 'Google::Chart::Color'
    => from 'Str'
    => via {
        Google::Chart::Color->new(values => [$_]);
    }
;

subtype 'Google::Chart::Color::Data'
    => as 'Str'
    => where { /^[a-f0-9]{6}$/i }
    => message { "value '$_' is not a valid hexadecimal value" }
;

subtype 'Google::Chart::Color::DataList'
    => as 'ArrayRef[Google::Chart::Color::Data]'
;

coerce 'Google::Chart::Color::DataList'
    => from 'Str'
    => via { [ $_ ] }
;

has 'values' => (
    is => 'rw',
    isa => 'Google::Chart::Color::DataList',
    coerce => 1,
    required => 1,
    default => sub { +[] }
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub parameter_value {
    my $self = shift;
    join(',', @{ $self->values });
}

1;

__END__

=head1 NAME

Google::Chart::Color - Google::Chart Color

=cut
