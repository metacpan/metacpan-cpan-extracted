package Lingua::EN::Inflexion::Term;

use 5.010; use warnings; use Carp;
no if $] >= 5.018, warnings => "experimental::smartmatch";

use Hash::Util 'fieldhash';

fieldhash my %term_of;

# Inside-out constructor...
sub new {
    my ($class, $term) = @_;

    my $object = bless do{ \my $scalar }, $class;

    $term_of{$object} = $term // croak "Missing arg to $class ctor";

    return $object;
}

# Replicate casing...
my $encase = sub {
    my ($original, $target) = @_;

    # Special case for 'I' <-> 'we'...
    return $target if $original =~ /\A(?:I|we)\Z/i;

    # Construct word-by-word case transformations...
    my @transforms
        = map { /\A[[:lower:][:^alpha:]]+\Z/            ? sub { lc shift }
              : /\A[[:upper:]][[:lower:][:^alpha:]]+\Z/ ? sub { ucfirst lc shift }
              : /\A[[:upper:][:^alpha:]]+\Z/            ? sub { uc shift }
              :                                           sub { shift }
              }
          split /\s+/, $original;

    if (!@transforms) {
        @transforms = sub {shift};
    }

    # Apply to target...
    $target =~ s{(\S+)}
                { my $transform = @transforms > 1 ? shift @transforms : $transforms[0];
                  $transform->($1);
                }xmseg;

    return $target;
};

# Report part-of-speech...
sub is_noun { 0 }
sub is_verb { 0 }
sub is_adj  { 0 }

# Default classical/unassimilated mode does nothing...
sub classical     { return shift; }
sub unassimilated { return shift->classical; }

# Coerce to original...
use Scalar::Util qw< refaddr blessed >;
use overload (
    q[qr]   => sub { return shift->as_regex();   },
    q[""]   => sub { return "$term_of{shift()}"; },
    q[0+]   => sub { return refaddr(shift);      },
    q[bool] => sub { return 1;                   },
    q[${}]  => sub { croak "Can't coerce ", ref(shift), ' object to scalar reference'; },
    q[@{}]  => sub { croak "Can't coerce ", ref(shift), ' object to array reference'; },
    q[%{}]  => sub { croak "Can't coerce ", ref(shift), ' object to hash reference'; },
    q[&{}]  => sub { croak "Can't coerce ", ref(shift), ' object to subroutine reference'; },
    q[*{}]  => sub { croak "Can't coerce ", ref(shift), ' object to typeglob reference'; },

    q[~~] => sub {
                my ($term, $other_arg) = @_;

                # Handle TERM ~~ TERM...
                if (blessed($other_arg) && $other_arg->isa(__PACKAGE__)) {
                    return lc($term->singular)          eq lc($other_arg->singular)
                        || lc($term->plural)            eq lc($other_arg->plural)
                        || lc($term->classical->plural) eq lc($other_arg->classical->plural);
                }

                # Otherwise just smartmatch against TERM as regex....
                else {
                    return $other_arg ~~ $term->as_regex;
                }
             },


    fallback => 1,
);

# Treat as regex...
sub as_regex {
    my ($self) = @_;
    my %seen;
    my $pattern = join '|', map { quotemeta } reverse sort grep { !$seen{$_}++ }
                  ($self->singular, $self->plural, $self->classical->plural);
    return qr{$pattern}i;
}


package Lingua::EN::Inflexion::Noun;
our @ISA = 'Lingua::EN::Inflexion::Term';

use Lingua::EN::Inflexion::Nouns;
use Lingua::EN::Inflexion::Indefinite;

# Report number of the noun...
sub is_plural   {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Nouns::is_plural( $term_of{$self} );
}

sub is_singular {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Nouns::is_singular( $term_of{$self} );
}

# Report part-of-speech...
sub is_noun { 1 }

# Return plural and singular forms of the noun...
sub plural   {
    my ($self) = @_;
    return $encase->(
        $term_of{$self},
        Lingua::EN::Inflexion::Nouns::convert_to_modern_plural( $term_of{$self} )
    );
}

sub singular {
    my ($self) = @_;
    return $encase->(
        $term_of{$self},
        Lingua::EN::Inflexion::Nouns::convert_to_singular( $term_of{$self} )
    );
}

sub indef_article {
    my ($self) = @_;

    return Lingua::EN::Inflexion::Indefinite::select_indefinite_article($self->singular);
}

sub indefinite {
    my ($self, $count) = @_;
    $count //= 1;

    if ($count == 1 ) {
        return Lingua::EN::Inflexion::Indefinite::prepend_indefinite_article($self->singular);
    }
    else {
        return "$count " . $self->plural;
    }
}

# Return a classical version of the term...
sub classical  { Lingua::EN::Inflexion::Noun::Classical->new(shift) }


package Lingua::EN::Inflexion::Noun::Classical;
our @ISA = 'Lingua::EN::Inflexion::Noun';

# Inside-out ctor expects a base-class object to clone...
sub new {
    my ($class, $orig_object) = @_;

    my $new_object = bless do{ \my $scalar }, $class;

    $term_of{$new_object} = $orig_object->singular;

    return $new_object;
}

# Already a classical noun, so this is now idempotent...
sub classical { return shift }

# Classical plurals are different...
sub plural {
    my ($self) = @_;
    return $encase->(
        $term_of{$self},
        Lingua::EN::Inflexion::Nouns::convert_to_classical_plural($term_of{$self})
    );
}


package Lingua::EN::Inflexion::Verb;
our @ISA = 'Lingua::EN::Inflexion::Term';

