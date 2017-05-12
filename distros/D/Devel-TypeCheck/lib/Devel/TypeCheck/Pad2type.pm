package Devel::TypeCheck::Pad2type;

use strict;
use Devel::TypeCheck::Type;
use Devel::TypeCheck::Sym2type;
use Devel::TypeCheck::Util;
use B;
use IO::Handle;

=head1 NAME

Devel::TypeCheck::Pad2type - Symbol table for pads.

=head1 SYNOPSIS

Pad2type maintains a symbol table for pads, which are the lexically
scoped symbols are referenced.

=head1 DESCRIPTION

=over 4

=cut
our @ISA = qw(Devel::TypeCheck::Sym2type);

sub new {
    my ($name) = @_;
    return bless([], $name);
}

sub get {
    my ($this, $pad, $env) = @_;

    if (!exists($this->[$pad])) {
        $this->[$pad] = $env->fresh();
    }

    return $this->[$pad];
}

=item B<print>($fh, $cv, $env)

Print out this pad to the given file handle using the given CV and
type environment.

=cut
sub print {
    my ($this, $fh, $cv, $env) = @_;

    my ($i, $t);

    $fh->print("  Pad Table Types:\n  Name                Type\n  ----------------------------------------\n");

    format P2T =
  @<<<<<<<<<<<<<<<<<< @*
  $i,                 $t
.

    my %set;

    for my $j (0 .. $#$this) {
	next unless defined($this->[$j]);

	my $sv = (($cv->PADLIST()->ARRAY())[0]->ARRAY)[$j];
	$i = $sv->PVX;
	my $intro = $sv->NVX;
	my $finish = int($sv->IVX);
	$i .= ":$intro,$finish";

	$t = $this->[$j]->str($env);

	$fh->format_write("Devel::TypeCheck::Pad2type::P2T");
    }

    $fh->print("\n");
}

1;

=back

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
