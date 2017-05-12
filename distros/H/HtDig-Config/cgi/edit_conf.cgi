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

#Update with new values if it was requested
if ($cgi->param("action") eq "Update") {

  #The global settings are hard-coded, and are only relevant to
  # the ConfigDig objects themselves
  my $log_path = $cgi->param("log_path");
  my $base_path = $cgi->param("base_path");
  if ($log_path) {
    if (-d $log_path) {
      $htdig->{configdig_log_path} = $log_path;
    }
    else {
      $T::status_msg .= "Invalid path setting for ConfigDig Log Path";
    }
  }

  if ($base_path && !$T::status_msg) {
    if (-d $base_path) {
      $htdig->{htdig_base_path} = $base_path;
    }
    else {
      $T::status_msg .= "Invalid path setting for htDig Base Path";
    }
  }

  if (!$T::status_msg) {
    if (!$htdig->save()) {
      $T::status_msg = $htdig->errstr;
      #Current state is indeterminate, so get a fresh object
      $htdig = new HtDig::Config(conf_path=>$conf_path);
    }
    else {
      $T::status_msg = "Global settings successfully saved";
    }
  }
}

#Set template namespace values
$T::log_path = $htdig->{configdig_log_path};
$T::base_path = $htdig->{htdig_base_path};

#Generate output
proc_tpl($cgi);


__END__

=head1 NAME

ConfigDig - edit_conf.cgi

=head1 DESCRIPTION

edit_conf.cgi allows the user to edit the main ConfigDig settings that are the same for all site operations.

Buttons on the view_site.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
index.cgi (typically through a hyperlink, with no CGI input)

=back

The template should also provide a way of inputting new values for each of the global settings listed in CGI INPUTS.

=head1 CGI INPUTS

edit_conf.cgi can process the following CGI parameters:

=over 4

=item *
log_path - Indicates a place where ConfigDig can keep its log files.  A good location is a "log" directory in the ht://Dig installation directory (see base_path).

=item *
base_path - Indicates where the ht://Dig system is installed.  Usually something like /opt/www/

=item *
action - Indicates what action to take.  The only recognized value is "Update".  When present, it causes the new settings values to be committed.  Otherwise, the template is processed.

=back

=head1 TEMPLATE OUTPUTS

edit_conf.cgi creates the following variables in the "T" namespace for use in templates:

=over 4

=item *
$T::status_msg - An error/status message to be displayed.

=item *
$T::log_path - The current value for this global setting.

=item *
$T::base_path - The current value for this global setting.

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
