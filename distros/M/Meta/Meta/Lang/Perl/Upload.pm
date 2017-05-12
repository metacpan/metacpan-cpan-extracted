#!/bin/echo This is a perl module and should not be run

package Meta::Lang::Perl::Upload;

use strict qw(vars refs subs);
use Net::FTP qw();
use Meta::Development::Verbose qw();
use HTTP::Request::Common qw();
use LWP::UserAgent qw();
#use HTTP::Status qw();
use File::Basename qw();
use Meta::Class::MethodMaker qw();
use Meta::Lang::Perl::Perlpkgs qw();

our($VERSION,@ISA);
$VERSION="0.08";
@ISA=qw(Meta::Development::Verbose);

#sub BEGIN();
#sub new($);
#sub init($);
#sub upload($$);
#sub fast_upload($$);
#sub finish($);
#sub ftp_init($);
#sub ftp_upload($$$);
#sub ftp_finish($);
#sub http_init($);
#sub http_upload($$$);
#sub http_finish($);
#sub TEST($);

#__DATA__

sub BEGIN() {
	Meta::Class::MethodMaker->get_set(
		-java=>"_site",
		-java=>"_upload_dir",
		-java=>"_pause_add_uri",
		-java=>"_ftp_user",
		-java=>"_ftp_password",
		-java=>"_use_ftp_gateway",
		-java=>"_ftp_gateway",
		-java=>"_use_ftp_proxy",
		-java=>"_ftp_proxy",
		-java=>"_ftp",
		-java=>"_use_http_proxy",
		-java=>"_http_proxy",
		-java=>"_program",
		-java=>"_version",
		-java=>"_do_ftp",
		-java=>"_do_http",
	);
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Development::Verbose->new();
	bless($self,$class);
	return($self);
}

sub init($) {
	my($self)=@_;
	#$self->set_site('pause.kbx.de');
	$self->set_site('pause.cpan.org');
	$self->set_upload_dir('incoming');
	$self->set_pause_add_uri('http://pause.cpan.org/pause/authenquery');
	$self->set_ftp_user('ftp');
	$self->set_ftp_password('frodo@gandalf.org');
	$self->set_use_ftp_gateway(0);
	$self->set_ftp_gateway('');
	$self->set_use_ftp_proxy(0);
	$self->set_ftp_proxy('');
	$self->set_ftp(undef);
	$self->set_use_http_proxy(0);
	$self->set_http_proxy('');
	$self->set_program('');
	$self->set_version('');
	if($self->get_do_ftp()) {
		$self->ftp_init();
	}
	if($self->get_do_http()) {
		$self->http_init();
	}
}

sub upload($$) {
	my($self,$perlpkg)=@_;
	my($module)=Meta::Development::Module->new_name($perlpkg);
	my($perlpkg_obj)=Meta::Lang::Perl::Perlpkgs->new_modu($module);
	for(my($i)=0;$i<$perlpkg_obj->size();$i++) {
		my($pkg)=$perlpkg_obj->getx($i);
		my($file)=$pkg->get_pack_file_name();
		my($abs)=Meta::Baseline::Aegis::which($file);
		$self->verbose("doing package [".$file."] abs [".$abs."]\n");
		if($self->get_do_ftp()) {
			$self->verbose("before ftping\n");
			$self->ftp_upload($abs,$pkg);
			$self->verbose("after ftping\n");
		}
		if($self->get_do_http()) {
			$self->verbose("before pausing\n");
			$self->http_upload($abs,$pkg);
			$self->verbose("after pausing\n");
		}
	}
	return(1);
}

sub fast_upload($$) {
	my($self,$perlpkg)=@_;
	$self->init();
	$self->upload($perlpkg);
	$self->finish();
}

sub finish($) {
	my($self)=@_;
	if($self->get_do_ftp()) {
		$self->ftp_finish();
	}
	if($self->get_do_http()) {
		$self->http_finish();
	}
}

