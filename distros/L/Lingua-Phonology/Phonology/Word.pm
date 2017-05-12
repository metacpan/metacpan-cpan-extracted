#!/usr/bin/perl

# A Word contains circular references, so we make a very thin wrapper around
# it.  Word itself is quite small, with WordWrapped doing most of the work.

package Lingua::Phonology::Word;

our $VERSION = 0.1;

use strict;
use warnings;

sub new {
    my $class = shift;
    my $word = Lingua::Phonology::WordWrapped->new(@_);
    bless \$word, $class;
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    no strict 'refs';
    *$method = sub { ${shift()}->$method(@_) };
    $self->$method(@_);
}

sub DESTROY {
    return if not defined ${$_[0]};
    ${shift()}->_release;
}

package Lingua::Phonology::WordWrapped;

use strict;
use warnings;
use Lingua::Phonology::Segment::Rules;
use Lingua::Phonology::Segment::Boundary;
use Lingua::Phonology::Common;
use constant {
    RIGHT => 0,
    LEFT => 1
};

sub new {
    my $class = shift;

    my $self = {
        orig => \@_,
        working => [],
        curidx => 0,
        curdom => 0,
        direction => RIGHT,
        domain => undef,
        tier => undef,
        filter => sub {1}
    };
    $self->{lbound} = Lingua::Phonology::Segment::Rules->new($self, Lingua::Phonology::Segment::Boundary->new());
    $self->{rbound} = Lingua::Phonology::Segment::Rules->new($self, Lingua::Phonology::Segment::Boundary->new());

    bless $self, $class;
}

my %valid = (
    direction => sub { 
        $_[0] = lc $_[0]; 
        return LEFT if $_[0] eq 'leftward'; 
        return RIGHT if $_[0] eq 'rightward'; 
        return; 
    },
    filter => sub { return $_[0] if _is $_[0], 'CODE'; return; },
    tier => sub { $_[0] },
    domain => sub { $_[0] },
    rule => sub { return $_[0] if _is $_[0], 'HASH'; return; }
);

for my $method (keys %valid) {
    no strict 'refs';
    *$method = sub { 
        my $self = shift;
        if (@_) {
            if (not defined $_[0]) {
                delete $self->{$method};
            }
            else {
                my $ok = $valid{$method}->(@_);
                if (defined $ok) {
                    $self->{$method} = $ok;
                }
                else {
                    return;
                }
            }
        }
        $self->{resync} = 1;
        return $self->{$method} unless $method eq 'direction';
        return $self->{$method} == RIGHT ? 'rightward' : 'leftward';
    };
}


# Call this func with an array ref
sub set_segs {
    my ($self, @ary) = @_;
    # Return undef and set $@ for errors
    for (@ary) {
        unless (_is_seg $_) {
            $@ = "Element in array not a segment";
            return;
        }
    }

    $self->{orig} = \@ary;
    $self->_rehash;
    $self->{resync} = 0;
    $self->_prepare;
    $self->reset;
}

# Reset the iterator
sub reset {
    my $self = shift;
    $self->{curdom} = 0;
    if ($self->{direction} == RIGHT) {
        $self->{curidx} = 0;
    }
    else {
        $self->{curidx} = $#{$self->{working}[0]};
    }
    $self->{first} = 1;
    1;
}

# Advance to the next segment
sub next {
    my $self = shift;

    # We should resync if needed before moving the iterator
    $self->_resync if $self->{resync};

    if ($self->{first}) {
        $self->{first} = 0;
    }
    else {
        if ($self->{direction} == RIGHT) {
            if (not defined $self->{working}[$self->{curdom}][++$self->{curidx}]) {
                return unless defined $self->{working}[++$self->{curdom}];
                $self->{curidx} = 0;
            }
        }
        elsif ($self->{direction} == LEFT) {
            if (--$self->{curidx} < 0) {
                return unless defined $self->{working}[++$self->{curdom}];
                $self->{curidx} = $#{$self->{working}[$self->{curdom}]};
            }
        }
    }
    return 1;
}

sub get_orig_segs {
    return @{$_[0]->{orig}};
}

