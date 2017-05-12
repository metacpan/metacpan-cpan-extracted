package Dimedis::Sql::Import;

use strict;
use vars qw($VERSION);
use Carp;

use Dimedis::Sql;
use Dimedis::Sql::CSV;
use Data::Dumper;
use FileHandle;
use File::Path;

$VERSION = '0.22';

##------------------------------------------------------------------------------
# CLASS
#   Dimedis::Sql::Import
#
# PURPOSE
#   Diese Klasse ermöglicht einen Import von Daten aus einem bestimmten
#   Export-Verzeichnis im Filesystem in ein bestehendes Datenbank-Schema
#   (Oracle, MySQL oder mSQL).
#   <p>
#   Es werden alle Daten aus dem angegebenen Export-Verzeichnis importiert,
#   für die es einen Eintrag im übergebenen Type-Hash gibt.
#   <p>
#   Das Export-Verzeichnis enthält für jede exportierte Tabelle ein
#   Unterverzeichnis mit dem Namen der entsprechenden Tabelle.
#   Dort sind die zugehörigen Daten abgelegt:
#   <ul>
#     <li>Die Datei <b>format.conf</b> enthält Informationen (Spaltenname, Typ
#         und Länge) zu den zugehörigen Tabellen-Spalten.<br>
#     <li>Die eigentlichen Daten sind in der CSV-Datei <b>data.dump</b>
#         abgelegt, wobei die einzelnen Spalten durch Tabs voneinander getrennt
#         sind. Enthält eine Tabelle BLOB- oder CLOB-Spalten, sind die
#         Inhalte dieser Spalten in separaten Dateien (<b>blob_1.bin -
#         blob_n.bin</b>) gespeichert. In der CSV-Datei ist dann für diese
#         Spalten nur der Name der zugehörigen Datei abgelegt.
#   </ul>
#   <p>
#   Die Start- und Endzeit des Imports, sowie die übergebenen Parameter
#   und die Statusmeldungen, die während des Imports ausgegeben werden,
#   werden in eine Meta-Datei im Export-Verzeichnis geschrieben.<br>
#   Für jeden Import wird eine neue Meta-Datei mit dem Namen
#   "import_<code>time()</code>.meta" erzeugt.
#   <p>
#   Über den optionalen Config-Parameter <code>inserts_per_transaction</code>
#   kann angegeben werden, nach wievielen DB-Inserts jeweils ein Commit
#   erfolgen soll.
#   (Beispiel: <code>inserts_per_transaction => 1</code> gibt an, dass nach
#   jedem eingefügten Datensatz committed wird).<br>
#   Wird der <code>inserts_per_transaction</code>-Parameter nicht angegeben,
#   erfolgt jeweils ein Commit pro Tabelle. 
#   <p>
#   Beispiel-Aufruf:
#   <pre>
#   |   my $import = Dimedis::Sql::Import->new(
#   |       dbh        => $dbh,
#   |       config     => {
#   |                      data_source    => 'dbi:Oracle:',
#   |                      username       => 'test',
#   |                      directory      => '/tmp/export',
#   |                      type_hash_file => './prod/config/lib.install.sql.general.all_tables.config',
#   |                     #inserts_per_transaction => 1
#   |                     },
#   |   );
#   |
#   |   $import->do_import();
#   </pre>
#
# AUTHOR
#   Sabine Tonn <stonn@dimedis.de>
#
# COPYRIGHT
#   dimedis GmbH, Cologne, Germany
#-------------------------------------------------------------------------------


