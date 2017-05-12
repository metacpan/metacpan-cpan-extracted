package Form::Base;

use strict;
use warnings;
use UNIVERSAL::moniker;

=head1 NAME

Form::Base - Base class for other Form classes

=head1 SYNOPSIS

=head1 DESCRIPTION

This provides a base class for Form classes that need attributes that
can be set either as class or instance methods. This is really a
standalone CPAN module waiting to escape once we decide it's a sensible
approach to things.

=head1 METHODS

=head2 mk_attributes

	__PACKAGE__->mk_attributes(qw/ decorators fields name /);

Any subclass which wishes to have other attributes that follow this same
pattern (inheritiable class data which gets copied into instance data
when a form is created), can set them up using mk_attributes.

=cut

use base qw/Class::Data::Inheritable/;

sub mk_attributes {
	my ($class, @att) = @_;
	no strict 'refs';

	foreach my $att (@att) {
		my $inner = "_$att";
		my $add   = "add_$att";
		my $addalias   = "_add_$att";
        my $alias = "_att_$att";

		$class->mk_classdata($inner);

		*{"$class\::$alias"} = sub {
			my $proto = shift;
            if (ref $proto) {
                if (@_) { $proto->{$att} = shift }
                return $proto->{$att};
            } else {
                $proto->$inner(@_);
            }
		};

        *{"$class\::$att"} = \&{"$class\::$alias"}
            unless *{"$class\::$att"}{CODE};

		*{"$class\::$addalias"} = sub {
			my $proto = shift;
			$proto->$alias([ @{ $proto->$alias || [] }, @_ ]);
			return $proto;
		};
        *{"$class\::$add"} = \&{"$class\::$addalias"}
            unless *{"$class\::$add"}{CODE};
	}

	*{"$class\::new"} = sub {
		my ($class, $args) = @_;
		my $self = bless {}, ref $class || $class;

		# Copy class-data down into instance
		foreach my $att (@att) {
            my $att2 = "_att_$att";
			$self->$att2($class->$att2() || $class->moniker);
            # Why the moniker?
		}

		while (my ($att, $val) = each %$args) {
			if (ref($val) eq "ARRAY") {
				my $meth = "add_$att";
				$self->$meth(@$val);
			} else {
				$self->$att($val);
			}
		}
		return $self;
	};
}

1;
