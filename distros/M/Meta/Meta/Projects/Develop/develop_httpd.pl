#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use HTTP::Daemon qw();
use HTTP::Response qw();
use Meta::Utils::Output qw();
use HTTP::Status qw();
use HTTP::Headers qw();
use Meta::File::MMagic qw();
use Error qw(:try);

my($verbose,$url,$port);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->def_bool("verbose","should I be noisy",0,\$verbose);
$opts->def_stri("url","what url to serve","www.veltzer.org",\$url);
$opts->def_inte("port","what port to serve",65000,\$port);
$opts->set_standard();
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($mm)=Meta::File::MMagic->new();
$mm->addFileExts('\.css$',"text/css");
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
			my($string)=$name->as_string();
			if($verbose) {
				Meta::Utils::Output::print("string is [".$string."]\n");
			}
			my($file)=Meta::Baseline::Aegis::which_nodie($string);
			if(defined($file)) {
				if($verbose) {
					Meta::Utils::Output::print("found\n");
				}
				my($content);
				Meta::Utils::File::File::load($file,\$content);
				my($content_type)=$mm->checktype_byfilename($file);
				if($verbose) {
					Meta::Utils::Output::print("type is [".$content_type."]\n");
				}
				# return the result
				my($header)=HTTP::Headers->new();
				$header->content_type($content_type);
				$header->content_length(CORE::length($content));
				my($rc)=HTTP::Status::RC_OK;
				my($msg)=undef;#or "OK"
				my($response)=HTTP::Response->new($rc,$msg,$header,$content);
				$c->send_response($response);
			} else {
				$c->send_error(HTTP::Status::RC_NOT_FOUND);
			}
		} else {
			$c->send_error(HTTP::Status::RC_FORBIDDEN);
		}
	}
	$c->close();
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

develop_httpd.pl - service aegis pages to the web.

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

	MANIFEST: develop_httpd.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	develop_httpd.pl [options]

=head1 DESCRIPTION

Run this script and point your web server at the appropriate adderess
and you'll get Aegis pages served right.

=head1 OPTIONS

=over 4

=item B<verbose> (type: bool, default: 0)

should I be noisy

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
	0.01 MV md5 issues

=head1 SEE ALSO

Error(3), HTTP::Daemon(3), HTTP::Headers(3), HTTP::Response(3), HTTP::Status(3), Meta::File::MMagic(3), Meta::Utils::Opts::Opts(3), Meta::Utils::Output(3), Meta::Utils::System(3), strict(3)

=head1 TODO

-add options to select which baseline and which change.

-add options to restrict file types or files served so that you could run this over your development directory directly (without needing to export to another directory).
