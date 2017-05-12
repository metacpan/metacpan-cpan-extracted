package Mail::Address::Tagged;

#------------------------------------------------------------------------------
#
# Copyright  (c) Andrew Wilson 2001
#
#------------------------------------------------------------------------------
#
# Modification History
#
# Auth    Date       AECN        Description
# ------  ---------  ----------  ----------------------------------------------
# andrew  16 Sep 01  1.0.1001    Expanded the documentation
# andrew  12 Sep 01  1.0.1000    Wrote this.
#------------------------------------------------------------------------------

$Mail::Address::Tagged::VERSION = '0.01';

=head1 NAME

Mail::Address::Tagged - construct and validate email addresses with HMAC verification

=head1 SYNOPSIS

 #---------------------------------------------------------------------------
 # methods to use when constructing an address
 #---------------------------------------------------------------------------

 my $tag = Mail::Address::Tagged->new(key   => $key,
                                      email => 'foo@bar.com');

 my $seconds = $tag->set_valid_for($period);
 my $keyword = $tag->set_keyword('wibble');

 my $tag = Mail::Address::Tagged->new(key       => $key,
                                      user      => 'foo',
                                      host      => 'bar.com',
                                      valid_for => '10d',
                                      keyword   => 'wibble');

 $my $address = $tag->make_confirm(time    => $unix_time,
                                   pid     => $pid,
                                   keyword => $keyword);

 $my $address = $tag->make_confirm({time    => $unix_time,
                                    pid     => $pid,});

 $my $address = $tag->make_dated;
 $my $address = $tag->make_sender($address_to_receive_from);


 #---------------------------------------------------------------------------
 # methods to use when validating an address
 #---------------------------------------------------------------------------

 my $tag = Mail::Address::Tagged->for_received(key      => $key,
                                               received => $address,
                                               sender   => $sender,);

 if ($tag->valid) {
   ...
 }

 my $still_valid = ! $tag->expired;


 #---------------------------------------------------------------------------
 # Methods for accessing the objects internals (these will probably
 # be mainly used internally)
 #---------------------------------------------------------------------------

 my $email   = $tag->key;
 my $address = $tag->email;
 my $user    = $tag->user;
 my $host    = $tag->host;
 my $seconds = $tag->valid_for;
 my $keyword = $tag->keyword
 my $address = $tag->wrap('text_to_wrap');

 my $hmac = $tag->conf_mac(time => $time,
                           pid  => $pid);

 my $hmac = $tag->conf_mac(time    => $time,
                           pid     => $pid,
                           keyword => $value);

 my $hmac = $tag->single_value_mac($date);
 my $hmac = $tag->single_value_mac($sender);


 # only set by for_received

 my $received_time = $tag->candidate_time
 my $received_pid  = $tag->candidate_pid
 my $received_HMAC = $tag->candidate_mac
 my $address_type  = $tag->type
 my $correspondent = $tag->sender

=head1 DESCRIPTION

This module implements an object that can generate and validate tagged
email addresses.  These are designed to be used primarily in anti-spam
applications.

The addresses generated all carry extra information, such as the date
when they expire, who may use them to send you mail etc.  A
cryptocraphic hash of this extra information is also included in in
the address.  This Hashed Message Authenticaion Code (HMAC RFC 2104)
is your guarantee that the information contained in the address has
not been tampered with.

This module can generate and validate three different types of tagged
address.  They are all extensions of a users normal email address and
are constructed in a similar manner.  Where the normal address is
user@host.com, the tagged address takes the form
user-tagtype-tag@host.com.

The three supported address types are confirm, dated and sender.

Confirm addresses must contain a time (in unixtime) and the process id
of the process that generated them, they may also optionally contain a
keyword.  They include the time and process id so that the system can
deal with more than one message a second.  Addresses of this type are
used to request verification that a message should be delivered.  The
point being that automated mailers are unlikely to be able to respond
in this way so spam will not get through.  If a persistant spammer
does reach your mailbox, then you can always black list the address.
The keyword when it is supplied is the type of confirmation being
asked for.  All three bits of information are combined and a
cryptographic hash is taken of the result, these bits of info are then
combined like this.

  user-confirm-keyword.time.pid.HMAC@host.com

