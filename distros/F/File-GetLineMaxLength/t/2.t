# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-GetLineMaxLength.t'

#########################

use Test::More tests => 2;
BEGIN { use_ok('File::GetLineMaxLength') };
use File::Temp qw(tempfile);
use Time::HiRes qw(gettimeofday tv_interval);

#########################

use strict;

my $Fh = tempfile();

WriteFile($Fh);

my $Start = [ gettimeofday ];
for (1 .. 100) {
  ReadFile($Fh);
}
warn "read: " . tv_interval($Start);


$Start = [ gettimeofday ];
for (1 .. 100) {
  ReadGLMLFile($Fh);
}
warn "glml read: " . tv_interval($Start);

ok(1);

sub WriteFile {
  my $Fh = shift;

  for (1 .. 10000) {
    print $Fh "this is an average sort of line\n";
  }

  seek($Fh, 0, 0);
}

sub ReadFile {
  my $Fh = shift;

  while (<$Fh>) {
#	    @_ = split / /;
  }

  seek($Fh, 0, 0);
}

sub ReadGLMLFile {
  my $Fh = shift;

  my $GLMLFh = File::GetLineMaxLength->new($Fh);
  while ($_ = $GLMLFh->getline()) {
#	    @_ = split / /;
  }

  seek($Fh, 0, 0);
}

