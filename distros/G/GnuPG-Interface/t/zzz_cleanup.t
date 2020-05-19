#!/usr/bin/perl -w

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;
use File::Path qw (remove_tree);

# this is actually no test, just cleanup.
TEST
{
    my $homedir = $gnupg->options->homedir();
    my $err = [];
    # kill off any long-lived gpg-agent, ignoring errors.
    # gpgconf versions < 2.1.11 do not support '--homedir', but still
    # respect the GNUPGHOME environment variable
    if ($gnupg->cmp_version($gnupg->version, '2.1') >= 0) {
        $ENV{'GNUPGHOME'} = $homedir;
        system('gpgconf', '--homedir', $homedir, '--quiet', '--kill', 'gpg-agent');
        delete $ENV{'GNUPGHOME'};
    }
    remove_tree($homedir, {error => \$err});
    unlink('test/gnupghome');
    return ! @$err;
};
