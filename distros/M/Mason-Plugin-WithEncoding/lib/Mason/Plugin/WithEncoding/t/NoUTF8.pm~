package Mason::Plugin::WithEncoding::t::NoUTF8;

use utf8;

use Test::Class::Most parent => 'Mason::Plugin::WithEncoding::Test::Class';
use Capture::Tiny qw();
use Guard;
use Poet::Tools qw(dirname mkpath trim write_file);
use Encode qw(encode decode);

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


        # Don't encode the path because, hmm, not sure. Because it 'just works' as-is.
        $self->add_comp(path => '/♥♥♥.mc',   src => encode('UTF-8', $self->content_for_tests('utf8')), poet => $poet);
        $self->add_comp(path => '/utf8.mc',  src => encode('UTF-8', $self->content_for_tests('utf8')), poet => $poet);
        $self->add_comp(path => '/plain.mc', src => encode('UTF-8', $self->content_for_tests('plain')), poet => $poet);
        $self->add_comp(path => '/dies.mc',  src => encode('UTF-8', $self->content_for_tests('dies')), poet => $poet);

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
    }
    else {
        # child
        close STDOUT;
        close STDERR;
        exec( $poet->bin_path("run.pl > $run_log 2>&1") );
    }
}

1;
