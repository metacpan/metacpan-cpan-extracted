package Langertha::Holmgang::Template;
# ABSTRACT: Kolon output templates of handlers and observations

use strict;
use warnings;
use utf8;

use Exporter qw( import );
use Text::Xslate ();
use Langertha::Holmgang::Expectation qw( same_scalar );
use Langertha::Holmgang::Simulators;

our $VERSION = '0.002';

our @EXPORT_OK = qw( render );


# the compiler with the fixed function table; the registry for nft_verdict comes
# per render through $SIMULATORS
my $TX;
our $SIMULATORS;

sub _tx {
  return $TX //= Text::Xslate->new(
    syntax   => 'Kolon',
    type     => 'text',
    cache    => 0,
    verbose  => 0,
    function => {
      re  => sub { my ( $s, $re ) = @_; return defined $s && !ref $s && $s =~ /$re/ ? 1 : 0 },
      cap => sub { my ( $s, $re ) = @_; return defined $s && !ref $s && $s =~ /$re/ ? $1 // '' : '' },
      has => sub { my ( $l, $v ) = @_; return ref $l eq 'ARRAY' && ( grep { same_scalar( $_, $v ) } @$l ) ? 1 : 0 },
      pad => sub { my ( $s, $n ) = @_; $s //= ''; my $fill = $n - length $s; return $s.( $fill > 0 ? ' ' x $fill : '' ) },
      nft_verdict => sub {
        my ( $dev, $pkt ) = @_;
        return '' unless ref $dev eq 'HASH' && ref $pkt eq 'HASH';
        my $sims = $SIMULATORS // Langertha::Holmgang::Simulators->new;
        my ( $v ) = eval { $sims->packet_verdict( $dev, $pkt ) };
        return $v // '';
      },
    },
  );
}


sub render {
  my ( $tmpl, $state, $args, $sims ) = @_;
  return 'ok' unless defined $tmpl;
  return $tmpl unless $tmpl =~ /<:|^\s*:/m;
  local $SIMULATORS = $sims;
  return _tx()->render_string( $tmpl, { state => $state, args => $args // {} } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Holmgang::Template - Kolon output templates of handlers and observations

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Langertha::Holmgang::Template qw( render );

  my $text = render( "<: $state.lampe.an :>\n", $state, \%args );
  my $text = render( $template, $state, \%args, $simulators );   # nft_verdict through this registry

=head1 DESCRIPTION

The C<output> of a handler or an observation is a Kolon template
(L<Text::Xslate>, type C<text>, so nothing is HTML-escaped), rendered with two
variables, C<$state> (the whole state, after the handler's change) and
C<$args> (the call's arguments plus the named captures of C<match>), and these
functions:

=over 4

=item C<re($text, $pattern)>

C<1> when the text matches the Perl regular expression, else C<0>.

=item C<cap($text, $pattern)>

The first capture group of the match, or C<''>.

=item C<has($list, $value)>

C<1> when the list holds the value (numbers numerically, text exactly).

=item C<pad($text, $width)>

The text left-aligned and padded with blanks to C<$width>.

=item C<nft_verdict($device, \%packet)>

C<accept> or C<drop>: what the packet filter of the device does with the
packet, asked through the simulator registry
(L<Langertha::Holmgang::Simulators/packet_verdict>); C<''> when the device's
simulator cannot answer or a rule on the way cannot be evaluated.

=back

A text without Kolon markers (C<< <: >> or a line starting with C<:>) comes
back as it is; no template at all renders as C<ok>.

A plain function module: the Linux simulator renders the start messages of its
services through L</render> too.

=head2 render

  my $text = render( $template, $state, \%args, $simulators );

Renders the template with C<$state> and C<$args> (default C<{}>).
C<$simulators> is the registry C<nft_verdict> asks; without it a fresh
L<Langertha::Holmgang::Simulators>. Dies when the template does not compile.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/langertha-holmgang/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
