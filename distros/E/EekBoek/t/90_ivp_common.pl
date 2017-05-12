#! perl

# 90_ivp_common.pl -- Common code for IVPs
# Author          : Johan Vromans
# Created On      : Thu Oct 15 16:27:04 2009
# Last Modified By: Johan Vromans
# Last Modified On: Mon Jan 23 22:51:48 2012
# Update Count    : 126

use strict;
use warnings;

# The actual number of database tests, as executed by report_tests.
use constant NUMTESTS => 38;
# There are 9 initial tests.
# report_tests requires 1 more for the setup, and 1 for the export
# (all but the last).

my $remaining;
use Test::More
  $ENV{EB_SKIPDBTESTS} ? (skip_all => "Database tests skipped on request")
  : (tests => ( $remaining = 3*(NUMTESTS+2)-1+10 ));

use warnings;
BEGIN { use_ok('IPC::Run3') }
BEGIN { use_ok('EB::Config') }
BEGIN { use_ok('EB') }
BEGIN { use_ok('File::Copy') }
EB->app_init( { app => "ivp" } );
ok( $::cfg, "Got config");

$remaining -= 5;

our $dbdriver;
my $dbddrv;
$dbdriver = "postgres" unless $dbdriver;
if ( $dbdriver eq "postgres" ) {
    $dbddrv = "DBD::Pg";
}
elsif ( $dbdriver eq "sqlite" ) {
    $dbddrv = "DBD::SQLite";
}
BAIL_OUT("Unsupported database driver: $dbdriver") unless $dbddrv;

my $l = $ENV{LANG};
$l =~ s/_.*//;
for ( "ivp_".$ENV{LANG}, "ivp_$l", "ivp" ) {
    chdir($_), last if -d $_;
}

SKIP: {
    diag("This test is not yet implemented -- SKIPPED") unless -d "ref";
    skip("This test is not yet implemented", $remaining) unless -d "ref";

    my $f;
    for ( qw(opening.eb relaties.eb mutaties.eb schema.dat) ) {
	ok(1, $_), next if -s $_;
	if ( $f = findlib($_, "examples") and -s $f ) {
	    copy($f, $_);
	}
	ok(-s $_, $_);
    }
    $remaining -= 4;
    for ( qw(ivp.conf opening.eb relaties.eb
	     mutaties.eb reports.eb schema.dat ) ) {
	die("=== IVP configuratiefout: $_ ===\n") unless -s $_;
    }

    mkdir("out") unless -d "out";
    ok( -w "out" && -d "out", "writable output dir" );
    $remaining--;

    eval "require $dbddrv";
    skip("DBI $dbdriver driver ($dbddrv) not installed", $remaining) if $@;

    # Cleanup old files.
    unlink( glob("out/*.sql") );
    unlink( glob("out/*.log") );
    unlink( glob("out/*.txt") );
    unlink( glob("out/*.html") );
    unlink( glob("out/*.csv") );
    unlink( glob("ebsqlite_sample*") );

    my @ebcmd = qw(-MEB::Main -e EB::Main->run -- -X -f ivp.conf --echo);
    push(@ebcmd, "-D", "database:driver=$dbdriver") if $dbdriver;

    unshift(@ebcmd, map { ("-I",
			   "../../$_"
			  ) } grep { /^\w\w/ } reverse @INC);
    unshift(@ebcmd, $^X);

    # Check whether we can contact the database.
    eval {
	if ( $dbdriver eq "postgres" ) {
	    my @ds = DBI->data_sources("Pg");
	    diag("Connect error:\n\t" . ($DBI::errstr||""))
	      if $DBI::errstr;
	    skip("No access to database", $remaining)
	      if $DBI::errstr;
	      # && $DBI::errstr =~ /FATAL:\s*(user|role) .* does not exist/;
	}
    };

    #### PASS 1: Construct from distributed files.
    for my $log ( "out/init.log" ) {
	ok(syscmd([@ebcmd, qw(--init)], undef, $log), "init");
	checkerr($log);
    }

    report_tests(@ebcmd);

    for my $log ( "out/export1.log" ) {
	ok(syscmd([@ebcmd, qw(--export --dir=out)], undef, $log), "export1");
	checkerr($log);
    }

    #### PASS 2: Construct from exported files.
    for my $log ( "out/import1.log" ) {
	ok(syscmd([@ebcmd, qw(--import --dir=out)], undef, $log), "import1");
	checkerr($log);
    }

    report_tests(@ebcmd);

    for my $log ( "out/export2.log" ) {
	ok(syscmd([@ebcmd, qw(--export --file=out/export2.ebz)], undef, $log), "export2");
	checkerr($log);
    }

    #### PASS 3: Construct from exported .ebz .
    for my $log ( "out/import2.log" ) {
	ok(syscmd([@ebcmd, qw(--import --file=out/export2.ebz)], undef, $log), "import2");
	checkerr($log);
    }

    report_tests(@ebcmd);


}	# end SKIP

################ subroutines ################

