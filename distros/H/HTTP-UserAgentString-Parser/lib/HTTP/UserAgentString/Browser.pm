package HTTP::UserAgentString::Browser;

=head1 NAME

HTTP::UserAgentString::Browser - Web browser 

=head1 SYNOPSIS

 $browser = $p->parse($string)

 print "This is a ", ($browser->isRobot()) ? "robot" : "browser", "\n";
 print "Name: ", $browser->name(), "\n";
 print "Version: ", $browser->version(), "\n";
 print "URL: ", $browser->url(), "\n";
 print "Company: ", $browser->company(), "\n";
 print "Company URL: ", $browser->company_url(), "\n";
 print "Info URL: ", $browser->info_url(), "\n";
 print "Type: ", $browser->type(), "\n";
 
 $os = $browser->os();

=head1 DESCRIPTION

Used to represent web browsers returned by L<HTTP::UserAgentString::Parser>.  Object is read
only.  Accesors are provided for all capabilities defined by
user-agent-string.info

=head1 METHODS

=over 4

=item $browser->name()

Browser name.  Example: "Firefox"

=item $browser->version()

String version. Example: "3.5"

=item $browser->url()

Web page for the browser

=item $browser->company()

Name of the company that develops the browser 

=item $browser->company_url()

URL of the company that develops the browser

=item $browser->ico()

PNG icon for the browser that can be obtained from http://user-agent-string.info/pub/img/ua/

=item $browser->info_url()

Web page in http://user-agent-string.info/ that provides information on the browser

=item $browser->type()

Numeric type (see browser_type_id[] in the .ini file)
More accessors are provided to check for type:

=over 4

=item $browser->typeDesc()

String description for the browser's type. 

=item $browser->isBrowser()

Check for standard web browser

=item $browser->isOffline()

Check for offline web browsers

=item $browser->isMobile()

Check for mobile web browsers

=item $browser->isEmail()

Check for e-mail clients

=item $browser->isWAP()

Check for WAP browsers

=item $browser->isLibrary()

Check for HTTP libraries

=back 

=item $browser->os

If defined, L<HTTP::UserAgentString::OS> object representing the operating system 
where the browser is running.

=back

=head1 SEE ALSO

L<HTTP::UserAgentString::OS> for the class representing operating systems, and 
L<HTTP::UserAgentString::Robot> for robots.

=head1 COPYRIGHT

 Copyright (c) 2011 Nicolas Moldavsky (http://www.e-planning.net/)
 This library is released under LGPL V3

=cut

use strict;
use base qw(HTTP::UserAgentString::Sys);

my @KEYS = qw(type name url company company_url ico info_url);

my $BROWSER = 0;
my $OFFLINE = 1;
my $MOBILE = 3;
my $EMAIL = 4;
my $LIBRARY = 5;
my $WAP = 6;

sub new($$$;$$) {
	my ($pkg, $data, $typeDesc, $version, $os) = @_;
	
	my $h = {};
	for (my $i = 0; $i < scalar(@KEYS); $i++) {
		my $val = $data->[$i];
		if (defined($val) and (length($val) > 0)) {
			$h->{$KEYS[$i]} = $val;
		}
	}
	$h->{os} = $os;
	$h->{version} = $version;
	if (defined($version)) {
		my @v = split(/\./, $version);
		if (@v) {
			$h->{major_version} = shift(@v);
			if (@v) {
				$h->{minor_version} = shift(@v);
			}
		}
	}
	
	$h->{typeDesc} = $typeDesc;
	return bless($h, $pkg);
}

sub type($) { $_[0]->{type} }
sub info_url($) { $_[0]->{info_url} }
sub os($) { $_[0]->{os} }
sub version($) { $_[0]->{version} }
sub major_version($) { $_[0]->{major_version} }
sub minor_version($) { $_[0]->{minor_version} }
sub typeDesc($) { $_[0]->{typeDesc} }

sub isRobot($) { 0 }

sub isBrowser($) { $BROWSER == $_[0]->type }
sub isOffline($) { $OFFLINE == $_[0]->type }
sub isMobile($) { $MOBILE == $_[0]->type }
sub isEmail($) { $EMAIL == $_[0]->type }
sub isLibrary($) { $LIBRARY == $_[0]->type }
sub isWAP($) { $WAP == $_[0]->type }

1;
