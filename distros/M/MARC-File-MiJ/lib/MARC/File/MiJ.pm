package MARC::File::MiJ;

use 5.006;
use strict;
use warnings FATAL => 'all';

use MARC::Record::MiJ;
use base qw(MARC::File);

=head1 NAME

MARC::File::MiJ - Read newline-delimited marc-in-json files

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

Use by itself or with MARC::Batch

    use MARC::Batch;
    use MARC::File::MiJ;

    my $reader = new MARC::Batch('MiJ', $jsonfilename);
    while (my $r = $batch->next) { ... }

    # or, use it without MARC::Batch
    my $reader = MARC::File::MiJ->in($jsonfilename);
    
=head1 DESCRIPTION

A subclass of MARC::File for reading MARC records encoded as newline-delimited marc-in-json,
as supported by pymarc/ruby-marc/marc4j and
described at http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/.



=head1 SUBROUTINES/METHODS


=head2 _next()

The underlying "next" that pulls the next line from the filehandle;

=cut

sub _next {
  my $self = shift;
  my $fh = $self->{fh};
  return if eof($fh);
  local $/ = "\n";
  my $rec = <$fh>;
  return $rec;
}



=head2 decode(json)

=cut

sub decode {
  my $self = shift;
  my $str = shift;
  return MARC::Record::MiJ->new($str);
}


=head2 encode

=cut

sub encode {
  my $marc = shift;
  $marc = shift if (ref($marc)||$marc) =~ /^MARC::File/;
  return MARC::Record::MiJ->to_mij($marc);
}


=head1 AUTHOR

Bill Dueber, C<< <dueberb at umich.edu> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-MARC-File-MiJ at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MARC-File-MiJ>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MARC::File::MiJ


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MARC-File-MiJ>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MARC-File-MiJ>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MARC-File-MiJ>

=item * Search CPAN

L<http://search.cpan.org/dist/MARC-File-MiJ/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Bill Dueber.

This software is free software and may be distributed under the same
terms as Perl itself.


=cut

1; # End of MARC::File::MiJ
