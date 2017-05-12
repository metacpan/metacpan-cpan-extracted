package Exporter::AutoClean;
use strict;
use warnings;
use B::Hooks::EndOfScope;

our $VERSION = '0.01';

sub export {
    my $class   = shift;
    my $pkg     = shift;
    my %exports = @_;

    no strict 'refs';
    while (my ($name, $code) = each %exports) {
        *{"${pkg}::${name}"} = $code;
    }

    on_scope_end {
        for my $name (keys %exports) {
            delete ${ $pkg . '::' }{ $name };
        }
    };
}

1;

__END__

=head1 NAME

Exporter::AutoClean - export instant functions available at compile time only

=head1 SYNOPSIS

    use Exporter::AutoClean;
    
    sub import {
        my $caller = caller;
        Exporter::AutoClean->export( $caller, sub_name => sub { # code... } );
    }

=head1 DESCRIPTION

This is a simple wrapper module of L<B::Hooks::EndOfScope>, allows you to export instant functions that is only available at compile time.

=head1 SEE ALSO

L<B::Hooks::EndOfScope>, L<namespace::autoclean>.

=head1 METHOD

=head2 Exporter::AutoClean->export( $package, %export_functions );

    Exporter::AutoClean->export(
        $caller,
        function_name1 => sub { # code },
        function_name2 => \&code,
        :
    );

Export instant functions described C<%export_functions> to C<$package>.
These functions are automatically removed when compile time is done.

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009 by KAYAC Inc.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
