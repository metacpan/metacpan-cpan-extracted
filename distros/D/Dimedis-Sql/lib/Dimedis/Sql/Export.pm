package Dimedis::Sql::Export;

use strict;
use vars qw($VERSION);
use Carp;

use Dimedis::Sql;
use Dimedis::Sql::CSV;
use Data::Dumper;
use FileHandle;
use File::Path;

$VERSION = '0.21';

##------------------------------------------------------------------------------
# CLASS
#   Dimedis::Sql::Export
#
# PURPOSE
#   Diese Klasse ermöglicht einen Export von Daten aus einer bestimmten
#   Datenbank (Oracle, MySQL oder mSQL) in ein angegebenes Export-Verzeichnis
#   im Filesystem.
#   <p>
#   Es werden alle bestehenden Tabellen der Quelldatenbank exportiert, für die
#   es einen Eintrag im übergebenen Type-Hash gibt, und die nicht explizit über
#   den <code>exclude_tables</code>-Parameter vom Export ausgeschlossen werden.
#   <p>
#   Im angegebenen Export-Verzeichnis wird für jede exportierte Tabelle ein
#   Unterverzeichnis mit dem Namen der entsprechenden Tabelle angelegt.
#   Dort werden dann die zugehörigen Daten abgelegt:
#   <ul>
#     <li>Die Datei <b>format.conf</b> enthält Informationen (Spaltenname, Typ
#         und maximale Länge) zu den zugehörigen Tabellen-Spalten.<br>
#     <li>Die eigentlichen Daten werden in der CSV-Datei <b>data.dump</b>
#         abgelegt, wobei die einzelnen Spalten durch Tabulatoren voneinander
#         getrennt sind.<br>
#         Enthält eine Tabelle BLOB- oder CLOB-Spalten, werden die
#         Inhalte dieser Spalten in separaten Dateien (<b>blob_1.bin -
#         blob_n.bin</b>) gespeichert. In der CSV-Datei wird dann für diese
#         Spalten nur der Name der zugehörigen Datei abgelegt.
#   </ul>
#   <p>
#   Die Start- und Endzeit des Exports, sowie die übergebenen Parameter
#   und die Statusmeldungen, die während des Exports ausgegeben werden,
#   werden in die Datei <b>export.meta</b> im Export-Verzeichnis
#   geschrieben.
#   <p>
#   Wenn ein DB-Export in ein bereits vorhandenes Export-Verzeichnis
#   gemacht wird, dann wird die bestehende <b>export.meta</b>-Datei 
#   überschrieben. Die Unterverzeichnisse der Tabellen, die neu exportiert
#   werden, werden vorher komplett gelöscht. Bereits existierende
#   Unterverzeichnisse von Tabellen, die beim neuen Export nicht berücksichtigt
#   werden, bleiben bestehen.
#   <p>
#   Beispiel-Aufruf:
#   <pre>
#   |   my $export = Dimedis::Sql::Export->new(
#   |       dbh        => $dbh,
#   |       config     => {
#   |                      data_source    => 'dbi:Oracle:',
#   |                      username       => 'test',
#   |                      directory      => '/tmp/export',
#   |                      type_hash_file => './prod/config/lib.install.sql.general.all_tables.config',
#   |                      exclude_tables => ['dr.*', 'test_table'],
#   |                     },
#   |   );
#   |
#   |   $export->do_export();
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
#   Erzeugt ein neues Export-Objekt
#
# INPUT
#   dbh       -- DB-Handle
#   config      -- Config-Hash
#                    <ul>
#                      <li><b>Key:</b>   <code>data_source</code>
#                      <li><b>Value:</b> Data-Source der Quelldatenbank, aus
#                                        der die Daten exportiert werden
#                      <br><br>
#                      <li><b>Key:</b>   <code>username</code>
#                      <li><b>Value:</b> Schema-Name der Quelldatenbank, aus
#                                        der die Daten exportiert werden
#                      <br><br>
#                      <li><b>Key:</b>   <code>directory</code>
#                      <li><b>Value:</b> kompletter Pfad des Verzeichnisses,
#                                        in dem die exportierten Daten
#                                        abgelegt werden
#                      <br><br>
#                      <li><b>Key</b>:   <code>type_hash_file</code>
#                      <li><b>Value</b>: kompletter Pfad der Datei, in der das
#                                        Type-Hash für die zu exportierenden
#                                        Tabellen abgelegt ist
#                      <br><br>
#                      Optional:<br>
#                      <li><b>Key</b>:   <code>exclude_tables</code>
#                      <li><b>Value</b>: Liste der Tabellen, die vom Export
#                                        ausgeschlossen werden
#                    </ul> 
#
# OUTPUT
#   quiet_mode    -- 1 = keine Status-Meldungen zur Laufzeit auf der
#                    Standardausgabe anzeigen
#                    (Default = 0)
#
# RETURN
#   neues Export-Objekt
#-------------------------------------------------------------------------------
sub new {

  my $class = shift;
  my %par   = @_;

  #--- Parameterprüfung
  my $dbh      = $par{dbh}    or croak("'dbh' missing");
  $dbh->{odbc_SQL_ROWSET_SIZE} = 2;
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

  #--- Export-Verzeichnis anlegen, falls noch nicht vorhanden
  mkpath( $config->{directory} )  if not -d $config->{directory};

  #--- neuen Filehandle für die Meta-Datei erzeugen
  my $fh_meta = FileHandle->new();
  open( $fh_meta, "> $config->{directory}/export.meta" )
    or die "Can't open file: $!\n";

  #------

  my $self = {
              dbh            => $dbh,
              data_source    => $config->{data_source},
              username       => $config->{username},
              dir            => $config->{directory},
              exclude_tables => $config->{exclude_tables},
	      include_tables => $config->{include_tables},
              type_hash_file => $config->{type_hash_file},
	      utf8	     => ($config->{utf8}?1:0),
              type_hash_ref  => $type_hash_ref,
              quiet_mode     => $quiet_mode,
              fh_meta        => $fh_meta,
             };

  return bless $self,$class;
}

