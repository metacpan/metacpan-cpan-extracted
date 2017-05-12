use strict;
use warnings;

use Test::More tests => 14;
use Test::MockObject;
use Apache2::Const -compile => qw(OK);
BEGIN{
    use_ok(q|JavaScript::Ectype::Handler::Apache2|);
}



sub setup_fake_request{
    my ($uri,$config,$headers_in ) = @_;
    my $request    = Test::MockObject->new;
    my $dir_config = Test::MockObject->new;
    my $headers    = Test::MockObject->new;
    my $status;
    $dir_config->mock( get => sub{
        $config->{$_[1]};
    });
    my $headers_out = {};
    $headers->mock('set' => sub{
        $headers_out->{$_[1]} = $_[2];
    });
    $request->mock('status'=>sub{
        my $class = shift;
        if( @_ ){
            $status = shift;
        }else{
            return $status;
        }
    });
    $request->set_true('content_type');
    $request->set_true('print');
    $request->set_always('uri',$uri);
    $request->set_always('dir_config',$dir_config);
    $request->set_always('err_headers_out',$headers);
    $request->set_always('headers_out',$headers);
    $request->set_always('headers_in',$headers_in);
    $request->fake_new('Apache2::Request');
    $headers_out;

}



{
    my ($headers) = setup_fake_request(
        q|/ectype/org.cpan.no_such|,
        {
            EctypeLibPath => './t/js/',
            EctypePrefix  => '/ectype/',
            EctypeMinify  => 1,
        },
        {

        }
    );
    my $req = Apache2::Request->new;
    ::is( 
        JavaScript::Ectype::Handler::Apache2->handler($req),
        Apache2::Const::OK
    );
    $req->called_ok('status');
    ok( $req->status == 404 );

}

{
    my ($headers) = setup_fake_request(
        q|/ectype/org.cpan|,
        {
            EctypeLibPath => './t/js/',
            EctypePrefix  => '/ectype/',
            EctypeMinify  => 1,
        },
        {

        }
    );
    my $req = Apache2::Request->new;
    ::is( 
        JavaScript::Ectype::Handler::Apache2->handler($req),
        Apache2::Const::OK
    );
    $req->called_ok('status');
    ok( $req->status == 200 );
    $req->called_ok('print');
    ok( exists $headers->{"Content-length"} );
    ok( exists $headers->{"Last-Modified"} );
    ok( exists $headers->{"Expires"} );
}

use HTTP::Date;
{
    my ($headers) = setup_fake_request(
        q|/ectype/org.cpan|,
        {
            EctypeLibPath => './t/js/',
            EctypePrefix  => '/ectype/',
            EctypeMinify  => 1,
        },
        {
            "If-Modified-Since" => HTTP::Date::time2str( time() )
        }
    );
    my $req = Apache2::Request->new;
    ::is( 
        JavaScript::Ectype::Handler::Apache2->handler($req),
        Apache2::Const::OK
    );
    $req->called_ok('status');
    ok( $req->status == 304 );

}


