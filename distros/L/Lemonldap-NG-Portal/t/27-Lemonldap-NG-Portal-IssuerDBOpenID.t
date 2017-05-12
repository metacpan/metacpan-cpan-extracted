package My::Portal;

use Test::More tests => 14;
use strict;

our @ISA = qw(Lemonldap::NG::Portal::IssuerDBOpenID
  Lemonldap::NG::Portal::OpenID::SREG Lemonldap::NG::Portal::Simple);

sub lmLog {
    my ( $self, $msg, $level ) = splice @_;

    #print STDERR "[$level] $msg\n";
}

our $param = { confirm => 0 };

sub param {
    my ( $self, $key ) = splice @_;
    return $param->{$key};
}

sub info                    { }
sub _sub                    { }
sub updatePersistentSession { }

$ENV{HTTP_ACCEPT_LANGUAGE} = 'en';
SKIP: {
    eval { require Net::OpenID::Server; };
    skip(
        "Net::OpenID::Consumer is not installed, so "
          . "Lemonldap::NG::Portal::AuthOpenID will not be useable",
        14
    ) if ($@);
    use_ok('Lemonldap::NG::Portal::OpenID::Server');
    use_ok('Lemonldap::NG::Portal::IssuerDBOpenID');
    use_ok('Lemonldap::NG::Portal::OpenID::SREG');

    my $p = bless {
        sessionInfo => {
            uid  => 'test',
            mail => 'x.x.org'
        },
        whatToTrace => 'uid',
      },
      __PACKAGE__;

    my ( $r, $h );
    ( $r, $h ) = $p->sregHook( '', '', 0, 0, {} );
    ok( $r == 0, 'SREG: Call sregHook with untrusted request' );
    $param->{confirm} = -1;
    ok(
        !$p->sregHook( '', '', 1, 1, {} ),
        'SREG: call sregHook with confirm => -1'
    );
    $param->{confirm} = 1;
    ok(
        $p->sregHook( '', '', 1, 1, {} ),
        'SREG: call sregHook without arguments'
    );
    ( $r, $h ) =
      $p->sregHook( '', '', 1, 1,
        { required => 'fullname,email', optional => 'nickname' },
      );
    ok( $r == 0, 'SREG: 0 returned unless required attributes are configured' );
    $p->{openIdSreg_fullname} = '$uid';
    $p->{openIdSreg_email}    = '$mail';
    $p->{openIdSreg_nickname} = '$uid';
    ( $r, $h ) =
      $p->sregHook( '', '', 1, 1,
        { required => 'fullname,email', optional => 'nickname' },
      );
    ok( $r == 1, 'SREG: 1 returned if required attributes are configured' );
    ok( ref($h), 'SREG: Parameters returned as hashref' );
    ok( ( $h->{email} eq 'x.x.org' and $h->{fullname} eq 'test' ),
        'SREG: required attributes returned' );
    ok( !defined( $h->{nickname} ), 'SREG: optional parameter not returned' );
    $param->{sreg_nickname} = 0;
    ( $r, $h ) =
      $p->sregHook( '', '', 1, 1,
        { required => 'fullname,email', optional => 'nickname' },
      );
    ok( !defined( $h->{nickname} ),
        'SREG: optional unwanted parameter not returned' );
    $param->{sreg_nickname} = 'OK';
    ( $r, $h ) =
      $p->sregHook( '', '', 1, 1,
        { required => 'fullname,email', optional => 'nickname' },
      );
    ok( defined( $h->{nickname} ), 'SREG: optional wanted parameter returned' );

    $param->{confirm} = 0;
    ( $r, $h ) =
      $p->sregHook( '', '', 1, 1,
        { required => 'fullname,email', optional => 'nickname' },
      );
    ok( ( $r == 0 and ref($h) ),
        'SREG: 0 returned for unconfirmed parameters' );
}

