# $Id: mysql.pm,v 1.20 2006/10/20 09:57:43 cvsinst Exp $

package Dimedis::SqlDriver::mysql;

use strict;
use vars qw($VERSION @ISA $DEFAULT_CHARSET $DEFAULT_COLLATE);

$VERSION = '0.17';
@ISA = qw(Dimedis::Sql);	# Vererbung von Dimedis::Sql

$DEFAULT_CHARSET = "latin1";
$DEFAULT_COLLATE = "latin1_german1_ci";

use Carp;
use File::Copy;
use FileHandle;

my $exc = "Dimedis::SqlDriver::mysql:";	# Exception Prefix

# set_utf8 muß überschrieben werden ==================================

sub set_utf8 {
	my $self = shift;
	my ($utf8) = @_;
	$self->{utf8} = $utf8;
	$self->db_init;
	return $utf8;
}

# offizielles Dimedis::SqlDriver Interface ===========================

# init ---------------------------------------------------------------

sub db_init {
	my $self = shift;

	# Bei MySQL ab 4.1 muß das Character Set der Verbindung auf
	# auf den richtigen Wert gesetzt werden, sonst
	# nimmt der MySQL Server zusätzliche Konvertierungen
	# vor - damit stehen dann z.B. "doppelt" utf8 kodierte Zeichen
	# in der Datenbank.

	my $dbh = $self->{dbh};
	my $version = $dbh->{mysql_serverinfo};
	my @v = $version =~ /(\d+)/g;
	my $num_version = $v[0]*10000+$v[1]*100+$v[2];

	$self->{debug} &&
		print STDERR "$exc:db_init: MySQL ".
			     "Server version $version detected\n";

	my $charset = $self->{utf8} ? "utf8"            : $DEFAULT_CHARSET;
	my $collate = $self->{utf8} ? "utf8_general_ci" : $DEFAULT_COLLATE;

	if ( $num_version >= 40100 ) {
		$dbh->do ("set character_set_client='$charset'");
		$dbh->do ("set character_set_connection='$charset'");
		$dbh->do ("set character_set_results='$charset'");
		$dbh->do ("set collation_connection='$collate'");
		
		$self->{debug} &&
			print STDERR "$exc:db_init: version > 4.1 => set charset/collate $charset/$collate\n";
	} else {
		$self->{debug} &&
			print STDERR "$exc:db_init: version < 4.1 => no charset setting\n";
		}
	
	return 1;
}

# install ------------------------------------------------------------

sub db_install {
	my $self = shift;
	
	return 1;
}

# insert -------------------------------------------------------------

sub db_insert {
	my $self = shift;

	my ($par)= @_;
	$par->{db_action} = "insert";
	
	$self->db_insert_or_update ($par);
}

# update -------------------------------------------------------------

sub db_update {
	my $self = shift;

	my ($par)= @_;
	$par->{db_action} = "update";
	
	$self->db_insert_or_update ($par);
}

# blob_read ----------------------------------------------------------

sub db_blob_read {
	my $self = shift;
	
	my ($par) = @_;

	my $filename = $par->{filename};
	my $filehandle = $par->{filehandle};
	
	my $dbh = $self->{dbh};
	
	# das ist einfach! rausSELECTen halt...

	my $sth = $dbh->prepare (
		"select $par->{col}
		 from   $par->{table}
		 where  $par->{where}"
	) or croak "$DBI::errstr";
		
	$sth->execute(@{$par->{params}}) or croak $DBI::errstr;

	# Blob lesen

	my $ar = $sth->fetchrow_arrayref;
	croak $DBI::errstr if $DBI::errstr;
	if ( not defined $ar ) {
		return \"";
	}

	my $blob = $ar->[0];

	$sth->finish or croak $DBI::errstr;
	
	# und nun ggf. irgendwo hinschreiben...	
	
	if ( $filename ) {
		open (BLOB, "> $filename") or croak "can't write $filename";
		# Kein UTF8 Handling nötig hier. Die BLOB Variable hat
		# kein UTF8 Flag. Falls die DB UTF8 geliefert hat, können
		# die Daten also raw geschrieben werden. Sonst müßte der
		# IO Layer auf utf8 gesetzt werden *und* $blob müßte das
		# UTF8-Flag bekommen. Überflüssig!
		binmode BLOB;
		print BLOB $blob;
		close BLOB;
		$blob = "";	# Speicher wieder freigeben

	} elsif ( $filehandle ) {
		binmode $filehandle;
		print $filehandle $blob;
		$blob = "";	# Speicher wieder freigeben
	}

	return if $par->{filehandle} or $par->{filename};
	return \$blob;
}

