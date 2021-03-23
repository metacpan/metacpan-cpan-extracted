package main;

use 5.006002;

use strict;
use warnings;

use Test::More 0.96;	# Because of subtest();

note <<'EOD';

The tests were originally segregated into their own files because this
was the handiest way to segregate the tests of different functions. But
this causes fights over the clipboard when the tests are run in
parallel, resulting in test failures. Renaming the test files and then
just doing them seemed like the simplest way to serialize the whole
mess.

EOD

diag '';
foreach my $name ( qw{ LANG LC_ALL LC_COLLATE LC_CTYPE LC_MONETARY
    LC_NUMERIC LC_TIME LC_MESSAGES } ) {
    if ( defined $ENV{$name} ) {
	diag "$name='$ENV{$name}'";
    } else {
	diag "$name undefined";
    }
}
{
    local $@ = undef;
    eval {
	require I18N::Langinfo;
	diag q<I18N::Langinfo CODESET='>, I18N::Langinfo::langinfo(
	    I18N::Langinfo::CODESET() ), q<'>;
	1;
    } or diag 'I18N::Langinfo unavailable';
}

subtest 'Copy to clipboard' => sub {
    do './t/copy.tx';
};

subtest 'Error handling' => sub {
    do './t/error.tx';
};

subtest 'Miscellaneous' => sub {
    do './t/misc.tx';
};

subtest 'Paste from clipboard' => sub {
    do './t/paste.tx';
};

subtest 'Synch with clipboard' => sub {
    do './t/synch.tx';
};

done_testing;

1;

# ex: set textwidth=72 :
