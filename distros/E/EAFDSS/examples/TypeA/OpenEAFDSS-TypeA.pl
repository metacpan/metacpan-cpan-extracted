#!/usr/bin/perl -w

# OpenEAFDSS-GUI.pl - Electronic Fiscal Signature Devices GUI Utility
#                 Ειδική Ασφαλής Φορολογική Διάταξη Σήμανσης (ΕΑΦΔΣΣ)
#
# Copyright (C) 2008 by Hasiotis Nikos
#
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ID: $Id: OpenEAFDSS-TypeA.pl 105 2009-05-18 10:52:03Z hasiotis $

use strict;
use Config::IniFiles;
use Data::Dumper;
use Curses::UI;
use DBI;
use EAFDSS; 


my($cfg) = Config::IniFiles->new(-file => "/etc/OpenEAFDSS/OpenEAFDSS-TypeA.ini", -nocase => 1);

my($ABC_DIR) = $cfg->val('MAIN', 'ABC_DIR', '/tmp/signs');
my($SQLITE)  = $cfg->val('MAIN', 'SQLITE', '/tmp/eafdss.sqlite');

my($SN)      = $cfg->val('DEVICE', 'SN', 'ABC02000001');
my($DRIVER)  = $cfg->val('DEVICE', 'DRIVER', 'SDNP');
my($PARAM)   = $cfg->val('DEVICE', 'PARAM', 'localhost');

my(%reply);
my($cui) = new Curses::UI(
			-clear_on_exit  => 1,
			-color_support  => 1,
			-fg             => 'white',
			-bg             => 'blue',
		);

my($menuFile) = [
	{ -label => ' Settings  ^S', -value => \&settingsDialog },
	{ -label => ' Exit      ^Q', -value => \&exitDialog     }
];
my($menuTypeA) = [
	{ -label => ' Issue Z Report ',   -value => \&issueReportDialog   },
	{ -label => ' Browse Invoices',   -value => \&browseInvoiceDialog },
	{ -label => ' Search Invoices',   -value => \&searchInvoiceDialog },
	{ -label => ' Check A,B,C Files', -value => \&checkABCDialog      },
];
my($menuTools) = [
	{ -label => ' Get Status     ', -value => \&getStatusDialog      },
	{ -label => ' Get Headers    ', -value => \&getHeadersDialog     },
	{ -label => ' Set Headers    ', -value => \&setHeadersDialog     },
	{ -label => ' Read Time      ', -value => \&readTimeDialog       },
	{ -label => ' Set Time       ', -value => \&setTimeDialog        },
	{ -label => ' Version Info   ', -value => \&versionInfoDialog    },
];
my($menuHelp) = [
	{ -label => ' Help ', -value => \&helpDialog },
	{ -label => ' About', -value => \&aboutDialog }
];
my($menuBar) = [
	{ -label => 'File',   -submenu => $menuFile  },
	{ -label => 'Type A', -submenu => $menuTypeA },
	{ -label => 'Tools',  -submenu => $menuTools },
	{ -label => 'Help',   -submenu => $menuHelp  }
]; 

my($menu) = $cui->add( 'menu', 'Menubar', -menu => $menuBar);

my($statusBar) = $cui->add( 'statusbar_win', 'Window', -height => 4, -y => -1);
my($status) = $statusBar->add(
	'status_text', 'TextViewer',
	-text		=> " ^X:Menu | OpenEAFDSS Type A *example* Solution Utility",
	-padtop		=> 2,
	-width		=> 180,
	-fg             => 'white',
	-bg             => 'blue',
);

$cui->set_binding(sub {$menu->focus()},     "\cX");
$cui->set_binding( \&settingsDialog,        "\cS");
$cui->set_binding( \&exitDialog,            "\cQ");

$cui->mainloop();

sub exitDialog {
	my($return) = $cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-message   => "Do you really want to quit?",
			-title     => "[ EXIT ]", 
			-buttons   => ['yes', 'no'],
		);
	exit(0) if $return;
}

