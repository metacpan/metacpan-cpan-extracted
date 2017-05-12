package HTML::Merge::Development;

use CGI qw/:standard/;
use HTML::Merge::Error;
use strict qw(vars subs);
use warnings;
require Exporter;

use vars qw(@ISA @EXPORT $merge_absolute_path $merge_script $extra $file $year);

@ISA = qw(Exporter);
@EXPORT = qw($merge_absolute_path $merge_script $extra ReadConfig $file $year);

$year = (localtime)[5] + 1900;

# Functions ######################################################
sub OpenToolBox
{
	my $url = &MakeLink("toolbox.pl");

	print <<EOM;
<SCRIPT LANGUAGE="JavaScript">
<!--
open("$url&__MERGE_DEV_LIVE__=1","MergeToolBoxTarget","screenY=20,top=20,screenX=20,left=20,width=180,height=265,status=no,scrollbars=yes,toolbar=no,menubar=no,copyhistory=no,resizable=no");
// --->
</SCRIPT>
EOM
}
##################################################################
sub MakeLink 
{
	my ($script, $more) = @_;

	$more = "&$more" if $more;
	return "$HTML::Merge::Ini::MERGE_PATH/private/perl/$script?merge_absolute_path=$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH&merge_script=$HTML::Merge::Ini::MERGE_SCRIPT$more";
}
##################################################################
sub MakeDefault 
{
	my ($sub) = @_;

	return "$HTML::Merge::Ini::MERGE_PATH/$HTML::Merge::Ini::MERGE_SCRIPT?__default__=yes&sub=$sub";
}
##################################################################
sub DefaultPage 
{
	print <<HTML;

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">

<HTML>
<HEAD>
	<TITLE>Merge</TITLE>
</HEAD>

<BODY BGCOLOR='white'>

<FONT FACE=Arial SIZE=6 COLOR=black><CENTER><B>Merge</B>
</CENTER></FONT><BR>
<CENTER><TABLE BGCOLOR=yellow><TR><TD><FONT FACE=Arial SIZE=5 COLOR=black>
RAZ Information System LTD.
</TD></TR></TABLE></CENTER></FONT>
<BR><BR>
<FONT FACE=Arial SIZE=4 COLOR=black><CENTER>
</CENTER></FONT>
<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR>
<CENTER>
<BR>
<BR>
<FONT FACE=Arial SIZE=2 COLOR=black>
Merge(c) 1999-$year&nbsp;&nbsp;</FONT>
<A HREF="http://www.raz.co.il"><FONT FACE=Arial SIZE=2 COLOR=black>
http://www.raz.co.il
</FONT></A><BR>
</CENTER>
</FORM>
</BODY>
</HTML>
HTML
}
##################################################################
sub Transfer 
{
	foreach (qw(merge_absolute_path merge_script)) 
	{
		printf qq(<INPUT TYPE=HIDDEN NAME="%s" VALUE="%s">\n), $_, (param($_)||"");
	}
}
##################################################################
sub ReadConfig 
{
	my ($dont) = @_;
	my @extra;

	foreach (qw(merge_absolute_path merge_script))
	{
		$$_ = param($_) || '';
		$merge_script =~ s|/.*$||;
		push(@extra, "$_=$$_");
	}

	$extra = join("&", @extra);
	$file = "$merge_absolute_path/$merge_script";
	$file =~ s/\.\w+$/.conf/;
	$HTML::Merge::config = $file;
	do $file unless $dont;

	unless ($HTML::Merge::Ini::DEVELOPMENT) 
	{
		print header;
		HTML::Merge::Error::ForceError('Development is off');
		die "development is off $HTML::Merge::Ini::DEVELOPMENT"; # Would do both for CGI and mod_perl
	}
}
##################################################################
sub DefaultError 
{
	my ($error) = @_;
	print <<HTML;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">

<HTML>
<HEAD>
	<TITLE>Error</TITLE>
</HEAD>

<BODY BGCOLOR='white'>

<FONT FACE=Arial SIZE=6 COLOR=black><CENTER><B>Merge ver. ($HTML::Merge::Compile::VERSION) Error Message</B>
</CENTER></FONT><BR>
<CENTER><TABLE BGCOLOR=yellow><TR><TD><FONT FACE=Arial SIZE=5 COLOR=black>
RAZ Information System LTD.
</TD></TR></TABLE></CENTER></FONT>
<BR><BR>
<FONT FACE=Arial SIZE=4 COLOR=black><CENTER>$error</CENTER></FONT>
<BR><BR><BR><BR><BR><BR><BR><BR><BR><BR>
<CENTER>
<BR>
<FONT FACE=Arial SIZE=3 COLOR=black>
Please contact the system administrator
</FONT>
<BR>
<FONT FACE=Arial SIZE=2 COLOR=black>
Merge(c) 1999-$year&nbsp;&nbsp;</FONT>
<A HREF="http://www.raz.co.il"><FONT FACE=Arial SIZE=2 COLOR=black>
http://www.raz.co.il
</FONT></A><BR>
</CENTER>
</FORM>
</BODY>
</HTML>
HTML
}
##################################################################
sub DefaultDisplay 
{
	require CGI;
	import CGI;
	DefaultError(CGI::param('message'));
}
##################################################################
sub DefaultExpire 
{
	DefaultError("Your session has expired. Please log in again");
}
##################################################################
sub DefaultForbidden 
{
	DefaultError("You do not have access to this page");
}
##################################################################
sub FindHash 
{
	my ($line) = @_;

	my $pos = 0;

	while ($line =~ s/^(.*?)(['"#])//) 
	{
		$pos += length($1) + 1;
		return $pos - 1 if ($2 eq '#');
		my $ch = $2;
		unless ($line =~ s/^(.*?)(?<!\\)$ch//) 
		{
			return -1;
		}
		$pos += length($1) + 1;
	}
	return -1;
}
##################################################################
sub WriteConfig 
{
	my ($glob) = @_;

	my $date = pack("A21", scalar(localtime));

	print $glob <<EOM;
#####################################################################
package HTML::Merge::Ini;
#####################################################################
# ini - Contains enviroment vars - the Merge configuration file     #
# All right reserved - Raz Information Systems Ltd.(c) 1999-$year   #
# Date : 14/10/2005                                                 #
# Last update : $date                               		    #
# Automatic page  - Generated by the Merge Configuration Web page   #
#####################################################################
EOM
}
1;
__END__

=head1 NAME

HTML::Merge::Development - Contains functions developer user interface

=head1 DESCRIPTION

This module is used by developers' web based user interface cgi scripts.


=head1 COPYRIGHT

Copyright (c) 1999 - 2008 Raz Information Systems Ltd.
http://www.raz.co.il

This package is distributed under the same terms as Perl itself, see the
Artistic License on Perl's home page.

=head1 SEE ALSO

perl(1), L<HTML::Merge::Tags>, L<HTML::Merge::Tags>, L<HTML::Merge::Ext>.


=cut


