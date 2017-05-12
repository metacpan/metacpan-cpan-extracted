#########################

# There is currently a problem under Windows with Date::Manip on
# certain non-english installations of XP (and possible others).
#
# So we set our time zone to CET
BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
use Socket;
BEGIN { 
    if ( not $ENV{TEST_PG} ) {
        my $msg = 'DBI/DBD::PG test.  Set $ENV{TEST_PG} to a true value to run.';
        plan( skip_all => $msg );
    }
	# Disable preforking for now
    plan skip_all => "PreForking not yet stable";
	exit(0);

    require("t/testhelpers.pm");
    my $daemon_status = connect_memcached();
    if($daemon_status ne "OK") {
        plan skip_all => "no memchached running - wont stress-test";
		done_testing();
    } else {
        #plan tests => 1305;
    }
    use_ok('Maplat::Web');
    use_ok('Time::HiRes', qw(sleep usleep));
    use_ok('XML::Simple');
    use_ok('WWW::Mechanize');
    use_ok('HTTP::Cookies');

};
use DBI     ':sql_types';
use DBD::Pg ':pg_types';
use lib 't','.';
require 'dbdpg_test_setup.pl';
select(($|=1,select(STDERR),$|=1)[1]);


our $APPNAME = "Maplat Webtest";
our $VERSION = "0.95";

my ($testdsn,$testuser) = get_test_settings();
if ($testdsn =~ /FAIL/ || $testuser =~ /FAIL/) {
    fail("Can't get test database");
    exit(1);
}
#warn("DSN: $testdsn : User: $testuser\n");
#exit(0);

chdir "t";
my $configfile = "configs/webgui.xml";
if(!-f $configfile) {
    fail("Missing config file");
    exit(1);
}


my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);

$APPNAME = $config->{appname};
print "Changing application name to '$APPNAME'\n\n";

# Change config to use a forking server
$config->{server}->{forking} = 1;

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig($config->{server}, 0);

foreach my $module (@modlist) {
    if($module->{pm} eq "PostgresDB") {
        $module->{options}->{dburl} = $testdsn;
        $module->{options}->{dbuser} = $testuser;
        $module->{options}->{dbpassword} = "";
    }
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();

# Everything ready to run
my $pid = $webserver->background();
warn "Waiting for webserver to start up\n";
sleep(5);
eval {

	my $jar = new HTTP::Cookies(file => "cookies.dat", autosave=>1);
    my $mech = new WWW::Mechanize(cookie_jar => \$jar);

    for(1..50) {
        # Log in...
        my $result = $mech->get("http://localhost:9500/user/login");
        runchecks($result, "Login mask", ["Authentification", "Login", "Make me an application"], []);
        $result = $mech->submit_form(
            form_name => 'login',
            fields      => {
                username    => 'admin',
                password    => 'admin',
            },
        );
        runchecks($result, "Login", ["Login ok"], []);

        # Conclude this test run and log out
        $result = $mech->get("http://localhost:9500/user/logout");
        runchecks($result, "Log out", ["logged out"], []);
    }

};

# Finish up
is(kill(15,$pid),1,'Signaled 1 process successfully');
wait or die "counldn't wait for sub-process completion";

unlink "cookies.dat";
done_testing();

sub runchecks {
    my ($result, $name, $has, $hasnot) = @_;
    if($result->is_success) {
        pass($name);
    } else {
        fail($name);
    }
    foreach my $check (@{$has}) {
        like($result->content, qr/$check/, "STRING: $check");
    }
    foreach my $check (@{$hasnot}) {
        unlike($result->content, qr/$check/, "!STRING: $check");
    }
}


