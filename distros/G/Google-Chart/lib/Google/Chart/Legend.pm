# $Id$

package Google::Chart::Legend;
use Moose;
use Moose::Util::TypeConstraints;
use URI::Escape ();

with 'Google::Chart::QueryComponent';

coerce 'Google::Chart::Legend'
    => from 'HashRef'
    => via {
        Google::Chart::Legend->new(%{$_});
    }
;
coerce 'Google::Chart::Legend'
    => from 'ArrayRef'
    => via {
        Google::Chart::Legend->new(values => $_);
    }
;

coerce 'Google::Chart::Legend'
    => from 'Str'
    => via {
        Google::Chart::Legend->new(values => [$_])
    }
;

subtype 'Google::Chart::Legend::Data'
    => as 'Str'
;

subtype 'Google::Chart::Legend::DataList'
    => as 'ArrayRef[Google::Chart::Legend::Data]',
;

coerce 'Google::Chart::Legend::DataList'
    => from 'Str'
    => via { [ $_ ] }
;

has 'values' => (
    is => 'rw',
    isa => 'Google::Chart::Legend::DataList',
    coerce => 1,
    required => 1,
    default => sub { +[] }
);

has 'position' => (
    is => 'rw',
    isa => enum([ qw(b t r l) ]),
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub as_query {
    my $self = shift;
    my %data = (
        chdl => join('|', @{ $self->values }),
    );
    if (my $position = $self->position) {
        $data{chdlp} = $position;
    }
    return wantarray ? %data : join('&',
        map {
            join('=', URI::Escape::uri_escape($_), URI::Escape::uri_escape($data{$_}))
        } keys %data
    );
}

1;

__END__

=head1 NAME

Google::Chart::Legend - Google::Chart Legend

=head1 METHODS

=head2 as_query

=cut
