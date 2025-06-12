package MQUL;

# ABSTRACT: General purpose, MongoDB-style query and update language

BEGIN {
    use Exporter 'import';
    @EXPORT_OK = qw/doc_matches update_doc/;
}

use warnings;
use strict;
use Carp;
use Data::Compare;
use Data::Types qw/:is/;
use DateTime::Format::W3CDTF;
use Scalar::Util qw/blessed/;
use Try::Tiny;

our $VERSION = "3.000000";
$VERSION = eval $VERSION;

=head1 NAME

MQUL - General purpose, MongoDB-style query and update language

=head1 SYNOPSIS

	use MQUL qw/doc_matches update_doc/;

	my $doc = {
		title => 'Freaks and Geeks',
		genres => [qw/comedy drama/],
		imdb_score => 9.4,
		seasons => 1,
		starring => ['Linda Cardellini', 'James Franco', 'Jason Segel'],
		likes => { up => 45, down => 11 }
	};

	if (doc_matches($doc, {
		title => qr/geeks/i,
		genres => 'comedy',
		imdb_score => { '$gte' => 5, '$lte' => 9.5 },
		starring => { '$type' => 'array', '$size' => 3 },
		'likes.up' => { '$gt' => 40 }
	})) {
		# will be true in this example
	}

	update_doc($doc, {
		'$set' => { title => 'Greeks and Feaks' },
		'$pop' => { genres => 1 },
		'$inc' => { imdb_score => 0.6 },
		'$unset' => { seasons => 1 },
		'$push' => { starring => 'John Francis Daley' },
	});

	# $doc will now be:
	{
		title => 'Greeks and Feaks',
		genres => ['comedy'],
		imdb_score => 10,
		starring => ['Linda Cardellini', 'James Franco', 'Jason Segel', 'John Francis Daley'],
		likes => { up => 45, down => 11 }
	}

=head1 DESCRIPTION

