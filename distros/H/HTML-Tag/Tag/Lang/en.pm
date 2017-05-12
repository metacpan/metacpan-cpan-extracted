package HTML::Tag::Lang::en;
use strict;
use warnings;
our $VERSION = 0.02;

use base qw(Exporter);
our (@EXPORT_OK, %bool_descr,@month);
@EXPORT_OK = qw(%bool_descr @month);

%bool_descr = (
								0	=> 'No',
								1 => 'Yes'
							);

@month  = qw/January February March April May June July August
             September October November December/;

1;
