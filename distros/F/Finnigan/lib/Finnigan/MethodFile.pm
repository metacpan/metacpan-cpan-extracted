package Finnigan::MethodFile;

use strict;
use warnings FATAL => qw( all );
our $VERSION = 0.0206;

use Finnigan;
use base 'Finnigan::Decoder';


sub decode {
  my ($class, $stream, $version) = @_;

  my @fields = (
                "header"      => ['object', 'Finnigan::FileHeader'],
                "file size"        => ['V',      'UInt32'],
                "orig file name"   => ['varstr', 'PascalStringWin32'],
                "n"                => ['V',      'UInt32'],
               );

  my $self = Finnigan::Decoder->read($stream, \@fields, $version);
  bless $self, $class;

  if ( $self->n ) { # this is a hack, because I don't have an iterate_hash() method
    # the tags come in pairs, so retreive them later with a method
    $self->iterate_scalar($stream, 2*$self->n, "name trans" => ['varstr', 'PascalStringWin32']);
  }

  $self->SUPER::decode($stream, ["container" => ['object', 'Finnigan::OLE2File']]);

  return $self;
}

sub n {
  shift->{data}->{n}->{value};
}

sub file_size {
  shift->{data}->{"file size"}->{value};
}

sub container {
  shift->{data}->{"container"}->{value};
}

sub header {
  shift->{data}->{"header"}->{value};
}

sub translation_table {
  shift->{data}->{"name trans"}->{value};
}

sub instrument_name {
  my ($self, $i) = @_;
  my $n = $self->n;
  die "instrument index cannot be 0" if $i == 0;
  die "instrument index cannot be greater than $n" if $i > $n;
  $i--;
  return @{$self->translation_table}[2*$i .. 2*$i + 1];
}

1;
__END__

=head1 NAME

Finnigan::MethodFile -- a decoder for the outer MethodFile container

=head1 SYNOPSIS

  use Finnigan;

  my $mf = Finnigan::MethodFile->decode(\*INPUT);
  say $mf->header->version;
  say $mf->container->size;
  my $dirent = $mf->container->find($path);

=head1 DESCRIPTION

This object decodes the outer container for a Windows OLE2 directory
which in turn contains a set of method files for various instruments,
both in binary and text representations.

The outer container also contains a name translation table mapping the
names of the instruments into the names used inside the method files.


=head2 METHODS

=over 4

=item decode($stream)

The constructor method

=item header

Get the Finnigan::FileHeader object attached to the method file

=item n

Get the number of entries in the name translation table

=item translation_table

Get the name translation table

=item instrument_name($i)

Get the translation at index $i in the name translation table

=item file_size

Get the size of the Finnigan::OLE2File container

=item container

Get the Finnigan::OLE2File object


=back

=head1 SEE ALSO

Finnigan::OLE2File

L<uf-meth>

=head1 AUTHOR

Gene Selkov, E<lt>selkovjr@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Gene Selkov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
