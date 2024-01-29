use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Deep;
use Test::Exception;

my $class = 'Git::Lint::Config';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $raw_userconfig = "lint.profiles.commit.default Whitespace, IndentTabs, MixedIndentTabsSpaces, Flipdoozler\n" .
                         "lint.profiles.message.default BlankLineAfterSummary, BodyLineLength, SummaryLength\n" .
                         "lint.config.localdir /home/blaine/tmp/git-lint/lib\n";

    my $config_expected = {
        config => {
            localdir => '/home/blaine/tmp/git-lint/lib',
        },
        profiles => {
            commit => {
                default => [
                    'Whitespace',
                    'IndentTabs',
                    'MixedIndentTabsSpaces',
                    'Flipdoozler',
                ],
            },
            message => {
                default => [
                    'BlankLineAfterSummary',
                    'BodyLineLength',
                    'SummaryLength',
                ],
            },
        },
    };

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( $raw_userconfig, '', 0 ) },
    );

    my $object = bless {}, $class;
    my $config_returned;
    lives_ok( sub { $config_returned = $object->user_config() }, 'lives if no error status or error message' );
    cmp_deeply( $config_returned, $config_expected, 'returned config matches expected' );
}

NO_USER_CONFIG: {
    note( 'no user config' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', '', 1 ) },
    );

    my $object = bless {}, $class;
    dies_ok( sub { $object->user_config() }, 'dies if no user config is defined' );
    like( $@, qr/configuration setup is required\. see the documentation for instructions\./, 'exception string matches expected' );
}

GIT_CONFIG_ERROR: {
    note( 'git config error' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', 'git config error', 1 ) },
    );

    my $object = bless {}, $class;
    dies_ok( sub { $object->user_config() }, 'dies if error was returned from git config command' );
    like( $@, qr/git config error/, 'exception string matches expected' );
}

done_testing;
