package Froody::Upload;
use strict;
use warnings;

use base 'Froody::Base';

__PACKAGE__->mk_accessors(qw( fh filename client_filename mime_type ));

=head1 NAME

Froody::Upload - wrapper class for uploaded data in Froody

=head1 SYNOPSIS

  # used internally

=head1 DESCRIPTION

This module represents uploads

=head2 Accessors

These are get/set accessors on the instance.

=over

=item fh

=item filename

=item client_filename

=item mime_type

=back

=head2 EASY CONSTRUCTOR

=over

=item from_file( filename )

=cut

sub from_file {
  my $class = shift;
  my $filename = shift;
  open my $fh, $filename or die "Can't open $filename: $!";
  return $class->new->fh($fh)->filename($filename);
}

=back

=head1 BUGS

None known.

Please report any bugs you find via the CPAN RT system.
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Froody>

=head1 AUTHOR

Copyright Fotango 2005.  All rights reserved.

Please see the main L<Froody> documentation for details of who has worked
on this project.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Froody>, L<Froody::Request::Apache>, L<Froody::Request::CGI>, L<Froody::XML>

=cut

1;