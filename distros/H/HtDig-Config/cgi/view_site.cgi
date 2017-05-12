#!/usr/bin/perl
#-*-CPerl-*-

BEGIN {require "local_inc.pl";}

use strict;
use vars(qw/$conf_path/);
use HtDig::Site;
use HtDig::Config;
use Date::Manip;
use File::Spec;
use CGI;
require "proc_tpl.pl";
require "cgi_settings.pl";

my $cgi = new CGI;

#Check to make sure they provided a site to view
my $site_name = $cgi->param("site");
if (!$site_name) {
  print $cgi->redirect("index.cgi?e=" . $cgi->escape("Couldn't display info: No site specified"));
  exit;
}

#Get the site object, redirect if failure
my $htdig = new HtDig::Config(conf_path=>$conf_path);
my $site;
eval('$site = $htdig->get_site($site_name)');
if ($@ and $cgi->param("action") ne "Unregister") {
  print $cgi->redirect("index.cgi?e=" . $cgi->escape("Couldn't access site: $@"));
  exit;
}

my $action = $cgi->param("action");
my $safe_site_name = $cgi->escape($site_name);

#Action switchboard
if ($action eq "Unregister") {
  $htdig->delete_site(site_name=>$site_name);
  if($htdig->save()) {
    print $cgi->redirect("index.cgi?e=" . $cgi->escape("Site unregistered (configuration file remains)"));
  }
  else {
    print $cgi->redirect("index.cgi?e=" . $cgi->escape("Couldn't unregister site: " . $htdig->errstr));
  }
  exit;
}
elsif ($action eq "edit") {
  print $cgi->redirect("edit_site.cgi?site=" . $safe_site_name);
  exit;
}
elsif ($action eq "fuzzy") {
  my $index_type = $cgi->param("index_type");
  if (my $pid = $site->generate_fuzzy_index(type=>$index_type)) {
    $T::status_msg .= "Fuzzy index creation initiated.  PID $pid.";
  }
  else {
    $T::status_msg .= "Error: " . $site->errstr;
  }
}
elsif ($action eq "dig_later") {
  my $at_time = $cgi->param("dig_time");
  my $notify = $cgi->param("notify_later");
  if(my $ID = $site->dig(at=>$at_time, notify=>$notify)) {
    $T::status_msg = "Site indexing process scheduled: at job #$ID";
  }
  else {
    $T::status_msg = $site->errstr;
  }
}
elsif ($action eq "dig_now") {
  if(my $PID = $site->dig(notify=>$cgi->param("notify_now"))) {
    $T::status_msg = "Site indexing process initiated: PID $PID";
  }
  else {
    $T::status_msg = $site->errstr;
  }
}
elsif ($action eq "merge") {
  my $merge_site = $cgi->param("merge_site");
  if (my $pid = $site->merge(type=>$merge_site, verbosity=>3)) {
    $T::status_msg .= "Merge initiated.  PID $pid.";
  }
  else {
    $T::status_msg .= "Error: " . $site->errstr;
  }
}

#Set template namespace values
$T::status_msg .= $cgi->param("e"); 
@T::settings = $site->{settings};
$T::site_name = $site_name;
$T::safe_site_name = $safe_site_name;
$T::site_path = $site->{conf_path};

#Create list of sites other than this one
for my $other_site ($htdig->sites) {
    $T::other_site_list .= qq|
      <option value="$other_site">$other_site</option>
| unless $other_site eq $site_name;
}

#Create list of supported fuzzy index types
for my $fuzzy_type ($site->fuzzy_types) {
    $T::fuzzy_type_list .= qq|
      <option value="$fuzzy_type">$fuzzy_type</option>
|;
}



#Generate output
proc_tpl($cgi);

__END__

=head1 NAME

ConfigDig - view_site.cgi

=head1 DESCRIPTION

view_site.cgi is the primary switchboard for administering a single ht://Dig site configuration.  It allows actions such as starting digs, merging sites, generating fuzzy indexes and jumping to the configuration editor page.

Buttons on the view_site.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
index.cgi (typically through a hyperlink, with no CGI input)

=back

The template should also provide a way of selecting from the following commands, which will send CGI input back to the view_site.cgi:

=over 4

=item *
Site configuration modification

=item *
Fuzzy index creation

=item *
Scheduled site indexing (broken in beta)

=item *
Immediate site indexing run

=item *
Merging another database into the current site's database

=back

=head1 CGI INPUTS

view_site.cgi can process the following CGI parameters:

=over 4

=item *
e - This parameter indicates an error/status message to display.

=item *
site - This parameter indicates the name of the ConfigDig site to be managed.

=item *
action - This parameter indicates the action to be taken.  Should be one of the following:

=over 4

=item *
Unregister - Indicates that the site defined in the site parameter should be removed from the ConfigDig registry.

=item *
fuzzy - Indicates that a fuzzy index of the type defined in the index_type parameter should be created using htfuzzy.

=item *
dig_later - Indicates that a rundig process should be scheduled.  Desired time is stored in the dig_time parameter.

=item *
dig_now - Indicates that an immediate site indexing process should be started using rundig.  Presence of the notify_now parameter indicates that email should sent to the addresses listed in the ht://Dig custom setting configdig_notify when the site indexing process is complete.

=item *
merge - Indicates that the site named in the merge_site parameter should be merged using htmerge.

=back

=back

=head1 TEMPLATE OUTPUTS

index.cgi creates the following variables in the "T" namespace for use in templates:

=over 4

=item *
$T::status_msg - An error/status message to be displayed.

=item *
@T::settings - Contains an array indicating the stock settings that are documented for ht://Dig conf files.  Useful for creating an option list for new settings values.

=item *
$T::site_name - Name of the site being managed as registered with ConfigDig

=item *
$T::safe_site_name - URL-encoded name of the site, because ConfigDig site names might contain characters that are considered illegal for URLs, such as spaces.

=item *
$T::site_path - Filesystem location of the site's conf file.

=item *
$T::other_site_list - String containing an HTML <option> list of other registered ht://Dig sites.  Useful for allowing input in the template for merges into this site.

=item *
$T::fuzzy_type_list - String containing an HTML <option> list of known types of fuzzy indexes that htfuzzy can create.

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
