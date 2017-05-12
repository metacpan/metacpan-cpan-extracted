#line 1
#!/usr/bin/perl

package Data::Visitor::Callback;
use Moose;

use Data::Visitor ();

use Carp qw(carp);
use Scalar::Util qw/blessed refaddr reftype/;

no warnings 'recursion';

use namespace::clean -except => 'meta';

use constant DEBUG => Data::Visitor::DEBUG();
use constant FIVE_EIGHT => ( $] >= 5.008 );

extends qw(Data::Visitor);

has callbacks => (
	isa => "HashRef",
	is  => "rw",
	default => sub { {} },
);

has class_callbacks => (
	isa => "ArrayRef",
	is  => "rw",
	default => sub { [] },
);

has ignore_return_values => (
	isa => "Bool",
	is  => "rw",
);

sub BUILDARGS {
	my ( $class, @args ) = @_;

	my $args = $class->SUPER::BUILDARGS(@args);

	my %init_args = map { $_->init_arg => undef } $class->meta->get_all_attributes;

	my %callbacks = map { $_ => $args->{$_} } grep { not exists $init_args{$_} } keys %$args;

	my @class_callbacks = do {
		no strict 'refs';
		grep {
			# this check can be half assed because an ->isa check will be
			# performed later. Anything that cold plausibly be a class name
			# should be included in the list, even if the class doesn't
			# actually exist.

			m{ :: | ^[A-Z] }x # if it looks kinda lack a class name
				or
			scalar keys %{"${_}::"} # or it really is a class
		} keys %callbacks;
	};

	# sort from least derived to most derived
	@class_callbacks = sort { !$a->isa($b) <=> !$b->isa($a) } @class_callbacks;

	return {
		%$args,
		callbacks       => \%callbacks,
		class_callbacks => \@class_callbacks,
	};
}

