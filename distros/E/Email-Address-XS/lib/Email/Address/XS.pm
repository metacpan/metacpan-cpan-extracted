# Copyright (c) 2015-2017 by Pali <pali@cpan.org>

package Email::Address::XS;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.00';

use Carp;

use base 'Exporter';
our @EXPORT_OK = qw(parse_email_addresses parse_email_groups format_email_addresses format_email_groups);

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

=head1 NAME

Email::Address::XS - Parse and format RFC 2822 email addresses and groups

=head1 SYNOPSIS

  use Email::Address::XS;

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue', comment => 'Records Department');
  print $winstons_address->address();
  # winston.smith@recdep.minitrue

  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  print $julias_address->format();
  # Julia <julia@ficdep.minitrue>

  my $users_address = Email::Address::XS->parse('user <user@oceania>');
  print $users_address->host();
  # oceania


  use Email::Address::XS qw(format_email_addresses format_email_groups parse_email_addresses parse_email_groups);
  my $undef = undef;

  my $addresses_string = format_email_addresses($winstons_address, $julias_address, $users_address);
  print $addresses_string;
  # "Winston Smith" <winston.smith@recdep.minitrue> (Records Department), Julia <julia@ficdep.minitrue>, user <user@oceania>

  my @addresses = parse_email_addresses($addresses_string);
  print 'address: ' . $_->address() . "\n" foreach @addresses;
  # address: winston.smith@recdep.minitrue
  # address: julia@ficdep.minitrue
  # address: user@oceania

  my $groups_string = format_email_groups('Brotherhood' => [ $winstons_address, $julias_address ], $undef => [ $users_address ]);
  print $groups_string;
  # Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue> (Records Department), Julia <julia@ficdep.minitrue>;, user <user@oceania>

  my @groups = parse_email_groups($groups_string);

=head1 DESCRIPTION

This module implements L<RFC 2822|https://tools.ietf.org/html/rfc2822>
parser and formatter of email addresses and groups. It parses an input
string from email headers which contain a list of email addresses or
a groups of email addresses (like From, To, Cc, Bcc, Reply-To, Sender,
...). Also it can generate a string value for those headers from a
list of email addresses objects.

Parser and formatter functionality is implemented in XS and uses
shared code from Dovecot IMAP server.

It is a drop-in replacement for L<the Email::Address module|Email::Address>
which has several security issues. E.g. issue L<CVE-2015-7686 (Algorithmic complexity vulnerability)|https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2015-7686>,
which allows remote attackers to cause denial of service, is still
present in L<Email::Address|Email::Address> version 1.908.

Email::Address::XS module was created to finally fix CVE-2015-7686.

Existing applications that use Email::Address module could be easily
switched to Email::Address::XS module. In most cases only changing
C<use Email::Address> to C<use Email::Address::XS> and replacing every
C<Email::Address> occurrence with C<Email::Address::XS> is sufficient.

So unlike L<Email::Address|Email::Address>, this module does not use
regular expressions for parsing but instead native XS implementation
parses input string sequentially according to RFC 2822 grammar.

Additionally it has support also for named groups and so can be use
instead of L<the Email::Address::List module|Email::Address::List>.

=head2 EXPORT

None by default. Exportable functions are:
C<parse_email_addresses>,
C<parse_email_groups>,
C<format_email_addresses>,
C<format_email_groups>.

=head2 Exportable Functions

=over 4

=item format_email_addresses

  use Email::Address::XS qw(format_email_addresses);

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston@recdep.minitrue');
  my $julias_address = Email::Address::XS->new(phrase => 'Julia', address => 'julia@ficdep.minitrue');
  my @addresses = ($winstons_address, $julias_address);
  my $string = format_email_addresses(@addresses);
  print $string;
  # "Winston Smith" <winston@recdep.minitrue>, Julia <julia@ficdep.minitrue>

Takes a list of email address objects and returns one formatted string
of those email addresses.

=cut

sub format_email_addresses {
	my (@args) = @_;
	return format_email_groups(undef, \@args);
}

=item format_email_groups

  use Email::Address::XS qw(format_email_groups);
  my $undef = undef;

  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue');
  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  my $users_address = Email::Address::XS->new(address => 'user@oceania');

  my $groups_string = format_email_groups('Brotherhood' => [ $winstons_address, $julias_address ], $undef => [ $users_address ]);
  print $groups_string;
  # Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, user@oceania

  my $undisclosed_string = format_email_groups('undisclosed-recipients' => []);
  print $undisclosed_string;
  # undisclosed-recipients:;

Like C<format_email_addresses> but this method takes pairs which
consist of a group display name and a reference to address list. If a
group is not undef then address list is formatted inside named group.

=item parse_email_addresses

  use Email::Address::XS qw(parse_email_addresses);

  my $string = '"Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>, user@oceania';
  my @addresses = parse_email_addresses($string);
  # @addresses now contains three Email::Address::XS objects, one for each address

Parses an input string and returns a list of Email::Address::XS
objects. Optional second string argument specifies class name for
blessing new objects.

