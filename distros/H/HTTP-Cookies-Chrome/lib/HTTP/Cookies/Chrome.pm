use 5.010;
use utf8;

package HTTP::Cookies::Chrome;
use strict;

use warnings;
use warnings::register;

use POSIX;

BEGIN {
	my @names = qw( _VERSION KEY VALUE PATH DOMAIN PORT PATH_SPEC
		SECURE EXPIRES DISCARD REST );
	my $n = 0;
	foreach my $name ( @names ) {
		no strict 'refs';
		my $m = $n++;
		*{$name} = sub () { $m }
		}
	}

=encoding utf8

=head1 NAME

HTTP::Cookies::Chrome - Cookie storage and management for Google Chrome

=head1 SYNOPSIS

	use HTTP::Cookies::Chrome;

	my $password = HTTP::Cookies::Chrome->get_from_gnome;

	my $cookie_jar = HTTP::Cookies::Chrome->new(
		chrome_safe_storage_password => $password,
		file     => ...,
		autosave => ...,
		);
	$cookie_jar->load( $path_to_cookies );

	# otherwise same as HTTP::Cookies

=head1 DESCRIPTION

This package overrides the C<load()> and C<save()> methods of
C<HTTP::Cookies> so it can work with Google Chrome cookie files,
which are SQLite databases. This also should work from Chrome clones,
such as Brave.

First, you are allowed to create different profiles within Chrome, and
each profile has its own set of files. The default profile is just C<Default>.
Along with that, there are various clones with their own product names.
The expected paths incorporate the product and profiles:

Starting with Chrome 80, cookie values may be (likely are) encrypted
with a password that Chrome changes and stores somewhere. Additionally,
each cookie record tracks several other fields. If you are
using an earlier Chrome, you should use an older version of this module
(the 1.x series).

=over 4

=item macOS - ~/Library/Application Support/PRODUCT/Chrome/PROFILE/Cookies

=item Linux - ~/.config/PRODUCT/PROFILE/Cookies

=item Windows - C:\Users\USER\AppData\Local\PRODUCT\User Data\$profile\Cookies

=back

=cut

use base qw( HTTP::Cookies );
use vars qw( $VERSION );

use constant TRUE  => 1;
use constant FALSE => 0;

$VERSION = '2.002';

use DBI;


sub _add_value {
	my( $self, $key, $value ) = @_;
	$self->_stash->{$key} = $value;
	}

sub _cipher { $_[0]->_get_value( 'cipher' ) }

sub _connect {
	my( $self, $file ) = @_;
	my $dbh = DBI->connect( "dbi:SQLite:dbname=$file", '', '',
		{
		sqlite_see_if_its_a_number => 1,
		} );
	$_[0]->{dbh} = $dbh;
	}

sub _create_table {
	my( $self ) = @_;

	$self->_dbh->do(  'DROP TABLE IF EXISTS cookies' );

	$self->_dbh->do( <<'SQL' );
CREATE TABLE cookies(
	creation_utc    INTEGER NOT NULL,
	host_key        TEXT NOT NULL,
	name            TEXT NOT NULL,
	value           TEXT NOT NULL,
	path            TEXT NOT NULL,
	expires_utc     INTEGER NOT NULL,
	is_secure       INTEGER NOT NULL,
	is_httponly     INTEGER NOT NULL,
	last_access_utc INTEGER NOT NULL,
	has_expires     INTEGER NOT NULL DEFAULT 1,
	is_persistent   INTEGER NOT NULL DEFAULT 1,
	priority        INTEGER NOT NULL DEFAULT 1,
	encrypted_value BLOB DEFAULT '',
	samesite        INTEGER NOT NULL DEFAULT -1,
	source_scheme   INTEGER NOT NULL DEFAULT 0,
	source_port     INTEGER NOT NULL DEFAULT -1,
	is_same_party   INTEGER NOT NULL DEFAULT 0,
	UNIQUE (host_key, name, path)
	)
SQL
	}

