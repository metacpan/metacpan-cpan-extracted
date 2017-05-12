# Makefile.PL -- Makefile for pmv.

# Author          : Johan Vromans
# Created On      : Wed Dec 14 15:01:44 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Apr 11 11:22:05 2017
# Update Count    : 10
# Status          : Stable

# Verify perl version.
require 5.6.0;

use ExtUtils::MakeMaker;

my @scripts = map { "script/$_" } qw(pmv);

my $x =
WriteMakefile
  (
   NAME         => 'File::PerlMove',
   AUTHOR	=> 'Johan Vromans (jvromans@squirrel.nl)',
   ABSTRACT	=> 'move files using Perl power',
   VERSION_FROM => 'lib/File/PerlMove.pm',
   PREREQ_PM	=> { 'Getopt::Long' => 2.00,
		     'Test::More' => 0,
		     'File::Path' => 0,
		     'File::Basename' => 0,
		   },
   LICENSE => 'artistic_2',
   EXE_FILES    => \@scripts,
   # *.pm files will be picked up automatically from ./lib
 );

sub WriteSpecfile {
    my $name    = shift;
    my $perlmodname = $name;
    my $version = shift;
    $name =~ s/::/-/g;
    my $fh;
    if ( open ($fh, "perl-$name.spec.in") ) {
	print "Writing RPM spec file...\n";
	my $newfh;
	open ($newfh, ">perl-$name.spec");
	print { $newfh } ("%define modname $name\n");
	print { $newfh } ("%define perlmodname $perlmodname\n");
	print { $newfh } ("%define modversion $version\n");
	print { $newfh } ("\n");
	while ( <$fh> ) {
	    print $newfh $_;
	}
	close($newfh);
    }
}

WriteSpecfile($x->{NAME}, $x->{VERSION});
