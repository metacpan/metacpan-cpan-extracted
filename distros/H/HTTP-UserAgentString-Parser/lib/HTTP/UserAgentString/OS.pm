package HTTP::UserAgentString::OS;

=head1 NAME

HTTP::UserAgentString::OS - Operating system

=head1 SYNOPSIS

 $os = $browser->os()

 print "Name: ", $os->name(), "\n";
 print "Family: ", $os->family(), "\n";
 print "URL: ", $os->url(), "\n";
 print "Company: ", $os->company(), "\n";
 print "Company URL: ", $os->company_url(), "\n";

=head1 DESCRIPTION

Used to represent operating systems returned where browsers or
robots run.  The class is read only.  Accesors are provided for 
all capabilities defined by user-agent-string.info

=head1 METHODS

=over 4

=item $os->name()

OS name (includes version).  Example: Windows 95

=item $os->family()

OS family. I.e: Windows

=item $os->url()

Web page for the OS

=item $os->company()

Name of the company that develops the OS

=item $os->company_url()

URL of the company that develops the OS

=item $os->ico()

Icon for the OS, found in http://user-agent-string.info/pub/img/os/

=back

=head1 COPYRIGHT

 Copyright (c) 2011 Nicolas Moldavsky (http://www.e-planning.net/)
 This library is released under LGPL V3

=cut

use strict;
use base qw(HTTP::UserAgentString::Sys);

my @KEYS = qw(family name url company company_url ico);

sub new($$) {
	my ($pkg, $data) = @_;
	
	my $h = {};
	for (my $i = 0; $i < scalar(@KEYS); $i++) {
		my $val = $data->[$i];
		if (defined($val) and (length($val) > 0)) {
			$h->{$KEYS[$i]} = $val;
		}
	}
	return bless($h, $pkg);
}

sub family($) { $_[0]->{family} }
sub ico($) { $_[0]->{ico} }
sub name($) { $_[0]->{name} }
sub company($) { $_[0]->{company} }
sub company_url($) { $_[0]->{company_url} }
sub url($) { $_[0]->{url} }

1;
