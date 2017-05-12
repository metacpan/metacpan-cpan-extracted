package JE::Object::Error::SyntaxError;

our $VERSION = '0.066';


use strict;
use warnings;

our @ISA = 'JE::Object::Error';

require JE::Object::Error;
require JE::String;


=head1 NAME

JE::Object::Error::SyntaxError - JavaScript SyntaxError object class

=head1 SYNOPSIS

  use JE::Object::Error::SyntaxError;

  # Somewhere in code called by an eval{}
  die new JE::Object::Error::SyntaxError $global, "(Error message here)";

  # Later:
  $@->prop('message');  # error message
  $@->prop('name');     # 'SyntaxError'
  "$@";                 # 'SyntaxError: ' plus the error message

=head1 DESCRIPTION

This class implements JavaScript SyntaxError objects for JE.

=head1 METHODS

See L<JE::Types> and L<JE::Object::Error>.

=cut

sub name { SyntaxError => }


return "a true value";

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object>

=item L<JE::Object::Error>

=back

=cut




