package Koha::Contrib::Tamil::RecordWriter::File::Iso2709;
$Koha::Contrib::Tamil::RecordWriter::File::Iso2709::VERSION = '0.052';
#ABSTRACT: ISO2709 MARC records writer
use Moose;

extends 'Koha::Contrib::Tamil::RecordWriter::File';

use Carp;
use MARC::Batch;
use MARC::Record;


sub BUILD {
    my $self = shift;

    #FIXME: Encore les joies de l'utf8 et du MARC
    #binmode( $self->fh, ':utf8' );
}


sub write {
    my ( $self, $record ) = @_;

    $self->SUPER::write();

    my $fh = $self->fh;
    print $fh $record->as_usmarc(); 
}

__PACKAGE__->meta->make_immutable;

1

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::RecordWriter::File::Iso2709 - ISO2709 MARC records writer

=head1 VERSION

version 0.052

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
