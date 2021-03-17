package Iterator::Records::Lines;

use 5.006;
use strict;
use warnings;
use parent 'Iterator::Records';
use Data::Dumper;

=head1 NAME

Iterator::Records::Lines - Provides simple record iterators for reading text line by line

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This module specializes L<Iterator::Records> to provide record iterators returning one line at a time from either a file or a string containing text.
The iterator can optionally keep track of text indentation. All line record iterators return the columns (type, lno, indent, len, text); the type is either
"line" or "blank". if indentation is not being tracked ("raw input") then the type is always "line", the indent is always 0, and trailing space will not be stripped
from the text. (The primary use I have for the line reader is as a pre-tokenizer for parsing input.)

=head1 new (input_type, input_source, raw)

Creates an iterator factory. The C<input_type> is either 'file' or 'string', and the source is then either the filename or the string. The string can be a reference to a string.
By default, the input line is cleaned up and its non-blank 

=cut

sub new {
   my $class = shift;

   my $self = bless ({}, $class);
   $self->{input_type} = shift;
   
   if (ref ($self->{input_type}) eq 'CODE') {
      # This is a transmogrification of a line iterator, so keep the class intact but initialize like a vanilla itrecs.
      # Transmogrification creates a new itrecs of the parent's class because the parent might have custom transmogrifiers. (See thread on 2019-02-23.)
      $self->{gen} = $self->{input_type};
      $self->{f} = shift;
      $self->{id} = '*';
      return $self;
   }
   
   # Else this is an initial line iterator and we know our fields.
   $self->{f} = ['type', 'lno', 'indent', 'len', 'text'];
   $self->{id} = '*';
   my $input = shift;
   $self->{input_source} = $input;
   $self->{input_source} = \$input if $self->{input_type} eq 'string' and not ref $input;
   my $raw = shift;
   
   $self->{gen} = sub {
      my $done = 0;
      open my $fh, '<', $self->{input_source} or $done = 1;
      if ($done) {
         $self->{file_error} = $!;
      }
      my $lno = 0;
      sub {
         return undef if $done;
         
         $lno += 1;
         my $line = <$fh>;
         if (not $line) {
            $done = 1;
            return undef;
         }
         $line =~ s/[\r\n]*$//;
         return ['line', $lno, 0, length($line), $line] if $raw;
         
         $line =~ s/(\s+)$//;
         return ['blank', $lno, 0, 0, ''] unless length($line);
         
         if ($line =~ /^(\s+)(.*)/) {
            return ['line', $lno, length($1), length($2), $2];
         }
         
         return ['line', $lno, 0, length($line), $line];
      }
   };
   $self;
}


=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-iterator-records-lines at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Iterator-Records-Lines>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Iterator::Records::Lines


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Iterator-Records-Lines>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Iterator-Records-Lines>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Iterator-Records-Lines>

=item * Search CPAN

L<http://search.cpan.org/dist/Iterator-Records-Lines/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2021 Michael Roberts.

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

1; # End of Iterator::Records::Lines