##------------------------------------------------------------------------------
# METHOD
#   public constructor: new
#
# DESCRIPTION
#   Erzeugt ein neues Import-Objekt
#
# INPUT
#   dbh       -- DB-Handle
#   config      -- Config-Hash
#                    <ul>
#                      <li><b>Key:</b>   <code>data_source</code>
#                      <li><b>Value:</b> Data-Source der Zieldatenbank, in die
#                                        die Daten importiert werden
#                      <br><br>
#                      <li><b>Key:</b>   <code>username</code>
#                      <li><b>Value:</b> Schema-Name der Zieldatenbank, in die
#                                        die Daten importiert werden
#                      <br><br>
#                      <li><b>Key:</b>   <code>directory</code>
#                      <li><b>Value:</b> kompletter Pfad des Verzeichnisses,
#                                        aus dem die zu importierenden Daten
#                                        gelesen werden
#                      <br><br>
#                      <li><b>Key</b>:   <code>type_hash_file</code>
#                      <li><b>Value</b>: kompletter Pfad der Datei, in der das
#                                        Type-Hash abgelegt ist
#                      <br><br>
#                      Optional:<br>
#                      <li><b>Key</b>:   <code>inserts_per_transaction</code>
#                      <li><b>Value</b>: Anzahl der DB-Inserts, nach denen
#                                        jeweils ein Commit gemacht werden soll
#                                        (Default: ein Commit pro Tabelle)
#                    </ul> 
#
# OUTPUT
#   quiet_mode    -- 1 = keine Status-Meldungen zur Laufzeit auf der
#                    Standardausgabe anzeigen
#                    (Default = 0)
#
# RETURN
#   neues Import-Objekt
#-------------------------------------------------------------------------------
sub new {

  my $class = shift;
  my %par   = @_;

  #--- Parameterprüfung
  my $dbh      = $par{dbh}    or croak("'dbh' missing");
  my $config   = $par{config} or croak("'config' missing");

  croak "'data_source' missing"     unless $config->{data_source};
  croak "'username' missing"        unless $config->{username};
  croak "'directory' missing"       unless $config->{directory};
  croak "'type_hash_file' missing"  unless $config->{type_hash_file};

  my $quiet_mode = $par{quiet_mode};

  #--- Type-Hash einlesen
  my $fh = FileHandle->new();
  open( $fh, $config->{type_hash_file} ) or die "Can't open file: $!\n";

  my $data          = join ("", <$fh>);
  my $type_hash_ref = eval ($data);

  close( $fh );
  
  #--- neuen Filehandle für die Meta-Datei erzeugen
  my $fh_meta = FileHandle->new();
  
  open( $fh_meta, "> $config->{directory}/import_".time().".meta" )
    or die "Can't open file: $!\n";

  #------

  my ($from_charset, $to_charset) = $config->{recode} =~ /(.*?)\.\.(.*)/;
  
  $from_charset ||= "latin1";
  $to_charset   ||= "latin1";

  die "Invalid from_charset '$from_charset'"
  	unless $from_charset eq 'utf8' or $from_charset eq 'latin1';
  die "Invalid to_charset '$to_charset'"
  	unless $to_charset eq 'utf8' or $to_charset eq 'latin1';
  die "Recoding utf8..latin1 currently not supported"
  	if $from_charset eq 'utf8' and $to_charset eq 'latin1';

  my $self = {
      dbh                       => $dbh,
      data_source               => $config->{data_source},
      username                  => $config->{username},
      dir                       => $config->{directory},
      type_hash_file            => $config->{type_hash_file},
      inserts_per_transaction   => $config->{inserts_per_transaction},
      from_charset	        => $from_charset,
      to_charset	        => $to_charset,
      type_hash_ref             => $type_hash_ref,
      quiet_mode                => $quiet_mode,
      fh_meta                   => $fh_meta,
  };

  return bless $self, $class;
}

##------------------------------------------------------------------------------
# METHOD
#   public: do_import
#
# DESCRIPTION
#   Importieren der Daten
#-------------------------------------------------------------------------------
sub do_import {

  my $self = shift;
  
  my $dbh     = $self->{dbh};
  my $fh_meta = $self->{fh_meta};
  
  #--- Startzeit und übergebene Parameter in die Meta-Datei schreiben
  print $fh_meta "Import.pm version $VERSION\n\n".
                 "Import started at " . localtime() ." by user $ENV{USER} ".
                 "on $ENV{HOSTNAME}\n\n" .
                 "directory     : $self->{dir}\n" .
                 "data source   : $self->{data_source}\n" .
                 "schema        : $self->{username}\n" .
                 "type hash file: $self->{type_hash_file}\n\n";

  #--- Spalteninformationen zu den bestehenden Tabellen holen
  $self->_get_table_info();

  #--- Daten lesen und in die Datenbank schreiben 
  $self->_insert_data();

  #--- Endezeit in die Meta-Datei schreiben
  print $fh_meta "\nImport finished at " . localtime() ."\n";
}

