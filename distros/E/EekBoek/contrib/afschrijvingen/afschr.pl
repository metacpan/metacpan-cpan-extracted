#!/usr/bin/perl
my $RCS_Id = '$Id: skel.pl,v 1.7 1998-02-06 11:41:12+01 jv Exp $ ';

# Author          : Johan Vromans
# Created On      : Tue Sep 15 15:59:04 1998
# Last Modified By: Johan Vromans
# Last Modified On: Sat May 10 19:03:19 2008
# Update Count    : 215
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use locale;

# Package name.
my $my_package = 'EekBoek';
# Program name and version.
my ($my_name, $my_version) = $RCS_Id =~ /: (.+).pl,v ([\d.]+)/;
$my_name = 'Afschrijvingen';
# Tack '*' if it is not checked in into RCS.
$my_version .= '*' if length('$Locker:  $ ') > 12;

################ Command line parameters ################

use Getopt::Long 2.13;
sub app_options();

my $eb;				# EekBoek boekingen
my $gr;				# only group totals
my $oy;				# order by year
my $html;			# produce HTML
my $adm;			# admin name

app_options();

################ The Process ################

$^L = "\n";

use Time::Local;

sub min { $_[0] < $_[1] ? $_[1] : $_[0] }

my @data;
my @grdata;
my %grdesc;
my $ythis = 1900 + (localtime())[6];

while ( <> ) {

    # Skip comments and empty lines.
    next if /^#/;
    next unless /\S/;

    # Detect group identifiers
    if (/^(\d+)\s+(\d+)\s*=\s*(\S.*?)\s*$/) {
       $grdesc{"${1}:${2}"} = $3;
       next;
    }

    # Split up.
    my ( $date, $amt, $rest, $n, @desc ) = split;

    # Check for account numbers.
    my ($bal, $res);
    ($bal, $res) = splice(@desc, 0, 2)
      if @desc > 2 && $desc[0] =~ /^\d+$/ && $desc[1] =~ /^\d+$/;

    my $desc = "@desc";
    my @aux = ($desc, $date, $amt, $rest, $n, $bal, $res);

    my ( $year, $month, $day );
    if ( $date =~ /^(\d\d\d\d)-?(\d\d)-?(\d\d)$/ ) {
	( $year, $month, $day ) = ( $1, $2, $3);
    }
    elsif ( $date =~ /^(\d\d\d\d)$/ ) {
	( $year, $month, $day ) = ( $1, 1, 1 );
    }

    # Beginwaarde.
    my $val = $amt;

    # Tijdstip van aanschaf.
    my $t1 = timelocal (0, 0, 0, $day, $month-1, $year);

    # Zolang er meer is dan de restwaarde.
    while ( $val > $rest ) {

	# Eind van het boekjaar.
	my $t2 = timelocal (0, 0, 0, 1, 0, $year+1);

	# Tijdspanne.
	my $d1 = $t2 - $t1;

	# Gedeelte in dit jaar.
	my $d2 = $t2 - timelocal (0, 0, 0, 1, 0, $year);

	# Afschrijving,
	my $decr = ($amt - $rest) / $n * $d1 / $d2;
	$decr = $val-$rest if $val -$decr < $rest;

	# Waardevermindering.
	$val -= $decr;

	# Sla op.
	push (@data, [$year, $decr, min($rest,$val), @aux]);
	push_group (\@grdata, \%grdesc, [$year, $decr, min($rest,$val), @aux]);

	# Naar volgend jaar.
	$year++;
	$t1 = $t2;
    }
}

my ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res);

if ( $gr ) {
    @data = @grdata;
    $~ = 'GROUP';
    $^ = 'GROUP_TOP';
}

if ( !defined($eb) || !$eb ) {
    my $this = "";

    if ( defined($oy) ) {
	do_template(join("", <DATA>)) if $html;
	foreach ( sort { $a->[0] <=> $b->[0] or $a->[3] cmp $b->[3] } @data ) {
	    ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res) = @$_;
	    if ( $this ne $year ) {
		$this = $year;
		$- = 0;
	    }
	    next if $oy && $year != $oy;
	    do_write();
	}
	if ( $html ) {
	    do_template(<<EOD);
</table>
<p class="footer">Overzicht aangemaakt op [% bky %]-12-31 door <a href="http://www.eekboek.nl">EekBoek</a></p>
</body>
</html>
EOD
	}
    }
}

