#!/usr/bin/env perl

use strict qw(vars refs subs);
use Meta::Utils::System qw();
use Meta::Utils::Opts::Opts qw();
use Pipeline qw();
use HTTP::Daemon qw();
use OpenFrame::Segment::HTTP::Request qw();
use OpenFrame::Segment::ContentLoader qw();
use Meta::Baseline::Aegis qw();
use Error qw(:try);

my($url,$port,$reuse,$verbose);
my($opts)=Meta::Utils::Opts::Opts->new();
$opts->set_standard();
$opts->def_stri("url","what url to serve","www.veltzer.org",\$url);
$opts->def_inte("port","what port to serve",65000,\$port);
$opts->def_bool("reuse","reuse httpd",1,\$reuse);
$opts->def_bool("verbose","should I be noisy ?",1,\$verbose);
$opts->set_free_allo(0);
$opts->analyze(\@ARGV);

my($d)=HTTP::Daemon->new(
	LocalAddr=>$url,
	LocalPort=>$port,
	Reuse=>$reuse,
);
if(!defined($d)) {
	throw Meta::Error::Simple("unable to create HTTP::Daemon");
}
my($pipeline)=Pipeline->new();

my($hr)=OpenFrame::Segment::HTTP::Request->new();

my($cl)=OpenFrame::Segment::ContentLoader->new();

my($bl)=Meta::Baseline::Aegis::baseline();
$cl->directory($bl);

$pipeline->add_segment($hr,$cl);

if($verbose) {
	Meta::Utils::Output::print("Please contact me at: [".$d->url()."]\n");
}
while(my($c)=$d->accept()) {
	while(my($r)=$c->get_request) {
		my($store)=Pipeline::Store::Simple->new();
		$pipeline->store($store->set($r));
		$pipeline->dispatch();
		my($response)=$pipeline->store->get('HTTP::Response');
		$c->send_response($response);
	}
}

Meta::Utils::System::exit_ok();

__END__

=head1 NAME

website_httpd.pl - simple perl based web server.

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

	MANIFEST: website_httpd.pl
	PROJECT: meta
	VERSION: 0.01

=head1 SYNOPSIS

	website_httpd.pl [options]

=head1 DESCRIPTION

This program is a simple web based http server based on OpenFrame version 3.
This does not mean that it is not usable for small sites. For larger sites
it needs to be expanded and this could be done using the OpenFrame framework.

=head1 OPTIONS

=over 4

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

=item B<url> (type: stri, default: www.veltzer.org)

what url to serve

=item B<port> (type: inte, default: 65000)

what port to serve

=item B<reuse> (type: bool, default: 1)

reuse httpd

=item B<verbose> (type: bool, default: 1)

should I be noisy ?

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

Error(3), HTTP::Daemon(3), Meta::Baseline::Aegis(3), Meta::Utils::Opts::Opts(3), Meta::Utils::System(3), OpenFrame::Segment::ContentLoader(3), OpenFrame::Segment::HTTP::Request(3), Pipeline(3), strict(3)

=head1 TODO

Nothing.
