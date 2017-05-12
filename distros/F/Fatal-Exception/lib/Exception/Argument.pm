#!/usr/bin/perl -c

package Exception::Argument;

=head1 NAME

Exception::Argument - Thrown when called function or method with wrong argument

=head1 SYNOPSIS

  use Exception::Argument;

  sub method {
      my $self = shift;
      Exception::Argument->throw(
          message => 'Usage: $obj->method( STR )',
      ) if @_ < 1;
      my ($str) = @_;
      print $str;
  };

=head1 DESCRIPTION

This class is an L<Exception::Base> exception thrown when function or method
was called with wrong argument.

=for readme stop

=cut

use 5.006;
use strict;
use warnings;

our $VERSION = 0.05;


use Exception::Base 0.21 (
    'Exception::Argument' => {
        isa     => 'Exception::Died',
        message => 'Bad argument',
    },
);


1;


__END__

=begin umlwiki

= Class Diagram =

[             <<exception>>
            Exception::Argument
 -----------------------------------------
 +message : Str = "Bad argument" {rw, new}
 -----------------------------------------
                                          ]

[Exception::Argument] ---|> [Exception::Base]

=end umlwiki

=head1 BASE CLASSES

=over

=item *

L<Exception::Base>

=back

=head1 ATTRIBUTES

This class provides new attributes.  See L<Exception::Base> for other
descriptions.

=over

=item message : Str = "Bad argument" {rw}

Contains the message of the exception.  This class overrides the default value
from L<Exception::Base> class.

=back

=head1 SEE ALSO

L<Exception::Base>.

=head1 BUGS

If you find the bug, please report it.

=for readme continue

=head1 AUTHOR

Piotr Roszatycki E<lt>dexter@debian.orgE<gt>

=head1 LICENSE

Copyright (C) 2008 by Piotr Roszatycki E<lt>dexter@debian.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
