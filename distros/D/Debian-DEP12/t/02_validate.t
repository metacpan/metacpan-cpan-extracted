#!/usr/bin/perl

use strict;
use warnings;
use Debian::DEP12;

use Test::More tests => 7;

my $entry;
my $warning;
my @warnings;

$entry = Debian::DEP12->new( <<END );
Bug-Database: https://github.com/merkys/Debian-DEP12/issues
Bug-Submit: https://github.com/merkys/Debian-DEP12/issues
END

@warnings = $entry->validate;
is( scalar @warnings, 0 );

$entry = Debian::DEP12->new( <<END );
Bug-Database: github.com/merkys/Debian-DEP12/issues
Bug-Submit:
END

@warnings = $entry->validate;
is( join( "\n", @warnings ) . "\n", <<'END' );
Bug-Database: value 'github.com/merkys/Debian-DEP12/issues' does not look like valid URL
Bug-Submit: undefined value
END

$entry = Debian::DEP12->new;
$entry->set( 'Bug-Database', 'github.com/merkys/Debian-DEP12/issues' );

@warnings = $entry->validate;
is( "@warnings", 'Bug-Database: value \'github.com/merkys/Debian-DEP12/issues\' does not look like valid URL' );

$entry = Debian::DEP12->new( <<END );
Reference:
  DOI: search for my surname and year
END

@warnings = $entry->validate;
is( "@warnings", 'Reference.DOI: value \'search for my surname and year\' does not look like valid DOI' );

$entry = Debian::DEP12->new( <<END );
Reference:
 - Year: 2021
 - DOI: search for my surname and year
END

@warnings = $entry->validate;
is( "@warnings", 'Reference[1].DOI: value \'search for my surname and year\' does not look like valid DOI' );

$entry = Debian::DEP12->new( { 'Bug-Submit' => 'merkys@cpan.org' } );
@warnings = $entry->validate;
is( "@warnings", 'Bug-Submit: value \'merkys@cpan.org\' is better written as \'mailto:merkys@cpan.org\'' );

$entry = Debian::DEP12->new(
    { 'Bug-Submit' => [ 'merkys@cpan.org',
                        'github.com/merkys/Debian-DEP12/issues' ] }
);
@warnings = $entry->validate;
is( join( "\n", @warnings ) . "\n", <<'END' );
Bug-Submit: scalar value expected
Bug-Submit[0]: value 'merkys@cpan.org' is better written as 'mailto:merkys@cpan.org'
Bug-Submit[1]: value 'github.com/merkys/Debian-DEP12/issues' does not look like valid URL
END
