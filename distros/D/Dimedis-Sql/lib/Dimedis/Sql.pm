package Dimedis::Sql;

use strict;
use vars qw($VERSION);
use Carp;
use FileHandle;
use Encode;

$VERSION = '0.44';

my $exc = "Dimedis::Sql:";	# Exception-Type prefix

my %known_data_types = (	# bekannte Datentypen
	'serial'  => 1,
	'date'    => 1,
	'clob'    => 1,
	'blob'    => 1,
	'varchar' => 1,
	'char'    => 1,
	'integer' => 1,
	'numeric' => 1,
);

my %known_operators = (		# bekannte Operatoren
	'='	 => 1,
	'!='	 => 1,
	'like'	 => 1
);

sub get_dbh			{ shift->{dbh}				}
sub get_debug			{ shift->{debug}			}
sub get_type			{ shift->{type}				}
sub get_cache			{ shift->{cache}			}
sub get_serial_write		{ shift->{serial_write}			}
sub get_utf8			{ shift->{utf8}				}

sub set_debug			{ shift->{debug}		= $_[1]	}
sub set_type			{ shift->{type}			= $_[1]	}
sub set_cache			{ shift->{cache}		= $_[1]	}
sub set_serial_write		{ shift->{serial_write}		= $_[1]	}
sub set_utf8			{ shift->{utf8}			= $_[1]	}

# Kann, muss aber nicht von Drivern implementiert werden
sub db_init 			{ 1 }

# Konstruktor --------------------------------------------------------

sub new {
	my $class = shift;
	my %par = @_;
	my  ($dbh, $debug, $type, $cache, $serial_write, $utf8) =
	@par{'dbh','debug','type','cache','serial_write','utf8'};

	$type ||= {};
	
	# Abwärtskompatibilität: wenn cache nicht angegeben ist,
	# wird das Caching eingeschaltet.

	if ( not exists $par{cache} ) {
		$cache = 1;
	}

	# Parametercheck
	
	croak "$exc:new\tmissing dbh" if not $dbh;

	# Datenbanktyp ermitteln

	my $db_type = $dbh->{Driver}->{Name};

	# Sonderbehandlung fuer das Proxymodul	
	if ( $db_type eq "Proxy") {
	  # Aus dem DSN die eigentlichen Datenbanktyp ermitteln
	  $dbh->{Name} =~ m/;dsn=dbi:([^:]+):/;
	  $db_type     = $1;
	}

	# Instanzhash zusammenbauen
	
	my $self = {
		dbh          => $dbh,
		debug        => $debug,
		db_type      => $db_type,
		db_features  => undef,
		type_href    => $type,
		cache        => $cache,
		serial_write => $serial_write,
		utf8         => $utf8,
	};

	$debug && print STDERR "$exc:new\tdb_type=$db_type\n";

	# datenbankspezifische Methoden definieren
	require "Dimedis/SqlDriver/$db_type.pm";

	# diese Klasse in die Vererbungshierarchie einfügen
	my $driver_isa = "Dimedis::SqlDriver::$db_type:\:ISA";
	{ no strict; @{$driver_isa} = ( $class ); }

	# diese Instanz auf die SqlDriver Klasse setzen
	bless $self, "Dimedis::SqlDriver::$db_type";
	
	# Initialisierungsmethode aufrufen
	$self->db_init;
	
	# features Hash initialisieren
	$self->{db_features} = $self->db_get_features;

	# ggf. Encode Modul laden
	require Encode if $utf8;
	
	return $self;
}

# Datentyp-Check -----------------------------------------------------

sub check_data_types {
	my $self = shift;
	
	my ($type_href, $data_href, $action) = @_;

	my $serial_found;
	my $blob_found;
	
	my ($col, $type);
	while ( ($col,$type) = each %{$type_href} ) {
	
		# Nur der Datentyp ohne Groessenangabe
		$type =~ s/\([^\(]+\)$//;
		
		croak "$exc:check_data_types\ttype $type unknown"
			unless defined $known_data_types{$type};

		if ( $type eq 'serial' ) {
			# Serials dürfen nur 1x vorkommen
			if ( exists $data_href->{$col} ) {
				croak "$exc:check_data_types\tmultiple serial type"
					if $serial_found;
				$serial_found = $col;
			}
			# wurde was anderes als undef übergeben,
			# dann Exception
			croak "$exc:check_data_types\t".
			    "only the undef value allowed for serial columns"
			    	if defined $data_href->{$col} and
				   not $self->{serial_write};
			
		} elsif ( $type eq 'date') {
			# GROBER Datumsformatcheck
			croak "$exc:check_data_types\t".
			    "illegal date: $col=$data_href->{$col}"
				if $data_href->{$col} and
				   $data_href->{$col} !~
				   /^\d\d\d\d\d\d\d\d\d\d:\d\d:\d\d$/;
		} elsif ( $type eq 'blob' or $type eq 'clob' ) {
			$blob_found = 1 if exists $data_href->{$col};
		}
	}

	croak "$exc:check_data_types\tblob/clob handling only with serial column"
		if $action eq 'insert' and $blob_found and
		   (not $serial_found or
		    not exists $data_href->{$serial_found});

	return $serial_found;
}

# INSERT -------------------------------------------------------------

sub insert {
	my $self = shift;
	my %par = @_;

	$par{type} ||= $self->{type_href}->{$par{table}}; # wenn undef, globales Type Hash holen

	# Parametercheck
	
	croak "$exc:insert\tmissing table" unless defined $par{table};
	croak "$exc:insert\tmissing data"  unless defined $par{data};

	$self->check_data_types (
		$par{type}, $par{data}, 'insert'
	);

	# Hier kein UTF8 Upgrading, wird beim späteren
	# $self->do ( sql => ... ) gemacht. Die Werte
	# in Data sind noch nicht unbedingt die finalen
	# Werte (z.B. bei Blobs können hier Filenamen
	# drin stehen, die an dieser Stelle also noch
	# nicht zu UTF8 gewandelt werden dürfen).

	# Driver-Methode aufrufen
	my $serial;
	eval {
		$serial = $self->db_insert (\%par);
	};
	croak "$exc:insert\t$@" if $@;

	return $serial;	
}

# UPDATE -------------------------------------------------------------

sub update {
	my $self = shift;
	my %par = @_;
	
	$par{type}   ||= $self->{type_href}->{$par{table}}; # wenn undef, globales Type Hash holen
	$par{params} ||= [];	# wenn undef, leeres Listref draus machen
	
	# Parametercheck
	
	croak "$exc:insert\tmissing table" unless defined $par{table};
	croak "$exc:insert\tmissing data"  unless defined $par{data};
	croak "$exc:insert\tmissing where" unless defined $par{where};

	my $serial_found = $self->check_data_types (
		$par{type}, $par{data}, 'update'
	);
	
	croak "$exc:insert\tserial in update not allowed" if $serial_found;
	
	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		foreach my $p ( $par{where}, @{$par{params}} ) {
			utf8::upgrade($p);
		}
	}
	
	# Kein UTF8 Upgrading auf %{$data}, wird beim späteren
	# $self->do ( sql => ... ) gemacht. Die Werte
	# in %{$data} sind noch nicht unbedingt die finalen
	# Werte (z.B. bei Blobs können hier Filenamen
	# drin stehen, die an dieser Stelle also noch
	# nicht zu UTF8 gewandelt werden dürfen).

	# Driver-Methode aufrufen
	
	my $modified;
	eval {
		$modified = $self->db_update (\%par);
	};
	croak "$exc:update\t$@" if $@;

	return $modified;
}

