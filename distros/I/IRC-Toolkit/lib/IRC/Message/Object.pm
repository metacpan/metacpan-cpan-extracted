package IRC::Message::Object;
$IRC::Message::Object::VERSION = '0.092002';
use strictures 2;
use Carp;

use Scalar::Util 'blessed';

use List::Objects::WithUtils;
use List::Objects::Types -all;
use Types::Standard -all;

use POE::Filter::IRCv3;

sub ircmsg { __PACKAGE__->new(@_) }
our @EXPORT = our @EXPORT_OK = 'ircmsg';


use Moo; use MooX::TypeTiny;
extends 'Exporter::Tiny';

has colonify => (
  lazy      => 1,
  is        => 'ro',
  predicate => 1,
  default   => sub { 0 },
);

has command => (
  required  => 1,
  is        => 'ro',
);


has filter => (
  is        => 'rw',
  isa       => HasMethods[qw/get put/],
  lazy      => 1,
  predicate => 1,
  builder   => '__build_filter',
);

sub __build_filter {
  POE::Filter::IRCv3->new(
    colonify => (
      defined $_[1] ? $_[1] : $_[0]->colonify
    ),
  )
}


has prefix => (
  is        => 'ro',
  lazy      => 1,
  predicate => 1,
  default   => sub { '' },
);

has params => (
  is        => 'ro',
  lazy      => 1,
  isa       => ArrayObj,
  coerce    => 1,
  predicate => 1,
  default   => sub { array },
);

has raw_line => (
  is        => 'ro',
  lazy      => 1,
  predicate => 1,
  default   => sub {
    my ($self) = @_;
    my %opts = ( command => $self->command );
    for (qw/colonify prefix params tags/) {
      my $pred = "has_".$_;
      $opts{$_} = $self->$_ if $self->$pred;
    }
    $self->filter->put([ \%opts ])->[0]
  },
);

has tags => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  predicate => 'has_tags',
  default   => sub { hash },
);

sub BUILDARGS {
  my $class = shift;
  my %params = @_ > 1 ? @_ : (raw_line => $_[0]) ;

  if (! defined $params{command}) {
    if (defined $params{raw_line}) {
      ## Try to create self from raw_line instead:
      my $filt = $params{filter} ?
        $params{filter} : $class->__build_filter(
          defined $params{colonify} ? $params{colonify} : 0
        );
      my $refs = $filt->get( [$params{raw_line}] );
      %params = %{ $refs->[0] } if @$refs;
    } else {
      confess "Bad params; a command or a raw_line must be specified in new()"
    }
  }

  \%params
}

sub get_tag {
  my ($self, $tag) = @_;
  return unless $self->has_tags;
  ## A tag might have an undef value ...
  ## ... see has_tag
  $self->tags->{$tag}
}

sub has_tag {
  my ($self, $tag) = @_;
  return unless $self->has_tags;
  exists $self->tags->{$tag}
}

sub tags_as_array {
  my ($self) = @_;
  return array unless $self->has_tags;

  my @tag_array;
  for ($self->tags->kv->all) {
    my ($thistag, $thisval) = @$_;
    push @tag_array,
      defined $thisval ? join '=', $thistag, $thisval
        : $thistag
  };

  array @tag_array
}

sub tags_as_string {
  my ($self) = @_;
  return unless $self->has_tags;

  my $str;
  my $kv = $self->tags->kv;

  TAG: {
    my $nxt = $kv->shift || last TAG;
    my ($thistag, $thisval) = @$nxt;
    $str .= $thistag . ( defined $thisval ? '='.$thisval : '' );
    if ($kv->has_any) {
      $str .= ';';
      redo TAG
    }
  }

  $str
}

sub truncate {
  my ($self) = @_;

  my $new;
  my $current = $self->raw_line;

  ## TODO check for CTCP first
  ##  if so, set flag, consider and readd trailing \001 ?

  if ($self->has_tags) {
    my $tagstr = '@' . $self->tags_as_string;
    my $trunc  = substr $current, (length($tagstr) + 1), 510;
    $new = join ' ', $tagstr, $trunc;
  } else {
    ## No tags, truncate to 510
    $new = length $current <= 510 ? $current : substr $current, 0, 510 ;
  }

  (blessed $self)->new(raw_line => $new)
}