##------------------------------------------------------------------------------
# METHOD
#   private: _get_table_info
#
# DESCRIPTION
#   Spalteninformationen zu den bestehenden Tabellen holen
#-------------------------------------------------------------------------------
sub _get_table_info {

  my $self = shift;

  my $dbh    = $self->{dbh};
  
  # -------------------------
  #  Tabellennamen ermitteln
  # -------------------------
  $self->_get_table_names();
 
  # -------------------------------------------------------
  #  Hash mit allen verfügbaren Spaltentypen zusammenbauen
  # -------------------------------------------------------
  my $type_info_all = $dbh->type_info_all();

  my $DATA_TYPE_idx = $type_info_all->[0]->{DATA_TYPE};
  my $TYPE_NAME_idx = $type_info_all->[0]->{TYPE_NAME};

  my %data_types;

  my $len = @{$type_info_all};

  #--- Ids und Namen der verfügbaren Spaltentypen holen
  for ( my $i=1; $i < $len; ++$i ) {

    $data_types{$type_info_all->[$i]->[$DATA_TYPE_idx]}
          = lc( $type_info_all->[$i]->[$TYPE_NAME_idx] );
  }

  # --------------------------------------------
  #  Spalten-Infos der einzelnen Tabellen holen
  # --------------------------------------------
  $self->_write_status( "\n" );

  foreach my $table_name ( keys %{ $self->{tables} } ) {

    $self->_write_status(
        ">>> getting column infos for table " . uc( $table_name ) . "...\n"
    );

    #--- Dummy-Statement ausführen, um die Spalteninformationen
    #--- zur aktuellen Tabelle ermitteln zu können
    my $sth = $dbh->prepare ("SELECT * FROM $table_name WHERE 1=0");

    $sth->execute();

    my @column_names  = @{ $sth->{NAME_lc} };
    my @column_types  = @{ $sth->{TYPE} };
    my $column_number = 0;

    foreach my $col ( @column_names ) {

      #--- Bei BLOB-, CLOB- und Serial-Spalten, wird der Typ nicht aus der
      #--- Datenbank sondern aus dem übergebenen Type-Hash geholt
      my $hash_type = $self->{type_hash_ref}{$table_name}{$col};
      my $db_type   = $data_types{$column_types[$column_number]};

      if ( $hash_type =~ /(^blob|^clob|^serial)/i ) {
        $self->{tables}{$table_name}{$col}{type} = $hash_type;
      }
      else {
        $self->{tables}{$table_name}{$col}{type} = $db_type;
      }

      $column_number++;
    }
  }
}

##------------------------------------------------------------------------------
# METHOD
#   private: _get_table_names
#
# DESCRIPTION
#   Namen der bestehenden Tabellen ermitteln
#-------------------------------------------------------------------------------
sub _get_table_names {
  
  my $self = shift;

  my $dbh    = $self->{dbh};
  
  my $schema = uc ( $self->{username} );
  
  my ( $sth, $table_name_key);

  # --------------------------
  #  alle Tabellennamen holen
  # --------------------------
  $self->_write_status( ">>> getting table names for schema $schema...\n" );
  
  #--- Sonderbehandlung für Sybase
  #--- (table_info()-Aufruf funktioniert nicht mit Hashref als Parameter)
  if ( $self->{data_source} =~ m/Sybase/i ) {
    $sth            = $dbh->table_info( $self->{username} );
    $table_name_key = "table_name";
  }
  else {
    my %attr        = (  TABLE_SCHEM => $schema );
    $sth            = $dbh->table_info( \%attr );
    $table_name_key = "TABLE_NAME";
  }

  # ----------------------
  #  Tabellennamen prüfen
  # ----------------------
  my $table_info_hr;
  
  while ( $table_info_hr = $sth->fetchrow_hashref() ) {
    
    my $table_name = lc( $table_info_hr->{$table_name_key} );
   
    #--- überspringen, wenn die Tabelle nicht zum angegebenen Schema gehört
    #--- (bei mySQL wird kein Schema-Name zurückgegeben..)
    #next  if $table_info_hr->{TABLE_SCHEM} ne $schema;

    #--- überspringen, wenn es zur Tabelle keinen Eintrag im
    #--- übergebenen Type-Hash gibt
    if ( not $self->{type_hash_ref}{$table_name} ) {
      
      $self->_write_status(
          "\nWARNING! Table " . uc( $table_name ) .
          " will be skipped due to missing type hash entry!\n"
      );
      next;
    }

    $self->{tables}{ lc( $table_name ) } = {};
  }

}