# BLOB_READ ----------------------------------------------------------

sub blob_read {
	my $self = shift;
	my %par = @_;
	
	$par{params} ||= [];	# wenn undef, leeres Listref draus machen

	# Parametercheck
	
	croak "$exc:blob_read\tmissing table" unless defined $par{table};
	croak "$exc:blob_read\tmissing where" unless defined $par{where};
	croak "$exc:blob_read\tmissing col"   unless defined $par{col};
	croak "$exc:blob_read\tgot filehandle and filename parameter"
		if defined $par{filehandle} and defined $par{filename};
                
	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		foreach my $p ( $par{where}, @{$par{params}} ) {
			utf8::upgrade($p);
		}
	}
	
	# Driver-Methode aufrufen
	my $blob;
	eval {
		$blob = $self->db_blob_read (\%par);
	};

	croak "$exc:blob_read\t$@" if $@;

	# ggf. UTF8 Flag setzen, wenn clob
	if ( $blob and $self->{utf8} and
	     $self->{type_href}->{$par{table}}->{$par{col}} eq 'clob' ) {
	        $self->{debug} && print STDERR "$exc:db_blob_read: Encode::_utf8_on($par{col})\n";
		Encode::_utf8_on($$blob);
	}

	return $blob;
}

# DO -----------------------------------------------------------------

sub do {
        my $self = shift;
	my %par = @_;
	my  ($sql, $par_cache, $no_utf8, $params, $no_nulling) =
	@par{'sql','par_cache','no_utf8','params','no_nulling'};

	$params ||= [];
	
	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} and not $no_utf8 ) {
		foreach my $p ( $par{sql}, @{$params} ) {
			utf8::upgrade($p);
		}
	}
	elsif ( not $self->{utf8} and not $no_utf8 ) {
		foreach my $p ( $par{sql}, @{$params} ) {
			$p = Encode::encode("windows-1252", $p)
				if Encode::is_utf8($p);
		}
	}

	# Normalerweise werden SQL Statements hier von DBI gecached.
	# Es gibt aber Befehle, bei denen das keinen Sinn macht.
	# Deshalb gibt es drei Mechanismen, die das Caching steuern:
	
	# 1. wenn keine SQL Parameter übergeben wurden, gehen wir davon
	#    aus, daß das Statement die Parameter enthält. In diesem
	#    Fall wollen wir das Statement nicht cachen.
	my $use_prepare_cached = @{$params};

	# 2. über den Parameter cache kann das Caching explizit
	#    gesteuert werden
	if ( exists $par{cache} ) {
		$use_prepare_cached = $par_cache;
	}

	# 3. wenn das Caching beim Erzeugen des Dimedis::Sql Instanz
	#    abgeschaltet wurde, gibt's kein Caching!
	
	$use_prepare_cached = 0 if not $self->{cache};

        $self->{debug} && print STDERR "$exc:do: sql = $sql\n";
        $self->{debug} && print STDERR "$exc:do: params = ".
		join(",", @{$params}), "\n";

	my $sth;
	if ( $use_prepare_cached ) {
		$self->{debug} && print STDERR "$exc:do: statement is cached\n";
		$sth = $self->{dbh}->prepare_cached ($sql);
	} else {
		$self->{debug} && print STDERR "$exc:do: statement is NOT cached\n";
		$sth = $self->{dbh}->prepare ($sql);
	}
	croak "$exc:do\t$DBI::errstr\n$sql" if $DBI::errstr;

	if ( not $no_nulling ) {
		for ( @{$params} ) {
			$_ = undef if $_ eq ''
		};
	}

	my $modified = $sth->execute (@{$params});
	croak "$exc:do\t$DBI::errstr\n$sql" if $DBI::errstr;
	
	$sth->finish;
	
	return $modified;
}

sub do_without_cache {
        my $self = shift;
	my %par  = @_;

        my $sql    = $par{sql};
	my $params = $par{params} ||= [];
	
	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		foreach my $p ( $par{sql}, @{$params} ) {
			utf8::upgrade($p);
		}
	}
	elsif ( not $self->{utf8} ) {
		foreach my $p ( $par{sql}, @{$params} ) {
			$p = Encode::encode("windows-1252", $p)
				if Encode::is_utf8($p);
		}
	}
	
        $self->{debug} && print STDERR "$exc:do: sql = $sql\n";
        $self->{debug} && print STDERR "$exc:do: params = ".
		join(",", @{$params}), "\n";

        my $modified = $self->{dbh}->do ($sql, undef, @{$params});
	
	croak "$exc:do\t$DBI::errstr\n$sql" if $DBI::errstr;
	
	return $modified;
}

# GET ----------------------------------------------------------------

