package Koha::Contrib::Sudoc::PPNize::Reader;
# ABSTRACT: Reader du fichier ABES d'équivalence PPN biblionumber
$Koha::Contrib::Sudoc::PPNize::Reader::VERSION = '2.31';
use Moose;

with 'MooseX::RW::Reader::File';


sub read {
    my $self = shift;

    my $fh = $self->fh;
    
    my $line = <$fh>;
    return 0 unless $line;

    chop $line;
    my ($ppn, $biblionumber) = $line =~ /PPN (.*) : (.*)/;
    return { ppn => $ppn, biblionumber => $biblionumber };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Sudoc::PPNize::Reader - Reader du fichier ABES d'Ã©quivalence PPN biblionumber

=head1 VERSION

version 2.31

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Fréderic Demians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
