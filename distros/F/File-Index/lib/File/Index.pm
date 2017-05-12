package File::Index;
use strict;
use warnings;

use Exporter ();
use Carp qw(croak);
use vars qw($VERSION @ISA @EXPORT);

$VERSION = "0.06";
@ISA = qw(Exporter);
@EXPORT = qw(indexf rindexf);

sub indexf {
  my $filehandle=shift;
  my $substring=shift;
  my $start=shift||0;
  my $bufferSize=shift||131072;
  my $k=length($substring);
  my $offset=0;
  my $s="";
  croak "BufferSize must not be less than substring length"
    if $bufferSize<$k;
  # Seek to start point; use successive reads if file isn't seekable 
  if ( ! seek($filehandle,$start,0) ) {
    for (my $j=0;$j<int($start/$bufferSize);$j++) {
      read($filehandle,$s,$bufferSize) or return(-1)
    }
    if ( $start%($bufferSize) > 0 ) {
      read($filehandle,$s,$start%($bufferSize)) or return(-1)
    }
    $s=""
  }
  # Read and append to end of preserved string
  while ( read($filehandle,substr($s,length($s)),$bufferSize) > 0 ) {
    if ( (my $n=index($s,$substring)) > -1 ) { return($n+$offset+$start) }
    $offset+=(length($s)-$k+1);
    # Preserve last ($k-1) characters
    $s=substr($s,-$k+1)
  }
  return(-1)
}

sub rindexf {
  my $filehandle=shift;
  my $substring=shift;
  my $beg=shift||-1;
  my $bufferSize=shift||131072;
  my $k=length($substring);
  my $offset=0;
  my $s="";
  my $match=-1;
  croak "BufferSize must not be less than substring length" if $bufferSize<$k;
  seek($filehandle,0,0);
  while (read($filehandle,substr($s,length($s)),$bufferSize)) {
    # Read and append to end of preserved string
    my $j=0;
    while ( (my $n=index($s,$substring,$j)) > -1 ) {
      if ( ($beg>=0) && (($n+$offset)>$beg) ) { return($match) }
      else { $match=$n+$offset; $j=$n+1 }
    }
    $offset+=(length($s)-$k+1);
    # Preserve last ($k-1) characters
    $s=substr($s,-$k+1)
  }
  # Return last match-position
  return($match)
}

=head1 NAME

File::Index - an index function for files

=head1 SYNOPSIS

  use File::Index;
  open(FILE,$myfile);
  my $pos=indexf(*FILE,"Foo");
  print "Foo found at position: $pos\n" if $pos > -1;
  open(FILE2,$myfile2);
  my $pos2=rindexf(*FILE2,"Bar");
  print "Bar found at position: $pos2\n" if $pos2 > -1;

=head1 DESCRIPTION

This module provides the indexf and rindexf functions which operate on files in the
same way that the index and rindex functions operate on strings. It can be used where
memory limitations prohibit the slurping of an entire file.

=over 4

=item C<indexf( *FH, $string, [$start], [$buffersize] )>

Starts at the position specified by '$start' (or at the beginning) of
the file associated with filehandle 'FH', and returns the absolute start
position of the string '$string'.
The buffer-size can be adjusted by specifying '$buffersize'.

=item C<rindexf( *FH, $string, [$position], [$buffersize] )>

Returns the position of the last occurrence of '$string' in the file
associated with filehandle 'FH'. If '$position' is specified, returns
the last occurrence beginning at or before '$position'.

The buffer-size can be adjusted by specifying '$buffersize'. If you
wish to specify a '$buffersize' value without specifying a '$position'
value, use a negative value (e.g. '-1') for the latter.


=back

=head1 AUTHOR

Graham Jenkins, C<< <grahjenk at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-index at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Index>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Index


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Index>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Index>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Index>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Index/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Graham Jenkins.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of File::Index
