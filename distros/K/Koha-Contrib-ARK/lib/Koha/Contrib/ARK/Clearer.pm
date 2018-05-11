package Koha::Contrib::ARK::Clearer;
$Koha::Contrib::ARK::Clearer::VERSION = '1.0.2';
# ABSTRACT: Clear Koha ARK field
use Moose;

with 'AnyEvent::Processor::Converter';

use Modern::Perl;
use Koha::Contrib::ARK::Reader;
use Koha::Contrib::ARK::Writer;
use AnyEvent::Processor::Conversion;

has ark => ( is => 'rw', isa => 'Koha::Contrib::ARK' );


sub convert {
    my ($self, $br) = @_;

    my ($biblionumber, $record) = @$br;
    return $br unless $record;

    my $ark = $self->ark;
    my $ka = $ark->c->{ark}->{koha}->{ark};
    my ($tag, $letter) = ($ka->{tag}, $ka->{letter});

    $ark->log->debug("Remove ARK field\n");
    if ( $letter ) {
        for my $field ( $record->field($tag) ) {
            my @subf = grep { $_->[0] ne $letter; } @{$field->subf};
            $field->subf( \@subf );
        }
        $record->fields( [ grep {
            $_->tag eq $tag && @{$_->subf} == 0 ? 0 : 1;
        } @{ $record->fields } ] );
    }
    else {
        $record->delete($tag);
    }
    return [$biblionumber, $record];
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Clearer - Clear Koha ARK field

=head1 VERSION

version 1.0.2

=head1 ATTRIBUTES

=head2 ark

L<Koha::Contrib::ARK> object

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
