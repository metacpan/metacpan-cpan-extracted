#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  Image::Identicon/example/index.cgi.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Image-Identicon/example/index.cgi 337 2007-02-02T12:31:38.414450Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings;
use CGI qw(escapeHTML);
use CGI::Carp qw(fatalsToBrowser warningsToBrowser);

our $TMPL_FILE = 'index.tmpl.html';

__PACKAGE__->do_work(@ARGV);

# -----------------------------------------------------------------------------
# main.
#
sub do_work
{
	our $CGI = CGI->new();
	
	my $addr = $CGI->param('addr') || $CGI->param('ar') || $ENV{REMOTE_ADDR} || '';
	if( $CGI->param('random') )
	{
		$addr = join('.', map{int(rand(256))}1..4);
	}
	
	open(my $fh, '<', $TMPL_FILE) or die "could not open template file [$TMPL_FILE]: $!";
	my $tmpl = join('', <$fh>);
	close ($fh);
	
	if( $addr && !is_valid_address($addr) )
	{
		$tmpl =~ s{<!begin:image>.*<!end:image>\r?\n}{invalid ip address: $addr}sg;
		$addr = escapeHTML($addr);
		$tmpl =~ s{<&ADDR>}{$addr}g;
	}elsif( $addr )
	{
		$tmpl =~ s{<!begin:image>(.*)<!end:image>\n}{$1}sg;
		$tmpl =~ s{<&ADDR>}{$addr}g;
	}else
	{
		$tmpl =~ s{<!begin:image>.*<!end:image>\r?\n}{}sg;
		$tmpl =~ s{<&ADDR>}{}g;
	}
	$tmpl =~ s{<&RAND>}{int(rand 0xFFFF)}ge;
	
	print "Content-Type: text/html; charset=utf-8\r\n\r\n";
	print $tmpl;
}

sub is_valid_address
{
	my $addr = shift;
	my @ip = $addr =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
	my $packed = pack("C*", @ip);
	join('.', unpack("C*",$packed)) eq $addr;
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	identicon

=head1 NAME

index.cgi - identicon sample cgi

=head1 SEE ALSO

L<Image::Identicon>

