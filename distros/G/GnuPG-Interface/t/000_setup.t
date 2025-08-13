#!/usr/bin/perl -w

use strict;
use English qw( -no_match_vars );

use lib './t';
use MyTest;
use MyTestSpecific;
use Cwd;
use File::Path qw (make_path);
use File::Copy;

TEST
{
    my $homedir = $gnupg->options->homedir();
    make_path($homedir, { mode => 0700 });


    if ($gnupg->cmp_version($gnupg->version, '2.2') >= 0) {
        my $agentconf = IO::File->new( "> " . $homedir . "/gpg-agent.conf" );
        # Classic gpg can't use loopback pinentry programs like fake-pinentry.pl.
        $agentconf->write(
            "allow-preset-passphrase\n".
                "allow-loopback-pinentry\n".
                "pinentry-program " . getcwd() . "/test/fake-pinentry.pl\n"
            );
        $agentconf->close();

        my $error = system("gpg-connect-agent", "--homedir", "$homedir", '/bye');
        if ($error) {
            warn "gpg-connect-agent returned error : $error";
        }

        $error = system('gpg-connect-agent', "--homedir", "$homedir", 'reloadagent', '/bye');
        if ($error) {
            warn "gpg-connect-agent returned error : $error";
        }

        $error = system("gpg-agent", '--homedir', "$homedir");
        if ($error) {
            warn "gpg-agent returned error : $error";
        }

    }

    if ($gnupg->cmp_version($gnupg->version, '2.4') >= 0) {
        copy('test/gpg.conf', $homedir . '/gpg.conf');
    }
    else {
        copy('test/gpg1.conf', $homedir . '/gpg.conf');
    }

    reset_handles();

    my $pid = $gnupg->import_keys(command_args => [ 'test/public_keys.pgp', 'test/secret_keys.pgp', 'test/new_secret.pgp' ],
                                  options => [ 'batch'],
                                  handles => $handles);
    waitpid $pid, 0;

    return $CHILD_ERROR == 0;
};
