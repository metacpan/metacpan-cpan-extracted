use strict;
use Test::More tests => 64;
#use Test::More qw(no_plan);

require MIME::Expander; # don't "use" for import tests

# import
{;
    is_deeply( \ @MIME::Expander::EnabledPlugins, [], 'EnabledPlugins default');

    MIME::Expander->import(qw/ApplicationTar ApplicationZip/);
    is_deeply( \ @MIME::Expander::EnabledPlugins,
        [qw/ApplicationTar ApplicationZip/], 'import EnabledPlugins');

    @MIME::Expander::EnabledPlugins = (); # reset
}

# new
{;
    my $me = MIME::Expander->new;
    isa_ok($me, 'MIME::Expander');
}

# init
{;
    my $me = MIME::Expander->new;

    is( "@{[$me->init]}", "$me", 'init returns own' );

    $me->init( depth => 5 );
    is( $me->depth, 5, 'init accepts hash' );

    $me->init( { depth => 1 } );
    is( $me->depth, 1, 'init accepts ref hash' );

    $me->init;
    is( $me->depth, undef, 'init resets' );
}

# expects
{;
    my $me = MIME::Expander->new;

    is_deeply( $me->expects, [], 'expects default empty');

    is_deeply( $me->expects(['a','b']), ['a','b'], 'expects received ref array');

    eval { $me->expects('scalar') };
    ok( $@, 'excepts received invalid value' );

    eval { $me->expects(undef) };
    ok( ! $@, 'excepts allows undef');
    is( $me->expects, undef, 'excepts received undef');
}

# is_expected
{;
    my $me = MIME::Expander->new({
        expects => [qw(text/plain image/jpeg application/tar)] });
    ok(   $me->is_expected('text/plain'), 'is_expected text/plain');
    ok(   $me->is_expected('image/jpeg'), 'is_expected image/jpeg');
    ok(   $me->is_expected('application/tar'), 'is_expected application/tar');
    ok( ! $me->is_expected('text/xml'), 'is_expected not text/xml');
    ok( ! $me->is_expected('image/jpg'), 'is_expected not image/jpg');
    eval { $me->is_expected('image') };
    ok( $@, 'is_expected receives invalid type');
    
    $me->expects(undef);
    ok( ! $me->is_expected('text/plain'), 'no is_expected text/plain');
    ok( ! $me->is_expected('image/jpeg'), 'no is_expected image/jpeg');
    ok( ! $me->is_expected('application/tar'), 'no is_expected application/tar');
    ok( ! $me->is_expected('text/xml'), 'no is_expected not text/xml');
    ok( ! $me->is_expected('image/jpg'), 'no is_expected not image/jpg');

    $me->expects([qr/text/, 'application/.*']);
    ok(   $me->is_expected('text/plain'), 'is_expected text/plain matches text');
    ok( ! $me->is_expected('image/jpeg'), 'is_expected image/jpeg no matches');
    ok(   $me->is_expected('application/tar'), 'is_expected application/tar matches application/.*');
    ok(   $me->is_expected('text/xml'), 'is_expected text/xml matches text');
    ok( ! $me->is_expected('image/jpg'), 'is_expected image/jpg no matches');
}

# depth
{;
    my $me = MIME::Expander->new;

    is( $me->depth, undef, 'depth default');
    
    is( $me->depth(2), 2, 'depth set 2');
    is( $me->depth, 2, 'depth get 2');

    $me->depth(undef);
    is( $me->depth, undef, 'depth allows undef');

    eval { $me->depth('string') };
    ok( $@, 'depth received invalid value');
}

