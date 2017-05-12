# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Convert-CSV.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
use strict; use warnings;

use Test::More tests => 1;

use IO::Extended qw(:all);

use Class::Maker qw(:all);

use Data::Iter qw(:all);

use Data::Dump qw(dump);

BEGIN { use_ok('File::Convert::CSV') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $converter = File::Convert::CSV->new( 
					d_verbosity => 3,
					file => 'examples/excel_export.txt',
					separator => ";"
				       );

$converter->iterate_each_line( 
			      sub 
			      { 
				my $this = shift; 

				$this->d_warn( "DATA_HASH %s", dump( $this->data_hash ) );
				
				$this->d_warn( "DATA_ARRAY %s", dump( $this->data_array ) );
				
				$this->d_warn( "DATA_FIELDS %s", dump( $this->data_fields ) );
				
				$this->d_warn( "RAW %s", $this->raw );

			      }
			     );


$converter = File::Convert::CSV->new( 
				     d_verbosity => 3,
				     separator => " "
				    );

my $string = <<'END_HERE';
ALPHA BETA
1 6
2 6
3 6
END_HERE

$converter->iterate_each_line_from_string(
					  $string,
					   sub 
					   { 
					     my $this = shift; 
					     
					     $this->d_warn( "DATA_HASH %s", dump( $this->data_hash ) );
					     
					     $this->d_warn( "DATA_ARRAY %s", dump( $this->data_array ) );
					     
					     $this->d_warn( "DATA_FIELDS %s", dump( $this->data_fields ) );
					     
					     $this->d_warn( "RAW %s", $this->raw );
					     
					   }
					 );

