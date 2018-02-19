use strict;
use warnings;

use Github::Backup;
use Test::More;

my $mod = 'Github::Backup';

{ # no params
    my $ok;

    $ok = eval { my $o = $mod->new; 1; };
    is $ok, undef, "we die if no params sent in";
    like $@, qr/mandatory/, "...and error is sane";

    $ok = eval { my $o = $mod->new(dir => 1, token => 1); 1; };
    is $ok, undef, "we die if no 'user' param sent in";
    like $@, qr/mandatory/, "...and error is sane";

    $ok = eval { my $o = $mod->new(api_user => 1, token => 1); 1; };
    is $ok, undef, "we die if no 'dir' param sent in";
    like $@, qr/mandatory/, "...and error is sane";

    $ok = eval { my $o = $mod->new(api_user => 1, dir => 1); 1; };
    is $ok, undef, "we die if no 'token' param sent in";
    like $@, qr/mandatory/, "...and error is sane";
}
{ # params

    my $o = $mod->new(
        api_user => 'stevieb9',
        token => 5,
        dir => '/tmp/gh_backup',
        proxy => 'http://10.0.0.4:80'
    );

    isa_ok $o, 'Github::Backup', "object is in proper class";
    is $o->user, 'stevieb9', "user() ok";
    is $o->token, 5, "token() ok";
    is $o->dir, '/tmp/gh_backup', "dir() ok";
}

done_testing();