sub get {
        my $self = shift;

 	my %par = @_;

        my $sql       = $par{sql};
	my $par_cache = $par{cache};
	my $params    = $par{params};

	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		foreach my $p ( $par{sql}, @{$params} ) {
			utf8::upgrade($p);
		}
	}
	
        my $dbh = $self->{dbh};

	# Normalerweise werden SQL Statements hier von DBI gecached.
	# Es gibt aber Befehle, bei denen das keinen Sinn macht.
	# Deshalb gibt es drei Mechanismen, die das Caching steuern:
	
	# 1. wenn keine SQL Parameter übergeben wurden, gehen wir davon
	#    aus, daß das Statement die Parameter enthält. In diesem
	#    Fall wollen wir das Statement nicht cachen.
	my $use_prepare_cached = defined $params;

	# 2. über den Parameter cache kann das Caching explizit
	#    gesteuert werden
	if ( exists $par{cache} ) {
		$use_prepare_cached = $par_cache;
	}

	# 3. wenn das Caching beim Erzeugen des Dimedis::Sql Instanz
	#    abgeschaltet wurde, gibt's kein Caching!
	
	$use_prepare_cached = 0 if not $self->{cache};

        $self->{debug} && print STDERR "$exc:get sql = $sql\n";

        my $sth;
	
	if ( $use_prepare_cached ) {
		$self->{debug} && print STDERR "$exc:get: statement is cached\n";
		$sth = $dbh->prepare_cached ($sql)
			or croak "$exc:get\t$DBI::errstr\n$sql";
	} else {
		$self->{debug} && print STDERR "$exc:get: statement is NOT cached\n";
		$sth = $dbh->prepare ($sql)
			or croak "$exc:get\t$DBI::errstr\n$sql";
	}

        $sth->execute (@{$params})
		or croak "$exc:get\t$DBI::errstr\n$sql";

        if ( wantarray ) {
		my $lref = $sth->fetchrow_arrayref;
		# ggf. UTF8 Flag setzen
		if ( $self->{utf8} and defined $lref ) {
			foreach my $p ( @{$lref} ) {
				Encode::_utf8_on($p);
			}
		}
                $sth->finish or croak "$exc:get\t$DBI::errstr\n$sql";
                return defined $lref ? @{$lref} : undef;
        } else {
                my $href = $sth->fetchrow_hashref;
                $sth->finish or croak "$exc:get\t$DBI::errstr\n$sql";
		return if not keys %{$href};
		my %lc_hash;
		map { Encode::_utf8_on($href->{$_}) if $self->{utf8};
		      $lc_hash{lc($_)} = $href->{$_} } keys %{$href};
                return \%lc_hash;
        }
}

# LEFT_OUTER_JOIN ----------------------------------------------------

sub left_outer_join {
        my $self = shift;

	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		_utf8_upgrade_lref (\@_);
	}
	
	return $self->db_left_outer_join (\@_);
}

sub _utf8_upgrade_lref {
	my ($lref) = @_;
	
	foreach my $p ( @{$lref} ) {
		if ( ref $p ) {
			_utf8_upgrade_lref($p);
		} else {
			utf8::upgrade($p);
		}
	}

	1;
}

# CMPI ---------------------------------------------------------------

sub cmpi {
        my $self = shift;
	
	my %par = @_;

	# Parametercheck
	
	croak "$exc:cmpi\tmissing col" unless defined $par{col};
	croak "$exc:cmpi\tmissing val" unless defined $par{val};
	croak "$exc:cmpi\tmissing op"  unless defined $par{op};

	croak "$exc:cmpi\tunknown op '$par{op}'"
		unless defined $known_operators{$par{op}};

	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		utf8::upgrade($par{col});
		utf8::upgrade($par{val});
	}
	
	return $self->db_cmpi (\%par);
}

# USE_DB -------------------------------------------------------------

sub use_db {
        my $self = shift;
	
	my %par = @_;

	# Parametercheck
	
	croak "$exc:cmpi\tmissing db" unless defined $par{db};
	
	return $self->db_use_db (\%par);
}

# DB_PREFIX ----------------------------------------------------------

sub db_prefix {
        my $self = shift;
	
	my %par = @_;

	# Parametercheck
	
	croak "$exc:cmpi\tmissing db" unless defined $par{db};
	
	return $self->db_db_prefix (\%par);
}

# INSTALL ------------------------------------------------------------

sub install {
	my $self = shift;
	
	my %par = @_;
	
	eval {
		$self->db_install (\%par);
	};
	croak "$exc:install\t$@" if $@;
	
	1;
}

# LEFT_OUTER_JOIN ----------------------------------------------------

sub contains {
        my $self = shift;
	
	my %par = @_;
	
	croak "$exc:contains\tmissing col"        unless defined $par{col};
	croak "$exc:contains\tmissing vals"       unless defined $par{vals};
	croak "$exc:contains\tmissing search_op"  unless defined $par{search_op};

	croak "$exc:contains\tunsupported search_op '$par{search_op}'"
		if $par{search_op} ne 'sub';

	croak "$exc:contains\tmissing logic_op (number of vals > 1)"
		if @{$par{vals}} > 1 and not defined $par{logic_op};

	croak "$exc:contains\tunknown logic_op ($par{logic_op})"
		if defined $par{logic_op} and $par{logic_op} !~ /^(and|or)$/;

	# ggf. UTF8 Konvertierung vornehmen
	if ( $self->{utf8} ) {
		foreach my $p ( @{$par{vals}} ) {
			utf8::upgrade($p);
		}
	}
	
	$self->db_contains (\%par);
}

# GET_FEATURES -------------------------------------------------------

sub get_features {
	my $self = shift;
	
	return $self->{db_features};
}

# HELPDER METHODS FOR DRIVERS ----------------------------------------

sub blob2memory {
	my $self = shift;
	my ($val, $col, $type, $layer) = @_;

	$layer ||= $self->{utf8} && $type eq 'clob' ? ":utf8" : ":raw";

	$self->{debug} && print STDERR "$exc:db_blob2memory col=$col type=$type layer=$layer\n";

	my $blob;
	if ( ref $val and ref $val ne 'SCALAR' ) {
		# Referenz und zwar keine Scalarreferenz
		# => das ist ein Filehandle
		# => reinlesen den Kram
		binmode $val, $layer;
		{ local $/ = undef; $blob = <$val> }

	} elsif ( not ref $val ) {
		# keine Referenz
		# => Dateiname
		# => reinlesen den Kram
		my $fh = new FileHandle;
		open ($fh, $val) or croak "can't open file '$val'";
		binmode $fh, $layer;
		{ local $/ = undef; $blob = <$fh> }
		close $fh;

	} else {
		# andernfalls ist val eine Skalarreferenz mit dem Blob
		# => nur ggf. upgraden
		utf8::upgrade($$val) if $layer eq ':utf8';
		return $val;
	}

	return \$blob;
}

1;

__END__

=head1 NAME

Dimedis::Sql - SQL/DBI Interface für datenbankunabhängige Applikationen

