use 5.014;
use strict;
use warnings;

package Kavorka::TraitFor::Parameter::locked;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.039';

use Moo::Role;

use Hash::Util;
use Types::Standard qw(Dict);

around _injection_assignment => sub
{
	my $next = shift;
	my $self = shift;
	my ($sig, $var, $val) = @_;
	
	my $str = $self->$next(@_);
	
	state $_FIND_KEYS = sub {
		return unless $_[0];
		my ($dict) = grep {
			$_->is_parameterized
			and $_->has_parent
			and $_->parent->strictly_equals(Dict)
		} $_[0], $_[0]->parents;
		return unless $dict;
		return if ref($dict->parameters->[-1]) eq q(HASH);
		my @keys = sort keys %{ +{ @{ $dict->parameters } } };
		return unless @keys;
		\@keys;
	};
	
	my $legal_keys  = $_FIND_KEYS->($self->type);
	my $quoted_keys = $legal_keys ? join(q[,], q[], map B::perlstring($_), @$legal_keys) : '';
	my $ref_var     = $self->sigil eq '$' ? $var : "\\$var";
	
	$str .= "&Hash::Util::unlock_hash($ref_var);";
	$str .= "&Hash::Util::lock_keys($ref_var $quoted_keys);";
	
	return $str;
};

1;
