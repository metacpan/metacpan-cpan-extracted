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

BEGIN 
  { 
    use_ok('File::Convert::CSV');
    use_ok('File::Convert::Taqman');
  };

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $converter = File::Convert::Taqman->new( 
					d_verbosity => 3,
					file => 'examples/taqman_export.txt',
				       );


ok( $converter->is_file_valid( 'examples/taqman_export.txt' ) );

my @converted_output;

$converter->iterate_each_line( 
			      sub 
			      { 
				my $this = shift; 

				$this->d_warn( "RAW %s", $this->raw );

				my $href = $this->data_hash;

				$href->{date_last_modified} = $this->file_info->{'Last Modified'};

				push @converted_output, $href;
			      }

			     );


#print dump( @converted_output );

