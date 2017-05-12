package JCONF::Writer::Boolean;

use strict;
use Scalar::Util 'refaddr';
use overload
	'""' => sub { ${$_[0]} },
	'==' => sub { refaddr $_[0] == refaddr $_[1] },
	fallback => 1;
 
use constant {
	TRUE  => bless(\(my $true  = 1),  __PACKAGE__),
	FALSE => bless(\(my $false = ''), __PACKAGE__)
};

our $VERSION = '0.03';

use parent 'Exporter';
our @EXPORT_OK = qw(TRUE FALSE);

1;
