# $Id: Apache.pm,v 1.5 2002/12/16 21:16:51 m_ilya Exp $

package HTTP::WebTest::Plugin::Apache;

$VERSION = '1.01';

=head1 NAME

HTTP::WebTest::Plugin::Apache - Plugin for local web file tests

=head1 SYNOPSIS

Not Applicable

=head1 DESCRIPTION

This plugin adds support for local web file test mode to
L<HTTP::WebTest>. In this mode Apache is started on a private/dynamic
port with a configuration file in a temporary directory and
L<HTTP::WebTest> runs its tests against local web files using this
temporary local instance of Apache.

Data flow diagram for C<HTTP::WebTest> using a local web file:

          --------------           ---------------------
          |            |           |                   |
          | Input      |           |  Web page code    |
          | parameters |           |  (Perl/HTML/etc.) |
          |            |           |                   |
          --------------           ---------------------
              |                              |
              |  -----------------------------
              |  |
              V  V                ------------------------
          -------------           |                      |
          |           |---------->| Temporary Apache     |
          |  WebTest  |           | directories (htdocs, |
          |           |<----------| conf, logs)          |
          -------------           |                      |
              |  ^                ------------------------
              |  |                        |    ^
              V  |                        V    |
          ------------             ----------------------
          |          |   request   |                    |
          |   HTTP   |------------>| Temporary local    |
          |   user   |             | instance of Apache |
          |   agent  |<------------|                    |
          |          |   response  ----------------------
          ------------


=head1 EXAMPLE

The parameters below specify a test of a local file containing Perl
code using the L<Apache::ASP|Apache::ASP> module.  The C<includes.htm>
file requires five include files and two Perl modules, which are
copied using the C<include_file_path> parameter.

    apache_exec = /usr/sbin/apache
    ignore_case = yes
    include_file_path = ( footer.inc => htdocs/apps/myapp/inc
                          header.inc => htdocs/apps/myapp/inc
                          head.inc   => htdocs/apps/myapp/inc
                          go.script  => htdocs/shared/includes
                          go.include => htdocs/shared/includes
                          ../utils/DBconn.pm  => lib/perl/utils
                          ../utils/Window.pm  => lib/perl/utils
                        )

    test_name = includes.htm
        file_path = ( includes.htm => apps/myapp )
        min_bytes = 33000
        max_bytes = 35000
        text_require = ( input type=hidden name=control value= )
        text_forbid  = ( Premature end of script headers
                         an error occurred while processing this directive
                       )
    end_test

=head1 APACHE DIRECTORY AND FILES

A tree of directories with templates of Apache config files is
required to run local web file tests.

The C<apache_dir> parameter must be set to the name of a directory
that contains the subdirectories C<conf>, C<logs> and C<htdocs>.  The
C<conf> subdirectory must contain a file named C<httpd.conf-dist>.
The C<htdocs> subdirectory must contain a subdirectory named
C<webtest> that contains a file named C<is_apache_responding.html>.
If your installation of Apache has the Perl module
L<Apache::ASP|Apache::ASP> configured, the C<apache_dir> directory
must also contain a subdirectory named C<asp_tmp>.

The file C<httpd.conf-dist> is used as template for the Apache config
file.  It contains tags which are replaced with the values needed by
the Apache server that the program starts at runtime.

=over 4

=item * Please_do_not_modify_PORT

To be replaced with port number on which Apache runs during tests.

=item * Please_do_not_modify_HOST_NAME

To be replace with Apache host name.

=item * Please_do_not_modify_SERVER_ROOT

To be replaced with Apache server root.

=item * Please_do_not_modify_LOG_LEVEL

To be replaced with Apache log level.

=back

=cut

use strict;

use Config;
use File::Basename;
use File::Copy;
use File::Temp qw(tempdir);
use File::Path;
use File::Spec::Functions;
use HTTP::Request::Common;
use IO::File;
use POSIX qw(SIGTERM);
use Time::HiRes qw(time sleep);
use URI;

use HTTP::WebTest::Utils qw(make_access_method find_port copy_dir);

use base qw(HTTP::WebTest::Plugin);

=head1 TEST PARAMETERS

=head2 apache_dir

I<GLOBAL PARAMETER>

