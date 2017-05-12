package Model;

use Array::Group;
use Data::Dumper;

# A model is overkill for this example, but lets plan for
# scaleability

sub new {
  
  my $data = [1 .. 10] ;
  bless $data, __PACKAGE__ ;
  return $data;
}

sub reform_data {

  my $aref = shift;
  my $cols = shift;


  my $tabdata = Array::Group::ngroup $cols => $aref ;



  # This filling of the last row should be an option to
  # Array::Group...
  my $last_row = $tabdata->[$#$tabdata] ;

  my $diff = $cols - @$last_row;

  my @nbsp = (' ') x $diff; 
  push @$last_row, @nbsp;

  return $tabdata;
}


1 ;

