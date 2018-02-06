package HTML::DOM::NamedNodeMap;

use strict;
use warnings;

use HTML::DOM::Exception qw'NOT_FOUND_ERR';
use HTML::DOM::_FieldHash;
use Scalar::Util 'weaken';

our $VERSION = '0.058';

fieldhashes \my(%a, %h);

use overload fallback => 1,
	'@{}' => sub {
		my $self = ${+shift};
		$a{$self} ||= do {
			my $t = [];
			tie @$t, __PACKAGE__."'_atie", $self;
			$t
		};
	 },
	'%{}' => sub {
		my $self = ${+shift};
		$h{$self} ||= do {
			my $t = {};
			tie %$t, __PACKAGE__."'_htie", $self;
			$t
		};
	 };


# This object stores nothing more than the Element object whose attributes
# it purports to hold.
sub new { # [0] class  [1] element obj
	my $map = bless \(my $elem = $_[1]), shift;
	weaken $$map;
	$map;
}

sub getNamedItem {
	${+shift}->getAttributeNode(shift);
}

sub setNamedItem {
	${+shift}->setAttributeNode(shift);
}

sub removeNamedItem {
	# The spec contradicts itself slightly.  It says that null  is
	# returned if no node with such a name exists, but then it says
	# that a NOT_FOUND_ERR is thrown if no node  with  such  a name
	# exists. I can't do both.
	my($elem,$name) = (${+shift},shift);
	my $attr = $elem->attr($name);
	defined $attr or die HTML::DOM::Exception->new(NOT_FOUND_ERR,
		"No attribute named $name exists");
	if(ref $attr) {
		$elem->attr($name, undef);
		$attr->_element(undef);
		return $attr
	}
	else {
		my $new_attr = HTML::DOM::Attr->new($name);
		$new_attr->_set_ownerDocument($elem->ownerDocument);
		$new_attr->value($attr);
		return $new_attr;
	}
}

sub item {
	my $elem = ${+shift};
	my $name = (sort $elem->all_external_attr_names)[shift];
	defined $name or return;
	$elem->getAttributeNode($name);
}

sub length {
	scalar(() = ${$_[0]}-> all_external_attr_names);
}

package HTML::DOM::NamedNodeMap::_atie;

our @ISA = "Tie::Array";

sub TIEARRAY {
    require Tie::Array;
    goto &HTML::DOM'NamedNodeMap'new;
}

*FETCH = *HTML::DOM::NamedNodeMap::item;
*FETCHSIZE = *HTML::DOM::NamedNodeMap::length;
sub EXISTS { $_[1] >=0 && $_[1] < &FETCHSIZE }

package HTML::DOM::NamedNodeMap::_htie;

our @ISA = "Tie::Hash";

sub TIEHASH {
    require Tie::Hash;
    goto &HTML::DOM'NamedNodeMap'new;
}
*STORE = *HTML'DOM'NamedNodeMap'setNamedItem;
*FETCH = *HTML'DOM'NamedNodeMap'getNamedItem;

sub FIRSTKEY {
    # reset iterator; I don’t *think* any other code uses it.
    keys %${$_[0]};
    goto &NEXTKEY;
}
sub NEXTKEY {
    my $elem = ${+shift};
    while (defined($_ = each %$elem)) {
     return $_ unless /^_/;
    }
    return undef;
}
sub EXISTS {
	my($elem,$name) = (${+shift},shift);
	defined $elem->attr($name);
}
sub DELETE {
 my($elem,$name) = (${+shift},shift);
 $elem->attr($name, undef);
}
sub CLEAR {
 my $elem = ${+shift};
 $elem->attr($_,undef) for $elem->all_external_attr_names;
}
*SCALAR = *HTML::DOM::NamedNodeMap::length;

1