Absolute or relative path name of directory containing Apache files.
See the L<APACHE DIRECTORY AND FILES|/"APACHE DIRECTORY AND FILES">
section.  This parameter is ignored unless the C<file_path> parameter
is specified.

=head3 Default value

C</usr/local/etc/http-webtest>

=head2 apache_exec

I<GLOBAL PARAMETER>

Absolute or relative path name of Apache executable.  This command can
be in your C<$PATH>.  This parameter is ignored unless the
C<file_path> parameter is specified.

=head3 Default value

C</usr/sbin/apache>

=head2 apache_loglevel

I<GLOBAL PARAMETER>

Apache logging level.  If you use a level less than C<warn> (i.e.,
C<debug>, C<info>, or C<notice>), the program may generate irrelevant
errors.  This parameter is ignored unless the C<file_path> parameter
is specified.  See also the C<ignore_error_log> parameter.

=head3 Allowed values

C<debug>, C<info>, C<notice>, C<warn>, C<error>, C<crit>, C<alert>,
C<emerg>

=head3 Default value

C<warn>

=head2 apache_max_wait

I<GLOBAL PARAMETER>

Maximum number of seconds to wait for Apache to start.  This parameter
is ignored unless the C<file_path> parameter is specified.

=head3 Default value

C<60>

=head2 apache_options

I<GLOBAL PARAMETER>

Additional Apache command line options.  Many of the options cause
Apache to exit immediately after starting, so the web page tests will
not run.  This parameter is ignored unless the C<file_path> parameter
is specified.

=head3 Allowed values

See Apache documentation

=head2 error_log

I<GLOBAL PARAMETER>

The pathname of a local web server error log.  The module counts the
number of lines in the error log before and after each request.  If
the number of lines increases, an error is counted and the additional
lines are listed in the report.  This argument should be used only
when the local web server is running in single-process mode.
Otherwise, requests generated by other processes/users may add lines
to the error log that are not related to the requests generated by
this module.  See also parameter C<ignore_error_log>.

=head2 file_path

If L<HTTP::WebTest|HTTP::WebTest> encounters parameter C<file_path> it
switches in local web file test mode.  In local web file test mode it
launches an instance of Apache daemon, copies local test file(s) under
DocumentRoot of this Apache and performs test checks against it.

=head3 Allowed values

Two-element list.  First element is the file to test, either an
absolute or a relative pathname.  Second element is the subdirectory
pathname, relative to the Apache htdocs directory, to copy the file
to.  The copied file will have the same basename as the first element
and the relative pathname of the second element.  To copy the file
directly to the htdocs directory, use a pathname of C<.> or C<./.>.

=head2 ignore_error_log

Option to ignore any errors found in the Apache error log.  The
default behavior is to flag an error if the fetch causes any errors to
be added to the error log and echo the errors to the program output.
This check is available only if C<error_log> parameter is specified.
See also the C<apache_loglevel> parameter.

=head3 Allowed values

C<yes>, C<no>

=head3 Default value

C<no>

=head2 include_file_path

List with an even number of elements.  Odd-numbered elements are files
to copy to the the temporary Apache directory before running the
tests.  These files can be specified using either an absolute or a
relative pathname.  Even-numbered elements are the subdirectory
pathname, relative to the Apache ServerRoot directory, to copy the
corresponding file to.  The copied file will have the same basename as
the odd-numbered element and the relative pathname of the
corresponding even-numbered element.  To copy the file directly to the
ServerRoot directory, use a pathname of C<.> or C<./.>.

For example:

    include_file_path = (/home/tester/inc/header.inc => htdocs/includes)

will copy the file to htdocs/includes/header.inc.

This parameter is also useful for adding Perl modules that are needed
by the web page specified by the file_path parameter.  For example:

    include_file_path = ( ../apps/myapp/DBconn.pm => lib/perl/apps )

will copy the Perl module DBconn.pm to a directory that is in the
Perl @INC array.

=cut

sub param_types {
    return q(file_path         list('scalar','scalar')
             include_file_path hashlist
             apache_dir        scalar
             apache_loglevel   scalar
             apache_exec       scalar
             apache_options    scalar
             apache_max_wait   scalar
             error_log         scalar
             ignore_error_log  yesno
             mail_server       scalar
             mail_addresses    scalar);
}

