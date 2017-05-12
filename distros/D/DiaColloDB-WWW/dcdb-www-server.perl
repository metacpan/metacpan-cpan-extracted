#!/usr/bin/perl -w

use lib qw(. lib blib/lib lib/lib lib/blib/lib dclib);
use DiaColloDB::WWW;
use DiaColloDB::WWW::Server;
use File::Basename qw(basename);
use Getopt::Long qw(:config no_ignore_case);
use Cwd qw(getcwd abs_path);
use Socket qw(SOMAXCONN);
use Pod::Usage;
use strict;

##==============================================================================
## Constants & Globals
##==============================================================================

##-- program identity
our $prog = basename($0);

##-- General Options
our ($help,$man,$version);
our $verbose = 'INFO';   ##-- default log level

##-- logging
our %log = (level=>'INFO', rootLevel=>'FATAL');
our %srv = (wwwdir=>undef,
	    daemonArgs=>{LocalAddr=>'127.0.0.1', LocalPort=>6066,ReuseAddr=>1},
	   );

##-- caller state
our $cwd = abs_path(".");

##==============================================================================
## Command-line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'man|m'     => \$man,
	   'version|V' => \$version,

	   ##-- Server configuration
	   'addr|a|bind|b|host=s'   => \$srv{daemonArgs}{LocalAddr},
	   'port|p=i'   => \$srv{daemonArgs}{LocalPort},
	   'wwwdir|www-dir|wd|w=s' => \$srv{wwwdir},

	   ##-- logging stuff
	   'log-level|log|level|ll=s' => sub { $log{level} = uc($_[1]); },
	   'log-option|logopt|lo=s' => \%log,
	  );

