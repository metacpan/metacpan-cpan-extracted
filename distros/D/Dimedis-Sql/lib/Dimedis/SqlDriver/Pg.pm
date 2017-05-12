package Dimedis::SqlDriver::Pg;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.02';
@ISA = qw(Dimedis::Sql);

use Carp;
use File::Copy;
use File::Basename;
use FileHandle;

my $exc = "Dimedis::SqlDriver::Pg:";	# Exception Prefix

# offizielles Dimedis::SqlDriver Interface ===========================

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
	my   ($filehandle, $filename, $table, $col, $where, $params) =
	@$par{'filehandle','filename','table','col','where','params'};

	my $dbh = $self->{dbh};

	# sind wir im AutoCommit Modus? Blob Handling bei Pg MUSS in
	# einer Transaktion gemacht werden
	my $autocommit = $dbh->{AutoCommit};
	
	if ( $autocommit ) {
		$dbh->{AutoCommit} = 0;
		$self->{debug} && print STDERR "$exc:blob_read: AutoCommit abgeschaltet\n";
	}

	# die folgenden Operationen können Exceptions werfen. In jedem
	# Fall muß aber der Transaktionsmodus wieder hergestellt werden,
	# deshalb müssen diese in einem eval stehen.

	my $blob;
	eval {
		# oid des Blobs lesen
		my ($oid) = $self->get (
			sql => "select $col
				from   $table
				where  $where",
			params => $params
		);

		$self->{debug} && print STDERR "$exc:blob_read: blob oid $oid\n";

		croak "no_blob" if not $oid or $oid < 0;

		# Blob öffnen
		my $lo_fd = $dbh->func($oid, $dbh->{pg_INV_READ}, 'lo_open');
		croak "Can't open blob with oid $oid" if not defined $lo_fd;

		$self->{debug} && print STDERR "$exc:blob_read: AutoCommit abgeschaltet\n";

		my ($buffer, $len);

		if ( $filehandle ) {
			# Blob in Filhandle schreiben
			while ( $len = $dbh->func ($lo_fd, $buffer, 4096, 'lo_read' ) ) {
				croak "Can't read from blob with oid $oid"
					if not defined $len;
				write ($filehandle, $buffer, $len);
			}

		} elsif ( $filename ) {
			# Blob in eine Datei schreiben
			my $fh = FileHandle->new;
			open ($fh, "> $filename") or croak "Can't write $filename";
			while ( $len = $dbh->func ($lo_fd, $buffer, 4096, 'lo_read' ) ) {
				croak "Can't read from blob with oid $oid"
					if not defined $len;
				write ($fh, $buffer, $len);
			}
			close $fh;

		} else {
			# Blob in den Speicher lesen
			while ( $len = $dbh->func ($lo_fd, $buffer, 4096, 'lo_read' ) ) {
				croak "Can't read from blob with oid $oid"
					if not defined $len;
				$blob .= $buffer;
			}
		}

		my $rc = $dbh->func($lo_fd, 'lo_close');
		croak "Can't close blob with oid $oid" if not $rc;
	};
	
	# evtl. Exception speichern
	my $error = $@;
	
	# Die no_blob Exception ist hier kein Fehlerfall
	$error = undef if $@ =~ /^no_blob/;

	# Hatten wir AutoCommit abgeschaltet und Transaktionsmodus
	# eingeschaltet? Dann committen wir hier und schalten
	# AutoCommit wieder ein.
	if ( $autocommit ) {
		if ( $error ) {
			$dbh->rollback;
		} else {
			$dbh->commit;
		}
		$dbh->{AutoCommit} = 1;
		$self->{debug} && print STDERR "$exc:blob_read: AutoCommit eingeschaltet\n";
	}

	# Exception weiterreichen
	croak $error if $error;

	return if $filehandle or $filename;
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

	use locale;

	return "lower($par->{col}) $par->{op} ".
	       $self->{dbh}->quote (lc($par->{val}));
}

# use_db -------------------------------------------------------------

sub db_use_db {
	my $self = shift;

	croak "use_db not implemented";
}

# db_prefix ----------------------------------------------------------

sub db_db_prefix {
	my $self = shift;

	croak "db_prefix not implemented";
}

# install ------------------------------------------------------------

sub db_install {
	# nichts zu tun hier, für PostgreSQL
	1;
}

# contains -----------------------------------------------------------

sub db_contains {
	my $self = shift;

	return;
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
		contains => 0,
	};
}

# Driverspezifische Hilfsmethoden ====================================

# join Bedingung bauen -----------------------------------------------