MQUL (for B<M>ongoDB-style B<Q>uery & B<U>pdate B<L>anguage; pronounced
I<"umm, cool">; yeah, I know, that's the dumbest thing ever), is a general
purpose implementation of L<MongoDB>'s query and update language. The
implementation is not 100% compatible, but it only slightly deviates from
MongoDB's behavior, actually extending it a bit.

The module exports two subroutines: C<doc_matches()> and C<update_doc()>.
The first subroutine takes a document, which is really just a hash-ref (of
whatever complexity), and a query hash-ref built in the MQUL query language.
It returns a true value if the document matches the query, and a
false value otherwise. The second subroutine takes a document and an update
hash-ref built in the MQUL update language. The subroutine modifies the document
(in-place) according to the update hash-ref.

You can use this module for whatever purpose you see fit. It was actually
written for L<Giddy>, my Git-database, and was extracted from its
original code. Outside of the database world, I plan to use it in an application
that performs tests (such as process monitoring for example), and uses the
query language to determine whether the results are valid or not (in our
monitoring example, that could be CPU usage above a certain threshold and
stuff like that). It is also used by L<MorboDB>, an in-memory clone of
MongoDB.

=head2 UPGRADE NOTES

My distributions follow the L<semantic versioning scheme|http://semver.org/>,
so whenever the major version changes, that means that API changes incompatible
with previous versions have been made. Always read the Changes file before upgrading.

=head2 THE LANGUAGE

The language itself is described in L<MQUL::Reference>. This document
only describes the interface of this module.

The reference document also details MQUL's current differences from the
original MongoDB language.

=cut

our %BUILTINS = (
    '$abs' => sub {
        ##############################################
        # abs( $value )                              #
        # ========================================== #
        # $value - a numerical value                 #
        # ------------------------------------------ #
        # returns the absolute value of $value       #
        ##############################################
        abs shift;
    },
    '$min' => sub {
        ##############################################
        # min( @values )                             #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the smallest number in @values     #
        ##############################################
        my $min = shift;
        foreach (@_) {
            $min = $_ if $_ < $min;
        }
        return $min;
    },
    '$max' => sub {
        ##############################################
        # max( @values )                             #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the largest number in @values      #
        ##############################################
        my $max = shift;
        foreach (@_) {
            $max = $_ if $_ > $max;
        }
        return $max;
    },
    '$diff' => sub {
        ##############################################
        # diff( @values )                            #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the difference between the values  #
        ##############################################
        my $diff = shift;
        foreach (@_) {
            $diff -= $_;
        }
        return $diff;
    },
    '$sum' => sub {
        ##############################################
        # sum( @values )                             #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the summation of the values        #
        ##############################################
        my $sum = shift;
        foreach (@_) {
            $sum += $_;
        }
        return $sum;
    },
    '$product' => sub {
        ##############################################
        # product( @values )                         #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the product of the values          #
        ##############################################
        my $prod = shift;
        foreach (@_) {
            $prod *= $_;
        }
        return $prod;
    },
    '$div' => sub {
        ##############################################
        # div( @values )                             #
        # ========================================== #
        # @values - a list of numerical values       #
        # ------------------------------------------ #
        # returns the division of the values.        #
        # if the function encounters zero anywhere   #
        # after the first value, it will immediately #
        # return zero instead of raise an error.     #
        ##############################################
        my $div = shift;
        foreach (@_) {
            return 0 if $_ == 0;
            $div /= $_;
        }
        return $div;
    }
);

=head1 INTERFACE

=head2 doc_matches( \%document, [ \%query, \@defs ] )

Receives a document hash-ref and possibly a query hash-ref, and returns
true if the document matches the query, false otherwise. If no query
is given (or an empty hash-ref is given), true will be returned (every
document will match an empty query - in accordance with MongoDB).

See L<MQUL::Reference/"QUERY STRUCTURE"> to learn about the structure of
query hash-refs.

Optionally, an even-numbered array reference of dynamically calculated
attribute definitions can be provided. For example:

	[ min_val => { '$min' => ['attr1', 'attr2', 'attr3' ] },
	  max_val => { '$max' => ['attr1', 'attr2', 'attr3' ] },
	  difference => { '$diff' => ['max_val', 'min_val'] } ]

This defines three dynamic attributes: C<min_val>, C<max_val> and
C<difference>, which is made up of the first two.

See L<MQUL::Reference/"DYNAMICALLY CALCULATED ATTRIBUTES"> for more information
about dynamic attributes.

=cut

sub doc_matches {
    my ( $doc, $query, $defs ) = @_;

    croak 'MQUL::doc_matches() requires a document hash-ref.'
      unless $doc && ref $doc && ref $doc eq 'HASH';
    croak 'MQUL::doc_matches() expects a query hash-ref.'
      if $query && ( !ref $query || ref $query ne 'HASH' );
    croak 'MQUL::doc_matches() expects an even-numbered definitions array-ref.'
      if $defs
      && ( !ref $defs || ref $defs ne 'ARRAY' || scalar @$defs % 2 != 0 );

    $query ||= {};

    if ($defs) {
        for ( my $i = 0 ; $i < scalar(@$defs) - 1 ; $i = $i + 2 ) {
            my ( $name, $def ) = ( $defs->[$i], $defs->[ $i + 1 ] );
            $doc->{$name} = _parse_function( $doc, $def );
        }
    }

    # go over each key of the query
    foreach my $key ( keys %$query ) {
        my $value = $query->{$key};
        if ( $key eq '$or' && ref $value eq 'ARRAY' ) {
            my $found;
            foreach (@$value) {
                next unless ref $_ eq 'HASH';
                my $ok = 1;

                while ( my ( $k, $v ) = each %$_ ) {
                    unless ( &_attribute_matches( $doc, $k, $v ) ) {
                        undef $ok;
                        last;
                    }
                }

                if ($ok) {    # document matches this criteria
                    $found = 1;
                    last;
                }
            }
            return unless $found;
        } elsif ( $key eq '$and' && ref $value eq 'ARRAY' ) {
            foreach (@$value) {
                return unless &doc_matches( $doc, $_, $defs );
            }
        } else {
            return unless &_attribute_matches( $doc, $key, $value );
        }
    }

    # if we've reached here, the document matches, so return true
    return 1;
}

##############################################
# _attribute_matches( $doc, $key, $value )   #
# ========================================== #
# $doc   - the document hash-ref             #
# $key   - the attribute being checked       #
# $value - the constraint for the attribute  #
#          taken from the query hash-ref     #
# ------------------------------------------ #
# returns true if constraint is met in the   #
# provided document.                         #
##############################################

my $funcs = join( '|', keys %BUILTINS );

sub _attribute_matches {
    my ( $doc, $key, $value ) = @_;

    my %virt;
    if ( $key =~ m/\./ ) {

        # support for the dot notation
        my ( $v, $k ) = _expand_dot_notation( $doc, $key );

        $key = $k;
        $virt{$key} = $v
          if defined $v;
    } else {
        $virt{$key} = $doc->{$key}
          if exists $doc->{$key};
    }

    if ( !ref $value ) {   # if value is a scalar, we need to check for equality
                           # (or, if the attribute is an array in the document,
                           # we need to check the value exists in it)
        return unless defined $virt{$key};
        if ( ref $virt{$key} eq 'ARRAY' )
        {                  # check the array has the requested value
            return unless &_array_has_eq( $value, $virt{$key} );
        } elsif ( !ref $virt{$key} ) {    # check the values are equal
            return unless $virt{$key} eq $value;
        } else {    # we can't compare a non-scalar to a scalar, so return false
            return;
        }
    } elsif (
        blessed $value
        && (   blessed $value eq 'MongoDB::OID'
            || blessed $value eq 'MorboDB::OID' )
      )
    {
        # we're trying to compare MongoDB::OIDs/MorboDB::OIDs
        # (MorboDB is my in-memory clone of MongoDB)
        return unless defined $virt{$key};
        if (
            blessed $virt{$key}
            && (   blessed $virt{$key} eq 'MongoDB::OID'
                || blessed $virt{$key} eq 'MorboDB::OID' )
          )
        {
            return unless $virt{$key}->value eq $value->value;
        } else {
            return;
        }
    } elsif ( ref $value eq 'Regexp' )
    {    # if the value is a regex, we need to check
         # for a match (or, if the attribute is an array
         # in the document, we need to check at least one
         # value in it matches it)
        return unless defined $virt{$key};
        if ( ref $virt{$key} eq 'ARRAY' ) {
            return unless &_array_has_re( $value, $virt{$key} );
        } elsif ( !ref $virt{$key} ) {    # check the values match
            return unless $virt{$key} =~ $value;
        } else {    # we can't compare a non-scalar to a scalar, so return false
            return;
        }
    } elsif ( ref $value eq 'HASH' )
    {               # if the value is a hash, than it either contains
                    # advanced queries, or it's just a hash that we
                    # want the document to have as-is
        unless ( &_has_adv_que($value) ) {

            # value hash-ref doesn't have any advanced
            # queries, we need to check our document
            # has an attributes with exactly the same hash-ref
            # (and name of course)
            return unless Compare( $value, $virt{$key} );
        } else {

            # value contains advanced queries,
            # we need to make sure our document has an
            # attribute with the same name that matches
            # all these queries
            foreach my $q ( keys %$value ) {
                my $term = $value->{$q};
                if (   $q eq '$gt'
                    || $q eq '$gte'
                    || $q eq '$lt'
                    || $q eq '$lte'
                    || $q eq '$eq'
                    || $q eq '$ne' )
                {
                    return unless defined $virt{$key} && !ref $virt{$key};

                    # If the values are not of the same type, do not bother
                    # comparing.
                    if ( is_float( $virt{$key} ) && !is_float($term)
                        || ( !is_float( $virt{$key} ) && is_float($term) ) )
                    {
                        return;
                    }

                    if ( $q eq '$gt' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} > $term;
                        } else {
                            return unless $virt{$key} gt $term;
                        }
                    } elsif ( $q eq '$gte' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} >= $term;
                        } else {
                            return unless $virt{$key} ge $term;
                        }
                    } elsif ( $q eq '$lt' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} < $term;
                        } else {
                            return unless $virt{$key} lt $term;
                        }
                    } elsif ( $q eq '$lte' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} <= $term;
                        } else {
                            return unless $virt{$key} le $term;
                        }
                    } elsif ( $q eq '$eq' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} == $term;
                        } else {
                            return unless $virt{$key} eq $term;
                        }
                    } elsif ( $q eq '$ne' ) {
                        if ( is_float( $virt{$key} ) ) {
                            return unless $virt{$key} != $term;
                        } else {
                            return unless $virt{$key} ne $term;
                        }
                    }
                } elsif ( $q eq '$exists' ) {
                    if ($term) {
                        return unless exists $virt{$key};
                    } else {
                        return if exists $virt{$key};
                    }
                } elsif ( $q eq '$mod'
                    && ref $term eq 'ARRAY'
                    && scalar @$term == 2 )
                {
                    return
                         unless defined $virt{$key}
                      && is_float( $virt{$key} )
                      && $virt{$key} % $term->[0] == $term->[1];
                } elsif ( $q eq '$in' && ref $term eq 'ARRAY' ) {
                    return
                      unless defined $virt{$key}
                      && &_value_in( $virt{$key}, $term );
                } elsif ( $q eq '$nin' && ref $term eq 'ARRAY' ) {
                    return
                      unless defined $virt{$key}
                      && !&_value_in( $virt{$key}, $term );
                } elsif ( $q eq '$size' && is_int($term) ) {
                    return
                      unless defined $virt{$key}
                      && (
                        (
                            ref $virt{$key} eq 'ARRAY'
                            && scalar @{ $virt{$key} } == $term
                        )
                        || ( ref $virt{$key} eq 'HASH'
                            && scalar keys %{ $virt{$key} } == $term )
                      );
                } elsif ( $q eq '$all' && ref $term eq 'ARRAY' ) {
                    return
                      unless defined $virt{$key} && ref $virt{$key} eq 'ARRAY';
                    foreach (@$term) {
                        return unless &_value_in( $_, $virt{$key} );
                    }
                } elsif ( $q eq '$type' && !ref $term ) {
                    if ( $term eq 'int' ) {
                        return
                          unless defined $virt{$key} && is_int( $virt{$key} );
                    } elsif ( $term eq 'float' ) {
                        return
                          unless defined $virt{$key} && is_float( $virt{$key} );
                    } elsif ( $term eq 'real' ) {
                        return
                          unless defined $virt{$key} && is_real( $virt{$key} );
                    } elsif ( $term eq 'whole' ) {
                        return
                          unless defined $virt{$key} && is_whole( $virt{$key} );
                    } elsif ( $term eq 'string' ) {
                        return
                          unless defined $virt{$key}
                          && is_string( $virt{$key} );
                    } elsif ( $term eq 'array' ) {
                        return
                          unless defined $virt{$key}
                          && ref $virt{$key} eq 'ARRAY';
                    } elsif ( $term eq 'hash' ) {
                        return
                          unless defined $virt{$key}
                          && ref $virt{$key} eq 'HASH';
                    } elsif ( $term eq 'bool' ) {

# boolean - not really supported, will always return true since everything in Perl is a boolean
                    } elsif ( $term eq 'date' ) {
                        return unless defined $virt{$key} && !ref $virt{$key};
                        my $date = try {
                            DateTime::Format::W3CDTF->parse_datetime(
                                $virt{$key} )
                        } catch {
                            undef
                        };
                        return
                          unless blessed $date && blessed $date eq 'DateTime';
                    } elsif ( $term eq 'null' ) {
                        return
                          unless exists $virt{$key} && !defined $virt{$key};
                    } elsif ( $term eq 'regex' ) {
                        return
                          unless defined $virt{$key}
                          && ref $virt{$key} eq 'Regexp';
                    }
                }
            }
        }
    } elsif ( ref $value eq 'ARRAY' ) {
        return unless Compare( $value, $virt{$key} );
    }

    return 1;
}

