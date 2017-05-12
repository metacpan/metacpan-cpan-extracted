package Mason::Plugin::WithEncoding::t::NoUTF8;
$Mason::Plugin::WithEncoding::t::NoUTF8::VERSION = '0.2';
use utf8;

use Test::Class::Most parent => 'Mason::Plugin::WithEncoding::Test::Class';
use Guard;
use Poet::Tools qw(dirname mkpath trim write_file);

# Setup stolen from Poet::t::Run and Poet::t::PSGIHandler

sub test_no_withencoding : Tests {
    my $self = shift;

    my $conf_no_encoding = {
        'layer' => 'production',
        'server.port' => 9998,
    };

    my $poet = $self->temp_env(conf => $conf_no_encoding);
    my $root_dir = $poet->root_dir;
    my $run_log  = "$root_dir/logs/run.log";

    if ( my $pid = fork() ) {
        # parent
        scope_guard { kill( 1, $pid ) };
        sleep(2);

        my $mech = $self->mech($poet);
        $self->add_comps($poet);

        # std config, utf8 content, utf8 url, utf8 query
        $mech->get_ok("http://127.0.0.1:9998/♥♥♥?♥♥=♥♥♥♥♥♥♥");
        # query string goes over wires as encoded ascii, so clients use url encoding to preserve information
        $mech->content_unlike(qr/QUERY STRING FROM REQ: ♥♥=♥♥♥♥♥♥/);
        $mech->content_like(qr[QUERY STRING FROM REQ: \Q%E2%99%A5%E2%99%A5=%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5\E]);
        $mech->content_unlike(qr/QUERY STRING UNESCAPED: ♥♥=♥♥♥♥♥♥♥/);
        #warn $mech->content;
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_unlike(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);   #### WithEncode matches       (uc operation works)
        $mech->content_like(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);     #### WithEncode doesn't match (uc operation works)
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, utf8 content, utf8 url, no query
        $mech->get_ok("http://127.0.0.1:9998/♥♥♥");
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_unlike(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);    #### WithEncode matches       (uc operation works)
        $mech->content_like(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);      #### WithEncode doesn't match (uc operation works)
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, utf8 content, ascii url, utf8 query
        $mech->get_ok("http://127.0.0.1:9998/utf8?♥♥=♥♥♥♥♥♥♥");
        # query string goes over wires as encoded ascii, so clients use url encoding to preserve information
        $mech->content_unlike(qr/QUERY STRING FROM REQ: ♥♥=♥♥♥♥♥♥/);
        $mech->content_like(qr[QUERY STRING FROM REQ: \Q%E2%99%A5%E2%99%A5=%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5%E2%99%A5\E]);
        $mech->content_unlike(qr/QUERY STRING UNESCAPED: ♥♥=♥♥♥♥♥♥♥/);
        #warn $mech->content;
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_unlike(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);    #### WithEncode matches       (uc operation works)
        $mech->content_like(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);      #### WithEncode doesn't match (uc operation works)
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, utf8 content, ascii url, no query
        $mech->get_ok("http://127.0.0.1:9998/utf8");
        #warn $mech->content;
        $mech->content_like(qr/A QUICK BROWN FOX JUMPS OVER THE LAZY DOG/);
        $mech->content_unlike(qr/a quick brown fox jumps over the lazy dog/);
        $mech->content_unlike(qr/ΔΙΑΦΥΛΆΞΤΕ ΓΕΝΙΚΆ ΤΗ ΖΩΉ ΣΑΣ ΑΠΌ ΒΑΘΕΙΆ ΨΥΧΙΚΆ ΤΡΑΎΜΑΤΑ/);    #### WithEncode matches       (uc operation works)
        $mech->content_like(qr/διαφυλάξτε γενικά τη ζωή σας από βαθειά ψυχικά τραύματα/);      #### WithEncode doesn't match (uc operation works)
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, plain content, plain url, no query
        $mech->get_ok("http://127.0.0.1:9998/plain");
        $mech->content_like(qr/LOREM IPSUM DOLOR SIT AMET/);
        $mech->content_unlike(qr/Lorem ipsum dolor sit amet/);
        #warn $mech->content;
        is($mech->content_type, 'text/html', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, chokes on $.args->{♥} in the page, looks like a bug
        $mech->get("http://127.0.0.1:9998/dies"); # PSGI error: Unrecognized character
        ok($mech->status == 500, 'UTF8 content bug');
        #$mech->content_like(qr/♥♥♥♥♥♥♥/);
        is($mech->content_type, '', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        # std config, json content
        my $expected_from_json = {
            foo => 'bar',
            baz => [qw(barp beep)],
            9 => { one => 1, ex => 'EKS' },
            heart => '♥',
        };
        $mech->get_ok("http://127.0.0.1:9999/json");
        #warn $mech->content;
        # see comments in UTF8.pm for why I can't use cmp_deeply
        #cmp_deeply(JSON->new->utf8->decode($mech->content), $expected_from_json, 'Decoded expected data from JSON');   # fails 'â�¥' - that's what is in the content
        #cmp_deeply(JSON->new->decode($mech->content), $expected_from_json, 'Decoded expected data from JSON');         # fails 'Ã¢Â�Â¥'

        my $from_decoded_utf8 = JSON->new->utf8->decode($mech->content); # should work    DOESN'T
        my $not_decoded = JSON->new->decode($mech->content);             # should break

        use Encode qw();
        my $manually_decoded = JSON->new->decode(Encode::decode('UTF8', $mech->content));                  # should work    DOESN'T
        my $manually_and_JSON_decoded = JSON->new->utf8->decode(Encode::decode('UTF8', $mech->content));   # should break   ISN'T

        ok($from_decoded_utf8->{heart}, 'My heart is true');


        ok($not_decoded->{heart}, 'My heart is true');
        ok($not_decoded->{heart} ne '♥', 'My heart has been mangled');

        is($mech->content_type, 'application/json', 'Got correct content type');
        is($mech->response->content_type_charset, undef, 'Got correct content-type charset');

        local $TODO = "I'm not grokking something";
        is($from_decoded_utf8->{heart}, '♥', 'Found my true ♥');             # why does this fail? 'â�¥'
        is($manually_decoded->{heart}, '♥', 'Found my true ♥');              # why does this fail? 'â�¥'
        ok($manually_and_JSON_decoded->{heart} ne '♥', 'Found my true ♥');   # WHY DOES THIS WORK (when 'eq')????  somewhere it got UTF8 encoded a second time
    }
    else {
        # child
        close STDOUT;
        close STDERR;
        exec( $poet->bin_path("run.pl > $run_log 2>&1") );
    }
}

1;
