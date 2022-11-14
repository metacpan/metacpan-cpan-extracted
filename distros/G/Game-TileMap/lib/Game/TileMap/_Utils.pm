package Game::TileMap::_Utils;
$Game::TileMap::_Utils::VERSION = '0.001';
use v5.10;
use strict;
use warnings;

sub trim
{
	my $str = shift;
	$str =~ s/\A \s+ | \s+ \z//gx;
	return $str;
}

1;