sub db_join_cond {
	my $self = shift;
	
	my ($left, $cond, $right, $join) = @_;
	
	# beim outer join müssen (+) Zeichen bei Ausdrücken der
	# rechten Tabelle angehängt werden
	
	my ($table, $alias) = split (/\s/, $right);
	$alias ||= $table;
	
	$cond =~ s/($alias\.[^\s]+)/$1 (+)/g;
	
	return $cond;
}

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
	my $primary_key;	# Name der primary key Spalte
	
	while ( ($col,$val) = each %{$par->{data}} ) {
		my $type = $type_href->{$col};
		$type =~ s/\[.*//;

		if ( $type eq 'serial' ) {
			# serial Typ bearbeiten

			if ( not defined $val ) {
				$serial = $self->db_get_serial (
					$par->{table},
					$col,
					$type_href->{$col}
				);
			} else {
				$serial = $val;
			}
			
			push @columns, $col;
			push @values, $serial;
			$qm .= "?,";
			$primary_key = $col;
			
		} elsif ( $type eq 'blob' or $type eq 'clob' ) {

			# Blobs werden nach dem INSERT/UPDATE verarbeitet

			if ( $par->{db_action} eq 'insert' ) {
				push @columns, $col;
				$qm .= "-1, ";
			}

			$blob_found = 1;
			$blobs{$col} = $val;

		} else {
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
			params => \@values
		);
		$return_value = $serial;
	} else {
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
				params => \@values
			);
		}
	}

	# nun evtl. BLOBs verarbeiten
	
	if ( $blob_found ) {
		if ( $par->{db_action} eq 'insert' ) {
			while ( ($col,$val) = each %blobs ) {
				$self->db_put_blob (
					$par->{table},
					"$primary_key=$serial",
					$col, $val,
					$type_href
				);
			}
		} else {
			while ( ($col,$val) = each %blobs ) {
				$self->db_put_blob (
					$par->{table},
					$par->{where},
					$col, $val,
					$type_href,
					$par->{params}
				);
			}
		}
	}

	$self->{debug} && print STDERR "$exc:insert_or_update: return_value=$return_value\n";

	return $return_value;
}

# Serial ermitteln ---------------------------------------------------

sub db_get_serial {
	my $self = shift;
	
	my ($table, $col, $type) = @_;
	
	# SEQUENCE Namen bestimmen
	
	my $sequence ||= "${table}_SEQ";
	
	# Sequence auslesen

	my $serial;
	
	eval {
		($serial) = $self->get (
			sql    => "select nextval(?)",
			cache  => 1,
			params => [ $sequence ],
		);
	};
	
	# wenn's nicht geklappt hat, gab's die SEQUENCE wohl nicht
	
	if ( $@ ) {
		$self->{debug} && print STDERR "$exc:get_serial: sequence existiert nicht\n";
		# also: legen wir sie doch einfach an!
		
		my ($max_id) = $self->get (
			sql => "select max($col) from $table"
		);

		$self->{debug} && print STDERR "$exc:get_serial: max_id=$max_id\n";

		$max_id += 100;

		$self->{debug} && print STDERR "$exc:get_serial: create sequence mit start=$max_id\n";

		$self->do (
			sql => "create sequence $sequence
				start $max_id
				increment 1"
		);
		$serial = $max_id-1;
	}
	
	return $serial;
}

# BLOB speichern -----------------------------------------------------

