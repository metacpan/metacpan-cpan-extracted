use 5.006; use strict; use warnings;

package JSON::ToHTML;

our $VERSION = '0.001';

use Scalar::Util ();

sub json_object_to_html;
sub json_array_to_html;

sub json_values_to_html {
	my $copy;
	map +(
		( not defined $_ )                   ? '<i>null</i>'
		: 'HASH'  eq ref $_                  ? json_object_to_html $_
		: 'ARRAY' eq ref $_                  ? json_array_to_html $_
		: eval { $$_ eq 1 or $$_ eq 0 }      ? ( $$_ ? '<i>true</i>' : '<i>false</i>' )
		: Scalar::Util::looks_like_number $_ ? qq'<div class="num">$_</div>'
		: grep s!([<>"'&@\x{80}-\x{10FFFF}])!'&#'.(ord $1).';'!ge || 1, $copy = $_
	), @_
}

sub json_identical_keys {
	return if grep 'HASH' ne ref, @_;
	my $keyset = join ':', map length . $_, my @sk = sort keys %{ shift @_ };
	$keyset eq ( join ':', map length . $_, sort keys %$_ ) or return for @_;
	@sk;
}

sub json_object_to_html {
	my ( $o ) = @_;

	my @sk = sort keys %$o;
	return '<i>empty&#160;object</i>' unless @sk;

	my @ik = @sk > 1 ? json_identical_keys values %$o : ();
	return
		( '<table class="table"><tr><th><i>key</i></th><th>'
		. ( join '</th><th>', json_values_to_html @ik )
		. '</th></tr><tr><td>'
		. ( join '</td></tr><tr><td>', map join( '</td><td>', json_values_to_html $_, @{ $o->{$_} }{ @ik } ), @sk )
		. '</td></tr></table>'
	) if @ik;

	my @k = json_values_to_html @sk;
	my @v = json_values_to_html @$o{ @sk };
	join '', '<table class="object">', ( map "<tr><th>$k[$_]</th><td>$v[$_]</td></tr>", 0 .. $#k ), '</table>'
}

sub json_array_to_html {
	my ( $a ) = @_;

	return '<table class="table"><tr><td><i>empty&#160;array</i></td></tr></table>' unless @$a;

	my @ik = json_identical_keys @$a;
	return
		( '<table class="table"><tr><th class="num"><i>#</i></th><th>'
		. ( join '</th><th>', json_values_to_html @ik )
		. '</th></tr><tr><td class="num">'
		. ( join '</td></tr><tr><td class="num">', map join( '</td><td>', "<i>$_</i>", json_values_to_html @{ $a->[$_] }{ @ik } ), 0 .. $#$a )
		. '</td></tr></table>'
	) if @ik;

	my $i;
	join '', (
		'<table class="array">',
		( map '<tr><td><div class="num"><i>'.$i++.qq'</i></div></td><td>$_</td></tr>', json_values_to_html @$a ),
		'</table>',
	);
}

1;

__END__

=pod

=head1 NAME

JSON::ToHTML - render JSON-based Perl datastructures as HTML tables

=head1 DESCRIPTION

This module will provide functions to render JSON-based Perl datastructures
as HTML tables which do not look like code.
The focus is on the display of regular tabular datastructures such as database
resultsets to non- (or not particularly) technical users.

=head1 AUTHOR

Aristotle Pagaltzis <pagaltzis@gmx.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Aristotle Pagaltzis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