##############################################
# _array_has_eq( $value, \@array )           #
# ========================================== #
# $value - the value to check for            #
# $array - the array to search in            #
# ------------------------------------------ #
# returns true if the value exists in the    #
# array provided.                            #
##############################################

sub _array_has_eq {
    my ( $value, $array ) = @_;

    foreach (@$array) {
        return 1 if $_ eq $value;
    }

    return;
}

##############################################
# _array_has_re( $regex, \@array )           #
# ========================================== #
# $regex - the regex to check for            #
# $array - the array to search in            #
# ------------------------------------------ #
# returns true if a value exists in the      #
# array provided that matches the regex.     #
##############################################

sub _array_has_re {
    my ( $re, $array ) = @_;

    foreach (@$array) {
        return 1 if m/$re/;
    }

    return;
}

##############################################
# _has_adv_que( \%hash )                     #
# ========================================== #
# $hash - the hash-ref to search in          #
# ------------------------------------------ #
# returns true if the hash-ref has any of    #
# the lang's advanced query operators        #
##############################################

sub _has_adv_que {
    my $hash = shift;

    foreach (
        '$gt', '$gte', '$lt', '$lte', '$all',  '$exists', '$mod',
        '$eq', '$ne',  '$in', '$nin', '$size', '$type'
      )
    {
        return 1 if exists $hash->{$_};
    }

    return;
}