if ( !defined($eb) || $eb ) {
    my $fmt = "        std 31-12 %-34s %9.2f %4d";
    foreach ( sort {$a->[0] <=> $b->[0] or $a->[3] cmp $b->[3] } @data ) {
	my ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res) = @$_;
	next unless defined($bal) && defined($res);
	$desc = "\"Afschrijving $desc\"";
	printf STDOUT ("# Afschrijving %4d %s, balanswaarde = %.2f -> %.2f\n".
		       "memoriaal 31-12 %s \\\n".
		       "$fmt \\\n".
		       "$fmt\n\n",
		       $year, $_->[3], $v+$af, $v,
		       $desc,
		       $desc, $af, $bal,
		       $desc, -$af, $res);
    }
}

################ Subroutines ################

sub app_ident;
sub app_usage($);

sub app_options() {
    my $help = 0;		# handled locally
    my $ident = 0;		# handled locally

    # Process options, if any.
    # Make sure defaults are set before returning!
    return unless @ARGV > 0;

    if ( !GetOptions(
		     'adm=s'           => \$adm,
		     'eb|eekboek!'     => \$eb,
		     'groups'          => \$gr,
		     'oy|order-year:i' => \$oy,
		     'html'            => \$html,
		     'ident'	       => \$ident,
		     'help|?'	       => \$help,
		    ) or $help )
    {
	app_usage(2);
    }
    app_ident if $ident;
    $oy = 0 if defined($oy) && $oy <= 1900;
    if ( $html ) {
	die("--html requires --oy=YYYY\n") if $oy <= 1900;
	die("--html requires --adm=XXX\n") unless $adm;
	die("--html cannot (yet) be used with --groups\n") if $gr;
	$eb = 0;
    }
}

sub app_ident {
    print STDERR ("This is $my_package [$my_name $my_version]\n");
}

sub app_usage($) {
    my ($exit) = @_;
    app_ident;
    print STDERR <<EndOfUsage;
Usage: $0 [options] [file ...]
    --eb   --eekboek	only EekBoek bookings
    --noeb --noeekboek	no EekBoek bookings
    --order-year --oy [YEAR] order by (this) year
    --group             order per group
    --html		produce HTML (requires --oy and --adm)
    --adm=NAME		admin name
    --help		this message
    --ident		show identification
EndOfUsage
    exit $exit if $exit != 0;
}

sub html {
    my $t = shift;
    $t =~ s/&/&amp;/g;
    $t =~ s/>/&gt;/g;
    $t =~ s/</&lt;/g;
    $t =~ s/"/&quot;/g;
    $t;
}

sub numfmt {
    my $t = sprintf("%.2f", shift);
    $t =~ s/\./,/;
    $t;
}

sub do_template {
    my ($t) = @_;

    my %ctrl =
      ( title	   => "Afschrijfstaat",
	bky	   => $oy,
	adm	   => html($adm),
      );
    my $pat = "(";
    foreach ( grep { ! /^_/ } keys(%ctrl) ) {
	$pat .= quotemeta($_) . "|";
    }
    chop($pat);
    $pat .= ")";

    $pat = qr/\[\%\s+$pat\s+\%\]/;

    $t =~ s/$pat/$ctrl{$1}/ge;
    print($t);
}

sub do_write {
    if ( $date =~ /(\d\d\d\d)-?(\d\d)-?(\d\d)/ ) {
	$date = "$3-$2-$1";
    }
    else {
	$date = $html ? "Boekwaarde $date" : "Boekw $date";
    }
    if ( !$html ) {
	write;
	return;
    }
    print <<EOD;
<tr>
<td class="c_desc">@{[html($desc)]}</th>
<td class="c_aans">$date</th>
<td class="c_val">@{[numfmt($amt)]}</th>
<td class="c_n">$n</th>
<td class="c_rest">@{[numfmt($rest)]}</th>
<td class="c_begn">@{[numfmt($v+$af)]}</th>
<td class="c_afs">@{[numfmt($af)]}</th>
<td class="c_eind">@{[numfmt($v)]}</th>
</tr>
EOD
}