sub get_working_segs {
    my $self = shift;
    $self->_resync if ($self->{resync});
    return 
        @{$self->{working}[$self->{curdom}]}[$self->{curidx} .. $#{$self->{working}[$self->{curdom}]}],
        $self->{rbound},
        $self->{lbound},
        @{$self->{working}[$self->{curdom}]}[0 .. ($self->{curidx} - 1)];
}

# Clear out current segments
sub clear {
    my $self = shift;
    $self->{orig} = [];
    $self->{working} = [];
    1;
}


# Called by child segments, inserts a segment into the word
sub _insert {
    my ($self, $id, $pos, $ins) = @_;

    # Adjust position according to the slot
    if ($id == $self->{lbound}->_getid) {
        unshift @{$self->{orig}}, $ins;
    }
    elsif ($id == $self->{rbound}->_getid) {
        push @{$self->{orig}}, $ins;
    }
    else {
        $pos += $self->{slot}{$id};
        splice @{$self->{orig}}, $pos, 0, $ins;
    }

    $self->_rehash;
}

# Called by child segments, removes a segment from the word
sub _delete {
    my ($self, $id) = @_;
    splice @{$self->{orig}}, $self->{slot}{$id}, 1;
    $self->_rehash;
}

# Rebuild the ref => index hash
sub _rehash {
    my $self = shift;

    my $count;
    for (@{$self->{orig}}) {
        $self->{slot}{int $_} = $count++;
    }
    $self->{resync} = 1;
}

sub _resync {
    my $self = shift;

    # When tier or domain is in effect, ignore
    unless ($self->{tier} || $self->{domain}) {
        # Get the id of the seg at our current position
        my $oldid = $self->{working}[$self->{curdom}][$self->{curidx}]->_getid;

        # Rebuild the working hash
        $self->_prepare;

        # Find out where we left off
        $self->_find($oldid);
    }
    $self->{resync} = 0;
}


# Find out where our current segment now is
sub _find {
    my $self = shift;

    my $oldid = shift;
    for my $outer (0 .. $#{$self->{working}}) {
        for (0 .. $#{$self->{working}[$outer]}) {
            if ($self->{working}[$outer][$_]->_getid == $oldid) {
                $self->{curdom} = $outer;
                $self->{curidx} = $_;
                return 1;
            }
        }
    }
    # Getting here indicates that we couldn't find the working seg--it was
    # probably deleted. So do nothing, and hope where we left off is okay
    1;
}
    
# Set up $self->{working}
sub _prepare {
    my $self = shift;
    $self->{working} = [];
    for (_make_domain($self->{domain}, @{$self->{orig}})) {
        my @sect = map { Lingua::Phonology::Segment::Rules->new($self, $_) } _make_tier($self->{tier}, @$_);

        my @keep;
        if ($self->{filter}) {
            push @sect, $self->{rbound}, $self->{lbound};
            for (0 .. ($#sect - 2)) {
                push @keep, $sect[0] if $self->{filter}->(@sect);
                push @sect, (shift @sect);
            }
        }
        else {
            @keep = @sect;
        }
        push @{$self->{working}}, \@keep;
    }
}

# Make a domain
sub _make_domain ($@) {
    my $domain = shift;
    return (\@_) if not defined $domain;
	my @return = ();

	my $i = 0;
	while ($i < scalar @_) {
		my @domain = ($_[$i]);

		# Keep adding segments as long as they have the same reference for $domain
        no warnings 'uninitialized';
		while (defined $_[$i + 1] &&
               _flatten([$_[$i]->value_ref($domain)]) eq _flatten([$_[$i+1]->value_ref($domain)])) {
			$i++;
			push (@domain, $_[$i]);
		}

		push (@return, \@domain);
		$i++;
	} 

	return @return;
}

# A quick func to flatten hashrefs into easily comparable strings
sub _flatten {
    my ($ref, $seen) = @_;
    return '' if not defined $ref;
    $seen = {} if not $seen;
    if (ref $ref) {
        return $ref if exists $seen->{$ref};
        $seen->{$ref} = undef;
    }

    if (_is $ref, 'ARRAY' ) {
        return join '', map { _flatten($_, $seen) } @$ref;
    }
    if (_is($ref, 'HASH')) {
        return join '', map { $_, _flatten($ref->{$_}, $seen) } sort keys %$ref;
    }
    return "$ref";
} 

sub _make_tier {
    my $tier = shift;
    return @_ if not defined $tier;
    return map { Lingua::Phonology::Segment::Tier->new(@$_) }
           _make_domain $tier, grep { defined $_->value($tier) }
           @_;
}

# Prepare for destruction
sub _release {
    my $self = shift;
    $self->clear;
    delete $self->{lbound};
    delete $self->{rbound};
}

1;