sub visit {
	my $self = shift;

	my $replaced_hash = local $self->{_replaced} = ($self->{_replaced} || {}); # delete it after we're done with the whole visit

	my @ret;

	for my $data (@_) {
		my $refaddr = ref($data) && refaddr($data); # we need this early, it may change by the time we write replaced hash

		local *_ = \$data; # alias $_

		if ( $refaddr and exists $replaced_hash->{ $refaddr } ) {
			if ( FIVE_EIGHT ) {
				$self->trace( mapping => replace => $data, with => $replaced_hash->{$refaddr} ) if DEBUG;
				push @ret, $data = $replaced_hash->{$refaddr};
				next;
			} else {
				carp(q{Assignment of replacement value for already seen reference } . overload::StrVal($data) . q{ to container doesn't work on Perls older than 5.8, structure shape may have lost integrity.});
			}
		}

		my $ret;

		if ( defined wantarray ) {
			$ret = $self->SUPER::visit( $self->callback( visit => $data ) );
		} else {
			$self->SUPER::visit( $self->callback( visit => $data ) );
		}

		$replaced_hash->{$refaddr} = $_ if $refaddr and ( not ref $_ or $refaddr ne refaddr($_) );

		push @ret, $ret if defined wantarray;
	}

	return ( @_ == 1 ? $ret[0] : @ret );
}

sub visit_ref {
	my ( $self, $data ) = @_;

	my $mapped = $self->callback( ref => $data );

	if ( ref $mapped ) {
		return $self->SUPER::visit_ref($mapped);
	} else {
		return $self->visit($mapped);
	}
}

sub visit_seen {
	my ( $self, $data, $result ) = @_;

	my $mapped = $self->callback( seen => $data, $result );

	no warnings 'uninitialized';
	if ( refaddr($mapped) == refaddr($data) ) {
		return $result;
	} else {
		return $mapped;
	}
}

sub visit_value {
	my ( $self, $data ) = @_;

	$data = $self->callback_and_reg( value => $data );
	$self->callback_and_reg( ( ref($data) ? "ref_value" : "plain_value" ) => $data );
}

sub visit_object {
	my ( $self, $data ) = @_;

	$self->trace( flow => visit_object => $data ) if DEBUG;

	$data = $self->callback_and_reg( object => $data );

	my $class_cb = 0;

	foreach my $class ( @{ $self->class_callbacks } ) {
		last unless blessed($data);
		next unless $data->isa($class);
		$self->trace( flow => class_callback => $class, on => $data ) if DEBUG;

		$class_cb++;
		$data = $self->callback_and_reg( $class => $data );
	}

	$data = $self->callback_and_reg( object_no_class => $data ) unless $class_cb;

	$data = $self->callback_and_reg( object_final => $data )
		if blessed($data);

	$data;
}

sub visit_scalar {
	my ( $self, $data ) = @_;
	my $new_data = $self->callback_and_reg( scalar => $data );
	if ( (reftype($new_data)||"") =~ /^(?: SCALAR | REF | LVALUE | VSTRING ) $/x ) {
		my $visited = $self->SUPER::visit_scalar( $new_data );

		no warnings "uninitialized";
		if ( refaddr($visited) != refaddr($data) ) {
			return $self->_register_mapping( $data, $visited );
		} else {
			return $visited;
		}
	} else {
		return $self->_register_mapping( $data, $self->visit( $new_data ) );
	}
}

sub subname { $_[1] }

BEGIN {
	eval {
		require Sub::Name;
		no warnings 'redefine';
		*subname = \&Sub::Name::subname;
	};

	foreach my $reftype ( qw/array hash glob code/ ) {
		my $name = "visit_$reftype";
		no strict 'refs';
		*$name = subname(__PACKAGE__ . "::$name", eval '
			sub {
				my ( $self, $data ) = @_;
				my $new_data = $self->callback_and_reg( '.$reftype.' => $data );
				if ( "'.uc($reftype).'" eq (reftype($new_data)||"") ) {
					my $visited = $self->SUPER::visit_'.$reftype.'( $new_data );

					no warnings "uninitialized";
					if ( refaddr($visited) != refaddr($data) ) {
						return $self->_register_mapping( $data, $visited );
					} else {
						return $visited;
					}
				} else {
					return $self->_register_mapping( $data, $self->visit( $new_data ) );
				}
			}
		' || die $@);
	}
}

sub visit_hash_entry {
	my ( $self, $key, $value, $hash ) = @_;

	my ( $new_key, $new_value ) = $self->callback( hash_entry => $_[1], $_[2], $_[3] );

	unless ( $self->ignore_return_values ) {
		no warnings 'uninitialized';
		if ( ref($value) and refaddr($value) != refaddr($new_value) ) {
			$self->_register_mapping( $value, $new_value );
			if ( $key ne $new_key ) {
				return $self->SUPER::visit_hash_entry($new_key, $new_value, $_[3]);
			} else {
				return $self->SUPER::visit_hash_entry($_[1], $new_value, $_[3]);
			}
		} else {
			if ( $key ne $new_key ) {
				return $self->SUPER::visit_hash_entry($new_key, $_[2], $_[3]);
			} else {
				return $self->SUPER::visit_hash_entry($_[1], $_[2], $_[3]);
			}
		}
	} else {
		return $self->SUPER::visit_hash_entry($_[1], $_[2], $_[3]);
	}
}

sub callback {
	my ( $self, $name, $data, @args ) = @_;

	if ( my $code = $self->callbacks->{$name} ) {
		$self->trace( flow => callback => $name, on => $data ) if DEBUG;
		if ( wantarray ) {
			my @ret = $self->$code( $data, @args );
			return $self->ignore_return_values ? ( $data, @args ) : @ret;
		} else {
			my $ret = $self->$code( $data, @args );
			return $self->ignore_return_values ? $data : $ret ;
		}
	} else {
		return wantarray ? ( $data, @args ) : $data;
	}
}

sub callback_and_reg {
	my ( $self, $name, $data, @args ) = @_;

	my $new_data = $self->callback( $name, $data, @args );

	unless ( $self->ignore_return_values ) {
		no warnings 'uninitialized';
		if ( ref $data ) {
			if ( refaddr($data) != refaddr($new_data) ) {
				return $self->_register_mapping( $data, $new_data );
			}
		}

		return $new_data;
	}

	return $data;
}

sub visit_tied {
	my ( $self, $tied, @args ) = @_;
	$self->SUPER::visit_tied( $self->callback_and_reg( tied => $tied, @args ), @args );
}

__PACKAGE__->meta->make_immutable if __PACKAGE__->meta->can("make_immutable");

__PACKAGE__

__END__

#line 451