# left_outer_join ----------------------------------------------------
{
	my $from;
	my $where;

	sub db_left_outer_join {
		my $self = shift;
	
		# static Variablen initialisieren
		
		$from = "";
		$where = "";

		# Rekursionsmethode anwerfen

		$self->db_left_outer_join_rec ( @_ );
	
		# Dreck bereinigen

		$from =~ s/,$//;
		$from =~ s/,\)/)/g;
		$where =~ s/ AND $//;

		$where = '1=1' if $where eq '';

		return ($from, $where);
	}

	sub db_left_outer_join_rec {
		my $self = shift;

		my ($lref, $left_table_out) = @_;
		
		# linke Tabelle in die FROM Zeile

		$from .= " ".$lref->[0]
			if not $left_table_out;
		
		if ( ref $lref->[1] ) {
			# aha, Outer Join
			if ( @{$lref->[1]} > 1 ) {
				# kein einfacher Outer Join
				# (verschachtelt oder outer join gegen
				#  simple join, Fall II/III)

				$from .= " left outer join ".$lref->[1]->[0].
						 " on ".$lref->[2];

				$self->db_left_outer_join_rec ($lref->[1], 1);

			} else {
				# Fall I, outer join einer linken Tabelle
				# gegen eine oder mehrere rechte Tabellen
				my $i = 1;
				while ($i < @{$lref}) {
					$from .= " left outer join ".$lref->[$i]->[0].
						 " on ".$lref->[$i+1];
					$i += 2;
				}
			}
		} else {
			# noe, kein Outer join
			croak "$exc:db_left_outer_join\tcase III does not exist anymore";
			$from .= $lref->[1];
			$where .= $lref->[2]." AND ";
		}
	}
}

# cmpi ---------------------------------------------------------------

sub db_cmpi {
	my $self = shift;
	my ($par)= @_;

	my $not = $par->{op} eq '!=' ? 'not ' : '';

	my $quoted = $self->{dbh}->quote ($par->{val});

	# Bug in DBI->quote. utf8 flag ist weg :(
	# (wurde durch utf8::upgrade in ->cmpi gesetzt)
	Encode::_utf8_on($quoted) if $self->{utf8};

	return "${not}lower($par->{col}) like $quoted";
}

# use_db -------------------------------------------------------------

sub db_use_db {
	my $self = shift;
	
	my ($par)= @_;

	$self->do (
		sql => "use $par->{db}"
	);

	1;
}

# db_prefix ----------------------------------------------------------

sub db_db_prefix {
	my $self = shift;
	
	my ($par)= @_;

	return $par->{db}.'.';

	1;
}

# contains -----------------------------------------------------------

sub db_contains {
	my $self = shift;
	my ($par) = @_;

	my $col      = $par->{col};
	my $vals     = $par->{vals};
	my $logic_op = $par->{logic_op};

	my $dbh      = $self->{dbh};

	my $cond;
	foreach my $val ( @{$vals} ) {
		$cond .= "$col like ".
			 $dbh->quote('%'.$val.'%').
			 " $logic_op ";
	}
	
	$cond =~ s/ $logic_op $//;
	$cond = "($cond)";

	return $cond;
}

# get_features -------------------------------------------------------

sub db_get_features {
	my $self = shift;
	
	return {
		serial => 1,
		blob_read => 1,
		blob_write => 1,
		left_outer_join => {
			simple => 1,
			nested => 1
		},
	  	cmpi => 1,
		contains => 1,
		use_db => 1,
		utf8 => 1,
	};
}

# Driverspezifische Hilfsmethoden ====================================

# Insert bzw. Update durchführen -------------------------------------

