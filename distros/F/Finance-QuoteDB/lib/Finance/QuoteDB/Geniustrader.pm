package Finance::QuoteDB::Geniustrader;

use strict;
use warnings;

use Exporter ();
use vars qw/@EXPORT @EXPORT_OK @EXPORT_TAGS/;

use Log::Log4perl qw(:easy);

=head1 NAME

Finance::QuoteDB::Geniustrader - Interfaces to external program Geniustrader

=cut

@EXPORT = ();
@EXPORT_OK = qw // ;
@EXPORT_TAGS = ( all => [@EXPORT_OK] );

our $VERSION = '0.18'; # VERSION

=head1 SYNOPSIS

Please take a look at script/fqdb which is the command-line frontend
to Finance::QuoteDB.

=head1 METHODS

=head2 writeConfig

writeConfig ( $fqdb-obj, $file )

This function will create a Geniustrader config file for the $fqdb object.

=cut

sub writeConfig {
  my ($fqdb,$file) = @_ ;
  my $fh ;
  my $dsn = $fqdb->{dsn};
  INFO ("--- $dsn") ;
  if ( open($fh,"+>","$file") ) {
    my $db = "";
    my $dbname = "";
    my $dbhost = "" ;
    my $dbport = "";
    if ($dsn=~/dbi:(\w+):(\S+)(;.*)?$/) {
      $db = $1 ;
      $dbname = $2 ;
    }
    if ($dsn=~/;host=(\w+)(;.*)?$/) {
      $dbhost = $1 ;
    }
    if ($dsn=~/;port=(\w+)(;.*)?$/) {
      $dbport = $1 ;
    }
		print $fh "# Database specific stuff\n";
    print $fh "DB::module genericdbi\n" ;
    print $fh "DB::genericdbi::db $db\n" if $db ;
    print $fh "DB::genericdbi::dbname $dbname\n" if $dbname ;
    print $fh "DB::genericdbi::dbhost $dbhost\n" if $dbhost ;
    print $fh "DB::genericdbi::dbport $dbport\n" if $dbport ;
    print $fh "DB::genericdbi::dbuser ".$fqdb->{dsnuser}."\n" if $fqdb->{dsnuser} ;
    print $fh "DB::genericdbi::dbpasswd ".$fqdb->{dsnpasswd}."\n" if $fqdb->{dsnpasswd} ;
    print $fh "DB::genericdbi::prices_sql SELECT day_open, day_high, day_low, day_close, volume, date ".
			"FROM quote WHERE symbolID = '\$code' ORDER BY date DESC\n" ;
		print $fh "DB::genericdbi::name_sql SELECT name FROM symbol WHERE symbolID = '\$code'\n" ;
		print $fh "\n";
		print $fh "# Stuff needed by geniustrader which you should set correctly\n";
		print $fh "Graphics::Driver GD\n";
		print $fh "Analysis::ReferenceTimeFrame year\n";
		print $fh "Brokers::module SelfTrade\n";
		print $fh "Path::Font::Arial ~/.gt/Arial.ttf\n";
		print $fh "Path::Font::Courier ~/.gt/Geneva.ttf\n";
		print $fh "Path::Font::Times ~/.gt/Times.ttf\n";
    close $fh ;
		print "Configuration file $file written.\n";
  } else {
    ERROR ("Could not open $file in write mode") ;
  }
}

1;