sub ftp_init($) {
	my($self)=@_;
	my(@args);
	my($ftp_site,$user);
	if($self->get_use_ftp_gateway()) {
		$ftp_site=$self->get_ftp_gateway();
		$user='ftp@'.$self->get_site();
	} else {
		$ftp_site=$self->get_site();
		$user=$self->get_ftp_user();
	}
	if($self->get_use_ftp_proxy()) {
		push(@args,'Firewall'=>$self->get_ftp_proxy());
	}
	$self->verbose("args are [".join(',',@args)."]\n");
	$self->verbose("ftp_site is [".$ftp_site."]\n");
	my($ftp)=Net::FTP->new($ftp_site,@args);
	$self->verbose("ftp is [".$ftp."]\n");
	if(!defined($ftp)) {
		throw Meta::Error::Simple("failed to connect to remote server with error [".$!."]");
	}
	if(!$ftp->login($user,$self->get_ftp_password()))
	{
		$ftp->quit();
		throw Meta::Error::Simple("failed to login as user [".$self->get_ftp_user()."] and password [".$self->get_ftp_password()."] with message [".$ftp->message()."] and code [".$ftp->code()."]");
	}
	$self->verbose("changing to [".$self->get_upload_dir()."] directory...\n");
	if(!$ftp->cwd($self->get_upload_dir()))
	{
		$ftp->quit();
		throw Meta::Error::Simple("failed to change directory to [".$self->get_upload_dir()."]");
	}

	$self->verbose("setting binary mode.\n");
	my($res)=$ftp->binary();
	if(!$res)
	{
		$ftp->quit();
		throw Meta::Error::Simple("failed to change mode to 'binary' with message [".$ftp->message()."] and code [".$ftp->code()."]");
	}
	$self->set_ftp($ftp);
}

sub ftp_upload($$$) {
	my($self,$file,$pack)=@_;
	$self->verbose("uploading file [".$file."]\n");
	my($ftp)=$self->get_ftp();
	my($res)=$ftp->put($file);
	if(!defined($res)) {
		throw Meta::Error::Simple("failed to upload with message [".$ftp->message()."]");
	}
}

sub ftp_finish($) {
	my($self)=@_;
	my($ftp)=$self->get_ftp();
	$self->verbose("closing connection with FTP server\n");
	my($res)=$ftp->quit();
	if(!$res) {
		throw Meta::Error::Simple("failed to quit with message [".$ftp->message()."]");
	}
}

sub http_init($) {
	my($self)=@_;
}

sub http_upload($$$) {
	my($self,$file,$pack)=@_;
	$self->verbose("registering upload with PAUSE web server\n");
	# Create the agent we'll use to make the web requests
	$self->verbose("creating instance of LWP::UserAgent\n");
	my($agent)=LWP::UserAgent->new();
	if(!defined($agent)) {
		throw Meta::Error::Simple("Failed to create UserAgent with error [".$!."]");
	}
	$agent->agent($self->get_program()."/".$self->get_version());
	$agent->from($pack->get_author()->get_cpan_mail());
	if($self->get_use_http_proxy()) {
		$agent->proxy(['http'],$self->get_http_proxy());
	}
	# Post an upload message to the PAUSE web site for each file
	my($basename)=File::Basename::basename($file);
	# Create the request to add the file
	my($request)=HTTP::Request::Common::POST($self->get_pause_add_uri(),
		{
			HIDDENNAME=>$pack->get_author()->get_cpan_user(),
			pause99_add_uri_upload=>$basename,
			SUBMIT_pause99_add_uri_upload=>" Upload the checked file "
		}
	);
	my($auth_user)=$pack->get_author()->get_cpan_user();
	my($auth_password)=$pack->get_author()->get_cpan_password();
	$request->authorization_basic($auth_user,$auth_password);
	$self->verbose("auth_user is [".$auth_user."]\n");
	$self->verbose("auth_password is [".$auth_password."]\n");
	$self->verbose("Request is [".$request."]\n");
	# Make the request to the PAUSE web server
	$self->verbose("POST upload for [".$file."] with basename [".$basename."]\n");
	my($response)=$agent->request($request);
	if(!defined($response)) {
		throw Meta::Error::Simple("request completely failed - we got undef back with error [".$!."]");
	}
	if($response->is_error()) {
		if($response->code=="RC_NOT_FOUND") {
			throw Meta::Error::Simple("PAUSE's CGI for handling messages seems to have moved!".
			"(HTTP response code of 404 from the PAUSE web server)\n".
			"It used to be:\n\n\t".$self->get_pause_add_uri()."\n\n".
			"Please inform the maintainer of this script\n");
		} else {
			throw Meta::Error::Simple("request failed with error [".$response->code."] and message [".$response->message."]");
		}
	} else {
		$self->verbose("response is [".$response->as_string()."]\n");
		$self->verbose("PAUSE add message sent ok [".$response->code."]\n");
	}
}

