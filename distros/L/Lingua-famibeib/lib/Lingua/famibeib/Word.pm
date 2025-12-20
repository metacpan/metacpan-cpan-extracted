# Copyright (c) 2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to interact with the famibeib words


package Lingua::famibeib::Word;

use v5.16;
use strict;
use warnings;

use Carp;

our $VERSION = v0.02;

use parent qw(Data::Identifier::Interface::Simple Data::Identifier::Interface::Subobjects);

use constant {
    _GENERATOR          => Data::Identifier->new(uuid => 'e2afa39e-fd57-45f8-89fd-8662b275cc68')->register,
    _GENERATOR_UINTEGER => Data::Identifier->new(uuid => '53863a15-68d4-448d-bd69-a9b19289a191')->register,
    _GENERATOR_SINTEGER => Data::Identifier->new(uuid => 'e8aa9e01-8d37-4b4b-8899-42ca0a2a906f')->register,
};

use overload (
    '""'    => \&as_string,
    'eq'    => sub {  $_[0]->eq($_[1]) },
    'ne'    => sub { !$_[0]->eq($_[1]) },
    'cmp'   => sub {  $_[0]->cmp($_[1]) },
);

my @_word_mora = qw(
    ba be bi bo bu
    fa fe fi fo fu
    ka ke ki ko ku
    la le li lo lu
    ma me mi mo mu
    sa se si so su
    ta te ti to tu
);

my %_word_mora;
{
    my $i = 0;
    %_word_mora = map {$_ => $i++} @_word_mora;
}

my %_registered_by_string;
my %_registered_by_uuid;


sub new {
    my ($pkg, $type, $value, @opts) = @_;
    my $self = bless {}, $pkg;

    croak 'Stray options passed' if scalar @opts;
    croak 'No type given' unless defined $type;
    croak 'No value given' unless defined $value;

    if ($type eq 'from') {
        if (ref $value) {
            if ($value->isa(__PACKAGE__)) {
                # TODO: handle this when @opts are non-empty
                return $value;
            } elsif ($value->isa('Data::Identifier') || $value->isa('Data::Identifier::Interface::Simple') || $value->isa('Data::URIID::Base')) {
                my $id = $value->as('Data::Identifier');
                my $generator = eval {$id->generator};
                my $request;

                if (defined($generator) && $generator->eq(_GENERATOR) && defined($request = $id->request(default => undef, no_defaults => 1))) {
                    $type = 'string';
                    $value = $request;
                } elsif (defined($generator) && ($generator->eq(_GENERATOR_UINTEGER) || $generator->eq(_GENERATOR_SINTEGER)) && defined($request = $id->request(default => undef, no_defaults => 1))) {
                    $type = 'number';
                    $value = $request;
                } else {
                    if (defined(my $o = $_registered_by_uuid{$id->uuid})) {
                        if (scalar @opts) {
                            $type = 'string';
                            $value = $o>as_string;
                            $self = $o;
                        } else {
                            return $o;
                        }
                    } else {
                        croak 'Unknown word (did you register it or a dictionary?): '.$value;
                    }
                }
            }
        } elsif ($value =~ /^(-?)(0|[1-9][0-9]*)\z/) {
            $type = 'number';
        } else {
            $type = 'string';
        }
    }

    if ($type eq 'number') {
        if ($value =~ /^(-?)(0|[1-9][0-9]*)\z/) {
            my ($neg, $val) = ($1, int($2));

            if ($val == 0) {
                $value = 'beba';
            } else {
                my @parts;

                while ($val) {
                    my $p = $val % 35;
                    $val = int($val / 35);

                    push(@parts, $_word_mora[$p]);
                }

                $value = 'be'.join('', reverse @parts);
                $value .= 'ub' if length $neg;
            }

            $type = 'string';
        } else {
            croak 'Bad number: '.$value;
        }
    }

    if ($type eq 'string') {
        $value = lc($value);

        $value =~ s/^([bfklmst][aeiou])$/to$1ik/;

        if ($value =~ /^[bfklmst][aeiou](?:[bfklmst][aeiou]|[aeiou][bfklmst])+\z/m) {
            my ($stem, $modifiers) = $value =~ /^((?:[bfklmst][aeiou])+)([aeiou][bfklmst].*)?\z/;

            if ($stem eq $value) {
                # This is a stem
                $self->{stem} = ':self';
            } else {
                $self->{stem} = $stem;
            }

            if (defined($modifiers)) {
                my %mod;
                my $plural;

                while (length($modifiers)) {
                    my $mod;

                    croak 'Invalid word: '.$value unless $modifiers =~ s/^([aeiou][bfklmst])//;
                    $mod = $1;

                    if ($mod eq 'ab') {
                        # plural
                        if ($modifiers =~ /^(?:[bfklmst][aeiou])*\z/) {
                            $plural = $mod.$modifiers;
                            $modifiers = '';
                        } else {
                            croak 'Unsupported plural: -ab'.$modifiers;
                        }
                    } elsif ($mod eq 'af' || $mod eq 'ef') {
                        croak 'Modifiers af/ef not supported: '.$value;
                    } else {
                        $mod{$mod} //= 0;
                        $mod{$mod}++;
                    }
                }

                $modifiers = '';
                $self->{modifiers} = {};
                foreach my $mod (sort keys %mod) {
                    $mod = $mod x $mod{$mod};
                    $self->{modifiers}{$mod} = undef;
                    $modifiers .= $mod;
                }

                if (defined($plural) && length($plural)) {
                    $self->{modifiers}{$plural} = undef;
                    $modifiers .= $plural;
                }

                $value = $stem.$modifiers;
            }

            $self = $_registered_by_string{$value} // $self;
            $self->{string} = $value;
        } else {
            croak 'Bad string: '.$value;
        }
    } else {
        croak 'Bad type: '.$type;
    }


    return $self;
}


