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
my $htdig = new HtDig::Config(conf_path=>$conf_path);

@T::sites = $htdig->sites();

if ($cgi->param("action") eq "Register") {
  my $site_name = $cgi->param("name");
  my $conf_path = $cgi->param("path");
  my $auto_create = $cgi->param("auto_create");
  if ($htdig->add_site(site_name=>$site_name, conf_path=>$conf_path, auto_create=>$auto_create)) {
    if ($htdig->save()) {
      print $cgi->redirect("index.cgi?e=Site+registered+successfully");
    }
    else {
      print $cgi->redirect("index.cgi?e=" . $cgi->escape($htdig->errstr));
    }
    exit;
  }
  else {
    print $cgi->redirect("index.cgi?e=" . $cgi->escape($htdig->errstr));
    exit;
  }
}
elsif ($cgi->param("action") eq "Cancel") {
  print $cgi->redirect("index.cgi?e=Operation%20Cancelled");
  exit;
}

#Generate output
proc_tpl($cgi);

__END__

=head1 NAME

ConfigDig - new_site.cgi

=head1 DESCRIPTION

new_site.cgi allows registration of a new ht://Dig conf file with the ConfigDig system.  It can also create the file if it doesn't exist.

Buttons on the new_site.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
index.cgi (typically with a hyperlink, no CGI input)

=back

The template should also provide a way of specifying a file path to an ht://Dig conf file and a name to give to the newly registered site.  The CGI parameters should be sent to new_site.cgi for processing.

=head1 CGI INPUTS

new_site.cgi can process the following CGI parameters:

=over 4

=item *
action - Indicates what action to take.  The only recognized value is "Register".  When present, it causes the other CGI variables to be used for registering the new site.  Otherwise, the template is processed.

=item *
name - Indicates the desired name for the new site.

=item *
path - Indicates the path to the conf file for the new site

=item *
auto_create - When present, indicates that the conf file should be created if it can't be found.

=back

=head1 TEMPLATE OUTPUTS

None.  The template is displayed verbatim.

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