# time period between checks if Apache have been started
use constant APACHE_WAIT_SECONDS => 0.25;
# default max time to wait for Apache
use constant DEFAULT_MAX_APACHE_WAIT_SECONDS => 60;

# accessor method for apache PID
*apache_pid = make_access_method('APACHE_PID');
# accessor method for apache directory
*apache_dir = make_access_method('APACHE_DIR');
# accessor method for temporary directory
*temp_dir = make_access_method('TEMP_DIR');
# accessor method for loglevel
*apache_loglevel = make_access_method('APACHE_LOGLEVEL');
# accessor method for apache hostname
*hostname = make_access_method('HOSTNAME');
# accessor method for apache port
*port = make_access_method('PORT');
# accessor method for apache binary path
*apache_exec = make_access_method('APACHE_EXEC');
# accessor method for apache options
*apache_options = make_access_method('APACHE_OPTIONS');
# accessor method for apache startup wait period
*apache_max_wait = make_access_method('APACHE_MAX_WAIT');
# accessor method for apache error log filename
*error_log = make_access_method('ERROR_LOG');
# accessor method for number of lines in error log after last fetch
*error_log_nlines = make_access_method('ERROR_LOG_NLINES');

sub prepare_request {
    my $self = shift;

    # get request object
    my $request = $self->webtest->current_request;

    $self->global_validate_params(qw(apache_dir apache_loglevel
                                     apache_exec apache_options
                                     apache_max_wait error_log));
    $self->validate_params(qw(file_path include_file_path));

    # get various params we handle
    my $apache_dir        = $self->global_test_param('apache_dir');
    my $apache_loglevel   = $self->global_test_param('apache_loglevel');
    my $apache_exec       = $self->global_test_param('apache_exec');
    my $apache_options    = $self->global_test_param('apache_options');
    my $apache_max_wait   = $self->global_test_param('apache_max_wait');
    my $error_log         = $self->global_test_param('error_log');
    my $file_path         = $self->test_param('file_path');
    my $include_file_path = $self->test_param('include_file_path');

    if(defined $file_path) {
	# local file test found

	# setup ourselves
	$self->apache_dir($apache_dir || '/usr/local/etc/http-webtest');
	$self->apache_loglevel($apache_loglevel || 'warn');
	$self->apache_exec($apache_exec || '/usr/sbin/apache');
	$self->apache_options($apache_options || '');
	$self->apache_max_wait($apache_max_wait ||
			       DEFAULT_MAX_APACHE_WAIT_SECONDS);

	# check if apache is running
	$self->check_apache;

	# copy local file to temporary directory
	my($file, $path) = @$file_path;
	my $target_file =
	    $self->copy_file($file, catfile($self->temp_dir, 'htdocs'), $path);

	# set request uri
	$request->uri(new URI->new_abs($target_file, $self->base_url));
    }

    if(defined $include_file_path) {
	for my $i (0 .. @$include_file_path / 2 - 1) {
	    my($file, $path) = @$include_file_path[2 * $i, 2 * $i + 1];
	    $self->copy_file($file, catfile($self->temp_dir, 'htdocs'), $path);
	}
    }

    # init error log filename
    unless(defined $self->error_log) {
	$self->error_log($error_log);
    }

    # init error log line counter
    if(defined $self->error_log) {
	my $file = $self->error_log;
	my $fh = new IO::File;
	$fh->open("< $file") or
	    die "HTTP::WebTest: Can't open file $file: $!";

	while(<$fh>) {};

	$self->error_log_nlines($.);

	$fh->close;
    }
}

