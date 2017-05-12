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

#Get the config object
my $htdig = new HtDig::Config(conf_path=>$conf_path);

#If the action is "Perform Autodetect, they've already
# seen the path entry page and have confirmed the action
if ($cgi->param("action") eq "Perform Autodetection") {
  my @paths = split(/ +/, $cgi->param("search_paths"));
  my $sites_found = $htdig->autodetect(paths=>\@paths);
  if ($htdig->errstr) {
   $T::status_msg = $htdig->errstr;
   $T::status_msg =~ s/\n/<BR>\n/g;
  }
  else {
    $htdig->save();
    print $cgi->redirect("index.cgi?e=" . $cgi->escape("$sites_found site" . ($sites_found > 1 ? "s" : "") . " found"));
    exit;
  }
}

#Generate output
proc_tpl($cgi);

__END__

=head1 NAME

ConfigDig - autodetect.cgi

=head1 DESCRIPTION

autodetect.cgi allows the autodetection of pre-existing ht://Dig conf files in user-defined directories.

Buttons on the view_site.cgi.html template's form(s) should provide links to the following CGI scripts:

=over 4

=item *
index.cgi (typically through a hyperlink, with no CGI input)

=back

The template should also provide a way of inputting a whitespace delimited list of directories to search during autodetection.  The list should be sent back to autodetect.cgi as the search_paths parameter.

=head1 CGI INPUTS

autodetect.cgi can process the following CGI parameters:

=over 4

=item *
search_paths - A whitespace delimited list of directories to search during autodetection.  Optional.

=item *
action - This parameter indicates the action to be taken.  The only recognized value is Perform Autodetection and its presence indicates that autodetection should be performed immediately and the user should be redirected to index.cgi.  Without it, the script will process its template.

=back

=head1 TEMPLATE OUTPUTS

autodetect.cgi creates the following variables in the "T" namespace for use in templates:

=over 4

=item *
$T::status_msg - An error/status message to be displayed.

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
