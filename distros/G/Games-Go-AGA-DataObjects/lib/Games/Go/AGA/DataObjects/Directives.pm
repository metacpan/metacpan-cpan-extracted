#===============================================================================
#
#         FILE:  Games::Go::AGA::DataObjects::Directives.pm
#
#        USAGE:  use Games::Go::AGA::DataObjects::Directives;
#
#      PODNAME:  Games::Go::AGA::DataObjects::Directives
#     ABSTRACT:  model directives information from an AGA register.tde file
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/19/2010 03:13:05 PM PST
#===============================================================================

use strict;
use warnings;

package Games::Go::AGA::DataObjects::Directives;
use Moo;
use namespace::clean;

use Games::Go::AGA::DataObjects::Types qw( is_Rank is_Rating );
use Games::Go::AGA::Parse::Util qw( Rank_to_Rating );
use Games::Go::AGA::DataObjects::Types qw( isa_CodeRef isa_HashRef );

our $VERSION = '0.152'; # VERSION

has booleans => (
    isa => \&isa_HashRef,
    is => 'lazy',
    default => sub {
        {
            FORCE_ROUND_ROBIN   => 1,
            NO_ROUND_ROBIN      => 1,
            MCMAHON             => 1,
            AGA_RATED           => 1,
            TEST                => 1,
        }
    },
);
has change_callback => (
    isa => \&isa_CodeRef,
    is => 'rw',
    lazy => 1,
    default => sub { sub { } }
);

sub BUILD {
    my ($self) = @_;
    $self->{keys}   = [];    # empty arrays
    $self->{values} = [];
}

sub changed {
    my ($self) = @_;

    &{$self->change_callback}(@_);
}

sub directives {
    my ($self) = @_;

    return wantarray
        ? @{$self->{keys}}
        : scalar @{$self->{keys}};
}

sub is_boolean {
    my ($self, $key) = @_;

    return $self->booleans->{uc $key};
}

sub get_directive_at_idx {
    my ($self, $idx) = @_;

    croak("$idx out of range") if (($idx < 0) or
                                    ($idx >= @{$self->{keys}}));
    return ($self->{keys}[$idx], $self->{values}[$idx]);
}

sub set_directive_at_idx {
    my ($self, $idx, $key, $value) = @_;

    croak("$idx out of range") if (($idx < 0) or
                                    ($idx >= @{$self->{keys}}));
    $value = $self->_munge_BAND_BREAKS($value) if (uc $key eq 'BAND_BREAKS');
    $self->{keys}[$idx] = $key;
    $self->{values}[$idx] = $value;
    $self->changed;
    return $self;
}

sub delete_directive_at_idx {
    my ($self, $idx) = @_;

    $idx = 0 if ($idx < 0);
    $idx = $#{$self->{keys}} if ($idx > $#{$self->{keys}});

    splice(@{$self->{keys}}  , $idx, 1);
    splice(@{$self->{values}}, $idx, 1);
    $self->changed;
    return $self;
}

sub _munge_BAND_BREAKS {
    my ($self, $value) = @_;

    return '' if ($value eq '');        #special case to mark empty breaks
    return  join ' ',               # read from the bottom up:
        sort { $b <=> $a }              # sort stronger bands higher
        grep { $_ }                     # defined and truthy
        map  { is_Rank($_)              # is it a valid Rank?
            ? int Rank_to_Rating($_)    # if so, convert to a Rating and integerize
            : is_Rating($_)             # is it a Rating?
                ? $_                    # pass through untouched
                : undef }               # filter out everything else
        grep { $_ }                     # defined and truthy
        split(/[^\ddDkK\.\-]+/, $value);  # split into ranks/ratings
}

