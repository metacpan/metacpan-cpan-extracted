use strict;
use warnings;
package File::Macro;

use Exporter qw(import);

=head1 NAME

File::Macro - Read a file within a block scope

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
our @EXPORT = qw( with_file );

=head1 SYNOPSIS

This module exists exclusively to provide a shorthand for the C<open... or die>
idiom. Instead of repeating the same boilerplate, you simply call C<with_file>
and do whatever you need to do with your file inside the block, which is
already opened for you in C<$_>.

    use File::Macro;
    with_file 'foo.csv' => '<' => sub {
        say <$_>;
    };

If you want to use a different variable for the filehandle, just specify it
after the mode selector, like so:

    my $fh;
    with_file 'foo.csv' => '<' => \$fh => sub {
        say <$fh>;
    };

=head1 EXPORT

Exports only C<with_file>.

=head1 SUBROUTINES/METHODS

=head2 with_file $file_name => [ $file_mode => ] sub { }

 Opens file C<$file_name> in mode C<$file_mode> for reading, assigns the
 filehandle to C<$_>. Once the function in the second argument is complete,
 perl closes the filehandle automatically.

 The C<$file_mode> defaults to C<< < >>, that is to say, reading.

 You can also pass in a reference to your own file handle as follows:

  with_file( 't/01-base.t', '<', \$my_fh, sub {
    say <$my_fh>;
  } );

=cut

sub with_file {
  my ( $file_name, $file_mode, $file_handle, $coderef );
  if ( @_ == 3 ) {
    ( $file_name, $file_mode, $coderef ) = @_;
  }
  else {
    ( $file_name, $file_mode, $file_handle, $coderef ) = @_;
  }

  if ( $file_handle ) {
    my $save = $$file_handle;
    $$file_handle = undef;
    open $$file_handle, $file_mode, $file_name or
      die "Could not open '$file_name' in '$file_mode' mode: $@";
    $coderef->();
    close $_;
    $$file_handle = $save;
  }
  else {
    open local $_, $file_mode, $file_name or
      die "Could not open '$file_name' in '$file_mode' mode: $@";
    $coderef->();
    close $_;
  }
}

=head1 AUTHOR

Jeff Goff, C<< <jgoff at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-macro at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Macro>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Macro

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Macro>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Macro>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Macro>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Macro/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Jeff Goff.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
