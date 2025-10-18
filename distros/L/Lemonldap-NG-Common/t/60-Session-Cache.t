use warnings;

use Apache::Session::File;
use Cache::FileCache;
use File::Find;
use File::Path;
use File::Temp;
use JSON;
use Test::More;

BEGIN {
    use_ok('Lemonldap::NG::Common::Apache::Session');
    use_ok('Lemonldap::NG::Common::Session');
}

my $dir         = File::Temp::tempdir( CLEANUP => 1 );
my $sessionsdir = "$dir/sessions";
my $cachedir    = "$dir/cache";

mkdir $sessionsdir;
mkdir "$sessionsdir/lock";
mkdir $cachedir;

my %session;

my $cacheOpts = {
    namespace            => 'llng',
    cache_root           => $cachedir,
    allow_cache_for_root => 1,
};

my $args = {
    localStorage        => 'Cache::FileCache',
    localStorageOptions => $cacheOpts,
    backend             => 'Apache::Session::File',
    Directory           => $sessionsdir,
    LockDirectory       => "$sessionsdir/lock",
};

ok( tie( %session, 'Lemonldap::NG::Common::Apache::Session', undef, $args ),
    'Create session' );
my $id;
ok( $id = $session{_session_id}, "Get session id $id" );

$session{aa} = 'bb';
untie %session;

my $cache = Cache::FileCache->new($cacheOpts);
my $cacheData;

# Cache corruption
$cache->set( $id, '{"a":k' );
ok( tie( %session, 'Lemonldap::NG::Common::Apache::Session', $id, $args ),
    'Get session' );
ok( $session{aa} eq 'bb', 'Session is restored' );

$session{bb} = 'cc';
untie %session;

# Cache deletion
rmtree $cachedir;
mkdir $cachedir;
chmod 0555, $cachedir;

ok( tie( %session, 'Lemonldap::NG::Common::Apache::Session', $id, $args ),
    'Get session' );
ok( $session{bb} eq 'cc', 'Session is restored' );
untie %session;

chmod 0755, $cachedir;

ok( tie( %session, 'Lemonldap::NG::Common::Apache::Session', $id, $args ),
    'Get session' );
untie %session;

ok( unlink("$sessionsdir/$id"), 'Drop session' );

ok( tie( %session, 'Lemonldap::NG::Common::Apache::Session', $id, $args ),
    'get session from cache' );
ok( $session{bb} eq 'cc', 'cached session is valid' );
untie %session;

rmtree $cachedir;
mkdir $cachedir;

eval { tie( %session, 'Lemonldap::NG::Common::Apache::Session', $id, $args ) };
ok( $@, 'Error when session and cache are inexitent' );

rmtree $dir;
done_testing();