When mail like this is received, the bits can be separated out and a
new HMAC generated, if it matches the one in the address, then this is
a valid address.

Dated addresses have an expiry time and are used to accept mail up to
a given time.  They end up in the format

  user-dated-time.HMAC@host.com

and are validated in the same manner

The third type of supported address is sender, this takes the form

  user-sender-HMAC@host.com

the address that this will be accepted from is included in the HMAC
generation.  When mail of this form comes in the sending address can
be checked against the HMAC if they don't match then appropriate
action can be taken (disposal or confirmation request etc.).

=cut

use strict;
use Digest::HMAC;
use Digest::SHA1;

=head1 FACTORY METHODS

=head2 new

  my $tag = Mail::Address::Tagged->new(key   => $key,
                                       email => 'foo@bar.com');

  my $tag = Mail::Address::Tagged->new(key       => $key,
                                       user      => 'foo',
                                       host      => 'bar.com',
                                       valid_for => '10d',
                                       keyword   => 'wibble');

Pass this your key and email address it will constrct an object for
making tagged addresses.  The email address may be complete
e.g. foo@bar.com or supplied as user and host.

There are also various optional parametes that may be supplied to new.

You may pass the valid_for attribute to control how long dated address
will be active for, if not supplied it defaults to 5 days (see
set_valid_for documentation)

The keyword parameter is used when generating dated addresses.  It is
included in the string and allows for the generation of addresses like
this:

name-confirm-keyword.12344556.123.ABCDEF@host.org

If not supplied it defaults to the empty string.

=cut

sub new {
  my $class = shift;

  my %arg = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
  exists $arg{key} or return undef;
  exists $arg{email} or (exists $arg{user} and exists $arg{host}) or return undef;

  my $self = bless {}, $class;
  $self->_init(%arg) or return undef;

  return $self;
}

sub _init {
  my $self = shift;

  %{$self} = (@_);

  if (exists $self->{email}) {
    @{$self}{'user', 'host'} = split "@", $self->{email};
  } else {
    $self->{email} = $self->{user} . '@' . $self->{host};
  }

  $self->{keyword} ||= "";
  $self->set_valid_for($self->{valid_for});
}

=head2 for_received

  my $tag = Mail::Address::Tagged->for_received(key      => $key,
                                                received => $address,
                                                sender   => $sender,);

This constructs an object based on the received address.  It will
break it down into it's component parts, these may then be queried and
checked for validity.

=cut

sub for_received {
  my $class = shift;

  my %arg = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
  exists $arg{key} and
  exists $arg{address} and
  exists $arg{sender} or return undef;

  my ($user_part, $host)   = split "@", $arg{address};
  my ($user, $type, $data) = split "-", $user_part;

  # if we don't know what type of address this is then there's no
  # point continuing
  defined $type and $type =~ /^(confirm|dated|sender)$/ or return undef;

  # need to have an HMAC
  defined $data or return undef;

  # now set up the object
  my $self = $class->new(key  => $arg{key},
                         user => $user,
                         host => $host,);
  defined $self or return undef;

  $self->_set_type($type);
  $self->_set_sender($arg{sender});

  if ($type eq 'confirm') {

    my ($keyword, $date, $pid, $mac) = split m#\.#, $data;
    $self->set_keyword($keyword);
    $self->_set_candidate_time($date);
    $self->_set_candidate_pid($pid);
    $self->_set_candidate_mac($mac);

  } elsif ($type eq 'dated') {

    my ($date, $mac) = split m#\.#, $data;
    $self->_set_candidate_time($date);
    $self->_set_candidate_mac($mac);

  } else {
    $self->_set_candidate_mac($data);
  }

  return $self;
}

=head1 INSTANCE METHODS - Construction

=head2 set_valid_for

  my $seconds = $tag->set_valid_for($period);

This allows one to set the time period that dated addresses will be
valid for.  Times periods are specified as a string which consists of
a positive integer folowed by a period modifier.  Valid modifiers are:

=over 4

=item Y year

=item M month

=item w week

=item d day

=item h hours

=item s seconds

=back

=cut

