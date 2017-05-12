#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;
use vars qw($type $this $other);

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");


$type = param("type");
$this = param($type);
$other = param("other");

do "bk_lib.pl";

&backend_header;

unless ($type && $this) {
	print "No object chosen.\n";
	&backend_footer;
	exit;
}
&$code if $code;
print <<HTML;
<B>Managing $type <U>$this</U></B>:<BR>
HTML

my $dbh = $engine->DBH;

foreach $other (HTML::Merge::Engine::Dependencies($type)) {
	my $nice = ucfirst($other);
	my %pop = $engine->GetHash($other);

	my ($add, $del) = HTML::Merge::Engine::GetSay($type, $other, 'imperative');
	my ($addp, $delp) = HTML::Merge::Engine::GetSay($type, $other, 'past');
	my @here = $engine->Links($type => $this, $other);
	$addp =~ s/^.* //;
	print "${nice}s $addp:<BR>\n";
	if (@here) {
		print "<UL>\n";
		foreach (@here) {
			delete $pop{$_};
			print qq!\t<LI> $_ <A HREF="$ENV{'SCRIPT_NAME'}?$extra&$type=$this&type=$type&action=DEL&other=$other&$other=$_">$del</A>\n!;
		}

		print "</UL>\n";
	} else {
		print "<B>None</B><BR>\n";
	}

	my $flag;
	if (%pop) {
		openform('ADD', 'other');
		print qq!<SELECT NAME="${other}s" SIZE=6 MULTIPLE>\n!;
		foreach (sort keys %pop) {
			print qq!<OPTION VALUE="$_">$_\n!;
		}

		print "</SELECT>\n";
		$flag++;
	} 
	if ($other ne 'user' && $other ne 'template') {
		if ($flag) {
			print "Or:<BR>\n";
		} else {
			openform('ADD', 'other');
		}
		$flag++;
		print <<HTML;
Create new $other:<BR>
New $other: <INPUT NAME="${other}s"><BR>
HTML
	}
	if ($flag) {
		print <<HTML;
<INPUT TYPE=SUBMIT VALUE="$add">
</FORM>
HTML
	}
}


print <<HTML;
<HR>
<A HREF="many.pl?$extra&type=$type">Back to ${type}s</A>
HTML

&backend_footer;

sub doDEL {
	my $rel = param($other);
	unless ($other) {
		print "Unspecified object.\n";
		return;
	}
	unless ($rel) {
		print "Error: $other not specified.<BR>\n";
		return;
	}
	eval { $engine->Assert($type => $this, $other => $rel, 1); };
	if ($@) {
		print "Error: $@<BR>\n";
		return;
	}
	out($type, $other, $this, $rel, 1);
}

sub out {
	my ($child, $parent, $cv, $pv, $e) = @_;
	($child, $parent, $cv, $pv) = ($parent, $child, $pv, $cv)
		unless HTML::Merge::Engine::IsMatrix($child, $parent);
	my $nice = ucfirst($child);
	my ($add, $del) = HTML::Merge::Engine::GetSay($child, $parent, 'past');
	my $msg = $e ? $del : $add;
	print "$nice $cv has $msg $parent $pv.<BR>\n";
}


sub doADD {
	unless ($other) {
		print "Unspecified object.\n";
		return;
	}
	foreach (param("${other}s")) {
		next unless $_;
		eval { $engine->Assert($other => $_, $type => $this); };
		if ($@) {
			print "Error: $@<BR>\n";
			return;
		}
		&out($type, $other, $this, $_);
	}
}


