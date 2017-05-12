package Math::MultiplicationTable;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::MultiplicationTable ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

=item generate()

Generate 9 * 9 cells table as plain text.

=cut

=item generate($size)

Generate $size * $size size multiplication table as plain text.

=cut

sub generate
{
	my $size = (defined $_[0]) ? $_[0] : 9;
	my $ret = '';
	return undef if ($size < 0);
	return $ret if ($size == 0);
	
	my $figure = int(log($size ** 2) / log(10)) + 2;
	foreach my $r (1 .. $size){
		foreach my $c (1 .. $size){
			$ret .= sprintf "%".$figure."d", $r * $c;
		}
		$ret .= "\n";
	}
	
	return $ret;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Math::MultiplicationTable - Perl extension for generate multiplication table.

=head1 SYNOPSIS

	use Math::MultiplicationTable;
	print Math::MultiplicationTable::generate(9);

=head1 DESCRIPTION

Math::MultiplicationTable is just generate multiplication table.

=head2 EXPORT

None.

=head1 SEE ALSO

=head1 AUTHOR

pmint, E<lt>pmint@mx13.freecom.ne.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by pmint.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