sub issueReportDialog {
	my($dh) = loadDriverHandle();

	my($result) = $dh->Report();
	if ($result) {
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Z Report",
			-message => $result
		);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error producing Z report",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		)
	}
}

sub settingsDialog {
	my($winSettings) = $cui->add(
		'winSettings', 'Window',
		-title		=> 'Device Settings',
		-width          => 60,
		-height         => 23,
		-border         => 1,
		-padtop         => 2,
		-padbottom      => 2,
		-padleft        => 2,
		-padright       => 2,
		-ipad           => 1
	);

	my($driverIndex) = 1;
	if ($DRIVER eq 'SDNP')  { $driverIndex = 1 };
	if ($DRIVER eq 'SDSP')  { $driverIndex = 2 };
	if ($DRIVER eq 'Dummy') { $driverIndex = 3 };

	my($lblDRIVER) = $winSettings->add(
		"lDRIVER", "Label", -text   => "      Driver Type: ",
		-x      => 2, -y      => 1,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($boxDRIVER) = $winSettings->add(
		"boxDRIVER", "Listbox", 
		-values    => ['SDNP', 'SDSP', 'Dummy'],
		-labels    => { 1 => 'Micrelec Network', 
				2 => 'Micrelec Serial', 
				3 => 'Dummy' },
		-selected   => $driverIndex,
		-fg     => 'white', -bg     => 'black',
		-x      => 25, -y      => 1,
		-height => 1, -width  => 20,
		-maxlength => 11,
	);

	my($lblPARAM) = $winSettings->add(
		"lPARAM", "Label", -text   => "Driver Parameter: ",
		-x      => 2, -y      => 3,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtPARAM) = $winSettings->add(
		"PARAM", "TextEntry", -text   => $PARAM,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 3,
		-height => 1, -width  => 12,
		-maxlength => 11,
	);

	my($lblSN) = $winSettings->add(
		"lSN", "Label", -text   => "  Serial Number: ",
		-x      => 4, -y      => 5,
		-height => 1, -width  => 18,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtSN) = $winSettings->add(
		"SN", "TextEntry", -text   => $SN,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 5,
		-height => 1, -width  => 12,
		-maxlength => 11,
	);

	my($lblABC_DIR) = $winSettings->add(
		"lABC_DIR", "Label", -text   => "  Signatures Dir: ",
		-x      => 2, -y      => 8,
		-height => 1, -width  => 20,
		-maxlength => 11, -textalignment => 'right',
	);
	my($txtABC_DIR) = $winSettings->add(
		"ABC_DIR", "TextEntry", -text   => $ABC_DIR,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 8,
		-height => 1, -width  => 25,
		-maxlength => 11,
	);

	my($lblSQLITE) = $winSettings->add(
		"lSQLITE", "Label", -text   => "  SQLITE file: ",
		-x      => 2, -y      => 10,
		-height => 1, -width  => 20,
		-maxlength => 40, -textalignment => 'right',
	);
	my($txtSQLITE) = $winSettings->add(
		"SQLITE", "TextEntry", -text   => $SQLITE,
		-fg     => 'black', -bg     => 'cyan',
		-x      => 25, -y      => 10,
		-height => 1, -width  => 25,
		-maxlength => 40,
	);

	my($settingsCancel) = sub {
		$winSettings->loose_focus();
		$cui->delete('winSettings');
	};

	my($settingsOK) = sub {
		$ABC_DIR = $txtABC_DIR->get();
		$SQLITE  = $txtSQLITE->get();

		$SN      = $txtSN->get();
		$DRIVER  = $boxDRIVER->get();
		$PARAM   = $txtPARAM->get();

		$cfg->newval("MAIN", 'ABC_DIR',  $ABC_DIR);
		$cfg->newval("MAIN", 'SQLITE',   $SQLITE);

		$cfg->newval("DEVICE", 'DRIVER', $DRIVER);
		$cfg->newval("DEVICE", 'PARAM',  $PARAM);
		$cfg->newval("DEVICE", 'SN',     $SN);
		$cfg->RewriteConfig();

		$winSettings->loose_focus();
		$cui->delete('winSettings');
	};

	my($btnBox) = $winSettings->add(
		"btnBox", "Buttonbox" ,
		-y => -1,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $settingsOK },
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $settingsCancel}
		],
		-buttonalignment => 'middle'
	);

	$btnBox->focus();
	$winSettings->modalfocus();
}