##############################################
# _value_in( $value, \@array )               #
# ========================================== #
# $value - the value to check for            #
# $array - the array to search in            #
# ------------------------------------------ #
# returns true if the value is one of the    #
# values from the array.                     #
##############################################

sub _value_in {
    my ( $value, $array ) = @_;

    foreach (@$array) {
        next     if is_float($_)  && !is_float($value);
        next     if !is_float($_) && is_float($value);
        return 1 if is_float($_)  && $value == $_;
        return 1 if !is_float($_) && $value eq $_;
    }

    return;
}

=head2 update_doc( \%document, \%update )

Receives a document hash-ref and an update hash-ref, and updates the
document in-place according to the update hash-ref. Also returns the document
after the update. If the update hash-ref doesn't have any of the update
modifiers described by the language, then the update hash-ref is considered
as what the document should now be, and so will simply replace the document
hash-ref (once again, in accordance with MongoDB).

See L<MQUL::Reference/"UPDATE STRUCTURE"> to learn about the structure of
update hash-refs.

=cut

sub update_doc {
    my ( $doc, $obj ) = @_;

    croak "MQUL::update_doc() requires a document hash-ref."
      unless defined $doc && ref $doc && ref $doc eq 'HASH';
    croak "MQUL::update_doc() requires an update hash-ref."
      unless defined $obj && ref $obj && ref $obj eq 'HASH';

    # we only need to do something if the $obj hash-ref has any advanced
    # update operations, otherwise $obj is meant to be the new $doc

    if ( &_has_adv_upd($obj) ) {
        foreach my $op ( keys %$obj ) {
            if ( $op eq '$inc' ) {

                # increase numerically
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    $doc->{$field} ||= 0;
                    $doc->{$field} += $obj->{$op}->{$field};
                }
            } elsif ( $op eq '$set' ) {

                # set key-value pairs
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    $doc->{$field} = $obj->{$op}->{$field};
                }
            } elsif ( $op eq '$unset' ) {

                # remove key-value pairs
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    delete $doc->{$field} if $obj->{$op}->{$field};
                }
            } elsif ( $op eq '$rename' ) {

                # rename attributes
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    $doc->{ $obj->{$op}->{$field} } = delete $doc->{$field}
                      if exists $doc->{$field};
                }
            } elsif ( $op eq '$push' ) {

                # push values to end of arrays
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    push( @{ $doc->{$field} }, $obj->{$op}->{$field} );
                }
            } elsif ( $op eq '$pushAll' ) {

                # push a list of values to end of arrays
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    push( @{ $doc->{$field} }, @{ $obj->{$op}->{$field} } );
                }
            } elsif ( $op eq '$addToSet' ) {

                # push values to arrays only if they're not already there
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    my @add =
                         ref $obj->{$op}->{$field}
                      && ref $obj->{$op}->{$field} eq 'ARRAY'
                      ? @{ $obj->{$op}->{$field} }
                      : ( $obj->{$op}->{$field} );
                    foreach my $val (@add) {
                        push( @{ $doc->{$field} }, $val )
                          unless defined &_index_of( $val, $doc->{$field} );
                    }
                }
            } elsif ( $op eq '$pop' ) {

                # pop the last item from an array
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    pop( @{ $doc->{$field} } )
                      if $obj->{$op}->{$field};
                }
            } elsif ( $op eq '$shift' ) {

                # shift the first item from an array
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    shift( @{ $doc->{$field} } )
                      if $obj->{$op}->{$field};
                }
            } elsif ( $op eq '$splice' ) {

                # splice offsets from arrays
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    next
                      unless ref $obj->{$op}->{$field}
                      && ref $obj->{$op}->{$field} eq 'ARRAY'
                      && scalar @{ $obj->{$op}->{$field} } == 2;
                    $doc->{$field} ||= [];
                    splice(
                        @{ $doc->{$field} },
                        $obj->{$op}->{$field}->[0],
                        $obj->{$op}->{$field}->[1]
                    );
                }
            } elsif ( $op eq '$pull' ) {

                # remove values from arrays
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    my $i = &_index_of( $obj->{$op}->{$field}, $doc->{$field} );
                    while ( defined $i ) {
                        splice( @{ $doc->{$field} }, $i, 1 );
                        $i =
                          &_index_of( $obj->{$op}->{$field}, $doc->{$field} );
                    }
                }
            } elsif ( $op eq '$pullAll' ) {

                # remove a list of values from arrays
                next unless ref $obj->{$op} eq 'HASH';
                foreach my $field ( keys %{ $obj->{$op} } ) {
                    croak "The $field attribute is not an array in the doc."
                      if defined $doc->{$field}
                      && ref $doc->{$field} ne 'ARRAY';
                    $doc->{$field} ||= [];
                    foreach my $value ( @{ $obj->{$op}->{$field} } ) {
                        my $i = &_index_of( $value, $doc->{$field} );
                        while ( defined $i ) {
                            splice( @{ $doc->{$field} }, $i, 1 );
                            $i = &_index_of( $value, $doc->{$field} );
                        }
                    }
                }
            }
        }
    } else {

        # $obj is actually the new $doc
        %$doc = %$obj;
    }

    return $doc;
}

