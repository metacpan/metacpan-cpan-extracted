package Koha::Contrib::Tamil::Authority::EditorsUpdater;
$Koha::Contrib::Tamil::Authority::EditorsUpdater::VERSION = '0.062';
use Moose;

extends 'AnyEvent::Processor';

use C4::AuthoritiesMarc;

has verbose => ( is => 'rw', isa => 'Bool' );

has doit => ( is => 'rw', isa => 'Bool' );

has koha => ( is => 'rw', isa => 'Koha::Contrib::Tamil::Koha' );

has editor_from_isbn => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

has isbns => ( is => 'rw', isa => 'ArrayRef' );


before 'run' => sub {
    my ($self, $delete) = @_;

    if ( $delete && $self->doit ) {
        print "Deleting EDITORS\n";
        $self->koha->dbh->do("delete from auth_header where authtypecode='EDITORS'");
    }
    my @isbns = sort keys %{$self->editor_from_isbn};
    $self->isbns( \@isbns );

    $self->SUPER::run();
};


override 'process' => sub {
    my $self = shift;

    return 0  if $self->count == @{$self->isbns};

    my $isbn = $self->isbns->[$self->count];
    $self->count( $self->count + 1 );
    my ($name, $collections) = @{ $self->editor_from_isbn->{$isbn} };
    my @sf = ();
    push @sf, 'a', $isbn, 'b', $name;
    foreach my $collection (sort keys %$collections) {
        push @sf, 'c', $collection;
    }
    my $authority = MARC::Record->new();
    $authority->append_fields( MARC::Field->new( 200, '', '', @sf ) );
    AddAuthority( $authority, 0, 'EDITORS' ) if $self->doit;
    #print $authority->as_formatted(), "\n" if $self->verbose;
    return 1;
};


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Authority::EditorsUpdater

=head1 VERSION

version 0.062

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