sub report_tests {
    my @ebcmd = @_;

    for my $log ( "out/reports.log" ) {
	ok(syscmd(\@ebcmd, "reports.eb", $log), "reports");
	checkerr($log);
	$remaining--;
    }

    # Verify: balans in varianten.
    vfy([@ebcmd, qw(-c balans)           ], "balans.txt" );
    vfy([@ebcmd, qw(-c balans --detail=0)], "balans0.txt");
    vfy([@ebcmd, qw(-c balans --detail=1)], "balans1.txt");
    vfy([@ebcmd, qw(-c balans --detail=2)], "balans2.txt");
    vfy([@ebcmd, qw(-c balans --verdicht)], "balans2.txt");
    vfy([@ebcmd, qw(-c balans --opening) ], "obalans.txt");

    # Verify: verlies/winst in varianten.
    vfy([@ebcmd, qw(-c result)           ], "result.txt" );
    vfy([@ebcmd, qw(-c result --detail=0)], "result0.txt");
    vfy([@ebcmd, qw(-c result --detail=1)], "result1.txt");
    vfy([@ebcmd, qw(-c result --detail=2)], "result2.txt");
    vfy([@ebcmd, qw(-c result --verdicht)], "result2.txt");

    # Verify: Journaal.
    vfy([@ebcmd, qw(-c journaal)            ], "journaal.txt");
    # Verify: Journaal van dagboek.
    vfy([@ebcmd, qw(-c journaal postbank)   ], "journaal-postbank.txt");
    # Verify: Journaal van boekstuk.
    vfy([@ebcmd, qw(-c journaal postbank:24)], "journaal-postbank24.txt");

    # Verify: Proef- en Saldibalans in varianten.
    vfy([@ebcmd, qw(-c proefensaldibalans)           ], "proef.txt");
    vfy([@ebcmd, qw(-c proefensaldibalans --detail=0)], "proef0.txt");
    vfy([@ebcmd, qw(-c proefensaldibalans --detail=1)], "proef1.txt");
    vfy([@ebcmd, qw(-c proefensaldibalans --detail=2)], "proef2.txt");
    vfy([@ebcmd, qw(-c proefensaldibalans --verdicht)], "proef2.txt");

    # Verify: Grootboek in varianten.
    vfy([@ebcmd, qw(-c grootboek)           ], "grootboek.txt"      );
    vfy([@ebcmd, qw(-c grootboek --detail=0)], "grootboek0.txt"     );
    vfy([@ebcmd, qw(-c grootboek --detail=1)], "grootboek1.txt"     );
    vfy([@ebcmd, qw(-c grootboek --detail=2)], "grootboek2.txt"     );
    vfy([@ebcmd, qw(-c grootboek 2)         ], "grootboek_2.txt"    );
    vfy([@ebcmd, qw(-c grootboek 23)        ], "grootboek_23.txt"   );
    vfy([@ebcmd, qw(-c grootboek 23 22)     ], "grootboek_23_22.txt");
    vfy([@ebcmd, qw(-c grootboek 2320)      ], "grootboek_2320.txt" );

    # Verify: Crediteuren/Debiteuren.
    vfy([@ebcmd, qw(-c crediteuren)         ], "crdrept.txt");
    vfy([@ebcmd, qw(-c debiteuren)          ], "debrept.txt");

    # Verify: BTW aangifte.
    vfy([@ebcmd, qw(-c btwaangifte j)       ], "btw.txt"  );
    vfy([@ebcmd, qw(-c btwaangifte k2)      ], "btwk2.txt");
    vfy([@ebcmd, qw(-c btwaangifte 7)       ], "btw7.txt" );

    # Verify: HTML generatie.
    vfy([@ebcmd, qw(-c balans --detail=2 --gen-html)            ], "balans2.html");
    vfy([@ebcmd, qw(-c balans --detail=2 --gen-html --style=xxx)], "balans2xxx.html");
    vfy([@ebcmd, qw(-c btwaangifte j)], "btw.html");

    # Verify: CSV generatie.
    vfy([@ebcmd, qw(-c balans --detail=2 --gen-csv)], "balans2.csv");

    # Verify: XAF generatie.
    vfy([@ebcmd, qw(-c export --xaf=out/export.xaf)], "export.xaf");
}

sub vfy {
    my ($cmd, $ref) = @_;
    my @c = @$cmd;
    while ( shift(@c) ne "-c" ) { }
    if ( $ref =~ /\.xaf$/ ) {
	push( @c, "--xaf=$ref" );
    }
    else {
	push( @c, "--output=$ref" );
    }
    ok(!diff($ref), $ref);
}

sub vfyxx {
    my ($cmd, $ref) = @_;
    syscmd($cmd, undef, $ref);
    ok(!diff($ref), $ref);
}

sub diff {
    my ($file1, $file2) = @_;
    $file2 = "ref/$file1" unless $file2;
    $file1 = "out/$file1";
    my ($str1, $str2);
    local($/);
    open(my $fd1, "<:encoding(utf-8)", $file1) or die("$file1: $!\n");
    $str1 = <$fd1>;
    close($fd1);
    open(my $fd2, "<:encoding(utf-8)", $file2) or die("$file2: $!\n");
    $str2 = <$fd2>;
    close($fd2);
    $str1 =~ s/^EekBoek \d.*Squirrel Consultancy\n//;
    $str1 =~ s/[\n\r]+/\n/;
    $str2 =~ s/[\n\r]+/\n/;
    return 0 if $str1 eq $str2;
    1;
}

sub syscmd {
    my ($cmd, $in, $out, $err) = @_;
    $in = \undef unless defined($in);
    $err = $out if @_ < 4;
    #warn("+ @$cmd\n");
    run3($cmd, $in, $out, $err);
    printf STDERR ("Exit status 0x%x\n", $?) if $?;
    $? == 0;
}

sub checkerr {
    my $fail;
    unless ( -s $_[0] ) {
	warn("$_[0]: Bestand ontbreekt, of is leeg\n");
	$fail++;
    }
    open(my $fd, "<", $_[0]) or die("$_[0]: $!\n");
    while ( <$fd> ) {
	next unless /(^\?|^ERROR| at .* line \d+)/;
	warn($_);
	$fail++;
    }
    close($fd);
    die("=== IVP afgebroken ===\n") if $fail;
}

1;