=head1 SYNOPSIS

  use Dimedis::Sql;

  # Konstruktor und Initialisierung
  my $sqlh = new Dimedis::Sql ( ... );
  $sqlh->install ( ... );

  # Ausführung elementarer Kommandos zur Datenein-/ausgabe
  my $seq_id = $sqlh->insert ( ... );
  my $modified = $sqlh->update ( ... );
  my $blob_sref = $sqlh->blob_read ( ... );

  # Handling mehrerer Datenbanken
  $sqlh->use_db ( ...)
  my $db_prefix = $sqlh->db_prefix ( ...)

  # direkte Ausführung von SQL Statements
  my $modified = $sqlh->do ( ... );
  my $href = $sqlh->get ( ... );
  my @row  = $sqlh->get ( ... );

  # Generierung von datenbankspezifischem SQL Code
  my ($from, $where) = $sqlh->outer_join ( ... );
  my $cond = $sqlh->cmpi ( ... );
  my $where = $sqlh->contains ( ... );

  # Kompatibilitätsprüfung
  my $feature_href = $sqlh->get_features;

=head1 DESCRIPTION

Dieses Modul erleichtert die Realisierung datenbankunabhängiger
Applikationen. Die Schnittstelle gliedert sich in drei Kategorien:

=over 4

=item B<Ausführung elementarer Kommandos zur Datenein-/ausgabe>

Diese Methoden führen anhand vorgegebener Parameter intern generierte
SQL Statements direkt über das DBI Modul aus. Die Parameter sind dabei
so abstrakt gehalten, daß sie von jeglicher Datenbankarchitektur
unabhängig sind.

=for html
<P>

=item B<direkte Ausführung von SQL Statements>

Die Methoden dieser Kategorie führen SQL Statements ohne weitere
Manipulation direkt über das DBI Modul aus. Diese Statements müssen
also von ihrer Art her bereits unabhängig von jeglicher verwendeten
Datenbankarchitektur sein.

=for html
<P>

=item B<Generierung von datenbankspezifischen SQL Code>

Diese Methoden führen keine Statements aus sondern generieren anhand
gegebener Parameter den SQL Code für eine bestimmte Datenbankplattform
und geben diesen zurück, so daß er mit den Methoden der ersten beiden
Kategorien weiterverarbeitet werden kann.

=back

=head1 VORAUSSETZUNGEN

Es gibt einige Voraussetzungen für erfolgreiche datenbankunabhängige
Programmierung mit diesem Modul.

=over 4

=item B<Verwendung datenbankspezifischer Datentypen>

Es dürfen keine datenbankspezifischen Datentypen verwendet werden,
die nicht von diesem Modul erfaßt sind.

Besonderheiten der unterschiedlichen Datenbankplattformen und wie
Dimedis::Sql damit umgeht, können der Dokumentation des entsprechenden
Datenbanktreibers (Dimedis::SqlDriver::*) entnommen werden.

=for html
<P>

=item B<Konvention für das Datum Format>

Die von der Datenbank gegebenen Typen für die Speicherung von Zeit- und
Datum Werten dürfen nicht verwendet werden. Stattdessen muß ein
String von folgendem Format verwendet werden:

B<YYYYMMDDHH:MM:SS>

=for html
<P>

=item B<Grundsätzliche Kenntnisse im Umgang mit DBI>

Dieses Modul bildet alle Operationen direkt auf die darunter liegende
DBI Schnittselle ab. Deshalb werden Grundkenntnisse der DBI Programmierung
vorausgesetzt, z.B. die Technik des Parameter Bindings. Bei Problemen
kann die manpage des DBI Moduls (perldoc DBI) u.U. weiterhelfen.

=back

=head1 VERWENDUNG VON FILEHANDLES UNTER WINDOWS

Bei der Verwendung des Moduls unter Windows ist folgendes grundsätzlich
zu beachten: beim Umgang mit Binärdateien unter Windows ist es erforderlich,
daß sämtlicher File I/O im 'binmode' durchführt wird, d.h. die
für die entsprechenden Filehandles muß die Perl Funktion binmode
aufgerufen werden.

Dimedis::Sql ruft grundsätzlich für B<alle> Filehandles binmode auf,
auch wenn diese vom Benutzer übergeben wurden. Dies stellt kein
Problem dar, wenn in vom Benutzer übergebene Filehandles noch nichts
geschrieben bzw. gelesen wurde.

Wenn Filehandles übergeben werden, die bereits für I/O verwendet wurden,
führt dies zu undefinierten Zuständen, wenn diese nicht bereits vorher
mit binmode behandelt wurden. Deshalb müssen Filehandles, die vor der
Übergabe an Dimedis::Sql bereits verwendet werden sollen,  B<unbedingt>
sofort nach dem Öffnen mit binmode in den Binärmodus versetzt werden.

=head1 FEHLERBEHANDLUNG

Alle Methoden erzeugen im Fehlerfall eine Exception mit der Perl B<croak>
Funktion. Die Fehlermeldung hat folgenden Aufbau:

  "$method\t$message"

Dabei enthält $method den vollständigen Methodennamen und
$message eine detailliertere Fehlermeldung (z.B. $DBI::errstr, wenn
es sich um einen SQL Fehler handelt).

=head1 CACHING VON SQL BEFEHLEN

DBI bietet ein Feature an, mit dem einmal ausgeführte SQL Statements
intern gecached werden. Bei einem gecachten Statement entfällt der
Aufwand für das 'prepare'. Dies kann (insbesondere im Kontext persistenter
Perl Umgebungen) erhebliche Performancevorteile bringen, allerdings
auf Kosten des Speicherverbrauchs.

Grundsätzlich benutzt Dimedis::Sql wo möglich dieses Caching Feature. Es
gibt aber Gründe, es nicht zu verwenden. Wenn es nicht möglich ist, alle
Parameter eines Statements mit Parameter Binding zu übergeben, sollte das
resultierende Statement B<nicht> gecached werden. Der eingebettete Parameter
würde mit gecached werden. Die Wahrscheinlichkeit aber, daß dieses Statement
genau B<so> noch einmal abgesetzt wird, ist extrem gering. Dafür wird aber
viel Speicher verbraucht, weil das gecachte Statement bis zur Prozeßbeendung
im Speicher verbleibt. Zudem gibt es bei den verschiedenen Datenbanken
eine Begrenzung der gleichzeitig offenen Statement-Handles.

