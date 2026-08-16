# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module to generate proper famibeib names


package Lingua::famibeib::NameGenerator;

use v5.16;
use strict;
use warnings;

use Carp;
use Digest::SHA3;
use Lingua::famibeib::Word;

our $VERSION = v0.07;

my @_word_mora = qw(
    ba be bi bo bu
    fa fe fi fo fu
    ka ke ki ko ku
    la le li lo lu
    ma me mi mo mu
    sa se si so su
    ta te ti to tu
);

my %_static_length_probabilities = (
    1 => 0.01,
    2 => 0.10,
    3 => 0.80,
    4 => 0.40,
    5 => 0.10,
);

my %_static_key_factors = (
    (map {$_ => 0.5} qw(species family tribe)),
    (map {$_ => 1.0} qw(email realname nickname username name user tag)),
);


#@returns Lingua::famibeib::Word
sub generate {
    my ($pkg, %opts) = @_;
    my $digest  = Digest::SHA3->new(384);
    my $minlen  = delete($opts{minlength}) // $opts{length} // 3;
    my $maxlen  = delete($opts{maxlength}) // $opts{length} // 6;
    my $counter = $opts{counter} // 0;
    my $retry   = $opts{retry};
    my $last    = $opts{last};
    my @rands;
    my %letters;
    my %strings;
    my %mora = map {$_ => 0} @_word_mora;
    my $length;

    $counter++;
    $counter = 1/($counter**.5);

    delete $opts{length};

    if (delete $opts{random}) {
        my $random = $pkg->_random;
        $digest->add(sprintf(':random%u*=%s', length($random), $random));
    }

    foreach my $key (qw(seed retry counter last sex_or_gender species family tribe email realname nickname username name subjecttype user tag)) {
        my $v = delete($opts{$key}) // next;
        my $ref = ref($v) // '';
        my $displayname;
        my $str;

        if ($ref) {
            if ($v->isa('Data::Identifier') || $v->isa('Data::Identifier::Interface::Simple')) {
                $str = $v->ise;
                $displayname = $v->displayname(default => undef, no_defaults => 1);
            } else {
                croak 'Unsupported object: '.$v;
            }
        } else {
            $str = $v;
            $displayname = $v;
        }

        $str = sprintf(':%s%u%s=%s', $key, length($str), $ref, $str);
        $digest->add($str);
        #say $str;

        if (defined(my $factor = $_static_key_factors{$key})) {
            $factor *= $counter;
            if (defined($displayname) && length($displayname)) {
                $displayname =~ s/\@.*\z//;

                $displayname = lc($displayname);

                unless (exists $strings{$factor.'-'.$displayname}) {
                    $strings{$factor.'-'.$displayname} = undef;

                    foreach my $c (split //, $displayname) { # we use lc() not fc() as famibeib in normal form is lower-case.
                        $letters{$c} //= 0;
                        $letters{$c} += $factor;
                    }

                    foreach my $mora (@_word_mora) {
                        my $c = () = $displayname =~ /\Q$mora/g;
                        $mora{$mora} += $factor*$c;
                    }
                }
            }
        }
    }

    croak 'Stray options passed' if scalar keys %opts;
    croak 'Bad length' if $minlen > $maxlen || $minlen < 2 || $maxlen > 9;
    # Correct given the prefix.
    $minlen--;
    $maxlen--;

    @rands = unpack('C*', $digest->digest);
    #say '[', join(', ', @rands), ']';

    foreach my $mora (@_word_mora) {
        my ($x, $y) = $mora =~ /^(.)(.)\z/;

        $mora{$mora} = (((($letters{$x} // 0)**2 + ($letters{$y} // 0)**2)**.25)/2) + sqrt($mora{$mora}/8) + (shift(@rands)/256);
    }

    {
        my %lens = map {$_ => (shift(@rands)/256) * ($_static_length_probabilities{$_} // 0.01)} $minlen .. $maxlen;
        $length = int((sort {$lens{$a} <=> $lens{$b} || $a <=> $b} keys %lens)[-1]);
    }

    #use Data::Dumper;
    #warn Dumper(\@rands, \%mora);

    {
        my $res = 'ta';

        for (; $length; $length--) {
            my $m = (sort {$mora{$a} <=> $mora{$b} || $a cmp $b} keys %mora)[-1];
            $res .= $m;
            $mora{$m} *= 0.8;
            $mora{$m} -= 0.3;
        }

        #warn Dumper(\@rands, \%mora);
        $res = Lingua::famibeib::Word->new(string => $res);

        if (defined $last) {
            $last = Lingua::famibeib::Word->new(from => $last); # enforce a valid word
            if ($last->eq($res)) {
                # Same as last, we need to retry:
                croak 'Double collision error. You broke the universe. Please retry with a new big-bang.' if $retry;
                return __SUB__->(@_, retry => ($retry // 0) + 1);
            }
        }

        return $res;
    }
}

# ---- Private helpers ----

sub _random {
    state $prefix = sprintf('%s.%s', $$, $^T);
    state $count = 0;

    return sprintf('%s/%u/%u/%s', $prefix, $count++, time(), rand());
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::famibeib::NameGenerator - module to generate proper famibeib names

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use Lingua::famibeib::NameGenerator;

    my Lingua::famibeib::Word $name = Lingua::famibeib::NameGenerator->generate(...);

(since v0.04)

This package is used to generate proper famibeib names (C<ta->).

=head1 METHODS

=head2 generate

    my Lingua::famibeib::Word $name = Lingua::famibeib::NameGenerator->generate(%opts);

Generates a proper name based on the passed options.

This method tries to match the output to the input as best as it can.
Hence it is slower than just a random string generator.

Unless C<random> (see below) is passed, the output is also fully stable for any given version of this module.
This means, that if you call this method again with the same inputs it will result in the same output (as long as the same version is used).

It returns the name as a L<Lingua::famibeib::Word>.

The following (all optional) options are supported:

=over

=item C<counter>

The counter for the given request (if any).
This can be used together with C<last> to break loops of repeating names when generating multiple names.

Generally one would set this to 0 for the first request, with C<last> being C<undef>.
For the second request this would be 1, and C<last> would be the result of the first call and so on.

=item C<email>

An e-mail address of the person.

=item C<family>

The name of the family of the person.
Can be a plain name, or a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.

=item C<last>

The result of the last call to this method.
This can be used to generate more results for the same inputs to allow the user to select one.

See also C<counter>.

=item C<length>

The length in mora to generate.
This value is the default for C<maxlength>, and C<minlength>.

=item C<maxlength>

The maximum length in mora to use for generated names.

=item C<minlength>

The minimum length in mora to use for generated names.

=item C<name>

A name for the entity in any other language.
This can be used if none of the more specific options fit: C<email>, C<nickname>, C<realname>, C<username>.
Can be a plain name, or a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.

=item C<nickname>

A nick name, any name the entity is called by.
Can be a plain name, or a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.

=item C<random>

If set to a true-ish value this method will add some (low quality) random value to the generator.
This is useful when no information about the entity is known.
This also means that the results will not be the same for two calls with the same parameters.

See also C<seed>.

=item C<realname>

The real name (legal name) of a entity.
Can be a plain name, or a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.

=item C<seed>

A seed that is added to the generator. It can be used as an alternatives to C<random> when a result not bound to the entity is wanted
(or no such data is available), but still a deterministic result is wanted.

If this is a floating point value it is converted to a string in some way.
Different versions of this module and/or of perl, or the machine this runs on can result in different results.

=item C<sex_or_gender>

The sex or gender of the entity.
Should be a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
This method might try to match sexes/genders internally.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=item C<species>

The species of the entity.
Should be a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
This method might try to match species internally.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=item C<subjecttype>

The primary subject-type (C<has-type>) of the entity.
This should be a L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=item C<tag>

The tag of the entity.
This should be a L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=item C<tribe>

The tribe of the entity. Takes the same values as C<family>.

=item C<user>

The user object for this entity.
This should be a L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=item C<username>

The username for this entity.
Can be a plain name, or a L<Lingua::famibeib::Word> or L<Data::Identifier> or any L<Data::Identifier::Interface::Simple>.
Note that L<Data::TagDB::Tag> implements L<Data::Identifier::Interface::Simple> and can therefore be used.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
