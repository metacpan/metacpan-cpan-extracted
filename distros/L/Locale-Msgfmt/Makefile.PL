use inc::Module::Install::DSL 0.92;

all_from      lib/Locale/Msgfmt.pm
requires      File::Spec 0.80
test_requires Test::More 0.47
test_requires Locale::Maketext::Gettext 1.28 if $ENV{AUTOMATED_TESTING}
no_index      directory private