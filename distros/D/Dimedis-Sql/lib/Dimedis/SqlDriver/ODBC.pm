# $Id: ODBC.pm,v 1.3 2003/08/07 07:48:58 joern Exp $

package Dimedis::SqlDriver::ODBC;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.12';
@ISA = qw(Dimedis::Sql);	# Vererbung von Dimedis::Sql

use Carp;
use File::Copy;
use FileHandle;

my $exc = "Dimedis::SqlDriver::ODBC:";	# Exception Prefix

my $BLOB_CHUNK_SIZE = 32764;

# offizielles Dimedis::SqlDriver Interface ===========================

# install ------------------------------------------------------------

sub db_install {
	my $self = shift;

	eval {
		# wir brauchen eine Tabelle für serials
		$self->do (
			sql => "create table dim_serial (
				  name	varchar(32) not null,
				  id 	integer default 0,
				  primary key(name)
				)"
		);
	};
	
	eval {
		# und eine für Blobs
		$self->do (
			sql => "create table dim_blob (
				  id	integer not null, 
				  pos	integer not null,
				  chunk	image null,
				  primary key(id, pos)
				)"
		);
	};

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

        $dbh->{LongReadLen} = 1000000;  
        $dbh->{LongTruncOk} = 1;
	$dbh->{odbc_default_bind_type} = 1;

	# erstmal die Blob-ID holen
	my ($blob_id) = $self->get (
		sql => "select $par->{col}
			from   $par->{table}
			where  $par->{where}",
		params => $par->{params},
	);
#print "<!--$blob_id -->";	
	return \'' if not $blob_id;
	
	$self->{debug} && 
		print STDERR "$exc:blob_read blob_id=$blob_id\n";
	
	# nun die Chunks dieser ID rausholen
	$self->{debug} && 
		print STDERR "$exc:blob_read SQL=
	select chunk
	from   dim_blob
	where  id=?
	order by pos\n";
	$self->{debug} && print STDERR "$exc:blob_read PARAMS: $blob_id\n";
	
	my $sth = $self->{dbh}->prepare_cached (q{
		select chunk  
		from   dim_blob
		where  id = ?
		order by pos
	}) or die "$exc: prepare $DBI::errstr";
	
	$sth->execute ($blob_id) or croak "$exc: execute $DBI::errstr";

	# Blob lesen
	my $ar;
	my $blob = "";
	my $chunk;
	my $cnt;
	while ( $ar = $sth->fetchrow_arrayref ) {
		++$cnt;
		croak "$exc:db_blob_read fetch $DBI::errstr" if $DBI::errstr;
		#$chunk = pack("H*", $ar->[0]);
		$chunk = $ar->[0];
		$chunk = substr($chunk, 0, length($chunk)-1);
		$blob .= $chunk;
		$self->{debug} &&
			printf STDERR "$exc:db_blob_read %d bytes\n",
				      length($chunk);
	}
#print "<!--: $blob :-->";
	$sth->finish or croak $DBI::errstr;
	
	$self->{debug} &&
		print STDERR "$exc:db_blob_read read $cnt chunks of $BLOB_CHUNK_SIZE bytes\n";
	
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
	
	my ($par)= @_;

	$self->do (
		sql => "use $par->{db}",
		cache => 1
	);

	1;
}

# db_prefix ----------------------------------------------------------

sub db_db_prefix {
	my $self = shift;
	
	my ($par)= @_;

	return $par->{db}.'..';

	1;
}

# contains -----------------------------------------------------------

sub db_contains {
	my $self = shift;
	
	my ($par) = @_;
	my $cond;

	# bei Sybase z.Zt. nicht unterstüzt, deshalb undef returnen

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
			nested => 0
		},
	  	cmpi => 1,
		contains => 0,
		use_db => 1,
		cache_control => 1
	};
}

# Driverspezifische Hilfsmethoden ====================================

# Serial ermitteln ---------------------------------------------------

sub db_get_serial {
	my $self = shift;
	
	my ($table, $col) = @_;
	
	# Serials erzeugen wir selber, da der identity Mechanismus
	# von Sybase nicht im Zusammenhang mit Platzhaltern zu
	# gebrauchen ist (der zuletzt vergebene Wert kann nicht
	# ermittelt werden).
	
	# erstmal die Spalte (bzw. wohl leider die ganze
	# Tabelle) sperren, mit einem Pseudo Update.
	# (sonst könnten serials doppelt vergeben werden, da wir
	#  ja erst lesen und dann updaten müssen. Deshalb muß dieser
	#  Vorgang in jedem Fall atomar ablaufen.)
		
	my $modified = $self->do (
		sql => "update dim_serial
		          set id=id
			where name=?",
		params => [ $table ]
	);
	
	# Hier kommt unsere serial rein.
	my $id;
	
	if ( $modified != 1 ) {
		# oha, die Zeile für unsere Tabelle gibt's noch
		# gar nicht: also anlegen!
		#
		# Wenn das gelingt, setzen wir $id auf 1,
		# wenn  nicht, war ein anderer Prozeß
		# schneller und wir müssen uns den Wert
		# später noch rauslesen ($id bleibt erstmal
		# undef)
		
		my ($max_id) = $self->get (
			sql => "select max($col) from $table"
		);

		$self->{debug} && print STDERR "$exc:get_serial: max_id=$max_id\n";

		$max_id += 100;

		$self->{debug} && print STDERR "$exc:get_serial: create sequence mit start=$max_id\n";
		
		eval {
			$self->do (
				sql => "insert into dim_serial
					(name, id)
					values
					(?, ?)",
				params => [ $table, $max_id ]
			);
			$id = $max_id;
		};
	}
	
	# wenn $id noch undef, dann müssen wir uns den Wert
	# aus der Datenbank holen, eins hochzählen und
	# wieder wegschreiben
	
	if ( not $id ) {
		($id) = $self->get (
			sql => "select id
				from   dim_serial
				where  name=?",
			params => [ $table ]
		);
		++$id;
		$modified = $self->do (
			sql => "update dim_serial
				  set id=?
				where name=?",
			params => [ $id, $table ]
		);
		croak "Serial konnte nicht upgedated werden!"
			unless $modified == 1;
	}
	
	return $id;
}


# Insert bzw. Update durchführen -------------------------------------

sub db_insert_or_update {
	my $self = shift;

	$self->{debug} && print STDERR "$exc:db_insert_or_update entered\n";

	my ($par) = @_;
	my $type_href = $par->{type};
	my $par_cache = $par->{cache};

	my $serial;			# evtl. Serial Wert
	my (@columns, @values);		# Spaltennamen und -werte
	my $return_value;		# serial bei insert,
					# modified bei update
	
	# Parameter aufbereiten

	my ($col, $val);
	my @parameters;	# Parameter (Parameterbinding, falls moeglich)
	my %blobs;	# Hier werden BLOB Spalten abgelegt, die
			# nach dem INSERT eingefügt werden
	my $blob_found;
	my $primary_key;	# Name der primary key Spalte

	# Normalerweise werden Statements gecached,
	# es gibt aber auch Ausnahmen (z.B. bei globaler
	# Abschaltung oder größeren Texten, s.u.)
	my $cache = 1;

	if ( exists $par->{cache} ) {
		# oder der Benutzer will das Caching Verhalten
		# explizit selbst steuern
		# (wobei das später trotzdem noch abgeschaltet werden
		#  kann, z.B. bei größeren Texten, s.u.)
		$cache = $par_cache;
	}

	# wenn global abgeschaltet, dann bleibt's auch so
	$cache = 0 if not $self->{cache};

	while ( ($col,$val) = each %{$par->{data}} ) {
		my $type  = $type_href->{$col};
		$type     =~ s/\(([^\(]+)\)$//;
		my $scale = $1;
		
		$type     =~ s/\[.*//;

		if ( $type eq 'serial' and ( not $val or not $self->{serial_write} ) ) {

			# serials generieren wir uns selber
			$return_value = $self->db_get_serial ($par->{table}, $col);
			push @columns,    $col;
			push @values,     $return_value;
			push @parameters, "?";
			$primary_key = $col;

		} elsif ( $type eq 'blob' or $type eq 'clob' ) {

			# Blobs müssen später reingeupdated
			# werden (keine Blob-Handling mit
			# Platzhaltern möglich)

			my $blob_id;
			if ( $par->{db_action} eq 'insert' ) {
				# bei einem Insert legen wir schonmal
				# die Blob-ID an
				$blob_id = $self->db_get_serial ("dim_blob", "id");
				push @columns,   $col;
				push @values,    $blob_id;
				push @parameters, "?";
			} else {
				# bei einem Update holen wir uns die
				# Blob-ID aus der Tabelle
				($blob_id) = $self->get (
					sql => "select $col
						from   $par->{table}
					        where  $par->{where}",
					params => $par->{params}
				);
			}
				
			$blob_found = 1;
			$blobs{$col} = {
				id => $blob_id,
				val => $val
			};
		} elsif ( $type eq 'varchar' and $scale > 255) {
			# grosse Texte muessen im Datentyp Text gespeichert werden,
			# fuer den allerdings kein Parameterbinding gemacht werden 
			# kann
			push @columns, $col;
			
			if ( $val eq '' or not defined $val ) {
				push @parameters, "NULL";
			} else {
				push @parameters, $self->{dbh}->quote($val);
			}
			
			$cache = 0;

		} else {
			# alle übrigen Typen werden as is eingefügt
			push @columns, $col;
			push @values,  $val;
			push @parameters, "?";
		}
	}
	
	# Insert oder Update durchführen
	
	if ( $par->{db_action} eq 'insert' ) {
		# insert ausführen

		$self->do (
			sql => "insert into $par->{table} (".
			       join (",",@columns).
			       ") values (".
			       join (",",@parameters).
			       ")",
			params => \@values,
			cache => $cache
		);
	} else {
		# Parameter der where Klausel in @value pushen
		push @values, @{$par->{params}};
		
		# update ausführen, wenn columns da sind
		# (bei einem reinen BLOB updated passiert es,
		#  daß keine 'normalen' Spalten upgedated werden)
		
		if ( @columns ) {
			my $i = 0;
			$return_value = $self->do (
				sql => "update $par->{table} set ".
				       join(",", map( "$_=" . $parameters[$i++], 
				       @columns)).
				       " where $par->{where}",
				params => \@values,
				cache => $cache
			);
			
		}
	}

	# nun evtl. BLOBs verarbeiten
	
	if ( $blob_found ) {
		my $method = "db_$par->{db_action}_blob";
		while ( ($col,$val) = each %blobs ) {
			$self->db_update_or_insert_blob (
				$val->{id},		# Blob ID
				$type_href->{$col},	# Blob Typ
				$par->{table},		# Tabellenname
				$col,			# Blob Spalte
				$val->{val}		# Blob
			);
		}
	}

	return $return_value;
}

# BLOB updaten oder einfügen -----------------------------------------

sub db_update_or_insert_blob {
	my $self = shift;

	$self->{debug} && print STDERR "$exc:db_update_or_insert_blob entered\n";

	my ($blob_id) = @_;

	# gibt's schon einen Blob?
	my ($blob_exists) = $self->get (
		sql => "select pos
		        from   dim_blob
			where  id=? and pos=1",
		params => [ $blob_id ]
	);

	if ( $blob_exists ) {
		# update
		$self->db_update_blob (@_);
	} else {
		# insert
		$self->db_insert_blob (@_);
	}
}

sub db_insert_blob {
	my $self = shift;

	my ($blob_id, $type, $table, $col, $val) = @_;
		
	$self->{debug} && print STDERR "$exc:db_insert_blob: serial=$blob_id\n";

	my $fh;
	if ( not ref $val ) {
		# ein Dateiname: öffnen
		$fh = new FileHandle;
		open ($fh, $val) or croak "$exc: can't read file '$val'";
		binmode $fh;
	} elsif ( ref $val ne 'SCALAR' ) {
		# kein Skalar, dann Filehandle
		$fh = $val;
		binmode $fh;
	}
		
	# nun ist $fh das FileHandle des Blobs, oder undef,
	# wenn der Blob im Speicher liegt und $val die
	# entsprechende Skalarreferenz ist
		
	my $pos = 0;
	if ( not $fh ) {
		# Blob liegt im Speicher vor
		my $len = length($$val);
		my $idx = 0;
		while ( $idx < $len ) {
			++$pos;
			$self->{debug} &&
				print STDERR "$exc:db_insert_blob: insert $BLOB_CHUNK_SIZE characters...\n";
			$self->do (
				sql => "insert into dim_blob (id, pos, chunk)
					values ($blob_id, $pos, 0x".
					unpack("H*", substr($$val, $idx, $BLOB_CHUNK_SIZE)).
					"FF)",
				cache => 0
			);
			$idx += $BLOB_CHUNK_SIZE;
		}
	} else {
		# Blob liegt als File vor
		my $chunk;
		while ( read ($fh, $chunk, $BLOB_CHUNK_SIZE) ) {
			++$pos;
			$self->{debug} &&
				print STDERR "$exc:db_insert_blob: insert ", length($chunk), " characters...\n";
			$self->do (
				sql => "insert into dim_blob (id, pos, chunk)
					values ($blob_id, $pos, 0x".
					unpack("H*", $chunk).
					"FF)",
				cache => 0
			);
		}
		
		# Datei schließen, wenn wir sie selber geöffnet haben
		close $fh if not ref $val;
	}

	1;
}

sub db_update_blob {
	my $self = shift;

	my ($blob_id, $type, $table, $col, $val) = @_;
		
	$self->{debug} && print STDERR "$exc:db_update_blob: serial=$blob_id\n";

	my $fh;
	if ( not ref $val ) {
		# ein Dateiname: öffnen
		$fh = new FileHandle;
		open ($fh, $val) or croak "$exc: can't read file '$val'";
		binmode $fh;
	} elsif ( ref $val ne 'SCALAR' ) {
		# kein Skalar, dann Filehandle
		$fh = $val;
		binmode $fh;
	}
		
	# nun ist $fh das FileHandle des Blobs, oder undef,
	# wenn der Blob im Speicher liegt und $val die
	# entsprechende Skalarreferenz ist
		
	my $pos = 0;
	my $insert = 0;		# wird auf evtl. auf 1 gesetzt, wenn neuer Blob
				# größer als aktueller Blob ist, dann müssen
				# neue Chunks angehängt werden.

	if ( not $fh ) {
		# Blob liegt im Speicher vor
		my $len = length($$val);
		my $idx = 0;
		while ( $idx < $len ) {
			++$pos;

			if ( not $insert ) {
				my $updated = $self->do (
					sql => "update dim_blob set chunk=0x".
						unpack("H*", substr($$val, $idx, $BLOB_CHUNK_SIZE)).
						"FF where id=$blob_id and pos=$pos",
					cache => 0
				);
				$self->{debug} && print STDERR "$exc:db_blob_update update ".
						"$BLOB_CHUNK_SIZE characters (modified=$updated)...\n";
				if ( $updated == 0 ) {
					$insert = 1;
				}
			}

			if ( $insert ) {
				$self->do (
					sql => "insert into dim_blob (id, pos, chunk)
						values ($blob_id, $pos, 0x".
						unpack("H*", substr($$val, $idx, $BLOB_CHUNK_SIZE)).
						"FF)",
					cache => 0
				);
				$self->{debug} && print STDERR "$exc:db_blob_update insert ".
						"$BLOB_CHUNK_SIZE characters...\n";
			}

			$idx += $BLOB_CHUNK_SIZE;
		}
	} else {
		# Blob liegt als File vor
		my $chunk;
		while ( read ($fh, $chunk, $BLOB_CHUNK_SIZE) ) {
			++$pos;

			if ( not $insert ) {
				my $updated = $self->do (
					sql => "update dim_blob set chunk=0x".
						unpack("H*", $chunk).
						"FF where id=$blob_id and pos=$pos",
					cache => 0
				);
				$self->{debug} &&
					print STDERR "$exc:db_blob_update update ".
						length($chunk)." characters (modified=$updated)...\n";
				if ( $updated == 0 ) {
					$insert = 1;
				}
			}

			if ( $insert ) {
				$self->do (
					sql => "insert into dim_blob (id, pos, chunk)
						values ($blob_id, $pos, 0x".
						unpack("H*", $chunk).
						"FF)",
					cache => 0
				);
				$self->{debug} &&
					print STDERR "$exc:db_blob_update insert ".
						length($chunk)." characters...\n";
			}
		}
		
		# Datei schließen, wenn wir sie selber geöffnet haben
		close $fh if not ref $val;
	}

	if ( not $insert ) {
		# wenn noch im UPDATE Modus, ist der neue Blob vielleicht
		# kleiner. In dem Fall löschen wir den Rest.
		my $deleted = $self->do (
			sql => "delete from dim_blob
				where id=? and pos > ?",
			params => [ $blob_id, $pos ]
		);
		
		$self->{debug} &&
			print STDERR "$exc:db_blob_update deleted ".
				$deleted." unused blob chunks!\n";
	}

	1;
}

1;

__END__

=head1 NAME

Dimedis::SqlDriver::Sybase - Sybase Treiber für das Dimedis::Sql Modul

=head1 SYNOPSIS

siehe Dimedis::Sql

=head1 DESCRIPTION

siehe Dimedis::Sql

=head1 BESONDERHEITEN DER IMPLEMENTIERUNG

=head2 SERIAL BEHANDLUNG

Spalten, die mit dem 'serial' Datentyp angegeben sind, müssen in der
Datenbank als primary key integer Spalten deklariert sein, z.B.

        id integer primary key not null

Aufgrund von Restriktionen der Sybase Datenbank im Zusammenhang mit
Parameter Binding kann der Sybase eigene identity Mechanismus nicht
verwendet werden.

Stattdessen legt die $sqlh->install Methode eine eigene Tabelle für
die Verwaltung von serials an.

  create table dim_serial (
	  name	varchar(32),
	  id 	integer default 0,
	  primary key(name)
  )

Die Verwaltung dieser Tabelle erfolgt durch Dimedis::Sql vollkommen
transparent.

=head2 BLOB BEHANDLUNG

Blobs werden vollständig über eine eigene Implementierung innerhalb
von Dimedis::Sql verwaltet. Hierzu legt die $sqlh->install Methode
eine Tabelle an, die Blobs in Form von einzelnen Datensätzen mit
einer maximalen Größe von derzeit knapp 16KB aufnimmt.

  create table dim_blob (
	  id	integer not null, 
	  pos	integer not null,
	  chunk	image null,
	  primary key(id, pos)
  )

Eine Tabelle, die einen Blob aufnehmen soll, enthält nun nur eine
integer Referenz auf die ID des Blobs (dim_blob.id), da der Blob
selbst ja in der dim_blob Tabelle gespeichert wird. Der Zugriff
auf den Blob (lesend wie schreibend) wird durch Dimedis::Sql
vollkommen transparent durchgeführt.

Sybase Blobs machen keinen Unterschied zwischen textuellen (CLOB)
und binären (BLOB) Daten.

Beispiel für eine Tabelle mit Blobs:

  create table test (
	id integer primary key not null,
	bild_blob integer null,
	text_blob integer null
  )

Damit Blobs, die auf diese Weise von einer Tabelle aus referenziert
werden, auch beim Löschen von Datensätzen mit entfernt werden,
muß ein Trigger angelegt werden, für jede Tabelle, die Blobs enthält:

  create trigger test_del
     on  test
     for delete as
	 delete from dim_blob
	 where  id in (select bild_blob from deleted) or
	        id in (select text_blob from deleted)

Die where Bedingung des 'delete' Statements muß natürlich
entsprechend der Haupttabelle angepaßt werden. (Die 'deleted'
Tabelle in der where Bedingung ist eine Pseudo Tabelle, die
alle Datensätze der Haupttabelle enthält, die im Begriff sind
durch das aktuell durchgeführte delete Statement entfernt zu
werden).

=head2 NULL VALUES

Dies ist keine Besonderheit von Dimedis::SqlDriver::Sybase,
sie betrifft Sybase Datenbanken grundsätzlich. Per Default sind
Spalten in Sybase stets mit NOT NULL deklariert. Um eine Spalte
zu erzeugen, die NULL Werte aufnehmen darf, muß explizit NULL
angegeben werden. (Siehe Beispieltabelle bei BLOB BEHANDLUNG).

=head2 LEFT OUTER JOIN METHODE

Sybase kennt keine nested outer Joins. Derzeit liefert Dimedis::Sql
zwar Werte für diesen Fall zurück, diese werden jedoch bei Ausführung
von Sybase als fehlerhaft abgewiesen.

Nested outer Joins müssen demzufolge per Hand in der Applikation
realisiert werden. (Ob eine Datenbank nested outer Joins unterstützt,
kann mit der Methode $sqlh->get_features abgefragt werden).

=head2 CONTAINS METHODE

Diese Methode ist z.Zt. nicht implementiert, d.h. liefert B<immer> undef
zurück.

=head2 INSTALL METHODE

Die $sqlh->install Methode legt zwei Tabellen an, sofern sie
nicht schon existieren:

  dim_serial	verwaltet Serials (siehe SERIAL BEHANDLUNG)
  dim_blob	verwaltet Blobs (sie BLOB BEHANDLUNG)

=head1 AUTOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 1999 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1).

=cut
