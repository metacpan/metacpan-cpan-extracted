#!/usr/bin/perl

use Test::More tests => 1;
use Lemonldap::NG::Portal;

SKIP: {
    my $p;
    eval 'use Test::Weaken qw(leaks)';
    if ($@) {
        skip 'Test::Weaken is not available', 1;
    }
    else {

        my $tester = Test::Weaken::leaks(
            {
                constructor => sub {
                    Lemonldap::NG::Portal::Simple->new(
                        {
                            globalStorage  => 'Apache::Session::File',
                            domain         => 'example.com',
                            authentication => 'LDAP test=1',
                            userDB         => 'LDAP test=1',
                            passwordDB     => 'LDAP test=1',
                            user           => '',
                            password       => '',
                        }
                    );
                },
                destructor => sub {
                    my $p = shift;
                    undef $p;
                    undef $Lemonldap::NG::Portal::SharedConf::confCached;
                },
            }
        );
        if ($tester) {
            my $unfreed_proberefs = $tester->unfreed_proberefs();
            my $unfreed_count     = @{$unfreed_proberefs};
            printf STDERR
              "Test 2: %d of %d original references were not freed\n",
              $tester->unfreed_count(), $tester->probe_count();
            print STDERR
              "These are the probe references to the unfreed objects:\n";
            require Data::Dumper;
            for my $ix ( 0 .. $#{$unfreed_proberefs} ) {
                print STDERR Data::Dumper->Dump( [ $unfreed_proberefs->[$ix] ],
                    ["unfreed_$ix"] );
            }
        }
        ok( !$tester );
    }
}
done_testing;
