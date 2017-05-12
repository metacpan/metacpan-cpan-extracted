#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use HTTP::Daemon qw();
use HTTP::Response qw();
use Meta::Db::Dbi qw();
use Meta::Utils::Output qw();
use HTTP::Status qw();
use HTTP::Headers qw();
use Meta::Class::DBI qw();
use Meta::Projects::Elems::Elems qw();
#use Meta::Projects::Elems::Views qw();
use Meta::Db::Connections qw();
use Error qw(:try);

my($verbose,$connections_file,$con_name,$name,$url,$port);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_bool("verbose","should I be noisy",0,\$verbose);
$opts->def_modu("connections_file","what XML/connections file to use","xmlx/connections/connections.xml",\$connections_file);
$opts->def_stri("con_name","what connection name",undef,\$con_name);
$opts->def_stri("database","what database to work on","elems",\$name);
$opts->def_stri("url","what url to serve","www.veltzer.org",\$url);
$opts->def_inte("port","what port to serve",65000,\$port);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

# connet to the database and prepare a select statement

#my($dbi)=Meta::Db::Dbi->new();
my($connections)=Meta::Db::Connections->new_modu($connections_file);
#$dbi->Meta::Db::Dbi::connect_xml($connections,$con_name,$name);

Meta::Class::DBI::set_connection($connections->get_con_null($con_name),$name);

#my($stat)="SELECT content FROM elems WHERE name=?";
#my($prep)=$dbi->prepare($stat);

my($d)=HTTP::Daemon->new(
	LocalAddr=>$url,
	LocalPort=>$port,
);
if(!defined($d)) {
	throw Meta::Error::Simple("unable to create HTTP::Daemon");
}
if($verbose) {
	Meta::Utils::Output::print("Please contact me at: [".$d->url()."]\n");
}
while(my($c)=$d->accept()) {
	# this should be a while loop to keep connections alive
	if(my($r)=$c->get_request()) {
		if($verbose) {
			Meta::Utils::Output::print("method is [".$r->method()."]\n");
		}
		if($r->method() eq 'GET') {
			my($name)=$r->uri();
			$name=CORE::substr($name,1);
			Meta::Utils::Output::print("uri is [".$name."]\n");
			#$prep->bind_param(1,$need);
			#my($res)=$prep->execute();
			#if($res==1) {
			my($res)=Meta::Projects::Elems::Elems->search('name',$name);
			if(defined($res)) {
				#my($arr)=$prep->fetchall_arrayref();
				#my($content)=$arr->[0][0];
				my($content,$content_type);
				if($res->type() eq "html") {
					$content=$res->content();
					$content_type='text/html';
				}
				if($res->type() eq "binary") {
					$content=$res->binary_content();
					$content_type='image/whatever';
				}
				if($res->type() eq "cgi") {
					my($script)=$res->cgi_content();
					$res=Meta::Utils::System::system_out($script,[]);
					$content=$$res;
					$content_type='text/html';
				}
				if($verbose) {
					#Meta::Utils::Output::print("sending content [".$content."]\n");
				}
				my($header)=HTTP::Headers->new();
				$header->content_type($content_type);
				$header->content_length(CORE::length($content));
				my($rc)=HTTP::Status::RC_OK;
				my($msg)=undef;#or "OK"
				my($response)=HTTP::Response->new($rc,$msg,$header,$content);
				#my($response)=HTTP::Response->new();
				#$response->code(HTTP::Status::RC_OK);
				#$response->message("OK");
				#$response->header("");
				#$response->content($content);
				#$response->requret($r);
				#$response->protocol("HTTP/1.1");
				#$response->status_line("200 OK");
				#$c->send_response($response);
				#$c->send_basic_header(200);
				#$c->print("Content-Type: text/plain");
				#$c->print($r->as_string());
				if($verbose) {
					Meta::Utils::Output::print("going to respond\n");
				}
				$c->send_response($response);
				#$c->send_file_response("/etc/passwd");
			} else {
				$c->send_error(HTTP::Status::RC_NOT_FOUND);
			}
		} else {
			$c->send_error(HTTP::Status::RC_NOT_FOUND);
		}
	}
	$c->close();
	$c=undef;
#	undef($c);
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

elems_httpd.pl - an HTTP/HTTPS server for the elems project.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: elems_httpd.pl
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	elems_httpd.pl [options]

=head1 DESCRIPTION

This is a fully functional HTTP/HTTPS server which is written in Perl.
If you do not understand why it is needed please refer to the Elems project
documentaion to understand the advantages of having a DB only web server.

What does this server do:
1. Make contact with the backend database.
2. Get configuration information from the backend database.
3. Start serving HTTP at the required address and port.

=head1 OPTIONS

=over 4

=item B<verbose> (type: bool, default: 0)

should I be noisy

=item B<connections_file> (type: modu, default: xmlx/connections/connections.xml)

what XML/connections file to use

=item B<con_name> (type: stri, default: )

what connection name

=item B<database> (type: stri, default: elems)

what database to work on

=item B<url> (type: stri, default: www.veltzer.org)

what url to serve

=item B<port> (type: inte, default: 65000)

what port to serve

=item B<help> (type: bool, default: 0)

display help message

=item B<pod> (type: bool, default: 0)

display pod options snipplet

=item B<man> (type: bool, default: 0)

display manual page

=item B<quit> (type: bool, default: 0)

quit without doing anything

=item B<gtk> (type: bool, default: 0)

run a gtk ui to get the parameters

=item B<license> (type: bool, default: 0)

show license and exit

=item B<copyright> (type: bool, default: 0)

show copyright and exit

=item B<description> (type: bool, default: 0)

show description and exit

=item B<history> (type: bool, default: 0)

show history and exit

=back

no free arguments are allowed

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV download scripts
	0.01 MV teachers project
	0.02 MV md5 issues

=head1 SEE ALSO

Error(3), HTTP::Daemon(3), HTTP::Headers(3), HTTP::Response(3), HTTP::Status(3), Meta::Class::DBI(3), Meta::Db::Connections(3), Meta::Db::Dbi(3), Meta::Projects::Elems::Elems(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-this server does not currently fork.
