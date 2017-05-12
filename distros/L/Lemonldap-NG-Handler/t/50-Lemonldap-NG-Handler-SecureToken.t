# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-Proxy.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 1;
use Cwd 'abs_path';
use File::Basename;
use File::Temp;

my $ini = File::Temp->new();
my $dir = dirname( abs_path($0) );

print $ini "[all]

[configuration]
type=File
dirName=$dir
";

$ini->flush();

use Env qw(LLNG_DEFAULTCONFFILE);
$LLNG_DEFAULTCONFFILE = $ini->filename;

open STDERR, '>/dev/null';

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

SKIP: {
    eval { require Cache::Memcached };
    skip
"Cache::Memcached is not installed, so Lemonldap::NG::Handler::Specific::SecureToken will not be useable",
      1
      if ($@);
    use_ok('Lemonldap::NG::Handler::Specific::SecureToken');
}

$LLNG_DEFAULTCONFFILE = undef;
