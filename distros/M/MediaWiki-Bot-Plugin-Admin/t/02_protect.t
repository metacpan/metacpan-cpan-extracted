#!perl
use strict;
use warnings;
use Test::More 0.96;
use MediaWiki::Bot;

my $username = $ENV{PWPAdminUsername};
my $password = $ENV{PWPAdminPassword};
my $host     = $ENV{PWPAdminHost};
my $path     = $ENV{PWPAdminPath};
plan $username && $password && $host
    ? (tests => 6)
    : (skip_all => 'test wiki and admin login required');

my $t = __FILE__;
my $summary = "MediaWiki::Bot::Plugin::Admin tests ($t)";

my $page         = "User:$username/02 protect.t";
my $cascade_page = "User:$username/02 protect.t (2)";

# Create bot objects to play with
my $admin = MediaWiki::Bot->new({
    # debug   => 2,
    agent   => $summary,
    host    => $host,
    ($path ? (path => $path) : ()),
    login_data => { username => $username, password => $password },
});
my $anon = MediaWiki::Bot->new({
    # debug   => 2,
    agent   => $summary,
    host    => $host,
    ($path ? (path => $path) : ()),
});

subtest q/Ensure test pages aren't protected/ => sub {
    plan tests => 2;
    foreach my $title ($page, $cascade_page) {
        if ( defined $anon->get_text($title) ) { # page exists, make sure it is unprotected
            $admin->unprotect($title, $summary);
        }
        else { # page doesn't exist; create it
            $admin->edit({ page => $title, text => $summary });
        }
        my $protected = $admin->get_protection($title);
        is($protected, undef, "[[$title]] isn't protected");
    }
};

subtest q/Make sure we can edit/ => sub {
    plan tests => 1;
    my $rand = rand();
    $admin->edit({
        page    => $page,
        text    => $rand,
        summary => $summary,
    });
    my $text = $admin->get_text($page);
    is($text, $rand, 'Successfully edited page');
};

subtest q/Protect the page/ => sub {
    plan tests => 3;
    $admin->protect($page, $summary, 'sysop', '', 'infinite');
    my $cmp_protection = [
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'cascade' => '',
            'type' => 'edit'
          }
        ];
    my $protection = $admin->get_protection($page);
    is_deeply($protection, $cmp_protection, 'Protection applied correctly');

    {   # Fail to edit it anonymously
        my $rand = rand();
        $anon->edit({ page => $page, text => $rand, summary => $summary });
        my $text = $admin->get_text($page);
        isnt($text, $rand, q{Shouldn't be able to edit anon});
    }

    {   # Successfully edit the page with a sysop account
        my $rand = rand();
        $admin->edit({ page => $page, text => $rand, summary => $summary });
        my $text = $admin->get_text($page);
        is($text, $rand, "Should be able to edit [[$page]] with sysop account");
    }
};

subtest q/Cascade-protect a test page/ => sub {
    plan tests => 4;
    $admin->protect(
        $cascade_page,
        $summary,
        'sysop', 'sysop', undef, 1 # edit, move, expiry, cascading
    );
    my $cmp_protection = [
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'cascade' => '',
            'type' => 'edit'
          },
          {
            'expiry' => 'infinity',
            'level' => 'sysop',
            'type' => 'move'
          }
        ];
    my $protection = $admin->get_protection($cascade_page);
    is_deeply($protection, $cmp_protection, "[[$cascade_page]] protected properly");

    {   # Transclude it into another
        my $rand = rand();
        $admin->edit({
            page    => $page,
            text    => $rand . "{{$cascade_page}}",
            summary => $summary,
        });
        my $text = $admin->get_text($page);
        like($text, qr/\Q{{$cascade_page}}\E/, 'Set cascading');
    }

    {   # Fail to edit a page transcluding a cascade-protected page anonymously
        my $rand = rand();
        $anon->edit({ page => $page, text => $rand, summary => $summary });
        my $text = $admin->get_text($page);
        isnt($text, $rand, q{Shouldn't be able to edit anon after setting cascading});
        is($text, $text,   q{Should be the same as before});
    }
};

subtest q/Remove protection and edit anonymously/ => sub {
    plan tests => 3;
    {
        $admin->unprotect($page, $summary);
        my $protection = $admin->get_protection($page);
        is($protection, undef, "[[$page]] no longer protected");
    }

    {
        $admin->unprotect($cascade_page, $summary);
        my $protection = $admin->get_protection($cascade_page);
        is($protection, undef, "[[$cascade_page]] no longer protected");
    }

    my $rand = rand();
    $anon->edit({ page => $page, text => $rand, summary => $summary });
    $admin->purge_page($page);
    my $text = $admin->get_text($page);
    is($text, $rand, 'Should be able to edit anon');
};

subtest q/Cleanup/ => sub {
    plan tests => 2;
    {
        $admin->unprotect($page, $summary);
        my $protection = $admin->get_protection($page);
        is($protection, undef, "[[$page]] no longer protected");
    }

    {
        $admin->unprotect($cascade_page, $summary);
        my $protection = $admin->get_protection($cascade_page);
        is($protection, undef, "[[$cascade_page]] no longer protected");
    }
};
