package BookDB::Form::BookView;

use strict;
use warnings;
use base 'Form::Processor::Model::DBIC';
use DateTime;


sub object_class { 'DB::Book' } 

sub profile {
   return  {
      required => {
         borrower   => 'Select',
	     borrowed   => 'Text',
      },
   };
}	


# List for the "view" part of this form. These are not updated 
# Not a standard form method. Convenience function
sub view_list {
	my @fields = ('title', 'author', 'genre', 'publisher', 'isbn', 'format', 'pages', 'year');
	
    return wantarray ? @fields : \@fields;
}

sub init_value_borrowed
{
    my ($self, $field) = @_;
    return DateTime->now( time_zone => 'local')->ymd;
}

1;
