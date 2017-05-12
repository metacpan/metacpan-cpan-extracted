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
my $hasMemcached;
BEGIN { 
    if ( not $ENV{TEST_PG} ) {
        my $msg = 'DBI/DBD::PG test.  Set $ENV{TEST_PG} to a true value to run.';
        plan( skip_all => $msg );
    }

    plan tests => 47;
    use_ok('Maplat::Web');
    use_ok('Time::HiRes', qw(sleep usleep));
    use_ok('XML::Simple');
    use_ok('WWW::Mechanize');
    use_ok('Maplat::Web::MemCacheSim');
    unshift @INC, "t";
    use_ok('Maplat::Web::HelloWorld');
    require("t/testhelpers.pm");
    my $daemon_status = connect_memcached();
    if($daemon_status ne "OK") {
        warn("No running memcached - using SIM\n");
        $hasMemcached = 0;
    } else {
        $hasMemcached = 1;
    }

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
my $isForking = $config->{server}->{forking} || 0;

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig($config->{server}, 0);

foreach my $module (@modlist) {
    if($module->{pm} eq "MemCache" && !$hasMemcached) {
        $module->{pm} = "MemCacheSim";  # Just change the perl module to use
    } elsif($module->{pm} eq "PostgresDB") {
        $module->{options}->{dburl} = $testdsn;
        $module->{options}->{dbuser} = $testuser;
        $module->{options}->{dbpassword} = "";
    }
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();

# Everything ready to run
my $pid;
eval {
    $pid = $webserver->background();

    my $mech = new WWW::Mechanize();

    # Test login
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

    # Set and unset a variable
    $result = $mech->get("http://localhost:9500/admin/variables");
    runchecks($result, "Variables GET", ["HeaderMessage"], ["Test Text"]);
    $result = $mech->submit_form(
        form_name => 'setvariable_HeaderMessage',
        fields      => {
            varvalue    => 'Test Text',
        },
    );
    runchecks($result, "Variables SET", ["HeaderMessage", "Test Text"], []);
    $result = $mech->submit_form(
        form_name => 'setvariable_HeaderMessage',
        fields      => {
            varvalue    => '',
        },
    );
    runchecks($result, "Variables UNSET", ["HeaderMessage"], ["Test Text"]);

    # Change user rights
    $result = $mech->get("http://localhost:9500/admin/useredit");
    runchecks($result, "User rights mask", ["HelloWorld", "Admin", "Dev Test"], ["Test Text"]);
    $result = $mech->submit_form(
        form_name => 'changeuser_admin',
        fields      => {
            has_world    => '1',
            is_admin     => '1',
            has_devtest  => '1',
            password     => '',
        },
    );
    runchecks($result, "Change rights", ["User changed"], []);

    # Logout/Login so new user rights are set in this session
    $result = $mech->get("http://localhost:9500/user/logout");
    runchecks($result, "Log out", ["logged out"], []);

    # Log back in...
    $result = $mech->get("http://localhost:9500/user/login");
    runchecks($result, "Login mask", ["Authentification", "Login", "Make me an application"], []);
    $result = $mech->submit_form(
        form_name => 'login',
        fields      => {
            username    => 'admin',
            password    => 'admin',
        },
    );
    runchecks($result, "Login", ["Login ok"], []);

    # ...and change to "Hello world", which should now be our default view (check by checking
    # the string in the menu)
    # Logout/Login so new user rights are set in this session
    $result = $mech->get("http://localhost:9500/helloworld/example");
    runchecks($result, "HelloWorld default view", ["Hello World", "Text in module template", "Dynamic module text"], 
        []);

    # ...and select admin view again...
    $result = $mech->submit_form(
        form_name => 'viewselect',
        fields      => {
            viewname    => 'Admin',
        },
    );
    runchecks($result, "Admin", ["Variables", "Status", "Users"], ["Hello World"]);


    # Conclude this test and log out
    $result = $mech->get("http://localhost:9500/user/logout");
    runchecks($result, "Log out", ["logged out"], []);

};

# Finish up
is(kill(9,$pid),1,'Signaled 1 process successfully');
wait or die "counldn't wait for sub-process completion";

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