=cut

sub parse_email_addresses {
	my (@args) = @_;
	my $t = 1;
	return map { @{$_} } grep { $t ^= 1 } parse_email_groups(@args);
}

=item parse_email_groups

  use Email::Address::XS qw(parse_email_groups);
  my $undef = undef;

  my $string = 'Brotherhood: "Winston Smith" <winston.smith@recdep.minitrue>, Julia <julia@ficdep.minitrue>;, user@oceania, undisclosed-recipients:;';
  my @groups = parse_email_groups($string);
  # @groups now contains list ('Brotherhood' => [ $winstons_object, $julias_object ], $undef => [ $users_object ], 'undisclosed-recipients' => [])

Like C<parse_email_addresses> but this function returns a list of
pairs: a group display name and a reference to a list of addresses
which belongs to that named group. An undef value for a group means
that a following list of addresses is not inside any named group. An
output is in a same format as a input for the function
C<format_email_groups>. This function preserves order of groups and
does not do any de-duplication or merging.

=back

=head2 Class Methods

=over 4

=item new

  my $empty_address = Email::Address::XS->new();
  my $winstons_address = Email::Address::XS->new(phrase => 'Winston Smith', user => 'winston.smith', host => 'recdep.minitrue', comment => 'Records Department');
  my $julias_address = Email::Address::XS->new('Julia', 'julia@ficdep.minitrue');
  my $users_address = Email::Address::XS->new(address => 'user@oceania');
  my $only_name = Email::Address::XS->new(phrase => 'Name');
  my $copy_of_winstons_address = Email::Address::XS->new(copy => $winstons_address);

Constructs and returns a new C<Email::Address::XS> object. Takes named
list of arguments: phrase, address, user, host, comment and copy.
An argument address takes precedence over user and host.

When an argument copy is specified then it is expected an
Email::Address::XS object and a cloned copy of that object is
returned. All other parameters are ignored.

Old syntax L<from the Email::Address module|Email::Address/new> is
supported too. Takes one to four positional arguments: phrase, address
comment, and original string. An argument original is deprecated and
ignored. Passing it throws a warning.

=cut

sub new {
	my ($class, @args) = @_;

	my %hash_keys = (phrase => 1, address => 1, user => 1, host => 1, comment => 1, copy => 1);
	my $is_hash;
	if ( scalar @args == 2 and defined $args[0] ) {
		$is_hash = 1 if exists $hash_keys{$args[0]};
	} elsif ( scalar @args == 4 and defined $args[0] and defined $args[2] ) {
		$is_hash = 1 if exists $hash_keys{$args[0]} and exists $hash_keys{$args[2]};
	} elsif ( scalar @args > 4 ) {
		$is_hash = 1;
	}

	my %args;
	if ( $is_hash ) {
		%args = @args;
	} else {
		carp 'Argument original is deprecated and ignored' if scalar @args > 3;
		$args{comment} = $args[2] if scalar @args > 2;
		$args{address} = $args[1] if scalar @args > 1;
		$args{phrase} = $args[0] if scalar @args > 0;
	}

	if ( exists $args{copy} ) {
		if ( $class->is_obj($args{copy}) ) {
			$args{phrase} = $args{copy}->phrase();
			$args{comment} = $args{copy}->comment();
			$args{user} = $args{copy}->user();
			$args{host} = $args{copy}->host();
			delete $args{address};
		} else {
			carp 'Named argument copy does not contain a valid object';
		}
	}

	my $self = bless {}, $class;

	$self->phrase($args{phrase});
	$self->comment($args{comment});

	if ( exists $args{address} ) {
		$self->address($args{address});
	} else {
		$self->user($args{user});
		$self->host($args{host});
	}

	return $self;
}

=item parse

  my $winstons_address = Email::Address::XS->parse('"Winston Smith" <winston.smith@recdep.minitrue> (Records Department)');
  my @users_addresses = Email::Address::XS->parse('user1@oceania, user2@oceania');

Parses an input string and returns a list of an Email::Address::XS
objects. Same as the function C<parse_email_addresses> but this one is
class method.

In scalar context this function returns just first parsed object.

=cut

sub parse {
	my ($class, $string) = @_;
	my @addresses = parse_email_addresses($string, $class);
	return wantarray ? @addresses : $addresses[0];
}

=back

=head2 Object Methods

=over 4

=item format

  my $string = $address->format();

Returns formatted Email::Address::XS object as a string.

=cut

sub format {
	my ($self) = @_;
	return format_email_addresses($self);
}

=item phrase

  my $phrase = $address->phrase();
  $address->phrase('Winston Smith');

Accessor and mutator for the phrase (display name).

=cut

sub phrase {
	my ($self, @args) = @_;
	return $self->{phrase} unless @args;
	return $self->{phrase} = $args[0];
}

=item user

  my $user = $address->user();
  $address->user('winston.smith');

Accessor and mutator for the unescaped user part of an address.

=cut

