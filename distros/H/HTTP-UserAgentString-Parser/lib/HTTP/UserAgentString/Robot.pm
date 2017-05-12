package HTTP::UserAgentString::Robot;

=head1 NAME

HTTP::UserAgentString::Robot - Web robot 

=head1 SYNOPSIS

 $robot = $p->parse($string)

 print "This is a ", ($robot->isRobot()) ? "robot" : "browser", "\n";
 print "Family: ", $robot->family(), "\n";
 print "Name: ", $robot->name(), "\n";
 print "URL: ", $robot->url(), "\n";
 print "Company: ", $robot->company(), "\n";
 print "Company URL: ", $robot->company_url(), "\n";
 print "Info URL: ", $robot->info_url(), "\n";
 
 $os = $robot->os();

=head1 DESCRIPTION

Used to represent web robots returned by L<HTTP::UserAgentString::Parser>.  Object is read
only.  Accesors are provided for all capabilities defined by
user-agent-string.info

=head1 METHODS

=over 4

=item $robot->family()

Robot family. I.e, name without version.

=item $robot->name()

Robot name including version

=item $robot->url()

Web page for the robot

=item $robot->company()

Name of the company that develops the robot 

=item $robot->company_url()

URL of the company that develops the robot

=item $robot->ico()

PNG icon for the robot that can be obtained from http://user-agent-string.info/pub/img/ua/

=item $robot->info_url()

Web page in http://user-agent-string.info/ that provides information on the robot

=item $robot->os

If defined, L<HTTP::UserAgentString::OS> object representing the operating system where the robot is
running.

=back

=head1 SEE ALSO

L<HTTP::UserAgentString::OS> for the class representing operating systems, and L<UAS::Browser> 
for browsers.

=head1 COPYRIGHT

 Copyright (c) 2011 Nicolas Moldavsky (http://www.e-planning.net/)
 This library is released under LGPL V3

=cut

use strict;
use base qw(HTTP::UserAgentString::Sys);

my @KEYS = qw(uastring family name url company company_url ico os_id info_url);

sub new($$;$) {
	my ($pkg, $data, $os) = @_;
	
	my $h = {};
	for (my $i = 0; $i < scalar(@KEYS); $i++) {
		my $val = $data->[$i];
		if (defined($val) and (length($val) > 0)) {
			$h->{$KEYS[$i]} = $val;
		}
	}
	$h->{os} = $os;
	return bless($h, $pkg);
}


sub uastring($) { $_[0]->{uastring} }
sub family($) { $_[0]->{family} }
sub info_url($) { $_[0]->{info_url} }
sub os($) { $_[0]->{os} }
sub os_id($) { $_[0]->{os_id} }

sub isRobot($) { 1 }

1;
