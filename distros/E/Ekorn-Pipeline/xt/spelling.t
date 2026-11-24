use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# The POD's spelling, checked as Minilla's own release test,
# xt/minilla/spelling.t, checks it as `minil dist` builds the tarball,
# so that a word it doesn't know fails CI on the push that brings it,
# not the release. Twice, a word in the manuals failed only at the
# release, after the tag was published: v0.3.8's was "setlist", and
# that version never reached CPAN. A word that's right but unknown goes
# in the stopwords of the file it's in: in docs/REFERENCE.md and
# docs/HOWTO.md, the <!-- stopwords: ... --> comment at the top, which
# scripts/manuals makes the manual's =for stopwords.
# CI's coverage job runs it, as it installs the cpanfile's develop
# modules, Test::Spellunker among them; elsewhere it's skipped without
# that module, saying so.


BEGIN {
    eval { require Test::Spellunker; Test::Spellunker->VERSION('v0.2.2') }
        or skip_all "Test::Spellunker v0.2.2 or later isn't installed";
    Test::Spellunker->import;
}

# As Minilla's test does: the distribution's name, and the stopwords in
# minil.toml, of which there are none.
add_stopwords('Ekorn-Pipeline');

all_pod_files_spelling_ok('lib');
