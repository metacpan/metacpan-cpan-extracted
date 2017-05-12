package IRC::Toolkit::CTCP;
$IRC::Toolkit::CTCP::VERSION = '0.092002';
use strictures 2;
use Carp 'confess';

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  ctcp_quote
  ctcp_unquote
  ctcp_extract
/;

use IRC::Message::Object 'ircmsg';

use Scalar::Util 'blessed';

my %quote = (
  "\012" => 'n',
  "\015" => 'r',
  "\0"   => '0',
  "\cP"  => "\cP",
);
my %dequote = reverse %quote;

## CTCP handling logic borrowed from POE::Filter::IRC::Compat  /  Net::IRC
##  (by BinGOs, fimm, Abigail et al)

sub ctcp_quote {
  my ($line) = @_;
  confess "Expected a line" unless defined $line;

  if ($line =~ tr/[\012\015\0\cP]//) {
    $line =~ s/([\012\015\0\cP])/\cP$quote{$1}/g;
  }

  $line =~ s/\001/\\a/g;
  "\001$line\001"
}

sub ctcp_unquote {
  my ($line) = @_;
  confess "Expected a line" unless defined $line;

  if ($line =~ tr/\cP//) {
    $line =~ s/\cP([nr0\cP])/$dequote{$1}/g;
  }

  substr $line, rindex($line, "\001"), 1, '\\a' 
    if ($line =~ tr/\001//) % 2 != 0;
  return unless $line =~ tr/\001//;

  my @chunks = split /\001/, $line;
  shift @chunks unless length $chunks[0];
  ## De-quote / convert escapes
  s/\\([^\\a])/$1/g, s/\\\\/\\/g, s/\\a/\001/g for @chunks;

  my (@ctcp, @text);

  ## If we start with a ctrl+A, the first chunk is CTCP:
  if (index($line, "\001") == 0) {
    push @ctcp, shift @chunks;
  }
  ## Otherwise we start with text and alternate CTCP:
  while (@chunks) {
    push @text, shift @chunks;
    push @ctcp, shift @chunks if @chunks;
  }

  +{ ctcp => \@ctcp, text => \@text }
}

sub ctcp_extract {
  my ($input) = @_;

  unless (blessed $input && $input->isa('IRC::Message::Object')) {
    $input = ref $input ? 
      ircmsg(%$input) : ircmsg(raw_line => $input)
  }

  my $type = uc($input->command) eq 'PRIVMSG' ? 'ctcp' : 'ctcpreply' ;
  my $line = $input->params->[1];
  my $unquoted = ctcp_unquote($line);
  return unless $unquoted and @{ $unquoted->{ctcp} };

  my ($name, $params);
  CTCP: for my $str ($unquoted->{ctcp}->[0]) {
    ($name, $params) = $str =~ /^(\w+)(?: +(.*))?/;
    last CTCP unless $name;
    $name = lc $name;
    if ($name eq 'dcc') {
      ## Does no extra work to parse DCC
      ## ... but see POE::Filter::IRC::Compat for that
      my ($dcc_type, $dcc_params) = $params =~ /^(\w+) +(.+)/;
      last CTCP unless $dcc_type;
      return ircmsg(
        ( $input->prefix ? (prefix => $input->prefix) : () ),
        command => 'dcc_request_'.lc($dcc_type),
        params  => [
          $input->prefix,
          $dcc_params
        ],
        raw_line => $input->raw_line,
      )
    } else {
      return ircmsg(
        ( $input->prefix ? (prefix => $input->prefix) : () ),
        command => $type .'_'. $name,
        params  => [
          $input->params->[0],
          ( defined $params ? $params : '' ),
        ],
        raw_line => $input->raw_line,
      )
    }
  }
  
  undef
}


1;

=pod

=head1 NAME

IRC::Toolkit::CTCP - CTCP parsing utilities

=head1 SYNOPSIS

  ## Extract first CTCP request/reply from a message:
  if (my $ctcp_ev = ctcp_extract( $orig_msg ) ) {
    ## CTCP was found; $ctcp_ev is an IRC::Message::Object
    ...
  }

  ## Properly CTCP-quote a string:
  my $quoted_ctcp = ctcp_quote("PING 1234");

  ## Deparse CTCP messages (including multipart):
  if (my $ref = ctcp_unquote($raw_line)) {
    my @ctcp = @{ $ref->{ctcp} };
    my @txt  = @{ $ref->{text} };
    ...
  }

=head1 DESCRIPTION

Utility functions useful for quoting/unquoting/extracting CTCP.

=head2 ctcp_extract

Takes input (in the form of an L<IRC::Message::Object> instance,
a hash such as that produced by L<POE::Filter::IRCv3>, or a
raw line) and attempts to extract a valid CTCP request or reply.

Returns an L<IRC::Message::Object> whose C<command> carries an
appropriate prefix (one of B<ctcp>, B<ctcpreply>, or B<dcc_request>) prepended
to the CTCP command:

  ## '$ev' is your incoming or outgoing IRC::Message::Object
  ## CTCP VERSION request:
  $ev->command eq 'ctcp_version' 

  ## Reply to CTCP VERSION:
  $ev->command eq 'ctcpreply_version'

  ## DCC SEND:
  $ev->command eq 'dcc_request_send' 

Returns C<undef> if no valid CTCP was found; this is a breaking change in
C<v0.91.2>, as previous versions returned the empty list.

=head2 ctcp_quote

CTCP quote a raw line.

=head2 ctcp_unquote

Deparses a raw line possibly containing CTCP.

Returns a hash with two keys, B<ctcp> and B<text>, whose values are 
ARRAYs containing the CTCP and text portions of a CTCP-quoted message.

Returns an empty list if no valid CTCP was found.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

Code derived from L<Net::IRC> and L<POE::Filter::IRC::Compat>, 
copyright BinGOs, HINRIK, fimm, Abigail et al

Licensed under the same terms as Perl.

=cut

