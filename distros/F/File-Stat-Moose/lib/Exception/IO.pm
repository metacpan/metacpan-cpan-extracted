#!/usr/bin/perl -c

package Exception::IO;

=head1 NAME

Exception::IO - Thrown when IO operation failed

=head1 SYNOPSIS

  use warnings FATAL => 'all';
  use Exception::Fatal;
  use Exception::IO;

  my $status = eval {
      open my $fh, '/etc/passwd', '+badmode';
  };
  if ($@ or not defined $status) {
      my $e = $@ ? Exception::Fatal->catch : Exception::IO->new;
      $e->throw( message => 'Cannot open' );
  };

=head1 DESCRIPTION

This class is an L<Exception::System> exception thrown when IO operation
failed.

=for readme stop

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = '0.06';


use Exception::Base 0.21 (
    'Exception::IO' => {
        isa       => 'Exception::System',
        message   => 'Unknown IO exception',
    },
);


1;


__END__

=begin umlwiki

= Class Diagram =

[                   <<exception>>
                    Exception::IO
 -------------------------------------------------
 +message : Str = "Unknown IO exception" {rw, new}
 -------------------------------------------------
                                                  ]

[Exception::IO] ---|> [Exception::System]

=end umlwiki

=head1 INHERITANCE

=head2 Extends

=over

=item *

L<Exception::System>

=back

=head1 ATTRIBUTES

This class provides new attributes.  See L<Exception::Base> for other
descriptions.

=over

=item message : Str = "Unknown IO exception" {rw}

Contains the message of the exception.  This class overrides the default value
from L<Exception::Base> class.

=back

=head1 SEE ALSO

L<Exception::System>, L<Exception::Base>.

=head1 BUGS

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (C) 2008, 2009 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
