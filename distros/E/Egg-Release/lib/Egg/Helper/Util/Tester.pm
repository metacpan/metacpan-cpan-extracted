package Egg::Helper::Util::Tester;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Tester.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.00';

sub _start_helper {
	my($self)= @_;
	my $uri= shift(@ARGV)
	      || return $self->_helper_help('I want request URI.');
	my $o= $self->_helper_get_options;
	$o->{help} and return $self->_helper_help;
	my($server, $path);
	if ($uri=~m{^https?\://(.+)}) {
		($server, $path)= $1=~m{^([^/]+)(.+)};
		$path || return $self->_helper_help('Bad format of URI.');
	}
	$path ||= $uri;
	$path=~m{^/.*} || return $self->_helper_help('Input error of URI.');
	$path=~s{\#.+?$} [];
	$ENV{REQUEST_URI}= $path;
	$ENV{REQUEST_METHOD}= 'GET';
	if ($path=~m{(.+?)\?(.+)$}) {
		($path, $ENV{QUERY_STRING})= ($1, $2);
	}
	$ENV{PATH_INFO}= $path;
	$ENV{REMOTE_ADDR}= '127.0.0.1';
	$server ||= 'localhost';
	if ($server=~m{(.+)\:(\d+)$}) {
		$server= $1;
		$ENV{SERVER_PORT}= $2;
	} else {
		$ENV{SERVER_PORT}= 80;
	}
	$ENV{SERVER_NAME}= $ENV{HTTP_HOST}= $server || 'localhost';
	$ENV{HTTPS}= 'on' if $uri=~m{^https\://};
	my $res= $self->helper_stdout(sub {
		my $p= $self->project_name;
		$p->require or die $@;
		$p->handler;
	  });
	if ($res->error) {
		print STDERR $res->error;
	} elsif ($o->{all}) {
		print STDERR $res->result;
	} else {
		print STDERR "\n\nDone...\n";
	}
}
sub _helper_get_options {
	shift->next::method(' a-all r-response_header ');
}
sub _helper_help {
	my $self= shift;
	my $msg = shift || "";
	$msg= "ERROR: ${msg}\n\n" if $msg;
	print <<END_HELP;
${msg}% perl myapp_tester.pl [URI] [OPTION]

Usage: ./myapp_tester.pl http://mydomain/hoge/boo -ar

END_HELP
}

1;

__END__

=head1 NAME

Egg::Helper::Util::Tester - Operation test of project.

=head1 SYNOPSIS

  % cd /path/to/MyApp
  % bin/myapp_tester.pl http://domainname/
  DEBUG:
  # ----------------------------------------------------------
  # >> Egg - MyApp: startup !! - load plugins.
  #   = Egg::Plugin::ConfigLoader v3.00
  # + Request Class: Egg::Request::CGI v3.00
  # + Load Model: dbic-3.00
  # + Load View : mason-3.00
  # + Load Dispatch: MyApp::Dispatch v0.01
  DEBUG: # >>>>> MyApp v0.01
  # + Request Path : /
  # + template file : index.tt
  # >> simple bench = -------------------
  * prepare            : 0.004711 sec.
  * dispatch           : 0.000978 sec.
  * action_start       : 0.084614 sec.
  * action_end         : 0.000111 sec.
  * finalize           : 0.005493 sec.
  * output             : 0.000904 sec.
  * finish             : 0.003839 sec.
  * ======= Total >>   : 0.100650 sec.
  # -------------------------------------

=head1 DESCRIPTION

It is a module to do the operation test of the project.

It uses it from [PROJECT_LC]_tester.pl generated to 'bin' directory of the project.

  % cd /path/to/MyApp
  % bin/myapp_tester.pl http://domainname/

Please pass URI that wants to test to [PROJECT_LC]_tester.pl and start.

* It doesn't correspond to the test of place POST current request.

When '-a' option is put, the content of STDOUT comes to be output though the
content output to STDOUT is not displayed usually.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Helper>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