sub check_response {
    my $self = shift;

    $self->validate_params(qw(ignore_error_log));

    # get various params we handle
    my $ignore_error_log = $self->yesno_test_param('ignore_error_log');

    # test results
    my @ret = ();

    if(defined($self->error_log) and not($ignore_error_log)) {
	my $file = $self->error_log;
	my $fh = new IO::File;
	$fh->open("< $file") or
	    die "HTTP::WebTest: Can't open file $file: $!";

	my @errors = ();

	while(defined(my $line = <$fh>)) {
	    next if $. <= $self->error_log_nlines;
	    push @errors, $line;
	}

	my $ok;
	my $comment;
	if ($. <= $self->error_log_nlines) {
	    $comment = 'Number of messages in Apache error log is zero ?';
	    $ok = 1;
	} else {
	    $comment = 'Number of messages in Apache error log ( =';
	    $comment .= sprintf "%2d", $. - $self->error_log_nlines;
	    $comment .= ' ) is zero ?';
	    $ok = 0;
	}
	my @results = ($self->test_result($ok, $comment));

	$fh->close;

	push @ret, [ 'Apache error log test', @results ];
    }

    return @ret;
}

# check if apache is running and start it if not
sub check_apache {
    my $self = shift;

    return if defined $self->apache_pid;

    $self->start_apache;
}

# forks a child process that starts Apache on a random private/dynamic
# port number.  Checks if Apache was started by fetching a test page
# and searching the fetched page for a tag line.
sub start_apache {
    my $self = shift;

    # set our hostname
    $self->hostname('localhost');

    # find free port
    my $port = find_port(hostname => $self->hostname);
    die "HTTP::WebTest: can't find free port"
	unless defined $port;
    $self->port($port);

    # create temporary directory for apache tests
    $self->temp_dir(tempdir('webtest_XXXXXX', TMPDIR => 1));

    # copy Apache files tree to temporary directory
    $self->copy_apache_files;

    # write Apache configuration file
    $self->write_config;

    # fork child with Apache
    $self->fork_apache;

    # verify apache is running
    my $start = time;
    while(1) {
	sleep APACHE_WAIT_SECONDS;
	eval {
	    $self->verify_apache;
	};
	if($@) {
	    unless($@ =~ /^HTTP::WebTest/ and
		   (time - $start) < $self->apache_max_wait) {
		die $@;
	    }
	} else {
	    last;
	}
    }

    # set error log filename
    $self->error_log(catfile($self->temp_dir, 'logs/error.log'));
}

# copies Apache files tree into temporary directory
sub copy_apache_files {
    my $self = shift;

    copy_dir($self->apache_dir, $self->temp_dir);
}

# inserts required and optional Apache attributes into configuration
# file
sub write_config {
    my $self = shift;

    # read config template
    my $file_in = catfile($self->temp_dir, 'conf/httpd.conf-dist');
    my $fh_in = new IO::File;
    unless($fh_in->open("< $file_in")) {
	die "HTTP::WebTest: Can't open file $file_in: $!";
    }
    my $config = join '', <$fh_in>;   # Slurp entire file
    $fh_in->close;

    $self->global_validate_params(qw(mail_server mail_addresses));

    # get test params we use
    my $mail_server    = $self->global_test_param('mail_server');
    my $mail_addresses = $self->global_test_param('mail_addresses');
    $mail_server ||= 'localhost';

    # insert Apache attributes
    my %subst = (PORT => $self->port,
		 HOST_NAME => $self->hostname,
		 LOG_LEVEL => $self->apache_loglevel,
		 SERVER_ROOT => $self->temp_dir,
		 PERLSETVAR_GLOBAL =>
		 ($self->temp_dir ?
		  'PerlSetVar Global ' . catdir($self->temp_dir, 'asp_tmp') :
		  ''),
		 PERLSETVAR_MAILHOST =>
		 ($mail_server ?
		  'PerlSetVar MailHost' . $mail_server :
		  ''),
		 PERLSETVAR_MAILERRORSTO =>
		 ($mail_addresses ?
		  'PerlSetVar MailErrorsTo' . $$mail_addresses[0] :
		  ''));

    while(my($key, $val) = each %subst) {
	$config =~ s/Please_do_not_modify_$key/$val/g;
    }

    # write config
    my $file_out = $self->temp_dir . '/conf/httpd.conf';
    my $fh_out = new IO::File;
    unless($fh_out->open("> $file_out")) {
	die "HTTP::WebTest: Can't open file $file_out: $!";
    }
    $fh_out->print($config);
    $fh_in->close;
}

