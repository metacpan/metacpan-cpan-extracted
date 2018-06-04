#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

BEGIN {
    # Avoid loading REAL modules - fake everything
    foreach (qw(
        Apache2::RequestRec Apache2::RequestIO Apache2::Connection
        APR::SockAddr Apache2::Request Apache2::Upload Apache2::Const
    ) ) {
        my $mod = $_;
        $mod =~ s/::/\//g;
        $INC{ "$mod.pm" } = 1;
    };

    sub Apache2::Const::OK() { 0 }; ## no critic # const

    package Apache2::Request;
    use Carp;
    sub new {
        my $class = shift;
        @_ == 1 and return shift;
        my (%opt) = @_;
        return bless \%opt, $class;
    };

    sub method { "GET" };
    sub args { "" };

    our $AUTOLOAD;
    sub AUTOLOAD {
        my $self = shift;
        my $method = $AUTOLOAD;
        $method =~ s/.*:://;

        push @{ $self->{memo} }, [$method, @_];
        return $self->{retval}{$method};
    };

    sub DESTROY {
        # so that AUTOLOAD isn't called
    };
    1;

};

warnings_like {
    $ENV{MOD_PERL} = 2;
    require MVC::Neaf::Request::Apache2;
} qr#DEPRECATED.*Plack::Handler::Apache#, "Warning issued and alternative suggested";
ok (!MVC::Neaf::Request::Apache2->failed_startup, "Monkey patching worked")
    or die "Failed to mock apache, bailing out";

my $r = Apache2::Request->new (
    retval => {
        uri => "/foo/bar",
        param => "foo",
    },
);
my $neaf = MVC::Neaf::neaf();

$r->{retval}{headers_out} = $r;
$r->{retval}{headers_in}  = $r;

$neaf->load_view( TT => 'TT' );
$neaf->route( '/foo' => sub  {
    my $req = shift;

    local $SIG{__DIE__} = \&Carp::cluck;
    ok (!$req->secure, "No ssl under fake apache!!");
    return {
        -view => 'TT',
        -template => \'[% foo %] [% bar %]',
        foo => scalar $req->param( foo => '.*', 42 ),
        bar => scalar $req->get_cookie( bar => '\w+', 42 ),
    }
}, path_info_regex => '.*' );
my $code = $neaf->run; # PSGI mode to avoid CGI-ing

eval {
    MVC::Neaf::Request::Apache2->handler( $r );
};
ok (!$@, "Request lives")
    or diag "Died: $@";

is ($r->{memo}[0][0], "uri", "uri was 1st method called");
is ($r->{memo}[-1][0], "print", "print was last method called");
is ($r->{memo}[-1][1], "foo 42", "print got content");
# note explain $r->{memo};

done_testing;
