package Grid::Request::HTC;

# $Id: HTC.pm 8365 2006-04-10 23:08:42Z vfelix $

=head1 NAME

HTC.pm - Utilities and methods for the Grid::Request modules.

=head1 DESCRIPTION

=head2 Overview

This method provides several functions and methods that are
useful to the Grid modules.

=head2 Class and object methods

=over 4

=cut

use strict;
use Carp;
use Config::IniFiles;
use File::Which;
use Log::Log4perl qw(:easy :levels);

my $logger = get_logger(__PACKAGE__);
our ($config_section, $drm_param);

my $worker_name = "grid_request_worker";
our $WORKER = which($worker_name);
if (! defined $WORKER) {
    croak("No $worker_name found in the PATH.\n\n");
}

use vars qw($config $client $server);
our $VERSION = do { my @r=(q$Revision: 8365 $=~/\d+/g); sprintf "%d."."%03d"x$#r,@r };

if ($^W) {
    $VERSION = $VERSION;
}

BEGIN {
    $config_section = "request";
    $drm_param = "drm";

    my $central_config = "$ENV{HOME}/.grid_request.conf";

    $config = defined($ENV{GRID_CONFIG}) ? $ENV{GRID_CONFIG} : $central_config;
    if (-f $config && -r $config) {
        my $cfg = Config::IniFiles->new(-file => $config);
        if (! defined $cfg) {
            warn "There was a problem with the configuration file at $config\n";
            warn "Is it a valid INI file with a [" . $config_section . "] section?\n";
            exit 1;
        }
        my $drm = $cfg->val($config_section, $drm_param);
        if (! defined $drm) {
            warn "The config file does not define a '" . $drm_param . "' parameter.\n";
            exit 1;
        }
    } else {
        warn "The config file $config does not exist or isn't readable.\n";
        exit 1;
    }
    # Don't initialize if we have already done it...
    Log::Log4perl->easy_init($ERROR);
}


=item $obj->new([%arg]);

B<Description:> This is the object contructor. A hash
with arguments may be passed.

B<Parameters:> %arg.

B<Returns:> $self, a blessed hash reference.

=cut

sub new {
    my ($class, %arg) = @_;
    my $self = bless {}, ref($class) || $class;
    $self->_init(%arg);
    return $self;
}


=item $obj->_init();

B<Description:> _init in this class is an abstract method
and is not implemented. In fact, it will die with an error
message if you somehow call this method in this class.

B<Parameters:> None.

B<Returns:> None.

=cut

sub _init {
    $logger->logcroak("_init not implemented in this class.\n");
}

sub config { $config };

=item $obj->debug([$debug]);

B<Description:> The debug method allows the user to set or get
the debug level. If an optional argument is sent, it will be used
to set the debug level. The default level is "error". When passing a string
debug level, case is ignored.

B<Parameters:> Optional integer argument to set debug level. The debug
level can be either numeric or a string as follows:

    Name     Code
    ----     ----
    DEBUG       5
    INFO        4
    WARN        3
    ERROR       2
    FATAL       1

B<Returns:> The current debug level in numeric form.

=cut

sub debug {
    $logger->debug("In debug.");
    my ($self, @args) = @_;
    if (scalar(@args)) {
        my $debug = uc($args[0]);

        my %levels = ( DEBUG => [5, $DEBUG],
                       INFO  => [4, $INFO],
                       WARN  => [3, $WARN],
                       ERROR => [2, $ERROR],
                       FATAL => [1, $FATAL] );
        my %name_to_level = map { $_ => $levels{$_}->[1] } keys %levels;
        my %level_to_name = reverse (
                              map { $_ => $levels{$_}->[0] } keys %levels
                            );

        # Anonymous subroutine.
        my $set_by_name = sub {
            my $level_string = shift;
            $logger->info("Setting new debug level to $level_string.");
            my $level = $name_to_level{$level_string};
            $logger->level($level);
            # Set the debug level for the object.
            $self->{debug} = $levels{$level_string}->[0];
        };

        if (exists $levels{$debug}) {
            # If we have a named debug level.
            $set_by_name->($debug);
        } else {
            # We probably have a numbered debug level.
            if ( $debug !~ m/\D/ && $debug >= 1 && $debug <= 5) {
                $set_by_name->( $level_to_name{$debug} );
            } else {
                $logger->error("\"$debug\" is an invalid debug level.");
                $set_by_name->("ERROR");
            }
        }
    } else { # No arguments provided. Act like a simple accessor (getter).
       return $self->{debug};
    }
}

1;

__END__

=back

=head1 ENVIRONMENT

If the user sets the GRID_CONFIG environment variable, it will be interpreted
as the path to an alternate configuration file that will override the default.

=head1 BUGS

Description of known bugs (and any workarounds). Usually also includes an
invitation to send the author bug reports.