sub _dbh { $_[0]->{dbh} }

sub _decrypt {
	my( $self, $blob ) = @_;

	unless( $self->_cipher ) {
		warnings::warn("Decrypted cookies is not set up") if warnings::enabled();
		return;
		}

	my $type = substr $blob, 0, 3;
	unless( $type eq 'v10' ) { # v11 is a thing, too
		warnings::warn("Encrypted value is unexpected type <$type>") if warnings::enabled();
		return;
		}

	my $plaintext = $self->_cipher->decrypt( substr $blob, 3 );
	my $padding_count = ord( substr $plaintext, -1 );
	substr( $plaintext, -$padding_count ) = '' if $padding_count < 16;

	$plaintext;
	}

sub _encrypt {
	my( $self, $value ) = @_;

	unless( defined $value ) {
		warnings::warn("Value is not defined! Nothing to encrypt!") if warnings::enabled();
		return;
		}

	unless( $self->_cipher ) {
		warnings::warn("Encrypted cookies is not set up") if warnings::enabled();
		return;
		}

	my $blocksize = 16;

	my $padding_length = ($blocksize - length($value) % $blocksize);
	my $padding = chr($padding_length) x $padding_length;
	my $encrypted = 'v10' . $self->_cipher->encrypt( $value . $padding );

	$encrypted;
	}

sub _filter_cookies {
    my( $self ) = @_;

    $self->scan(
		sub {
			my( $version, $key, $val, $path, $domain, $port,
				$path_spec, $secure, $expires, $discard, $rest ) = @_;

			my @parts = @_;

			return if $parts[DISCARD] && not $self->{ignore_discard};
			return if defined $parts[EXPIRES] && time > $parts[EXPIRES];

			$parts[EXPIRES]  = $rest->{expires_utc};
			$parts[SECURE]   = $parts[SECURE] ? TRUE : FALSE;

			my $bool = $domain =~ /^\./ ? TRUE : FALSE;

			$self->_insert( @parts );
			}
		);

	}

sub _get_rows {
	my( $self, $file ) = @_;

	my $dbh = $self->_connect( $file );

	my $sth = $dbh->prepare( 'SELECT * FROM cookies' );

	$sth->execute;

	my @rows =
		map {
			if( my $e = $_->encrypted_value ) {
			my $p = $self->_decrypt( $e );
				$_->decrypted_value( $self->_decrypt( $e ) );
				}
			$_;
			}
		map { HTTP::Cookies::Chrome::Record->new( $_ ) }
		@{ $sth->fetchall_arrayref };

	$dbh->disconnect;

	\@rows;
	}

sub _get_value {
	my( $self, $key ) = @_;
	$self->_stash->{$key}
	}

{
my $creation_offset = 0;

sub _insert {
	my( $self, @parts ) = @_;

	my $rest = $parts[REST];

	$rest->{httponly} //= 0;
	$rest->{samesite} //= 0;

	# possibly thinking about a feature to remove the encryption,
	# so we'd need to re-encrypt things. Here we assume that already
	# exists so we always re-encrypt.
	my $encrypted_value = '';

	# If we have a value and there was a previous encrypted value,
	# encrypted the current value and blank out the value. Other
	if( $parts[VALUE] and $rest->{encrypted_value} and $self->_cipher ) {
		$encrypted_value = $self->_encrypt( $parts[VALUE] );
		$parts[VALUE] = '';
		}

	# Some cookies don't have values. WTF?
	$parts[VALUE] //= '';

	my @values = (
		$rest->{creation_utc},
		@parts[DOMAIN, KEY, VALUE, PATH],
		$rest->{expires_utc},
		$parts[SECURE],
		@{ $rest }{ qw(is_httponly last_access_utc has_expires
			is_persistent priority) },
		$encrypted_value,
		@{ $rest }{ qw(samesite source_scheme ) },
		$parts[PORT],
		$rest->{is_same_party},
		);

	$self->{insert_sth}->execute( @values );
	}
}

