use strict;
use vars(qw/$cgi/);
use Text::Template;
sub proc_tpl {
        my ($cgi) = @_;
	print "Content-type: text/html\n\n";
	my ($file) = @_;
	my ($this_file);
#	print "Filename: $0\n<BR>";
	if ($0 =~ /\//) {
	  ($this_file) = $0 =~ m|/([^/]+)$|;
	}
	else {
	  $this_file = $0;
	}
	if (!-f "./tpl/$this_file.html") {
	  print "Can't locate template $this_file.html\n";
	  exit;
	}
	my $tpl_file = "./tpl/$this_file.html";
	my $tpl =
		Text::Template->new(	TYPE=>'FILE',
					SOURCE=>"$tpl_file",
					);
	$cgi->header();
	print $tpl->fill_in(PACKAGE=>'T', DELIMITERS=>['<%','%>']);
}

1;
__END__


__END__

=head1 NAME

ConfigDig - proc_tpl.pl

=head1 DESCRIPTION

proc_tpl.pl provides templating capability in which a cgi can have an html template that contains perl variables embedded inside <% %> delimiters.  The cgi must place values for the embedded perl variables into the "T" namespace.  It contains a single subroutine called proc_tpl which does all the work.

The script uses the Text::Tempate modules for the  variable interpolation.  See Text::Template for more information.

The assumption is that no text has been output by the calling cgi script before proc_tpl() is called.  proc_tpl() figures out what template to use by appending .html onto the end of the current cgi script's filename and looking for the resulting filename in a tpl subdirectory immediately below the current directory.  Thus, the cgi script /docs/script.cgi would have a template in this location /docs/tpl/script.cgi.html

=head1 SUBROUTINE INPUTS

proc_tpl() requires a single parameter, a reference to the CGI object that has been used to process the current cgi script's CGI parameters.  It uses this CGI object to print out headers for the HTML it creates by processing the template.

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