if ($version) {
  print STDERR "$prog version $DiaColloDB::WWW::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}
pod2usage({-exitval=>0, -verbose=>0}) if ($help);
pod2usage({-exitval=>0,-verbose=>0,-msg=>"no DBURL specified!"}) if (@ARGV < 1);

##==============================================================================
## MAIN
##==============================================================================

##-- setup logger
DiaColloDB::Logger->ensureLog(%log);

##-- get dburl
my $dburl = $srv{dburl} = shift(@ARGV);
die("$0: cannot access local DBURL $dburl") if ($dburl !~ m{^[a-zA-Z0-9]*://} && !-e $dburl);

##-- create / load server object
if (defined($srv{wwwdir})) {
  $srv{dburl}  = abs_path($srv{dburl});
  $srv{wwwdir} = abs_path($srv{wwwdir});
  chdir($srv{wwwdir});
}
END {
  chdir($cwd) if (defined($cwd));
}
my $srv = DiaColloDB::WWW::Server->new(%srv)
  or die("$0: failed to create DiaColloDB::WWW::Server object");

##-- serverMain(): main post-preparation code; run in subprocess if we're in daemon mode
my $dargs = $srv->{daemonArgs} || {};
sub serverMain {
  $srv->info("serverMain(): initializing server $dargs->{LocalAddr}:$dargs->{LocalPort}");
  $srv->info("serverMain(): using DiaColloDB::WWW::Server version $DiaColloDB::WWW::Server::VERSION");
  $srv->prepare()
    or $srv->logdie("prepare() failed!");
  $srv->info("serverMain(): CWD    = ", abs_path(getcwd));
  $srv->info("serverMain(): DBURL  = ", abs_path($srv->{dburl}) || $srv->{dburl});
  $srv->info("serverMain(): WWWDIR = ", abs_path($srv->{wwwdir} // '(default)'));
  $srv->run();
  $srv->finish();
  $srv->info("exiting");
}

##-- check whether we can really bind the socket
my $sock = IO::Socket::INET->new(%$dargs, Listen=>SOMAXCONN)
  or $srv->logdie("cannot bind socket $dargs->{LocalAddr}:$dargs->{LocalPort}: $!");
undef $sock;

##-- just run server in serial mode
serverMain();

__END__
=pod

=head1 NAME

dcdb-www-server.perl - standalone HTTP server for DiaColloDB indices

=head1 SYNOPSIS

 dcdb-www-server.perl [OPTIONS...] DBURL

 General Options:
  -help                           ##-- show short usage summary
  -man                            ##-- show longer help message
  -version                        ##-- show version & exit

 Server Configuration Options:
  -bind HOST                      ##-- override host to bind (default=127.0.0.1)
  -port PORT                      ##-- override port to bind (default=6066)
  -wwwdir DIR                     ##-- override WWW wrapper directory (default=shared)

 Logging Options:                 ##-- see Log::Log4perl(3pm)
  -log-level LEVEL                ##-- set minimum log level (default=INFO)
  -log-option OPT=VALUE           ##-- set any logging option (e.g. -log-option file=server.log)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

dcdb-www-server.perl is a command-line utility for starting
a standalone HTTP server to provide a L<DiaColloDB|DiaColloDB> web-service
and HTTP-based user interface
using the L<DiaColloDB::WWW::Server|DiaColloDB::WWW::Server> module.
After successful startup, point your browser at F<http://HOST:PORT>
(by default L<http://127.0.0.1:6066>) to use.

=cut

##==============================================================================
## Options and Arguments
##==============================================================================
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

###############################################################
# Arguments
###############################################################
=pod

=head2 Arguments

=over 4

=item DBURL

L<DiaColloDB|DiaColloDB> database URL to be wrapped,
which must be supported by L<DiaColloDB::Client|DiaColloDB::Client>,
i.e. must use one of the supported schemes C<file://>, C<rcfile://>, C<http://>, and C<list://>.
If no scheme is specified, C<file://> is assumed.
Typically, I<DBURL> is simply the path to a localL<DiaColloDB|DiaColloDB> index directory
as created by
L<dcdb-create.perl(1)|dcdb-create.perl>.

=back

=cut

##==============================================================================
## Options: General Options
=pod

=head2 General Options

=over 4

=item -help

Display a short help message and exit.

=item -man

Display a longer help message and exit.

=item -version

Display program and module version information and exit.

=back

=cut

##==============================================================================
## Options: Server Options
=pod

=head2 Server Options

=over 4

=item -bind HOST

Set local hostname or IP address to listen on; default=C<127.0.0.1> just binds the
loopback address.  If you're feeling adventurous, you can specify
C<-bind=0.0.0.0> to bind all IP addresses assigned to the local machine.

=item -port PORT

Set local port to listen on; default=C<6066>.

=item -wwwdir DIR

Override WWW wrapper directory.  If unspecified, the default templates
installed with the L<DiaColloDB::WWW|DiaColloDB::WWW> distribution are used.
You can create a copy of the default wrapper directory with the
L<dcdb-www-create.perl(1)|dcdb-www-create.perl> script and
edit the F<dstar.rc> and/or F<dstar/corpus.ttk> files to override
the default variables (e.g. corpus label, ddc server, KWIC query root, etc.).

=back

=cut


##==============================================================================
## Options: Logging Options
=pod

=head2 Logging Options

The L<DTA::CAB|DTA::CAB> family of modules uses
the Log::Log4perl logging mechanism.
See L<Log::Log4perl(3pm)|Log::Log4perl> for details
on the general logging mechanism.

=over 4

=item -log-level LEVEL

Set minimum log level.  Has no effect if you also specify L</-log-config>.
Known levels: (trace|debug|info|warn|error|fatal).

=item -log-option OPT=VALUE

Set any L<DiaColloDB::Logger|DiaColloDB::Logger> option, e.g. C<-log-option file=server.log>.

=back

=cut


##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Bryan Jurish

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

L<DiaColloDB::WWW::Server(3pm)|DiaColloDB::WWW::Server>,
L<DiaColloDB::WWW::CGI(3pm)|DiaColloDB::WWW::CGI>,
L<DiaColloDB(3pm)|DiaColloDB>,
L<HTTP::Daemon(3pm)|HTTP::Daemon>,
L<perl(1)|perl>,
...

=cut
