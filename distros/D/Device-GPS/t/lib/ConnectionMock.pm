package ConnectionMock;
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;

with 'Device::GPS::Connection';

has 'sentences' => (
    is       => 'ro',
    isa      => 'ArrayRef[Str]',
    required => 1,
);
has 'sentence_index' => (
    is      => 'rw',
    isa     => 'Int',
    default => 0,
);


sub read_nmea_sentence
{
    my ($self) = @_;
    my $i = $self->sentence_index;
    $self->sentence_index( $i + 1 );
    my $sentence = $self->sentences->[$i];
    return $sentence;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