sub combine {
    my ($pkg, $word, @parts) = @_;

    require Lingua::famibeib::Modifier;

    if (ref($pkg)) {
        unshift(@parts, $word);
        $word = $pkg;
        $pkg = __PACKAGE__;
    }

    $word = $pkg->new(from => $word);

    $_ = Lingua::famibeib::Modifier->new(from => $_) foreach @parts;

    unshift(@parts, $word->modifiers);
    $word = $word->stem;

    {
        my $plural;
        my %mod;

        foreach my $mod (@parts) {
            my $master_mora = $mod->master_mora;

            if ($master_mora eq 'ab') {
                $plural = $mod;
                next;
            } elsif ($master_mora eq 'eb') {
                delete $mod{ib};
            } elsif ($master_mora eq 'ib') {
                delete $mod{eb};

            } elsif ($master_mora eq 'if') {
                delete $mod{of};
            } elsif ($master_mora eq 'of') {
                delete $mod{if};

            } elsif ($master_mora eq 'ak') {
                delete $mod{ek};
            } elsif ($master_mora eq 'ek') {
                delete $mod{ak};

            } elsif ($master_mora eq 'ok') {
                delete $mod{uk};
            } elsif ($master_mora eq 'uk') {
                delete $mod{ok};
            }

            $mod{$master_mora} = $mod;
        }

        @parts = map {$mod{$_}->as_string} sort keys %mod;

        push(@parts, $plural->as_string) if defined $plural;
    }

    return $pkg->new(string => sprintf('%s%s', $word->as_string, join('', @parts)));
}


sub as_string {
    my ($self) = @_;
    return $self->{string};
}


sub as_number {
    my ($self) = @_;

    if ($self->as_string =~ /^be((?:[bfklmst][aeiou])+)((?:ub)?)\z/) {
        my ($mora, $neg) = ($1, $2);
        my $value = 0;

        while ($mora =~ /([bfklmst][aeiou])/g) {
            $value *= 35;
            $value += $_word_mora{$1};
        }

        return length($neg) ? -$value : $value;
    } elsif ($self->as_string =~ /^be/) {
        croak 'Not a simple number';
    } else {
        croak 'Not a number';
    }
}


sub stem {
    my ($self, @opts) = @_;
    my $stem = $self->{stem};

    croak 'Stray options passed' if scalar @opts;

    return $stem if ref $stem;
    return $self if $stem eq ':self';
    return $self->{stem} = __PACKAGE__->new(string => $stem);
}