# guesser
{;
    my $me = MIME::Expander->new;
    my $v;

    is( $me->guesser, undef, 'guesser default');

    $v = $me->guesser(['FileName','MMagic']);
    is( ref($v), 'ARRAY', 'guesser set list');
    $v = $me->guesser;
    is( ref($v), 'ARRAY', 'guesser get');
    is_deeply( $v, ['FileName','MMagic'], 'expects get list is expected');

    $v = $me->guesser(sub {'yes'});
    is( ref($v), 'CODE', 'guesser set code');
    $v = $me->guesser;
    is( ref($v), 'CODE', 'guesser get');
    is( $v->(), 'yes', 'guesser get code is expected');

    $me->depth(undef);
    is( $me->depth, undef, 'guesser allows undef');

    eval { $me->guesser('Guess') };
    ok( $@, 'guesser received invalid value');
}

# guess_type_of
{;
    my $me = MIME::Expander->new;
    
    # default routine
    is( $me->guess_type_of(
        \ 'this is text', { filename => 'plain.txt' } ),
        'text/plain', 'guess_type_of using default - text');

    is( $me->guess_type_of(
        \ pack('C*',0x25,0x50,0x44,0x46,0x2d,0x31,0x2e,0x33,0x0a,0x25,0xc4,0xe5,0xf2,0xe5,0xeb,0xa7), { filename => 'plain.pdf' } ),
        'application/pdf', 'guess_type_of using default - pdf');

    # switch routine
    $me->guesser(['FileName','MMagic']);
    
    is( $me->guess_type_of(
        \ 'this is text', { filename => undef }),
        'text/plain', 'guess_type_of using multi-guessers - text');

    is( $me->guess_type_of(
        \ pack('C*', 0x00), { filename => 'plain.txt' }), # fake suffix
        'text/plain', 'guess_type_of using guessers - text');

    # switch routine again
    $me->guesser(sub {
        my ($ref_data, $info) = @_;
        return 'text/plain' if( $$ref_data =~ /text/ );
        return undef;
        });

    is( $me->guess_type_of(
        \ 'this is text',{ filename => 'plain.txt' } ),
        'text/plain', 'guess_type_of using code - text');

    is( $me->guess_type_of(
        \ pack('C*',0x01,0x02),{ filename => 'plain.pdf' } ),
        'application/octet-stream', 'guess_type_of using code - unknown');
}

# plugin_for
{;
    my $me = MIME::Expander->new;
    my $plg;

    $plg = $me->plugin_for('message/rfc822');
    isa_ok( $plg, 'MIME::Expander::Plugin::MessageRFC822', 'plugin_for returns a plugin');

    is( $me->plugin_for('foo/bar'), undef, 'plugin_for says unkown');

    local @MIME::Expander::EnabledPlugins = qw/ApplicationTar/;
    is( $me->plugin_for('message/rfc822'), undef, 'plugin_for disabled plugin');
    isa_ok( $me->plugin_for('application/tar'),
        'MIME::Expander::Plugin::ApplicationTar', 'plugin_for enabled plugin');
}

# regulate_type (class method)
{;
    is( MIME::Expander->regulate_type('text/plain'), 'text/plain', 'regulate_type normal');
    is( MIME::Expander->regulate_type('text/x-me'), 'text/me', 'regulate_type unregistered');
    is( MIME::Expander->regulate_type('x-media/x-type'), 'media/type', 'regulate_type unregistered');
    is( MIME::Expander->regulate_type(), undef, 'regulate_type undef');
    is( MIME::Expander->regulate_type('a'), undef, 'regulate_type invalid');
    is( MIME::Expander->regulate_type('text/plain; charset=UTF-8'), 'text/plain', 'regulate_type content-type');

}

# regulate_type (via instance)
{;
    my $me = MIME::Expander->new;
    is( $me->regulate_type('text/plain'), 'text/plain', 'regulate_type normal');
    is( $me->regulate_type('text/x-me'), 'text/me', 'regulate_type unregistered');
    is( $me->regulate_type('x-media/x-type'), 'media/type', 'regulate_type unregistered');
    is( $me->regulate_type(), undef, 'regulate_type undef');
    is( $me->regulate_type('a'), undef, 'regulate_type invalid');
    is( $me->regulate_type('text/plain; charset=UTF-8'), 'text/plain', 'regulate_type content-type');
}

# walk

    # => 11_expander_walk.t

__END__
