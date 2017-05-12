# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Handler-CGI.t'

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

use_ok('Lemonldap::NG::Handler::CGI');

$LLNG_DEFAULTCONFFILE = undef;

#    sub Lemonldap::NG::Handler::CGI::lmLog { }

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

__END__
my $p;

# CGI Environment
$ENV{SCRIPT_NAME}     = '/test.pl';
$ENV{SCRIPT_FILENAME} = '/tmp/test.pl';
$ENV{REQUEST_METHOD}  = 'GET';
$ENV{REQUEST_URI}     = '/';
$ENV{QUERY_STRING}    = '';

ok(
    $p = Lemonldap::NG::Handler::CGI->new(
        {
            configStorage => {
                confFile => 'undefined.xx',
            },
            https         => 0,
            portal        => 'http://auth.example.com/',
            globalStorage => 'Apache::Session::File',
        }
    ),
    'Portal object'
);