##############################################
# _has_adv_upd( \%hash )                     #
# ========================================== #
# $hash - the hash-ref to search in          #
# ------------------------------------------ #
# returns true if the hash-ref has any of    #
# the lang's advanced update operators       #
##############################################

sub _has_adv_upd {
    my $hash = shift;

    foreach (
        '$inc',      '$set',    '$unset', '$push',   '$pushAll',
        '$addToSet', '$pop',    '$shift', '$splice', '$pull',
        '$pullAll',  '$rename', '$bit'
      )
    {
        return 1 if exists $hash->{$_};
    }

    return;
}

##############################################
# _index_of( $value, \@array )               #
# ========================================== #
# $value - the value to search for           #
# $array - the array to search in            #
# ------------------------------------------ #
# searches for the provided value in the     #
# array, and returns its index if it is      #
# found, or undef otherwise.                 #
##############################################

sub _index_of {
    my ( $value, $array ) = @_;

    for ( my $i = 0 ; $i < scalar @$array ; $i++ ) {
        if ( is_float( $array->[$i] ) && is_float($value) ) {
            return $i if $array->[$i] == $value;
        } else {
            return $i if $array->[$i] eq $value;
        }
    }

    return;
}

##############################################
# _parse_function( $doc, $key )              #
# ========================================== #
# $doc - the document                        #
# $key - the key referencing a function and  #
#        a list of attributes, such as       #
#        min(attr1, attr2, attr3)            #
# ------------------------------------------ #
# calculates the value using the appropriate #
# function and returns the result            #
##############################################

