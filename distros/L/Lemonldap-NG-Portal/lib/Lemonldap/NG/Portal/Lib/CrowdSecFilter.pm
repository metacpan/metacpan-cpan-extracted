package Lemonldap::NG::Portal::Lib::CrowdSecFilter;

use strict;
use Mouse::Role;
use Regexp::Assemble;

our $VERSION = '2.23.0';

# Known special categories (urlskip is whitelist, url is legacy fallback)
use constant knownCat      => (qw(url urlskip));
use constant knownSuffixes => (qw(re txt));

# Note: 'scenarios' attribute must be defined in consuming class

# Initialization functions for CrowdsecFilter feature

sub initializeFilters {
    my ($self) = @_;
    my $filters = $self->parseFilters( $self->conf->{crowdsecFilters} );
    if ( $filters and %$filters ) {
        foreach my $cat ( keys %$filters ) {
            my $re = Regexp::Assemble->new;
            eval {
                $re->add( map { qr/(?i)$_/ } @{ $filters->{$cat}->{re} } )
                  if $filters->{$cat}->{re};
                $re->add( map { qr/(?i)\Q$_\E/ } @{ $filters->{$cat}->{txt} } )
                  if $filters->{$cat}->{txt};
            };
            if ($@) {
                $self->logger->error("Unable to parse category $cat: $@");
            }
            else {
                $self->filters->{$cat} = $re->re;
                $self->logger->debug("RE $cat: $re");
            }
        }
    }
}

sub parseFilters {
    my ( $self, $dirname, $res, $cat ) = @_;
    $self->logger->debug("Crowdsec filters, parsing $dirname");
    $res //= {};
    my $fh;
    unless ( opendir $fh, $dirname ) {
        $self->logger->error("Unable to read directory $dirname: $!");
        return $res;
    }
    my @files = grep /\w/, readdir $fh;
    closedir $fh;
  LOOP: foreach my $file (@files) {

        # Sub-directories fixes the category
        my $path = "$dirname/$file";
        if ( -d $path ) {
            if ($cat) {
                $self->parseFilters( $path, $res, $cat );
            }
            else {
             # Check for .scenario file to determine if this is a named scenario
                my $scenarioFile = "$path/.scenario";
                if ( -f $scenarioFile ) {

                    # This is a named scenario directory
                    my $scenarioName = $self->_readScenarioFile($scenarioFile);
                    if ($scenarioName) {
                        $self->scenarios->{$file} = $scenarioName;
                        $self->logger->debug(
                            "Found scenario '$scenarioName' in directory $file"
                        );

                        # Check for optional .maxfailures file
                        my $maxFailuresFile = "$path/.maxfailures";
                        if ( -f $maxFailuresFile ) {
                            my $maxFailures =
                              $self->_readMaxFailuresFile($maxFailuresFile);
                            if ( defined $maxFailures ) {
                                $self->scenarioMaxFailures->{$file} =
                                  $maxFailures;
                                $self->logger->debug(
"Found maxfailures '$maxFailures' for scenario in directory $file"
                                );
                            }
                        }

                        # Check for optional .banduration file
                        my $banDurationFile = "$path/.banduration";
                        if ( -f $banDurationFile ) {
                            my $banDuration =
                              $self->_readBanDurationFile($banDurationFile);
                            if ( defined $banDuration ) {
                                $self->scenarioBanDuration->{$file} =
                                  $banDuration;
                                $self->logger->debug(
"Found banduration '$banDuration' for scenario in directory $file"
                                );
                            }
                        }

                        # Check for optional .timewindow file
                        my $timeWindowFile = "$path/.timewindow";
                        if ( -f $timeWindowFile ) {
                            my $timeWindow =
                              $self->_readTimeWindowFile($timeWindowFile);
                            if ( defined $timeWindow ) {
                                $self->scenarioTimeWindow->{$file} =
                                  $timeWindow;
                                $self->logger->debug(
"Found timewindow '$timeWindow' for scenario in directory $file"
                                );
                            }
                        }

                        $self->parseFilters( $path, $res, $file );
                    }
                    else {
                        $self->logger->error(
                            "Empty or invalid .scenario file in $path");
                    }
                }
                elsif (
                    my ($t) =
                    grep { $file =~ m/^${_}(?:[_\s-]|$)/ } knownCat
                  )
                {
                    # Legacy known category (url, urlskip)
                    $self->parseFilters( $path, $res, $t );

                }
                else {
                    $self->logger->error(
                        "Unknown category for directory $path");
                }
            }
            next LOOP;
        }

# Skip .scenario, .maxfailures, .banduration, .timewindow files (already processed at directory level)
        next LOOP
          if $file eq '.scenario'
          or $file eq '.maxfailures'
          or $file eq '.banduration'
          or $file eq '.timewindow';

        $file =~ s/\.([^\.]+)$//;
        my $type = $1;
        unless ( $type and grep { $_ eq $type } knownSuffixes ) {
            $self->logger->error("Bad suffix for $path, skipping");
            next LOOP;
        }
        my $lcat = $cat;
        unless ($lcat) {
            $file =~ s/\.([^\.]+)$//;
            $lcat = $1;
            unless ($lcat) {
                $self->logger->error("Malformed file $path (missing category)");
                next LOOP;
            }

            # For files in root directory, must be known category
            unless ( grep { $_ eq $lcat } knownCat ) {
                $self->logger->error("Unknown category $lcat for $path");
                next LOOP;
            }
        }
        unless ( open $fh, '<', $path ) {
            $self->logger->error("Unable to read file $path: $!");
            next LOOP;
        }
        $self->logger->debug(
"Crowdsec filters, adding content of $path into category $lcat, type $type"
        );
        my $c = 0;
        foreach (<$fh>) {
            next if /^\s*#/;
            next unless /\w/;
            s/[\r\n]//g;
            s/^\s+//;
            # For regex files, preserve trailing escaped spaces (e.g. '\ ')
            if ( $type eq 're' ) {
                s/(?<!\\)\s+$//;
            }
            else {
                s/\s+$//;
            }
            push @{ $res->{$lcat}->{$type} }, $_;
            $c++;
        }
        close $fh;
        $self->logger->debug("  -> $c lines added");
    }
    return $res;
}

