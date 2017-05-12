#
#    Results.pm - Object which contains validation result.
#
#    This file is part of FormValidator.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 2000 iNsu Innovations Inc.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms same terms as perl itself.
#
use strict;

package HTML::FormValidator::Results;

use HTML::FormValidator::Constraints;
use HTML::FormValidator::Filters;

=pod

=head1 NAME

HTML::FormValidator::Results - Object which contains the results of an input validation.

=head1 SYNOPSIS

    my $results = $validator->check( \%fdat, "customer_infos" );

    # Print the name of missing fields
    if ( $results->has_missing ) {
	foreach my $f ( $results->missing ) {
	    print $f, " is missing\n";
	}
    }

    # Print the name of invalid fields
    if ( $results->has_invalid ) {
	foreach my $f ( $results->invalid ) {
	    print $f, " is invalid: ", $results->invalid( $f ) \n";
	}
    }

    # Print fields with warnings
    if ( $results->has_warnings ) {
	foreach my $f ( $results->warnings ) {
	    print $f, "'s value is not recommended\n";
	}
    }

    # Print unknown fields
    if ( $results->has_unknown ) {
	foreach my $f ( $results->unknown ) {
	    print $f, " is unknown\n";
	}
    }

    # Print conflicting fields
    if ( $results->has_conflicts ) {
	foreach my $f ( $results->conflicts ) {
	    print $f, " conflicts with ", join( "," $results->conflicts( $f)),  "\n";
	}
    }

    # Print valid fields
    foreach my $f ( $results->valid() ) {
	print $f, " =  ", $result->valid( $f ), "\n";
    }

=head1 DESCRIPTION

This is the object returned by the HTML::FormValidator check method. It can
be queried for information about the validation results.

=cut

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my ($profile, $data) = @_;

    my $self = bless {}, $class;

    $self->_process( $profile, $data );

    $self;
}

sub _process {
    my ($self, $profile, $data) = @_;

    # Copy data and assumes that all is valid
    my %valid	    = %$data;
    my %missing;
    my %invalid;
    my %unknown;
    my %conflicts;
    my %warnings;

     # Apply inconditional filters
    foreach my $filter ( @{$profile->{filters}} ) {
	# Qualify symbolic references
	$filter = ref $filter ? $filter :
	  "HTML::FormValidator::Filters::filter_" . $filter;
	foreach my $field ( keys %valid ) {
	    no strict 'refs';
	    $valid{$field} = $filter->( $valid{$field} );
	}
    }

    # Apply specific filters
    while ( my ($field,$filters) = each %{$profile->{field_filters} }) {
	my @f = ref $filters eq "ARRAY" ? @$filters : ( $filters );
	my $v = $valid{$field};
	foreach my $filter ( @f ) {
	    # Qualify symbolic references
	    $filter = ref $filter ? $filter :
	      "HTML::FormValidator::Filters::filter_" . $filter;
	    no strict 'refs';

	    $v = $filter->( $v );
	}
	$valid{$field} = $v;
    }

    # Remove all empty fields
    foreach my $field ( keys %valid ) {
	delete $valid{$field} unless length $valid{$field};
    }

    my %required    = map { $_ => 1 } @{$profile->{required}};
    my %optional    = map { $_ => 1 } @{$profile->{optional}};

    # Check if the presence of some fields makes other optional
    # fields required.
    while ( my ( $field, $deps) = each %{$profile->{dependencies}} ) {
	if ( $valid{$field} ) {
	    foreach my $dep ( @$deps ) {
		$required{$dep} = 1;
	    }
	}
    }

    # Find unknown
    %unknown = map { $_ => $valid{$_} }
      grep { ! (exists $optional{$_} || exists $required{$_} ) } keys %valid;
    # and remove them from the list
    foreach my $field ( keys %unknown ) {
	delete $valid{$field};
    }

    # Fill defaults
    while ( my ($field,$value) = each %{$profile->{defaults}} ) {
	$valid{$field} = $value unless exists $valid{$field};
    }

    # Check for required fields
    foreach my $field ( keys %required ) {
	$missing{$field} = 1 unless exists $valid{$field};
    }

    # Find conflicts
    while ( my ( $field, $conflict ) = each %{$profile->{conflicts}} ) {
	foreach my $c ( @$conflict ) {
	    if ( exists $valid{$c} ) {
		push @{$conflicts{$c}}, $field;
		delete $valid{$c};
	    }
	}
    }

    # Check constraints
    while ( my ($field,$constraint_spec) = each %{$profile->{constraints}} ) {
	my ($constraint,@params);
	if ( ref $constraint_spec eq "HASH" ) {
	    $constraint = $constraint_spec->{constraint};
	    foreach my $fname ( @{$constraint_spec->{params} } ) {
		push @params, $valid{$fname};
	    }
	} else {
	    $constraint = $constraint_spec;
	    @params     = ( $valid{$field} );
	}
	next unless exists $valid{$field};

	unless ( ref $constraint ) {
	    # Check for regexp constraint
	    if ( $constraint =~ m@^\s*(/.+/|m(.).+\2)[cgimosx]*\s*$@ ) {
		my $sub = eval 'sub { $_[0] =~ '. $constraint . '}';
		die "Error compiling regular expression $constraint: $@" if $@;
		$constraint = $sub;
		# Cache for next use
		if ( ref $constraint_spec eq "HASH" ) {
		    $constraint_spec->{constraint} = $sub;
		} else {
		    $profile->{constraints}{$field} = $sub;
		}
	    } else {
		# Qualify symbolic reference
		$constraint = "HTML::FormValidator::Constraints::valid_" .
		  $constraint;
	    }
	}
	no strict 'refs';

	my $r = $constraint->( @params );
	if ( $r == -1 ) {
	    $warnings{$field} = 1;
	} elsif ( ! $r ) {
	    $invalid{$field} = $valid{$field};
	    delete $valid{$field};
	}
    }

    $self->{valid}	= \%valid;
    $self->{invalid}	= \%invalid;
    $self->{unknown}	= \%unknown;
    $self->{missing}	= \%missing;
    $self->{conflicts}	= \%conflicts;
    $self->{warnings}	= \%warnings;
}

