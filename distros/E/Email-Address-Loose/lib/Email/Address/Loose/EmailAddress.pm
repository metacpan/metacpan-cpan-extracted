package Email::Address::Loose::EmailAddress;

## no critic
use base 'Email::Address'; # for isa("Email::Address");
use Email::Address::Loose::EmailValidLoose;

# Note:
# The following code were copied from Email::Address 1.892.
# http://search.cpan.org/perldoc?Email::Address
# To make same behavior with Email::Address escept local-part.




use strict;
## no critic RequireUseWarnings
# support pre-5.6

use vars qw[$VERSION $COMMENT_NEST_LEVEL $STRINGIFY
            $COLLAPSE_SPACES
            %PARSE_CACHE %FORMAT_CACHE %NAME_CACHE
            $addr_spec $angle_addr $name_addr $mailbox];

my $NOCACHE;

$VERSION              = '1.892';
$COMMENT_NEST_LEVEL ||= 2;
$STRINGIFY          ||= 'format';
$COLLAPSE_SPACES      = 1 unless defined $COLLAPSE_SPACES; # who wants //=? me!


my $CTL            = q{\x00-\x1F\x7F};
my $special        = q{()<>\\[\\]:;@\\\\,."};

my $text           = qr/[^\x0A\x0D]/;

my $quoted_pair    = qr/\\$text/;

my $ctext          = qr/(?>[^()\\]+)/;
my ($ccontent, $comment) = (q{})x2;
for (1 .. $COMMENT_NEST_LEVEL) {
  $ccontent = qr/$ctext|$quoted_pair|$comment/;
  $comment  = qr/\s*\((?:\s*$ccontent)*\s*\)\s*/;
}
my $cfws           = qr/$comment|\s+/;

my $atext          = qq/[^$CTL$special\\s]/;
my $atom           = qr/$cfws*$atext+$cfws*/;
my $dot_atom_text  = qr/$atext+(?:\.$atext+)*/;
my $dot_atom       = qr/$cfws*$dot_atom_text$cfws*/;

my $qtext          = qr/[^\\"]/;
my $qcontent       = qr/$qtext|$quoted_pair/;
my $quoted_string  = qr/$cfws*"$qcontent+"$cfws*/;

my $word           = qr/$atom|$quoted_string/;

# XXX: This ($phrase) used to just be: my $phrase = qr/$word+/; It was changed
# to resolve bug 22991, creating a significant slowdown.  Given current speed
# problems.  Once 16320 is resolved, this section should be dealt with.
# -- rjbs, 2006-11-11
#my $obs_phrase     = qr/$word(?:$word|\.|$cfws)*/;

# XXX: ...and the above solution caused endless problems (never returned) when
# examining this address, now in a test:
#   admin+=E6=96=B0=E5=8A=A0=E5=9D=A1_Weblog-- ATAT --test.socialtext.com
# So we disallow the hateful CFWS in this context for now.  Of modern mail
# agents, only Apple Web Mail 2.0 is known to produce obs-phrase.
# -- rjbs, 2006-11-19
my $simple_word    = qr/$atom|\.|\s*"$qcontent+"\s*/;
my $obs_phrase     = qr/$simple_word+/;

my $phrase         = qr/$obs_phrase|(?:$word+)/;

my $local_part     = qr/$dot_atom|$quoted_string/;
$local_part = Email::Address::Loose::EmailValidLoose->peek_local_part; # Note: added by Email::Address::Loose

my $dtext          = qr/[^\[\]\\]/;
my $dcontent       = qr/$dtext|$quoted_pair/;
my $domain_literal = qr/$cfws*\[(?:\s*$dcontent)*\s*\]$cfws*/;
my $domain         = qr/$dot_atom|$domain_literal/;

my $display_name   = $phrase;


$addr_spec  = qr/$local_part\@$domain/;
$angle_addr = qr/$cfws*<$addr_spec>$cfws*/;
$name_addr  = qr/$display_name?$angle_addr/;
$mailbox    = qr/(?:$name_addr|$addr_spec)$comment*/;

sub _PHRASE   () { 0 }
sub _ADDRESS  () { 1 }
sub _COMMENT  () { 2 }
sub _ORIGINAL () { 3 }
sub _IN_CACHE () { 4 }


sub __get_cached_parse {
    return if $NOCACHE;

    my ($class, $line) = @_;

    return @{$PARSE_CACHE{$line}} if exists $PARSE_CACHE{$line};
    return; 
}

sub __cache_parse {
    return if $NOCACHE;
    
    my ($class, $line, $addrs) = @_;

    $PARSE_CACHE{$line} = $addrs;
}

sub parse {
    my ($class, $line) = @_;
    $class = 'Email::Address::Loose' if $class eq 'Email::Address'; # Note: added by Email::Address::Loose

    return unless $line;

    $line =~ s/[ \t]+/ /g if $COLLAPSE_SPACES;

    if (my @cached = $class->__get_cached_parse($line)) {
        return @cached;
    }

    my (@mailboxes) = ($line =~ /$mailbox/go);
    my @addrs;
    foreach (@mailboxes) {
      my $original = $_;

      my @comments = /($comment)/go;
      s/$comment//go if @comments;

      my ($user, $host, $com);
      ($user, $host) = ($1, $2) if s/<($local_part)\@($domain)>//o;
      if (! defined($user) || ! defined($host)) {
          s/($local_part)\@($domain)//o;
          ($user, $host) = ($1, $2);
      }

      my ($phrase)       = /($display_name)/o;

      for ( $phrase, $host, $user, @comments ) {
        next unless defined $_;
        s/^\s+//;
        s/\s+$//;
        $_ = undef unless length $_;
      }

      my $new_comment = join q{ }, @comments;
      push @addrs,
        $class->new($phrase, "$user\@$host", $new_comment, $original);
      $addrs[-1]->[_IN_CACHE] = [ \$line, $#addrs ]
    }

    $class->__cache_parse($line, \@addrs);
    return @addrs;
}


sub new {
  my ($class, $phrase, $email, $comment, $orig) = @_;
  $phrase =~ s/\A"(.+)"\z/$1/ if $phrase;

  bless [ $phrase, $email, $comment, $orig ] => $class;
}


sub purge_cache {
    %NAME_CACHE   = ();
    %FORMAT_CACHE = ();
    %PARSE_CACHE  = ();
}


sub disable_cache {
  my ($class) = @_;
  $class->purge_cache;
  $NOCACHE = 1;
}

sub enable_cache {
  $NOCACHE = undef;
}


BEGIN {
  my %_INDEX = (
    phrase   => _PHRASE,
    address  => _ADDRESS,
    comment  => _COMMENT,
    original => _ORIGINAL,
  );

  for my $method (keys %_INDEX) {
    no strict 'refs';
    my $index = $_INDEX{ $method };
    *$method = sub {
      if ($_[1]) {
        if ($_[0][_IN_CACHE]) {
          my $replicant = bless [ @{$_[0]} ] => ref $_[0];
          $PARSE_CACHE{ ${ $_[0][_IN_CACHE][0] } }[ $_[0][_IN_CACHE][1] ] 
            = $replicant;
          $_[0][_IN_CACHE] = undef;
        }
        $_[0]->[ $index ] = $_[1];
      } else {
        $_[0]->[ $index ];
      }
    };
  }
}

sub host { ($_[0]->[_ADDRESS] =~ /\@($domain)/o)[0]     }
sub user { ($_[0]->[_ADDRESS] =~ /($local_part)\@/o)[0] }


sub format {
    local $^W = 0; ## no critic
    return $FORMAT_CACHE{"@{$_[0]}"} if exists $FORMAT_CACHE{"@{$_[0]}"};
    $FORMAT_CACHE{"@{$_[0]}"} = $_[0]->_format;
}

sub _format {
    my ($self) = @_;

    unless (
      defined $self->[_PHRASE] && length $self->[_PHRASE]
      ||
      defined $self->[_COMMENT] && length $self->[_COMMENT]
    ) {
        return $self->[_ADDRESS];
    }

    my $format = sprintf q{%s <%s> %s},
                 $self->_enquoted_phrase, $self->[_ADDRESS], $self->[_COMMENT];

    $format =~ s/^\s+//;
    $format =~ s/\s+$//;

    return $format;
}

sub _enquoted_phrase {
  my ($self) = @_;

  my $phrase = $self->[_PHRASE];

  # if it's encoded -- rjbs, 2007-02-28
  return $phrase if $phrase =~ /\A=\?.+\?=\z/;

  $phrase =~ s/\A"(.+)"\z/$1/;
  $phrase =~ s/\"/\\"/g;

  return qq{"$phrase"};
}


sub name {
    local $^W = 0;
    return $NAME_CACHE{"@{$_[0]}"} if exists $NAME_CACHE{"@{$_[0]}"};
    my ($self) = @_;
    my $name = q{};
    if ( $name = $self->[_PHRASE] ) {
        $name =~ s/^"//;
        $name =~ s/"$//;
        $name =~ s/($quoted_pair)/substr $1, -1/goe;
    } elsif ( $name = $self->[_COMMENT] ) {
        $name =~ s/^\(//;
        $name =~ s/\)$//;
        $name =~ s/($quoted_pair)/substr $1, -1/goe;
        $name =~ s/$comment/ /go;
    } else {
        ($name) = $self->[_ADDRESS] =~ /($local_part)\@/o;
    }
    $NAME_CACHE{"@{$_[0]}"} = $name;
}


sub as_string {
  warn 'altering $Email::Address::STRINGIFY is deprecated; subclass instead'
    if $STRINGIFY ne 'format';

  $_[0]->can($STRINGIFY)->($_[0]);
}

use overload '""' => 'as_string';


1;

