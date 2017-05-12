package Devel::Eval;

=pod

=head1 NAME

Devel::Eval - Allows you to debug string evals

=head1 SYNOPSIS

  use Devel::Eval 'dval';
  
  dval "print 'Hello World!';";

=head1 DESCRIPTION

In the Perl debugger, code created via a string eval is effectively
invisible. You can run it, but the debugger will not be able to display
the code as it runs.

For modules that make heavy use of code generation, this can make
debugging almost impossible.

B<Devel::Eval> provides an alternative to string eval that will
do a string-eval equivalent, except that it will run the code via a
temp file.

Because the eval is being done though a physical file, the debugger will
be able to see this code and you can happily debug your generated code
as you do all the rest of your code.

=head1 FUNCTIONS

=cut

use 5.006;
use strict;
use Exporter   ();
use File::Temp ();

use vars qw{$VERSION @ISA @EXPORT $TRACE $UNLINK};
BEGIN {
	$VERSION = '1.01';
	@ISA     = 'Exporter';
	@EXPORT  = 'dval';
	$TRACE   = '' unless defined $TRACE;
	$UNLINK  = 1  unless defined $UNLINK;
}

=pod

=head2 dval

The C<dval> function takes a single parameter that should be the string
you want to eval, and executes it.

Because this is intended for code generation testing, your code is
expected to be safe to run via a 'require' (that is, it should return
true).

=cut

sub dval ($) {
	if ( $^V >= 5.008009 ) {
		pval(@_);
	} else {
		fval(@_);
	}
}

sub pval ($) {
	local $^P = $^P | 0x800;
	eval $_[0];
}

sub fval ($) {
	my ($fh, $filename) = File::Temp::tempfile();
	$fh->print("$_[0]") or die "print: $!";
	close( $fh )        or die "close: $!";
	my $message = "# do $filename\n";
	if ( defined $TRACE and not ref $TRACE ) {
		print STDOUT $message if $TRACE eq 'STDOUT';
		print STDERR $message if $TRACE eq 'STDERR';
	} elsif ( $TRACE ) {
		$TRACE->print($message);
	}
	do $filename;
	unlink $filename if $UNLINK;
	return 1;
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Eval>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>

=head1 COPYRIGHT

Copyright 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