Bei einigen Methoden und beim Konstruktor gibt es deshalb einen B<cache>
Parameter, um die Verwendung des Caches zu steuern.

Der B<cache> Parameter gibt an, das DBI Statement Caching verwendet werden soll,
oder nicht. In der Regel erkennt Dimedis::Sql selbständig, ob das
Statement cachebar ist oder nicht: wenn keine B<params> zwecks Parameter
Binding übergeben wurden, so wird das Statement nicht gecached, weil davon
ausgegangen wird, daß entsprechende Parameter im SQL Befehlstext direkt
eingebettet sind, was ein Caching des SQL Befehls sinnlos macht. Andernfalls
cached Dimedis::Sql das Statement immer.

Über den B<cache> Parameter kann der Anwender das Verhalten selbst steuern.
Falls cache => 0 beim Erzeugen der Dimedis::Sql Instanz angegeben wurde,
ist das Caching B<immer> abgeschaltet, unabhängig von den oben beschriebenen
Bedingungen. B<ACHTUNG>: derzeit unterstützen nicht alle Dimedis::SqlDriver
dieses Feature (sowohl das globale Abschalten des Caches, als
auch das Einstellen pro Methodenaufruf). $sqlh->get_features gibt hierüber
Auskunft. Wenn der B<cache> Parameter nicht unterstützt wird, so ist nicht
definiert, ob mit oder ohne Cache gearbeitet wird.

=head1 UNICODE SUPPORT

Unter Perl 5.8.0 unterstützt Dimedis::Sql auch Unicode. Beim Konstruktor
muß dazu das utf8 Attribut gesetzt werden. Dimedis::Sql konvertiert damit
alle Daten (außer Blobs) ggf. in das UTF8 Format, wenn die Daten nicht bereits
in UTF8 vorliegen.

Alle gelesenen Daten erhalten das Perl eigene UTF8 Flag gesetzt, d.h. es
wird vorausgesetzt, daß alle in der Datenbank gespeicherten Daten auch im
UTF8 Format vorliegen. Solange Dimedis::Sql stets im UTF8 Modus betrieben,
ist das auch gewährleistet. Eine Mischung von UTF8- und nicht-UTF8-Daten
ist nicht möglich und führt zu fehlerhaft codierten Daten.

Der UTF8 Support ist datenbankabhängig (derzeit unterstützt von MySQL
und Oracle). Das B<get_features> Hash hat einen Eintrag B<utf8>, der
angibt, ob die Datenbank UTF8 unterstützt, oder nicht.

=head1 BEHANDLUNG VON LEER-STRINGS / NULL SPALTEN

Leer-Strings werden von den Datenbanksystemen unterschiedlich behandelt.
Einige konvertieren sie stets zu NULL Spalten, andere können zwischen
NULL und Leer-String korrekt unterscheiden.

Zur Erfüllung eines minimalen Konsens werden alle Leerstrings von den
Dimedis::Sql Methoden zu undef bzw. NULL konvertiert, so daß es
grundsätzlich keine Leerstrings gibt, sondern nur NULL Spalten bzw.
undef Werte (NULL wird in DBI durch undef repräsentiert).

=head1 METHODEN

=head2 KONSTRUKTOR

  my $sqlh = new Dimedis::Sql (
  	dbh          => $dbh
     [, debug        => {0 | 1} ]
     [, cache        => {0 | 1} ]
     [, serial_write => {0 | 1} ]
     [, utf8         => {0 | 1] ]
  );

Der Konstruktor erkennt anhand des übergebenen DBI Handles die
Datenbankarchitektur und lädt das entsprechende Dimedis::SqlDriver
Modul für diese Datenbank, welches die übrigen Methoden implementiert.

Wenn der B<debug> Parameter gesetzt ist, werden Debugging Informationen
auf STDERR geschrieben. Es gibt keine Unterscheidung in unterschiedliche
Debugging Levels. Generell werden alle ausgeführten SQL Statements
ausgegeben sowie zusätzliche spezifische Debugging Informationen, je
nach verwendeter Funktion.