sub user {
	my ($self, @args) = @_;
	return $self->{user} unless @args;
	delete $self->{cached_address} if exists $self->{cached_address};
	return $self->{user} = $args[0];
}

=item host

  my $host = $address->host();
  $address->host('recdep.minitrue');

Accessor and mutator for the unescaped host part of an address.

=cut

sub host {
	my ($self, @args) = @_;
	return $self->{host} unless @args;
	delete $self->{cached_address} if exists $self->{cached_address};
	return $self->{host} = $args[0];
}

=item address

  my $string_address = $address->address();
  $address->address('winston.smith@recdep.minitrue');

Accessor and mutator for the escaped address.

Internally this module stores a user and a host part of an address
separately. Private method C<compose_address> is used for composing
full address and private method C<split_address> for splitting into a
user and a host parts. If splitting new address into these two parts
is not possible then this method returns undef and sets both parts to
undef.

=cut

sub address {
	my ($self, @args) = @_;
	my $user;
	my $host;
	if ( @args ) {
		($user, $host) = split_address($args[0]) if defined $args[0];
		if ( not defined $user or not defined $host ) {
			$user = undef;
			$host = undef;
		}
		$self->{user} = $user;
		$self->{host} = $host;
	} else {
		return $self->{cached_address} if exists $self->{cached_address};
		$user = $self->user();
		$host = $self->host();
	}
	if ( defined $user and defined $host and length $user and length $host ) {
		return $self->{cached_address} = compose_address($user, $host);
	} else {
		return $self->{cached_address} = undef;
	}
}

=item comment

  my $comment = $address->comment();
  $address->comment('Records Department');

Accessor and mutator for the comment which is formatted after an
address. A comment can contain another nested comments in round
brackets. When setting new comment this method check if brackets are
balanced. If not undef is set and returned.

=cut

sub comment {
	my ($self, @args) = @_;
	return $self->{comment} unless @args;
	return $self->{comment} = undef unless defined $args[0];
	my $count = 0;
	my $cleaned = $args[0];
	$cleaned =~ s/(?:\\.|[^\(\)])//g;
	foreach ( split //, $cleaned ) {
		$count++ if $_ eq '(';
		$count-- if $_ eq ')';
		last if $count < 0;
	}
	return $self->{comment} = undef if $count != 0;
	return $self->{comment} = $args[0];
}

=item name

  my $name = $address->name();

This method tries to return a name which belongs to the address. It
returns either C<phrase> or C<comment> or C<user> part of the address
or empty string (first defined value in this order). But it never
returns undef.

=cut

sub name {
	my ($self) = @_;
	my $phrase = $self->phrase();
	return $phrase if defined $phrase and length $phrase;
	my $comment = $self->comment();
	return $comment if defined $comment and length $comment;
	my $user = $self->user();
	return $user if defined $user and length $user;
	return '';
}

=back

=head2 Overloaded Operators

=over 4

=item stringify

  my $address = Email::Address::XS->new(phrase => 'Winston Smith', address => 'winston.smith@recdep.minitrue');
  print "Winston's address is $address.";
  # Winston's address is "Winston Smith" <winston.smith@recdep.minitrue>.

Objects stringify to C<format>.

=cut

our $STRINGIFY; # deprecated

use overload '""' => sub {
	my ($self) = @_;
	return $self->format() unless defined $STRINGIFY;
	carp 'Variable $Email::Address::XS::STRINGIFY is deprecated; subclass instead';
	my $method = $self->can($STRINGIFY);
	croak 'Stringify method ' . $STRINGIFY . ' does not exist' unless defined $method;
	return $method->($self);
};

=back

=head2 Deprecated Functions, Methods and Variables

For compatibility with L<the Email::Address module|Email::Address>
there are defined some deprecated functions, methods and variables.
Do not use them in new code. Their usage throws warnings.

Altering deprecated variable C<$Email:Address::XS::STRINGIFY> changes
method which is called for objects stringification.

Deprecated cache functions C<purge_cache>, C<disable_cache> and
C<enable_cache> are noop and do nothing.

=cut

sub purge_cache {
	carp 'Function purge_cache is deprecated and does nothing';
}

sub disable_cache {
	carp 'Function disable_cache is deprecated and does nothing';
}

sub enable_cache {
	carp 'Function enable_cache is deprecated and does nothing';
}

=pod

Deprecated object method C<original> just returns C<address>.

=cut

sub original {
	my ($self) = @_;
	carp 'Method original is deprecated and returns address';
	return $self->address();
}

=head1 SEE ALSO

L<RFC 822|https://tools.ietf.org/html/rfc822>,
L<RFC 2822|https://tools.ietf.org/html/rfc2822>,
L<Email::Address>,
L<Email::Address::List>,
L<Email::AddressParser>

=head1 AUTHOR

Pali E<lt>pali@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015-2017 by Pali E<lt>pali@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6.0 or,
at your option, any later version of Perl 5 you may have available.

Dovecot parser is licensed under The MIT License and copyrighted by
Dovecot authors.

=cut

1;