sub http_finish($) {
	my($self)=@_;
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Lang::Perl::Upload - automatically upload a module to cpan.

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

	MANIFEST: Upload.pm
	PROJECT: meta
	VERSION: 0.08

=head1 SYNOPSIS

	package foo;
	use Meta::Lang::Perl::Upload qw();
	my($uploader)=Meta::Lang::Perl::Upload->new();
	$uploader->set_do_ftp(1);
	$uploader->set_do_http(1);
	$uploader->fast_upload("my_first_package.xml);

=head1 DESCRIPTION

Give this module the information it needs and it will upload a module
to cpan for you. The information that you need to supply is a XML/PERLPKG
type file describing your package. Please refer to the XML/PERLPKG DTD
and it's documentation to check out how to fill this XML file out.
This XML file contains your user id on CPAN, your CPAN password and the
name of the package file that needs to be uploaded amongs other things.

How do you use the module ? Create an object of this type, call it's
init modules, then call it's upload methos for each package XML file
and at the end call the finish method.

How does it do it ? The process is composed of two issues: FTPing the
file to the CPAN ftp server and notifying (via HTTP just like the
regular user does it with his browser) the PAUSE engine of the new
file and to which person it belongs. The first task is accoplished
by using Net::FTP and the second using LWP::UserAgent.

The module is object oriented so you can have as many upload objects
as you want working in parallel...:)

The idea behind this module is that you could automate your release
process by putting a very small script (the package that you got this
in should already supply you with such a script) which you can use
at the end of your development cycle to automagically upload the end
product to CPAN (instead of all the manual clicking and web browsing).

=head1 FUNCTIONS

	BEGIN()
	new($)
	init($)
	upload($$)
	finish($)
	ftp_init($)
	ftp_upload($$$)
	ftp_finish($)
	http_init($)
	http_upload($$$)
	http_finish($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<BEGIN()>

Setup some accessor methods for this class.
Attributes are:

=item B<new($)>

This is a constructor for the Meta::Lang::Perl::Upload object.
This method does internal house keeping.

=item B<init($)>

Initialize the upload process (this includes access to the internet
and making the relevant persistant connections).

=item B<upload($$)>

This method does the actual uploading based on the HTTP protocol.
The method receives an uploader object and an XML/PERLPKG file
with a description of the package. The method proceeds to
calculate where the output package should be, and then uploads
the package.

=item B<fast_upload($$)>

This method is a wrapper method to do init, upload and finish for you.

=item B<finish($)>

This declares you are finished with the object. FTP and HTTP connections
are closed and you can no longer use the upload method. Please call this
method and don't just leave the connections dangling.

=item B<ftp_init($)>

Internal method.
Inits the FTP process by opening a binary mode FTP
connection to the CPAN FTP server.

=item B<ftp_upload($$$)>

Internal method.
Receives a file. The method does the actual ftping.

=item B<ftp_finish($)>

Internal method.
Shuts down the FTP part of the upload process by terminating
the FTP connection.

=item B<http_init($)>

Internal method.
This method initializes the HTTP part of the process. Currently does
nothing and the actual work is being done in http_upload.

=item B<http_upload($$$)>

Internal method.
This method receives a file and uses the HTTP agent in Perl to notify the
PAUSE of the new file. This method needs your valid CPAN user id and password.

=item B<http_finish($)>

Internal method.
This method terminates the HTTP part of the process. Currently this method
does nothing since all of the work is done in http_upload.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Development::Verbose(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site development
	0.01 MV web site automation
	0.02 MV SEE ALSO section fix
	0.03 MV put all tests in modules
	0.04 MV move tests to modules
	0.05 MV bring movie data
	0.06 MV weblog issues
	0.07 MV teachers project
	0.08 MV md5 issues

=head1 SEE ALSO

File::Basename(3), HTTP::Request::Common(3), LWP::UserAgent(3), Meta::Class::MethodMaker(3), Meta::Development::Verbose(3), Meta::Lang::Perl::Perlpkgs(3), Net::FTP(3), strict(3)

=head1 TODO

-add option for this module to update the pause engine with a new homepage, new email address and all
	the other preferences that they have.
