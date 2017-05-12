#! /usr/bin/env polyperl

use 5.010; use warnings;

use Lingua::EN::Grammarian ':all';
use Data::Dumper 'Dumper';

sub show {
    my $text = Dumper(@_);
    $text =~ s/^.{8}|;\s*$//g;
    return join q{ }, split /\s+/, $text;
}

my $TEXT;

for my $caution (extract_cautions_from $TEXT) {
    say "[" . $caution->match . "] from ", show($caution->from),
                                   " to ", show($caution->to);
    my $explanation = $caution->explanation;
    $explanation =~ s{^}{\t}gxms;
    say $explanation;
    say "\tConsider:";
    say "\t\t$_" for $caution->suggestions;
    say q{};
}

say '_' x 60;

for my $error (extract_errors_from $TEXT) {
    say "[$error] from ", show($error->from),
                 " to ", show($error->to);
    my $explanation = $error->explanation;
    $explanation =~ s{^}{\t}gxms;
    say $explanation;
    say "\tReplace wth:";
    say "\t\t$_" for $error->suggestions;
    say q{};
}

say show( get_coverage_stats() ); 


for my $index (7, 8, 11, 75, 295, 296, 300, 449, 505) {
    my $problem = get_error_at($TEXT,$index)
               // get_caution_at($TEXT,$index);

    if ($problem) {
        say "At index $index: '$problem' --> ", $problem->explanation;
    }
    else {
        say "No problems detected at index $index";
    }
}

BEGIN {
    $TEXT = <<'END_TEXT';
And so had began his tortuous experience, as he is be waited their
with baited breathe while the courtroom dramas we're unfolding.

He were sentenced after a summery judgement under a
RETROSPECTIVELY applied ordnance, using suspicious evidence. He
he had be given no chance to refute it, so he begun his interment. Where
upon he were subject to THE MOST UNIQUE and unspeakable horrors.

The he couldn't hardly believe it. Not only was he striped and kept
stationery in a prone position in a pit who's contents comprised of
leaches; his perverse tormentors were not reticent about to insisted he
better learn EMACS.

He have resisted and he sworn the experience would prove most fatal
the him. "I are innocent", he had say.

END_TEXT
}

__END__
