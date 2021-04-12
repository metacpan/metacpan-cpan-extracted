use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;

TEST
{
    reset_handles();

    my $pid = $gnupg->wrap_call(
        gnupg_commands     => [qw( --delete-secret-keys )],
        gnupg_command_args => [qw( 0x93AFC4B1B0288A104996B44253AE596EF950DA9C )],
        handles            => $handles,
    );

    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};

TEST
{
    reset_handles();

    my $pid = $gnupg->wrap_call(
        gnupg_commands     => [qw( --delete-keys )],
        gnupg_command_args => [qw( 0x93AFC4B1B0288A104996B44253AE596EF950DA9C )],
        handles            => $handles,
    );

    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};

TEST
{
    reset_handles();

    my $pid = $gnupg->wrap_call(
        gnupg_commands     => [qw( --delete-secret-and-public-keys )],
        gnupg_command_args => [qw( 278F850AA702911F1318F0A61B913CE9B6747DDC )],
        handles            => $handles,
    );

    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};
