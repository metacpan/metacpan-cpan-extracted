package Getopt::optparse;

use strict;
use Scalar::Util 'reftype';

our $VERSION = '0.02';
 
$| = 1;

######################################################
sub new {
######################################################
    my ($class, $args) = @_;
    my $self;

    my %defaults;
    $defaults{int_parser}{'--help'} = {
        'help' => 'Show this help message and exit'
    };

    # Apply defaults.
    for my $key (keys %defaults) {
        $self->{$key} = $defaults{$key};
    }

    # Apply arguments passed by human.
    # They may clobber our defaults.
    for my $key (keys %{$args}) {
        $self->{$key} = $args->{$key};
    }

    bless $self, $class;

    return $self;
}

######################################################
sub add_option {
######################################################
    my $self = shift;
    my $optname = shift;
    my $optvals = shift;

    # action, default ,dest, help

    if (Scalar::Util::reftype($optvals) eq 'HASH') {
        $self->{parser}{$optname} = $optvals;
    }
    else {
        # Throw error.
        return;
    }
}

######################################################
sub parse_args {
######################################################
    my $self = shift;
    $self->{cmdline} = join " ", @ARGV;
    $self->{cmdline} .= ' ';

    my %options;

    if ($self->{cmdline} =~ /--help/) {
        $self->show_help();
        return \%options;
    }

    for my $key (keys %{$self->{parser}}) {
        if ($self->{parser}{$key}{'dest'}) {
            # Handle default value
            if ($self->{parser}{$key}{default}) {
                $options{$self->{parser}{$key}{dest}} = $self->{parser}{$key}{default};
            }
            # Handle store_true
            if ($self->{parser}{$key}{'action'} eq 'store_true') {
                if ($self->{cmdline} =~ /$key/) {
                    $options{$self->{parser}{$key}{dest}} = 1;
                } else {
                    $options{$self->{parser}{$key}{dest}} = 0;
                }
            }
            else {
                # Search command lien option
                if (! $self->{parser}{$key}{default}) {
                    $options{$self->{parser}{$key}{dest}} = '';
                }
                if ($self->{cmdline} =~ /$key=(.*?)\s/) {
                    if ($1 !~ /^-/) {
                        $options{$self->{parser}{$key}{dest}} = $1;
                    }
                }
            }
        }
    }
    return \%options;
}

######################################################
sub show_help {
######################################################
    my $self = shift;

    printf("Usage: %s [options]\n\n", $0);
    printf("Options:\n");

    my %max_length = (1 => 22);
    for my $val ('int_parser', 'parser') {
        for my $key (keys %{$self->{$val}}) {
            my $length = length($key);
            if ($self->{$val}{$key}{dest} && ($self->{$val}{$key}{action} ne 'store_true')) {
                $length += length('=' . $self->{$val}{$key}{dest});
            }
            if ($length > $max_length{1}) {
                $max_length{1} = $length;
            }
        }
    }

    for my $val ('int_parser', 'parser') {
        for my $key (keys %{$self->{$val}}) {
            if ($self->{$val}{$key}{dest} && ($self->{$val}{$key}{action} ne 'store_true')) {
                printf(
                    "%-$max_length{1}s : %s\n",
                    $key . '=' . uc($self->{$val}{$key}{dest}),
                    $self->{$val}{$key}{help}
                );
            }
            else {
                printf("%-$max_length{1}s : %s\n", $key, $self->{$val}{$key}{help});
            }
        }
    }
}

1;

=head1 NAME

Getopt::optparse - optparse style processing of command line options

=head1 SYNOPSIS

    use Getopt::optparse;
    my $parser = Getopt::optparse->new();
    $parser->add_option(
        '--hostname', 
        {
            dest => 'hostname',
            help => 'Remote hostname',
            default => 'localhost.localdomain'
        }
    );
    $parser->add_option(
        '--username', 
        {
            dest => 'username',
            help => 'Username for new ILO account'
        }
    );
    $parser->add_option( 
        '--global',
        dest    => 'global',
        action  => 'store_true',
        help    => 'Show global',
        default => 0
    )

    my $options = $parser->parse_args();
    printf("Hostname is: %s\n", $options->{hostname});
    printf("Username is: %s\n", $options->{username});
    if ($options->{global}) {

    }

=head1 DESCRIPTION

Library which allows Python optparse style processing of command line options.

=head1 CONSTRUCTOR

=over 4

=item $parser = Getopt::optparse->new( \%options )

Construct a new C<Getopt::optparse> object and return it.  
Hash reference argument may be provided though none are required.

=back

=head1 METHODS

The following methods are available:

=over 4

=item Getopt::optparse->add_option()

    $parser->add_option(
        '--hostname',
        {
            dest => 'hostname',
            help => 'Remote hostname',
            default => 'localhost.localdomain'
        }
    )

Add option to be parsed from command line.  Accepts two arguments:

=over 4

=item Option Name

Value to be parsed from command line.  --hostname in the above example.  
This library uses only double dash.

=item Option Attributes.  A hash reference.

These may include:

=over 4

=item dest

Name of key were parsed option will be stored.

=item default (optional)

Value of dest if no option is parsed on command line.

=item help (optional)

Text message displayed when --help is found on command line.

=item action (optional)

Presently only store_true supported.  Using this makes dest true or false.  (0 or 1)

=back

=back

=item Getopt::optparse->parse_args()

    my $options = $parser->parse_args();
    printf("Hostname is: %s\n", $options->{hostname});
    printf("Username is: %s\n", $options->{username});

Parse added options from command line and return their values as a hash reference.

=back

=head1 AUTHOR

Matt Hersant <matt_hersant@yahoo.com>

=cut
