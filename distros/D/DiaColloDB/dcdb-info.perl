#!/usr/bin/perl -w

use lib qw(. lib);
use DiaColloDB;
use Getopt::Long qw(:config no_ignore_case);
use Pod::Usage;
use File::Basename qw(basename);
use strict;

#use DiaColloDB::Relation::TDF; ##-- DEBUG

##----------------------------------------------------------------------
## Globals
##----------------------------------------------------------------------

##-- program vars
our $prog       = basename($0);
our ($help,$version);

our $dburl      = undef;
our $outdir     = undef;
our %cli        = (flags=>'r');
our %log        = (level=>'TRACE', rootLevel=>'FATAL');

##----------------------------------------------------------------------
## Command-line processing
##----------------------------------------------------------------------
GetOptions(##-- general
	   'help|h' => \$help,
	   'version|V' => \$version,
	   'log-level|level|log|verbose|v=s' => sub { $log{level} = uc($_[1]); },
	   'quiet|q!' => sub { $log{level} = $_[1] ? 'WARN' : 'TRACE' },
	  );

pod2usage({-exitval=>0,-verbose=>0}) if ($help);
pod2usage({-exitval=>1,-verbose=>0,-msg=>"$prog: ERROR: no DBURL specified!"}) if (!@ARGV);

if ($version) {
  print STDERR "$prog version $DiaColloDB::VERSION by Bryan Jurish\n";
  exit 0 if ($version);
}


##----------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------

##-- setup logger
DiaColloDB::Logger->ensureLog(%log);

##-- open colloc-db
$dburl = shift(@ARGV);
my ($cli);
if ($dburl !~ m{^[a-zA-Z]+://} && -d $dburl) {
  ##-- hack for local directory URLs without scheme
  $cli = DiaColloDB->new(dbdir=>$dburl,%cli);
} else {
  ##-- use client interface for any URL with a scheme
  $cli = DiaColloDB::Client->new($dburl,%cli);
}
die("$prog: failed to create new DiaColloDB::Client object for $dburl: $!") if (!$cli);

##-- get info
my $info = $cli->dbinfo()
  or die("$prog: dbinfo() failed for '$dburl': $cli->{error}");

##-- cleanup
$cli->close();

##-- dump info
DiaColloDB::Utils::saveJsonFile($info,'-');

__END__

###############################################################
## pods
###############################################################

=pod

=head1 NAME

dcdb-info.perl - get administrative info from a DiaColloDB diachronic collocation database

=head1 SYNOPSIS

 dcdb-info.perl [OPTIONS] DBDIR_OR_URL

 Options:
   -h, -help              # display a brief usage summary
   -V, -version           # display program version
   -l, -log-level LEVEL   # set minimum DiaColloDB log-level
   -q, -quiet             # alias for -log-level=warn

=cut

###############################################################
## DESCRIPTION
###############################################################
=pod

=head1 DESCRIPTION

dcdb-info.perl
prints some basic information about the
L<DiaColloDB|DiaColloDB> database directory specified
in the L<DBDIR|/DBDIR> argument.
Output is in L<JSON|http://json.org> format.

=cut

###############################################################
## OPTIONS AND ARGUMENTS
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

###############################################################
# Arguments
###############################################################
=pod

=head2 Arguments

=over 4

=item DBDIR

L<DiaColloDB|DiaColloDB> database directory to be scanned.

=back

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item -help

Display a brief help message and exit.

=item -version

Display version information and exit.

=back

=cut


###############################################################
# Bugs and Limitations
###############################################################
=pod

=head1 BUGS AND LIMITATIONS

Probably many.

=cut


###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>

=head1 SEE ALSO

L<DiaColloDB(3pm)|DiaColloDB>,
L<dcdb-create.perl(1)|dcdb-create.perl>,
L<dcdb-query.perl(1)|dcdb-query.perl>,
L<dcdb-export.perl(1)|dcdb-export.perl>,
L<dcdb-upgrade.perl(1)|dcdb-upgrade.perl>,
perl(1).

=cut
