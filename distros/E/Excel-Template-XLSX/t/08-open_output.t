#!perl 

use strict;
use warnings;

use lib 't/lib';
use Excel::Template::XLSX;
use Test::More;

our $CAPTURE = '';

# Setup to capture warnings
my $sigd = $SIG{__DIE__};
$SIG{__DIE__} = sub { $CAPTURE = $_[0] };

my $sigw = $SIG{__WARN__};
$SIG{__WARN__} = sub { };

eval {
   # Excel::Writer::XLSX->new() requires a file name
   Excel::Template::XLSX->new( '', '' );
};

# Restore previous warn handlers
$SIG{__DIE__}  = $sigd;
$SIG{__WARN__} = $sigw;

# remove reason from error message
( my $got = $CAPTURE ) =~ s/object.*/object/s;
is($got,
   "Can't create new Excel::Writer::XLSX object",
   'Failure to create EWX object'
);

done_testing;
