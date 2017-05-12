package HTML::HTML5::Table::HeadCell;

use 5.010;
use namespace::autoclean;
use utf8;

BEGIN {
	$HTML::HTML5::Table::HeadCell::AUTHORITY = 'cpan:TOBYINK';
	$HTML::HTML5::Table::HeadCell::VERSION   = '0.004';
}

use Moose;
extends 'HTML::HTML5::Table::Cell';

has '+default_alignment' => ( default   => 'center' );

1;
