package IRC::Toolkit::Masks;
$IRC::Toolkit::Masks::VERSION = '0.092002';
use Carp;
use strictures 2;

use parent 'Exporter::Tiny';
our @EXPORT = qw/
  matches_mask
  normalize_mask
  parse_user
/;

use IRC::Toolkit::Case;


sub matches_mask {
  ## Imported from IRC::Utils:
  my ($mask, $nuh, $casemap) = @_;
  confess "Expected a mask, a string to match, and optional casemap"
    unless length $mask and defined $nuh;

  my $quoted = quotemeta uc_irc $mask, $casemap;
  $quoted =~ s/\\\*/[\x01-\xFF]{0,}/g;
  $quoted =~ s/\\\?/[\x01-\xFF]{1,1}/g;

  !! ( uc_irc($nuh, $casemap) =~ /^$quoted$/ )
}

sub normalize_mask {
  my ($orig) = @_;
  confess "normalize_mask expected a mask" unless defined $orig;

  ## Inlined with some tweaks from IRC::Utils

  ## **+ --> *
  $orig =~ s/\*{2,}/*/g;

  my ($piece, @mask);
  if ( index($orig, '!') == -1 && index($orig, '@') > -1) {
    # no nick, add '*'
    $piece = $orig;
    @mask  = '*';
  } else {
    ($mask[0], $piece) = split /!/, $orig, 2;
  }

  ## user/host
  if (defined $piece) {
    $piece      =~ s/!//g;
    @mask[1, 2] = split /@/, $piece, 2;
  }
  $mask[2] =~ s/@//g if defined $mask[2];

  $mask[0] 
  # defined+length is annoying but elsewise we get fatal warnings on 5.10
  . '!' . (defined $mask[1] && length $mask[1] ? $mask[1] : '*' )
  . '@' . (defined $mask[2] && length $mask[2] ? $mask[2] : '*' )
}

sub parse_user {
  my ($full) = @_;

  confess "parse_user() called with no arguments"
    unless defined $full;

  my ($nick, $user, $host) = split /[!@]/, $full;

  wantarray ? ($nick, $user, $host) : $nick
}


1;

=pod

=head1 NAME

IRC::Toolkit::Masks - IRC mask-related utilities

=head1 SYNOPSIS

  use IRC::Toolkit::Masks;
  
  my $mask = '*!avenj@*.cobaltirc.org';
  my $full = 'avenj!avenj@eris.cobaltirc.org';
  my $casemap = 'rfc1459';
  if ( matches_mask($mask, $full, $casemap) ) {
    ...
  }

  my $bmask = normalize_mask( 'somenick' );  # somenick!*@*
  my $bmask = normalize_mask( 'user@host' ); # *!user@host

  my ($nick, $user, $host) = parse_user( $full );
  my $nick = parse_user( $full );

=head1 DESCRIPTION

IRC mask manipulation utilities derived from L<IRC::Utils>.

=head2 matches_mask

Takes an IRC mask, a string to match it against, and an optional IRC casemap
(see L<IRC::Toolkit::Case>).

Returns boolean true if the match applies successfully.

=head2 normalize_mask

Takes an IRC mask and returns the "normalized" version of the mask.

=head2 parse_user

Splits an IRC mask into components.

Returns all available pieces (nickname, username, and host, if applicable) in
list context.

Returns just the nickname in scalar context.

=head1 AUTHOR

Mask-matching and normalization code derived from L<IRC::Utils>, 
copyright Chris Williams, HINRIK et al.

Jon Portnoy <avenj@cobaltirc.org>

=cut