sub TO_JSON {
  my ($self) = @_;
  +{
    command => $self->command,
    prefix  => $self->prefix,
    params  => $self->params,
    ( $self->has_tags ? (tags => $self->tags) : () ),
  }
}

print
  qq[<rnowak> fine, be rude like that\n],
  qq[<Perihelion> SORRY I WAS DISCUSSING THE ABILITY TO],
  qq[ PUT AN IRCD ON A ROOMBA\n]
unless caller; 1;

=pod

=for Pod::Coverage BUILDARGS TO_JSON has_\w+

=head1 NAME

IRC::Message::Object - Incoming or outgoing IRC events

=head1 SYNOPSIS

  ## Feed me some parameters:
  my $event = IRC::Message::Object->new(
    command  => '001',
    prefix   => ':some.server.org',
    params   => [ 'user', 'Welcome to IRC' ],
  );

  ## ... or use the 'ircmsg()' shortcut:
  my $event = ircmsg(
    command => '001',
    prefix  => ':some.server.org',
    params  => [ 'user', 'Welcome to IRC' ],
  );

  ## ... or take a raw IRC line (and parse it):
  $event = ircmsg(
    raw_line => ':some.server.org 001 user :Welcome to IRC'
  );

  ## ... or feed from POE::Filter::IRCD or POE::Filter::IRCv3:
  $event = ircmsg( %$ref_from_filter );

  ## ... retrieve useful bits later (see Methods):
  my $cmd  = $event->command;
  my $line = $event->raw_line;
  if ($event->has_tag('monkeys')) {
    ...
  }

=head1 DESCRIPTION

These objects represent incoming or outgoing IRC messages (events); they can
be created from either named parameters or a raw IRC line and provide
accessors with automatic parsing magic.

=head2 Functions

=head3 ircmsg

Create a new B<IRC::Message::Object>; 
shortcut for C<< IRC::Message::Object->new >>.

This module uses L<Exporter::Tiny>, so you can rename the exported constructor
if you like:

  use IRC::Message::Object ircmsg => { -as => 'irc_ev' };

=head2 Attributes and Methods

=head3 raw_line

The raw IRC line. The line is generated via the current 
L</filter> if the message object wasn't constructed with one.

predicate: C<has_raw_line>

=head3 command

The parsed command received.

Note that if the C<command> is set at construction time, 
no case-folding takes place.
However, specifying a C<raw_line> at construction feeds 
L<POE::Filter::IRCv3>, which will uppercase commands.

=head3 params

A L<List::Objects::WithUtils::Array> containing the parameters attached to the
message.

predicate: C<has_params>

=head3 prefix

The origin prefix.

predicate: C<has_prefix>

=head3 colonify

Passed through to L<POE::Filter::IRCv3/"colonify">; see the
L<POE::Filter::IRCv3> documentation for details.

Defaults to true.

=head3 filter

Can be used to change the L<POE::Filter> used to transform a raw line into a
HASH and vice-versa.

Defaults to a L<POE::Filter::IRCv3> instance with C<< colonify => 0 >> set.

=head3 get_tag

Retrieve a specific IRCv3.2 message tag's value.

This only works for tags with a defined value; see L</has_tag> to discover if
a tag exists.

=head3 has_tag

Takes a tag identifier; returns true if the tag exists.

This is useful for finding out about tags that have no defined value.

=head3 has_tags

Returns true if there are tags present.

=head3 tags

IRCv3.2 message tags, as a L<List::Objects::WithUtils::Hash> of key-value pairs.

=head3 tags_as_array

IRCv3.2 message tags, as a L<List::Objects::WithUtils::Array> of tags in the
form of 'key=value'

=head3 tags_as_string

IRCv3.2 message tags as a specification-compliant string.

=head3 truncate

Truncates the raw line to 510 characters, excluding message tags (per the
specification), and returns a new L<IRC::Message::Object>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
