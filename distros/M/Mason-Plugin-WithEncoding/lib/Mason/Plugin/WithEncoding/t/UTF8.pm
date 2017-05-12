package Mason::Plugin::WithEncoding::t::UTF8;
$Mason::Plugin::WithEncoding::t::UTF8::VERSION = '0.2';
use utf8;

use Test::Class::Most parent => 'Mason::Plugin::WithEncoding::Test::Class';
use Guard;
use Poet::Tools qw(dirname mkpath trim write_file);

# Setup stolen from Poet::t::Run and Poet::t::PSGIHandler

sub test_withencoding : Tests {
    my $self = shift;
    my $poet_conf = shift;

    my $conf_utf8 = {
        'layer'       => 'production',
        'server.port' => 9999,

        'mason.extra_plugins' => [qw(WithEncoding)],
        'server.load_modules' => ['Mason::Plugin::WithEncoding'],
        'server.encoding.request' => 'UTF-8',
        'server.encoding.response' => 'UTF-8',
        'server.default_content_type' => 'text/html; charset=UTF-8',
    };

    my $poet = $self->temp_env(conf => $conf_utf8);
    my $root_dir = $poet->root_dir;
    my $run_log  = "$root_dir/logs/run.log";

    if ( my $pid = fork() ) {
        # parent
        scope_guard { kill( 1, $pid ) };
        sleep(2);

        my $mech = $self->mech($poet);
        $self->add_comps($poet);

        #
        # Unescaping the query string doesn't produce love hearts, which I don't
        # really understand, since this does:
        #
        # $ perl -MURI::Escape -e 'print uri_unescape("%E2%99%A5%E2%99%A5=%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5")."\n"'
        # $ ♥♥=♥♥♥♥♥♥♥
        #

        # utf8 config, utf8 content, utf8 url, utf8 query
        $mech->get_ok("http://127.0.0.1:9999/♥♥♥?♥♥=♥♥♥♥♥♥♥");
        # query string goes over wires as encoded ascii, so clients use url encoding to preserve information
        $mech->content_unlike(qr/QUERY STRING FROM REQ: ♥♥=♥♥♥♥♥♥/);
        $mech->content_like(qr[QUERY STRING FROM REQ: \Q%E2%99%A5%E2%99%A5=%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5\E]);
        $mech->content_unlike(qr/QUERY STRING UNESCAPED: ♥♥=♥♥♥♥♥♥♥/);
        #warn $mech->content;
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_like(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);
        $mech->content_unlike(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');

        # utf8 config, utf8 content, utf8 url, no query
        $mech->get_ok("http://127.0.0.1:9999/♥♥♥");
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_like(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);
        $mech->content_unlike(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');

        # utf8 config, utf8 content, ascii url, utf8 query
        $mech->get_ok("http://127.0.0.1:9999/utf8?♥♥=♥♥♥♥♥♥♥");
        # query string goes over wires as encoded ascii, so clients use url encoding to preserve information
        $mech->content_unlike(qr/QUERY STRING FROM REQ: ♥♥=♥♥♥♥♥♥/);
        $mech->content_like(qr[QUERY STRING FROM REQ: \Q%E2%99%A5%E2%99%A5=%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5\E]);
        $mech->content_unlike(qr/QUERY STRING UNESCAPED: ♥♥=♥♥♥♥♥♥♥/);
        #warn $mech->content;
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_like(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);
        $mech->content_unlike(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');

        # utf8 config, utf8 content, ascii url, no query
        $mech->get_ok("http://127.0.0.1:9999/utf8");
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_like(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);
        $mech->content_unlike(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');

        # utf8 config, plain content, plain url, no query
        $mech->get_ok("http://127.0.0.1:9999/plain");
        $mech->content_like(qr/LOREM IPSUM DOLOR SIT AMET/);
        $mech->content_unlike(qr/Lorem ipsum dolor sit amet/);
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');

        # utf8 config, chokes on $.args->{♥} in the page, looks like a bug
        $mech->get("http://127.0.0.1:9999/dies");
        ok($mech->status == 500, 'UTF8 content bug');
        is($mech->content_type, '', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # utf8 config, json content
        $mech->get_ok("http://127.0.0.1:9999/json");
        #warn $mech->content;
        my $expected_from_json = {
            foo => 'bar',
            baz => [qw(barp beep)],
            9 => { one => 1, ex => 'EKS' },
            heart => '♥',
        };

        cmp_deeply(JSON->new->utf8->decode($mech->content), $expected_from_json, 'Decoded and de-JSONified expected data from JSON');

        #   this doesn't work
        #my $expected_mangled_from_json = {%$expected_from_json, heart => 'â�¥'};  # â�¥
        #   I can't figure out how to get this test to work. The cmp_deeply fails if fed
        #   the unmangled hashref as expected, I
        #   just can't figure out how to mangle the expected hashref to match the mangled hashref
        #   retrieved from the $mech content
        #cmp_deeply(JSON->new->decode($mech->content), $expected_mangled_from_json, 'Mangled data from JSON');        # fails 'â�¥'

        my $from_decoded_utf8 = JSON->new->utf8->decode($mech->content); # should work
        my $not_decoded = JSON->new->decode($mech->content);             # should break

        ok($from_decoded_utf8->{heart}, 'My heart is true');
        is($from_decoded_utf8->{heart}, '♥', 'Found my true ♥');
        ok($not_decoded->{heart}, 'My heart is true');
        ok($not_decoded->{heart} ne '♥', 'My heart has been mangled');

        is($mech->content_type, 'application/json', 'Got correct content type');
        is($mech->response->content_type_charset, 'UTF-8', 'Got correct content-type charset');
    }
    else {
        # child
        close STDOUT;
        close STDERR;
        exec( $poet->bin_path("run.pl > $run_log 2>&1") );
    }
}

1;