use Lingua::EN::Inflexion::Verbs;

# Utility sub that adjusts final consonants when they need to be doubled in inflexions...
my $truncate = sub {
    my ($term) = @_;

    # Apply the first relevant transform...
       $term =~ s{       ie \Z }{y}x
    or $term =~ s{       ue \Z }{u}x
    or $term =~ s{ ([auy])e \Z }{$1}x

    or $term =~ s{      ski \Z }{ski}x
    or $term =~ s{    [^b]i \Z }{}x

    or $term =~ s{ ([^e])e \Z }{$1}x

    or $term =~ m{ er \Z }x
    or $term =~ s{ (.[bdghklmnprstz][o]([n])) \Z }{$1}x

    or $term =~ s{ ([^aeiou][aeiouy]([bcdlgmnprstv])) \Z }{$1$2}x

    or $term =~ s{ e \Z }{}x;

    return $term;
};

# Report status of verb...
sub is_plural   {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_plural( $term_of{$self} );
}

sub is_singular {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_singular( $term_of{$self} );
}

sub is_present {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_present( $term_of{$self} );
}

sub is_past {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_past( $term_of{$self} );
}

sub is_pres_part {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_pres_part( $term_of{$self} );
}

sub is_past_part {
    my ($self) = @_;
    return Lingua::EN::Inflexion::Verbs::is_past_part( $term_of{$self} );
}

# Report part-of-speech...
sub is_verb { 1 }


# Conversions...

sub singular {
    my ($self) = @_;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_singular( $term_of{$self} );

    # Return with case-following...
    return $encase->( $term_of{$self}, $inflexion eq '_' ? $term_of{$self} : $inflexion );
}

sub plural {
    my ($self) = @_;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_plural( $term_of{$self} );

    # Return with case-following...
    return $encase->( $term_of{$self}, $inflexion eq '_' ? $term_of{$self} : $inflexion );
}

sub past {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past( $term );

    if ($inflexion eq '_') {
        $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past( $root );
    }

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ed';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub pres_part {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_pres_part( $root );

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ing';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub past_part {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $root = $self->plural;

    # Is it a known inflexion???
    my $inflexion = Lingua::EN::Inflexion::Verbs::convert_to_past_part( $root );

    # Otherwise use the standard pattern...
    if ($inflexion eq '_') {
        $inflexion = $truncate->($root) . 'ed';
    }

    # Return with case-following...
    return $encase->( $term, $inflexion );
}

sub indefinite {
    my ($self, $count) = @_;
    $count //= 1;

    return $count == 1 ? $self->singular
                       : $self->plural;
}


package Lingua::EN::Inflexion::Adjective;
our @ISA = 'Lingua::EN::Inflexion::Term';

# Load adjective tables, always taking first option...
my @adjectives = (
    # Determiners...
        'a'      =>  'some',
        'an'     =>  'some',

    # Demonstratives...
        'that'   =>  'those',
        'this'   =>  'these',

    # Possessives...
        'my'     =>  'our',
        'your'   =>  'your',
        'their'  =>  'their',
        'her'    =>  'their',
        'his'    =>  'their',
        'its'    =>  'their',
);

my (%adj_plural_of, %adj_singular_of, %adj_is_plural, %adj_is_singular);
while (my ($sing, $plur) = splice @adjectives, 0, 2) {
    $adj_is_singular{$sing}   = 1;
    $adj_singular_of{$plur} //= $sing;

    $adj_is_plural{$plur}   = 1;
    $adj_plural_of{$sing} //= $plur;
}


# Report part-of-speech...
sub is_adj { 1 }


# Report number of adjective...
sub is_plural   {
    my ($self) = @_;
    my $term = $term_of{$self};
    return $adj_is_plural{$term} || $adj_is_plural{lc $term}
        || !$adj_is_singular{$term} && !$adj_is_singular{lc $term};
}

sub is_singular   {
    my ($self) = @_;
    my $term = $term_of{$self};
    return $adj_is_singular{$term} || $adj_is_singular{lc $term}
        || !$adj_is_plural{$term} && !$adj_is_plural{lc $term};
}


# Conversions...

sub singular {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $singular = $term;;

    # Is it a possessive form???
    if ($term =~ m{ \A (.*) 's? \Z }ixms) {
        $singular = Lingua::EN::Inflexion::Noun->new($1)->singular . q{'s};
    }

    # Otherwise, it's either a known inflexion, or uninflected...
    else {
        $singular = $adj_singular_of{$term} // $adj_singular_of{lc $term} // $term;
    }

    return $encase->($term, $singular);
}

sub plural {
    my ($self) = @_;
    my $term = $term_of{$self};
    my $plural = $term;;

    # Is it a possessive form???
    if ($term =~ m{ \A (.*) 's? \Z }ixms) {
        $plural = Lingua::EN::Inflexion::Noun->new($1)->plural . q{'s};
        $plural =~ s{ s's \Z }{s'}xms
    }

    # Otherwise, it's either a known inflexion, or uninflected...
    else {
        $plural = $adj_plural_of{$term} // $adj_plural_of{lc $term} // $term;
    }

    return $encase->($term, $plural);
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lingua::EN::Inflexion::Term - Implements classes of LEI objects


=head1 VERSION

This document describes Lingua::EN::Inflexion::Term version 0.000001


=head1 DESCRIPTION

This module contains implementation code only.
See the documentation of Lingua::EN::Inflexion instead.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Damian Conway C<< <DCONWAY@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