sub getStatusDialog {
	my($dh) = loadDriverHandle();

	my($result) = $dh->Status();
	if ($result) {
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Status",
			-message => $result
		);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error getting status",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		)
	}
}

sub getHeadersDialog {
	my($dh) = loadDriverHandle();

	my(@header) = $dh->GetHeaders();
	if (@header) {
		my($i, $header) = (0, "");
		for ($i=0; $i < 12; $i+=2) {
			$header .= "  Header #" . ($i/2+1) . " : (" . $header[$i]. ") [" . $header[$i+1] . "]\n";
		}

		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Get Headers",
			-message => $header
		);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error getting headers",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		);
	}
}

sub setHeadersDialog {
	my($dh) = loadDriverHandle();

	my(@header) = $dh->GetHeaders();
	if ( ! @header) {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error getting headers",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		);
	}

	my($winSetHeaders) = $cui->add(
		'winSetHeaders', 'Window',
		-title		=> 'Set Headers',
		-width          => 84,
		-height         => 24,
		-border         => 1,
		-padtop         => 2,
		-padbottom      => 2,
		-padleft        => 2,
		-padright       => 2,
		-ipad           => 1
	);

	my($i, @lblHeader, @txtHeader, @lblFont, @txtFont);
	for ($i=0; $i < 12; $i+=2) {
		$lblHeader[$i] = $winSetHeaders->add(
			"lHeader$i", "Label", -text   => sprintf("Header Line #%d: ", ($i/2+1)),
			-x      => 1, -y      => $i+1,
			-height => 1, -width  => 16,
			-maxlength => 11, -textalignment => 'right',
		);
		$txtHeader[$i] = $winSetHeaders->add(
			"txtHeader$i", "TextEntry", -text   => $header[$i+1],
			-fg     => 'black', -bg     => 'cyan',
			-x      => 18, -y      => $i+1,
			-height => 1, -width  => 33,
			-maxlength => 32,
		);
		$txtFont[$i] = $winSetHeaders->add(
			"txtFont$i", "Listbox", 
			-values    => [1, 2, 3, 4],
			-labels    => { 1 => 'Normal Printing', 
					2 => 'Double height', 
					3 => 'Double width', 
					4 => 'Double width/height'},
			-selected   => $header[$i]-1,
			-fg     => 'white', -bg     => 'black',
			-x      => 52, -y      => $i+1,
			-height => 1, -width  => 20,
			-maxlength => 11,
		);
	}

	my($setHeadersCancel) = sub {
		$winSetHeaders->loose_focus();
		$cui->delete('winSetHeaders');
	};

	my($setHeadersOK) = sub {
		$winSetHeaders->loose_focus();
		$cui->delete('winSetHeaders');

		my($headersPacked) = "";
		for ($i=0; $i < 12; $i+=2) {
			$headersPacked .= sprintf("%s/%s/", $txtFont[$i]->get(), $txtHeader[$i]->get());
		}

		my($result) = $dh->SetHeaders($headersPacked);
		if ( defined $result && ($result == 0)) {
			$cui->dialog(
				-title => "Set Headers",
				-message => "Headers updated",
				-x => 30, -y => 20
			);
		} else {
			my($errNo)  = $dh->error();
			my($errMsg) = $dh->errMessage($errNo);
			$cui->dialog(
				-fg  => 'cyan', -bg  => 'black',
				-tfg => 'blue', -tbg => 'cyan',
				-bfg => 'blue', -bbg => 'black',
				-title => "Error setting headers",
				-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
			);
		}
	};

	my($btnBox) = $winSetHeaders->add(
		"btnBox", "Buttonbox" ,
		-y => -1,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $setHeadersOK},
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $setHeadersCancel}
		],
		-buttonalignment => 'middle'
	);

	$btnBox->focus();
	$winSetHeaders->modalfocus();
}

