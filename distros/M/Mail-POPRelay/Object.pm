package Mail::Object;

use strict;
use Data::Dumper;
use vars qw[$AUTOLOAD $VERSION ];

$VERSION = '0.0.2';

# This is the base object class for all objects.

# ---------
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = { };
	bless($self, $class);
	return $self->init(@_);
}


# ---------
sub init {
	my $self = shift;
	foreach (@_) { @{%{$self}}{keys %{$_}} = values %{$_}; }
	return $self;
}


# ---------
sub copy {
	my $self = shift;
	return $self->deserialize();
}


# ---------
sub description {
	my $dataDumper = Data::Dumper->new([+shift, ]);
	$dataDumper->Purity(1)->Deepcopy(1)->Terse(1)->Indent(1);
	return $dataDumper->Dump();
}


# ---------
sub serialize {
	my $proto    = shift;
	my $anObject = ref($proto)
		? $proto
		: shift;

	my $dataDumper = Data::Dumper->new([$anObject, ]);
	$dataDumper->Purity(1)->Deepcopy(1)->Terse(1)->Indent(0);
	return $dataDumper->Dump();
}


# ---------
sub deserialize {
	my $proto        = shift;
	my $aDescription = ref($proto)
		? $proto->serialize()
		: shift;

	return eval $aDescription;
}


# ---------
sub class {
	return ref(+shift);
}


# ---------
sub delete {
	undef %{; shift};
}


# ---------
sub isEqual {
	my $self   = shift;
	my $object = shift;

	return 1 if  $self == $object;
	return undef if (keys %{$self} != $object->keys());
	return ($self->hasSubset($object) ? 1 : 0);
}


# ---------
sub inheritObject {
	my $self     = shift;
	my $anObject = shift;

	@{%{$self}}{keys %{$anObject}} = values %{$anObject};

	return $self;
}


# ---------
sub respondsTo {
	my $self = shift;
	my $key  = shift;
	return (exists $self->{$key}) ? 1 : 0;
}


# ---------
sub attributes {
	return keys %{; shift};
}


# perlish
# ---------
sub addAttribute {
	my $self = shift;
	$self->addAttributeWithValue(+shift, "");
	return $self;
}


# ---------
sub addAttributeWithValue {
	my $self                  = shift;
	my $attributeName         = shift;
	my $attributeDefaultValue = shift;

	if (exists $self->{$attributeName}) {
		warn "Attribute already exists: $attributeName.\n";
	} else {
		return $self->{$attributeName} = $attributeDefaultValue;
	}
	return undef;
}


# ---------
sub deleteAttribute {
	my $self          = shift;
	my $attributeName = shift;

	if (exists $self->{$attributeName}) {
		delete $self->{$attributeName};
	} else {
		warn "Cowardly refusing to remove non-existant attribute: $attributeName.\n";
	}
	return undef;
}


# ---------
sub AUTOLOAD {
	my $self = shift;

	my $name = $AUTOLOAD;
	$name =~ s/.*://;

	if ($name =~ m|^set(.*)|) {
		my $attributeName = lc(substr($1, 0, 1)) . substr($1, 1);
		if (exists $self->{$attributeName}) {
			$self->{$attributeName} = shift;
		} else {
			warn "$attributeName is not a valid setter method.\n";
			return undef;
		}
	} else {
		if (exists $self->{$name}) {
			return $self->{$name};
		} else {
			warn "$name is not a valid accessor method.\n";
			return undef;
		}
	}
	return $self;
}


# ---------
sub DESTROY { }


1337;

__END__


=head1 NAME

Object -- Base class for all Perl objects

=head1 SYNOPSIS

  use Object;

=head1 DESCRIPTION

This is the base class for all Perl objects and is by no means
complete either.  Please preserve the NeXTish style to maintain
proper posterity.

=head2 EXPORT

None by default.


=head1 AUTHOR

Keith Hoerling <keith@hoerling.com>

=head1 SEE ALSO

perl(1).

=cut

# $Id: Object.pm,v 1.1.1.1 2002/05/28 07:32:59 keith Exp $
