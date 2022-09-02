#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use Doit;

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

    my $tmp = File::Temp->new;
    binmode($tmp);
    $tmp->print($orig_ini);
    $tmp->close;
    expected_line_endings("$tmp", 'unix');

    for my $ini_class (qw(Config::IOD::INI Config::IniFiles)) {
    SKIP: {
	    skip "$ini_class not available", 1
		if !eval qq{ require $ini_class; 1 };

	    diag "Testing $ini_class";

	    $doit->ini_set_implementation($ini_class);
	    is $doit->ini_change("$tmp", "wifi-security.psk" => "new-secret", "connection.id" => "non-public"), 1, 'changes detected';
	    expected_line_endings("$tmp", 'unix');
	    {
		my $new_ini = slurp("$tmp");
		like $new_ini, qr{psk=new-secret}, 'found 1st changed value';
		like $new_ini, qr{id=non-public}, 'found 2nd changed value';
	    }

	    if ($ini_class eq 'Config::IOD::INI') {
		is $doit->ini_change("$tmp", sub {
					 my($self) = @_;
					 my $confobj = $self->confobj;
					 isa_ok $confobj, 'Config::IOD::Document';
					 # undo the changes done above
					 $confobj->set_value('wifi-security', 'psk', 'secret');
					 $confobj->set_value('connection', 'id', 'public');
				     }), 1, 'changes detected';
	    } else {
		is $doit->ini_change("$tmp", sub {
					 my($self) = @_;
					 my $confobj = $self->confobj;
					 isa_ok $confobj, 'Config::IniFiles';
					 # undo the changes done above
					 $confobj->setval('wifi-security', 'psk', 'secret');
					 $confobj->setval('connection', 'id', 'public');
				     }), 1, 'changes detected';
	    }

	    is $doit->ini_change("$tmp", "wifi-security.psk" => "secret"), 0, 'no changes detected';

	    if ($ini_class eq 'Config::IniFiles') {
		# workaround known problem: some newlines get lost with Config::IniFiles
		# $doit->change_file seems to have problems just adding empty lines on Windows, so do it "manually"
		open my $fh, "<", "$tmp" or die $!;
		binmode $fh;
		open my $ofh, ">", "$tmp~" or die $!;
		binmode $ofh;
		while(<$fh>) {
		    print $ofh $_;
		    if (/^; comment [23]/) {
			print $ofh "\n";
		    }
		}
		close $ofh or die $!;
		close $fh;
		$doit->rename("$tmp~", "$tmp");
		#$doit->change_file(
		#    "$tmp",
		#    { match => qr{^; comment 2}, replace => "; comment 2\n\n" },
		#    { match => qr{^; comment 3}, replace => "; comment 3\n\n" },
		#);
		expected_line_endings("$tmp", 'unix');
	    }

	    {
		my $new_ini = slurp("$tmp");
		is $new_ini, $orig_ini, 'all changes in ini file were reverted';
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
