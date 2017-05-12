# build_common.inc -- Build file common info -*- perl -*-
# RCS Info        : $Id: build_common.pl,v 1.27 2010/03/29 15:37:55 jv Exp $
# Author          : Johan Vromans
# Created On      : Thu Sep  1 17:28:26 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Aug 28 21:32:23 2012
# Update Count    : 107
# Status          : Unknown, Use with caution!

use strict;
use Config;
use File::Spec;

our $data;

$data =
  { %$data,
    author          => 'Johan Vromans (jvromans@squirrel.nl)',
    abstract        => 'Elementary Bookkeeping (for the Dutch/European market)',
    PL_files        => {},
    installtype     => 'site',
    modname         => 'EekBoek',
    distname        => 'EekBoek',
    license         => "perl",
    script_files    => [ map { File::Spec->catfile("script", $_) }
			 qw(ebshell ebwxshell) ],
    prereq_pm =>
    { 'Getopt::Long'        => '2.13',
      'Term::ReadLine'      => 0,
      $^O eq "linux" ? ('Term::ReadLine::Gnu' => 0) : (),
      'DBI'                 => '1.40',
      'Archive::Zip'	    => '1.16',
      'DBD::SQLite'         => '1.13',
    },
    buildreq_pm =>
    { # These are required for the build/test, and will be included.
      'Module::Build'	    => '0.26',
      'IPC::Run3'	    => '0.034',
    },
    recomm_pm =>
    { 'Getopt::Long'        => '2.32',
      'HTML::Entities'	    => '1.35',
      'DBD::Pg'             => '1.41',
    },
    usrbin => "/usr/bin",
  };

sub checkbin {
    my ($msg) = @_;
    my $installscript = $Config{installscript};

    return if $installscript eq $data->{usrbin};
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

    open(my $mf, "MANIFEST") or return filelist_dyn($dir, $pfx);
    while ( <$mf> ) {
	chomp;
	next unless /$dirp(.*)/;
	$pm->{$_} = $pfx ? $pfx . $1 : $_;
    }
    close($mf);
    $pm;
}

sub filelist_dyn {
    my ($dir, $pfx) = @_;
    use File::Find;
    $pfx ||= "";
    my $dirl = length($dir);
    my $pm;
    find(sub {
	     if ( $_ eq "CVS" ) {
		 $File::Find::prune = 1;
		 return;
	     }
	     return if /^#.*#/;
	     return if /~$/;
	     return unless -f $_;
	     if ( $pfx ) {
		 $pm->{$File::Find::name} = $pfx .
		   substr($File::Find::name, $dirl);
	     }
	     else {
		 $pm->{$File::Find::name} = $pfx . $File::Find::name;
	     }
	 }, $dir);
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

    vcopy( _tag	    => "RPM spec file",
	   _dst	    => "$name.spec",
	   %vars);

    vcopy( _tag	    => "XAF ref file (NL)",
	   _dst	    => "t/ivp/ref/export.xaf",
	   %vars);

    vcopy( _tag	    => "XAF ref file (EN)",
	   _dst	    => "t/ivp_en/ref/export.xaf",
	   %vars);

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
