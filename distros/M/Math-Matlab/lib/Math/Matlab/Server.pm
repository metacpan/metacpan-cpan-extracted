package Math::Matlab::Server;

use strict;
use vars qw($VERSION $CONFIG);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
}

use Apache::Constants qw(:common);
use Apache::Request;

##-----  Public Class Methods  -----
sub handler {
	my $r = Apache::Request->instance(shift);
	my $code = $r->param('CODE');

	if ($code) {
		my $rel_mwd = join( '/', $r->path_info, $r->param('REL_MWD'));
		$rel_mwd =~ s:^\/::;		## strip leading slash
		$rel_mwd =~ s:\/$::; 		## strip trailing slashes
		$rel_mwd =~ s:\/\/\/*:\/:;	## strip multiple slashes
		$r->content_type('text/plain');
		$r->send_http_header;
		return OK if $r->header_only;

		my $matlab;
		eval {
			my $class = $CONFIG->{class} or die '$' . __PACKAGE__ . '::CONFIG not defined.';
			$matlab = $class->new( $CONFIG->{args} );
			$matlab->execute($code, $rel_mwd) || die "Execute returned false.";
		};
		if ($@) {
			$r->print( $@ );
		} else {
			$r->print( $r->param('RAW_OUTPUT') ? $matlab->fetch_raw_result : $matlab->fetch_result );
		}
# 		$r->print( "\n==========================\n" .
# 					"MWD: '" . $matlab->root_mwd . "\n" .
# 					"PATH_INFO: '" . $r->path_info . "'\n" .
# 					"REL_MWD: '" . $r->param('REL_MWD') . "'\n" .
# 					"\$rel_mwd: '" . $rel_mwd . "'\n" .
# 					"==========================\n" ); 
	} else {
		$r->content_type('text/html');
		$r->send_http_header;
		return OK if $r->header_only;
		$r->print(<<END_OF_PAGE);
<HTML>
<HEADER>
<TITLE>Math::Matlab::Server</TITLE>
</HEADER>
<BODY BGCOLOR="white">
<H2>Math::Matlab::Server</H2>

<HR>

<FORM METHOD="POST">
<TABLE>
	<TR>
		<TD>Relative Matlab Working Directory: <INPUT TYPE="text" NAME="REL_MWD" SIZE="16" MAXLENGTH="64"></TD>
		<TD><INPUT TYPE="checkbox" NAME="RAW_OUTPUT" VALUE="1"> Raw Output</TD>
	</TR>
	<TR>
		<TD COLSPAN="2">
			Matlab code:<BR>
			<TEXTAREA NAME="CODE" ROWS="30" COLS="70">fprintf('Hello world!\\n');
			</TEXTAREA>
		</TD>
	</TR>
	<TR>
		<TD COLSPAN="2" ALIGN="CENTER"><INPUT TYPE="submit" VALUE="Execute"></TD>
	</TR>
</TABLE>
</FORM>

</BODY>
</HTML>
END_OF_PAGE

	}

	return OK;
}

1;
__END__

=head1 NAME

Math::Matlab::Server - A Matlab server as a mod_perl content handler.

=head1 SYNOPSIS

In httpd.conf ...
  
 PerlModule Math::Matlab::Server
 PerlModule Math::Matlab::Local
 <Perl>
    $Math::Matlab::Server::CONFIG = {
        class => 'Math::Matlab::Local',
        args => { root_mwd => '/opt/lib/matlab-server',
                  cmd      => '/usr/local/bin/matlab -nojvm -nodisplay'
            }
    };
 </Perl>

 <Location /matlab-server>
    SetHandler perl-script
    PerlHandler Math::Matlab::Server
    AuthName Matlab-Server
    AuthType Basic
    AuthUserFile /opt/httpd/users
    AuthGroupFile /opt/httpd/groups
    Order Allow,Deny
    Allow from myclient.mydomain.com
    require group matlab_server
 </Location>

=head1 DESCRIPTION

B<Math::Matlab::Server> implements a mod_perl content handler which
takes form input arguments named CODE, REL_MWD and RAW_OUTPUT, calls the
execute() method of the server's Math::Matlab object passing the CODE
and REL_MWD arguments, and sends back the results as a 'text/plain'
document. The results are the value returned by the object's
fetch_raw_result() or fetch_result() method, depending whether or not
the RAW_OUTPUT parameter is true.

If the CODE is not given, it outputs an HTML page with a form which
allows you to specify the CODE, REL_MWD and RAW_OUTPUT arguments.

Any PATH_INFO included in the URL is prepended to the REL_MWD before
passing it to the execute() method.

=head1 SECURITY (OR LACK THEREOF)

PLEASE, PLEASE, PLEASE be aware that setting up such a Matlab server is
opening up a HUGE security hole on your server. Anyone who can access
this page can submit ANY Matlab code to it for execution. This can
include shell commands. In other words, anyone who can access the page,
can execute ANY command they like on your system, with the privileges of
the web server user.

Even with basic authentication in place, it is very insecure. So be sure
to restrict access to only trusted IP addresses and possibly run it with
an SSL-enabled server.

YOU HAVE BEEN WARNED! I am not responsible for systems getting
compromised by using Math::Matlab::Server.

=head1 METHODS

=head2 Public Class Methods

=over 4

=item handler

 $status = CLASS->handler( $r )

A mod_perl content handler method which implements a Matlab server.

=back

=head1 CHANGE HISTORY

=over 4

=item *

10/25/02 - (RZ) Added docs.

=back

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1)

=cut
