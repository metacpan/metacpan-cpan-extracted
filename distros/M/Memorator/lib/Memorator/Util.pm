package Memorator::Util;
use strict;
use warnings;
{ our $VERSION = '0.006'; }

use Exporter qw< import >;
our @EXPORT_OK = qw< local_name >;

sub local_name {
   my ($name, $suffix) = @_;
   (my $retval = $name . '_' . $suffix) =~ s{\W}{_}gmxs;
   return $retval;
}

1;
