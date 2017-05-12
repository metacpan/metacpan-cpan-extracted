#!/usr/bin/perl -w
##----------------------------------------------------------------------------
## :mode=perl:indentSize=2:tabSize=2:noTabs=true:
##----------------------------------------------------------------------------
##        File: proxr_relay_control.pl
## Description: Use the Device::ProXR::RelayControl object to control a
##              relay control board
##----------------------------------------------------------------------------
## NOTES
##  * Before comitting this file to the repository, ensure Perl Critic can 
##    be invoked at the HARSH [3] level with no errors
##
##----------------------------------------------------------------------------
use strict;
use warnings;
## Cannot use Find::Bin because script may be invoked as an
## argument to another script, so instead we use __FILE__
use File::Basename qw(dirname fileparse basename);
use File::Spec;
## Add script directory
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)));
## Add script directory/lib
use lib File::Spec->catdir(File::Spec->splitdir(dirname(__FILE__)), qq{lib});
## Add script directory/../lib
use lib File::Spec->catdir(
  File::Spec->splitdir(dirname(__FILE__)), 
  qq{..}, 
  qq{lib});
use Readonly;
use Getopt::Long;
use Pod::Usage;
use Cwd qw(abs_path);
use Device::ProXR::RelayControl 0.05;

## Used for the version string
Readonly::Scalar my $VERSION => qq{0.02};
Readonly::Scalar my $DEFAULT_TITLE => qq{ProXR Relay Control Script};

##--------------------------------------------------------
## Return codes for booleans
##--------------------------------------------------------
Readonly::Scalar my $FALSE => 0;
Readonly::Scalar my $TRUE  => 1;

##--------------------------------------------------------
## Lookup table
##--------------------------------------------------------
#<<< begin perltidy exclusion zone
Readonly::Array my @COMMAND_LOOKUP_TABLE => (
  {
    command        => qq{STATUS}, 
    bank_required  => 1,
    relay_required => 0,
    function       => \&relay_status,
  },
  {
    command        => qq{ON},
    bank_required  => 1,
    relay_required => 0,
    function       => \&relay_on,
  },
  {
    command        => qq{OFF},
    bank_required  => 1,
    relay_required => 0,
    function       => \&relay_off,
  },
  {
    command        => qq{ALL_ON},
    bank_required  => 0,
    relay_required => 0,
    function       => \&all_on,
  },
  {
    command        => qq{ALL_OFF},
    bank_required  => 0,
    relay_required => 0,
    function       => \&all_off,
  },
  {
    command        => qq{BANK_ON},
    bank_required  => 1,
    relay_required => 0,
    function       => \&bank_on,
  },
  {
    command        => qq{BANK_OFF},
    bank_required  => 1,
    relay_required => 0,
    function       => \&bank_off,
  },
  {
    command        => qq{BANK_STATUS},
    bank_required  => 1,
    relay_required => 0,
    function       => \&bank_status,
  },
);
#>>> end perltidy exclusion zone

##--------------------------------------------------------
## A list of all command line options
## For GetOptions the following parameter indicaters are used
##    = Required parameter
##    : Optional parameter
##    s String parameter
##    i Integer parameter
##    f Real number (float)
## If a paramer is not indicated, then a value of 1
## indicates the parameter was found on the command line
##--------------------------------------------------------
#<<< begin perltidy exclusion zone
my @CommandLineOptions = (
  "port=s",
  "baud=i",
  "command=s",
  "bank=i",
  "relay=i",
  "help",
  "man",
  "version",
  "debug+",
);
#>>> end perltidy exclusion zone

##--------------------------------------------------------
## A hash to hold all default values for command line
## options
##--------------------------------------------------------
#<<< begin perltidy exclusion zone
my %gOptions = (
  "port"    => undef,
  "baud"    => 115200,
  "command" => qq{STATUS},
  "bank"    => undef,
  "relay"   => undef,
  "help"    => 0,
  "man"     => 0,
  "version" => 0,
  "debug"   => 0,
);
#>>> end perltidy exclusion zone

