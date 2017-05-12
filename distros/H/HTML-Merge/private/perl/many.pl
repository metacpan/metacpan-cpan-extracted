#!/usr/bin/perl

use CGI qw/:standard/;
use HTML::Merge::Development;
use HTML::Merge::Engine qw(:unconfig);
use strict;
use vars qw($type);

&ReadConfig();
my %engines;
tie %engines, 'HTML::Merge::Engine';
my $engine = $engines{""};

my $action = param('action');
my $code = UNIVERSAL::can(__PACKAGE__, "do$action");
$type = param('type');

do "bk_lib.pl";

&backend_header;

unless ($type) {
	print "Object not specified.<BR>\n";
	&backend_footer;
	exit;
}

&$code if $code;
my $nice = ucfirst($type);
print <<HTML;
<B>$nice manager</B>:<BR>
<UL>
HTML

my %pop;
my $dbh = $engine->DBH;
foreach ($engine->GetVector($type)) {
	$pop{$_}++;
	print qq!\t<LI><A HREF="one.pl?$extra&$type=$_&type=$type">Manage $type $_</A>\n!;
}
print <<HTML;
</UL>
HTML

my @children = HTML::Merge::Engine::Dependencies($type);

foreach my $child (@children) {
	foreach ($engine->Linkers($type, $child)) {
		delete $pop{$_};
	}
}

if (%pop) {
	print <<HTML;
</UL>
Empty ${type}s:
<UL>
HTML
	foreach (sort keys %pop) {
		print qq!\t<LI> $_ <A HREF="$ENV{'SCRIPT_NAME'}?$extra&action=DESTROY&$type=$_&type=$type">Destroy</A>\n!;
	}
	print <<HTML;
</UL>
HTML
}

print <<HTML;
HTML
openform("CREATE");
print <<HTML;
New $type name:
<INPUT NAME="$type">
<INPUT TYPE=SUBMIT VALUE="Create new $type">
</FORM>
<HR>
<A HREF="menu.pl?$extra">Menu</A>
HTML

&backend_footer;

sub doDESTROY {
	my $item = param($type);
	eval { $engine->Destruct($type => $item); };
	if ($@) {
		print "Error: $@<BR>\n";
		return;
	}
	my $nice = ucfirst($type);
	print "$nice $item erased.<BR>\n";
}

sub doCREATE {
	my $item = param($type);
	eval { $engine->GetIndex($type => $item); };
	if ($@) {
		print "Error: $@<BR>\n";
		return;
	}
	my $nice = ucfirst($type);
	print "$nice $item created.<BR>\n";
}