sub _parse_function {
    my ( $doc, $def ) = @_;

    my ($func) = keys %$def;

    die "Unrecognized function $func"
      unless exists $BUILTINS{$func};

    $def->{$func} = [ $def->{$func} ]
      unless ref $def->{$func};

    my @vals;
    foreach ( @{ $def->{$func} } ) {
        my ( $v, $k ) = _expand_dot_notation( $doc, $_ );
        push( @vals, $v )
          if defined $v;
    }

    return unless scalar @vals;

    return $BUILTINS{$func}->(@vals);
}

##############################################
# _expand_dot_notation( $doc, $key )         #
# ========================================== #
# $doc - the document                        #
# $key - the key using dot notation          #
# ------------------------------------------ #
# takes a key using the dot notation, and    #
# returns the value of the document at the   #
# end of the chain (if any), plus the key at #
# the end of the chain.                      #
##############################################

sub _expand_dot_notation {
    my ( $doc, $key ) = @_;

    return ( $doc->{$key}, $key )
      unless $key =~ m/\./;

    my @way_there = split( /\./, $key );

    $key = shift @way_there;
    my %virt = ( $key => $doc->{$key} );

    while ( scalar @way_there ) {
        $key = shift @way_there;
        my ($have) = values %virt;

        if ( $have && ref $have eq 'HASH' && exists $have->{$key} ) {
            %virt = ( $key => $have->{$key} );
        } elsif ( $have
            && ref $have eq 'ARRAY'
            && $key =~ m/^\d+$/
            && scalar @$have > $key )
        {
            %virt = ( $key => $have->[$key] );
        } else {
            %virt = ();
        }
    }

    return ( $virt{$key}, $key );
}

