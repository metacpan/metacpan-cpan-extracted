requires 'perl', '5.014';

# The house object system, and the keys, the screen and the picker. Digest::SHA
# is core and is all the deal needs.
requires 'Object::Proto::Sugar', '0.05';
requires 'Game::Terminal::Kit', '0.05';

recommends 'Term::ReadKey', '0';

on test => sub {
    requires 'Test::More', '0';
};

on develop => sub {
    # Without these the author tests SKIP, which is worse than failing: a
    # skipped check is one nobody notices is not running. Game-Gin shipped
    # t/manifest.t for three phases while MANIFEST was missing half the
    # distribution, because Test::CheckManifest was not installed.
    requires 'Test::Pod', '1.22';
    requires 'Test::Pod::Coverage', '1.08';
    requires 'Test::CheckManifest', '0.9';
};
