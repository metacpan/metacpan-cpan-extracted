package HTTP::Cookies::Mozilla;
use strict;

use warnings;
no warnings;

=encoding utf8

=head1 NAME

HTTP::Cookies::Mozilla - Cookie storage and management for Mozilla

=head1 SYNOPSIS

	use HTTP::Cookies::Mozilla;

	$cookie_jar = HTTP::Cookies::Mozilla->new;

	# otherwise same as HTTP::Cookies

=head1 DESCRIPTION

This package overrides the C<load()> and C<save()> methods of HTTP::Cookies
so it can work with Mozilla cookie files.

This module should be able to work with all Mozilla derived browsers
(FireBird, Camino, et alia).

Note that as of FireFox, version 3, the
cookie file format changed from plain text files to SQLite databases,
so you will need to have either L<DBI>/L<DBD::SQLite>, or the
B<sqlite3> executable somewhere in the path. Neither one has been
put as explicit dependency, anyway, so you'll get an exception if
you try to use this module with a new style file but without having
any of them:

   neither DBI nor pipe to sqlite3 worked (%s), install either one

If your command-line B<sqlite3> is not in the C<$ENV{PATH}>,
you can set C<$HTTP::Cookies::Mozilla::SQLITE> to point to the actual
program to be used, e.g.:

   use HTTP::Cookies::Mozilla;
   $HTTP::Cookies::Mozilla::SQLITE = '/path/to/sqlite3';

Usage of the external program is supported under perl 5.8 onwards only,
because previous perl versions do not support L<perlfunc/open> with
more than three arguments, which are safer. If you are still sticking
to perl 5.6, you'll have to install L<DBI>/L<DBD::SQLite> to make
FireFox 3 cookies work.

See L<HTTP::Cookies>.

=head1 SOURCE AVAILABILITY

The source is in GitHub:

	https://github.com/briandfoy/HTTP-Cookies-Mozilla

=head1 AUTHOR

Derived from Gisle Aas's HTTP::Cookies::Netscape package with very
few material changes.

Flavio Poletti added the SQLite support.

maintained by brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 1997-1999 Gisle Aas

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

use base qw( HTTP::Cookies );
use vars qw( $VERSION $SQLITE );

use Carp qw(carp);

use constant TRUE  => 'TRUE';
use constant FALSE => 'FALSE';

$VERSION = '2.033';
$SQLITE = 'sqlite3';


sub _load_ff3 {
	my ($self, $file) = @_;
	my $cookies;
	my $query = 'SELECT host, path, name, value, isSecure, expiry '
	  . ' FROM moz_cookies';
	eval {
		require DBI;
		my $dbh = DBI->connect('dbi:SQLite:dbname=' . $file, '', '',
		 {RaiseError => 1}
		 );
		$cookies = $dbh->selectall_arrayref($query);
		$dbh->disconnect();
		1;
		}
	or eval {
		require 5.008_000; # for >3 arguments open, which is safer
		open my $fh, '-|', $SQLITE, $file, $query or die $!;
		$cookies = [ map { [ split /\|/ ] } <$fh> ];
		1;
		}
	or do {
		carp "neither DBI nor pipe to sqlite3 worked ($@), install either one";
		return;
		};

	for my $cookie ( @$cookies )
		{
		my( $domain, $path, $key, $val, $secure, $expires ) = @$cookie;

		$self->set_cookie( undef, $key, $val, $path, $domain, undef,
		   0, $secure, $expires - _now(), 0 );
		}

	return 1;
}

sub load {
	my( $self, $file ) = @_;

	$file ||= $self->{'file'} || do {
		carp "load() did not get a filename!";
		return;
		};

	return $self->_load_ff3($file) if $file =~ m{\.sqlite}i;

	local $_;
	local $/ = "\n";  # make sure we got standard record separator

	my $fh;
	unless( open $fh, '<:utf8', $file ) {
		carp "Could not open file [$file]: $!";
		return;
		}

	my $magic = <$fh>;

	unless( $magic =~ /^\# HTTP Cookie File/ ) {
		carp "$file does not look like a Mozilla cookies file";
		close $fh;
		return;
		}

	while( <$fh> ) {
		next if /^\s*\#/;
		next if /^\s*$/;
		tr/\n\r//d;

		my( $domain, $bool1, $path, $secure, $expires, $key, $val )
		   = split /\t/;

		$secure = ( $secure eq TRUE );

		# The cookie format is an absolute time in epoch seconds, so
		# we subtract the current time (with appropriate offsets) to
		# get the max_age for the second-to-last argument.
		$self->set_cookie( undef, $key, $val, $path, $domain, undef,
		    0, $secure, $expires - _now(), 0 );
		}

	close $fh;

	1;
	}

