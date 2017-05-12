# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl 13_writepnmfile.t'

# WARNING: some of these tests are invalid if 10_makepnmheader.t has failed.

#########################

use Test::More tests => 11;
BEGIN { use_ok('Image::PBMlib') };

use strict;

use vars qw( $val $set @pix %i $val $file $rc $usemd5 %md5 );

%md5 = (
  'testout-2x10r.ppm' => 'f23163fc655dd21b76f2a72aef461fb8',
  'testout-3x3a.pgm'  => '9ebebf84cb6458ca9c10783d392cfb59',
  'testout-3x3hr.pgm' => '16c119e2aaac99a1ea201798246c9978',
  'testout-3x3r.pgm'  => 'e1464a8852add759f51dfb07f0e6cddd',
  'testout-9x5r.pgm'  => '4b7de094763f0fe18c6163207f256b58',
);

eval 'use Digest::MD5;';
if($@) {
  $usemd5 = undef;
} else {
  $usemd5 = 1;
}

# does 1 tests
sub checkfile {

  SKIP: {
    if(!open(WRITE, '>:raw', $file)) {
      skip "Cannot open test out $file: $!", 2;
    }
    $rc = writepnmfile(\*WRITE, \%i, \@pix); close WRITE;

    if(!defined($rc)) {
      skip "write to $file failed: $!", 2;
    }
    close WRITE;

    ok($rc == $val, "$set writepnmfile $file");

  }
}

$set = '1-d array';

@pix = ( '31/', '32/', '33/', '21/', '22/', '23/', '11/', '12/', '13/' );
%i = ( type => 2, width => 3, height => 3, max => 128, comments => 'test 3x3 ascii graymap' );
# three rows, three cols, 3 chars per number, plus final newline
$val = length(makepnmheader(\%i)) + 3*3*3 +1;
$file = 'testout-3x3a.pgm';
checkfile();

%i = ( type => 5, width => 3, height => 3, max => 128, comments => 'test 3x3 raw graymap' );
# three rows, three cols, 1 byte per value
$val = length(makepnmheader(\%i)) + 3*3;
$file = 'testout-3x3r.pgm';
checkfile();

%i = ( type => 5, width => 3, height => 3, max => 999, comments => 'test 3x3 high raw graymap' );
# three rows, three cols, 2 bytes per value
$val = length(makepnmheader(\%i)) + 3*3*2;
$file = 'testout-3x3hr.pgm';
checkfile();

$set = '2-d array';
@pix = ( [ '31/', '32/', '33/', '21/', '22/', '23/', '11/', '12/', '13/' ],
         [ '34/', '35/', '36/', '24/', '25/', '26/', '14/', '15/', '16/' ],
	 [ '37/', '38/', '39/', '27/', '28/', '29/', '17/', '18/', '19/' ],
	 [ '3A/', '3B/', '3C/', '2A/', '2B/', '2C/', '1A/', '1B/', '1C/' ],
	 [ '3D/', '3E/', '3F/', '2D/', '2E/', '2F/', '1D/', '1E/', '1F/' ],
);
%i = ( type => 5, width => 9, height => 5, max => 255, comments => 'test 9x5 raw graymap' );
# five rows, nine cols, 1 byte per value
$val = length(makepnmheader(\%i)) + 5*9;
$file = 'testout-9x5r.pgm';
checkfile();

$set = '3-d array';
@pix = ( [ [ '99:', '98:', '97:' ], [ '96:', '95:', '94:' ], ],
         [ [ '89:', '88:', '87:' ], [ '86:', '85:', '84:' ], ],
         [ [ '79:', '78:', '77:' ], [ '76:', '75:', '74:' ], ],
         [ [ '69:', '68:', '67:' ], [ '66:', '65:', '64:' ], ],
         [ [ '59:', '58:', '57:' ], [ '56:', '55:', '54:' ], ],
         [ [ '49:', '48:', '47:' ], [ '46:', '45:', '44:' ], ],
         [ [ '39:', '38:', '37:' ], [ '36:', '35:', '34:' ], ],
         [ [ '29:', '28:', '27:' ], [ '26:', '25:', '24:' ], ],
         [ [ '19:', '18:', '17:' ], [ '16:', '15:', '14:' ], ],
         [ [  '9:',  '8:',  '7:' ], [  '6:',  '5:',  '4:' ], ],
       );
%i = ( type => 6, width => 2, height => 10, max => 100, comments => 'test 2x10 raw pixmap' );
# ten rows, two cols, 1 byte per value, 3 values per pixel
$val = length(makepnmheader(\%i)) + 2*10*3;
$file = 'testout-2x10r.ppm';
checkfile();

SKIP: {
  if(!$usemd5) {
    skip 'No MD5 available', 5;
  }
  for $file (keys %md5) {
    my $ctx = Digest::MD5->new;

    open(READ, '<:raw', $file);
    $ctx->addfile(*READ);
    my $digest = $ctx->hexdigest;
    close READ;
    
    ok($md5{$file} eq $digest, "$set MD5 $file");
  }
}

END { 
  for $file (keys %md5) {
    unlink $file;
  }
}
