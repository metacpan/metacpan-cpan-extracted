# This code is part of Perl distribution Mail-Box-POP3 version 4.01.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2001-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package Mail::Box::POP3::Test;{
our $VERSION = '4.01';
}

use parent 'Exporter';

use strict;
use warnings;

use Log::Report  'mail-box-pop3';

use List::Util    qw/first/;
use File::Spec    ();

use Mail::Transport::POP3 ();

our @EXPORT = qw/start_pop3_server start_pop3_client/;

#
# Start POP3 server for tests
#

sub start_pop3_server($;$)
{	my $popbox  = shift;
	my $setting = shift || '';

	my $serverscript = File::Spec->catfile('t', 'server');

	# Some complications to find-out $perl, which must be absolute and
	# untainted for perl5.6.1, but not for the other Perl's.
	my $perl   = $^X;
	unless(File::Spec->file_name_is_absolute($perl))
	{	my @path = split /\:|\;/, $ENV{PATH};
		$perl    = first { -x $_ } map File::Spec->catfile($_, $^X), @path;
	}

	$perl =~ m/(.*)/;
	$perl = $1;
	%ENV = ();

	open my $server, "$perl $serverscript $popbox $setting |"
		or fault __x"could not start POP3 test server";

	my $line  = <$server>;
	my $port  = $line =~ m/(\d+)/ ? $1 : error __x"did not get port specification, but '{text}'.", text => $line;

	($server, $port);
}

#
# START_POP3_CLIENT PORT, OPTIONS
#

sub start_pop3_client($@)
{	my ($port, @options) = @_;

	Mail::Transport::POP3->new(
		hostname => '127.0.0.1',
		port     => $port,
		username => 'user',
		password => 'password',
		@options,
	);
}

1;
