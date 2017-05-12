#!/usr/bin/perl -w
#
# Generate datatypes.
#
# $Id: moses-generate-datatypes.pl,v 1.4 2008/05/09 20:26:04 kawas Exp $
# Contact: Martin Senger <martin.senger@gmail.com>
# -----------------------------------------------------------

# some command-line options
use Getopt::Std;
use vars qw/ $opt_h $opt_f $opt_R $opt_u $opt_d $opt_v $opt_s /;
getopts('hfudvsR:');

# usage
if ($opt_h) {
    print STDOUT <<'END_OF_USAGE';
Generate datatypes.
Usage: [-R registry-string] [-vds] [data-type-name] [data-type-name...]
	   [-R registry-string] [-uf]
	   
    It also needs to get a location of a local cache (and potentially
    a BioMoby registry endpoint, and an output directory). It takes
    it from the 'moby-service.cfg' configuration file.

    If no data type given it generates all of them.

    -R ... a registry string in the form:
               registry-url[@registry-uri]
           where registry-uri is optional.
           For example: 
              http://localhost/cgi-bin/MOBY-Central.pl
           or
              http://localhost/cgi-bin/MOBY-Central.pl@http://localhost/MOBY/Central

    -s ... show generated code on STDOUT
           (no file is created, disabled when no data type name given)
    -f ... fill the cache
    -u ... update the cache
    -v ... verbose
    -d ... debug
    -h ... help
END_OF_USAGE
    exit (0);
}
# -----------------------------------------------------------

use strict;

use MOSES::MOBY::Base;
use MOSES::MOBY::Generators::GenTypes;

$LOG->level ('INFO') if $opt_v;
$LOG->level ('DEBUG') if $opt_d;

sub say { print @_, "\n"; }

if ($opt_R) {
	my @r = split(/\@/, $opt_R);
	$opt_R = $r[0];
}

my $generator = new MOSES::MOBY::Generators::GenTypes;
$generator->registry($opt_R) if $opt_R;

if ($opt_f) {
	my $cache = MOSES::MOBY::Cache::Central->new (
						cachedir => $generator->cachedir,
    					registry => $generator->registry
    );
    say "Creating the datatype cache ... may take a few minutes!";
    eval {$cache->create_datatype_cache();};
    say "There was a problem creating the cache!\n$@" if $@;
    say 'Done.' unless $@;
    exit(0);
} elsif ($opt_u) {
	my $cache = MOSES::MOBY::Cache::Central->new (
						cachedir => $generator->cachedir,
    					registry => $generator->registry
    );
    say "Updating the datatype cache ... may take a few minutes!";
    eval {$cache->update_datatype_cache();};
    say "There was a problem updating the cache. Did you create it first?\n$@" if $@;
    say 'Done.' unless $@; 
    exit(0);
}

if (@ARGV) {
    say 'Generating ' . (@ARGV+0) . '+ data types.';
    if ($opt_s) {
	my $code = '';
	$generator->generate (datatype_names => [@ARGV],
			      with_docs      => 1,
			      outcode        => \$code);
	say $code;
    } else {
	$generator->generate (datatype_names => [@ARGV]);
    }
} else {
    say 'Generating all data types.';
    $generator->generate;
}
say 'Done.';


__END__
