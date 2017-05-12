package Locale::ID::GuessGender::FromFirstName;

our $DATE = '2016-03-11'; # DATE
our $VERSION = '0.06'; # VERSION

use 5.010001;
use strict;
use warnings;
use experimental 'smartmatch';

my @known_algos = qw/common v1_rules google/;

use Locale::ID::GuessGender::FromFirstName::common;
use Locale::ID::GuessGender::FromFirstName::v1_rules;
use Locale::ID::GuessGender::FromFirstName::google;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(guess_gender);

sub guess_gender {
    my $opts;
    if (@_ && ref($_[0]) eq 'HASH') {
        $opts = shift;
    } else {
        $opts = {};
    }
    die "Please specify at least 1 name" unless @_;

    # preprocess names
    my @names;
    for (@_) {
        my $name = lc $_;
        $name =~ s/[^a-z]//g;
        die "Invalid first name `$_`" unless $name;
        push @names, $name;
    }

    $opts->{try_all} //= 0;
    $opts->{algos} //= [qw/common v1_rules/];
    $opts->{min_guess_confidence} //= 0.51;
    $opts->{algo_opts} //= {};

    my @res = map {
        {
            name => $names[$_],
            result => undef,
            algo => undef,
            algo_res => [],
        }
    } 0..$#names;
    my $i = 0;
    no strict 'refs';
    for my $algo (@{ $opts->{algos} }) {
        die "Unknown algoritm `$algo`, use one of: ".
            join(", ", @known_algos) unless $algo ~~ @known_algos;
        $i++;
        my $func = "Locale::ID::GuessGender::FromFirstName::".
            $algo . "::guess_gender";
        my $algo_opts = $opts->{algo_opts}{$algo} // {};
        my @algo_res = $func->($algo_opts,
                               map { ($opts->{try_all} || !$res[$_]{result}) ?
                                   $names[$_] : undef } 0..$#_);
        for (0..$#algo_res) {
            next unless $algo_res[$_];
            $algo_res[$_]{algo} = $algo;
            $algo_res[$_]{order} = $i;
            push @{ $res[$_]{algo_res} }, $algo_res[$_];
            if ($algo_res[$_]{success} &&
                $algo_res[$_]{guess_confidence} >= $opts->{min_guess_confidence} &&
                (!$res[$_]{result} || $res[$_]{guess_confidence} < $algo_res[$_]{guess_confidence})) {
                $res[$_]{result} = $algo_res[$_]{result};
                $res[$_]{gender_ratio} = $algo_res[$_]{gender_ratio};
                $res[$_]{guess_confidence} = $algo_res[$_]{guess_confidence};
                $res[$_]{algo} = $algo;
            }
        }
    }

    @res;
}

1;
# ABSTRACT: Guess gender of an Indonesian first name

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::ID::GuessGender::FromFirstName - Guess gender of an Indonesian first name

=head1 VERSION

This document describes version 0.06 of Locale::ID::GuessGender::FromFirstName (from Perl distribution Locale-ID-GuessGender-FromFirstName), released on 2016-03-11.

=head1 SYNOPSIS

 use Locale::ID::GuessGender::FromFirstName qw/guess_gender/;

 my @res = guess_gender("Budi"); # ({ name=>"budi", result=>"M",
                                 #   guess_confidence=>1,
                                 #   gender_ratio => 1, algo=>"common" })

 # specify more detailed options, guess several names at once
 my @res = guess_gender({min_guess_confidence => 0.75,
                         algos => [qw/common v1_rules google/]},
                         "amita", "mega");

=head1 DESCRIPTION

This module provides a function to guess the gender of commonly
encountered people's names in Indonesia, using several algorithms.

=head1 BUGS/TODOS

This is a preliminary release. List of common names is not very
complete. Heuristic rules are still too simplistic. Expect the
accuracy of this module to improve in subsequent releases.

=head1 FUNCTIONS

=head2 guess_gender([OPTS, ]FIRSTNAME...) => (RES, ...)

Guess the gender of given first name(s). An optional hashref OPTS can
be given as the first argument. Valid pair for OPTS:

=over 4

=item algos => [ALGO, ...]

Set the algorithms to use, in that order. Default is [qw/common
v1_rules/]. Known algorithms: B<common> (try to match from the list of
common names), B<v1_rules> (use some simple heuristics), B<google>
(compare the number of Google search results for "bapak FIRSTNAME" vs
"ibu FIRSTNAME").

The choice of algorithms can severely impact the result. For example,
"Mega" is actually pretty ambivalent, used by both females and
males. But Google search for "ibu mega" will return much more results
than "bapak mega", thus the B<google> algorithm will decide that
"Mega" is predominantly female.

=item min_guess_confidence => FRACTION

Minimum guess confidence level to accept an algorithm's guess as the
final answer, a number between 0 and 1. Default is 0.51 (51%).

=item try_all => BOOL

Whether to try all algorithms specified in B<algorithms>. Default is
0, which means stop trying after an algorithm succeeds to generate
guess with specified minimum guess confidence. If set to 1, all
algorithms will be tried and the best result used.

=item algo_opts => {ALGO => OPTS, ...}

Specify per-algorithm options. See the algorithm's documentation for
known options.

=back

Will return a result hashref RES for each given input. Known pair of
RES:

=over 4

=item result => "M" or "F" or "both" OR "neither" OR undef

The final guess result. undef if no algorithm succeeded. "M" if name
is predominantly male. "F" if name is predominantly female. "both" if
name is ambivalent. "neither" if sufficiently confident that the name
is not a person's name.

=item guess_confidence => FRACTION

The final guess confidence level.

=item gender_ratio => FRACTION

Estimation of gender ratio. 1 (100%) means the name is always used for
male or female. 0.9 (90%) means sometimes (about 10% of the time) the
name is also used for the opposite sex. If the gender ratio is close
to 0.5 it means the name is ambivalent and often used equally by males
and females.

=item algo => FRACTION

The algo that is used to get the final result.

=item algo_res => [RES, ...]

Per-algorithm result. Usually only useful for debugging.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Locale-ID-GuessGender-FromFirstName>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Locale-ID-GuessGender-FromFirstName>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Locale-ID-GuessGender-FromFirstName>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Locale::ID::ParseName::Person>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
