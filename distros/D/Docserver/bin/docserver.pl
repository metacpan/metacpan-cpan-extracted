#!/usr/bin/perl -w

$^W = 1;
use strict;
use RPC::PlServer;
### use lib '.';
use Docserver;
use Docserver::Config;

package Docserver::Srv;
use vars qw( @ISA $VERSION );
@ISA = qw( RPC::PlServer );
$VERSION = $Docserver::VERSION;

my $oldfh = select STDOUT; $| = 1; select $oldfh;
$oldfh = select STDERR; $| = 1; select $oldfh;

my $server = new Docserver::Srv( {
		'debug' => 1,
		'facility' => 'stderr',
		'logfile' => $Docserver::Config::Config{'logfile'},
		'mode' => 'single',
		'localport' => $Docserver::Config::Config{'port'},
		'pidfile' => 'docserver.pid',
		'methods' => {
			'Docserver::Srv' => {
				'NewHandle' => 1,
				'CallMethod' => 1,
				'DestroyHandle' => 1,
				'errstr' => 1,
				},
			'Docserver' => {
				'new' => 1,
				'stderr' => 1,
				'preferred_chunk_size' => 1,
				'input_file_length' => 1,
				'put' => 1,
				'convert' => 1,
				'result_length' => 1,
				'get' => 1,
				'finished' => 1,
				'errstr' => 1,
				'server_version' => 1,
				}
			},
		'clients' => $Docserver::Config::Config{'clients'},
		} );
$server->Bind();

sub errstr {
	return "Server error: $Docserver::errstr";
	}

=head1 NAME

docserver - server for remote conversions of MS format documents

=head1 SYNOPSIS

Configure the server in lib/Docserver/Config.pm and start the
docserver.pl.

=head1 AUTHOR

(c) 1998--2002 Jan Pazdziora, adelton@fi.muni.cz,
http://www.fi.muni.cz/~adelton/ at Faculty of Informatics, Masaryk
University in Brno, Czech Republic.

All rights reserved. This package is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut

