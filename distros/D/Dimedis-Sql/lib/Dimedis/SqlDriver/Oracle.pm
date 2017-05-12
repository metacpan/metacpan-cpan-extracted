package Dimedis::SqlDriver::Oracle;

use strict;
use vars qw($VERSION @ISA);

$VERSION = '0.23';
@ISA = qw(Dimedis::Sql);	# Vererbung von Dimedis::Sql

use Carp;
use File::Copy;
use File::Basename;
use FileHandle;

my $exc = "Dimedis::SqlDriver::Oracle:";	# Exception Prefix

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
	my $filename = $par->{filename};
	
	my $dbh = $self->{dbh};

        $self->{debug} && print STDERR "$exc:db_blob_read: entered\n";
	
	# Truncating ist Ok. Die Blobs werden ja eh mit blob_read() gelesen,
	# da kann beim fetch() ruhig abgeschnitten werden.
	$dbh->{LongTruncOk} = 1;
	
	# Ohne eine zusätzliche Spalte funktioniert das Ganze nicht,
	# deshalb wird noch konstant 1 dazuselektiert
	my $sth = $dbh->prepare (
		"select 1, $par->{col}
		 from   $par->{table}
		 where  ($par->{where}) and $par->{col} is not NULL"
	) or die "$DBI::errstr";
		
	$sth->execute(@{$par->{params}}) or die $DBI::errstr;
	die $DBI::errstr if $DBI::errstr;

	my $blob = '';
	my $offset = 0;
	
	# Blob lesen
	my $fh;

	if ( $filename ) {
		$fh = new FileHandle;
		open ($fh, "> $filename")
			or die "can't write $filename";
	        $self->{debug} && print STDERR "$exc:db_blob_read: will write to $filename\n";
	} else {
		$fh = $par->{filehandle};
	        $self->{debug} && print STDERR "$exc:db_blob_read: will write to fh\n"
			if $fh;
	        $self->{debug} && print STDERR "$exc:db_blob_read: will return as sref\n"
			if not $fh;
	}

	binmode $fh if $fh;

	if ( $sth->fetchrow_arrayref ) {
		while (1) {
			$self->{debug} && print STDERR "$exc:db_blob_read: sth->blob_read(1, $offset, 32768)\n";
			my $frag = $sth->blob_read(1, $offset, 32768);
			$self->{debug} && print STDERR "$exc:db_blob_read: got something: len=".length($frag)."\n"
				if $frag ne '';
			$self->{debug} && print STDERR "$exc:db_blob_read: got nothing\n" if $frag eq "";
			last unless defined $frag;
			my $len = length $frag;
			last unless $len;
			if ( $fh ) {
				print $fh $frag or
					die "$exc:db_blob_read\tcan't write blob ".
					    "chunk to $filename";
			} else {
				$blob .= $frag;
			}
			$offset += $len;
		}
		
		$sth->finish or die $DBI::errstr;
	}
	
	close $fh if $fh and not $par->{filehandle};
	
	return if $par->{filehandle} or $par->{filename};
	return \$blob;
}

# left_outer_join ----------------------------------------------------

{
	my $from;
	my $where;
	my %from_tables;

	sub db_left_outer_join {
		my $self = shift;
	
		# static Variablen initialisieren
		
		$from = "";
		$where = "";
		%from_tables = ();

		# Rekursionsmethode anwerfen

		$self->db_left_outer_join_rec ( @_ );

		# Dreck bereinigen
		
		$from =~ s/,$//;
		$where =~ s/ AND $//;

		return ($from, $where);
	}

	sub db_left_outer_join_rec {
		my $self = shift;

		my ($lref) = @_;
		
		# linke Tabelle in die FROM Zeile

		my $left = $lref->[0];
		$from .= $left."," unless $from_tables{$left};
		$from_tables{$left} = 1;
	
		if ( ref $lref->[1] ) {
			# aha, Outer Join
			if ( @{$lref->[1]} > 1 ) {
				# kein einfacher Outer Join
				# (verschachtelt oder outer join gegen
				#  simple join, Fall II/III)

				$where .= $self->db_join_cond (
					$left,
					$lref->[2],
					$lref->[1]->[0],
					'outer'
				)." AND ";
				$self->db_left_outer_join_rec ($lref->[1]);
			} else {
				# Fall I, outer join einer linken Tabelle
				# gegen eine oder mehrere rechte Tabellen
				my $i = 1;
				while ($i < @{$lref}) {
					$from  .= $lref->[$i]->[0].","
						unless $from_tables{$lref->[$i]->[0]};
					$from_tables{$lref->[$i]->[0]} = 1;
					$where .= $self->db_join_cond (
						$left,
						$lref->[$i+1],
						$lref->[$i]->[0],
						'outer'
					)." AND ";
					$i += 2;
				}
			}
		} else {
			# noe, kein Outer join
			die "$exc:db_left_outer_join\tcase III does not exist anymore";
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
	my $quoted = $self->{dbh}->quote ( lc($par->{val}) );

	Encode::_utf8_on($quoted) if $self->{utf8};

	return "lower($par->{col}) $par->{op} ".$quoted;
}

# use_db -------------------------------------------------------------

sub db_use_db {
	my $self = shift;
	
	my ($par)= @_;

	$self->do (
		sql => "alter session set current_schema = $par->{db}"
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

# install ------------------------------------------------------------

sub db_install {
	# nichts zu tun hier, für Oracle

	1;
}

# contains -----------------------------------------------------------

sub db_contains {
	my $self = shift;
	my ($par) = @_;
	my $val_lr = $par->{vals};

	#---- Die Sonderzeichen in den Values muessen escaped werden,
	#---- da sonst "DRG-50937: query too complex" Fehler schnell
	#---- auftreten koennen, wenn man bspw. nach "e-mail" sucht.
	#---- Die Alternative, die Suchworte einfach in "{}" zu setzen,
	#---- escaped zwar auch die Sonderzeichen, behandelt aber
	#---- die Teilworte trotzdem als einzelne Suchworte.
	#---- Bei bspw. "e-mail" wird dann auch wieder nach "e" und "mail"
	#---- gesucht, was wieder in einer too complex Suche resultieren kann.
	#---- Daher die Zeichen einzeln escapen.
	my @values;
        foreach my $v ( @{$val_lr} ) {
                my $value = $v;
                $value =~ s/[^0-9a-z]+$//i; 
                $value =~ s/([^0-9a-z])/\\$1/ig;
                push @values, $value if $value ne '';
        }        
	
	return "" if not @values;
	
	my $cond;
	if ( $par->{search_op} eq 'sub' ) {
		$cond = "contains($par->{col}, ".
		$self->{dbh}->quote (
		    join (
			" ".$par->{logic_op}." ",
			map "$_%", @values
		    )
		).
		") > 0";
	}

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
		utf8 => 1,
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
				$qm .= $type eq 'blob' ?
					"empty_blob()," :
					"empty_clob(),";
			}

			$blob_found = 1;
			$blobs{$col} = $val;

		} else {
			# alle übrigen Typen werden as is eingefügt
			push @columns, $col;
			push @values, $val;
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
			sql => "select $sequence.nextval from dual",
			cache => 1
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
				start with $max_id
				increment by 1"
		);
		$serial = $max_id-1;
	}
	
	return $serial;
}

# BLOB speichern -----------------------------------------------------

sub db_put_blob {
	my $self = shift;

	$self->{debug} && print STDERR "$exc:db_put_blob entered\n";

	# Workaround für DBD::Proxy. Wenn kein DBD::Oracle installiert
	# geht das natürlich nicht. Somit funktionieren aber wenigstens
	# alle Funktionen außer db_put_blob auch unter DBD::Proxy.
	require "DBD/Oracle.pm";
	import DBD::Oracle qw(:ora_types)
		if not $Dimedis::SqlDriver::Oracle::already_imported;
	$Dimedis::SqlDriver::Oracle::already_imported = 1;

	my ($table, $where, $col, $val, $type_href, $param_lref) = @_;
	
	my $type = $type_href->{$col};

	my $set_utf8 = $self->{utf8} && $type eq 'clob';

	my $blob = $self->blob2memory($val, $col, $type);

	# in $blob steht nun eine Skalarrereferenz auf den Blob

	$self->{debug} && print STDERR "$exc:db_put_blob ".
		"prepare: update $table set $col = ? where $where\n";

	my $sth = $self->{dbh}->prepare (qq{
		update $table set $col = ? where $where
	}) or croak "$exc:db_put_blob\t$DBI::errstr";

	my $ora_type;
	$ora_type = $type eq 'blob' ? ORA_BLOB() : ORA_CLOB();

	$self->{debug} && print STDERR "$exc:db_put_blob ora_type=$ora_type\n";

	$sth->bind_param(1, $$blob, {ora_type => $ora_type, ora_field => $col} )
		or croak "$exc:db_put_blob\t$DBI::errstr";

	my $i = 2;
	foreach my $par (@{$param_lref}) {
		$sth->bind_param($i, $par);
		++$i;
	}
		
	$sth->execute
		or croak "$exc:db_put_blob\t$DBI::errstr";

	$sth->finish
		or croak "$exc:db_put_blob\t$DBI::errstr";

	$self->{debug} && print STDERR "$exc:db_put_blob succesfully put blob\n";

	1;
}

1;

__END__

=head1 NAME

Dimedis::SqlDriver::Oracle - Oracle Treiber für das Dimedis::Sql Modul

=head1 SYNOPSIS

use Dimedis::SqlDriver;

=head1 DESCRIPTION

siehe Dimedis::Sql

=head1 BESONDERHEITEN DER IMPLEMENTIERUNG

=head2 SERIAL BEHANDLUNG

Der 'serial' Datentyp wird mit Sequences realisiert. Dabei wird
für jede Tabelle automatisch eine Sequence verwaltet, deren Name
sich wie folgt zusammensetzt:

        ${table}_SEQ

Wenn die Sequence noch nicht existiert, wird sie automatisch
angelegt. Die Zählung beginnt dabei mit 1.

=head2 BLOB BEHANDLUNG

Es werden nur die Oracle Blob Datentypen 'blob' und 'clob'
unterstützt. Der Datentyp 'long' kann nicht verwendet werden.

Das Schreiben von Blobs wird direkt mit DBD::Oracle durchgeführt.
DBD::Oracle verlangt, daß der Blob hierzu im Speicher vorliegt, er wird
also ggf. vorher vollständig in den Speicher gelesen.

Das Lesen von Blobs wird mit der DBI blob_read Methode realisiert.
Dabei werden Blobs mit einer Blockgröße von 32KB sequentiell eingelesen.
Wenn also ein Blob in das Filesystem geschrieben werden soll, wird er
hierzu nicht vollständig in den Hauptspeicher eingelesen.

=head2 INSTALL METHODE

Für Dimedis::SqlDriver::Oracle ist die install Methode leer,
d.h. es werden keine Objekte in der Datenbank vorausgesetzt.

=head2 CONTAINS METHODE

Es wird in für diese Abfrage korrekt konfiguriertes Oracle Context
Cartridge vorausgesetzt. Die Abfrage liefert _alle_ Einträge zurück,
die matchen, d.h. bei einem Score von > 0 liegt ein Match vor.

=head2 USE METHODE

Der Wechsel in eine andere Datenbank bedeutet bei Oracle den Wechsel
auf ein anderes Default Schema. Der User, mit dem die Datenbankverbindung
hergestellt wurde, muß also die Rechte haben, um auf die Objekte dieses
Schemas zugreifen zu dürfen.

=head1 AUTOR

Jörn Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 1999 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1).

=cut
