package HTTP::CryptoCookie;

use 5.006001;
use strict;
# use warnings;

use CGI qw(:standard);  # for now, move to Apache (mod_perl) later
use CGI::Cookie;
use Crypt::CBC;
use Digest::SHA2;
use Convert::ASCII::Armour;
use Compress::Zlib qw(compress uncompress);
use FreezeThaw qw(freeze thaw);
use Data::Dumper;

# first, some notes about compression and cryptography.
#
# never, ever compress an encrypted string.  this can potentially 
# give a cryptanalysist  clues about the encryption algorithm,
# the key, and the plaintext. so remember... compress, then encrypt.

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '1.14';

my $aa = new Convert::ASCII::Armour;

sub _roll_dough {
	my ($self,$struct) = @_;

	my $step_one = compress(freeze($struct));
	my $step_two = $self->{cipher}->encrypt($step_one);

	my $cooked = $aa->armour(
		Object	=> 'HCC',
		Headers	=> {},
		Content	=> {data=>$step_two},
		Compress => 1);

	return $cooked;
}

sub new {
	my($class,$key) = @_;
	die "argument of key required" unless $key;

	my $digest = new Digest::SHA2(256);
	$digest->add(($key));
	my $digest_key = $digest->digest();

	my $self = bless {
        cipher => Crypt::CBC->new(
			-key => $digest_key,
			-cipher => 'Rijndael',
			-regenerate_key => 0,
			-salt => 1,
			-header => 'salt'),
	}, $class;

	# redefine the value of $key in memory, then undef it
	$key = join '', map { chr(int(rand(255))) } (0..(100+length $key));
	undef $key;
	return $self;
}

sub get_cookie {
	my($self, %args) = @_;

	ref $args{cookie_name} && return undef;

	my %cookies = (! exists $self->{debug}) ?  CGI::Cookie->fetch() : $args{force_cookie};
	if(my $cookie = $cookies{$args{cookie_name}}) {
		# first step, unarmour
		my $dough = $aa->unarmour($cookie->value);
		my $xcval = $self->{cipher}->decrypt($dough->{Content}{data});
		# next step, uncompress
		if(length($xcval) > 0) {
			my $rv = (thaw(uncompress($xcval)))[0];
			return $rv;
		} else {
			return undef;
		}
	}
	return undef;
}

sub set_cookie {
	my($self, %args) = @_;
	# a basic cookie...


	if(exists $args{cookie} && exists $args{cookie_name}) {
		# bake the cookie

		my $cookie = CGI::Cookie->new(
			-name => $args{cookie_name},
			-value => $self->_roll_dough($args{cookie}),
			-path => $args{path} || '/',
			-expires => $args{exp},
			-secure => $args{secure} || 0,
			-domain => $args{domain},
		);


		# toss the cookie at the browser
		if(exists $args{r}) {
			$args{r}->headers_out->set('Set-Cookie' => $cookie);
		} else {
			print header(-cookie =>[$cookie]);
		}
		return 1;
	} elsif (scalar(@{$args{cookies}}) > 0) {
		my $jar = [];

		foreach my $cookie (@{$args{cookies}}) {
			my $oreo = CGI::Cookie->new(
				-name => $cookie->{name} || $cookie->{cookie_name},
				-value => $self->_roll_dough($cookie->{cookie}),
				-path => $cookie->{path} || $args{path} || '/',
				-expires => $cookie->{exp} || $args{exp},
				-secure => $cookie->{secure} || $args{secure} || 0,
				-domain => $cookie->{domain} || $args{domain},
			);

			push(@{$jar}, $oreo);
			if(exists $args{r}) {
				$args{r}->headers_out->set('Set-Cookie' => $oreo);
			}
		}

		print header(-cookie => $jar) unless (exists $args{r});
		return scalar(@{$jar});
	}
	return undef;
}

sub del_cookie {
	my($self,%args) = @_;

	my $jar = [];

	unless(ref($args{cookie_name}) eq 'ARRAY') {
		$args{cookie_name} = [ $args{cookie_name} ];
	}

	foreach my $cookie_name (@{$args{cookie_name}}) {
		my $donut_hole = CGI::Cookie->new(
			-name => $cookie_name,
			-expires => '-1M',
		);

		push(@{$jar}, $donut_hole);
		if(exists $args{r}) {
			$args{r}->headers_out->set('Set-Cookie' => $donut_hole);
		} 
		print header(-cookie => $jar) unless (exists $args{r});
	}
	
	return scalar(@{$jar});
}