# Forks a child process that starts Apache
sub fork_apache {
    my $self = shift;

    my $apache_pid = fork;

    if($apache_pid == 0) {
        # child process
        my $cmd = ($self->apache_exec .
                   ' -f ' . $self->temp_dir . '/conf/httpd.conf' .
                   ' ' . $self->apache_options . ' -X');
        exec $cmd;
	die "HTTP::WebTest: Perl exec statement failed to start Apache: $!";
    }

    die "HTTP::WebTest: Can't fork: $!" unless defined $apache_pid;
    $self->apache_pid($apache_pid);
}

# return base url of test Apache server
sub base_url {
    my $self = shift;

    return 'http://' . $self->hostname . ':' . $self->port;
}

# verify Apache is running by fetching a test page (dies if something wrong)
sub verify_apache {
    my $self = shift;

    my $user_agent = $self->webtest->user_agent;

    my $test_uri = URI->new_abs('/webtest/is_apache_responding.html',
				$self->base_url);

    my $request = GET($test_uri);
    my $response = $user_agent->request($request);
    my $web_page = $response->content();
    if($response->is_error) {
	die 'HTTP::WebTest: Fetch of initial test page FAILED, ' .
	    'HTTP returned status: ' .  $response->status_line;
    } elsif($web_page !~ /Please_do_not_modify_TEST_TAG/) {
	die 'HTTP::WebTest: String \'Please_do_not_modify_TEST_TAG\' ' .
	    'not found in file htdocs/webtest/is_apache_responding.html';
    }
}

# copy a file to a root directory concatenated with a relative
# pathname, creating directories as needed.  The basename of the file
# is preserved.  Returns pathname of file that was created, relative
# to root directory
sub copy_file {
    my $self = shift;
    # file to copy
    my $file = shift;
    # absolute pathname of root directory (it must exist)
    my $root_dir = shift;
    # Relative pathname that is appended to $root_dir
    my $rel_path = shift;

    die "HTTP::WebTest: Directory $root_dir doesn't exist"
	unless -d $root_dir;

    mkpath(catfile($root_dir, $rel_path));

    my $base = basename($file);

    my $target_file = catfile($rel_path, $base);

    copy($file, catfile($root_dir, $target_file))
	or die "HTTP::WebTest: Can't copy file: $!";

    return $target_file;
}

# kills Apache if required, deletes temporary directories if created
sub DESTROY {
    my $self = shift;

    my $apache_pid = $self->apache_pid;
    if($apache_pid) {
	kill SIGTERM, $apache_pid
	    or die "HTTP::WebTest: Can't kill Apache PID=$apache_pid: $!";

	{
	    my $pid = wait;
	    redo unless $pid == -1 or $pid == $apache_pid;
	}
    }

    my $temp_dir = $self->temp_dir;
    if($temp_dir) {
	rmtree($temp_dir);
    }
}


=head1 RESTRICTIONS / BUGS

Local file test mode unlikely to work on Win32 systems (at least it
have never been tested by authors there and nobody confirmed it to
work).

=head1 AUTHORS

Richard Anderson <richard@richard-anderson.org> wrote L<HTTP::WebTest>
1.xx, using some ideas from the CPAN Monkeywrench module.

Ilya Martynov <ilya@martynov.org> implemented the plug-in concept, the
extended API and completely rewrote L<HTTP::WebTest>.

Later this plugin module was removed from L<HTTP::WebTest>
distribution and released separately.

Please don't email authors directly.  Use the SourceForge
C<HTTP::WebTest> mail list (see SUPPORT, next section).

=head1 SUPPORT

Please email bug reports, suggestions, questions, etc. to the SourceForge
C<HTTP::WebTest> maillist.
You can sign up at
http://lists.sourceforge.net/lists/listinfo/http-webtest-general .
The email address is C<http-webtest-general@lists.sourceforge.net>.

=head1 COPYRIGHT

Copyright (c) 2000-2001 Richard Anderson.  All rights reserved.

Copyright (c) 2001-2002 Ilya Martynov.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTTP::WebTest|HTTP::WebTest>

L<HTTP::WebTest::API|HTTP::WebTest::API>

L<HTTP::WebTest::Plugin|HTTP::WebTest::Plugin>

L<HTTP::WebTest::Plugins|HTTP::WebTest::Plugins>

=cut

1;
