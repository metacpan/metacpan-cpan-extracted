package IRC::Toolkit::ISupport;
$IRC::Toolkit::ISupport::VERSION = '0.092002';
use strictures 2;

use Carp          'confess';
use Scalar::Util  'blessed';

use List::Objects::WithUtils;

use IRC::Message::Object 'ircmsg';


use parent 'Exporter::Tiny';
our @EXPORT = 'parse_isupport';


my $parse_simple_flags = sub {
  my ($val) = @_;
  +{ map {; $_ => 1 } split '', ( defined $val ? $val : '' ) }
};

my $parse = +{

  chanlimit => sub {
    my ($val) = @_;
    my $ref = {};
    for my $chunk (split /,/, $val) {
      my ($prefixed, $num) = split /:/, $chunk;
      for my $pfx (split '', $prefixed) {
        $ref->{$pfx} = $num
      }
    }
    $ref
  },

  chanmodes => sub {
    my ($val) = @_;
    my ($list, $always, $whenset, $bool) = split /,/, $val;
    +{
      list    => array( split '', ( defined $list    ? $list    : ''  ) ),
      always  => array( split '', ( defined $always  ? $always  : ''  ) ),
      whenset => array( split '', ( defined $whenset ? $whenset : ''  ) ),
      bool    => array( split '', ( defined $bool    ? $bool    : ''  ) ),
    }
  },

  chantypes => $parse_simple_flags,

  elist     => $parse_simple_flags,

  extban    => sub {
    my ($val) = @_;
    my ($prefix, $flags) = split /,/, $val;
    +{ 
      prefix => $prefix, 
      flags  => array( split '', ( defined $flags ? $flags : '' ) ),
    }
  },

  maxlist => sub {
    my ($val) = @_;
    my $ref = {};
    for my $chunk (split /,/, $val) {
      my ($modes, $num) = split /:/, $chunk;
      my @splitm = split '', $modes;
      for my $mode (@splitm) {
        $ref->{$mode} = $num
      }
    }
    $ref
  },

  prefix => sub {
    my ($val) = @_;
    my ($modes, $prefixes) = $val =~ /\(([^)]+)\)(.+)/;
    return +{} unless $modes and $prefixes;

    my @modes = split '', $modes;
    my @pfxs  = split '', $prefixes;
    unless (@modes == @pfxs) {
      warn "modes/prefixes do not appear to match: $modes $prefixes";
      return +{}
    }

    my $ref = +{};
    for my $mode (@modes) {
      $ref->{$mode} = shift @pfxs
    }
    $ref
  },

  statusmsg => $parse_simple_flags,

  targmax => sub {
    my ($val) = @_;
    my $ref = +{};
    TARGTYPE: for my $chunk (split /,/, $val) {
      my ($type, $lim) = split /:/, $chunk, 2;
      next TARGTYPE unless defined $lim;
      $ref->{ lc $type } = $lim;
    }
    $ref
  },

};

