use Demo_REM;

=head1 A demo

	print if /^(%d|![a])/;

=cut

while (<>) {
	print if /^(%d|![a])/;
}

__DATA__

	print if /^(%d|![a])/;
