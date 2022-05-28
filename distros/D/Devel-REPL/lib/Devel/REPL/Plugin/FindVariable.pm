use strict;
use warnings;
package Devel::REPL::Plugin::FindVariable;
# ABSTRACT: Finds variables by name

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;

sub find_variable {
    my ($self, $name) = @_;

    return \$self if $name eq '$_REPL';

    # XXX: this code needs to live in LexEnv
    if ($self->can('lexical_environment')) {
        return \( $self->lexical_environment->get_context('_')->{$name} )
            if exists $self->lexical_environment->get_context('_')->{$name};
    }

    my $sigil = $name =~ s/^([\$\@\%\&\*])// ? $1 : '';

    my $default_package = $self->can('current_package')
                        ? $self->current_package
                        : 'main';
    my $package = $name =~ s/^(.*)(::|')// ? $1 : $default_package;

    my $meta = Class::MOP::Class->initialize($package);

    # Class::MOP::Package::has_package_symbol method *requires* a sigil
    return unless length($sigil) and $meta->has_package_symbol("$sigil$name");
    $meta->get_package_symbol("$sigil$name");
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::FindVariable - Finds variables by name

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