sub insert_directive_above {
    my ($self, $idx, $key, $value) = @_;

    if (not defined $idx or
        $idx < 0 or
        $idx >= @{$self->{keys}}) {
        $idx = @{$self->{keys}};  # add to end
    }

    $value = $self->_munge_BAND_BREAKS($value) if (uc $key eq 'BAND_BREAKS');
    splice(@{$self->{keys}}  , $idx, 0, $key);
    splice(@{$self->{values}}, $idx, 0, $value);
    $self->changed;
    return $self;
}

sub delete_directive {
    my ($self, $key) = @_;

    my $keys = $self->{keys};

    for (my $ii = $#{$keys}; $ii >= 0; $ii--) {
        if (uc $key eq uc $keys->[$ii]) {
            $self->delete_directive_at_idx($ii);
            $self->changed;
            last;
        }
    }
    return $self;
}

sub get_directive_values {      # for backwards compatibility
    shift->get_directive_value(@_);
}

sub get_directive_value {
    my ($self, $key) = @_;

    my $keys = $self->{keys};
    $key = uc ($key);
    foreach my $ii (0 .. $#{$keys}) {
        if (uc($keys->[$ii]) eq $key) {
            my $val = $self->{values}[$ii];
            $val = 1 if ($self->is_boolean($key)); # booleans (key but no defined value)
            return $val;
        }
    }
    return; # undef
}

sub set_directive_value {
    my ($self, $key, $val) = @_;

    my $keys = $self->{keys};
    my $uc_key = uc ($key);
    foreach my $ii (0 .. $#{$keys}) {
        if (uc($keys->[$ii]) eq $uc_key) {
            $val = '' if ($self->directive_is_boolean($key));    # presence is sufficient
            return $self->set_directive_at_idx ($ii, $key, $val);
        }
    }
    # not found?  add to the end
    return $self->insert_directive_above (-1, $key, $val);
}

sub fprint {
    my ($self, $fh) = @_;

    for my $ii (0 .. $#{$self->{keys}}) {
        $fh->print("## $self->{keys}[$ii] $self->{values}[$ii]\n");
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Directives - model directives information from an AGA register.tde file

=head1 VERSION

version 0.152

=head1 SYNOPSIS

    use Games::Go::AGA::DataObjects::Directives;

    my $directives = Games::Go::AGA::DataObjects::Directives->new;
    my $handi = $directives->get_directive_value('HANDICAPS') || 'none';

=head1 DESCRIPTION

Games::Go::AGA::DataObjects::Directives models directives information from
an AGA register.tde file.

Directives are entered in the register.tde file with two comment characters
followed by the directive, followed by the value of the directive:

    ## TOURNEY  Name of the tournament goes here
    ## Rules AGA

The Games::Go::AGA::DataObjects::Directives object stores directives as
key-value pairs.

Note that AGA directives are not case sensitive.  Key matching by this
module is similarly case insensitive.

=head1 METHODS

=over

=item @keys = directives()

=item $count = directives()

In array context, returns the list of directive names.  In scalar context,
returns the number of directives.

=item {$key, $value) = get_directive_at_idx($idx)

Returns two element array ('key', 'value') at B<$idx>.

=item set_directive_at_idx($idx, 'key', 'new value')

Change directive at index B<$idx> to 'key' and 'new value').

=item delete_directive_at_idx($idx)

Remove the directive and its associated value at B<$idx>.

=item insert_directive_above($idx, 'key', 'value')

Insert the key and its associated value at (before) B<$idx>.  If B<$idx> is
undef or greater than the number of directives, the new key and value are
added to the end.

=item delete_directive('key')

Remove B<key> and its associated value from the list of directives.

=item $value = get_directive_value('key')

Returns the value associated with 'key'.  If the key is found, but it has
no value (undef or empty string), the return value is the empty string
('').  If there are no matching keys, undef is returned.  Key matching is
not case sensitive.

=item set_directive_value('key', 'value')

Sets a new value associated with 'key'.  If 'key' is not already present,
it is added to the end of the Directives list.

=back

=head1 SEE ALSO

=over 4

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

=item Games::Go::AGA::Parse

=item Games::Go::AGA::Gtd

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