##------------------------------------------------------------------------------
# METHOD
#   public: do_export
#
# DESCRIPTION
#   Exportieren der Daten
#-------------------------------------------------------------------------------
sub do_export {

  my $self = shift;
  
  my $fh_meta = $self->{fh_meta};
  
  my $exclude_string = join ( ", ", @{$self->{exclude_tables}} )
     if defined $self->{exclude_tables}; 
  my $include_string = join ( ", ", @{$self->{include_tables}} )
     if defined $self->{include_tables}; 

  #--- Startzeit und übergebene Parameter in die Meta-Datei schreiben
  print $fh_meta "Export.pm version $VERSION\n\n".
                 "Export started at " . localtime() ." by user $ENV{USER} ".
                 "on $ENV{HOSTNAME}\n\n" .
                 "directory     : $self->{dir}\n" .
                 "data source   : $self->{data_source}\n" .
                 "schema        : $self->{username}\n" .
		 "utf8          : $self->{utf8}\n" .
                 "exclude tables: $exclude_string \n" .
		 "include tables: $include_string \n" .
                 "type hash file: $self->{type_hash_file}\n\n";

  #--- Spalteninformationen zu den bestehenden Tabellen holen
  $self->_get_table_info();

  #--- Daten lesen und ins Filesystem schreiben 
  $self->_get_data();
  
  #--- Endezeit in die Meta-Datei schreiben
  print $fh_meta "\nExport finished at " . localtime() ."\n";
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

  # -------------------------------------------------------
  #  Spalteninformationen für die einzelnen Tabellen holen
  # -------------------------------------------------------
  $self->_write_status( "\n" );

  foreach my $table_name ( keys %{ $self->{tables} } ) {

    $self->_write_status( ">>> getting column infos for table " .
                  uc( $table_name ) . "...\n"
    );

    #--- Dummy-Statement ausführen, um die Spalteninformationen
    #--- zur aktuellen Tabelle ermitteln zu können
    my $sth = $dbh->prepare ("SELECT * FROM $table_name WHERE 1=0");

    $sth->execute();

    #--- alle Spaltennamen und -Typen zur aktuellen Tabelle speichern
    my @column_names  = @{ $sth->{NAME_lc} };
    my @column_types  = @{ $sth->{TYPE} };
    my $column_number = 0;

    foreach my $col ( @column_names ) {

      #--- Bei BLOB-, CLOB- und Serial-Spalten, wird der Typ nicht aus der
      #--- Datenbank sondern aus dem übergebenen Type-Hash geholt
      my $hash_type = $self->{type_hash_ref}{$table_name}{$col};

      if ( $hash_type =~ /(^blob|^clob|^serial)/i ) {

        push ( @{ $self->{tables}{$table_name} },
              {
               name => $col,
               type => $hash_type,
              }
        );
      }
      else {

        push ( @{ $self->{tables}{$table_name} },
              {
               name => $col,
               type => $data_types{$column_types[$column_number]},
              }
        );
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

  my ( $exclude_regexp, $include_regexp, $sth, $table_name_key );

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
    my %attr        = ( TABLE_SCHEM => "$schema" );
    $sth            = $dbh->table_info( \%attr );
    $table_name_key = "TABLE_NAME";
  }

  # -----------------------------------------------------------------
  #  Regulären Ausdruck zusammenbauen, um die Tabellen zu ermitteln,
  #  die exportiert werden sollen 
  # -----------------------------------------------------------------
  foreach my $include_table ( @{$self->{include_tables}} ) {
    $include_table  =~ s/_/\_/;
    $include_regexp .= "|$include_table";
  }

  $include_regexp = substr ( $include_regexp, 1 );
  
  # -----------------------------------------------------------------
  #  Regulären Ausdruck zusammenbauen, um die Tabellen zu ermitteln,
  #  die nicht exportiert werden sollen 
  # -----------------------------------------------------------------
  foreach my $exclude_table ( @{$self->{exclude_tables}} ) {
    $exclude_table  =~ s/_/\_/;
    $exclude_regexp .= "|$exclude_table";
  }

  $exclude_regexp = substr ( $exclude_regexp, 1 );
  
  # ----------------------
  #  Tabellennamen prüfen
  # ----------------------
  my $table_info_hr;

  while ( $table_info_hr = $sth->fetchrow_hashref() ) {
    
    my $table_name = lc( $table_info_hr->{$table_name_key} );
    
    #--- überspringen, wenn die Tabelle nicht zum angegebenen Schema gehört
    #--- (bei mySQL wird kein Schema-Name zurückgegeben..)
    #next  if $table_info_hr->{TABLE_SCHEM} ne $schema;

    #--- überspringen, wenn die Tabelle nicht importiert werden soll
    next  if $include_regexp and $table_name !~ /^($include_regexp)$/i;

    #--- überspringen, wenn die Tabelle nicht exportiert werden soll
    next  if $table_name =~ /^($exclude_regexp)$/i;
    
    #--- überspringen, wenn es zur Tabelle keinen Eintrag im
    #--- übergebenen Type-Hash gibt
    if ( not $self->{type_hash_ref}{$table_name} ) {
      
      $self->_write_status(
                           "\nWARNING! Table " . uc( $table_name ) .
                           " will be skipped due to missing type " .
                           "hash entry!\n"
      );
      next;
    }
   
    $self->{tables}{ lc( $table_name ) } = [];
  }
}

##------------------------------------------------------------------------------
# METHOD
#   private: _get_data
#
# DESCRIPTION
#   Daten aus der Datenbank lesen und ins Filesystem schreiben
#-------------------------------------------------------------------------------
sub _get_data {

  my $self = shift;
  
  my $dbh  = $self->{dbh};
  my $utf8 = $self->{utf8};

  #--- neuen SQL-Handle erzeugen  
  my $sqlh = new Dimedis::Sql ( 
    dbh   => $dbh, 
    type  => $self->{type_hash_ref},
    debug => 0,
    utf8  => $utf8, 
  );

  $self->_write_status( "\n" );

  foreach my $table_name ( keys %{ $self->{tables} } ) {

    $self->_write_status(
        ">>> getting data from table " .
        uc( $table_name ) . "...\n"
    );
    
    my @select_columns;
    my @select_column_max_length;
    my $select_column_count;
    my %lob_columns;
    my $serial_column;
    my $serial_index;

    my $table_dir = $self->{dir} . "/$table_name";

   #--- Export-Verzeichnis der aktuellen Tabelle entfernen, falls vorhanden
   #--- (enthält evtl. noch alte Daten vom vorherigen Export)
    File::Path::rmtree ($table_dir )  if -d $table_dir;

    #--- Export-Verzeichnis für die aktuelle Tabelle anlegen
    mkpath( "$table_dir" );

    # ------------------------------------------------------
    #  neues CSV-Objekt erzeugen, um die exportierten Daten
    #  im Filesystem zu speichern
    # ------------------------------------------------------
    my $csv = Dimedis::Sql::CSV->new (
      filename  => $table_dir . "/data.dump",
      delimiter => "\t",
      write     => 1,
      layer     => ($self->{utf8} ? ':utf8': ''),
    );

    # -----------------------------------------------------
    #  Namen der selektierbaren Tabellen-Spalten ermitteln
    # (BLOB- und CLOB-Felder werden separat gelesen)
    # -----------------------------------------------------
    my $column_number;

    foreach my $column_hr ( @{$self->{tables}{$table_name}} ) {

      #--- Ist es eine BLOB- oder CLOB-Spalte?
      #--- Wenn ja: Name und Position der Spalte merken und anstelle
      #--- des Feldinhaltes einen Leerstring selektieren, der dann später
      #--- durch den Namen der Datei, in der der Feldinhalt gespeichert wird,
      #--- ersetzt wird.
      if ( $column_hr->{type} =~ /(^blob$|^clob$)/i ) {
        $lob_columns{$column_hr->{name}} = $column_number;
        push ( @select_columns, "''" );
      }
      #--- normal selektierbare Spalten
      else {
  
        #--- Name der Serial-Spalte merken, falls vorhanden
        #--- (wird für den späteren Zugriff auf BLOB- / CLOB-Felder
        #---  als Schlüssel benötigt)
        if ( $column_hr->{type} =~ /^serial$/i ) {
          $serial_column = $column_hr->{name};
          $serial_index  = $column_number;
        }

        push ( @select_columns, $column_hr->{name} );
      }

      $column_number++;
    }
    
    $select_column_count = @select_columns;

    #--- Tabelle überspringen und Warnung ausgeben, wenn sie BLOB- oder
    #--- CLOB-Spalten, aber keine Serial-Spalte enthält, weil dann der
    #--- Schlüssel für den Zugriff auf die BLOB- / CLOB-Felder fehlt
    if ( %lob_columns and $serial_column eq "" ) {

      $self->_write_status(
          "\nWARNING! Skipped table $table_name. " .
          "Can't read lob columns due to missing serial column!\n\n"
      );
      next;
    }

    # ---------------------------------------------
    #  alle Daten (außer BLOBs und CLOBs) einlesen
    # ---------------------------------------------
    my $sth = $dbh->prepare (
        "SELECT " . join ( ", ", @select_columns ) .
        " FROM   $table_name"
    );

    $sth->execute();
    
    # ----------------------------    
    #  Daten in Dateien speichern
    # ----------------------------
    my $result_row;
    my $counter = 0;
    my $length  = 0;
 
    while ( $result_row = $sth->fetch() ) {
      
      #--- Längen der einzelnen Spalten-Inhalte ermitteln, um die
      #--- maximale Spaltenlänge in die format.conf-Datei zu schreiben
      for ( my $i = 0; $i < $select_column_count; $i++ ) {
        
        $length = length($result_row->[$i]);
        
        if ( $select_column_max_length[$i] < $length ) {
          $select_column_max_length[$i] = $length
        }
        
      }
      
      if ( $serial_column ne "" ) {

        # -----------------------------------------------------------
        #  alle BLOB- und CLOB-Feldinhalte des aktuellen Datensatzes
        #  als Datei speichern
        # -----------------------------------------------------------
        foreach my $lob_column_name ( keys %lob_columns ) {

          $counter++;

          my $filename = "blob_$counter.bin";
    
          $sqlh->blob_read (
              table    => $table_name,
              col      => $lob_column_name,
              where    => "$serial_column = $result_row->[$serial_index]",
              filename => "$table_dir/$filename",
          );

          #--- Datei löschen, wenn leer (spart Verzeichniseinträge)
          unlink "$table_dir/$filename" if -s "$table_dir/$filename" == 0;

          #--- Name der Datei in die Liste der selektierten Daten übernehmen
          $result_row->[$lob_columns{$lob_column_name}] = $filename;
        }
      }

      #--- Ggf. UTF8 Tagging durchführen
      if ( $utf8 ) {
	      Encode::_utf8_on($_) for @{$result_row};
      }

      #--- aktuellen Datensatz in die CVS-Datei schreiben
      $csv->append ( data_lr => $result_row );
    }
    
    #--- maximale Spaltenlängen eintragen
    for ( my $i = 0; $i < $select_column_count; $i++ ) {
      my $ref = $self->{tables}{$table_name}->[$i];
      $ref->{maxlength} = $select_column_max_length[$i];
    }

    # -------------------------------------------------------------------------
    #  Spalten-Infos in die Datei 'format.conf' der aktuelle Tabelle schreiben
    # -------------------------------------------------------------------------
    my $fh = FileHandle->new();
    open( $fh, "> $table_dir/format.conf" ) or die "Can't open file: $!\n";
    print $fh Dumper( $self->{tables}{$table_name} );
    close($fh);
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
