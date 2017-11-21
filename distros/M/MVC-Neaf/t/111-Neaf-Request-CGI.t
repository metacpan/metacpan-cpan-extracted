#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;
# Must autoload Request::CGI - so don't use explicitly!

my $warn = 0;
$SIG{__WARN__} = sub { $warn++; warn $_[0]; };

my $capture_req;
my $capture_stdout;
MVC::Neaf->route( "/my/script" => sub {
    $capture_req = shift; # "my" omitted on purpose
    return {
        -content  => '%', # hack - make Neaf autodetect utf8
        -continue => sub {
            my $req = shift;
            $req->write( $req->param( foo => '\w+' => '<undef>' )."\n" );
            $req->close;
        },
    }
} );

is ($MVC::Neaf::Request::CGI::VERSION, undef, "Module NOT loaded yet");

my ( $ver, $upl );
{
    local $ENV{HTTP_HOST};
    local @ARGV = qw( /my/script?foo=42 );
    local *STDOUT;
    open STDOUT, ">", \$capture_stdout;

    MVC::Neaf->run; # void context = CGI run

    $ver = $capture_req->http_version;
    $upl = $capture_req->upload("masha");

    # HACK - make postponed actions execute
    # HACK - we need STDERR localized until this point
    undef $capture_req;
    1; # make sure undef() executes BEFORE leaving the block
};

note $capture_stdout;
is ($ver, "1.0", "http 1.0 autodetected");
is ($upl, undef, "No uploads");

like ($MVC::Neaf::Request::CGI::VERSION, qr/\d+\.\d+/, "Module auto-loaded")
    or die "Nothing to test here, bailing out";

like ($capture_stdout, qr/\n\n%42\n$/s, "Reply as expected");
like ($capture_stdout, qr#Content-Type: text/plain#
    , "content type ok");

ok !$warn, "$warn warnings issued";
done_testing;
