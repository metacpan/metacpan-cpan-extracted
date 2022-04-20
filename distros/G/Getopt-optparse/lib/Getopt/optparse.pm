package Getopt::optparse;

use strict;
use Scalar::Util 'reftype';

our $VERSION = '0.07';
 
$| = 1;

######################################################
sub new {
######################################################
    my ($class, $args) = @_;
    my $self;

    my %defaults;
    $defaults{int_parser}{'-h, --help'} = {
        'help' => 'Show this help message and exita'
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
        print "Attributes must be passed as hashref\n";
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

    if (($self->{cmdline} =~ /--help\s+/) || ($self->{cmdline} =~ /-h\s+/)) {
        $self->show_help();
        return \%options;
    }

    for my $key (keys %{$self->{parser}}) {
        if ($self->{parser}{$key}{'dest'}) {
            my $parser = $self->{parser}{$key};
            # Handle default value
            if ($parser->{default}) {
                $options{$parser->{dest}} = $parser->{default};
            }

            # Handle count
            if ($parser->{action} eq 'count') {
                $options{$parser->{dest}} = 0;
            }

            # Handle store_true
            if ($parser->{action} eq 'store_true') {
                if ($self->{cmdline} =~ /$key\s+/) {
                    $options{$parser->{dest}} = 1;
                } else {
                    $options{$parser->{dest}} = 0;
                }
            }
            else {
                # Populate an empty scalar, which will evaluate to false.
                if (! $parser->{default}) {
                    $options{$parser->{dest}} = '';
                }

                # Populate a default of blank arrayref, which will evaluate to false.
                if ($parser->{action} eq 'append') {
                    $options{$parser->{dest}} = [];
                }

                # Match for store_true and count actions.
                if (my @matches = ($self->{cmdline} =~ /$key\s+/g)) {
                    for my $match (@matches) {
                        $options{$parser->{dest}} += 1;
                    }
                }

                # Search command line option
                if (my @matches = ($self->{cmdline} =~ /$key=(.*?)\s+/g)) {
                    if ($parser->{action} eq 'append') {
                        for my $match (@matches) {
                            push @{$options{$parser->{dest}}}, $match;
                        }
                    }
                    else {
                        if ($matches[0] !~ /^-/) {
                            $options{$parser->{dest}} = $1;
                        }
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

    # Determine length for text formatting.
    my %max_length = (1 => 22);
    for my $val ('int_parser', 'parser') {
        for my $key (keys %{$self->{$val}}) {
            my $special;
            if ($self->{$val}{$key}{action} eq 'count') {
                $special = '++';
            }
            if ($self->{$val}{$key}{action} eq 'append') {
                $special = '[]';
            }
            my $length = length($key);
            if ($self->{$val}{$key}{dest} && ($self->{$val}{$key}{action} ne 'store_true')) {
                $length += length('=' . $self->{$val}{$key}{dest} . $special);
            }
            if ($length > $max_length{1}) {
                $max_length{1} = $length;
            }
        }
    }

    # Print help.
    for my $val ('int_parser', 'parser') {
        for my $key (keys %{$self->{$val}}) {
            # Add special character for actions count and append.
            my $special;
            if ($self->{$val}{$key}{action} eq 'count') {
                $special = '++';
            }
            if ($self->{$val}{$key}{action} eq 'append') {
                $special = '[]';
            }

            if ($self->{$val}{$key}{dest} && ($self->{$val}{$key}{action} ne 'store_true')) {
                printf(
                    "%-$max_length{1}s : %s\n",
                    $key . '=' . uc($self->{$val}{$key}{dest}) . $special,
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

This library supports both single and double dash options.  An equal sign must be used.

=head1 SYNOPSIS

    use Getopt::optparse;
    my $parser = Getopt::optparse->new();
    $parser->add_option(
        '--hostname', 
        {
            dest    => 'hostname',
            help    => 'Remote hostname',
            default => 'localhost.localdomain'
        }
    );
    $parser->add_option( 
        '--global', {
            dest    => 'global',
            action  => 'store_true',
            help    => 'Show global',
            default => 0
        }
    );
    $parser->add_option(
        '--username', 
        {
            dest   => 'username',
            action => 'append',
            help   => 'Usernames to analyze'
        }
    );
    $parser->add_option(
        '-v', 
        {
            dest   => 'verbose',
            action => 'count',
            help   => 'Increment verbosity'
        }
    );

    my $options = $parser->parse_args();
    printf("Hostname is: %s\n", $options->{hostname});
    printf("Username is: %s\n", $options->{username});

    if ($options->{global}) {
    }

    for my $uname (@{$options->{username}}) {
        print $uname, "\n";
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

=item Getopt::optparse->add_option( 'optionname', {option_attributes} )

Add option to be parsed from command line.  Accepts two arguments.  Both are required:

    $parser->add_option(
        '--hostname',
        {
            dest => 'hostname',
            help => 'Remote hostname',
            default => 'localhost.localdomain'
        }
    )

=over 4

=item Option Name

Value to be parsed from command line.  --hostname in the above example.  
This library uses only double dash.

=item Option Attributes.  A hash reference.

These may include:

=over 8

=item dest

Name of key were parsed option will be stored.

=item default (optional)

Value of dest if no option is parsed on command line.

=item help (optional)

Text message displayed when --help is found on command line.

=item action (optional)

The following actions are supported.

=over 8

=item store_true

Using this makes dest true or false.  (0 or 1).  If the option is found.

=item append

Using this appends each occurrance of an option to an array reference.

=item count

using this increments dest by one for every occurrence.

=back

=back

=back

=item Getopt::optparse->parse_args()

Parse added options from command line and return their values as a hash reference.

    my $options = $parser->parse_args();

    printf("Hostname is: %s\n", $options->{hostname});

    for my $uname (@{$options->{username}}) {
        print $uname, "\n";
    }

=back

=head1 AUTHOR

Matt Hersant <matt_hersant@yahoo.com>

=cut