sub readTimeDialog {
	my($dh) = loadDriverHandle();

	my($result) = $dh->GetTime();
	if ($result) {
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Device time",
			-message => $result
		);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error reading time",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		)
	}
}

sub setTimeDialog {
	my($dh) = loadDriverHandle();

	my($winSetTime) = $cui->add(
		'winSetTime', 'Window',
				-fg  => 'cyan', -bg  => 'black',
				-tfg => 'blue', -tbg => 'cyan',
				-bfg => 'blue', -bbg => 'black',
		-title		=> 'Set Device time',
		-width          => 60,
		-height         => 10,
		-border         => 1,
		-x => 10, -y => 10,
	);

	my($lblTime) = $winSetTime->add(
		"lTime", "Label", -text   => "Enter time in DD/MM/YY HH:MM:SS format",
		-x      => 2, -y      => 1,
		-height => 1, -width  => 46,
		-maxlength => 11, -textalignment => 'right',
	);

	my($second, $minute, $hour, $dayOfMonth, $month, $yearOffset, $dayOfWeek, $dayOfYear, $daylightSavings) = localtime();
	my($year) = $yearOffset % 100;

	my($txtTime) = $winSetTime->add(
		"Time", "TextEntry", -text  => sprintf("%02d/%02d/%02d %02d:%02d:%02d", $dayOfMonth, $month+1, $year, $hour, $minute, $second),
		-fg     => 'black', -bg     => 'cyan',
		-x      => 20, -y      => 3,
		-height => 1, -width  => 22,
		-maxlength => 18,
	);

	my($settingsCancel) = sub {
		$winSetTime->loose_focus();
		$cui->delete('winSetTime');
	};

	my($settingsOK) = sub {
		my($result) = $dh->SetTime($txtTime->get());
		if ( defined $result && ($result == 0)) {
			$cui->dialog(
				-fg  => 'cyan', -bg  => 'black',
				-tfg => 'blue', -tbg => 'cyan',
				-bfg => 'blue', -bbg => 'black',
				-title => "Device time",
				-message => "Time successfully set"
			);
			$winSetTime->loose_focus();
			$cui->delete('winSetTime');
		} else {
			my($errNo)  = $dh->error();
			my($errMsg) = $dh->errMessage($errNo);
			$cui->dialog(
				-fg  => 'cyan', -bg  => 'black',
				-tfg => 'blue', -tbg => 'cyan',
				-bfg => 'blue', -bbg => 'black',
				-title => "Error setting time",
				-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
			)
		}
	};

	my($btnBox) = $winSetTime->add(
		"btnBox", "Buttonbox" ,
		-y => -2,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $settingsOK },
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $settingsCancel}
		],
		-buttonalignment => 'middle'
	);

	$btnBox->focus();
	$winSetTime->modalfocus();
}

sub readDeviceIdDialog {
	my($dh) = loadDriverHandle();

	if ($dh) {
		my($result) = $dh->Info();
		if ($result) {
			$cui->dialog(
				-title => "Device ID",
				-message => $result,
				-x => 30, -y => 20
			)
		} else {
			my($errNo)  = $dh->error();
			my($errMsg) = $dh->errMessage($errNo);

			$cui->dialog(
				-title => "Error reading device id",
				-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
			)
		}
	}
}

sub versionInfoDialog {
	my($dh) = loadDriverHandle();

	my($result) = $dh->Info();
	if ($result) {
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Device info",
			-message => $result
		);
	} else {
		my($errNo)  = $dh->error();
		my($errMsg) = $dh->errMessage($errNo);
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error Reading version info",
			-message => sprintf("ERROR [0x%02X]: %s\n", $errNo, $errMsg)
		)
	}
}

