#!/usr/bin/perl
##################################################################
# web_ini.pl - Gets the data to update in the ini.pm             #
#              from the Merge Configuration Web page             #
# Author : Eial Solodki                                          #
# All right reserved - Raz Information Systems Ltd.(c) 1999-2002 #
# Date : 07/05/2001                                              #
# updated :                                                      #
##################################################################

use HTML::Merge::Engine;
use HTML::Merge::Development;

use CGI qw/:standard/;
use strict qw(vars subs);

ReadConfig();

if ($ENV{'HTTP_REFERER'} =~ /chpass\.pl/) {
	my $curr = param('CURRENT_PASSWORD');
	my $mine = $HTML::Merge::Ini::ROOT_PASSWORD;
	my $check = crypt($curr, $mine);
	if ($check ne $mine) {
		print "Location: chpass.pl?$extra&r=Incorrect+password\n\n";
		exit;
	}
	my $new = param('ROOT_PASSWORD');
	if (param('DOUBLE_PASSWORD') ne $new) {
		print "Location: chpass.pl?$extra&r=Password mismatch\n\n";
		exit;
	}
	if ($new =~ /./) {
		$@ = undef;
		eval{ require Data::Password; };

		unless($@)
		{
			my $reason = Data::Password::IsBadPassword($new) ;
			if ($reason) {
				require URI::Escape;
				my $p = URI::Escape::uri_escape("bad password - $reason");
				print "Location: chpass.pl?$extra&r=$p\n\n";
				exit;
			}
		}
	}
}

my $state = 0;
open(INPUT, $file);
my @lines;
while (<INPUT>) {
	chop;
	if (!$state) {
		$state++ if /^package/;
	} elsif ($state == 1) {
		$state++ if /^#/;
	} else {
		next if /^#/;
		@lines = ($_);
		last;
	}
}

while (<INPUT>) {
        chop;
	last if (/^return /);
	eval {
		require Text::Tabs;
		($_) = Text::Tabs::expand($_);
	};
	push(@lines, $_);
}

close(INPUT);

my @vars = param();
my %hash;
@hash{@vars} = @vars;
my $code;
my $db_pass = HTML::Merge::Engine::Convert(param('DB_PASSWORD'), 1);
my $root_pass;

foreach my $v (@vars) {
	my $item =join(",", grep /./, param($v));
	$item =~ s/'/\\'/g;
	if ($v eq 'SUPPORT_SITE') {
		eval '
			use URI::Heuristic qw(uf_uristr);
			$item = uf_uristr($item);
		';
	}
	if ($v eq 'DB_PASSWORD2') {
		$item = $db_pass;
	}
	if ($v eq 'DB_PASSWORD') {
		$item = '';
	}
	if ($v eq 'ROOT_PASSWORD') {
		my $salt = pack("C2", int(rand(26) + 65), int(rand(26) + 97));
		$root_pass = $item = crypt(param('ROOT_PASSWORD'), $salt);
	}

	foreach (@lines) {
		my $extra;
		my $pos;
		if (/;\s*#/) {
			$pos = length($_) - length($') - 1;
			$extra = substr($_, $pos);
		}
			
		if (s/\$$v\s*=.*$/\$$v = '$item';/) {
			delete $hash{$v};
			if ($extra) {
				$_ = sprintf("%-${pos}s", $_) . $extra;
			}
		}
	}
}

if (%hash) {
	foreach (keys %hash) {
		my $item = join(",", grep /./, param($_));
		$item =~ s/'/\\'/g;
		push(@lines, "\$$_ = '$item';");
	}
}

unless (open(OUTPUT, ">$file")) {
	print "Status: 403 Permission denied\n";
	print "Content-type: text/plain\n\n";
	print "Could not rewrite $file: $!";
	exit;
}

HTML::Merge::Development::WriteConfig(\*OUTPUT);

print OUTPUT join("\n", grep {$_ ne "1;\n"} @lines, "");
print OUTPUT "1;\n";

close OUTPUT;

&ReadConfig; # Need to read $file and calculate $extra

if (defined($root_pass)) {
	open(I, "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/.htmerge");
	my @lines = grep {! /^$HTML::Merge::Ini::ROOT_USER\:/ } <I>;
	close(I);
	open(O, ">$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/.htmerge");
	print O join("", @lines);
	print O "$HTML::Merge::Ini::ROOT_USER\:$root_pass\n";
	close(O);
}

if ($ENV{'HTTP_REFERER'} =~ /chpass\.pl/) {
	print "Content-type: text/html\n\n";
	print <<HTML;
<HTML>
<BODY onLoad="doit();">
<SCRIPT>
	function doit() {
		opener.focus();
		opener.location.reload();
		window.close();
	}
</SCRIPT>
</BODY>
</HTML>
HTML
	exit;
}

print "Location: pre_web_ini.pl?$extra\n\n";