=pod

=head1 valid( [field] )

This method returns in an array context the list of fields which
contains valid value. In a scalar context, it returns an hash reference
which contains the valid fields and their value.

If called with an argument, it returns the value of that field if it
contains valid data, undef otherwise.

=cut

sub valid {
    return $_[0]{valid}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{valid}} : $_[0]{valid};
}

=pod

=head1 has_missing()

This method returns true if the results contains missing fields.

=cut

sub has_missing {
    return scalar keys %{$_[0]{missing}};
}

=pod

=head1 missing( [field] )

This method returns in an array context the list of fields which
are missing. In a scalar context, it returns an array reference
to the list of missing fields.

If called with an argument, it returns true if that field is missing,
undef otherwise.

=cut

sub missing {
    return $_[0]{missing}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{missing}} : [ keys %{$_[0]{missing}} ];
}

=pod

=head1 has_invalid()

This method returns true if the results contains fields with invalid
data.

=cut

sub has_invalid {
    return scalar keys %{$_[0]{invalid}};
}

=pod

=head1 invalid( [field] )

This method returns in an array context the list of fields which
contains invalid value. In a scalar context, it returns an hash reference
which contains the invalid fields and their value.

If called with an argument, it returns the value of that field if it
contains invalid data, undef otherwise.

=cut

sub invalid {
    return $_[0]{invalid}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{invalid}} : $_[0]{invalid};
}

=pod

=head1 has_unknown()

This method returns true if the results contains unknown fields.

=cut

sub has_unknown {
    return scalar keys %{$_[0]{unknown}};

}

=pod

=head1 unknown( [field] )

This method returns in an array context the list of fields which
are unknown. In a scalar context, it returns an hash reference
which contains the unknown fields and their value.

If called with an argument, it returns the value of that field if it
is unknown, undef otherwise.

=cut

sub unknown {
    return $_[0]{unknown}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{unknown}} : $_[0]{unknown};
}

=pod

=head1 has_warnings()

This method returns true if the results contains conflicts.

=cut

sub has_warnings {
    return scalar keys %{$_[0]{warnings}};
}

=pod

=head1 warnings( [field] )

This method returns in an array context the list of fields which
have warnings (a constraint returned -1). In a scalar context,
it returns an array reference to the list of fields which have
warnings.

If called with an argument, it returns true if that field has a
warning associated with it.

=cut

sub warnings {
    return $_[0]{warnings}{$_[1]} if (defined $_[1]);

    wantarray ? keys %{$_[0]{warnings}} : $_[0]{warnings};
}

=pod 

=head1 has_conflicts()

Return true if some fields have conflicts.

=cut

sub has_conflicts {
    return scalar keys %{$_[0]{conflicts}};
}

=pod

=head1 conflicts( [field] )

This method returns in an array context the list of fields which
contains have conflicts. In a scalar context, it returns an hash reference
which contains the fields and their conflicts.

If called with an argument, it returns in an array context the list of
conflicts for that field, or an array reference to the conflicts list in a
scalar context.

=cut

sub conflicts {
    if ( @_ == 2 ) {
	if ( wantarray ) {
	    my $ref = $_[0]{conflicts}{$_[1]};
	    return defined $ref ? @$ref : $ref;
	} else {
	    return $_[0]{conflicts}{$_[1]};
	}
    }

    wantarray ? keys %{$_[0]{conflicts}} : [ keys %{$_[0]{conflicts}} ];
}

1;

__END__

=pod

=head1 SEE ALSO

HTML::FormValidator(3) HTML::FormValidator::Filters(3)
HTML::FormValidator::Constraints(3) HTML::FormValidator::ConstraintsFactory(3)

=head1 AUTHOR

Francis J. Lacoste <francis.lacoste@iNsu.COM>

=head1 COPYRIGHT

Copyright (c) 1999,2000 iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms as perl itself.

=cut
