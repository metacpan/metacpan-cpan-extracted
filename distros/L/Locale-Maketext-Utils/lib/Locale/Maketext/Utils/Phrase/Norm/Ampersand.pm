package Locale::Maketext::Utils::Phrase::Norm::Ampersand;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} =~ s{\[output,chr,(?:\&|38)\]}{[output,amp]}g ) {
        $filter->add_violation('Prefer [output,amp] over [output,chr,&] or [output,chr,38].');
    }
    if ( ${$string_sr} =~ s{chr\(&\)}{chr\(38\)}g ) {
        $filter->add_violation('Prefer chr(38) over chr(&).');
    }

    if ( ${$string_sr} =~ s{&}{[output,amp]}g ) {
        $filter->add_violation('Ampersands need done via [output,amp].');
    }

    my $aft = ${$string_sr} =~ s/\[output,amp\]([^ ])/[output,amp] $1/g;
    my $bef = ${$string_sr} =~ s/([^ ])\[output,amp\]/$1 [output,amp]/g;
    if ( $bef || $aft ) {
        $filter->add_violation('Ampersand should have one space before and/or after unless it is embedded in an asis().');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Do not use a raw ampersand even in output,chr. If used as text it needs to have a spaces around it.

=head2 Rationale

Same rationale as the L<Markup|Locale::Maketext::Utils::Phrase::Norm::Markup/Rationale>.

Since & is a markup character it must be done via output() in order to be safe in all contexts.

If it is used as a word it should have a space on each side of it for clarity.

=head1 IF YOU USE THIS FILTER ALSO USE …

… THIS FILTER L<Locale::Maketext::Utils::Phrase::Norm::Markup>.

This is not enforced anywhere since we want to assume the coder knows what they are doing.

=head1 possible violations

=over 4

=item Prefer [output,amp] over [output,chr,&] or [output,chr,38].

Problem should be self explanatory. The former gets replaced with the latter.

=item Prefer chr(38) over chr(&).

Problem should be self explanatory. The former gets replaced with the latter.

=item Ampersands need done via [output,amp].

Problem should be self explanatory. The former gets replaced with the latter.

=item Ampersand should have one space before and/or after unless it is embedded in an asis().

Problem should be self explanatory. Spaces get added as needed.

=back

=head1 possible warnings

None