sub _get_utc_microseconds {
	no warnings 'uninitialized';
	use bignum;
	POSIX::strftime( '%s', gmtime() ) * 1_000_000 + ($_[1]//0);
	}

sub _make_cipher {
	my( $self, $password ) = @_;

	my $key = do {
		state $rc2 = require PBKDF2::Tiny;
		my $s = _platform_settings();
		my $salt = 'saltysalt';
		my $length = 16;
		PBKDF2::Tiny::derive( 'SHA-1', $password, $salt, $s->{iterations}, $length );
		};

	state $rc1 = require Crypt::Rijndael;
	my $cipher = Crypt::Rijndael->new( $key, Crypt::Rijndael::MODE_CBC() );
	$cipher->set_iv( ' ' x 16 );

	$self->_add_value( chrome_safe_storage_password => $password );
	$self->_add_value( cipher => $cipher );
	}

sub _platform_settings {
# https://n8henrie.com/2014/05/decrypt-chrome-cookies-with-python/
# https://github.com/n8henrie/pycookiecheat/issues/12
	state $settings = {
		darwin => {
			iterations => 1003,
			},
		linux => {
			iterations => 1,
			},
		MSWin32 => {
			},
		};

	$settings->{$^O};
	}

sub _prepare_insert {
	my( $self ) = @_;

	my $sth = $self->{insert_sth} = $self->_dbh->prepare_cached( <<'SQL' );
INSERT INTO cookies VALUES ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ? )
SQL

	}

sub _stash {
	state $mod_key = 'X-CHROME';
	$_[0]->{$mod_key} //= {};
	}

=head2 Class methods

=over 4

=item * guess_password

Try to retrieve the Chrome Safe Storage password by accessing the
system secrets for the logged-in user. This returns nothing if it
can't find it.

You don't need to use this to get the password.

On macOS, this looks in the Keyring using C<security>.

On Linux, this uses C<secret-tool>, which you might have to install
separately. Also, some early versions used the hard-coded password
C<peanut>, and some others may have used C<mock_password>.

I don't know how to do this on Windows. If you know, send a pull request.
That goes for other systems too.

=cut

sub guess_password {
	my $p = do {
		   if( $^O eq 'darwin' ) { `security find-generic-password -a "Chrome" -w` }
		elsif( $^O eq 'linux'  ) { `secret-tool lookup xdg:schema chrome_libsecret_os_crypt_password application chrome` }
		};
	chomp $p;
	$p
	}

=item * guess_path( PROFILE )

Try to retrieve the directory that contains the Cookies file. If you
don't specify C<PROFILE>, it uses C<Default>.

macOS: F<~/Library/Application Support/Google/Chrome/PROFILE/Cookies>

Linux: F<~/.config/google-chrome/PROFILE/Cookies>

=cut

sub guess_path {
	my( $self, $profile ) = @_;
	$profile //= 'Default';

	my $path_to_cookies = do {
		   if( $^O eq 'darwin' ) { "$ENV{HOME}/Library/Application Support/Google/Chrome/$profile/Cookies" }
		elsif( $^O eq 'linux'  ) { "$ENV{HOME}/.config/google-chrome/$profile/Cookies" }
		};

	return unless -e $path_to_cookies;
	$path_to_cookies
	}

=item * new

The extends the C<new> in L<HTTP::Cookies>, with the additional parameter
for the decryption password.

	chrome_safe_storage_password - the password

=cut

sub new {
	my( $class, %args ) = @_;

	my $pass = delete $args{chrome_safe_storage_password};
	my $file = delete $args{file};

	my $self = $class->SUPER::new( %args );

	return $self unless defined $pass;

	print STDERR "Making cipher\n";
	$self->_make_cipher( $pass );
	print STDERR "Made cipher\n";

	if( $file ) {
		$self->{file} = $file;
		$self->load;
		}

	return $self;
	}