1;
__END__

=head1 NAME

HTTP::CryptoCookie - Perl extension for encrypted HTTP cookies 

=head1 SYNOPSIS

  use HTTP::CryptoCookie;
  my $cc = new HTTP::CryptoCookie ($key);
  # fair warning, if a $key is not passed, the call to
  # "new" will die.  It is B<highly advised> that you wrap
  # this in an eval to handle $@ under mod_perl!!

  # $key is a scalar, secret key

  my %cookie = (
    cookie_name => 'PREFS',
    cookie => {
      color => 'blue',
      number => 8,
      day_of_week => 'friday',
      people => [qw(joe sam megan)],
    },
    secure => 1,  # only available through SSL, defaults to 0
    exp => '+1M', # expires in one month
    domain => 'foo.com',  # readable by all hosts in the foo.com domain
  );

  my $rv = $cc->set_cookie(%cookie);
  if(!$rv) {
    warn "oh no!  we couldn't set the cookie!";
  }

=head1 DESCRIPTION

HTTP::CryptoCookie provides a convenient, fast interface to store complex
data structures as cookies in a manner that cannot be humanly-read or tampered
with.  If the cookie is altered by even one bit, the attempt to read it
will return garbage.  Such is the price of security.

=head1 METHODS

=over 2

=item B<new>

This is the standard object constructor and requires a key be passed
as an argument.  If a key is not passed, there is a B<die> statement.
When running under mod_perl, this tends to be a Bad Thing[tm], so you
are B<highly advised> to wrap the call in an eval block to trap $@
and handle it sanely.  You've been duly warned. 

=back

=over 2

=item B<set_cookie>

This method takes either a hash as an argument and the hash may contain
a single hashref or an array of hashrefs with cookie details.  This allows
us to set one or more cookies in one call.  The attributes available when
setting a cookie (a hashref) are as follows:

=back

=over 4

=item * cookie_name

The name of this cookie so we can recall the data later.  This is a scalar.

=item * cookie

This is the data structure we want to store.  The exact structure is limited
to one of the following:  scalar, arrayref, hashref, and possibly coderefs.
Blessed references and objects cannot be stored.

=item * secure

If set to 1, the cookie is only available when the user is operating
under SSL.  Default is 0.  This is 0 or any true value.

=item * exp

The expiration date of the cookie.  By default, the cookie exists until
the user closes their browser.  For more information about expiration
formats, see perldoc CGI::Cookie.  This is set as a scalar.

=item * path

Cookies can be set such that they are only valid within certain request paths
within the file system (be they actual or virtual).  This is set as a scalar.

=item * domain

Unless this is set, the cookie will only be able to be read by machines
with the same host name (as far as the ServerName in the httpd is set)
as the machine that set the cookie.  e.g.  a cookie set by 'www.foo.com'
cannot be read by 'secure.foo.com' unless you've set domain equal to
'foo.com'.

=back

=over 2

=item B<get_cookie>

This method takes a hash as an argument.  The only available attribute
is:

=back

=over 4

=item * cookie_name

This is a scalar holding the name of the cookie you wish to retrieve.

=back

=over 2

=item B<del_cookie>

This method deletes cookies (I know, such a obfuscated function name!).
The only available attribute is:

=back

=over 4

=item * cookie_name

This is either a hash (or arrayref of hashes) containing the name or names
of cookies that should be deleted from the user's browser.  A common
application of this is a "log out" function.  They key in the hash is
"cookie_name".

=back

=head2 EXPORT

None.  This is an OO-only module.

=head1 AUTHOR

Dave Paris (a-mused), E<lt>amused@pobox.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 1998-2005, Dave Paris.  All Rights Reserved. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

Crypt::Rijndael, Crypt::CBC, Storable, FreezeThaw, Compress::Zlib
CGI::Cookie, Digest::SHA256, Convert::ASCII::Armour

=cut

