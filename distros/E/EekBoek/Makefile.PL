# Makefile.PL -- Build file for EekBoek
# Author          : Johan Vromans
# Created On      : Fri Sep  2 14:25:11 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Aug 29 16:22:07 2017
# Update Count    : 119
# Status          : Unknown, Use with caution!

# Ease the life of the CPAN testers.
exit 0 if $ENV{AUTOMATED_TESTING} && $] < 5.008006;

use 5.008006;

use strict;

# EU::MM 6.5503 is the first version to understand *_REQUIRES.
use ExtUtils::MakeMaker 6.5503;

my $distname = 'EekBoek';
my $version = MM->parse_version('lib/EB/Version.pm');

my @bins = qw( ebshell ebwxshell );

# Warn on non-standard install locations.
checkbin(<<EOD);
Please consult section "Determination of Perl Library and Installation
Locations" of the ExtUtils::MakeMaker documentation section if you
want to change this location.
EOD

# Write Makefile.
WriteMakefile
(
 NAME             => $distname,
 AUTHOR	          => 'Johan Vromans (jvromans@squirrel.nl)',
 ABSTRACT_FROM    => 'lib/EekBoek.pm',
 PL_FILES         => {'script/ebpp.PL' => [ map { "script/$_" } @bins ]},
 INSTALLDIRS      => 'site',
 DISTNAME         => $distname,
 EXE_FILES        => [ map { "script/$_" } @bins ],
 VERSION          => $version,
 MIN_PERL_VERSION => 5.008006,

 PREREQ_PM   => {
     'Getopt::Long'     => '2.13',
     'Term::ReadLine'   => 0,
     $^O eq "linux" ? ('Term::ReadLine::Gnu' => 0) : (),
     'DBI'              => '1.40',
     'Archive::Zip'	=> '1.16',
     'DBD::SQLite'      => '1.13',
 },

 CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => 6.5503,
 },

# BUILD_REQUIRES => {
# },

 TEST_REQUIRES  => {
    'Test::More'  => 0,
    'IPC::Run3' => 0.034,
 },

 PM          => filelist("lib", '$(INST_LIBDIR)/'),

 META_MERGE => {
     license   => "perl",
     resources => {
	 license    => "https://dev.perl.org/licenses/",
	 homepage   => "https://www.eekboek.nl",
	 repository => {
	     web  => "https://sourceforge.net/p/eekboek/code/",
	     url  => "git://git.code.sf.net/p/eekboek/code",
	     type => "git",
	 },
     },
     recommends => {
         'DBD::Pg'        => 1.41,
	 'Getopt::Long'   => 2.32,
         'HTML::Entities' => 1.35,
     },
     provides => {
	 'EekBoek' => { file => "lib/EekBoek.pm",
			version => $version },
     },
     no_index => {
         directory => [
	    "lib/EB",
	 ],
     },
 },


);

# Write .spec file, Debian control, ...
ProcessTemplates($distname, $version);

################ Subroutines ################

use Config;

sub checkbin {
    my ($msg) = @_;
    my $installscript = $Config{installscript};

    return if $installscript eq "/usr/bin";
    print STDERR <<EOD;

WARNING: This build process will install user accessible scripts.
The default location for user accessible scripts is
$installscript.
EOD
    print STDERR ($msg);
}

sub filelist {
    my ($dir, $pfx) = @_;
    $pfx ||= "";
    my $dirp = quotemeta($dir . "/");
    my $pm;

    open(my $mf, "MANIFEST") or die("Missing MANIFEST file.\n");
    while ( <$mf> ) {
	chomp;
	next unless /$dirp(.*)/;
	$pm->{$_} = $pfx ? $pfx . $1 : $_;
    }
    close($mf);
    $pm;
}

sub ProcessTemplates {
    my $name    = shift;
    my $version = shift;

    my ($mv) = $version =~ /^\d+\.(\d+)/;
    my %vars =
      ( PkgName	   => $name,
	pkgname	   => lc($name),
	version	   => $version,
	stable	   => $mv % 2 ? "-unstable" : "\%nil",
	stability  => $mv % 2 ? "unstable" : "stable",
      );

    vcopy( _tag	    => "XAF ref file",
	   _dst	    => "t/ivp/ref/export.xaf",
	   %vars);

=begin Fedora

    vcopy( _tag	    => "RPM spec file",
	   _dst	    => "$name.spec",
	   %vars);

=cut

=begin Debian

    vcopy( _tag	    => "Debian control file",
	   _dst	    => "debian/control",
	   %vars);

    vcopy( _tag	    => "Debian rules file",
	   _dst	    => "debian/rules",
	   %vars);
	 );
    chmod((((stat("debian/rules"))[2] & 0777) | 0111), "debian/rules");

    vcopy( _tag	    => "Debian changelog file",
	   _dst	    => "debian/changelog",
	   %vars);

=end

=cut

}

sub vcopy {
    my (%ctrl) = @_;

    $ctrl{_src} ||= $ctrl{_dst} . ".in";

    return unless open(my $fh, "<", $ctrl{_src});

    print("Writing ", $ctrl{_tag}, "...\n") if $ctrl{_tag};

    my $newfh;
    open ($newfh, ">", $ctrl{_dst})
      or die($ctrl{_dst}, ": $!\n");

    my $pat = "(";
    foreach ( grep { ! /^_/ } keys(%ctrl) ) {
	$pat .= quotemeta($_) . "|";
    }
    chop($pat);
    $pat .= ")";

    $pat = qr/\[\%\s+$pat\s+\%\]/;

    while ( <$fh> ) {
	s/$pat/$ctrl{$1}/ge;
	print { $newfh } $_;
    }
    close($newfh);
}

1;