sub loadDriverHandle {
	my($dh) = new EAFDSS(DRIVER => "EAFDSS::${DRIVER}::${PARAM}", SN => $SN, DIR => $ABC_DIR);

	if (! $dh) {
		$cui->dialog("ERROR: " . EAFDSS->error());
		return undef;
	}

	return $dh;
}

sub reprintInvoice {
	my($text) = shift @_;
	my($sign) = shift @_;

	my($tmp_fname) = "/tmp/reprint-eafdsss.$$";
	open(FH, ">", $tmp_fname) || die "Error opening file $tmp_fname";
	printf(FH $text);
	close(FH);

	system(sprintf('lp -d PDF -o "eafddssreprint=%s" %s', $sign, $tmp_fname));
	
	unlink($tmp_fname);
}

sub browseInvoiceDialog {
	my($winBrowseInvoices) = $cui->add(
		'winBrowseInvoices', 'Window',
		-title		=> 'Browse Invoices',
		-width          => 74,
		-height         => 22,
		-border         => 1,
		-padtop         => 2,
		-padbottom      => 2,
		-padleft        => 2,
		-padright       => 2,
		-ipad           => 1,
		-fg  => 'cyan', -bg  => 'black',
		-tfg => 'blue', -tbg => 'cyan',
		-bfg => 'blue', -bbg => 'black',
	);
	
	my($dbh);
	if ( -e $SQLITE) {
		$dbh = DBI->connect("dbi:SQLite:dbname=$SQLITE","","");
	} else {
		$dbh = DBI->connect("dbi:SQLite:dbname=$SQLITE","","");
		if ($dbh)  {
			$dbh->do("CREATE TABLE invoices" . 
				" (id INTEGER PRIMARY KEY, tm,  job_id, user, job_name, copies, options, signature, text);" );
		}
	}
	unless ($dbh)  {
		$cui->dialog(
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
			-title => "Error",
			-message => "Error opening SQLite DB" 
		);
		$winBrowseInvoices->loose_focus();
		$cui->delete('winBrowseInvoices');
	}

	my($invoices, $invoices_text, $invoices_signature, $keys, $ref);
	my($sth) = $dbh->prepare("SELECT id, tm, signature, job_name, text FROM invoices;");
	my($rv) = $sth->execute;
	while ( $ref = $sth->fetchrow_hashref() ) 
	{
		push(@$keys, $$ref{'id'});
		$invoices->{$$ref{'id'}} = $$ref{'id'} . ". " . $$ref{'job_name'} . " -- ( Date: " .  $$ref{'tm'}. " )";
		$invoices_text->{$$ref{'id'}} = $$ref{'text'};
		$invoices_signature->{$$ref{'id'}} = $$ref{'signature'};
	}

	my($lbInvoice) = $winBrowseInvoices->add(
		"lbInvoice", "Listbox", 
		-values    => $keys,
		-labels    => $invoices,
		-fg     => 'white', -bg     => 'black',
		-x      => 1, -y      => 1,
		-height => 10, -width  => 64,
		-maxlength => 60,
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
	);

	my($browseInvoiceCancel) = sub {
		$winBrowseInvoices->loose_focus();
		$cui->delete('winBrowseInvoices');
	};

	my($browseInvoiceOK) = sub {
		my($winInvoice) = $cui->add(
			'winInvoice', 'Window',
			-title		=> 'View Invoice',
			-width          => 74,
			-height         => 22,
			-border         => 1,
			-padtop         => 2,
			-padbottom      => 2,
			-padleft        => 2,
			-padright       => 2,
			-ipad           => 1,
			-centered       => 1,
			-fg  => 'cyan', -bg  => 'black',
			-tfg => 'blue', -tbg => 'cyan',
			-bfg => 'blue', -bbg => 'black',
		);
		my($viewInvoice) = $winInvoice->add( 
			'viewInvoice', 'TextViewer',
			-vscrollbar     => 1,
			-wrapping       => 1,
			-width          => 74,
			-height         => 10,
			-text => $invoices_text->{$lbInvoice->get()}
		);

		my($btnBox) = $winInvoice->add(
			"btnBox", "Buttonbox" ,
			-y => -1,
			-buttons => [
				{ -label    => '< OK >',
				  -shortcut => 'o',
				  -value    => 1,
				  -onpress  =>  sub {
							$winInvoice->loose_focus();
							$cui->delete('winInvoice');
							$winBrowseInvoices->focus();
							$winBrowseInvoices->modalfocus();
        					},
				},
				{ -label    => '< RePrint>',
				  -shortcut => 'p',
				  -value    => 0,
				  -onpress  => sub {
							reprintInvoice($invoices_text->{$lbInvoice->get()}, $invoices_signature->{$lbInvoice->get()});
							$winInvoice->loose_focus();
							$cui->delete('winInvoice');
							$winBrowseInvoices->focus();
							$winBrowseInvoices->modalfocus();
						}
				}
			],
			-buttonalignment => 'middle'
		);

		$winInvoice->modalfocus();
	};

	my($btnBox) = $winBrowseInvoices->add(
		"btnBox", "Buttonbox" ,
		-y => -1,
		-buttons => [
			{ -label    => '< OK >',
			  -shortcut => 'o',
			  -value    => 1,
			  -onpress  => $browseInvoiceOK},
			{ -label    => '< Cancel >',
			  -shortcut => 'c',
			  -value    => 0,
			  -onpress  => $browseInvoiceCancel}
		],
		-buttonalignment => 'middle'
	);

	$winBrowseInvoices->focus();
	$winBrowseInvoices->modalfocus();
}

