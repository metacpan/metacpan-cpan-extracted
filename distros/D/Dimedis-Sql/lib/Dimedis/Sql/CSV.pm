package Dimedis::Sql::CSV;

use strict;
use vars qw($VERSION);
use Carp;

use Data::Dumper;
use FileHandle;
use File::Path;

$VERSION = '0.20';

##------------------------------------------------------------------------------
# CLASS
#   Dimedis::Sql::CSV
#
# PURPOSE
#   Diese Klasse ermöglicht das Lesen und Schreiben einer CSV-Datei.
#   <p>
#   Beim Erzeugen eines neuen CSV-Objektes wird die im Konstruktor angegebene
#   Datei entweder zum Lesen oder zum Schreiben geöffnet (abhängig vom 
#   optionalen Parameter <code>write</code>).
#   <p>
#   Mit dem <code>delimiter</code>-Parameter kann das Trennzeichen für die
#   einzelnen Spalten der CSV-Datei angegeben werden (Default-Trennzeichen
#   ist ";").
#   <p>
#   Wurde die Datei zum Schreiben geöffnet, dann kann über die Methode
#   <code>append()</code> eine neue Zeile hinzugefügt werden.
#   <p>
#   Wurde die Datei zum Lesen geöffnet, dann kann über die Methode
#   <code>read_line()</code> eine einzelne Zeile gelesen werden.
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
#   Erzeugt ein neues CSV-Objekt
#
# INPUT
#   filename	-- Name der CSV-Datei, mit dem dieses Objekt verknüpft ist
#
# OPTIONAL
#   write     -- 1 = CSV-Datei zum Schreiben öffnen
#                (Default = 0, zum Lesen öffnen)
#   delimiter	-- Trennzeichen für die einzelnen Spalten der CSV-Datei
#                (Default = ";")
#
# RETURN
#   neues CSV-Objekt
#-------------------------------------------------------------------------------
sub new {

  my $class = shift;
  my %par   = @_;

  #--- Parameterprüfung
  my $filename  = $par{filename} or croak("'filename' missing");
  my $write     = $par{write};
  my $delimiter = $par{delimiter};
  my $layer     = $par{layer};

  $delimiter = ";"  if $delimiter eq "";

  my $fh = FileHandle->new();
  
  if ( $write ) {
    #--- CSV-Datei zum Schreiben öffnen
  	 open ($fh, ">> $filename")
	 	or die "Can't open file: $!\n";
  }
  else {
    #--- CSV-Datei zum Lesen öffnen
	 open ($fh, $filename) if -e $filename;
  }

  #-- Ggf. IO Layer aktivieren
  binmode $fh, $layer if $layer ne '';

  my $self = {
	fh		=> $fh,
	delimiter	=> $delimiter
  };

  return bless $self, $class;	
}

##------------------------------------------------------------------------------
# METHOD
#   public: append
#
# DESCRIPTION
#   Hängt eine neue Zeile an die CSV-Datei an
#   <p>
#   Übergeben wird eine Referenz auf eine Liste, welche die hinzuzufügenden
#   Daten enthält. Die einzelnen List-Elemente werden beim Schreiben in die
#   CSV-Datei durch das im Konstruktor angegebene Trennzeichen voneinander
#   getrennt.
#   <p>
#   Backslashes, Newlines und Tabulatoren, die in den übergebenen Daten
#   enthalten sind, werden vor dem Schreiben in die CSV-Datei escaped.
#
# INPUT
#   data_lr	   -- Referenz auf die Liste der hinzuzufügenden Daten
#-------------------------------------------------------------------------------
sub append {

  my $self = shift;
  my %par  = @_;

  my $fh = $self->{fh};

  #--- Parameterprüfung
  my $data_lr = $par{data_lr} or croak("'data_lr' missing");

  foreach ( @{$data_lr} ) {
	 #--- escape '\'
	 s/\\/\\\\/g;
	 #--- escape newlines
	 s/\n/\\n/g;
	 s/\r/\\r/g;
	 #--- escape tabs
	 s/\t/\\t/g;
  }

  my $data_string = join ( $self->{delimiter}, @{$data_lr} );

  print $fh "$data_string\n" or die "Can't write file: $!\n";
}

##------------------------------------------------------------------------------
# METHOD
#   public: read_line
#
# DESCRIPTION
#   Liest eine einzelne Zeile aus der CSV-Datei ein
#   <p>
#   Die Methode liefert eine Referenz auf eine Liste, welche die gelesenen
#   Daten enthält. Als Trennzeichen zwischen den einzelnen Spalten der
#   gelesenen Zeile gilt der im Konstruktor angegebene <code>delimiter</code>-
#   Parameter.
#   <p>
#   Backslashes, Newlines und Tabulatoren, die vor dem Schreiben in die
#   CSV-Datei escaped wurden, werden hier wieder unescaped.
#
# RETURN
#   Referenz auf die Liste der eingelesenen Daten oder <code>undef</code>,
#   wenn das Dateiende erreicht wurde
#-------------------------------------------------------------------------------
sub read_line {

  my $self = shift;
  
  my $fh = $self->{fh};
  
  my $data_record;

  if ( $data_record = <$fh> ) {

    #--- Zeilenumbruch am Ende der Zeile abschneiden	  
	 chomp $data_record;

    my @data = split ( /$self->{delimiter}/, $data_record );

    foreach ( @data ) {

      #--- unescape '\t'
      s/([^\\])\\t/$1\t/g;
      s/^\\t/\t/g;

      #--- unescape '\n', '\r'
      s/([^\\])\\n/$1\n/g;
      s/^\\n/\n/g;

      s/([^\\])\\r/$1\r/g;
      s/^\\r/\r/g;

      #--- unescape '\\'
      s/\\\\/\\/g;
    }
    
    return \@data;
  }
  #--- Dateiende
  else {

	  return undef;
  }
}

sub DESTROY {

	my $self = shift;

   #--- CSV-Datei schließen	
	my $fh = $self->{fh};

	close($fh) if $fh;
}
