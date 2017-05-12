package JE::Undefined;

our $VERSION = '0.066';

use strict;
use warnings;

use overload fallback => 1,
	'""' => 'typeof',
#	 cmp =>  sub { "$_[0]" cmp $_[1] },
	bool => \&value,
	'0+' =>  sub { sin 9**9**9 };

# ~~~ How should this numify?

require JE::String;
require JE::Boolean;


=head1 NAME

JE::Undefined - JavaScript undefined value

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $js_undefined = $j->undef;

  $js_undefined->value; # undef

=head1 DESCRIPTION

This class implements the JavaScript "undefined" type. There really
isn't much to it.

Undefined stringifies to 'undefined', and is false as a boolean.

=cut

# A JE::Undefined object is a reference to a global object.

sub new    { bless \do{my $thing = $_[1]}, $_[0] }
sub value  { undef }
*TO_JSON=*value;
sub typeof { 'undefined' }
sub id     { 'undef' }
sub primitive { 1 }
sub to_primitive { $_[0] }
sub to_boolean   { JE::Boolean->new(${+shift}, 0) }
sub to_string { JE::String->_new(${+shift}, 'undefined') };
sub to_number { JE::Number->new(${+shift}, 'NaN') }
sub global { ${$_[0]} }

return "undef";
__END__

=head1 SEE ALSO

=over 4

=item JE::Types

=item JE::Null

=item JE

=back
