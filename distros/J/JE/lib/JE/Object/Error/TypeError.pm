package JE::Object::Error::TypeError;

our $VERSION = '0.066';


use strict;
use warnings;

our @ISA = 'JE::Object::Error';

require JE::Object::Error;
require JE::String;


=head1 NAME

JE::Object::Error::TypeError - JavaScript TypeError object class

=head1 SYNOPSIS

  use JE::Object::Error::TypeError;

  # Somewhere in code called by an eval{}
  die new JE::Object::Error::TypeError $global, "(Error message here)";

  # Later:
  $@->prop('message');  # error message
  $@->prop('name');     # 'TypeError'
  "$@";                 # 'TypeError: ' plus the error message

=head1 DESCRIPTION

This class implements JavaScript TypeError objects for JE.

=head1 METHODS

See L<JE::Types> and L<JE::Object::Error>.

=cut

sub name { 'TypeError' }


return "a true value";

=head1 SEE ALSO

=over 4

=item L<JE>

=item L<JE::Types>

=item L<JE::Object>

=item L<JE::Object::Error>

=back

=cut




