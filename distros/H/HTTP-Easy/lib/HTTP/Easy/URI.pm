package HTTP::Easy::URI;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = our @EXPORT_OK = qw(
	path_query url_escape url_unescape url_params url_query url_split
);

sub path_query($) {
	return substr( $_[0], index($_[0],"/",8) ) || "/";
}
sub url_escape {
	my ($string) = @_;
	$string =~ s/([^A-Za-z0-9\-._~ ])/sprintf('%%%02X',ord($1))/ge;
	$string =~ s{ }{+}sg;
	return $string;
}
sub url_unescape {
	my $string = shift;
	$string =~ s{\+}{ }sg;
	return $string if index($string, '%') == -1;
	$string =~ s/%([[:xdigit:]]{2})/chr(hex($1))/sge;
	return $string;
}
sub url_params {
	+{ map { my ($k,$v) = map { url_unescape $_ } split /=/,$_,2; +( $k => $v ) } split /&/, $_[0] };
}

sub url_query {
	join('&',map { url_escape($_).'='.url_escape( $_[0]{$_} ) } keys %{ $_[0] } );
}

sub url_split {
	my $url = shift;
	if (( my $i = index( $url, '?') )>-1) {
		my $args = substr( $url, $i+1 );
		$url = substr( $url, 0, $i );
		return $url,url_params($args);
	} else {
		return $url, {};
	}
}

1;
