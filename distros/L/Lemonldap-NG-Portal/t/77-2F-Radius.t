use warnings;
use Test::More;
use strict;
use IO::String;
use Data::Dumper;

require 't/test-lib.pm';
require 't/smtp.pm';

use_ok('Lemonldap::NG::Common::FormEncode');

our $triggered = 0;

my $client = LLNG::Manager::Test->new( {
        ini => {
            logLevel                   => 'error',
            radius2fActivation         => 1,
            authentication             => 'Demo',
            userDB                     => 'Same',
            radius2fSendInitialRequest => 1,
            radius2fRequestAttributes  => {
                'NAS-Identifier'  => 'lemonldap',
                'X-Email-Address' => '$mail',
            }
        }
    }
);

no warnings 'redefine';
*Lemonldap::NG::Portal::Lib::Radius::_check_pwd_radius = sub {
    my ( $self, @attributes ) = @_;

    # Store attributes in a hash
    my %hattr;
    for my $a (@attributes) {
        $hattr{ $a->{Name} } = $a->{Value};
    }

    if ( exists $hattr{2} ) {
        is( $main::triggered, 1, "Has been triggered before" );
        $main::triggered = 0;
    }
    else {
        is( $main::triggered, 0, "Has not been triggered before" );
        $main::triggered = 1;
    }

    # Expect attributes
    is( $hattr{'NAS-Identifier'},
        'lemonldap', "Found NAS-Identifier attribute" );
    is( $hattr{'X-Email-Address'},
        'dwho@badwolf.org', "Found X-Email-Address attribute" );

    # Succeed if login == password, return no attributes
    return { result => ( defined $hattr{2} and ( $hattr{1} eq $hattr{2} ) ), };
};

sub runTestWithCode {
    my ($code) = @_;

    ok(
        my $res = $client->_post(
            '/',
            IO::String->new('user=dwho&password=dwho'),
            length => 23,
            accept => 'text/html',
        ),
        'Auth query'
    );

    my ( $host, $url, $query ) =
      expectForm( $res, undef, '/radius2fcheck?skin=bootstrap',
        'token', 'code' );

    ok(
        $res->[2]->[0] =~
qr%<input name="code" value="" type="text" class="form-control" id="extcode" trplaceholder="code" autocomplete="one-time-code" />%,
        'Found EXTCODE input'
    ) or print STDERR Dumper( $res->[2]->[0] );

    $query =~ s/code=/code=$code/;
    ok(
        $res = $client->_post(
            '/radius2fcheck',
            IO::String->new($query),
            length => length($query),
            accept => 'text/html',
        ),
        'Post code'
    );
    return $res;
}

subtest "Try with correct code" => sub {
    my $id = expectCookie( runTestWithCode("dwho") );
    $client->logout($id);
};

subtest "Try with incorrect code" => sub {
    expectPortalError( runTestWithCode("wrongcode"), 96, "Bad OTP error" );
};

clean_sessions();

done_testing();

