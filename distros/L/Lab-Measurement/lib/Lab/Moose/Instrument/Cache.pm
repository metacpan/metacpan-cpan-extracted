package Lab::Moose::Instrument::Cache;
$Lab::Moose::Instrument::Cache::VERSION = '3.682';
#ABSTRACT: Device caching functionality in Moose::Instrument drivers


use Moose;
use MooseX::Params::Validate;

Moose::Exporter->setup_import_methods( with_meta => ['cache'] );

use namespace::autoclean;

sub cache {
    my ( $meta, $name, %options ) = @_;

    my @options = %options;
    validated_hash(
        \@options,
        getter    => { isa      => 'Str' },
        isa       => { optional => 1, default => 'Any' },
        index_arg => { isa      => 'Str', optional => 1 },
    );

    my $getter         = $options{getter};
    my $isa            = $options{isa};
    my $index_arg      = $options{index_arg};
    my $have_index_arg = defined $index_arg;
    my $function       = "cached_$name";
    my $attribute      = "cached_${name}_attribute";
    my $builder        = "cached_${name}_builder";
    my $clearer        = "clear_cached_$name";
    my $predicate      = "has_cached_$name";

    # Creat builder method for the entry. The user can override
    # (method modifier)  this in an instrument driver to add additional
    # arguments to the getter.
    $meta->add_method(
        $builder => sub {
            my $self = shift;
            if ($have_index_arg) {
                my ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int' }
                );
                return $self->$getter( $index_arg => $index );
            }
            return $self->$getter();
        }
    );

    $meta->add_attribute(
        $attribute => (
            is       => 'rw',
            init_arg => undef,
            isa      => 'ArrayRef',
            default  => sub { [] },
        )
    );

    $meta->add_method(
        $function => sub {
            my $self  = shift;
            my $array = $self->$attribute();

            if ($have_index_arg) {
                my ( $index, $value ) = validated_list(
                    \@_,
                    $index_arg => { isa      => 'Int' },
                    value      => { optional => 1 },
                );
                if ( defined $value ) {

                    # Store entry.
                    return $array->[$index] = $value;
                }

                # Query cache.
                if ( defined $array->[$index] ) {
                    return $array->[$index];
                }
                return $array->[$index]
                    = $self->$builder( $index_arg => $index );
            }

            # No vector index argument. Behave like usual Moose attribute.
            if ( @_ == 0 ) {

                # Query cache.
                if ( defined $array->[0] ) {
                    return $array->[0];
                }
                $array->[0] = $self->$builder();
                return $array->[0];
            }

            # Store entry.
            my ($value) = pos_validated_list( \@_, { isa => $isa } );
            return $array->[0] = $value;
        }
    );

    $meta->add_method(
        $clearer => sub {
            my $self = shift;
            my $index;
            if ($have_index_arg) {

                # If no index is given, clear them all!
                ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int', optional => 1 },
                );
            }
            if ( defined $index ) {
                $self->$attribute->[$index] = undef;
            }
            else {
                $self->$attribute( [] );
            }
        }
    );

    $meta->add_method(
        $predicate => sub {
            my $self  = shift;
            my $index = 0;
            if ($have_index_arg) {
                ($index) = validated_list(
                    \@_,
                    $index_arg => { isa => 'Int' }
                );
            }

            my $array = $self->$attribute();
            if ( defined $array->[$index] ) {
                return 1;
            }
            return;
        }
    );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Cache - Device caching functionality in Moose::Instrument drivers

=head1 VERSION

version 3.682

=head1 SYNOPSIS

in your driver:

 use Lab::Moose::Instrument::Cache;

 cache foobar => (getter => 'get_foobar');

 sub get_foobar {
     my $self = shift;
     
     return $self->cached_foobar(
         $self->query(command => ...));
 }

 sub set_foobar {
     my ($self, $value) = @_;
     $self->write(command => ...);
     $self->cached_foobar($value);
 }

=head1 DESCRIPTION

This package exports a new Moose keyword: B<cache>.

Calling C<< cache key => (getter => $getter, isa => $type) >> generates the
following functions:

=over

=item C<cached_key> (accessor)

Calling C<< $instr->cached_key() >> will return the last stored value from the
cache. If the cache entry is empty, use the C<$getter> method.

To update the cache entry, call C<< $instr->cached_key($value) >>.

=item C<has_cached_key> (predicate)

Return true if the cache entry holds a value (which is not undef).

=item C<clear_cached_key> (clearer)

Clear the value of the cache entry.

=item C<cached_key_builder> (builder)

Called by C<cached_key> if the entry is cleared. This will call the C<$getter>
method. Can be overriden by 'around' method modifier if the C<$getter> needs
special extra arguments.

=back

The C<isa> argument is optional.

=head2 Array cache

Some methods take an additional parameter (e.g. channel number). For this case
you can give the C<index_arg> argument to the cache keyword:

 cache foobar => (isa => 'Num', getter => 'get_foobar', index_arg => 'channel');

 # Get value from cache.
 my $value = $instr->cached_foobar(channel => 1);
 
 # Store value.
 $instr->cached_foobar(channel => 2, value => 1.234);
 
 # Clear single entry.
 $instr->clear_cached_foobar(channel => 3);
 
 # Clear them all.
 $instr->clear_cached_foobar();
 
 # Check for cache value
 if ($instr->has_cached_foobar(channel => 1)) {...}

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt
            2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
