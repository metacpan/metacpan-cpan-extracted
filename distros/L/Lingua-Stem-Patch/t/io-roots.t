use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 34;
use Lingua::Stem::Patch::IO qw( stem stem_aggressive );

sub is_stem {
    my ($word, $stem, $description) = @_;

    is stem($word),            $stem, "$description (light)";
    is stem_aggressive($word), $stem, "$description (aggressive)";
}

# standalone roots
for my $word (qw{ la li lu me ni su tu vi vu }) {
    is_stem($word, $word, 'protected root');
}

# personal pronouns: full to short form
for my $word (qw{ el il ol on }) {
    is_stem($word,       $word, 'personal pronoun: short form');
    is_stem($word . 'u', $word, 'personal pronoun: full form');
}
