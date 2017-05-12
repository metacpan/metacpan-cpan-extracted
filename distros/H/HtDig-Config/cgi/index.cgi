#!/usr/bin/perl 
#-*-CPerl-*-

BEGIN {require "local_inc.pl";}

use strict;
use vars(qw/$conf_path/);
use HtDig::Config;
use CGI;
require "proc_tpl.pl";
require "cgi_settings.pl";

my $cgi = new CGI;
my $htdig = new HtDig::Config(conf_path=>$conf_path, auto_create=>1);

#Error messages from other cgis get sent in as "e"
if ($cgi->param("e")) {
  $T::status_msg = $cgi->param("e");
}

@T::sites = $htdig->sites();

for my $site (@T::sites) {
  $T::site_list .= qq|<option value="$site">$site</option>\n|;
}

#Generate output
proc_tpl($cgi);

__END__

=head1 NAME

ConfigDig - index.cgi

=head1 DESCRIPTION

index.cgi is the main screen for managing registered ht://Dig sites.  Its primary function is to allow the user to access other functional areas.  It also displays error/status messages passed in as a CGI param.  Buttons on the index.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
view_site.cgi

=item *
new_site.cgi

=item *
autodetect.cgi

=back

The template should also provide a way of selecting a site to remove from the registry.  The CGI data from this "remove" action should be sent view_site.cgi

=head1 CGI INPUTS

index.cgi can process the following CGI parameters:

=over 4

=item *
e - This parameter indicates an error/status message to display.

=back

=head1 TEMPLATE OUTPUTS

index.cgi creates the following variables in the "T" namespace for use in templates:

=over 4

=item *
@T::sites - This array contains a list of registered ht://Dig site names.  Mainly for use in creating a custom listing of the available sites.

=item *
$T::site_list - This scalar contains a string of HTML <option> tags that will display the list of registered sites.

=back

(see perldoc for proc_tpl.pl for more information on template usage)

=head1 KNOWN ISSUES

=head1 AUTHOR

James Tillman <jtillman@bigfoot.com>
CPAN PAUSE ID: jtillman

=head1 SEE ALSO

=over 4

=item *
HtDig::Config

=item *
HtDig::Site

=item *
Other ConfigDig cgi perldocs

=item *
perl(1)

=back

=cut
