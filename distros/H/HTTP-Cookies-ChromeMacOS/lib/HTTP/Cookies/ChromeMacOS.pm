package HTTP::Cookies::ChromeMacOS;

use 5.010;
use strict;
use warnings;

use DBI;
use utf8;
use POSIX;
use PBKDF2::Tiny qw/derive/;
use Crypt::CBC;

=head1 NAME

HTTP::Cookies::ChromeMacOS - MacOS系统读取Chrome Cookies

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use HTTP::Cookies::ChromeMacOS;

    my $cookie = HTTP::Cookies::ChromeMacOS->new();
    $cookie->load( "/path/to/Cookies", 'Want to load domain' );

    # /path/to/Cookies Usually is: ~/Library/Application Support/Google/Chrome/Default/Cookies
    # Want to load domain can be: google, yahoo, facebook etc or null will load all cookies

    my $ua = LWP::UserAgent->new(
      cookie_jar => $cookie,
      agent => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/43.0.2357.134 Safari/537.36',
    );

    ...

=head1 SUBROUTINES/METHODS

=head2 The Chrome cookies table

  creation_utc    INTEGER NOT NULL UNIQUE PRIMARY KEY
  host_key        TEXT NOT NULL
  name            TEXT NOT NULL
  value           TEXT NOT NULL
  path            TEXT NOT NULL
  expires_utc     INTEGER NOT NULL
  secure          INTEGER NOT NULL
  httponly        INTEGER NOT NULL
  last_access_utc INTEGER NOT NULL

=cut


use base qw( HTTP::Cookies );

use constant TRUE  => 1;
use constant FALSE => 0;

my ( $dbh, $pass );

sub _get_dbh {
  my ( $self, $file ) = @_;
  return $dbh if $dbh && $dbh->ping;
  $dbh = DBI->connect( "dbi:SQLite:dbname=$file", '', '',
    {
      sqlite_see_if_its_a_number => 1,
    }
  );

  return $dbh;
}

sub _get_rows {
  my( $self, $file, $domain ) = @_;
  $domain ||= '';

  my $dbh = $self->_get_dbh( $file );

  my @cols = qw/
    creation_utc
    host_key
    name
    value
    encrypted_value
    path
    expires_utc
    secure
    httponly
    last_access_utc
  /;

  my $sql = 'SELECT ' . join( ', ',  @cols ) . ' FROM cookies WHERE host_key like "%' . $domain . '%"';
  my $sth = $dbh->prepare( $sql );
  $sth->execute;

  my @rows = map { bless $_, 'HTTP::Cookies::Chrome::Record' } @{ $sth->fetchall_arrayref };
  $dbh->disconnect;

  return \@rows;
}

sub load {
  my( $self, $file, $domain ) = @_;

  $file ||= $self->{'file'} || return;


  my $salt = 'saltysalt';
  my $iv = ' ' x 16;
  my $salt_len = 16;
  my $pass = _get_pass();
  my $iterations = 1003;

  my $key = derive( 'SHA-1', $pass, $salt, $iterations, $salt_len );


  my $cipher = Crypt::CBC->new(
    -cipher => 'Crypt::OpenSSL::AES',
    -key    => $key,
    -keysize => 16,
    -iv => $iv,
    -header => 'none',
    -literal_key => 1,
  );

  foreach my $row ( @{ $self->_get_rows( $file, $domain ) } ) {
    my $value = $row->value || $row->encrypted_value || '';
    if ( $value =~ /^v10/ ) {
      $value =~ s/^v10//;
      $value = $cipher->decrypt( $value );
    }

    $self->set_cookie(
      undef,
      $row->name,
      $value,
      $row->path,
      $row->host_key,
      undef,
      undef,
      $row->secure,
      time() + 86400, # never expires for readonly
      0,
      {}
    );
  }

  return 1;
}

sub _get_pass {
  # On Mac, replace password from keychain
  # On Linux, replace password with 'peanuts'
  return $pass if $pass;
  $pass = `security find-generic-password -w -s "Chrome Safe Storage"`;
  chomp( $pass );
  return $pass;
}

sub save {
  my( $self, $new_file ) = @_;

  # never save, This is a ReadOnly Version
  return;
}

sub _filter_cookies {
  my( $self ) = @_;

  $self->scan(
    sub {
      my( $version, $key, $val, $path, $domain, $port,
        $path_spec, $secure, $expires, $discard, $rest ) = @_;

      return if $discard && not $self->{ignore_discard};

      return if defined $expires && time > $expires;

      $expires = do {
        unless( $expires ) { 0 }
        else {
          $expires * 1_000_000
        }
      };

      $secure = $secure ? TRUE : FALSE;

      my $bool = $domain =~ /^\./ ? TRUE : FALSE;

      $self->_insert(
        $domain,
        $key,
        $val,
        $path,
        $expires,
        $secure,
      );
    }
  );

}


sub _get_utc_microseconds {
  no warnings 'uninitialized';
  use bignum;
  POSIX::strftime( '%s', gmtime() ) * 1_000_000 + ($_[1]//0);
}

# This code from: https://github.com/briandfoy/HTTP-Cookies-Chrome
# I did small change
BEGIN {
  package HTTP::Cookies::Chrome::Record;
  use vars qw($AUTOLOAD);

  my %columns = map { state $n = 0; $_, $n++ } qw(
  creation_utc
  host_key
  name
  value
  encrypted_value
  path
  expires_utc
  secure
  httponly
  last_access_utc
  );


  sub AUTOLOAD {
    my( $self ) = @_;
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    die "" unless exists $columns{$method};

    $self->[ $columns{$method} ];
  }

  sub DESTROY { return 1 }
}



=head1 AUTHOR

MC Cheung, C<< <mc.cheung at aol.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-http-cookies-chromemacos at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Cookies-ChromeMacOS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::Cookies::ChromeMacOS


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-Cookies-ChromeMacOS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-Cookies-ChromeMacOS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-Cookies-ChromeMacOS>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-Cookies-ChromeMacOS/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 MC Cheung.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of HTTP::Cookies::ChromeMacOS