my %Conv = ('Y' => 60 * 60 * 24 * 365,
            'M' => 60 * 60 * 24 * 30,
            'w' => 60 * 60 * 24 * 7,
            'd' => 60 * 60 * 24,
            'h' => 60 * 60,
            'm' => 60,
            's' => 1,);

sub set_valid_for {
  my $self = shift;

  my $period  = shift;
  if (defined $period and $period =~  /^(\d+)([YMwdhms])/) {
    my $num = $1;
    my $unit = $2;

    $self->{valid_for} = $Conv{$unit} * $num;
  } else {
    $self->{valid_for} = $Conv{d} * 5;
  }
  return $self->{valid_for};
}

=head2 set_keyword

  my $keyword = $tag->set_keyword('wibble');

Set the keyword of this object.  Returns the new keyword.

=cut

sub set_keyword {
  my $self = shift;

  my $new = shift;
  defined $new or return $self->keyword;
  $self->{keyword} = $new;
}

=head2 make_confirm

  $my $address = $tag->make_confirm(time    => $unix_time,
                                    pid     => $pid,
                                    keyword => $keyword);

  $my $address = $tag->make_confirm({time    => $unix_time,
                                     pid     => $pid,});

Return an address that will be used to confirm an email from an
untrusted source.  You must pass time and processid, you may also
optionally pass a keyword.

=cut

sub make_confirm {
  my $self = shift;

  my %arg = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;

  exists $arg{time} or carp('no time passed to make_confirm');
  exists $arg{pid}  or carp('no pid passed to make_confirm');

  $self->set_keyword($arg{keyword}) if exists $arg{keyword};
  my $keyword = $self->keyword;

  # generate the HMAC
  my $details;
  @{$details}{'time', 'pid'} = @arg{'time', 'pid'};
  my $mac = $self->conf_mac($details);

  return $self->wrap("-confirm-$keyword.$arg{time}.$arg{pid}." . $mac);
}

=head2 make_dated

  $my $address = $tag->make_dated;

Return an address that will be allowed to send us mail for the default
period of time from now.

=cut

sub make_dated {
  my $self = shift;

  my $date = shift;
  defined $date or $date = time();
  $date += $self->valid_for;

  my $mac  = $self->single_value_mac($date);

  return $self->wrap("-dated-". $date . '.' . $mac);
}

=head2 make_sender

  $my $address = $tag->make_sender($address_to_receive_from);

Return an address that will only accept mail if it is sent from one
particular sender address.

=cut

sub make_sender {
  my $self = shift;

  my $sender = lc(shift);
  my $mac    = $self->single_value_mac($sender);

  return $self->wrap("-sender-" . $mac);
}

=head1 INSTANCE METHODS - querying

These methods are only useful on objects constructed with the
for_received method.  They will tell you whether the address is
genuine and whether it has expired (for dated addresses).

=head2 valid

  if ($tag->valid) {
   ...
  }

This will tell you whether the HMAC matches the details of the address.

=cut

sub valid {
  my $self = shift;

  return undef unless $self->type;

  if ($self->type eq "confirm") {

    my $mac = $self->conf_mac({time => $self->candidate_time,
                               pid  => $self->candidate_pid});
    return $mac eq $self->candidate_mac;

  } elsif ($self->type eq "dated") {

    my $mac = $self->single_value_mac($self->candidate_time);
    return $mac eq $self->candidate_mac;

  } elsif ($self->type eq "sender") {

    my $mac = $self->single_value_mac($self->sender);
    return $mac eq $self->candidate_mac;

  }

  return 0;
}

=head2 expired

  my $still_valid = ! $tag->expired;

This will tell you whether dated addresses have expired.

=cut

sub expired {
  my $self = shift;

  return undef unless $self->candidate_time and $self->valid;
  return $self->candidate_time > time();
}

=head1 VALIDATION METHODS (mostly only for internal use)

=head2 conf_mac

  my $hmac = $tag->conf_mac(time => $time,
                            pid  => $pid);

  my $hmac = $tag->conf_mac(time    => $time,
                            pid     => $pid,
                            keyword => $value);

Return the HMAC for the time and pid passed in.  The method may also
take an optional keyword -> value pairing and if provided this will
also be included in the HMAC generation.

