# $Id$

package Google::Chart::Type::QRcode;
use Moose;
use Moose::Util::TypeConstraints;
use Encode ();

enum 'Google::Chart::Type::QRcode::Encoding' => qw(shift_jis utf-8 iso-8859-1);
enum 'Google::Chart::Type::QRcode::ECLevel' => qw(L M Q H);

coerce 'Google::Chart::Type::QRcode::Encoding'
    => from 'Str'
    => via {
        s/^Shift[-_]JIS$/shift_jis/ ||
        s/^UTF-?8$/utf-8/ ||
            return lc $_;
    }
;

with 'Google::Chart::Type';

has 'text' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'encoding' => (
    is => 'rw',
    isa => 'Google::Chart::Type::QRcode::Encoding',
    required => 1,
    default => 'utf-8',
    coerce => 1
);

has 'eclevel' => (
    is => 'rw',
    isa => 'Google::Chart::Type::QRcode::ECLevel',
);

has 'margin' => (
    is => 'rw',
    isa => 'Num'
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub as_query {
    my $self = shift;
    my %data = (
        cht  => 'qr',
        chl  => Encode::is_utf8($self->text) ?
            Encode::decode_utf8($self->text) : $self->text,
        choe => $self->encoding,
        chld => $self->eclevel || $self->margin ? 
            join( '|', $self->eclevel || '', $self->margin || '') : ''
    );

    return %data;
}

1;

__END__

=head1 NAME

Google::Chart::Type::QRcode - Google::Chart QRcode Type

=head1 METHODS

=head2 as_query

=cut