sub _isupport_hash {
  my ($obj) = @_;
  my %cur;
  confess "No object passed or no params to process"
    unless defined $obj and @{ $obj->params };
  ## First arg should be the target.
  ## Last is 'are supported by ...'
  my %split = map {;
    my ($key, $val) = split /=/, $_, 2;
    ( lc($key), (defined $val ? $val : '0 but true') )
  } @{ $obj->params }[1 .. ($#{ $obj->params } - 1) ];

  unless (keys %split) {
    warn "Appear to have been passed valid IRC, but not an ISUPPORT string";
    return +{}
  }

  for my $param (keys %split) {
    if (defined $parse->{$param} && defined $split{$param}) {
      $cur{$param} = $parse->{$param}->($split{$param})
    } else {
      $cur{$param} = $split{$param} 
    }
  }

  \%cur
}

sub _isupport_hash_to_obj { IRC::Toolkit::ISupport::Obj->__new($_[0]) }

sub parse_isupport {
  my @items = map {;
    blessed $_ ? $_ : ircmsg(raw_line => $_)
  } @_;

  confess 
    'Expected a list of raw IRC lines or IRC::Message::Object instances'
    unless @items;

  my %cur;
  ITEM: for my $item (@items) {
    if ($item->isa('IRC::Message::Object')) {
      my $piece = _isupport_hash($item);
      @cur{keys %$piece} = values %$piece;
      next ITEM
    } else {
      confess "expected an IRC::Message::Object but got $item"
    }
  }

  _isupport_hash_to_obj(\%cur);
}


{ package
  IRC::Toolkit::_ISchanmodes;
  use Carp 'confess';
  use strictures 2;
  sub new { bless +{ @_[1 .. $#_] }, $_[0] }

  sub list    { $_[0]->{list} }
  sub always  { $_[0]->{always} }
  sub whenset { $_[0]->{whenset} }
  sub bool    { $_[0]->{bool} }

  sub as_string {
    my ($self) = @_;
    join ',', map {; join '', @$_ }
      $self->list,
      $self->always,
      $self->whenset,
      $self->bool
  }
}

{ package
  IRC::Toolkit::_ISextban;
  use Carp 'confess';
  use strictures 2;
  sub new { bless +{ @_[1 .. $#_] }, $_[0] }

  sub prefix { $_[0]->{prefix} }
  sub flags  { $_[0]->{flags}  }

  sub as_string {
    my ($self) = @_;
    join ',', $self->prefix, join '', @{ $self->flags }
  }
}

{ package
  IRC::Toolkit::ISupport::Obj;

  use Carp 'confess';
  use strictures 2;
  use Scalar::Util 'blessed';

  { no strict 'refs';
    ## We have parsers for these that generate HASHes:
    for my $acc (qw/ 
      chanlimit
      chantypes
      elist
      maxlist
      prefix
      statusmsg
      targmax
    / ) {
      *{ __PACKAGE__ .'::'. $acc } = sub {
          my ($ins, $val) = @_;
          return ($ins->{$acc} || +{}) unless defined $val;
          $ins->{$acc}->{$val}
      };
    }
  }

  sub __new {
    my ($cls, $self) = @_;
    confess "Expected a HASH from _isupport_hash"
      unless ref $self eq 'HASH';
    bless $self, $cls
  }

  ## These are special:
  sub chanmodes {
    my ($self) = @_;
    return unless $self->{chanmodes};
    unless (blessed $self->{chanmodes}) {
      return $self->{chanmodes} = 
        IRC::Toolkit::_ISchanmodes->new(%{$self->{chanmodes}})
    }
    $self->{chanmodes}
  }

  sub extban {
    my ($self) = @_;
    return unless $self->{extban};
    unless (blessed $self->{extban}) {
      return $self->{extban} =
        IRC::Toolkit::_ISextban->new(%{$self->{extban}})
    }
    $self->{extban}
  }

  ## Everything else is bool / int / str we can't parse:
  our $AUTOLOAD;
  sub AUTOLOAD {
    my ($self) = @_;
    my $method = (split /::/, $AUTOLOAD)[-1];
    $self->{$method}
  }

  sub can {
    my ($self, $method) = @_;
    if (my $sub = $self->SUPER::can($method)) {
      return $sub
    }
    return unless exists $self->{$method};
    sub {
      my ($this) = @_;
      if (my $sub = $this->SUPER::can($method)) {
        goto $sub
      }
      $AUTOLOAD = $method; goto &AUTOLOAD
    }
  }

  sub DESTROY {}

}


print
  qq[<Gilded> "BREAKING: NH MAN HEARS ABOUT CLIMATE CHANGE, ],
  qq[CLEARS FIVE HUNDRED ACRES FOR COCA PLANTATION"\n]
unless caller;
1;

=pod

=head1 NAME

IRC::Toolkit::ISupport - IRC ISUPPORT parser

=head1 SYNOPSIS

  use IRC::Toolkit::ISupport;
  my $isupport = parse_isupport(@raw_lines);

  ## Get the MODES= value
  my $maxmodes = $isupport->modes;

  ## Get the PREFIX= char for mode 'o'
  my $prefix_for_o = $isupport->prefix('o');

  ## Find out if we have WHOX support
  if ( $isupport->whox ) {
    ... 
  }

  ## ... etc ...

=head1 DESCRIPTION

An ISUPPORT (IRC numeric 005) parser that accepts either raw IRC lines or
L<IRC::Message::Object> instances and produces struct-like objects with some
special magic for parsing known ISUPPORT types.

See L<http://www.irc.org/tech_docs/005.html>

=head2 parse_isupport

Takes a list of raw IRC lines or L<IRC::Message::Object> instances and
produces ISupport objects.

Keys not listed here will return their raw value (or '0 but true' for boolean
values).

The following known keys are parsed to provide a nicer interface:

=head3 chanlimit

If passed a channel prefix character, returns the CHANLIMIT= value for that
prefix.

Without any arguments, returns a HASH mapping channel prefixes to their
respective CHANLIMIT= value.

=head3 chanmodes

The four mode sets described by a compliant CHANMODES= declaration are list
modes, modes that always take a parameter, modes that take a parameter only
when they are set, and boolean-type 'flag' modes, respectively:

  CHANMODES=LIST,ALWAYS,WHENSET,BOOL

You can retrieve L<List::Objects::WithUtils::Array> ARRAY-type objects 
containing lists of modes belonging to each set:

  my @listmodes = @{ $isupport->chanmodes->list };

  my @always  = $isupport->chanmodes->always->all;

  my $whenset = $isupport->chanmodes->whenset;
  my $boolean = $isupport->chanmodes->bool;

Or retrieve the full string representation via B<as_string>:

  my $chanmodes = $isupport->chanmodes->as_string;

=head3 chantypes

Without any arguments, returns a HASH whose keys are the allowable channel
prefixes.

If given a channel prefix, returns boolean true if the channel prefix is
allowed per CHANTYPES.

=head3 elist

Without any arguments, returns a HASH whose keys are the supported ELIST
tokens.

With a token specified, returns boolean true if the token is enabled.

=head3 extban

Returns an object with the following methods:

B<prefix> returns the extended ban prefix character.

B<flags> returns the supported extended ban flags as an
L<List::Objects::WithUtils::Array> of flags:

  if ($isupp->extban->flags->grep(sub { $_[0] eq 'a' })->has_any) {
    ...
  }

B<as_string> returns the string representation of the EXTBAN= declaration.

=head3 maxlist

Without any arguments, returns a HASH mapping list-type modes (see
L</chanmodes>) to their respective numeric limit.

If given a list-type mode, returns the limit for that list.

=head3 prefix

Without any arguments, returns a HASH mapping status modes to their respective
prefixes.

If given a status modes, returns the prefix belonging to that mode.

=head3 statusmsg

Without any arguments, returns a HASH whose keys are the valid message target 
status prefixes.

If given a status prefix, returns boolean true if the prefix is listed in
STATUSMSG.

=head3 targmax

Given a target type (as of this writing charybdis specifies 
'names', 'list', 'kick', 'whois', 'privmsg', 'notice', 'accept', 'monitor'), 
returns the TARGMAX definition for that type, if present.

Returns undef if the specified TARGMAX key is nonexistant or has no limit
defined.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
