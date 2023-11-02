#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;
use Doit::Util qw(get_os_release);

use File::Temp ();
use Test::More;

plan skip_all => 'No suitable ini module available'
    if !eval { require Config::IOD::INI; 1 } && !eval { require Config::IniFiles; 1 };
plan 'no_plan';

sub slurp ($) { open my $fh, shift or die $!; binmode $fh; local $/; <$fh> }

sub line_endings ($) {
    my($filename) = @_;
    open my $fh, $filename
	or die "Can't open $filename: $!";
    binmode $fh;
    my $unix = 0;
    my $dos = 0;
    while(<$fh>) {
	/\r\n$/ and $dos++, next;
	$unix++;
    }
    if ($unix > 0 && $dos > 0) {
	'mixed';
    } elsif ($unix) {
	'unix';
    } elsif ($dos) {
	'dos';
    } else {
	'empty';
    }
}

sub expected_line_endings ($$) {
    my($filename, $expected) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is line_endings($filename), $expected, "expected line endings in $filename";
}

my $doit = Doit->init;
$doit->add_component('ini');

{
    my $orig_ini = <<'EOF';
; comment 1
[connection]
id=public
type=wifi
permissions=

; comment 2

; comment 3

[wifi]
mac-address-blacklist=
mode=infrastructure
ssid=ssid

[wifi-security]
auth-alg=open
key-mgmt=wpa-psk
psk=secret
EOF
    $orig_ini =~ s/\r//g if $^O eq 'MSWin32';

    my $test_ini = File::Temp->new;
    binmode($test_ini);
    $test_ini->print($orig_ini);
    $test_ini->close;
    expected_line_endings("$test_ini", 'unix');

    my $shell_config_contents = <<'EOF';
NAME="Ubuntu"
ID=ubuntu
VERSION_CODENAME=focal
VERSION_ID="20.04"
EOF

    my $shell_config = File::Temp->new;
    binmode($shell_config);
    $shell_config->print($shell_config_contents);
    $shell_config->close;
    expected_line_endings("$shell_config", 'unix');

    for my $ini_class (qw(Config::IOD::INI Config::IniFiles)) {
    SKIP: {
	    skip "$ini_class not available", 1
		if !eval qq{ require $ini_class; 1 };

	    diag "Testing $ini_class";

	    {
		my $HoH = $doit->ini_info_as_HoH("$test_ini");
		is_deeply($HoH, {
		    connection => {
			id => "public",
			type => "wifi",
			permissions => "",
		    },
		    wifi => {
			"mac-address-blacklist" => "",
			mode => "infrastructure",
			ssid => "ssid",
		    },
		    "wifi-security" => {
			"auth-alg" => "open",
			"key-mgmt" => "wpa-psk",
			"psk" => "secret",
		    }
		}, "ini_info_as_HoH output for class $ini_class");
	    }

	    $doit->ini_set_implementation($ini_class);
	    is $doit->ini_change("$test_ini", "wifi-security.psk" => "new-secret", "connection.id" => "non-public"), 1, 'changes detected';
	    expected_line_endings("$test_ini", 'unix');
	    {
		my $new_ini = slurp("$test_ini");
		like $new_ini, qr{psk=new-secret}, 'found 1st changed value';
		like $new_ini, qr{id=non-public}, 'found 2nd changed value';
	    }

	    if ($ini_class eq 'Config::IOD::INI') {
		is $doit->ini_change("$test_ini", sub {
					 my($self) = @_;
					 my $confobj = $self->confobj;
					 isa_ok $confobj, 'Config::IOD::Document';
					 # undo the changes done above
					 $confobj->set_value('wifi-security', 'psk', 'secret');
					 $confobj->set_value('connection', 'id', 'public');
				     }), 1, 'changes detected';
	    } else {
		is $doit->ini_change("$test_ini", sub {
					 my($self) = @_;
					 my $confobj = $self->confobj;
					 isa_ok $confobj, 'Config::IniFiles';
					 # undo the changes done above
					 $confobj->setval('wifi-security', 'psk', 'secret');
					 $confobj->setval('connection', 'id', 'public');
				     }), 1, 'changes detected';
	    }

	    is $doit->ini_change("$test_ini", "wifi-security.psk" => "secret"), 0, 'no changes detected';

	    if ($ini_class eq 'Config::IniFiles') {
		# workaround known problem: some newlines get lost with Config::IniFiles
		# $doit->change_file seems to have problems just adding empty lines on Windows, so do it "manually"
		open my $fh, "<", "$test_ini" or die $!;
		binmode $fh;
		open my $ofh, ">", "$test_ini~" or die $!;
		binmode $ofh;
		while(<$fh>) {
		    print $ofh $_;
		    if (/^; comment [23]/) {
			print $ofh "\n";
		    }
		}
		close $ofh or die $!;
		close $fh;
		$doit->rename("$test_ini~", "$test_ini");
		#$doit->change_file(
		#    "$test_ini",
		#    { match => qr{^; comment 2}, replace => "; comment 2\n\n" },
		#    { match => qr{^; comment 3}, replace => "; comment 3\n\n" },
		#);
		expected_line_endings("$test_ini", 'unix');
	    }

	    {
		my $new_ini = slurp("$test_ini");
		is $new_ini, $orig_ini, 'all changes in ini file were reverted';
	    }

	    {
		my $got_shell_config = $doit->ini_info_as_HoH("$shell_config");
		if ($ini_class eq 'Config::IniFiles') {
		    # Different behavior between Config::IOD::INI and Config::IniFiles:
		    # the latter does not remove quotes around values
		    while(my(undef,$sect_v) = each %$got_shell_config) {
			while(my($k) = each %$sect_v) {
			    $sect_v->{$k} =~ s{^"(.*)"$}{$1}; # strip quotes
			}
		    }
		}
		is_deeply $got_shell_config->{GLOBAL}, {
		    NAME => 'Ubuntu',
		    ID => 'ubuntu',
		    VERSION_CODENAME => 'focal',
		    VERSION_ID => '20.04',
		}, 'expected content reading a shell config file';
	    }

	SKIP: {
		my $os_release_path = "/etc/os-release";
		skip "No $os_release_path available", 1
		    if !-f $os_release_path;
		my $os_release_contents = $doit->ini_info_as_HoH($os_release_path);
		my $id = $os_release_contents->{GLOBAL}->{ID};
		ok $id, "assume that $os_release_path contains at least ID";
		diag "$os_release_path contains ID=$id";

		# compare with get_os_release
		my $os_release = get_os_release();
		ok $os_release, 'if /etc/os-release exists, than a hash should be returned';
		if ($ini_class ne 'Config::IniFiles') { # double quotes are not stripped with Config::IniFiles
		    is $os_release_contents->{GLOBAL}->{ID}, $os_release->{ID}, 'ID from ini parser and get_os_release() is the same';
		    is_deeply $os_release_contents->{GLOBAL}, $os_release, 'os-release contents from ini parser and get_os_release() are the same';
		}
	    }

	    is $doit->ini_adapter_class, "Doit::Ini::$ini_class", 'expected adapter class';
	}
    }
}

eval {
    $doit->ini_set_implementation('Non::Existing::Ini::Module');
};
like $@, qr{The implementation 'Non::Existing::Ini::Module' is unknown}, 'expected error on unknown module';

{
    no warnings 'redefine', 'once';
    local *Doit::Ini::Config::IOD::INI::available = sub { 0 };
    local *Doit::Ini::Config::IniFiles::available = sub { 0 };
    local *Doit::Ini::Config::IniMan::available   = sub { 0 };
    is $doit->ini_adapter_class, undef, 'simulate unavailable ini implementation';
    eval {
	$doit->ini_change('/does/not/matter', sub { });
    };
    like $@, qr{No usable ini implementation found, tried:}, 'simulate failure to run ini_change without ini implementations';
}

eval {
    $doit->ini_change('/does/not/matter', sub { }, sub { });
};
like $@, qr{Too many arguments, only one code reference is allowed}, 'expected error message';

is $doit->ini_change('/does/not/matter'), 0, 'no change parameters specified';
