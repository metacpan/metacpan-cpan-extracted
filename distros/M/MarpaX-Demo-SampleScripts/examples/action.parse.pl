#!env perl -w
use Marpa::R2;
use Data::Section -setup;

our $MOD_GRAMMAR   = Marpa::R2::Scanless::G->new({source => __PACKAGE__->section_data('MOD_GRAMMAR')});
our $MOD_SEMANTICS = { semantics_package => 'Tautology::Mod::Actions' };
our $INPUTS        = ${__PACKAGE__->section_data('INPUTS')};

# ========== Grammars Semantics ============

package Tautology::Mod::Actions;

sub new { bless($Tautology::Mod::SELF, __PACKAGE__) }
sub _N  { my ($self, $x)     = @_; ${$self->{grammar}->parse(                \"~${x}", $self->{semantics})} }
sub _C  { my ($self, $x, $y) = @_; ${$self->{grammar}->parse(         \"NDN${x}N${y}", $self->{semantics})} }
sub _D  { my ($self, $x, $y) = @_; ${$self->{grammar}->parse(           \"V${x}${y};", $self->{semantics})} }
sub _I  { my ($self, $x, $y) = @_; ${$self->{grammar}->parse(           \"DN${x}${y}", $self->{semantics})} }
sub _E  { my ($self, $x, $y) = @_; ${$self->{grammar}->parse(\"DC${x}${y}CN${x}N${y}", $self->{semantics})} }
sub _ok { my  $self = shift;       join('', @_);                                                            }

# ================= Main ===================

package main;

local $Tautology::Mod::SELF = { grammar => $MOD_GRAMMAR, semantics => $MOD_SEMANTICS };

foreach (split(/\R/, $INPUTS)) {
  print "ORIG: $_\n";
  my $mod = ${$MOD_GRAMMAR->parse(\$_, $MOD_SEMANTICS)};
  print "MOD : $mod\n";
}

__DATA__
__[ MOD_GRAMMAR ]__
#
# Grammar to modify the input
#
expression ::= ('N') expression                 action => _N      # NOT x
             | ('C') expression expression      action => _C      # x AND y
             | ('D') expression expression      action => _D      # x OR y
             | ('I') expression expression      action => _I      # x IMPLIES y
             | ('E') expression expression      action => _E      # x EQUALS y
             |  '~'  expression                 action => _ok     # pass through
             |  'V'  expression expression ';'  action => _ok     # pass through
             | [a-z]                            action => ::first # variable
__[ VAL ]__
#
# Grammar to evaluate modified input
#
__[ INPUTS ]__
IIpqDpNp
NCNpp
Iaz
NNNNNNNp
IIqrIIpqIpr
Ipp
Ezz
