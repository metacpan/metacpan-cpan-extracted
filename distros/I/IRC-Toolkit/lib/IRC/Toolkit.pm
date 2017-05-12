package IRC::Toolkit;
$IRC::Toolkit::VERSION = '0.092002';
use strictures 2;
use Carp;

## Core bits can be added to this list ...
## ... but removing modules will break stuff downstream
my @modules = qw/
  Case
  Colors
  CTCP
  ISupport
  Masks
  Modes
  Parser
/;

sub import {
  my ($self, @load) = @_;
  @load = @modules unless @load;
  my $pkg = caller;
  my @failed;
  for my $mod (@load) {
    my $ld = "package $pkg; use IRC::Toolkit::$mod; 1;";
    eval $ld and not $@ or warn "$@\n" and push @failed, $mod;
  }
  confess "Failed to import ".join ' ', @failed if @failed;
  1
}

print
 qq[<Gilded> #otw also known as the "Welcome To Every Watchlist Channel"\n],
 qq[<Capn_Refsmmat> #otw: On The Watchlist\n]
unless caller; 1;


=pod

=head1 NAME

IRC::Toolkit - Useful IRC objects and utilities

=head1 SYNOPSIS

  ## Import the most commonly used Tookit:: modules
  ##  (Case, Colors, CTCP, ISupport, Masks, Modes, Parser)
  use IRC::Toolkit;

  ## Import a list of modules:
  use IRC::Toolkit qw/
    CTCP
    Masks
    Modes
    Numerics
  /;

  ## ... or individually:
  use IRC::Toolkit::Numerics;

=head1 DESCRIPTION

A collection of useful IRC-related utilities. See their respective
documentation, below.

Modules that export functions use L<Exporter::Tiny>, which is quite flexible;
see the L<Exporter::Tiny> docs for details.

L<IRC::Message::Object>; Objects representing incoming or outgoing IRC events

L<IRC::Mode::Single>; Objects representing a single mode change

L<IRC::Mode::Set>; Objects representing a set of mode changes

L<IRC::Toolkit::Case>; RFC-compliant case folding tools

L<IRC::Toolkit::Colors>; Color/format code interpolation & removal

L<IRC::Toolkit::CTCP>; CTCP quoting and extraction tools

L<IRC::Toolkit::ISupport>; ISUPPORT (numeric 005) parser

L<IRC::Toolkit::Masks>; Hostmask parsing and matching tools

L<IRC::Toolkit::Modes>; Mode-line parsing tools

L<IRC::Toolkit::Numerics>; IRC numerics translation to/from RPL or ERR names

L<IRC::Toolkit::Parser>; Functional interface to L<POE::Filter::IRCv3>

L<IRC::Toolkit::TS6>; Produce sequential TS6 IDs

L<IRC::Toolkit::Role::CaseMap>; A Role for classes that track IRC casemapping
settings

=head1 SEE ALSO

L<IRC::Utils>

L<Parse::IRC>

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Portions of code are derived from L<IRC::Utils>, L<Net::IRC>, and
L<POE::Filter::IRC::Compat>, which are copyright their respective authors;
these items are documented where they are found.

Licensed under the same terms as Perl.

=cut