##----------------------------------------------------------------------------
##     @fn process_commandline($allow_extra_args)
##  @brief Process all the command line options
##  @param $allow_extra_args - If TRUE, leave any unrecognized arguments in
##            @ARGV. If FALSE, consider unrecognized arguements an error.
##            (DEFAULT: FALSE)
## @return NONE
##   @note
##----------------------------------------------------------------------------
sub process_commandline
{
  my $allow_extra_args = shift;

  ## Pass through un-handled options in @ARGV
  Getopt::Long::Configure("pass_through");
  GetOptions(\%gOptions, @CommandLineOptions);

  ## See if --man was on the command line
  if ($gOptions{man})
  {
    pod2usage(
      -input    => \*DATA,
      -message  => "\n",
      -exitval  => 1,
      -verbose  => 99,
      -sections => '.*',     ## ALL sections
    );
  }

  ## See if --help was on the command line
  display_usage_and_exit(qq{}) if ($gOptions{help});

  ## See if --version was on the command line
  if ($gOptions{version})
  {
    print(qq{"$DEFAULT_TITLE" v$VERSION\n});
    exit(1);
  }

  ## Determine the path to the script
  $gOptions{ScriptPath} = abs_path($0);
  $gOptions{ScriptPath} =~ s!/?[^/]*/*$!!x;
  $gOptions{ScriptPath} .= "/" if ($gOptions{ScriptPath} !~ /\/$/x);

  ## See if we are running in windows
  if ($^O =~ /^MSWin/x)
  {
    ## Set the value
    $gOptions{IsWindows} = $TRUE;
    ## Get the 8.3 short name (eliminates spaces and quotes)
    $gOptions{ScriptPathShort} = Win32::GetShortPathName($gOptions{ScriptPath});
  }
  else
  {
    ## Set the value
    $gOptions{IsWindows} = $FALSE;
    ## Non-windows OSes don't care about short names
    $gOptions{ScriptPathShort} = $gOptions{ScriptPath};
  }

  ## See if there were any unknown parameters on the command line
  if (@ARGV && !$allow_extra_args)
  {
    display_usage_and_exit("\n\nERROR: Invalid "
        . (scalar(@ARGV) > 1 ? "arguments" : "argument") . ":\n  "
        . join("\n  ", @ARGV)
        . "\n\n");
  }

  return ($TRUE);
}

##----------------------------------------------------------------------------
##     @fn display_usage_and_exit($message, $exitval)
##  @brief Display the usage with the given message and exit with the given
##         value
##  @param $message - Message to display. DEFAULT: ""
##  @param $exitval - Exit vaule DEFAULT: 1
## @return NONE
##   @note
##----------------------------------------------------------------------------
sub display_usage_and_exit
{
  my $message = shift // qq{};
  my $exitval = shift // 1;

  pod2usage(
    -input   => \*DATA,
    -message => $message,
    -exitval => $exitval,
    -verbose => 1,
  );

  return;
}

##----------------------------------------------------------------------------
##     @fn validate_command();
##  @brief Validate parameters and invoke the usage and exit if needed 
##  @param 
## @return HASH REFERENCE - Hash reference of the COMMAND_TABLE_LOOKUP entry
##   @note 
##----------------------------------------------------------------------------
sub validate_command
{
  my @errors = ();
  my @required = (qw(port));

  my $cmd;
  foreach my $entry (@COMMAND_LOOKUP_TABLE)
  {
    if (uc($entry->{command}) eq uc($gOptions{command}))
    {
      $cmd = $entry;
    }
  }

  ## See if we found a valid command
  if ($cmd)
  {
    ## See if the command requires a bank parameter
    push(@required, qq{bank}) if ($cmd->{bank_required});
    ## See if the command requires a relay parameter
    push(@required, qq{relay}) if ($cmd->{relay_required});
  }
  else
  {
    push(@errors, qq{Unknown command "$gOptions{command}"});
  }
  
  ## Check that all required parameters exist
  foreach my $param (@required)
  {
    if (!defined($gOptions{$param}))
    {
      push(@errors, qq{Missing --$param parameter!});
    }
  }
  
  ## See if bank parameter was provided
  if (defined($gOptions{bank}))
  {
    ## Make sure bank parameter is valid
    if (($gOptions{bank} < 1) || ($gOptions{bank} > 255))
    {
      push(@errors, qq{Invalid --bank parameter, must be between 1 and 255!});
    }
  }
  
  ## See if relay paramter was provided
  if (defined($gOptions{relay}))
  {
    ## Make sure relay paramter is valid
    if (($gOptions{relay} < 0) || ($gOptions{relay} > 7))
    {
      push(@errors, qq{Invalid --relay parameter, must be between 0 and 7!});
    }
  }
  
  ## See if there are any errors
  if (scalar(@errors))
  {
    ## Display the errors and usage, then exit
    display_usage_and_exit("\n\nERROR: \n  "
        . join("\n  ", @errors)
        . "\n\n");
  }
  
  ## Return the entry in the command lookup table
  return($cmd);
}

##----------------------------------------------------------------------------
##     @fn relay_status($board)
##  @brief Print the relay status and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub relay_status
{
  my $board = shift;
  
  my $status = $board->relay_status($gOptions{bank}, $gOptions{relay});
  if (!defined($status))
  {
    print(qq{ERROR: Could not read the relay status!\n});
    exit(-1);
  }
  printf(qq{0x%02X\n}, $status);
  exit(0);
  
}

##----------------------------------------------------------------------------
##     @fn relay_on($board)
##  @brief Turn on a relay and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub relay_on
{
  my $board = shift;
  
  ## Send the relay command
  $board->relay_on($gOptions{bank}, $gOptions{relay});
  
  return relay_status($board);
}

##----------------------------------------------------------------------------
##     @fn relay_off($board)
##  @brief Turn on a relay and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub relay_off
{
  my $board = shift;
  
  ## Send the relay command
  $board->relay_off($gOptions{bank}, $gOptions{relay});
  
  return relay_status($board);
}

##----------------------------------------------------------------------------
##     @fn all_on($board)
##  @brief Turn on all relays
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub all_on
{
  my $board = shift;
  
  ## Send the relay command
  my $resp = $board->all_on();
  
  unless (length($resp))
  {
    print(qq{ERROR: No response received!\n});
    exit(-1);
  }
  
  exit(0);
}

##----------------------------------------------------------------------------
##     @fn all_off($board)
##  @brief Turn off all relays
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub all_off
{
  my $board = shift;
  
  ## Send the relay command
  my $resp = $board->all_off();
  
  unless (length($resp))
  {
    print(qq{ERROR: No response received!\n});
    exit(-1);
  }
  
  exit(0);
}

##----------------------------------------------------------------------------
##     @fn bank_status($board)
##  @brief Print the relay status of the bank and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub bank_status
{
  my $board = shift;
  
  my $status = $board->bank_status($gOptions{bank});
  if (!defined($status))
  {
    print(qq{ERROR: Could not read the bank status!\n});
    exit(-1);
  }
  printf(qq{0x%02X\n}, $status);
  exit(0);
}

##----------------------------------------------------------------------------
##     @fn bank_on($board)
##  @brief Turn on all relays in the bank and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub bank_on
{
  my $board = shift;
  
  ## Send the relay command
  $board->bank_on($gOptions{bank});
  
  return bank_status($board);
}

##----------------------------------------------------------------------------
##     @fn bank_off($board)
##  @brief Turn off all relays in the bank and exit
##  @param $board - Device::ProXR::RelayControl object
## @return NONE 
##   @note 
##----------------------------------------------------------------------------
sub bank_off
{
  my $board = shift;
  
  ## Send the relay command
  $board->bank_off($gOptions{bank});
  
  return bank_status($board);
}

##----------------------------------------------------------------------------
## MAIN
##----------------------------------------------------------------------------
## Set STDOUT to autoflush
$| = 1;    ## no critic (RequireLocalizedPunctuationVars)

## Parse the command line
process_commandline();

my $cmd = validate_command();

my $board = Device::ProXR::RelayControl->new(
  debug_level =>  $gOptions{debug},
  port        =>  $gOptions{port},
  baud        =>  $gOptions{baud},
  );

unless ($board)
{
  print(qq{ERROR: }, $board->last_error, qq{\n\n});
  exit(-1);
}

## Invoke the command
$cmd->{function}->($board);

exit(0);

__END__

__DATA__

##----------------------------------------------------------------------------
## By placing the POD in the DATA section, we can use
##   pod2usage(input => \*DATA)
## even if the script is compiled using PerlApp, perl2exe or Perl::PAR
##----------------------------------------------------------------------------

=head1 NAME

proxr_relay_control.pl - Control the NCD ProXR family of relay controllers

=head1 SYNOPSIS

B<proxr_relay_control.pl> B<--port> I<SerialPort>
B<--baud> I<Baud>
B<--command> I<Command>
B<--bank> I<BankNumber>
B<--relay> I<RelayNumber>
{B<--help>}
  
=head1 OPTIONS

=over 4

=item B<--port> I<SerialPort>

  Specify the serial port used to communicate with the controller.

=item B<--baud> I<Baud>

  Specify the baud rate used to communicate with the controller.
  DEFAULT: --baud 115200

=item B<--command> I<Command>

  Specify the command. Following commands are recognized:
    BANK_STATUS - Print the status of all relays in the specified bank
    BANK_ON     - Turn ON all relays in the specified bank
    BANK_OFF    - Turn OFF all relays in the specified bank
    STATUS      - Print the status of the relay in the specified bank
    ON          - Turn ON the relay in the specified bank
    OFF         - Turn OFF the relay in the specified bank
    ALL_ON      - Turn ON all relays on all banks
    ALL_OFF     - Turn OFF all relays on all banks
    
  DEFAULT: --command STATUS

=item B<--bank> I<BankNumber>

  Specify the bank number of the relay. This should be a number 1 to 255.

=item B<--relay> I<RelayNumber>

  Specify the number of the relay. This should be a number 0 to 7.

=item B<--version>

  Print version information and exit.

=item B<--help>

  Display basic help.

=item B<--man>

  Display more detailed help.

=back

=head1 DESCRIPTION

  proxr_relay_control.pl is used to control the NCD ProXR family of relay
  controllers

=cut

