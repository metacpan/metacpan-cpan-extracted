#!/usr/bin/perl
#-*-CPerl-*-

BEGIN {require "local_inc.pl";}

use strict;
use vars(qw/$conf_path/);
use HtDig::Site;
use HtDig::Config;
use CGI;
require "proc_tpl.pl";
require "cgi_settings.pl";

my $cgi = new CGI;

#Check to make sure they provided a site to view
my $site_name = $cgi->param("site");
my $safe_site_name = $cgi->escape($site_name);
if (!$site_name) {
  print $cgi->redirect("index.cgi?e=No+site+specified");
  exit;
}

#Get the site object, redirect if failure
my $htdig = new HtDig::Config(conf_path=>$conf_path);
my $site = $htdig->get_site($site_name);
if (!$site) {
  print $cgi->redirect("index.cgi?e=No+such+site");
  exit;
}

#Update with new values if it was requested
if ($cgi->param("action") eq "Update") {
  my @params = $cgi->param();
  for my $param (@params) {
    if (my ($stg) = $param =~ /^stg\_(.+)/) {
      my $val = $cgi->param($param);
      $val =~ s/\n/\\\n/g;
      $site->setting($stg, $cgi->param($param));
    }    
  }
  
  #Add new stock key and value if they provided them
  if ($cgi->param("new_stock_key")) {
    $site->setting($cgi->param("new__stock_key"), $cgi->param("new_stock_value"));
  }

  #Add new key and value if they provided them
  if ($cgi->param("new_key")) {
    $site->setting($cgi->param("new_key"), $cgi->param("new_value"));
  }

  if (!$site->save()) {
    $T::status_msg = $site->errstr;
    #Current state is indeterminate, so get a fresh object
    $site = $htdig->get_site($site_name);
  }
}

#Set template namespace values
@T::settings = $site->{settings};
$T::site_name = $site_name;
$T::safe_site_name = $safe_site_name;
$T::site_path = $site->{conf_path};

#Create the settings grid
for my $key (keys %{$site->{settings}}) {
  next if !$key;
  my $value = $site->_setting2string($site->{settings}->{$key});
  my $rows = $value =~ s/\\//g;

  $T::settings_grid .= qq|
<TR class="sgRow"><TD class="sgLabelCell">$key</TD>
<TD class="sgValueCell"><textarea name="stg_$key" cols="40" rows="$rows">| . $value . qq|</textarea></TD>
</TR>\n|;
}

#Create stock properties drop-down
@T::stock_properties = keys(%{$site->datatypes});
for my $prop (@T::stock_properties) {
  if (!$site->setting($prop)) {
    $T::stock_props_list .= qq|<option value="$prop">$prop</option>\n|;
  }
}

$T::settings_grid .=  qq|
<TR valign="top" class="sgRow"><TD class="sgLabelCell">New stock property:<BR><select name="new_stock_key">| . $T::stock_props_list . qq|</select></TD>
<TD valign="top" class="sgValueCell">New stock property value:<BR><textarea name="new_stock_value" cols="40" rows="2"></textarea></TD>
</TR>\n
|;

#Append free form setting box
$T::settings_grid .=  qq|
<TR valign="top" class="sgRow"><TD class="sgLabelCell">New custom setting name:<BR><input name="new_key"></TD>
<TD valign="top" class="sgValueCell">New custom setting value:<BR><textarea name="new_value" cols="40" rows="2"></textarea></TD>
</TR>\n
|;

#Generate output
proc_tpl($cgi);

__END__

=head1 NAME

ConfigDig - edit_site.cgi

=head1 DESCRIPTION

edit_site.cgi 

Buttons on the edit_site.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
view_site.cgi (with CGI input variable site indicating which site is being managed)

=back

The template should also provide a way of inputting new values for each of the site specific settings currently defined in the site configuration file, as well as providing a way to specify new settings to add.

=head1 CGI INPUTS

edit_site.cgi can process the following CGI parameters:

=over 4

=item *
site - Indicates what site is being managed.

=item *
action - Indicates what action to take.  The only recognized value is "Update".  When present, it causes the new settings values to be committed.  Otherwise, the template is processed.

=item *
new_stock_key - Indicates that the setting defined in this parameter should be given the value defined in the new_stock_value parameter.

=item *
new_key - Indicates that the setting defined in this parameter should be given the value defined in the new_value parameter.

=item *
stg_* - Any CGI parameter beginning with stg_ is assumed to be related to a setting in the site's configuration.  The part of the parameter name following stg_ is assumed to be the setting's name, and the parameter's value is assumed to be its desired new value.

=back

=head1 TEMPLATE OUTPUTS

edit_conf.cgi creates the following variables in the "T" namespace for use in templates:

=over 4

=item *
$T::status_msg - An error/status message to be displayed.

=item *
$T::settings_grid - An HTML table containing the name of each currently defined setting and an input box for the value (preset to the current setting value).

=item *
@T::stock_properties - Contains an array indicating the stock settings that are documented for ht://Dig conf files.  Useful for creating an option list for new settings values.

=item *
@T::stock_props_list - Contains an HTML <option> list of stock settings that are documented for ht://Dig conf files.

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