sub db_put_blob {
	my $self = shift;
	my ($table, $where, $col, $val, $type_href, $param_lref) = @_;

	$param_lref ||= [];

	my $dbh = $self->{dbh};

	# sind wir im AutoCommit Modus? Blob Handling bei Pg MUSS in
	# einer Transaktion gemacht werden
	my $autocommit = $dbh->{AutoCommit};
	
	if ( $autocommit ) {
		$dbh->{AutoCommit} = 0;
		$self->{debug} && print STDERR "$exc:put_blob: AutoCommit abgeschaltet\n";
	}

	# die folgenden Operationen können Exceptions werfen. In jedem
	# Fall muß aber der Transaktionsmodus wieder hergestellt werden,
	# deshalb müssen diese in einem eval stehen.

	eval {
		# 1. Prüfen, ob's da schon einen Blob gibt
		my ($oid) = $self->get (
			sql => "select $col
				from   $table
				where  $where",
			params => $param_lref,
		);

		$self->{debug} && print STDERR "$exc:put_blob: oid=$oid\n";

		if ( $oid != -1 ) {
			# alten Blob löschen
			my $rc = $dbh->func ($oid, 'lo_unlink');
			croak "can't delete old blob oid=$oid" if not $rc;
			$self->{debug} && print STDERR "$exc:put_blob: alten blob gelöscht oid=$oid\n";
		}

		$oid = $dbh->func($dbh->{pg_INV_WRITE}, 'lo_creat');
		croak "Can't create blob" if not defined $oid;

		$self->do (
			sql    => "update $table set $col = ? where $where",
			params => [ $oid, @{$param_lref} ]
		);

		$self->{debug} && print STDERR "$exc:put_blob: neuen blob erzeugt. oid=$oid\n";

		# nun den Blob zum Schreiben öffnen
		my $lo_fd = $dbh->func ($oid, $dbh->{pg_INV_WRITE}, 'lo_open');
		croak "Can't open blob for update with oid $oid" if not defined $lo_fd;

		# und nun schreiben wir den Burschen
		if ( ref $val and ref $val ne 'SCALAR' ) {
			# Referenz und zwar keine Scalarreferenz
			# => das ist ein Filehandle
			# => reinlesen den Kram
			binmode $val;
			my ($buffer, $rc);
			while ( read ($val, $buffer, 4096) ) {
				$rc = $dbh->func($lo_fd, $buffer, 4096, 'lo_write');
				croak "Can't write data to blob with oid $oid"
					if not defined $rc;
			}

		} elsif ( not ref $val ) {
			# keine Referenz
			# => Dateiname
			# => reinlesen den Kram
			my $fh = new FileHandle;
			open ($fh, $val) or croak "can't open file '$val'";
			binmode $fh;
			my ($buffer, $rc, $len);
			while ( $len = read ($fh, $buffer, 4096) ) {
				$rc = $dbh->func($lo_fd, $buffer, $len, 'lo_write');
				croak "Can't write data to blob with oid $oid"
					if not defined $rc;
			}
			close $fh;

		} else {
			# andernfalls ist val eine Skalarreferenz mit dem Blob
			my $len = length($$val);
			my $i = 0;
			my $rc;
			my $chunk_len;
			while ( $i < $len ) {
				$chunk_len = $i+4096;
				if ( $chunk_len > $len ) {
					$chunk_len = $len - $i;
				} else {
					$chunk_len = 4096;
				}
				$rc = $dbh->func (
					$lo_fd,
					substr($$val, $i, $i + $chunk_len),
					$chunk_len,
					'lo_write'
				);
				croak "Can't write data to blob with oid $oid"
					if not defined $rc;
				$i += 4096;
			}
		}

		# Blob schließen
		my $rc = $dbh->func($lo_fd,'lo_close');
		croak "Can't close blob with oid $oid" if not $rc;
	};
	
	# evtl. Exception speichern
	my $error = $@;
	
	# Hatten wir AutoCommit abgeschaltet und Transaktionsmodus
	# eingeschaltet? Dann committen wir hier und schalten
	# AutoCommit wieder ein.
	if ( $autocommit ) {
		if ( $error ) {
			$dbh->rollback;
		} else {
			$dbh->commit;
		}
		$dbh->{AutoCommit} = 1;
		$self->{debug} && print STDERR "$exc:put_blob: AutoCommit eingeschaltet\n";
	}

	# Exception weiterreichen
	croak $error if $error;

	return 1;
}

1;

__END__

=head1 NAME

Dimedis::SqlDriver::Pg - Postgres Treiber für das Dimedis::Sql Modul

=head1 SYNOPSIS

use Dimedis::Sql;

=head1 DESCRIPTION

siehe Dimedis::Sql

=head1 BESONDERHEITEN DER POSTGRESQL IMPLEMENTIERUNG

=head2 SERIAL BEHANDLUNG

Der 'serial' Datentyp wird mit Sequences realisiert. Dabei wird
für jede Tabelle automatisch eine Sequence verwaltet, deren Name
sich wie folgt zusammensetzt:

        ${table}_SEQ

Wenn die Sequence noch nicht existiert, wird sie automatisch
angelegt. Die Zählung beginnt dabei mit 100.

Der 'serial' Datentyp muß bei Postgres also als integer angelegt
werden.

Es gibt zwar auch einen eigenen Datentyp 'serial' in PostgreSQL,
der die Serial auch genau über eine Sequence realisiert. Hier wurde
aber eine eigene Implementierung vorgenommen, weil diese mit leichten
Änderungen von Oracle übernommen werden konnte und das Problemm,
"welche ID wurde zuletzt vergeben?", so gleich mit gelöst wurde.

=head2 BLOB BEHANDLUNG

Blobs und Clobs werden von Postgres direkt unterstützt, allerdings
nicht innerhalb einer Tabelle gespeichert. Stattdessen wird dort
eine ObjectID als Integer Wert gespeichert. Beim Anlegen von Blob
und Clob Spalten für Postgres müssen diese also als integer Spalten
deklariert werden.

Weiterhin muß eine RULE angelegt werden, damit die Blobs beim Löschen
aus der Tabelle auch mit gelöscht werden (ähnlich den Triggern bei
der Sybase Implementierung):

  create rule "TABELLE_blob_remove" as
      on delete to "TABELLE"
      do select lo_unlink(old.BLOB_SPALTE)

=head2 INSTALL METHODE

Für Dimedis::SqlDriver::Pg ist die install Methode leer,
d.h. es werden keine Objekte in der Datenbank vorausgesetzt.

=head2 USE_DB UND DB_PREFIX METHODE

Beide Methoden sind nicht implementiert, weil PostgreSQL den Wechsel
und den Zugriff mehrerer Datenbanken in derselben Connection
nicht unterstützt.

=head1 AUTOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 2001 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1).

=cut