sub searchInvoiceDialog {
	$cui->dialog(
		-fg  => 'cyan', -bg  => 'black',
		-tfg => 'blue', -tbg => 'cyan',
		-bfg => 'blue', -bbg => 'black',
		-title => "Help",
		-message =>
			"This will search for previously signed invoices" . "\n"
	);
}

sub checkABCDialog {
	$cui->dialog(
		-fg  => 'cyan', -bg  => 'black',
		-tfg => 'blue', -tbg => 'cyan',
		-bfg => 'blue', -bbg => 'black',
		-title => "Help",
		-message =>
			"This will check validity of the A, B, C files" . "\n"
	);
}

sub helpDialog {
	$cui->dialog(
		-fg  => 'cyan', -bg  => 'black',
		-tfg => 'blue', -tbg => 'cyan',
		-bfg => 'blue', -bbg => 'black',
		-title => "Help",
		-message =>
			"For the moment just read the man page of EAFDSS" . "\n"
	);
}

sub aboutDialog {
	$cui->dialog(
		-fg  => 'cyan', -bg  => 'black',
		-tfg => 'blue', -tbg => 'cyan',
		-bfg => 'blue', -bbg => 'black',
		-title => "About OpenEAFDSS",
		-message =>
			"OpenEAFDSS-GUI.pl ver 0.80 - Copyright (C) 2008 by Hasiotis Nikos " . "\n" .
			"                                                                     " . "\n" .
			"This program is free software: you can redistribute it and/or modify " . "\n" .
			"it under the terms of the GNU General Public License as published by " . "\n" .
			"the Free Software Foundation, either version 3 of the License, or    " . "\n" .
			"(at your option) any later version.                                  " . "\n" .
			"                                                                     " . "\n" .
			"This program is distributed in the hope that it will be useful,      " . "\n" .
			"but WITHOUT ANY WARRANTY; without even the implied warranty of       " . "\n" .
			"MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the        " . "\n" .
			"GNU General Public License for more details.                         " . "\n" .
			"                                                                     " . "\n" .
			"You should have received a copy of the GNU General Public License    " . "\n" .
			"along with this program.  If not, see <http://www.gnu.org/licenses/>." 
	);
}
