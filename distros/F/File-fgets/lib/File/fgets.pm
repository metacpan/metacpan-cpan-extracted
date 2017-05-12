package File::fgets;

use strict;
use warnings;

use version; our $VERSION = qv("v0.0.4");

use XSLoader;
XSLoader::load __PACKAGE__, $VERSION;

use base qw(Exporter);
our @EXPORT = qw(fgets);

use Carp;


=head1 NAME

File::fgets - Read either one line or X characters from a file

=head1 SYNOPSIS

  use File::fgets;

  open my $fh, $file;

  # Read either one line or the first 10 characters, which ever comes first
  my $line = fgets($fh, 10);

=head1 DESCRIPTION

An implementation of the C fgets() function.

=head3 fgets

    my $string = fgets($fh, $limit);

Reads either one line or at most $limit bytes from the $fh.

Returns undef at end of file.

NOTE: unlike C's fgets, this will read $limit characters not $limit -
1.  Perl doesn't have to leave room for a null byte.

=cut

sub fgets {
    my($fh, $limit) = @_;

    croak "Invalid filehandle supplied to fgets()" unless defined $fh;
    croak "No limit supplied to fgets()" unless defined $limit;
    croak "fgets() on closed filehandle" if do { tell($fh) == -1; };
    return if eof $fh;

    # fgets() is often buggy, returning garbage or silently reading
    # one character.  Let's just not get it involved.
    return "" if $limit == 0;

    my $fd = eval { fileno($fh) };
    my $has_fd = $fd && $fd != -1;
    return $has_fd ? xs_fgets($fh, $limit) : perl_fgets($fh, $limit);
}

# For dealing with filehandles that aren't real file descriptors
sub perl_fgets {
    my($fh, $limit) = @_;

    my $char;    # avoid reallocating it every iteration
    my $str = '';
    for(1..$limit) {
        $char = getc $fh;
        last unless defined $char;
        $str .= $char;
        last if $char eq "\n";
    }

    return $str;
}

1;

=head1 EXAMPLE

The following example demonstrates using fgets() to read in at most 5
characters at a time.

  use File::fgets;

  open my $write_fh, ">", $file;
  print $write_fh <<END;
  this is
  an example
  of use
  END
  close $write_fh;

  open my $fh, "<", $file;
  while( my $string = fgets($fh, 5) ) {
      $string =~ s{\n}{\\n};  # make newlines show up
      print "--$string--\n";
  }

The result will be:

  --this --
  --is\n--
  --an ex--
  --ample--
  --\n--
  --of us--
  --e\n--


=head1 NOTES

This is implemented as a wrapper around the C fgets() function and is
extremely efficient UNLESS the filehandle does not have an underlying
fileno.  For example, if its given a tied filehandle.  Then it falls
back to a Perl implementation.

=head1 LICENSE

Copyright 2010 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

Send bugs, feedback, ideas and suggestions via
L<https://rt.cpan.org/Public/Dist/Display.html?Name=File-fgets> or
E<lt>bugs-File-fgets@rt.cpan.orgE<gt>

The latest version of this software can be found at L<http://github.com/schwern/File-fgets>

=head1 SEE ALSO

L<File::GetLineMaxLength>

=cut
