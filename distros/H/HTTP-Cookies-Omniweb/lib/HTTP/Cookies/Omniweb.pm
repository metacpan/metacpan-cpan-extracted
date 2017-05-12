package HTTP::Cookies::Omniweb;
use strict;

use warnings;
no warnings;

=head1 NAME

HTTP::Cookies::Omniweb - Cookie storage and management for Omniweb

=head1 SYNOPSIS

	use HTTP::Cookies::Omniweb;

	$cookie_jar = HTTP::Cookies::Omniweb->new;

	# otherwise same as HTTP::Cookies

=head1 DESCRIPTION

This package overrides the load() and save() methods of HTTP::Cookies
so it can work with Omniweb cookie files.

See L<HTTP::Cookies>.

=head1 BUGS

Although Omniweb declares that it uses a DTD, the URL to the DTD is
dead.

Omniweb seems to not store the path for cookies unless it is not
/, and sometimes it stores it as %2f.  I haven't completely figured
that out, so output files will not exactly match input files.

=head1 SOURCE AVAILABILITY

This code is in Github:

	http://github.com/briandfoy/HTTP-Cookies-Omniweb/tree/master

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2011 brian d foy.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use base qw( HTTP::Cookies );
use vars qw( $VERSION );

use constant TRUE  => 'TRUE';
use constant FALSE => 'FALSE';

$VERSION = '1.13';

my $EPOCH_OFFSET = 978_350_400;  # difference from Unix epoch

sub load
	{
	my( $self, $file ) = @_;

	$file ||= $self->{'file'} || return;

	local $_;
	local $/ = "\n";  # make sure we got standard record separator

	open my $fh, $file or return;

	my $magic = ( <$fh>, <$fh>, <$fh> );

	unless( $magic =~ /^\s*<OmniWebCookies>\s*$/ )
		{
		warn "$file does not look like an Omniweb cookies file" if $^W;
		close $fh;
		return;
		}

	my $now = time() - $EPOCH_OFFSET;

	my $domain;
	while( <$fh> )
		{
		$domain = $1 if m/<domain name="(.*?)">/;
		next if m|</domain>|;
		last if m|</OmniWebCookies>|;
		next unless m|<cookie|;

		my $path    = m/path="(.*?)"/ ? $1 : "/";
		$path =~ s|%2f|/|ig;

		my $name    = $1 if m/name="(.*?)"/;
		my $value   = $1 if m/value="(.*?)"/;
		my $expires = $1 if m/expires="(.*?)"/;

		#print STDERR "D=$domain P=$path N=$name V=$value E=$expires\n";

		my $secure = FALSE;

		$self->set_cookie(undef, $name, $value, $path, $domain, undef,
			0, $secure, $expires - $now, 0);
		}

	close $fh;

	1;
	}

sub save
	{
	my( $self, $file ) = @_;

	$file ||= $self->{'file'} || return;

	local $_;
	open my $fh, "> $file" or return;

	print $fh <<'EOT';
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<!DOCTYPE OmniWebCookies SYSTEM "http://www.omnigroup.com/DTDs/OmniWebCookies.dtd">
<OmniWebCookies>
EOT

	my $now = time - $EPOCH_OFFSET;

	foreach my $domain ( sort keys %{ $self->{COOKIES} } )
		{
		my $domain_hash = $self->{COOKIES}{$domain};

		print $fh qq|<domain name="$domain">\n|;

		PATH: foreach my $path ( sort keys %$domain_hash )
			{
			my $cookie_hash = $domain_hash->{ $path };

			COOKIE: foreach my $name ( sort keys %$cookie_hash )
				{
				my( $value, $expires ) = @{ $cookie_hash->{$name} }[ 1, 5 ];
				$expires -= $EPOCH_OFFSET;
				my $path_str = $path eq '/' ? '' : qq| path="$path"|;

				print $fh qq|  <cookie name="$name"$path_str value="$value"| .
					qq| expires="$expires" />\n|;
				}
			}

		print $fh "</domain>\n";
		}

	print $fh "</OmniWebCookies>\n";

	close $fh;

	1;
	}

1;
