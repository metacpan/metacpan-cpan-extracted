# -*- Perl -*-
#
# Parser::MGC subclass that parses awkword patterns into a data structure

package Lingua::Awkwords::Parser;

use strict;
use warnings;

use parent qw( Parser::MGC );

use Lingua::Awkwords::ListOf;
use Lingua::Awkwords::OneOf;
use Lingua::Awkwords::String;
use Lingua::Awkwords::Subpattern;

our $VERSION = '0.09';

sub parse {
    my $self = shift;
    my $unit = $self->_parse_unit;

    my $filters =
      $self->sequence_of(sub { $self->expect('^'); $self->_parse_filter });
    $unit->add_filters(@$filters) if @$filters;

    return $unit;
}

# filters exclude strings from previous units
sub _parse_filter {
    my $self = shift;

    my $filter = '';

    1 while $self->any_of(
        # NOTE code for these duplicted from the unit parse
        sub {
            $filter .= ($self->expect(qr/"([^"]*)"/))[-1];
            1;
        },
        sub {
            $filter .= $self->generic_token('other', qr{[^ "A-Z\(\)\[\]/\*\^]+});
            1;
        },
        sub {
            0;
        }
    );

    return $filter;
}

# units, which might be a ::ListOf choices [VV] or ::OneOf [a/b] or both
# [VV/CV] or neither [asdf]. units can also contain other units
sub _parse_unit {
    my $self = shift;

    my ($oneof, $weight);
    my @terms = '';

    1 while $self->any_of(
        sub {
            $self->expect('*');

            # NOTE original version instead treats [a*10*20/b] as a
            # weight of 1020 then reduces that to 128 (with a warning)
            # as of 0.06 upper limit removed from this implementation
            $self->fail("weight already set") if $weight;

            my $num = $self->token_int;
            $self->fail("weight must be positive integer") if $num < 1;
            $weight = $num;
            1;
        },
        sub {
            $self->expect('/');

            $oneof = Lingua::Awkwords::OneOf->new if !defined $oneof;

            for my $term (@terms) {
                # TODO cache these strings so only one obj instance per str?
                $term = Lingua::Awkwords::String->new(string => $term) if !ref $term;
            }
            $oneof->add_choice(Lingua::Awkwords::ListOf->new(terms => [@terms]), $weight);

            # empty string here is so [a/] parses correctly as a choice
            # between a and nothing instead of dropping out of the unit
            # upon ]
            undef $weight;
            @terms = '';
            1;
        },
        sub {
            # recurse into sub-units [...] or (...)
            my $delim = $self->expect(qr/[ \[\( ]/x);
            $delim =~ tr/[(/])/;

            my $ret = $self->scope_of(undef, \&_parse_unit, $delim);
            if ($terms[-1] eq '') {
                $terms[-1] = $ret;
            } else {
                push @terms, $ret;
            }

            # () needs additional code as (a) is equivalent to [a/] so
            # we must add an empty string to what must become a oneof
            if ($delim eq ')') {
                my $newof;
                unless ($terms[-1]->can('add_choice')) {
                    $newof = Lingua::Awkwords::OneOf->new;
                    $newof->add_choice($terms[-1]);
                    $terms[-1] = $newof;
                } else {
                    $newof = $terms[-1];
                }

                # TODO cache this string in a hash so only one obj?
                $newof->add_choice(Lingua::Awkwords::String->new(string => ''));
            }

            # filters in [VV]^aa form (as opposed to the top-level
            # parse() VV^aa form which lack the trailing ] or ) of this
            # code path
            $self->maybe(
                sub {
                    my $filters =
                      $self->sequence_of(sub { $self->expect('^'); $self->_parse_filter });
                    $terms[-1]->add_filters(@$filters) if @$filters;
                }
            );
            1;
        },
        sub {
            my $pat = $self->generic_token('subpattern', qr{[A-Z]});
            $self->fail("not a defined pattern")
              if !Lingua::Awkwords::Subpattern->is_pattern($pat);

            my $ret = Lingua::Awkwords::Subpattern->new(pattern => $pat);
            if ($terms[-1] eq '') {
                $terms[-1] = $ret;
            } else {
                push @terms, $ret;
            }
            1;
        },
        # NOTE code from these two also used in _parse_filter
        sub {
            my $ret = ($self->expect(qr/"([^"]*)"/))[-1];
            if (ref $terms[-1]) {
                push @terms, $ret;
            } else {
                $terms[-1] .= $ret;
            }
            1;
        },
        sub {
            my $ret = $self->generic_token('other', qr{[^ "A-Z\(\)\[\]/\*\^]+});
            if (ref $terms[-1]) {
                push @terms, $ret;
            } else {
                $terms[-1] .= $ret;
            }
            1;
        },
        sub {
            0;
        }
    );

    for my $term (@terms) {
        # TODO cache these strings so only one obj instance per str?
        $term = Lingua::Awkwords::String->new(string => $term) if !ref $term;
    }

    if (defined $oneof) {
        $oneof->add_choice(Lingua::Awkwords::ListOf->new(terms => [@terms]), $weight);
        return $oneof;
    } else {
        return Lingua::Awkwords::ListOf->new(terms => \@terms);
    }
}

1;
__END__

=head1 NAME

Lingua::Awkwords::Parser - parser for awkwords

=head1 SYNOPSIS

  my $parser = Lingua::Awkwords::Parser->new;
  my $tree   = $parser->from_string(q{ [VV]^aa });

=head1 DESCRIPTION

L<Parser::MGC> subclass that parses awkword patterns. This module
will typically be called from L<Lingua::Awkwords>, so need not be
used directly.

The specification this code is based on can be found at

http://akana.conlang.org/tools/awkwords/help.html

though there are differences between this code and the implementation
associated with the above documentation; some of these differences are
listed as Known Issues; see also comments in the code and the unit tests
under the C<t/> directory of the distribution of this module.

=head1 METHODS

=over 4

=item B<parse>

Entry point for L<Parser::MGC>; returns the parsed pattern or fails
trying. Code that uses this module will likely instead use the B<new>,
B<from_string>, B<from_file> methods imported from L<Parser::MGC>.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-lingua-awkwords at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Awkwords>.

Patches might best be applied towards:

L<https://github.com/thrig/Lingua-Awkwords>

=head2 Known Issues

There are known (and doubtless various unknown) incompatibilities with
the parser of the original code (the online PHP version). In particular,

=over 4

=item *

A filter of C<[VV]^a"a"> in the online version does not filter out C<aa>
from the results as of August 2017, though the documentation indicates
that it should.

=item *

Filters differ in other ways; the online version filters out C<aa> if
given C<[VV]^aa> but not given C<VV^aa>, though otherwise does treat
C<VV> the same as C<[VV]>.

=item *

C<[a*10*20/b]> in the original code parses as a weight of C<1020> which
is then (with a warning) reduced to the maximum C<128>. This
implementation instead throws an error if multiple weights are parsed,
and accepts any (supported by perl) integer above 128.

=back

=head1 SEE ALSO

L<Lingua::Awkwords>

L<Lingua::Awkwords::ListOf>, L<Lingua::Awkwords::OneOf>,
L<Lingua::Awkwords::String>, L<Lingua::Awkwords::Subpattern>

L<Parser::MGC>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