sub push_group {
    my ($grdata, $grdesc, $elem) = @_;
    my ($year, $af, $v, $desc, $date, $amt, $rest, $n, $bal, $res) = @$elem;
    foreach (@$grdata) {
        if ($$_[0] == $year and $$_[8] == $bal and $$_[9] == $res) {
            $$_[1] += $af;
            $$_[2] += $v;
            return;
        }
    }
    my $d = $$grdesc{"${bal}:${res}"};
    $$elem[3] = $d ? $d : "Group-${bal}-${res}";
    push(@$grdata, $elem);
}

format STDOUT_TOP =
@>>>  @<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<  @>>>>>>>  @>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
"Jaar", "Omchrijving", "Aanschaf", "Waarde", "N", "Rest", "Begin", "Afschr.", "Eind"
----  --------------------  ----------  --------  --  --------  --------  --------  --------
.
format STDOUT =
@>>>  @<<<<<<<<<<<<<<<<<<<  @<<<<<<<<<  @>>>>>>>  @>  @>>>>>>>  @>>>>>>>  @>>>>>>>  @>>>>>>>
$year, $desc, $date, sprintf("%.2f",$amt), $n, sprintf("%.2f",$rest), sprintf("%.2f",$v+$af), sprintf("%.2f",$af), sprintf("%.2f",$v)
.

format GROUP_TOP =
@>>>  @<<<<<<<<<<<<<<<<<<<  @>>>>>>>  @>>>>>>>  @>>>>>>>
"Jaar", "Omchrijving", "Begin", "Afschr.", "Eind"
----  --------------------  --------  --------  --------
.
format GROUP =
@>>>  @<<<<<<<<<<<<<<<<<<<  @>>>>>>>  @>>>>>>>  @>>>>>>>
$year, $desc, sprintf("%.2f",$v+$af), sprintf("%.2f",$af), sprintf("%.2f",$v)
.
__END__
<html>
<head>
<title>[% title %]</title>
<style type="text/css">
body {
    font-family: Verdana, Arial, Helvetica, sans-serif;
    font-size: 12px;
}

.title {
    font-family: Verdana, Arial, Helvetica, sans-serif;
    font-size: 100%;
    font-weight: bold;
    margin-top: 0pt;
    margin-bottom: 0pt;
}

.subtitle {
    font-family: Verdana, Arial, Helvetica, sans-serif;
    font-size: 100%;
    font-weight: bold;
    margin-top: 0pt;
}

.footer {
    font-family: Verdana, Arial, Helvetica, sans-serif;
    font-size: 80%;
    font-weight: normal;
}

body {
    font-family: Verdana, Arial, Helvetica, sans-serif;
    line-height: 150%;
    color: #000000;
    table-width: 100%;
}

table {
    border: thin solid #000000;
    border-collapse: collapse;
}
table td {
    border-left:  thin solid #000000;
    border-right: thin solid #000000;
}
table th {
    border-left:  thin solid #000000;
    border-right: thin solid #000000;
    border-bottom: thin solid #000000;
}

th { vertical-align: top }
tr { vertical-align: top }

.c_acct, .h_acct {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: left;
}

.c_desc, .h_desc {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: left;
}

.c_aans, .h_aans {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: left;
}

.c_val, .h_val {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}

.c_n, .h_n {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}

.c_rest, .h_rest {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}

.c_begn, .h_begn {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}

.c_afs, .h_afs {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}

.c_eind, .h_eind {
    padding-left: 10pt;
    padding-right: 10pt;
    text-align: right;
}
</style>
</head>
<body>
<p class="title">[% title %]</p>
<p class="subtitle">Periode: [% bky %]-01-01 t/m [% bky %]-12-31<br>
[% adm %]</p>
<table class="main">
<tr class="head">
<th class="h_desc">&nbsp;</th>
<th class="h_aans" style="text-align:center" colspan="2">Aanschaf</th>
<th class="h_n" style="text-align:center" colspan="2">Afschrijving</th>
<th class="h_begn" style="text-align:center" colspan="3">Periode</th>
</tr>
<tr class="head">
<th class="h_desc">Omschrijving</th>
<th class="h_aans">Datum</th>
<th class="h_val">Waarde</th>
<th class="h_n">Jr</th>
<th class="h_rest">Restant</th>
<th class="h_begn">Begin</th>
<th class="h_afs">Afschr.</th>
<th class="h_eind">Eind</th>
</tr>
