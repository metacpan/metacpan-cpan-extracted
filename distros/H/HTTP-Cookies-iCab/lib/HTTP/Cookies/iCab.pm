package HTTP::Cookies::iCab;
use strict;

use warnings;
no warnings;

=head1 NAME

HTTP::Cookies::iCab - Cookie storage and management for iCab

=head1 SYNOPSIS

	use HTTP::Cookies::iCab;

	my $cookie_jar = HTTP::Cookies::iCab->new( $cookies_file );

	# otherwise same as HTTP::Cookies

=head1 DESCRIPTION

This package overrides the load() and save() methods of HTTP::Cookies
so it can work with iCab 3 cookie files. This doesn't work on iCab
4 cookie files yet, but if you really need that, convert HTTP::Cookies::Safari
to do what you need.

See L<HTTP::Cookies>.

=head1 SOURCE AVAILABILITY

This source is part of a SourceForge project which always has the
latest sources in CVS, as well as all of the previous releases.

	http://sourceforge.net/projects/brian-d-foy/

If, for some reason, I disappear from the world, one of the other
members of the project can shepherd this module appropriately.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2011 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#/Users/brian/Library/Preferences/iCab Preferences/iCab Cookies
# Time::Local::timelocal(0,0,0,1,0,70)

use base qw( HTTP::Cookies );
use vars qw( $VERSION );

use constant TRUE   => 'TRUE';
use constant FALSE  => 'FALSE';
use constant OFFSET => 2_082_823_200;

$VERSION = '1.131';

my $Debug = $ENV{DEBUG} || 0;

sub load
	{
    my( $self, $file ) = @_;

    $file ||= $self->{'file'} || return;

    open my $fh, '<:raw', $file or die "Could not open file [$file]: $!";

 	my $size = -s $file;

	COOKIE: until( eof $fh )
		{
		print STDERR "\n", "-" x 73, "\n" if $Debug;
		my $set_date = read_date( $fh );
		print STDERR ( "\tset date is " . localtime( $set_date ) . "\n" )
			if $Debug;
		my $tag      = read_str( $fh, 4 );
		print STDERR ( "==> tag is [$tag] not 'Cook'\n" )
			unless $tag eq 'Cook';

		my $name    = read_var( $fh );
		warn( "\tname is [$name]\n" ) if $Debug;
		my $path    = read_var( $fh );
		warn( "\tpath is [$path]\n" ) if $Debug;
		my $domain  = read_var( $fh );
		warn( "\tdomain is [$domain]\n" ) if $Debug;
		my $value   = read_var( $fh );
		warn( "\tvalue is [$value]\n" ) if $Debug;

		my $expires = read_int( $fh ) - OFFSET;

		warn( "\t$name expires at " .
			localtime( $expires ) . "\n" ) if $Debug;
		my $str     = read_str( $fh, 7 );

		DATE: {
			my $pos = tell $fh;
			warn( "read $pos of $size bytes\n" ) if $Debug > 1;
			if( eof $fh )
				{
				warn( "At end of file, setting cookie [$name]\n" ) if $Debug;
				$self->set_cookie(undef, $name, $value, $path,
					$domain, undef, 0, 0, $expires - time, 0);

				last COOKIE;
				}

			my $peek    = peek( $fh, 12 );
			warn( "\t--peek is $peek\n" ) if $Debug > 1;

			if( substr( $peek, 8, 4 ) eq 'Cook' )
				{
				warn( "Setting cookie [$name]\n" ) if $Debug;
				$self->set_cookie(undef, $name, $value, $path,
					$domain, undef, 0, 0, $expires - time, 0);
				next COOKIE;
				}

			my $date = read_date( $fh );

			redo;
			}

		}

    close $fh;

    1;
	}

sub save
	{
    my( $self, $file ) = @_;

    $file ||= $self->{'file'} || return;

	open my $fh, '>:raw', $file or die "Could not write file [$file]! $!\n";

    $self->scan(
    	sub {
			my( $version, $key, $val, $path, $domain, $port,
				$path_spec, $secure, $expires, $discard, $rest ) = @_;

			return if $discard && not $self->{ignore_discard};

			return if defined $expires && time > $expires;

			$expires += OFFSET;

			$secure = $secure ? TRUE : FALSE;

			my $bool = $domain =~ /^\./ ? TRUE : FALSE;

			print $fh 'Date', pack( 'N', time + OFFSET ),
				      'Cook', 
				      pack( 'N', length $key    ), $key, 
				      pack( 'N', length $path   ), $path,
				      pack( 'N', length $domain ), $domain,
				      pack( 'N', length $val    ), $val,
				      pack( 'N', $expires );
	    	}
		);

    close $fh;
	}

sub read_int
	{
	my $fh = shift;

	my $result = read_str( $fh, 4 );

	my $number = unpack( "N", $result );

	return $number;
	}

sub read_date
	{
	my $fh = shift;

	my $string = read_str( $fh, 4 );
	warn( "\t==tag is [$string] not 'Date'\n" ) unless $string eq 'Date';

	my $date = read_int( $fh );
	warn( sprintf "\t==read date %X | %d | %s\n", $date, $date,
		scalar localtime $date ) if $Debug > 1;

	$date -= OFFSET;
	warn( sprintf "\t==read date %X | %d | %s\n", $date, $date,
		scalar localtime $date ) if $Debug > 1;

	return $date;
	}

sub read_var
	{
	my $fh = shift;

	my $length = read_int( $fh );
	warn "length is $length\n" if $Debug > 1;
	my $string = read_str( $fh, $length );

	return $string;
	}

sub read_str
	{
	my $fh     = shift;
	my $length = shift;

	my $result = read( $fh, my $string, $length );

	return $string;
	}

sub peek
	{
	my $fh     = shift;
	my $length = shift;

	my $result = read( $fh, my $string, $length );

	seek $fh, -$length, 1;

	return $string;
	}

1;
