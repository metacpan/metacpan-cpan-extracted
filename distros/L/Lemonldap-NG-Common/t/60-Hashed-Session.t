use warnings;

use Test::More;
use Test::Output;
use File::Path;
use Data::Dumper;
use JSON;

BEGIN {
    use_ok('Lemonldap::NG::Common::Session');
    use_ok('Lemonldap::NG::Common::CliSessions');
}

use File::Temp;
my $dir          = File::Temp::tempdir();
my $sessionsdir  = "$dir/sessions";
my $psessionsdir = "$dir/psessions";
mkdir $sessionsdir;
mkdir $psessionsdir;

my $session;

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            force                => 1,
            hashStore            => 1,
            id                   => "123",
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
            info                 => { aa => 1 },
        }
    ),
    'Create fixed session'
);
ok( -f "$sessionsdir/" . id2storage('123'), 'Session name is hashed' );

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            hashStore            => 1,
            id                   => "123",
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
        }
    ),
    'Recover fixed session'
);
ok( $session->data->{aa} == 1, 'Data restored' );

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            hashStore            => 1,
            id                   => undef,
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
            info                 => { bb => 1 },
        }
    ),
    'Create session'
);

ok( -f "$sessionsdir/" . id2storage( $session->id ), 'Session name is hashed' );

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            hashStore            => 1,
            id                   => $session->id,
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
        }
    ),
    'Recover session'
);
ok( $session->data->{bb} == 1, 'Data restored' );

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            hashStore            => 1,
            id                   => $session->id,
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
            info                 => { bb => 1, cc => 2 },
        }
    ),
    'Recover session'
);
ok( $session->data->{bb} == 1 && $session->data->{cc} == 2, 'Data updated' )
  or print STDERR Dumper( $session->data );

ok(
    $session = Lemonldap::NG::Common::Session->new( {
            hashStore            => 1,
            id                   => $session->id,
            storageModule        => 'Apache::Session::File',
            storageModuleOptions => { Directory => $sessionsdir },
            kind                 => "SSO",
        }
    ),
    'Recover session'
);
ok( $session->data->{bb} == 1 && $session->data->{cc} == 2, 'Data updated' )
  or print STDERR Dumper( $session->data );

rmtree $dir;
done_testing();
