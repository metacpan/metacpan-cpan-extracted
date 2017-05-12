# $Id$

package Google::Chart::Title;
use Moose;
use Google::Chart::Types;
use Moose::Util::TypeConstraints;

coerce 'Google::Chart::Title'
    => from 'HashRef'
    => via {
        Google::Chart::Title->new(%$_);
    }
;

with 'Google::Chart::QueryComponent';

has 'text' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has 'color' => (
    is => 'rw',
    isa => 'Google::Chart::Color',
);

has 'fontsize' => (
    is => 'rw',
    isa => 'Num'
);

__PACKAGE__->meta->make_immutable;

no Moose;

sub as_query {
    my $self = shift;

    my $text = $self->text;
    $text =~ s/\r?\n/|/gsm;
    my %data = (
        chtt => $text
    );

    my $color = $self->color;
    my $fontsize = $self->fontsize;
    if (defined $color || defined $fontsize) {
        $data{chts} = join(',', 
            defined $color ? $color : '',
            defined $fontsize ? $fontsize : ''
        );
    }

    return wantarray ? %data : 
        join('&', map { "$_=$data{$_}" } keys %data );
}

1;

__END__

=head1 NAME

Google::Chart::Title - Apply Title 

=head1 METHODS

=head2 as_query

=cut
