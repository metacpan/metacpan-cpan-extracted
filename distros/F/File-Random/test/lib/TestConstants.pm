package TestConstants;

use strict;
use warnings;

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT = qw/SAMPLE_SIZE
                 HOME_DIR      SIMPLE_DIR  EMPTY_DIR  REC_DIR
				 SIMPLE_FILES  SIMPLE_FILES_WITH_NR  SIMPLE_FILES_WITH_DOT
				 REC_FILES     REC_TOP_FILES  REC_ODD_FILES 
				 SIMPLE_CONTENTS
				 REC_CONTENTS
                 no_slash with_slash/;

our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = ();
our $VERSION = '0.01';

use Test::More;
use Test::Exception;

use Set::Scalar;
use Data::Dumper;

use Cwd;

sub files {
	return map {"file$_"} @_;
}

use constant HOME_DIR    => cwd() . '/test';
use constant SIMPLE_DIR  => cwd() . '/test/dir';
use constant EMPTY_DIR   => SIMPLE_DIR . '/empty';
use constant REC_DIR     => SIMPLE_DIR . '/rec';

use constant SIMPLE_FILES_WITH_NR  => files(1 .. 5);
use constant SIMPLE_FILES_WITH_DOT => qw/x.dat y.dat z.dat/;
use constant SIMPLE_FILES          => SIMPLE_FILES_WITH_NR, 
                                      SIMPLE_FILES_WITH_DOT;
									  
use constant REC_TOP_FILES         => files(1 .. 3);
use constant REC_FILES             => REC_TOP_FILES,
                                      map( {"sub1/$_"}        files(4  ..  6) ),
									  map( {"sub1/subsub/$_"} files(7  ..  9) ),
									  map( {"sub2/$_"}        files(10 .. 12) ); 
use constant REC_ODD_FILES         => grep m/[13579]$/, REC_FILES;

use constant REC_CONTENTS    =>  map {"Content: $_"} REC_FILES;
use constant SIMPLE_CONTENTS => ( map({"Content: $_"} SIMPLE_FILES_WITH_NR),
                                  map({"line 0\nline 1\nline 2\n$_\nline 4"}
								      SIMPLE_FILES_WITH_DOT) );
	
use constant SAMPLE_SIZE   => 250;

sub no_slash {
	my $path = shift;
	$path =~ s:[/\\]*$::;
	return $path;
}

sub with_slash {
	no_slash(shift()) . '/';
}

1;
