#! perl --			-*- coding: utf-8 -*-

use utf8;

# Import.pm -- Import EekBoek administratie
# Author          : Johan Vromans
# Created On      : Tue Feb  7 11:56:50 2006
# Last Modified By: Johan Vromans
# Last Modified On: Wed May 30 16:07:58 2012
# Update Count    : 110
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Import;

use strict;
use warnings;

use EB;
use EB::Format;			# needs to be setup before we can use Schema

my $ident;

sub do_import {
    my ($self, $cmdobj, $opts) = @_;

    require EB::Tools::Schema;

    my $dir = $opts->{dir};
    if ( defined $dir ) {
	die("?".__x("Directory {dir} bestaat niet",
		    dir => $dir)."\n") unless -d $dir;
	die("?".__x("Geen toegang tot directory {dir}",
		    dir => $dir)."\n") unless -r _ || -x _;

	-r "$dir/schema.dat"
	  or die("?".__x("Bestand \"{file}\" ontbreekt ({err})",
			 file => "schema.dat", err => $!)."\n");

	# Do not open these with :encoding(utf-8) -- we'll do it ourselves.
	open(my $relaties, "<", "$dir/relaties.eb")
	  or die("?".__x("Bestand \"{file}\" ontbreekt ({err})",
			 file => "relaties.eb", err => $!)."\n");
	open(my $opening, "<", "$dir/opening.eb")
	  or die("?".__x("Bestand \"{file}\" ontbreekt ({err})",
			 file => "opening.eb", err => $!)."\n");
	open(my $mutaties, "<", "$dir/mutaties.eb")
	  or die("?".__x("Bestand \"{file}\" ontbreekt ({err})",
			 file => "mutaties.eb", err => $!)."\n");

	# To temporary suspend journaling.
	my $jnl_state = $cfg->val(qw(preferences journal), undef);

	# Delete daybook-associated shell functions.
	$cmdobj->_forget_cmds;

	# Create DB.
	$dbh->cleardb if $opts->{clean};

	# Schema.
	EB::Tools::Schema->create("$dir/schema.dat");
	$dbh->setup;

	# Add daybook-associated shell functions.
	$cmdobj->_plug_cmds;

	# Relaties, Opening, Mutaties.
	# Remember: These are executed in LIFO.
	$cmdobj->attach_lines(["journal --quiet $jnl_state"]) if $jnl_state;
	$cmdobj->attach_file($mutaties);
	$cmdobj->attach_file($opening);
	$cmdobj->attach_file($relaties);
	$cmdobj->attach_lines(["journal --quiet 0"]) if $jnl_state;
	return;
    }

    my $inp = $opts->{file};
    if ( defined $inp ) {
	# die("?"._T("Import van bestand is nog niet geïmplementeerd")."\n");

	eval { require Archive::Zip }
	  or die("?"._T("Module Archive::Zip, nodig voor import van file, is niet beschikbaar")."\n");

	open(my $zipf, "<", $inp)
	  or die("?".__x("Bestand \"{file}\" is niet beschikbaar ({err})",
			 file => $inp, err => $!)."\n");
	binmode($zipf);

	my $zip = Archive::Zip->new;
	my $status = $zip->read($zipf);
	die("?".__x("Fout {code} tijdens het lezen van {file}",
		    code => $status, file => $inp)."\n") if $status;

	my $c = $zip->zipfileComment;
	if ( $c ) {
	    warn("$inp: $c\n");
	}

	my $fail;

	my $d_schema   = $zip->contents("schema.dat");
	unless ( $d_schema ) {
	    warn("?".__x("Het schema ontbreekt in bestand {file}",
			 file => $inp)."\n");
	    $fail++;
	}

	my $d_relaties = $zip->contents("relaties.eb");
	unless ( $d_relaties ) {
	    warn("?".__x("De relatiegegevens ontbreken in bestand {file}",
			 file => $inp)."\n");
	    $fail++;
	}

	my $d_opening  = $zip->contents("opening.eb");
	unless ( $d_opening ) {
	    warn("?".__x("De openingsgegevens ontbreken in bestand {file}",
			 file => $inp)."\n");
	    $fail++;
	}

	my $d_mutaties = $zip->contents("mutaties.eb");
	unless ( $d_mutaties ) {
	    warn("?".__x("De mutatiegegevens ontbreken in bestand {file}",
			 file => $inp)."\n");
	    $fail++;
	}

	close($zipf);

	die("?"._T("DE IMPORT IS NIET UITGEVOERD")."\n") if $fail;

	foreach ( $d_mutaties, $d_relaties, $d_opening, $d_schema ) {
	    # Do not recode, the input loop will do that for us.
	    $_ = [ map { "$_\n" } split(/[\n\r]+/, $_) ];
	}

	# Delete daybook-associated shell functions.
	$cmdobj->_forget_cmds;

	eval {			#### TODO: Why eval?
	    # Create DB.
	    $dbh->cleardb if $opts->{clean};

	    # Schema.
	    my @s = @$d_schema;	# copy for 2nd pass
	    EB::Tools::Schema->_create1(sub { shift(@$d_schema) });
	    EB::Tools::Schema->_create2(sub { shift(@s) });
	    $dbh->setup;

	    # Add daybook-associated shell functions.
	    $cmdobj->_plug_cmds;

	    # Relaties, Opening, Mutaties. In reverse order.
	    $cmdobj->attach_lines($d_mutaties);
	    $cmdobj->attach_lines($d_opening );
	    $cmdobj->attach_lines($d_relaties);
	};
	return $@;
    }

    die("?ASSERT ERROR: missing --dir / --file in Import\n");
}

1;
