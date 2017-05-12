package Dimedis::SqlDriver::Informix;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.10';
@ISA = qw(Dimedis::Sql);	# Vererbung von Dimedis::Sql

use Carp;
use File::Copy;
use FileHandle;

my $exc = "Dimedis::SqlDriver::Informix:";	# Exception Prefix

# offizielles Dimedis::SqlDriver Interface ===========================

# install ------------------------------------------------------------

sub db_install {
	my $self = shift;
	
	return 1;	# wg. blob update mit temp table

	$self->{debug} && print STDERR "$exc:install\tblob Methode ohne temp. table\n";

	# erstmal alles löschen
	eval {
		$self->do (
			sql => "drop table dim_blob_insert"
		);
	};
	
	# Anlegen der INSERT Dummy Tabelle
	
	$self->do (
		sql => "create table dim_blob_insert (".
		       " id serial not null primary key,".
		       " myblob byte, myclob text )"
	);
	
	1;
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
		binmode BLOB;
		print BLOB $blob;
		close BLOB;
		$blob = "";	# Speicher wieder freigeben
	} elsif ( $filehandle ) {
		binmode $filehandle;
		print $filehandle $blob;
		$blob = "";	# Speicher wieder freigeben
	}
	
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

		return ($from, $where);
	}

	sub db_left_outer_join_rec {
		my $self = shift;

		my ($lref) = @_;
		
		# linke Tabelle in die FROM Zeile

		$from .= $lref->[0].",";
		
		if ( ref $lref->[1] ) {
			# aha, Outer Join
			if ( @{$lref->[1]} > 1 ) {
				# kein einfacher Outer Join
				# (verschachtelt oder outer join gegen
				#  simple join, Fall II/III)
				$from .= "outer (";
				$self->db_left_outer_join_rec ($lref->[1]);
				$from .= ")";
				$where .= $lref->[2]." AND ";
			} else {
				# Fall I, outer join einer linken Tabelle
				# gegen eine oder mehrere rechte Tabellen
				my $i = 1;
				while ($i < @{$lref}) {
					$from .= " outer ".$lref->[$i]->[0].",";
					$where .= $lref->[$i+1]." AND ";
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

	my $val = lc $par->{val};
	$val =~ s/(\w)/"[$1".uc($1)."]"/eg;
	$val =~ s/\%/*/g;
	my $not = $par->{op} eq '!=' ? 'not ' : '';

	return "$not$par->{col} matches ".
	       $self->{dbh}->quote ($val);
}

# contains -----------------------------------------------------------

sub db_contains {
	my $self = shift;
	
	my ($par) = @_;
	my $cond;

	# bei Informix z.Zt. nicht unterstüzt, deshalb undef returnen

	return $cond;
}

# db_prefix ----------------------------------------------------------

sub db_db_prefix {
	my $self = shift;
	
	my ($par)= @_;

	return $par->{db}.':';

	1;
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
		contains => 0
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
	my $primary_key;	# Name der primary key Spalte
	
	while ( ($col,$val) = each %{$par->{data}} ) {
		my $type = $type_href->{$col};
		$type =~ s/\[.*//;

		if ( $type eq 'serial' ) {
			# serial Typ bearbeiten

			if ( not defined $val ) {
				$serial = 0;
			} else {
				$serial = $val;
			}
			push @columns, $col;
			push @values, $serial;
			$qm .= "?,";
			$primary_key = $col;
			
		} elsif ( $type eq 'blob' or $type eq 'clob' ) {

			# Blob muß in jedem Fall im Speicher vorliegen
			
			$val = $self->db_blob2memory($val);

			if ( $par->{db_action} eq 'insert' ) {
				# Blobs können inline geinsertet werden
				push @columns, $col;
				push @values, $$val;
				$qm .= "?,";
			} else {
				# zum Updaten wirds komplizierter!
				# das machen wir später...
				$blob_found = 1;
				$blobs{$col} = $val;
			}
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
		$return_value = $self->{dbh}->{ix_sqlerrd}->[1];
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

	# nun evtl. BLOBs verarbeiten (kann nur beim Update passieren)
	
	if ( $blob_found ) {
		while ( ($col,$val) = each %blobs ) {
			$self->db_update_blob (
				$par->{table},
				$par->{where},
				$col, $val,
				$type_href,
				$par->{params}
			);
		}
	}

	return $return_value;
}

# BLOB ins Memory holen, wenn nicht schon da -------------------------

sub db_blob2memory {
	my $self = shift;

	my ($val) = @_;

	my $blob;
	if ( ref $val and ref $val ne 'SCALAR' ) {
		# Referenz und zwar keine Scalarreferenz
		# => das ist ein Filehandle
		# => reinlesen den Kram
		binmode $val;
		$$blob = join ("", <$val>);
	} elsif ( not ref $val ) {
		# keine Referenz
		# => Dateiname
		# => reinlesen den Kram
		my $fh = new FileHandle;
		open ($fh, $val) or croak "can't open $val";
		binmode $fh;
		$$blob = join ("", <$fh>);
		$self->{debug} && print STDERR "$exc:db_blob2memory: blob_size ($val): ", length($$blob), "\n";
		close $fh;
	} else {
		# andernfalls ist val eine Skalarreferenz mit dem Blob
		# => nix tun
		$blob = $val;
	}

	return $blob;	
}

# BLOB updaten -------------------------------------------------------

sub db_update_blob {
	my $self = shift;

	$self->{debug} && print STDERR "$exc:db_update_blob tmp table entered\n";

	my ($table, $where, $col, $val, $type_href, $param_lref) = @_;

	# blob oder clob?
	
	my $blob_col = $type_href->{$col} eq 'blob' ? 'myblob' : 'myclob';

	# temp table anlegen
	
	$self->do (
		sql => "create temp table dim_blob_insert (".
		       " myblob byte, myclob text ) with no log"
	);

	# dann Blob in temp Table inserten

	$self->do (
		sql => "insert into dim_blob_insert ($blob_col) ".
		       "values (?)",
		params => [ $$val ]
	);
	
	# nun von dort aus in die Zieltabelle updaten
        # FELIX: Einfuegen von Klaus-Fix am 4.8.99.
	# WHERE clause fehlte...
 	
	$self->do (
		sql => "update $table set $col = ".
		       "(select $blob_col from dim_blob_insert) where $where",
			params => $param_lref
	);

	# und die temp. Tabelle löschen
	
	$self->do (
		sql => "drop table dim_blob_insert"
	);

	1;
}

# this is currently disabled

sub db_update_blob_with_fix_installed_table {
	my $self = shift;

	$self->{debug} && print STDERR "$exc:db_update_blob entered\n";

	my ($table, $where, $col, $val, $type_href, $param_lref) = @_;

	# blob oder clob?
	
	my $blob_col = $type_href->{$col} eq 'blob' ? 'myblob' : 'myclob';

	# erstmal Blob in Dummy Table inserten

	$self->do (
		sql => "insert into dim_blob_insert (id, $blob_col) ".
		       "values (0, ?)",
		params => [ $$val ]
	);
	
	my $id = $self->{dbh}->{ix_sqlerrd}->[1];
	
	# nun von dort aus in die Zieltabelle updaten
	
	$self->do (
		sql => "update $table set $col = ".
		       "(select $blob_col from dim_blob_insert ".
		       " where id=$id)"
	);

	# und aus der Dummy Tabelle löschen
	
	$self->do (
		sql => "delete from dim_blob_insert where id=$id"
	);

	1;
}

1;

__END__

=head1 NAME

Dimedis::SqlDriver::Informix - Informix Treiber für das Dimedis::Sql Modul

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

Es werden nur die Informix Blob Datentypen 'byte' und 'text' unterstützt.
Die Smart Blobs der Universal Server Option können nicht verwendet werden.

Das Anlegen von Blobs wird direkt mit DBD::Informix durchgeführt.
DBD::Informix verlangt, daß der Blob hierzu im Speicher vorliegt, er wird
also ggf. vorher vollständig in den Speicher gelesen.

Das Updaten von Blobs wird von DBD::Informix nicht direkt unterstützt, deshalb
wird dieses über einen insert in eine temporäre Tabelle mit anschließendem
Update in die Zieltabelle realisiert. Die temporäre Tabelle wird sofort
wieder entfernt, damit in persistenten Datenbankumbebungen keine Seiteneffekte
auftreten.

Das Lesen von Blobs wird mit der Standardschnittstelle von DBD::Informix
realisiert. Dabei werden Blobs immer vollständig in den Speicher gelesen, auch
wenn sie in das Filesystem geschrieben werden sollen. Ein sequentielles Auslesen
findet hierbei also nicht statt.

=head2 INSTALL METHODE

Für Dimedis::SqlDriver::Informix ist die install Methode leer,
d.h. es werden keine Objekte in der Datenbank vorausgesetzt.

=head2 CONTAINS METHODE

Diese Methode ist z.Zt. nicht implementiert, d.h. liefert B<immer> undef
zurück. Sie wird zukünftig im Falle einer Datenbank mit Universal Data
Option eine Bedingung zurückliefern, die das Excalibur Text Datablade
verwenden wird.

Für Datenbanken ohne die Universal Data Option (z.B. Online Dynamic Server 7)
wird stets undef geliefert, da hier keine Volltextsuche in der Form
möglich ist.

=head1 AUTOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 1999 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1).

=cut
