use strict;
use warnings;
use Test::More tests => 3;
use File::Basename;
use File::Spec::Functions;
use ESPPlus::Storage::Reader::Tie;
#use vars '$TempFile';
use Fcntl qw(O_WRONLY LOCK_EX);

my $test_dir = dirname( $0 );
my $test_db  = catfile( $test_dir, 'read.rep' );
sub uncompress { \ "12345678" }

SKIP: {
  eval 'require File::Temp; File::Temp->import("tempfile")';
  skip 'File::Temp not installed', 3 if $@;
#  $TempFile = (tempfile())[1];
  
  skip "uncompress -h couldn't be used", 3 unless uncompress_ok();
  
  my $h =
    tie *DB, 'ESPPlus::Storage::Reader::Tie',
      { filename            => $test_db,
	uncompress_function => \ &uncompress };
  
  is( ref $h,
      'ESPPlus::Storage::Reader::Tie',
      'tie' );
  
  my $r = <DB>;
  is( ref $r,
      'SCALAR',
      'readline' );
  
  ok( length $$r,
      'record has contents' );
}

sub uncompress_ok {
  my $fh = IO::File->new;
  open $fh, '-|', $^X, '-e', 'close STDERR;`uncompress -h`;print$?;exit$?'
    or die "Can't exec perl: $!";
  my $ok = ! <$fh>;
  close $fh;
}


