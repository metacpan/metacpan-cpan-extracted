# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Lemonldap-NG-Manager.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Lemonldap::NG::Common::Conf') }

#########################

# Insert your test code below, the Test::More module is used here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $h;
my $inifile     = "lemonldap-ng.ini";
my $confsection = "configuration";

ok( (
        Lemonldap::NG::Common::Conf->new( type => 'bad' ) == 0
          and $Lemonldap::NG::Common::Conf::msg =~
          /Error: failed to load Lemonldap::NG::Common::Conf::Backends::bad/
    ),
    'Bad module'
) or print STDERR "Msg: $Lemonldap::NG::Common::Conf::msg\n";

$h = bless {}, 'Lemonldap::NG::Common::Conf';

ok( (
        %$h = ( %$h, %{ $h->getLocalConf( $confsection, $inifile, 0 ) } )
          and exists $h->{localStorage}
    ),
    "Read $inifile"
);