##------------------------------------------------------------------------------
# METHOD
#   private: _insert_data
#
# DESCRIPTION
#   Daten aus dem Filesystem lesen und in die Datenbank schreiben
#-------------------------------------------------------------------------------
sub _insert_data {

  my $self = shift;
  
  my $insert_count = 0;

  #--- neuen SQL-Handle erzeugen  
  my $dbh          = $self->{dbh};
  my $from_charset = $self->{from_charset};
  my $to_charset   = $self->{to_charset};

  my $sqlh = Dimedis::Sql->new ( 
      dbh           => $dbh, 
      type          => $self->{type_hash_ref},
      debug         => 0,
      serial_write  => 1,
      utf8          => ($to_charset eq 'utf8'),
  );

  $self->_write_status( "\n" );

  # --------------------------------------------------------
  #  alle gefundenen Tabellen durchlaufen, zugehörige Daten
  #  aus dem Filesystem lesen und in die DB einfügen
  # --------------------------------------------------------
  foreach my $table_name ( keys %{ $self->{tables} } ) {

    my $table_dir = $self->{dir} . "/$table_name";
   
    #--- Tabelle überspringen, wenn es kein zugehöriges
    #--- Export-Verzeichnis gibt 
    next  unless -d $table_dir;

    # -----------------------------------------------
    #  bestehende Datensätze aus der Tabelle löschen
    # -----------------------------------------------
    $self->_write_status(
        ">>> deleting data from table " . uc( $table_name ) . "...\n"
    );
   
    my $sth = $dbh->prepare ("DELETE FROM $table_name");
    $sth->execute();

    # ----------------------------------------------------------------------
    #  Spalten-Infos aus der Datei 'format.conf' der aktuelle Tabelle lesen
    # ----------------------------------------------------------------------
    my $VAR1;
   
    my $fh = FileHandle->new();
    open( $fh, "$table_dir/format.conf" ) or die "Can't open file: $!\n";

    my $data = join ("", <$fh>);
    eval ($data);

    close($fh);

    #--- zugehörige Spalten zur aktuellen Tabelle ermitteln
    #--- (aus der Datei format.conf, die beim Export erstellt wurde, holen,
    #---  damit die Reihenfolge der Spalten beim Insert stimmt)
    my $column_lr    = $VAR1;
    my $column_count = @{$column_lr};
    
    my ( @skipped_invalid_columns, @skipped_date_columns,
         $column_name, $column_type
    );
    
    for ( my $i=0; $i < $column_count; $i++ ) {

      $column_name = $column_lr->[$i]->{name};
      $column_type = $self->{tables}{$table_name}{$column_name}{type};
          
      #--- Spalte beim Insert überspringen, wenn es dazu keinen
      #--- Type-Hash-Eintrag gibt
      if ( $column_type eq "" ) {
        push ( @skipped_invalid_columns, uc( $column_name ) );
      }
      #--- Spalte beim Insert überspringen, wenn es eine Date-Spalte ist
      #--- (kann Dimedis::Sql nicht verarbeiten)
      elsif ( $column_type =~ /^date$/i ) {
        push ( @skipped_date_columns, uc( $column_name ) );
      }
    }

    # ----------------------------------------------------------
    #  neues CSV-Objekt erzeugen, um die exportierten Daten aus
    #   der entsprechenden CSV-Datei zu lesen
    # ----------------------------------------------------------
    my $csv = Dimedis::Sql::CSV->new (
        filename  => $table_dir . "/data.dump",
        delimiter => "\t",
	layer	  => ( $self->{from_charset} eq 'utf8' ? ':utf8' : '' ),
    );

    #--- für jede Zeile aus der CSV-Datei wird jetzt das
    #--- Datenhash gefüllt und der Datensatz wirden in die
    #--- Datenbank geschrieben
    $self->_write_status(
        ">>> inserting data into table " . uc( $table_name ) . "...\n\n"
    );
    
    my $data_lr;

    while ( $data_lr = $csv->read_line() ) {

      my %data;

      for ( my $i=0; $i < $column_count; $i++) {

        $column_name = $column_lr->[$i]->{name};
        $column_type = $self->{tables}{$table_name}{$column_name}{type};

        #--- Datums-Spalten und Spalten ohne Type-Hash-Eintrag überspringen
        #--- (die Namen dieser Spalten wurden weiter oben schon in die Liste
        #---  @skipped_invalid_columns oder @skipped_date_columns geschrieben
        #---  und werden später in einer Warnung ausgegeben)
        next  if ( $column_type eq "" or $column_type =~ /^date$/i ); 
        
        #--- Wert auf undef setzen, falls der Inhalt der DB-Spalte NULL war
        undef $data_lr->[$i] if $data_lr->[$i] eq "";

        #--- Sonderbehandlung von BLOB's und CLOB's
        if ( $column_type eq 'clob' or $column_type eq 'blob' ) {
          #-- Behandlung leerer Blobs (für die gibt's keine Datei)
          my $filename = "$table_dir/$data_lr->[$i]";
          $filename = "/dev/null" if not -f $filename;
          if ( $column_type eq 'clob' ) {
	    if ( $from_charset eq $to_charset ) {
	      #-- Dateiname übergeben, keine explizite Konvertierung
	      #-- nötig, also kann Dimedis::Sql das File für uns einlesen.
              $data_lr->[$i] = $filename;
	    } else {
	      #-- Bei unterschiedlichen Zeichensätzen (derzeit gibt's
	      #-- nur latin1->utf8), muß die Datei :raw eingelesen
	      #-- werden, da latin1. Beim Insert wird wg. des fehlenden
	      #-- utf8 Tags automatisch nach utf8 konvertiert.
	      $data_lr->[$i] = $sqlh->blob2memory (
	        $filename,
	        $column_name, $column_type,
	        ":raw"
	      );
	    }
          } elsif ( $column_type eq 'blob' ) {
	    $data_lr->[$i] = $filename;
	  }
        }
        $data{$column_name} = $data_lr->[$i];
      }

      # --------------------
      #  Datensatz einfügen
      # --------------------
      $sqlh->insert (
          table => $table_name,
          data  => \%data,
      );
     
      $insert_count++;
     
      #--- committen?
      if ( $self->{inserts_per_transaction} ne ""
       and $insert_count == $self->{inserts_per_transaction} )
      {
        $dbh->commit();
        $insert_count = 0;
      }
    }

    #--- Warnungen mit den Namen der übersprungenen Spalten ausgeben
    if ( scalar( @skipped_invalid_columns ) > 0 ) {
      $self->_write_status(
          "WARNING! Skipped column(s) "
          . join ( ", ", @skipped_invalid_columns ) .
          " due to missing type hash entry.\n\n"
      );
    }
    if ( scalar( @skipped_date_columns ) > 0 ) {
      $self->_write_status(
          "WARNING! Skipped column(s) "
          . join ( ", ", @skipped_date_columns ) .
          " due to illegal column type 'date'.\n\n"
      );
    }

    #--- Daten committen
    $dbh->commit();
  }

}

##------------------------------------------------------------------------------
# METHOD
#   private: _write_status
#
# DESCRIPTION
#   Status-Meldungen ausgeben
#-------------------------------------------------------------------------------
sub _write_status {
  
  my $self    = shift;
  my $message = shift;
  
  my $fh_meta = $self->{fh_meta};
  
  #--- Meldung auf der Standardausgabe ausgeben, wenn der Quiet-Modus
  #--- ausgeschaltet ist
  print $message  unless $self->{quiet_mode};
  
  #--- Meldung in die Meta-Datei schreiben
  print $fh_meta $message;
}

sub DESTROY {

  my $self = shift;

   #--- Meta-Datei schließen 
  my $fh = $self->{fh_meta};

  close($fh) if $fh;
}