sub db_insert_or_update {
	my $self = shift;

	my ($par) = @_;
	my $type_href = $par->{type};

	my $serial;			# evtl. Serial Wert
	my (@columns, @values);		# Spaltennamen und -werte
	my $return_value;		# serial bei insert,
					# modified bei update
	
	# Parameter aufbereiten

	my ($col, $val);
	my $qm;		# Fragezeichen für Parameterbinding
	my %blobs;	# Hier werden BLOB Spalten abgelegt, die
			# nach dem INSERT eingefügt werden
	my $blob_found;
	
	while ( ($col,$val) = each %{$par->{data}} ) {
		my $type = $type_href->{$col};
		$type =~ s/\[.*//;

		if ( $type eq 'serial' and not defined $val ) {
			# serial Typ bearbeiten
			push @columns, $col;
			push @values, 0;
			$qm .= "?,";
			
		} elsif ( $type eq 'blob' or $type eq 'clob' ) {

			# Blob muß in jedem Fall im Speicher vorliegen
			$val = $self->blob2memory($val, $col, $type);

			# Ggf. UTF8 draus machen (utf-8 Handling wird bei
                        # Dimedis::Sql->do Aufruf abgeschaltet, das muss
                        # der mysql Driver selbst machen, weil Blobs auch
                        # via Params übergeben werden, da darf kein utf8::upgrade
                        # drauf gemacht werden
			if ( $self->{utf8} and $type_href->{$col} eq 'clob' ) {
				utf8::upgrade($$val);
			}
			elsif ( !$self->{utf8} and $type_href->{$col} eq 'clob' ) {
				$$val = Encode::encode("windows-1252", $$val)
					if Encode::is_utf8($$val);
			}

			# Blobs können inline geinsertet 
			# und updated werden
			push @columns, $col;
			push @values, $$val;
			$qm .= "?,";

		} else {
			# utf8 Behandlung
                        if  ( $self->{utf8} ) {
        			utf8::upgrade($val);
                        }
                        else {
				$val = Encode::encode("windows-1252", $val)
					if Encode::is_utf8($val);
                        }

			# Leerstring zu NULL machen
			# (wird hier gemacht, da CLOB's nicht so behandelt
			#  werden dürfen - hier gibt es den Unterschied
			#  zwischen NULL und '' noch)
			$val = undef if $val eq '';

			# alle übrigen Typen werden as is eingefügt
			push @columns, $col;
			push @values,  $val;
			$qm .= "?,";
		}
	}
	$qm =~ s/,$//;	# letztes Komma bügeln

	# Insert oder Update durchführen
	if ( $par->{db_action} eq 'insert' ) {
		# insert ausführen

		$self->do (
			sql => "insert into $par->{table} (".
			       join (",",@columns).
			       ") values ($qm)",
			params  => \@values,

			no_utf8 => 1,	# Das haben wir schon gemacht,
					# außer bei Blobs. Die werden bei
					# MySQL as-is eingefügt, aber
					# dürfen natürlich *nicht* nach
					# UTF8 konvertiert werden,

			no_nulling => 1,# Das haben wir schon gemacht,
					# nur bei CLOBs nicht, weil hier
					# '' und NULL unterscheidbar sein
					# sollen.
			
		);
		
		$return_value = $self->{dbh}->{'mysql_insertid'};
		
	} else {
        	# ggf. UTF8 Konvertierung der Parameter vornehmen
                # (wird in Dimedis::Sql->do nicht gemacht, Kommentar s.o.)
        	if ( $self->{utf8} ) {
        		foreach my $p ( @{$par->{params}} ) {
        			utf8::upgrade($p);
        		}
        	}
        	else {
        		foreach my $p ( @{$par->{params}} ) {
        			$p = Encode::encode("windows-1252", $p)
        				if Encode::is_utf8($p);
        		}
        	}

		# Parameter der where Klausel in @value pushen
		push @values, @{$par->{params}};
		
		# update ausführen, wenn columns da sind
		# (bei einem reinen BLOB updated passiert es,
		#  daß keine 'normalen' Spalten upgedated werden)
		
		if ( @columns ) {
			$return_value = $self->do (
				sql => "update $par->{table} set ".
				       join(",", map("$_=?", @columns)).
				       " where $par->{where}",
				params => \@values,
				no_utf8		=> 1,
				no_nulling	=> 1,
			);
		}
	}

	return $return_value;
}

1;

__END__

=head1 NAME

Dimedis::SqlDriver::mysql - MySQL Treiber für das Dimedis::Sql Modul

=head1 SYNOPSIS

use Dimedis::SqlDriver;

=head1 DESCRIPTION

siehe Dimedis::Sql

=head1 BESONDERHEITEN DER IMPLEMENTIERUNG

=head2 SERIAL BEHANDLUNG

Spalten, die mit dem 'serial' Datentyp deklariert sind, müssen in der
Datenbank als primary key serial Spalten deklariert sein, z.B.

        id serial not null primary key

=head2 BLOB BEHANDLUNG

Es wird davon ausgegangen, daß Blob Spalten als 'mediumblob' deklariert
sind. Ansonsten gibt es keine besonderen Einschänkungen in der Blob
Behandlung.

=head2 INSTALL METHODE

Für Dimedis::SqlDriver::MySQL ist die install Methode leer,
d.h. es werden keine Objekte in der Datenbank vorausgesetzt.

=head2 CONTAINS METHODE

Diese Methode ist z.Zt. nicht implementiert, d.h. liefert B<immer> undef
zurück.

=head1 AUTOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 2000 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1).

=cut
