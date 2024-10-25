package Koha::Contrib::ARK::Update;
# ABSTRACT: Update Koha ARK fields
$Koha::Contrib::ARK::Update::VERSION = '1.1.2';
use Moose;
use Modern::Perl;

with 'Koha::Contrib::ARK::Action';


sub action {
    my $self = shift;
    my $ark = $self->ark;
    my $current = $ark->current;
    my $biblio = $current->{biblio};
    my $record = $biblio->{record};

    my $a = $self->ark->c->{ark};
    my $ark_value = $current->{ark};
    my $kfield = $a->{koha}->{ark};
    if ( $kfield->{letter} ) { # datafield
        if ( my $field = $record->field($kfield->{tag}) ) {
            my @subf = grep {
                my $keep = $_->[0] ne $kfield->{letter};
                $self->ark->what_append('remove_existing') unless $keep;
                $keep;
            } @{$field->subf};
            push @subf, [ $kfield->{letter} => $ark_value ];
            $field->subf( \@subf );
        }
        else {
            $record->append( MARC::Moose::Field::Std->new(
                tag => $kfield->{tag}, subf => [ [ $kfield->{letter} => $ark_value ] ] ) );
        }
    }
    else {
        if ( $record->field($kfield->{tag}) ) {
            $record->delete($kfield->{tag});
            $self->ark->what_append('remove_existing');
        }
        $record->append( MARC::Moose::Field::Control->new(
            tag => $kfield->{tag}, value => $ark_value ) );
    }
    $self->ark->what_append('add');
    $self->ark->current_modified();
}


__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::ARK::Update - Update Koha ARK fields

=head1 VERSION

version 1.1.2

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
