#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Language::Befunge::lib::NULL;
# ABSTRACT: Extension to opacify loaded extensions
$Language::Befunge::lib::NULL::VERSION = '5.000';
sub new { return bless {}, shift; }


# basic IP reflection
sub _reverse {
    my (undef, $interp) = @_;
	$interp->get_curip->dir_reverse;
}

#
# for each of the library instructions, override it with a reflection.
#
BEGIN {
	for my $l ( 'A'..'Z' ) {
		eval "*$l = \\&_reverse";
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::NULL - Extension to opacify loaded extensions

=head1 VERSION

version 5.000

=head1 DESCRIPTION

After successfully loading this extension (fingerprint 0x4e554c4c), all 26
instructions A to Z take the semantics of r.

This can be loaded before loading a regular transparent fingerprint to make
it act opaquely.

=head1 FUNCTIONS

=head2 new

Create a new NULL instance.

=head2 Opacification

=over 4

=item A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

All the library instructions reflect current IP (same as instruction C<r>).

=back

=head1 SEE ALSO

L<http://catseye.tc/projects/funge98/library/NULL.html>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
