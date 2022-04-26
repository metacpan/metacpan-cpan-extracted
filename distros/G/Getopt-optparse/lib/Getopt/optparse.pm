package Getopt::optparse;

use strict;
use Scalar::Util 'reftype';

our $VERSION = '1.6.0';
 
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
    # TODO: test for dest name collision.

    if (Scalar::Util::reftype($optvals) eq 'HASH') {
        if (! $optvals->{dest}) {
            printf("%s attribute dest is required.\n", $optname);
            exit;
        }

        $self->{parser}{$optname} = $optvals;
    }
    else {
        print "Attributes must be passed as hashref\n";
        exit;
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
                if ($parser->{action} eq 'count') {
                    if (my @matches = ($self->{cmdline} =~ /$key\s+/g)) {
                        for my $match (@matches) {
                            $options{$parser->{dest}} += 1;
                        }
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

    $self->run_callback(\%options);

    return \%options;
}

######################################################
sub run_callback {
######################################################
    my $self = shift;
    my $options = shift;

    for my $key (keys %{$self->{parser}}) {
        if ($self->{parser}{$key}{callback}) {
            my $parser = $self->{parser}{$key};
            $parser->{callback}->($parser, $options);
        }
    }

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

    my (@singles, @doubles);
    for my $key (keys %{$self->{parser}}) {
        if ($key =~ /^--\w+/) {
            push @doubles, $key;
        }
        elsif ($key =~ /^-\w+/) {
            push @singles, $key;
        }
    }

    my @sorted;
    for my $elmt (sort { length $a <=> length $b } @singles) {
        push @sorted, $elmt;
    }

    for my $elmt (sort { length $a <=> length $b } @doubles) {
        push @sorted, $elmt;
    }

    # Print help.
    for my $key(keys %{$self->{int_parser}}) {
        printf("%-$max_length{1}s : %s\n", $key, $self->{int_parser}{$key}{help});
    }

    for my $key (@sorted) {
        # Add special character for actions count and append.
        my $special;
        if ($self->{parser}{$key}{action} eq 'count') {
            $special = '++';
        }
        if ($self->{parser}{$key}{action} eq 'append') {
            $special = '[]';
        }

        if ($self->{parser}{$key}{dest} && ($self->{parser}{$key}{action} ne 'store_true')) {
            printf(
                "%-$max_length{1}s : %s\n",
                $key . '=' . uc($self->{parser}{$key}{dest}) . $special,
                $self->{parser}{$key}{help}
            );
        }
        else {
            printf("%-$max_length{1}s : %s\n", $key, $self->{parser}{$key}{help});
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

=item Option Name (required)

Value to be parsed from command line.  --hostname in the above example.  
This library supports both single and double dash option names..

=item Option Attributes hash reference (required)

These may include:

=over 8

=item dest (required)

Name of key were parsed option will be stored.

=item default (optional)

Value of dest if no option is parsed on command line.

=item help (optional)

Text message displayed when -h or --help is found on command line.

=item action (optional)

The following actions are supported.

=over 8

=item store_true

Using this makes dest true or false (0 or 1) if the option name is found on the command line.

=item append

Using this appends each occurrance of an option to an ARRAY reference if option name is found on the command line.

=item count

Using this increments dest by one for every occurrence if option name is found on the command line.

=back

=item callback (optional)

Allows user to pass code reference which is executed after Getopt::optparse->parse_args() is run.  The callback has access to to all parsed options from command line.  Placed here as not to clobber other actions.

    # This example uses a callback to validate that user accounts don't already exist.
    $parser->add_option(
        '-username', 
        {
            dest     => 'username',
            action   => 'append',
            help     => 'Username for new ILO account',
            callback => sub {
                my ($parser, $options) = @_;
                for my $uname (@{$options->{username}}) {
                    if ($uname) {
                         my $code = system(sprintf("getent passwd %s 2>&1 > /dev/null", $uname));
                         if (! $code) {
                             printf("Error: -username provided already exists: %s\n", $uname);
                             exit 1;
                         }
                     }
                     else {
                         printf("Error: -username provided not defined: %s\n", $uname);
                         exit 2;
                     }
                 }
             }
         }
    );

    # This example uses a callback to ensure a hostname is resolvable.
    $parser->add_option(
        '-hostname', 
        {
            dest     => 'hostname',
            help     => 'Remote hostname',
            default  => 'cpan.perl.org',
            callback => sub {
                my ($parser, $options) = @_;
                my $hostname = $options->{hostname};
                if ($hostname) {
                    if ($hostname =~ /(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/) {
                        printf("Error: -hostname should be resolvable fqdn not IP: %s\n", $hostname);
                        exit 3;
                    }
                    if (! gethostbyname($hostname)) {
                        printf("Error: unable to resolve -hostname: %s\n", $hostname);
                        exit 4;
                    }
                }
            }
        }
    );

    # This example uses a callback to validate password integrity.
    $parser->add_option(
        '-password', 
        {
            dest     => 'password',
            help     => 'Password for account',
            callback => sub {
                my ($parser, $options) = @_;
                my $password = $options->{password};
                if ($password) {
                    if ($password !~ /^(?=.*[0-9])(?=.*[A-Z])(?=.*[a-z])/s || (length($options->{password}) < 10)) {
                        print "Error: Password should be at least 10 characters, contain numbers and a lower and upper case letters.\n";
                        exit 5;
                    }
                }
            }
        }
       
    );

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
