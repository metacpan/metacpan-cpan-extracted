package MIME::Multipart::Parse::Ordered;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;

=head1 NAME

MIME::Multipart::Parse::Ordered - simple mime multipart parser, maintains document order

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

This is a really basic MIME multipart parser, 
and the only reason for its existence is that
I could not find an existing parser that would
give me the parts directly (not on fs) and also
give me the order.

	my $mmps = MIME::Multipart::Parse::Ordered->new();
	my $listref = $mmps->parse($my_file_handle);
	print $listref->[0]->{"Preamble"};
	print $listref->[0]->{"Content-Type.params"}->{"boundary"};
	foreach (@$listref){
		print $_->{"Body"} 
		  if $_->{"Content-Type"} eq 'text/plain';
	}

=head1 SUBROUTINES/METHODS

=head2 new

Created a new MIME::Multipart::Parse::Ordered

=cut

sub new {
  my $p = shift;
  my $c = ref($p) || $p;
  my $o = {};
  bless $o, $c;
  return $o;
}

=head2 parse

takes one argument: a file handle.

returns a listref, each item corresponding to a MIME header in
the document.  The first is the multipart file header itself.
Each header item is stored as key/value.  Additional parameters
are stored $key.params.  e.g. the boundary is at

    $o->[0]->{"Content-Type.params"}->{"boundary"}

The first item may also have {"Preamble"} and {"Epilog"} if these
existed in the file.

The content of each part is stored as {"Body"}.

=cut

sub parse {
  # load a MIME-multipart-style file containing at least one application/x-ptk.markdown
  my ($o,$fh) = @_;
  $o->{fh} = $fh;

  my $mp1 = <$fh>;
  my $mp1e = 'MIME Version: 1.0';
  die "Multipart header line 1 must begin ``$mp1e'' " unless $mp1 =~ /^$mp1e/;
 
  my $general_header = $o->parseHeader();
  croak "no boundary defined" unless $general_header->{"Content-Type.params"}->{"boundary"};
  $o->{boundary} = $general_header->{"Content-Type.params"}->{"boundary"};
  
  $general_header->{Preamble} = $o->parseBody();

  my @parts = ($general_header);

  while(! (eof($fh) || $o->{eof})){
    my $header = $o->parseHeader();
    $header->{Body} = $o->parseBody();
    push @parts, $header;
  }

  $general_header->{Epilog} = $o->parseBody();

  return \@parts;

}

=head2 parseBody

Used internally, parses mime "body"

=cut

sub parseBody {
  my ($o) = @_;
  my $fh = $o->{fh};
  my $body = '';
  my $boundary = $o->{boundary};
  while(<$fh>){
    $o->{eof} = 1 if /^--$boundary--/;
    last if /^--$boundary/;
    $body .= $_;
  }
  return $body;
}

=head2 parseHeader

Used internally, parses a MIME header.

=cut

sub parseHeader {
  my ($o) = @_;
  my $fh = $o->{fh};
  my %header = ();
  my ($k,$v,$e,$p);
  while(<$fh>){
    last if /^\s*$/; # break on a blank line...
    my @parts = split /;/;
    if(/^\S/){ # non space at start means a new header item
      my $header = shift @parts;
      ($k,$v) = split(/\:/, $header, 2);
      $k =~ s/(?:^\s+|\s+$)//g;
      $v =~ s/(?:^\s+|\s+$)//g;
      $header{$k} = $v;
      $p = $k.'.params';
      $header{$p} = {};
    }
    foreach my $part(@parts){
      my ($l,$w) = split(/=/, $part, 2);
      $l =~ s/(?:^\s+|\s+$)//g;
      $w =~ s/(?:^\s+|\s+$)//g;
      $header{$p}->{$l} = $w;
    }
  }
  return \%header;
}

=head1 AUTHOR

jimi, C<< <jimi at webu.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-mime-multipart-parse-ordered at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MIME-Multipart-Parse-Ordered>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MIME::Multipart::Parse::Ordered


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MIME-Multipart-Parse-Ordered>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MIME-Multipart-Parse-Ordered>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MIME-Multipart-Parse-Ordered>

=item * Search CPAN

L<http://search.cpan.org/dist/MIME-Multipart-Parse-Ordered/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 jimi.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of MIME::Multipart::ParseSimple