=cut

sub conf_mac {
  my $self = shift;

  my %arg = ref($_[0]) eq 'HASH' ? %{ $_[0] } : @_;
  exists $arg{time} or carp('no time passed to conf_mac');
  exists $arg{pid}  or carp('no pid passed to conf_mac');

  my $digest = Digest::HMAC->new($self->key, "Digest::SHA1");
  $digest->add($arg{time});
  $digest->add($arg{pid});
  $digest->add($self->keyword) if $self->keyword;
  # we only want the first 6 hex digits of the HMAC (there are 40)
  return substr($digest->hexdigest, 0, 6);
}

=head2 single_value_mac

  my $hmac = $tag->single_value_mac($date);

  my $hmac = $tag->single_value_mac($sender);

Return the HMAC for the value passed in.

=cut

sub single_value_mac {
  my $self = shift;

  my $value = shift;
  defined $value or carp('no value passed to single_value_mac');

  my $digest = Digest::HMAC->new($self->key, "Digest::SHA1");
  $digest->add($value);
  # we only want the first 6 hex digits of the HMAC (there are 40)
  return substr($digest->hexdigest, 0, 6);
}


=head2 key

  my $email = $tag->key;

Return the cryptographic key that this address is using.

=head2 email

  my $address = $tag->email;

This returns the unaltered email address that this object is
manipulating.

=head2 user

  my $user = $tag->user;

This returns the user portion of the email address that this object is
manipulating.

=head2 host

  my $host = $tag->host;

This returns the host portion of the email address that this object is
manipulating.

=cut

sub email     { $_[0]->{email} }
sub host      { $_[0]->{host} }
sub key       { $_[0]->{key} };
sub user      { $_[0]->{user} }

=head2 valid_for

  my $seconds = $tag->valid_for;

The number of seconds that a dated email address will be valid for.

=cut

sub valid_for { $_[0]->{valid_for} }

=head2 keyword

  my $keyword = $tag->keyword

If a keyword was supplied to the constructor, this method returns its
value.

=cut

sub keyword { $_[0]->{keyword} }

=head2 wrap

  my $address = $hmac->wrap('text_to_wrap');

When you call this method it constructs an email address of the form

  nametext_to_wrap@host

that is it wraps its argument in the user and host

=cut

sub wrap {
  my $self = shift;

  my $text = shift;
  return $self->user . $text . '@' . $self->host;
}

# these methods will not form part of the public interface of the module
sub _set_candidate_time {
  $_[0]->{candidate_time} = $_[1] if (defined $_[1])
};

sub _set_candidate_pid {
  $_[0]->{candidate_pid} = $_[1] if (defined $_[1])
};

sub _set_candidate_mac {
  $_[0]->{candidate_mac} = $_[1] if (defined $_[1])
};

sub _set_type {
  $_[0]->{type} = $_[1] if (defined $_[1])
};

sub _set_sender {
  $_[0]->{sender} = $_[1] if (defined $_[1])
};

=head2 candidate_time

  my $time = $tag->candidate_time

The time in the address.  This is only valid when an address of type
confirm or dated is being validated.  In all other cases it will
return undef.

=head2 candidate_pid

  my $received_pid = $tag->candidate_pid

the pid in the address.  this is only valid when a confirmation
address is bing validated.  it will return undef at all other times.

=head2 candidate_mac

  my $tag->candidate_mac

The HMAC of the address used to construct this object, this will only
being valid for objects that have been instantiated to validate an
address, it returns undef at all other times.

=head2 type

  $tag->type

The type of mail address used to create this object, it is only valid
when this object is being used for validation, it will return undef at
all other times.

=head2 sender

  $tag->sender

The sender argument passed to for_address when constructing an object
to validate an address.  If the object was not constructed to validate
an addrss it will return undef.

=cut

sub candidate_time { $_[0]->{candidate_time} };
sub candidate_pid  { $_[0]->{candidate_pid}  };
sub candidate_mac  { $_[0]->{candidate_mac}  };
sub type   {  $_[0]->{type}   };
sub sender {  $_[0]->{sender} };

=head1 BUGS

Nothing Known

=head1 TODO

Nothing Known

=cut

1;