# Generic config file reader
# Args: $file, $fieldName, $validationRegex (optional, undef = any non-empty value)
sub _readConfigFile {
    my ( $self, $file, $fieldName, $validationRegex ) = @_;
    my $fh;
    unless ( open $fh, '<', $file ) {
        $self->logger->error("Unable to read $fieldName file $file: $!");
        return undef;
    }
    my $value;
    while (<$fh>) {
        chomp;
        s/[^\x21-\x7E]//g;    # Remove non-printable characters and spaces
        s/^\s+//;
        s/\s+$//;
        next if /^#/;
        next unless /\S/;

        if ( !$validationRegex or /$validationRegex/ ) {
            $value = $_;
            last;
        }
        else {
            $self->logger->error("Invalid $fieldName value in $file: $_");
        }
    }
    close $fh;
    return $value;
}

sub _readScenarioFile {
    my ( $self, $file ) = @_;
    return $self->_readConfigFile( $file, 'scenario', undef );
}

sub _readMaxFailuresFile {
    my ( $self, $file ) = @_;
    return $self->_readConfigFile( $file, 'maxfailures', qr/^\d+$/ );
}

sub _readBanDurationFile {
    my ( $self, $file ) = @_;

    # Accept CrowdSec duration format: 4h, 1d, 30m, 1h30m, etc.
    return $self->_readConfigFile( $file, 'banduration', qr/^[\dsmhd]+$/i );
}

sub _readTimeWindowFile {
    my ( $self, $file ) = @_;

    # Accept integer (seconds) for time window
    return $self->_readConfigFile( $file, 'timewindow', qr/^\d+$/ );
}

# Find which scenario matches the given URI
# Returns: (scenario_name, category, maxFailures, banDuration, timeWindow)
#          or (undef, undef, undef, undef, undef) if no match
# maxFailures, banDuration and timeWindow are undef if not specified for the scenario
sub matchScenario {
    my ( $self, $uri ) = @_;

    # First check if URI is whitelisted
    if ( $self->filters->{urlskip} and $uri =~ $self->filters->{urlskip} ) {
        return ( undef, 'urlskip', undef, undef, undef );
    }

    # Check named scenarios first (they have priority over generic 'url')
    foreach my $cat ( keys %{ $self->scenarios } ) {
        if ( $self->filters->{$cat} and $uri =~ $self->filters->{$cat} ) {
            return (
                $self->scenarios->{$cat},
                $cat,
                $self->scenarioMaxFailures->{$cat},
                $self->scenarioBanDuration->{$cat},
                $self->scenarioTimeWindow->{$cat}
            );
        }
    }

    # Finally check generic 'url' category (legacy behavior)
    if ( $self->filters->{url} and $uri =~ $self->filters->{url} ) {
        return ( 'llng/urlscan', 'url', undef, undef, undef );
    }

    return ( undef, undef, undef, undef, undef );
}

1;