Über den B<cache> Parameter kann das DBI Caching von prepared Statements
gesteuert werden. Wenn hier 0 übergeben wird, werden Statements grundsätzlich
nie gecached (auch wenn bei einigen Statements lokal explizit cache => 1
gesetzt wurde. So kann das Caching bei Problemen sehr leich an zentraler
Stelle abgeschaltet werden. Default ist eingeschaltetes Caching.

Der B<serial_write> Parameter gibt an, ob explizite Werte für serial
Spalten angegeben werden dürfen. Per Default ist dies verboten.

Der B<utf8> Parameter schaltet das Dimedis::Sql Handle in den UTF8 Modus.
Siehe das Kapitel UNICODE SUPPORT.

=head2 EINSCHRÄNKUNGEN

Parameter für eine like Suche können nicht via Parameter Binding
übergeben werden (zumindest Sybase unterstützt dies nicht).

=head2 ÖFFENTLICHE ATTRIBUTE

Es gibt einige Attribute des $sqlh Handles, die direkt verwendet
werden können:

=over 4

=item $sqlh->{dbh}

Dies ist das DBI database handle, das dem Konstruktor übergeben
wurde. Es darf read only verwendet werden.

=for html
<P>

=item $sqlh->{debug}

Das Debugging-Verhalten kann jederzeit durch direktes Setzen
auf true oder false kontrolliert werden.

=for html
<P>

=item $sqlh->{db_type}

Dieses Read-Only Attribut enthält den verwendeten Datenbanktreiber.
Hier sind derzeit folgende Werte möglich:

  Oracle
  Informix
  Sybase

=item $sqlh->{serial_write}

Der B<serial_write> Parameter gibt an, ob explizite Werte für serial
Spalten angegeben werden dürfen. Per Default ist dies verboten.

=item $sqlh->{utf8}

Das B<utf8> Attribut gibt an, ob das Dimedis::Sql Handle im UTF8
Modus ist, oder nicht. Das Attribut ist read-only. Eine Datenbank
kann nur als ganzes in UTF8 betrieben werden, oder gar nicht. Ein
Mischbetrieb mit anderen Zeichensätzen ist nicht möglich.

=back 4

=head2 INITIALISIERUNG

  $sqlh->install

Diese Methode muß nur einmal bei der Installation der Applikation
aufgerufen werden. Sie erstellt in der Datenbank Objekte, die von dem
entsprechenden datenbankabhängigen SqlDriver benötigt werden.

Es ist möglich, daß ein SqlDriver keine Objekte in der Datenbank
benötigt, dann ist seine install Methode leer. Trotzdem muß diese
Methode B<immer> bei der Installation der Applikation einmal
aufgerufen werden.

=head2 DATEN EINFÜGEN

  my $seq_id = $sqlh->insert (
  	table	=> "table_name",
	data	=> {
		col_j => $val_j,
		...
	},
	type	=> {
		col_i => 'serial',
		col_j => 'date',
		col_k => 'clob',
		col_l => 'blob',
		...
	}
  );

Die insert Methode fügt einen Datensatz in die angegebene Tabelle
ein. Der Rückgabewert ist dabei eine evtl. beim Insert generierte
Primary Key ID.

Die einzelnen Werte der Spalten werden in dem B<data> Hash übergeben.
Dabei entsprechen die Schlüssel des Hashs den Spaltennamen der
Tabelle, deren Namen mit dem B<type> Parameter übergeben wird. SQL
B<NULL> Werte werden mit dem Perl Wert B<undef> abgebildet.

Das B<type> Hash typisiert alle Spalten, die keine String oder Number
Spalten sind. Hier sind folgende Werte erlaubt:

=over 4

=item serial

Diese Spalte ist ein numerischer Primary Key der Tabelle, deren
Wert bei Bedarf automatisch vergeben word.

Der serial Datentyp darf nur einmal pro Insert vorkommen.

Um eine serial Spalte mit den automatisch generierten Wert zu setzen,
muß im data Hash hierfür undef übergeben werden. Wenn eine serial
Spalte auf einen fixen Wert gesetzt werden soll, so muß im data
Hash der entsprechende Wert übergeben werden.

B<Beispiel:>

  my $id = $sqlh->insert (
  	table => 'users',
	data => {
		id => undef,
		nickname => 'foo'
	},
	type => {
		id => 'serial'
	}
  );

In diesem Beispiel wird ein Datensatz in die Tabelle 'users' eingefügt,
die eine serial Spalte enthält. Die Spalte 'nickname' wird im B<type>
Hash nicht erwähnt, da es sich hierbei um eine CHAR Spalte handelt.

=for html
<P>

=item date

Diese Spalte ist vom Typ Datum. Dimedis::Sql nimmt bei Werten dieses
Typs eine Prüfung auf syntaktische Korrektheit vor. Es wird B<nicht>
geprüft, ob es sich dabei um ein B<gültiges> Datum handelt, sondern
lediglich, ob das Zahlenformat eingehalten wurde.

=for html
<P>

=item clob blob

Es gibt zwei Möglichkeiten einen BLOB oder CLOB einzufügen. Wenn das Objekt
im Speicher vorliegt, wird eine Scalar-Referenz im data Hash erwartet. Wenn
ein Skalar übergeben wird, wird dieses als vollständiger
Dateiname interpretiert und die entsprechende Datei in die Datenbank
eingefügt. Die Datei wird dabei nicht gelöscht, sondern bleibt erhalten.

B<Zusätzlich gilt folgende Einschränkung für BLOBs:>

  - die Verarbeitung von BLOBS ist nur möglich, wenn
    eine serial Spalte mit angegeben ist

B<Beispiel:>

Hier wird ein Blob aus einer Datei heraus eingefügt:

  my $id = $sqlh->insert (
  	table => 'users',
	data => {
		id => undef,
		nickname => 'foo',
		photo => '/tmp/uploadfile'
	},
	type => {
		id => 'serial',
		photo => 'blob'
	}
  );

Hier wird dieselbe Datei eingefügt, nur diesmal wird sie
vorher in den Speicher eingelesen, und dann aus dem Speicher
heraus in die Datenbank eingefügt (Übergabe als Skalarreferenz):

  open (FILE, '/tmp/uploadfile')
    or die "can't open /tmp/uploadfile';
  binmode FILE;
  my $image;
  { local $/ = undef; $image = <FILE> };
  close FILE;

  my $id = $sqlh->insert (
  	table => 'users',
	data => {
		id => undef,
		nickname => 'foo',
		photo => \$image
	},
	type => {
		id => 'serial',
		photo => 'blob'
	}
  );

=back 4

=head2 DATEN UPDATEN

  my $modified = $sqlh->update (
  	table	=> "table_name",
	data	=> {
		col_j => $val_j,
		...
	},
	type	=> {
		col_j => 'date',
		col_k => 'clob',
		col_l => 'blob',
		...
	},
	where	=> "where clause"
     [, params  => [ $where_par_n, ... ] ]
     [, cache   => 1|0 ]
  );

Die update Methode führt ein Update auf der angegebenen Tabelle durch.
Dabei werden Tabellenname, Daten und Typinformationen wie bei der
insert Methode übergeben. Zusätzlich wird mit dem B<where> Parameter
die WHERE Klausel für das Update angegeben, wobei optional mit
dem params Parameter Platzhalter Variablen für die where Klausel
übergeben werden können. Das Wort 'where' darf in dem B<where> Parameter
nicht enthalten sein.

Der Rückgabewert ist die Anzahl der von dem UPDATE veränderten Datensätze.
Wenn B<nur> BLOB Spalten upgedated werden, ist der Rückgabewert nicht
spezifiziert und kann je nach verwendeter Datenbankarchitektur variieren.

Der B<cache> Parameter wird im Kapitel B<CACHING VON SQL BEFEHLEN>
beschrieben.

Zusätzlich zu den Einschränkungen der insert Methode muß noch
folgendes beachtet werden:

=over 4

=item Serial Spalte

Serial Spalten können B<nicht> verändert werden und dürfen demzufolge
nicht an einem Update beteiligt sein.

=for html
<P>

=item BLOB Update

Zum Updaten eines BLOBs bedarf es demzufolge der serial Spalte nicht.
Dafür B<muß> die B<where> Bedingung aber eindeutig sein, d.h. sie
darf nur einen Datensatz liefern. Ein Update mehrerer Blobs muß also
durch mehrere Aufrufe der update Methode gelöst werden.

Diese Einschränkung wird u.U. in Zukunft aufgehoben.

=back 4

B<Beispiel:>

In diesem Beispiel wird eine Blob Spalte upgedated, aus einer Datei
heraus. Der B<where> Parameter selektiert genau eine Zeile über
die B<id> Spalte der Tabelle. Der Wert der Spalte wird über Parameter
Binding übergeben.

  $sqlh->update (
  	table => 'users',
	data => {
		photo => '/tmp/uploadfile'
	},
	type => {
		photo => 'blob'
	},
	where => 'id = ?',
	params => [ $id ]
  );

=head2 BLOBS LESEN

  my $blob_sref = $sqlh->blob_read (
  	table	 => "table_name",
	col	 => "blob_column_name",
	where	 => "where clause"
     [, params   => [ $par_j, ... ]          ]
     [, filename => "absolute_path"          ]
     [, filehandle => "filehandle reference" ]
  );

Mit der B<blob_read> Methode wird ein einzelner Blob (oder Clob) gelesen
und als Skalarreferenz zurückgegeben. Dabei werden Tabellennamen, Spaltenname
sowie die WHERE Klausel zum Selektieren der richtigen Zeile als Parameter
übergeben.

Wenn der optionale Parameter filename gegeben ist, wird der Blob
nicht als Skalarreferenz zurückgegeben, sondern stattdessen in die
entsprechende Datei geschrieben und undef zurückgegeben.

Wenn filehandle angegeben ist, wird das Blob in diese Filehandle Referenz
geschrieben und undef zurückgegeben. Die mit dem Filehandle verbundene
Datei wird B<nicht> geschlossen.

filehandle und filename dürfen nicht gleichzeitig angegeben werden.

B<Beispiel:>

In diesem Beispiel wird ein Blob in eine Variable eingelesen:

  my $blob_sref = $sqlh->blob_read (
  	table	 => "users",
	col	 => "photo",
	where	 => "id=?",
        params   => [$id],
  );

Dasselbe Blob wird nun auf STDOUT ausgegeben, beispielsweise um
ein GIF Bild an einen Browser auszuliefern (binmode für die Win32
Kompatibilität nicht vergessen!):

  binmode STDOUT;
  print "Content-type: image/gif\n\n";
  
  $sqlh->blob_read (
  	table	 => "users",
	col	 => "photo",
	where	 => "id=?",
        params   => [$id],
	filehandle => \*STDOUT
  );

=head2 SQL BEFEHLE ABSETZEN

  my $modified = $sqlh->do (
  	sql	=> "SQL Statement",
     [, params	=> [ $par_j, ... ] ]
     [, cache   => 0|1 ]
  );

Mit der do Methode wird ein vollständiges SQL Statement ausgeführt, d.h.
ohne weitere Bearbeitung an DBI durchgereicht. Optionale Platzhalter
Parameter des SQL Statements werden dabei mit dem B<params> Parameter übergeben.

Der B<cache> Parameter wird im Kapitel B<CACHING VON SQL BEFEHLEN>
beschrieben.

Der Rückgabewert ist die Anzahl der von dem UPDATE veränderten Datensätze.

=head2 DATEN LESEN

  my $href =
  my @row  = $sqlh->get (
  	sql	=> "SQL Statement",
     [, params	=> [ $par_j, ... ] ]
     [, cache   => 0|1 ]
  );

Die get Methode ermöglicht das einfache Auslesen einer Datenbankzeile
mittels eines vollständigen SELECT Statements, d.h. das SQL Statement wird
ohne weitere Bearbeitung an DBI durchgereicht. Optionale Platzhalter
Parameter werden dabei mit dem params Parameter übergeben.

Im Scalar-Kontext aufgerufen, wird eine Hashreferenz mit Spalte => Wert
zurückgegeben. Im Listen-Kontext wird die Zeile als Liste zurückgegeben.

Wenn das SELECT Statement mehr als eine Zeile liefert, wird nur die erste
Zeile zurückgeliefert und die restlichen verworfen. Eine Verarbeitung
von Ergebnismengen kann also mit der get Methode nicht durchgeführt werden.

Der B<cache> Parameter wird im Kapitel B<CACHING VON SQL BEFEHLEN>
beschrieben.

=head2 LEFT OUTER JOIN

  my ($from, $where) = $sqlh->left_outer_join (
	komplexe, teilweise verschachtelte Liste,
	Beschreibung siehe unten
  );

Diese Methode liefert gültige Inhalte von FROM und WHERE Klauseln zurück
(ohne die Schlüsselwörte 'FROM' und 'WHERE'), die für die jeweilige
Datenbankplattform einen Left Outer Join realisieren. Für die WHERE
Klausel wird B<immer> eine gültige Bedingung zurückgeliefert, sie kann
also gefahrlos mit "... AND $where" in ein SELECT Statement eingebunden
werden, ohne abzufragen, ob sich der Outer Join überhaupt in der WHERE
Condition auswirkt.

Es wird eine Liste von Parametern erwartet, die einem der folgenden Schemata
genügen muß (es werden zwei Fälle von Joins unterschieden). Unter
der Parameterzeile ist zum besseren Verständnis jeweils die Umsetzung
für Informix und Oracle angedeutet.

(Es gibt noch einen weiteren Outer Join Fall, der von Dimedis::Sql aber
nicht unterstützt wird, da nicht alle Datenbankplattformen diesen
umsetzen können. Dabei handelt es sich um einen Simple Join, der als
gesamtes gegen die linke Tabelle left outer gejoined werden soll.)

=over 4

=item Fall I: eine odere mehrere Tab. gegen dieselbe linke Tab. joinen

Dieser Fall wird auch 'simple outer join' genannt.

  ("tableA A", ["tableB B"], "A.x = B.x" )
  
  Ifx:      A, outer B
  Ora:      A.x = B.x (+)

  Dies war ein Spezialfall des folgenden, es können also
  beliebig viele Tabellen jeweils mit A outer gejoined
  werden:

  ("tableA A", ["tableB B"], "A.x = B.x",
               ["tableC C"], "A.y = C.y",
               ["tableD D"], "A.z = D.z", ... )

  Ifx:      A, outer B, outer C
  Ora:      A.x = B.x (+) and A.y = C.y (+) and A.z = D.z (+) ...

=item Fall II: verschachtelter outer join

Dieser Fall wird auch 'nested outer join' genannt.

  ("tableA A",
   [ "tableB B", [ "tableC C" ], "B.y = C.y AND expr(c)" ],
   "A.x = B.x")

  Ifx:      A, outer (B, outer C)
  Ora:      A.x = B.x (+) and B.y = C.y (+)
            and expr(c (+) )

=item Beschreibung der Parameterübergabe

Generell muß die übergebene Parameterliste den folgenden Regeln
genügen:

  - die Angabe einer Tabelle erfolgt nach dem Schema

    "Tabelle[ Alias]"

    Alle Spaltenbezeichner in den Bedinungen müssen den Alias
    verwenden (bzw. den Tabellennamen, wenn der Alias
    weggelassen wurde).

  - zu einem Left Outer Join gehören immer drei Bestandteile:

    1. linke Tabelle (deren Inhalt vollständig bleibt)
    2. rechte Tabelle (in der fehlende Eintrage mit NULL
       gefüllt werden)
    3. Join Bedingung

    Die Parameterliste nimmt sie in genau dieser Reihenfolge
    auf, wobei die jeweils rechte Tabelle eines Outer Joins
    in eckigen Klammern steht:
    
    LeftTable, [ OuterRightTable ], Condition

    Dabei können im Fall I OuterRightTable und Condition
    beliebig oft auftreten, um die outer Joins dieser Tabellen
    gegen die LeftTable zu formulieren.
    
    Im Fall II erfolgt die Verschachtelung nach demselben
    Schema. Die OuterRightTable wird in diesem Fall zur
    LeftTable für den inneren Outer Join.

  - wenn zusätzliche Spaltenbedingungen für eine rechte
    Tabelle gelten sollen, so müssen diese an die Outer
    Join Bedingung angehängt werden, in der die Tabelle
    auch tatsächlich die rechte Tabelle darstellt.
    
    Im Fall II z.B. könnten sie theoretisch auch bei der
    Bedingung eines inneren Joins angegeben werden, das
    darf aber nicht geschehen, da die Tabelle im inneren
    Join als LeftTable fungiert. Dies führt dann je nach
    Datenbankplattform nicht zu dem gewünschten Resultat.
    
    Falsch:
    "A", ["B", ["C"], "B.y = C.y and B.foo=42"], "A.x = B.x"
    
    Richtig:
    "A", ["B", ["C"], "B.y = C.y"], "A.x = B.x and B.foo=42"

=back 4

=head2 CASE INSENSITIVE VERGLEICHE

  my $cond = $sqlh->cmpi (
  	col	=> "column_name",
	val	=> "column value (with wildcards)",
	op	=> 'like' | '=' | '!='
  );

Die cmpi Methode gibt eine SQL Bedingung zurück, die case insensitive ist.
Dabei gibt col den Namen der Spalte an und val den Wert der Spalte (evtl.
mit den SQL Wildcards % und ?, wenn der Operator like verwendet wird).
Der Wert muß ein einfaches B<String Literal> sein, ohne umschließende
Anführungszeichen. Andere Ausdrücke sind nicht erlaubt.

Der op Parameter gibt den Vergleichsoperator an, der verwendet werden soll.

Die cmpi Methode berücksichtigt eine mit setlocale() eingestellte Locale.

=head2 VOLLTEXTSUCHE

  my $cond = $sqlh->contains (
  	col	  => "column name",
	vals	  => [ "val1", ..., "valN" ],
      [ logic_op  => 'and' | 'or', ]
	search_op => 'sub'
  );

Die contains Methode generiert eine SQL Bedingung, die eine Volltextsuche
realisiert. Hierbei werden entsprechende datenbankspezifischen Erweiterungen
genutzt, die eine effeziente Volltextsuche ermöglichen (Oracle Context
Cartridge, Informix Excalibur Text Datablade).

col gibt die Spalte an, über die gesucht werden soll. vals zeigt auf die
Zeichenkette(n), nach der/denen gesucht werden soll (ohne Wildcards). Wenn
mit vals mehrere Werte übergeben werden, muß auch logic_op gesetzt sein,
welches bestimmt, ob die Suche mit 'and' oder 'or' verknüpft werden soll.

Mit search_op können unterschiedliche Varianten der Volltextsuche spezifiert
werden. Z.Zt. kann hier nur 'sub' angegeben werden, um anzuzeigen, daß eine
Teilwortsuche durchgeführt werden soll.

Wenn eine Datenbank keine Volltextsuche umsetzen kann, wird undef
zurückgegeben.

=head2 DATENBANK WECHSELN

 $sqlh->use_db (
  	db	=> "database_name"
  );

Diese Methode wechselt auf der aktuellen Datenbankconnection zu
einer anderen Datenbank. Der Name der Datenbank wird mit dem
B<db> Parameter übergeben.

=head2 DATENBANK TABELLEN PREFIX ERMITTELN

 $sqlh->db_prefix (
  	db	=> "database_name"
  );

Diese Methode liefert den Datenbanknamen zusammen mit dem
datenbankspezifischen Tabellen-Delimiter zurück. Der zurückgegebene
Wert kann direkt in einem SQL Statement zur vollständigen
Qualifikation einer Tabelle verwendet werden, die in einer anderen
Datenbank liegt.

Beispiel:

  my $db_prefix = $sqlh->db_prefix ( db => 'test' );
  $sqlh->do (
    sqlh => 'update ${db_prefix}foo set bla=42'
  );

  Hier wird die Tabelle 'foo' in der Datenbank 'test'
  upgedated.


=head2 UNTERSTÜTZTE FEATURES

  my $feature_href = $sqlh->get_features;

Diese Methode gibt eine Hashreferenz zurück, die folgenden Aufbau
hat und beschreibt, welche Dimedis::Sql Features von der aktuell
verwendeten Datenbankarchitektur unterstützt werden:

  $feature_href = {
	serial 		=> 1|0,
	blob_read	=> 1|0,
	blob_write 	=> 1|0,
	left_outer_join => {
	    simple 	=> 1|0,
	    nested 	=> 1|0
	},
  	cmpi 		=> 1|0,
	contains 	=> 1|0,
	use_db 		=> 1|0,
	cache_control 	=> 1|0,
	utf8		=> 1|0,
  };

Sollten dem $feature_href Schlüssel fehlen, so ist das
gleichbedeutend mit einem Setzen auf 0, d.h. das entsprechende
Feature wird nicht unterstützt.

'cache_control' meint die Möglichkeit, bei $sqlh->insert und
$sqlg->update mit dem Parameter 'cache' zu steuern, ob intern
mit Statement Caching gearbeitet werden soll, oder nicht.

=head1 AUTOR

Joern Reder, joern@dimedis.de

=head1 COPYRIGHT

Copyright (c) 1999 dimedis GmbH, All Rights Reserved

=head1 SEE ALSO

perl(1), Dimedis::SqlDriver::Oracle(3pm), Dimedis::SqlDriver::Informix(3pm)

=cut