=item * load

This overrides the C<load> from L<HTTP::Cookies>. There are a few
differences that matter.

The Cookies database for Chrome tracks many more things than L<HTTP::Cookies>
knows about, so this shoves everything into the "rest" hash. Notably:

=over 4

=item * Chrome sets the port to -1 if the cookie does not specify the port.

=item * The value of the cookie is either the plaintext value or the decrypted value from C<encrypted_value>.

=item * If C<ignore_discard> is set, this ignores the C<$maxage> part of L<HTTP::Cookies>, but remembers the value in C<expires_utc>.

=back

=cut

sub load {
	my( $self, $file ) = @_;

	$file ||= $self->{'file'} || return;

# $cookie_jar->set_cookie( $version, $key, $val, $path,
# $domain, $port, $path_spec, $secure, $maxage, $discard, \%rest )

	my $rows = $self->_get_rows( $file );

	foreach my $row ( @$rows ) {
		my $value = length $row->value ? $row->value : $row->decrypted_value;

		# if $max_page is not defined, HTTP::Cookies will not remove
		# the cookies. We still track the actual value in the the
		# hash and we can put the original back in place.
		my $max_age = do {
			if( $self->{ignore_discard} ) { undef }
			else { ($row->expires_utc / 1_000_000) - time }
			};

		# I've noticed that Chrome sets most ports to -1
		my $port = $row->source_port > 0 ? $row->source_port : 80;

		my $rc = $self->set_cookie(
			undef,              # version
			$row->name,         # key
			$value,             # value
			$row->path,         # path
			$row->host_key,     # domain
			$row->source_port,  # port
			undef,              # path spec
			$row->is_secure,    # secure
			$max_age,           # max_age
			0,                  # discard
			{
			map { $_ => $row->$_() } qw(
				value
				creation_utc
				is_httponly
				last_access_utc
				expires_utc
				has_expires
				is_persistent
				priority
				encrypted_value
				samesite
				source_scheme
				is_same_party
				source_port
				)
			}
			);

		}

	1;
	}

=back

=head2 Instance Methods

=over 4

=item * save( [ FILE ] )

With no argument, save the cookies to the original filename. With
a file name argument, write the cookies to that filename. This will
be a SQLite database.

=cut

sub save {
    my( $self, $new_file ) = @_;

    $new_file ||= $self->{'file'} || return;

	my $dbh = $self->_connect( $new_file );

	$self->_create_table;
	$self->_prepare_insert;
	$self->_filter_cookies;
	$dbh->disconnect;

	1;
	}

=item * set_cookie

Overrides the C<set_cookie> in L<HTTP::Cookies> so it can ignore
the port check. Chrome uses C<-1> as the port if the cookie did not
specify a port. This version of C<set_cookie> does no port check.

=cut

# We have to override this part because Chrome has -1 as a valid
# port value (for "unspecified port"). Otherwise this is lifted from
# HTTP::Cookies
sub set_cookie
{
    my $self = shift;
    my($version,
       $key, $val, $path, $domain, $port,
       $path_spec, $secure, $maxage, $discard, $rest) = @_;

    # path and key can not be empty (key can't start with '$')
    return $self if !defined($path) || $path !~ m,^/, ||
	            !defined($key)  || $key  =~ m,^\$,;

    # ensure legal port
    if (0 && defined $port) {  # nerf this part
	return $self unless $port =~ /^_?\d+(?:,\d+)*$/;
    }

    my $expires;
    if (defined $maxage) {
	if ($maxage <= 0) {
	    delete $self->{COOKIES}{$domain}{$path}{$key};
	    return $self;
	}
	$expires = time() + $maxage;
    }
    $version = 0 unless defined $version;

    my @array = ($version, $val,$port,
		 $path_spec,
		 $secure, $expires, $discard);
    push(@array, {%$rest}) if defined($rest) && %$rest;
    # trim off undefined values at end
    pop(@array) while !defined $array[-1];

    $self->{COOKIES}{$domain}{$path}{$key} = \@array;
    $self;
}

