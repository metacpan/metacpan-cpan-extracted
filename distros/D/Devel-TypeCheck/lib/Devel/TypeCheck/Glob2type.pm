package Devel::TypeCheck::Glob2type;

use strict;
use Carp;
use Devel::TypeCheck::Type;
use Devel::TypeCheck::Sym2type;

our @ISA = qw(Devel::TypeCheck::Sym2type);

=head1 NAME

Devel::TypeCheck::Sym2type - abstract parent to symbol table types.

=head1 SYNOPSIS

Devel::TypeCheck::Type is an abstract class and should not be
instantiated directly.  This defines the interface for symbol table
types, for keeping track of types in a symbol table.

=head1 DESCRIPTION

=over 4

=cut

=item B<get>

Retrieve a glob from the global table.

=cut
sub get {
    my ($this, $glob, $env) = @_;

    confess("env is null") if (!$env);

    if (!exists($this->{$glob})  || $glob eq "_") {
        $this->{$glob} = $env->freshEta;
    }

    return $this->{$glob};
}

=item B<symbols>

The list of all symbols tracked in this table.

=cut
sub symbols {
    my ($this) = @_;
    return keys(%$this);
}

1;

=back

=item B<del>

Remove a glob from the global table.  Used in an ad-hoc fashion to localize *_ in functions.

=cut
sub del {
    my ($this, $glob) = @_;

    delete($this->{$glob});
}

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
