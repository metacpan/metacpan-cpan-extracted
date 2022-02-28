use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Deep;

my $class = 'Git::Lint::Config';
use_ok( $class );

Git::Lint::Test::override(
    package => 'Module::Loader',
    name    => 'find_modules',
    subref  => sub {
                   my $self      = shift;
                   my $namespace = shift;

                   return (
                       $namespace eq 'Git::Lint::Check::Commit' ?
                           qw( Git::Lint::Check::Commit::One Git::Lint::Check::Commit::Two )
                         : qw( Git::Lint::Check::Message::One Git::Lint::Check::Message::Two )
                   )
    },
);

HAPPY_PATH: {
    note( 'happy path' );

    # user config will return nothing to parse
    Git::Lint::Test::override(
        package => 'Git::Lint::Config',
        name    => 'user_config',
        subref  => sub { return {} },
    );

    my $object = $class->load();

    my $expected = {
        profiles => {
            commit => {
                default => [ 'One', 'Two' ],
            },
            message => {
                default => [ 'One', 'Two' ],
            },
        },
    };
    bless $expected, 'Git::Lint::Config';
    cmp_deeply( $object, $expected, 'default config contains default' );
}

USER_ADD: {
    note( 'user add' );

    # user config will add but not override
    my $expected = {
        profiles => {
            commit => {
                default => [ 'One', 'Two' ],
                shoe => [ 'Gaze' ],
            },
            message => {
                default => [ 'One', 'Two' ],
            },
        },
    };
    my $user_config = { profiles => { commit => { shoe => [ 'Gaze' ] } } };
    Git::Lint::Test::override(
        package => 'Git::Lint::Config',
        name    => 'user_config',
        subref  => sub { return $user_config },
    );

    my $object = $class->load();
    bless $expected, 'Git::Lint::Config';
    cmp_deeply( $object, $expected, 'default config contains default and user adds' );
}

USER_OVERRIDE_AND_ADD: {
    note( 'user override and add' );

    # user config will override everything in default
    my $expected = {
        profiles => {
            commit => {
                default => [ 'Three' ],
                shoe => [ 'Gaze' ],
            },
            message => {
                default => [ 'One', 'Two' ],
            },
        },
    };

    Git::Lint::Test::override(
        package => 'Git::Lint::Config',
        name    => 'user_config',
        subref  => sub { return $expected },
    );

    my $object = $class->load();
    bless $expected, 'Git::Lint::Config';
    cmp_deeply( $object, $expected, 'user config overrides default and adds' );
}

done_testing;