BEGIN {
package HTTP::Cookies::Chrome::Record;
use vars qw($AUTOLOAD);

my %columns = map { state $n = 0; $_, $n++ } qw(
	creation_utc
	host_key
	name
	value
	path
	expires_utc
	is_secure
	is_httponly
	last_access_utc
	has_expires
	is_persistent
	priority
	encrypted_value
	samesite
	source_scheme
	source_port
	is_same_party
	decrypted_value
	);

sub new {
	my( $class, $array ) = @_;
	bless $array, $class;
	}

sub decrypted_value {
	my( $self, $value ) = @_;

	return $self->[ $columns{decrypted_value} ] unless defined $value;
	$self->[ $columns{decrypted_value} ] = $value;
	}

sub AUTOLOAD {
	my( $self ) = @_;
	my $method = $AUTOLOAD;
	$method =~ s/.*:://;

	die "No method <$method>" unless exists $columns{$method};

	$self->[ $columns{$method} ];
	}

sub DESTROY { 1 }
}

=back

=head2 Getting the Chrome Safe Storage password

You can get the Chrome Safe Storage password, although you may have to
respond to other dialogs and features of its storage mechanism:

On macOS:

	% security find-generic-password -a "Chrome" -w
	% security find-generic-password -a "Brave" -w

On Ubuntu using libsecret:

	% secret-tool lookup xdg:schema chrome_libsecret_os_crypt_password application chrome
	% secret-tool lookup xdg:schema chrome_libsecret_os_crypt_password application brave

If you know of other methods, let me know.

Some useful information:

=over 4

=item * On Linux systems not using a keychain, the password might be C<peanut>
or C<mock_password>. Maybe I should use L<Passwd::Keyring::Gnome>

=item * L<https://rtfm.co.ua/en/chromium-linux-keyrings-secret-service-passwords-encryption-and-store/>

=item * L<https://stackoverflow.com/questions/57646301/decrypt-chrome-cookies-from-sqlite-db-on-mac-os>

=item * L<https://superuser.com/a/969488/12972>

=back

=head2 The Chrome cookies table

	creation_utc    INTEGER NOT NULL UNIQUE PRIMARY KEY
	host_key        TEXT NOT NULL
	name            TEXT NOT NULL
	value           TEXT NOT NULL
	path            TEXT NOT NULL
	expires_utc     INTEGER NOT NULL
	is_secure       INTEGER NOT NULL
	is_httponly     INTEGER NOT NULL
	last_access_utc INTEGER NOT NULL
	has_expires     INTEGER NOT NULL
	is_persistent   INTEGER NOT NULL
	priority        INTEGER NOT NULL
	encrypted_value BLOB
	samesite        INTEGER NOT NULL
	source_scheme   INTEGER NOT NULL
	source_port     INTEGER NOT NULL
	is_same_party   INTEGER NOT NULL

=head1 TO DO

There are many ways that this module can approve.

1. The L<HTTP::Cookies> module was written a long time ago. We still
inherit from it, but it might be time to completely dump it even if
we keep the interface.

2. Some Windows people can fill in the Windows details for C<guess_password>
and C<guess_path>.

3. As in (2), systems that aren't Linux or macOS can fill in their details.

4. We need a way to specify a new password to output the cookies to a
different Chrome-like SQLite database. The easiest thing right now might be
to make a completely new object with the new password and load cookies
into it.

=head1 SOURCE AVAILABILITY

This module is in Github:

	https://github.com/briandfoy/http-cookies-chrome

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 CREDITS

Jon Orwant pointed out the problem with dates too far in the future

=head1 COPYRIGHT AND LICENSE

Copyright © 2009-2021, brian d foy <bdfoy@cpan.org>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License 2.0.

=cut

1;
