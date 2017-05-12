#!perl
use strict;
use warnings FATAL => 'all';
use Test::More;
use Math::BigFloat;

BEGIN {
    use_ok( 'MarpaX::Languages::ECMAScript::AST' ) || print "Bail out!\n";
    use_ok( 'MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics' ) || print "Bail out!\n";
}
our $impl = 'MyActions';

require File::Spec->catfile('inc', 'stringNumericLiteralDoTests.pl');

1;

#
# Example of externalized package where numbers are all Math::BigFloat objects.
#
package MyActions;
use Math::BigFloat;
use parent 'MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::StringNumericLiteral::NativeNumberSemantics';

#
# Precision nor accurracy being setted, default applied, i.e. up to 40 digits.
# Fair enough.

use constant {
  ACCURACY => 20,          # Number of significant digits
  ROUND_MODE => 'even'     # Round mode
};

sub new {
  my ($class, %opts) = @_;
  my $self = {_number => $opts{number}    // Math::BigFloat->new('0'),
              _length => $opts{length}    // 0,
              _decimal => $opts{decimal } // 0};
  bless($self, $class);
  return $self;
}

sub clone {
  my ($self) = @_;
  return (ref $self)->new(number => $self->{_number}->copy,
                          length => $self->{_length},
                          decimal => $self->{_decimal});
}

sub mul             { $_[0]->{_number}->bmul($_[1]->{_number});                                            return $_[0]; }
sub nan             { $_[0]->{_number}->bnan();                                                            return $_[0]; }
sub pos_one         { $_[0]->{_number}->bone();                                                            return $_[0]; }
sub neg_one         { $_[0]->{_number}->bone('-');                                                         return $_[0]; }
sub pos_zero        { $_[0]->{_number}->bzero();                                                           return $_[0]; }
sub pos_inf         { $_[0]->{_number}->binf();                                                            return $_[0]; }
sub pow             { $_[0]->{_number}->bpow($_[1]->{_number});                                            return $_[0]; }
sub int             { $_[0]->{_number} = Math::BigFloat->new("$_[1]"); $_[0]->{_length} = length("$_[1]"); return $_[0]; }
sub hex             { $_[0]->{_number} = Math::BigFloat->new(hex("$_[1]"));                                return $_[0]; }
sub neg             { $_[0]->{_number}->bneg();                                                            return $_[0]; }
sub abs             { $_[0]->{_number}->babs();                                                            return $_[0]; }
sub add             { $_[0]->{_number}->badd($_[1]->{_number});                                            return $_[0]; }
sub sub             { $_[0]->{_number}->bsub($_[1]->{_number});                                            return $_[0]; }
sub host_value      { $_[0]->{_number}->round(ACCURACY, undef, ROUND_MODE);                     return $_[0]->{_number}; }
