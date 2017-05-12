package Lexical::Importer;
use 5.012;
use warnings;
use strict;

use Lexical::SealRequireHints 0.006;
use Importer 0.013;
use parent 'Importer';

our $VERSION = "0.000005";

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

our %IMPORTED;

sub import {
    my $class = shift;
    my $from = shift;
    my $into = caller;
    $class->SUPER::import_into($from, $into, \&set_symbol, @_);
}

sub set_symbol {
    my ($name, $ref, %info) = @_;
    push @{$IMPORTED{$info{into}}} => $name if $info{sig} eq '&';
    __PACKAGE__->_import_lex_var("$info{sig}$name" => $ref);
}

sub do_unimport {
    my $self = shift;

    my $from = $self->from;
    my $imported = $IMPORTED{$from} or $self->croak("'$from' does not have any lexical imports to remove");

    my %allowed = map { $_ => 1 } @$imported;

    my @args = @_ ? @_ : @$imported;

    $self->_unimport_lex_sub($_) for @args;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lexical::Importer - Importer + Lexical subs/vars.

=head1 DESCRIPTION

This is a subclass of L<Importer> which will import all symbols as lexicals
instead of package symbols.

=head1 IMPORTANT NOTE

This imports symbols into the currently compiling scope which is not
necessarily the same as the package doing the importing.

=head1 SYNOPSIS

Say you have a module, C<Foo.pm>:

    package Foo

    use base 'Exporter';
    our @EXPORT = qw/foo/;

    sub foo { 'foo' }

You want to import C<foo()> to use, but you also have your own C<foo()> method
you do not want to squash in C<Your::Module.pm>

    # Define package versions first
    sub foo { 'not lexical' }

    say foo(); # prints 'not lexical';

    {
        use Lexical::Importer Foo => 'foo';
        say foo(); # prints 'foo'
    }

    say foo(); # prints 'not lexical' again;

    use Lexical::Importer Foo => 'foo';
    say foo(); # prints 'foo'

    say __PACKAGE__->foo(); # prints 'not lexical', method dispatch find package sub.

    # Remove lexical subs
    no Lexical::Importer;
    say foo(); # prints 'not lexical' again;

=head1 IMPORTER

This package inherits from L<Importer> and works exactly the same apart from
being lexical instead of modifying the symbol table.

=head1 SEE ALSO

L<Importer> - The importer module this package subclasses

L<Lexical::Var> and L<Lexical::Sub> - The awesome modules Zefram wrote that
make this possible. I<Note: Lexical::Importer ships with a forked copy of these>

L<Lexical::Import> - A similar module, but it does not support everything
L<Lexical::Importer> does.

=head1 LEXICAL-VAR FORK

The L<Lexical::Importer> module is bundled with a fork of the L<Lexical::Var> XS
code. This fork is necessary due to L<Lexical::Var> being broken on newer
perls. The author of the original package is not accepting third party patches,
and has not yet fixed the issues himself. Once a version of L<Lexical::Var>
ships with a fix for newer perls this fork will likely be removed.

=head2 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head2 COPYRIGHT

Copyright (C) 2009, 2010, 2011, 2012, 2013
Andrew Main (Zefram) <zefram@fysh.org>

=head2 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SOURCE

The source code repository for Lexical-Importer can be found at
F<https://github.com/exodist/Lexical-Importer>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2016 Chad Granum E<lt>exodist@cpan.orgE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
