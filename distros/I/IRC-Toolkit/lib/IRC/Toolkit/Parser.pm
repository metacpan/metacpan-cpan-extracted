package IRC::Toolkit::Parser;
$IRC::Toolkit::Parser::VERSION = '0.092002';
use Carp;
use strictures 2;

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  irc_ref_from_line
  irc_line_from_ref
/;

use Scalar::Util 'blessed', 'reftype';

use POE::Filter::IRCv3;
my $filter = 'POE::Filter::IRCv3';

sub irc_ref_from_line {
  my $line = shift;
  confess "Expected a line and optional filter arguments"
    unless $line;
  $filter->new(@_)->get([$line])->[0]
}

sub irc_line_from_ref {
  my $ref = shift;
  confess "Expected a HASH and optional filter arguments"
    unless reftype $ref eq 'HASH';
  $filter->new(@_)->put([blessed $ref ? +{%$ref} : $ref])->[0]
}

=pod

=head1 NAME

IRC::Toolkit::Parser - Functional-style IRC filter interface

=head1 SYNOPSIS

  use IRC::Toolkit::Parser;

  my $raw_irc_line = ':avenj PRIVMSG #channel :things';
  my $ref = irc_ref_from_line( $raw_irc_line );
  my $raw_line = irc_line_from_ref( $ref, colonify => 1 );

=head1 DESCRIPTION

A simple functional-style frontend to L<POE::Filter::IRCv3>.

This will be slower than using the filter directly, but it's convenient for
one-offs.

See L<POE::Filter::IRCv3> for details.

Also see L<IRC::Message::Object> for a handy object-oriented interface to IRC
event transformation.

=head2 irc_ref_from_line

Takes a raw IRC line and returns a HASH as described in the documentation for 
L<POE::Filter::IRCv3>.

=head2 irc_line_from_ref

Takes a HASH as described in L<POE::Filter::IRCv3> and returns a raw IRC line.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut

1;
