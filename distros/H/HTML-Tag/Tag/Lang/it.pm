package HTML::Tag::Lang::it;
use strict;
use warnings;
our $VERSION = 0.02;

use base qw(Exporter);
our (@EXPORT_OK, %bool_descr,@month);
@EXPORT_OK = qw(%bool_descr @month);

%bool_descr = (
								0	=> 'No',
								1 => 'Si'
							);

@month  = qw/Gennaio Febbraio Marzo Aprile Maggio Giugno Luglio Agosto
                Settembre Ottobre Novembre Dicembre/;

1;