sub modifiers {
    my ($self, @opts) = @_;
    my $modifiers = $self->{modifiers};

    croak 'Stray options passed' if scalar @opts;

    require Lingua::famibeib::Modifier;

    return map {$modifiers->{$_} //= Lingua::famibeib::Modifier->new(string => $_)} keys %{$modifiers};
}


sub get_modifier_by_master_mora {
    my ($self, $mora, %opts) = @_;
    my $has_default = exists $opts{default};
    my $default     = delete $opts{default};

    croak 'Stray options passed' if scalar keys %opts;

    require Lingua::famibeib::Modifier;

    $mora = Lingua::famibeib::Modifier->new(from => $mora)->master_mora;

    foreach my $modifier ($self->modifiers) {
        return $modifier if $mora eq $modifier->master_mora;
    }

    return $default if $has_default;

    croak 'No such modifier';
}


sub eq {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    return $self->as_string eq $other->as_string;
}


sub cmp {
    my ($self, $other, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return 1 if !defined($self) && !defined($other);
    return undef unless defined($self) && defined($other);

    $self  = __PACKAGE__->new(from => $self) unless eval {$self->isa(__PACKAGE__)};
    $other = __PACKAGE__->new(from => $other) unless eval {$other->isa(__PACKAGE__)};

    {
        my $stem_self = $self->stem;
        my $stem_other = $other->stem;

        if (!$self->eq($stem_self) || !$other->eq($stem_other)) {
            my $res = $stem_self->cmp($stem_other);

            return $res if $res != 0;
        }
    }

    {
        my $str_self  = $self->as_string;
        my $str_other = $other->as_string;

        return $str_self cmp $str_other;
    }

    croak 'BUG!';
}


sub is_verb {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return !!$self->get_modifier_by_master_mora('of', default => undef);
}


sub is_negative {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return !!$self->get_modifier_by_master_mora('ub', default => undef);
}


sub is_application {
    my ($self, @opts) = @_;

    croak 'Stray options passed' if scalar @opts;

    return !!$self->get_modifier_by_master_mora('ik', default => undef);
}


sub register {
    my ($self) = @_;

    $_registered_by_string{$self->as_string} //= $self;
    $_registered_by_uuid{$self->as('uuid')} //= $self;

    if (ref($self->{stem}) || $self->{stem} ne ':self') {
        $self->stem->register;
    }

    return $self;
}

# ---- Private helpers ----

sub as {
    my ($self, $as, @opts) = @_;
    my $id = $self->{id} //= do {
        require Data::Identifier::Generate;
        my $str = $self->as_string;

        Data::Identifier::Generate->generic(
            request => $str,
            displayname => $str,
            style => 'id-based',
            namespace => '10ce38bf-6238-4ed7-96ef-98ea9642a4c6',
            generator => _GENERATOR,
        )
    };

    return $id if $as eq 'Data::Identifier' && scalar(@opts) == 0;

    return $id->as($as, @opts);
}

sub displayname {
    my ($self, @opts) = @_;
    return $self->as_string if scalar(@opts) == 0;
    return $self->as('Data::Identifier')->displayname(@opts);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::Word - module to interact with the famibeib words

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use Lingua::famibeib::Word;

    my Lingua::famibeib::Word $word = Lingua::famibeib::Word->new(string => 'baba');

    my $str = $word->as_string;

This package is used to store individual famibeib words and query them about their properties.

This module inherits from L<Data::Identifier::Interface::Simple>, and L<Data::Identifier::Interface::Subobjects>.
Instances are overloaded so they will stringify to their string representation as per L</as_string>.

=head2 new

    my Lingua::famibeib::Word $word = Lingua::famibeib::Word->new($type => $value);
    # e.g:
    my Lingua::famibeib::Word $word = Lingua::famibeib::Word->new(string => $str);

(since v0.01)

Constructs a new word.
The word is normalised as part of this.
This method might deduplicate instances.
So not all instances might be new objects.
This is done to support working with large texts in an efficient manner.

Currently the following types (C<$type>) are supported:

=over

=item C<from>

(since v0.01)

Constructs a word from an object.
If the C<$value> should be a reference.

Currently references to the following types are supported:
L<Data::Identifier>,
L<Data::Identifier::Interface::Simple>,
L<Data::URIID::Base>,
and L<Lingua::famibeib::Word>.
More types might be supported.

If C<$value> is not a reference the value is parsed as per C<string> if it looks like a word string (experimental since v0.01).

=item C<string>

(since v0.01)

Constructs a word from it's string representation.

=item C<number>

(since v0.02)

Constructs a word from a number (must be an integer value).

=back

=head2 combine

    my Lingua::famibeib::Word $combined = $word->combine(@modifiers);
    # or:
    my Lingua::famibeib::Word $combined = Lingua::famibeib::Word->combine($word, @modifiers);

(experimental since v0.02)

Combines a word with modifiers. Returns the resulting new word.

This method tries to build new valid words, resolving any logical conflicts.
In order to do so the last given modifier always wins.

=head2 as_string

    my $str = $word->as_string;

(since v0.01)

Returns the string representation of the word.

=head2 as_number

    my $num = $word->as_number;

(since v0.02)

Returns the integer value of the word (or C<die> if none).
This works on simple numbers only.
Simple numbers are numbers with no modifiers (only a stem) or with the single modifier C<-ub> for negative.

To process more complex numbers (such as ordinals) process the modifiers individually and parse the value using
this method applied to the stem as returned by L</stem>.

=head2 stem

    my Lingua::famibeib::Word $stem = $word->stem;

(since v0.01)

Returns the stem of a word.
If this word is already a stem it returns itself.

=head2 modifiers

    my @modifiers = $word->modifiers;

(since v0.01)

Returns the list of the modifiers of the word.

B<Note:>
The list is not sorted in any way.

=head2 get_modifier_by_master_mora

    my Lingua::famibeib::Modifier $modifier = $word->get_modifier_by_master_mora($mora [, %opts]);

(experimental since v0.01)

Returns a modifier based on a master mora.
See L<Lingua::famibeib::Modifier/master_mora> for details.

Optionally the following options might be passed:

=over

=item C<default>

The default value to return if the modifier is not used.
This can be set to C<undef> to switch the method from C<die>ing to returning C<undef> if no such modifier is part of the word.

=back

=head2 eq

    my $bool = $word->eq($other); # $word must be non-undef
    # or:
    my $bool = Lingua::famibeib::Word::eq($word, $other); # $word can be undef

(since v0.01)

Compares two words to be equal.

If both words are C<undef> they are considered equal.

If C<$word> or C<$other> is not an instance of L<Lingua::famibeib::Word> or C<undef>
L</new> with the type C<from> is used.

The operators L<perlop/eq> and L<perlop/ne> are overloaded to this method.

=head2 cmp

    my $val = $word->cmp($other); # $word must be non-undef
    # or:
    my $val = Lingua::famibeib::Word::cmp($word, $other); # $word can be undef

(experimental since v0.01)

Compares the words similar to C<cmp>. This method can be used to order words.
To check for them to be equal see L</eq>.

The parameters are parsed the same way as L</eq>.

The operator L<perlop/cmp> is overloaded to this method.

If this method is used for sorting the exact resulting order is not defined. However:

=over

=item *

If the words differ in stems they are sorted by stem first

=item *

The order is stable

=item *

The order is the same for C<$a-E<gt>cmp($b)> as for C<- $b-E<gt>cmp($a)>.

=back

=head2 is_verb

    my $bool = $word->is_verb;

(since v0.01)

Returns true-ish if the current word is a verb or false-ish if it is not.

=head2 is_negative

    my $bool = $word->is_negative;

(since v0.01)

Returns true-ish if the current word is negative or false-ish if it is not.

=head2 is_application

    my $bool = $word->is_application;

(since v0.01)

Returns true-ish if the current word is in application form or false-ish if it is not.

=head2 register

    $word->register;

(since v0.01)

Registers the word with this module.
A registered word will be kept in memory indefinitely.
It is used for deduplication and some types of lookups.

This method will return C<$word>.
This can be used to build constants.

B<Note:>
Calling this multiple times on the same word is fine.
However, doing so might waste some time.

B<Note:>
If this word is not a stem itself it's stem is also registered.

B<Note:>
It is undefined (since v0.01) whether or not this will also register
the corresponding L<Data::Identifier>.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