=head1 DIAGNOSTICS

=over

=item C<< MQUL::doc_matches() requires a document hash-ref. >>

This error means that you've either haven't passed the C<doc_matches()>
subroutine any parameters, or given it a non-hash-ref document.

=item C<< MQUL::doc_matches() expects a query hash-ref. >>

This error means that you've passed the C<doc_matches()> attribute a
non-hash-ref query variable. While you don't actually have to pass a
query variable, if you do, it has to be a hash-ref.

=item C<< MQUL::update_doc() requires a document hash-ref. >>

This error means that you've either haven't passed the C<update_doc()>
subroutine any parameters, or given it a non-hash-ref document.

=item C<< MQUL::update_doc() requires an update hash-ref. >>

This error means that you've passed the C<update_doc()> subroutine a
non-hash-ref update variable.

=item C<< The %s attribute is not an array in the doc. >>

This error means that your update hash-ref tries to modify an array attribute
(with C<$push>, C<$pushAll>, C<$addToSet>, C<$pull>, C<$pullAll>,
C<$pop>, C<$shift> and C<$splice>), but the attribute in the document
provided to the C<update_doc()> subroutine is not an array.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
MQUL requires no configuration files or environment variables.

=head1 DEPENDENCIES

MQUL depends on the following modules:

=over

=item * L<Data::Compare>

=item * L<Data::Types>

=item * L<DateTime::Format::W3CDTF>

=item * L<Scalar::Util>

=item * L<Try::Tiny>

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-MQUL@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MQUL>.

=head1 AUTHOR

Ido Perlmuter <ido at ido50 dot net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2011-2025, Ido Perlmuter C<< ido at ido50 dot net >>.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
The full License is included in the LICENSE file. You may also
obtain a copy of the License at

L<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

1;
__END__
