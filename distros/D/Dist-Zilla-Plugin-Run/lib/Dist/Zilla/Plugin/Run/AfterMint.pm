use strict;
use warnings;

package Dist::Zilla::Plugin::Run::AfterMint;
# ABSTRACT: Execute a command after a new distribution is minted

our $VERSION = '0.050';

use Moose;
with qw(
  Dist::Zilla::Role::AfterMint
  Dist::Zilla::Plugin::Run::Role::Runner
);

use namespace::autoclean;

sub after_mint {
  my ($self, $param) = @_;
  $self->_call_script({
    dir     => $param->{mint_root},
    minting => 1,
  });
}

#pod =head1 SYNOPSIS
#pod
#pod   [Run::AfterMint]
#pod   run = some command %d
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin executes the specified command after minting a new distribution.
#pod
#pod =head1 CONVERSIONS
#pod
#pod See L<Dist::Zilla::Plugin::Run/CONVERSIONS>
#pod for the list of common formatting variables available to all plugins.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Run::AfterMint - Execute a command after a new distribution is minted

=head1 VERSION

version 0.050

=head1 SYNOPSIS

  [Run::AfterMint]
  run = some command %d

=head1 DESCRIPTION

This plugin executes the specified command after minting a new distribution.

=head1 CONVERSIONS

See L<Dist::Zilla::Plugin::Run/CONVERSIONS>
for the list of common formatting variables available to all plugins.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Run>
(or L<bug-Dist-Zilla-Plugin-Run@rt.cpan.org|mailto:bug-Dist-Zilla-Plugin-Run@rt.cpan.org>).

There is also a mailing list available for users of this distribution, at
L<http://dzil.org/#mailing-list>.

There is also an irc channel available for users of this distribution, at
L<C<#distzilla> on C<irc.perl.org>|irc://irc.perl.org/#distzilla>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2010 by L<Raudssus Social Software|https://raudss.us/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
