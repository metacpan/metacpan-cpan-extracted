package HTML::Entities::Interpolate;

#use strict;
use warnings;

use HTML::Entities;
use Tie::Function;

our $VERSION = '1.10';

# -----------------------------------------------

tie my %Entitize, 'Tie::Function' => \&encode_entities;

sub import{*{caller().'::Entitize'} = \%Entitize};

# -----------------------------------------------

1;

__END__

=head1 NAME

HTML::Entities::Interpolate - Call HTML::Entities::encode_entities, via a hash, within a string

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use HTML::Entities::Interpolate;

	# ------------------------------

	my($block_1) = '<p>Para One</p>';
	my($block_2) = "<p align='center'>Para Two</p>";
	my($block_3) = 'http://tipjar.com/bin/test?foo=bar&reg=inald';
	my($block_4) = $Entitize{$block_3};

	print <<EOS;
	<html>
		<head>
			<title>Test HTML::Entities::Interpolate</title>
		</head>
		<body>
			<h1 align='center'>HTML::Entities::Interpolate</h1>
			<form action='#'>
			<table align='center'>
			<tr>
				<td align='center'>Input: <input name='data' value='$Entitize{$block_1}'></td>
			</tr>
			<tr>
				<td align='center'><br>The full text of the block is <pre>$Entitize{$block_2}</pre></td>
			</tr>
			<tr>
				<td align='center'><br>Check out the web page at: <a href='$block_3'>$block_4</a></td>
			</tr>
			</table>
			</form>
		</body>
	</html>
	EOS

=head1 Description

C<HTML::Entities::Interpolate> is a pure Perl module.

=head1 Constructor and initialization

Not needed.

=head1 See Also

L<HTML::Entities>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Repository

L<https://github.com/ronsavage/HTML-Entities-Interpolate>

=head1 Support

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML::Entities::Interpolate>.

=head1 Author

David Nicol <davidnicol@gmail.com>.

Maintainer: Ron Savage I<E<lt>ron@savage.net.auE<gt>>.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