BEGIN {
	my $EPOCH_OFFSET = $^O eq "MacOS" ? 21600 : 0;  # difference from Unix epoch
	sub _epoch_offset { $EPOCH_OFFSET }
	}

sub _now { time() - _epoch_offset() };

sub _scansub_maker {  # Encapsulate checks logic during cookie scan
	my ($self, $coresub) = @_;

	return sub {
		my( $version, $key, $val, $path, $domain, $port,
		    $path_spec, $secure, $expires, $discard, $rest ) = @_;

		return if $discard && not $self->{ignore_discard};

		$expires = $expires ? $expires - _epoch_offset() : 0;
		return if defined $expires && _now() > $expires;

		return $coresub->($domain, $path, $key, $val, $secure, $expires);
		};
	}

sub _save_ff3 {
	my ($self, $file) = @_;

	my @fnames = qw( host path name value isSecure expiry );
	my $fnames = join ', ', @fnames;

	eval {
		require DBI;
		my $dbh = DBI->connect('dbi:SQLite:dbname=' . $file, '', '',
		   {RaiseError => 1, AutoCommit => 0});

		$dbh->do('DROP TABLE IF EXISTS moz_cookies;');

		$dbh->do('CREATE TABLE moz_cookies '
		    . ' (id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT,'
		    . '  path TEXT,expiry INTEGER, lastAccessed INTEGER, '
		    . '  isSecure INTEGER, isHttpOnly INTEGER);');

		{ # restrict scope for $sth
		my $pholds = join ', ', ('?') x @fnames;
		my $sth = $dbh->prepare(
		    "INSERT INTO moz_cookies($fnames) VALUES ($pholds)");
		$self->scan($self->_scansub_maker(
			sub {
				my( $domain, $path, $key, $val, $secure, $expires ) = @_;
				$secure = $secure ? 1 : 0;
				$sth->execute($domain, $path, $key, $val, $secure, $expires);
				}
				)
			);
		$sth->finish();
		}

		$dbh->commit();
		$dbh->disconnect();
		1;
		}
	or eval {
		open my $fh, '|-', $SQLITE, $file or die $!;
		print {$fh} <<'INCIPIT';

BEGIN TRANSACTION;

DROP TABLE IF EXISTS moz_cookies;
CREATE TABLE moz_cookies
   (id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT,
    path TEXT,expiry INTEGER, lastAccessed INTEGER,
    isSecure INTEGER, isHttpOnly INTEGER);

INCIPIT

		$self->scan( $self->_scansub_maker(
			sub {
				my( $domain, $path, $key, $val, $secure, $expires ) = @_;
				$secure = $secure ? 1 : 0;
				my $values = join ', ',
					map {  # Encode all params as hex, a bit overkill
					my $hex = unpack 'H*', $_;
					"X'$hex'";
					} ( $domain, $path, $key, $val, $secure, $expires );
				print {$fh}
					"INSERT INTO moz_cookies( $fnames ) VALUES ( $values );\n";
				}
			)
		);

		print {$fh} <<'EPILOGUE';

UPDATE moz_cookies SET lastAccessed = id;
END TRANSACTION;

EPILOGUE
	1;
	}
	or do {
		carp "neither DBI nor pipe to sqlite3 worked ($@), install either one";
		return;
	};

	return 1;
}

sub save {
	my( $self, $file ) = @_;

	$file ||= $self->{'file'} || do {
		carp "save() did not get a filename!";
		return;
		};

	return $self->_save_ff3($file) if $file =~ m{\. sqlite}imsx;

	local $_;

	my $fh;
	unless( open $fh, '>:utf8', $file ) {
		carp "Could not open file [$file]: $!";
		return;
		}

	print $fh <<'EOT';
# HTTP Cookie File
# http://www.netscape.com/newsref/std/cookie_spec.html
# This is a generated file!  Do not edit.
# To delete cookies, use the Cookie Manager.

EOT

	$self->scan($self->_scansub_maker(
		sub {
			my( $domain, $path, $key, $val, $secure, $expires ) = @_;
			$secure = $secure ? TRUE : FALSE;
			my $bool = $domain =~ /^\./ ? TRUE : FALSE;
			print $fh join( "\t", $domain, $bool, $path, $secure,
				$expires, $key, $val ), "\n";
			}
			)
		);

	close $fh;

	1;
	}

1;
