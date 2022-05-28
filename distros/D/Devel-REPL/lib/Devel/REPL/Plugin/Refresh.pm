use strict;
use warnings;
package Devel::REPL::Plugin::Refresh;
# ABSTRACT: Reload libraries with Module::Refresh

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;
use Module::Refresh;

# before evaluating the code, ask Module::Refresh to refresh
# the modules that have changed
around 'eval' => sub {
    my $orig = shift;
    my ($self, $line) = @_;

    # first refresh the changed modules
    Module::Refresh->refresh;

    # the eval the code
    return $self->$orig($line);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Refresh - Reload libraries with Module::Refresh

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
