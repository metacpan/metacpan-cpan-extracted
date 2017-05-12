package Locale::Maketext::Utils::Phrase::Norm::Ellipsis;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # 1. placeholder for BN w/ empty string args: ',,'
    while ( ${$string_sr} =~ m/(\[.*?\])/g ) {    # see note about this regex in Consider.pm
        my $bn_match = $1;
        if ( $bn_match =~ m/[,]{2,}/ ) {
            my $bn_match_tmp = $bn_match;
            $bn_match_tmp =~ s/([,]{2,})/my $n=CORE::length("$1");"MULTI_COMMA_IN_BN_$n"/ge;
            ${$string_sr} =~ s/\Q$bn_match\E/$bn_match_tmp/;
        }
    }

    # 2. look for multi's
    if ( ${$string_sr} =~ s/(?:[.]{2,}|[,]{2,})/…/g ) {
        $filter->add_warning('multiple period/comma instead of ellipsis character');
    }

    # 3. restore placeholder
    ${$string_sr} =~ s/MULTI_COMMA_IN_BN_([0-9]+)/"," x "$1"/eg;

    # TODO: output,latin so this occurance is more rare:
    # if ( ${$string_sr} =~ s/([,.]{2,})/\[comment,should “$1” here be an ellipsis?\]/g ) {
    #     $filter->add_warning('multiple concurrent period and comma');
    # }

    if ( ${$string_sr} =~ s/^(|\xc2\xa0|\[output\,nbsp\])…/ …/ ) {
        $filter->add_warning('initial ellipsis should be preceded by a normal space');
    }

    # 1. placeholders for legit ones
    my %l;
    my $copy = ${$string_sr};
    if ( ${$string_sr} =~ s/((?:\x20|\xc2\xa0|\[output\,nbsp\])…[\!\?\.\:])$/ELLIPSIS_END/ ) {    # final
        $l{'ELLIPSIS_END'} = $1;
    }

    if ( ${$string_sr} =~ s/^( …(?:\x20|\xc2\xa0|\[output\,nbsp\]))/ELLIPSIS_START/ ) {           # initial
        $l{'ELLIPSIS_START'} = $1;
    }

    while ( ${$string_sr} =~ m/(\(|\x20|\xc2\xa0|\[output\,nbsp\])…(\)|\x20|\xc2\xa0|\[output\,nbsp\])/g ) {
        ${$string_sr} =~ s/(\(|\x20|\xc2\xa0|\[output\,nbsp\])…(\)|\x20|\xc2\xa0|\[output\,nbsp\])/ELLIPSIS_MEDIAL/;
        push @{ $l{'ELLIPSIS_MEDIAL'} }, [ $1, $2 ];
    }

    # 2. mark any remaining ones (that are not legit)
    if ( ${$string_sr} =~ s/\A …(?!\x20|\xc2\xa0|\[output\,nbsp\])/ … / ) {
        $filter->add_warning('initial ellipsis should be followed by a normal space or a non-break-space (in bracket notation or character form)');
    }

    if ( ${$string_sr} =~ s/…(?:\x20|\xc2\xa0|\[output\,nbsp\]|\s)+\z/…/ ) {
        $filter->add_warning('final ellipsis should be followed by a valid punctuation mark or nothing');
    }

    if ( ${$string_sr} =~ m/…\z/ && ${$string_sr} !~ m/(?:\x20|\xc2\xa0|\[output\,nbsp\])…\z/ ) {
        ${$string_sr} =~ s/…$/ …/;
        $filter->add_warning('final ellipsis should be preceded by a normal space or a non-break-space (in bracket notation or character form)');
    }

    my $medial_prob = 0;
    if ( ${$string_sr} =~ s/(.{1})((?:(?<!\x20)…|(?<!\xc2\xa0)…(?<!\[output\,nbsp\])…))(.{2})/$1 $2$3/g ) {
        $medial_prob++;
    }

    if ( ${$string_sr} =~ s/(.{2})…(?!\x20|\xc2\xa0|\[output\,nbsp\]|\z)(.{1})/$1… $2/g ) {
        $medial_prob++;
    }

    if ($medial_prob) {
        $filter->add_warning('medial ellipsis should be surrounded on each side by a parenthesis or normal space or a non-break-space (in bracket notation or character form)');
    }

    # 3. reconstruct the valid ones
    ${$string_sr} =~ s/ELLIPSIS_END/$l{'ELLIPSIS_END'}/     if exists $l{'ELLIPSIS_END'};
    ${$string_sr} =~ s/ELLIPSIS_START/$l{'ELLIPSIS_START'}/ if exists $l{'ELLIPSIS_START'};
    if ( exists $l{'ELLIPSIS_MEDIAL'} ) {
        for my $medial ( @{ $l{'ELLIPSIS_MEDIAL'} } ) {
            ${$string_sr} =~ s/ELLIPSIS_MEDIAL/$medial->[0]…$medial->[1]/;
        }
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

=over 4

=item * It must be an ellipsis character (OSX: ⌥;).

=item * It must be surrounded by valid whitespace …

=item *  … except for a trailing ellipsis.

=back

Valid whitespace is a normal space or a non-break-space (literal (OSX: ⌥space) or via [output,nbsp]).

The only exception is that the initial space has to be a normal space (non-break-space there would imply formatting or partial phrase, ick).

=head2 Rationale

We want to be simple, consistent, and clear.

=over 4

=item * CLDR has 3 simple location based rules:

  initial:…{0}
  medial:{0}…{1}
  final:{0}…

Yet, English provides many more rules based on location in the text, purpose (show an omission, indicate a trailing off for various purposes), context (puntuation before or after?), and author’s whim.

Some are exact opposites and yet still valid either way.

So lets keep it simple.

=item * We are unlikely to be omitting things from a quote:

   The server said, “PHP […] is like training wheels without the bike.”.

Can be added later if necessary.

=item * We are unlikely to be implying a continuing thought:

   What can you do, you know how he is ….

Even if we were this form is still valid. So lets keep it consistent.

=item * We are not writing literature.

So lets keep it simple.

=item * The CLDR version leaves room for ambiguity:

   I drove the car…

Is that the first part of “I drove the car to the store.” or “I drove the carpet home and installed it.”?

So lets keep it clear.

=back

Tip: If you’re doing a single word(e.g. to indicate an action is happening) you might consider doing a non-break-space to the left of it:

    'Loading …' # i.e. Loading(OSX: ⌥-space)…

    'Loading[output,nbsp]…' # visually explicit

=head1 possible violations

None

=head1 possible warnings

=over 4

=item multiple period/comma instead of ellipsis character

We want an ellipsis character instead of 3 periods (or 2 periods, 4 or 5 periods, or commas (yes I’ve seen translators do ‘..’, ‘,,,,’, etc and after inquiring ‘…’ was the correct syntax)).

These will be turned into an ellipsis character.

=item initial ellipsis should be preceded by a normal space

The string is modified with a corrected version.

=item initial ellipsis should be followed by a normal space or a non-break-space (in bracket notation or character form)

The string is modified with a corrected version.

=item final ellipsis should be preceded by a normal space or a non-break-space (in bracket notation or character form)

The string is modified with a corrected version.

=item final ellipsis should be followed by a valid punctuation mark or nothing

The string is modified with a corrected version.

=item medial ellipsis should be surrounded on each side by a parenthesis or normal space or a non-break-space (in bracket notation or character form)

The string is modified with a corrected version.

=back
