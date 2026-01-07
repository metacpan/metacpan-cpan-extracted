# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v3.0.1';

# End Of Options Delimiter
sub EOOD () { '--' }
# Flag Indicator Character Class
sub FICC () { '[!+]' }
# Option-Argument Indicator Character Class
sub OAICC () { '[,:]' }
# Perl boolean true value ( IV == 1 )
sub TRUE () { !!1 }
# Perl boolean false value
sub FALSE () { !!0 }

@Getopt::Guided::EXPORT_OK = qw( EOOD getopts processopts );

sub croakf ( $@ ) {
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  require Carp;
  goto &Carp::croak
}

sub import {
  my $module = shift;

  our @EXPORT_OK;
  my $target = caller;
  for my $function ( @_ ) {
    croakf "%s: '%s' is not exported", $module, $function
      unless grep { $function eq $_ } @EXPORT_OK;
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    *{ "$target\::$function" } = $module->can( $function )
  }
}

# Implementation is based on m//gc with \G
sub parse_spec ( $;\%$ ) {
  my ( $spec, $spec_as_hash, $spec_length_expected ) = @_;

  $spec_as_hash = {} unless defined $spec_as_hash;

  my $spec_length_got;
  no warnings qw( uninitialized ); ## no critic ( ProhibitNoWarnings )
  while ( $spec =~ m/\G ( [[:alnum:]] ) ( ${ \( FICC ) } | ${ \( OAICC ) } | )/gcox ) {
    my ( $name, $indicator ) = ( $1, $2 );
    croakf "%s parameter contains option '%s' multiple times", '$spec', $name
      if exists $spec_as_hash->{ $name };
    $spec_as_hash->{ $name } = $indicator;
    ++$spec_length_got
  }
  my $offset = pos $spec;
  croakf "%s parameter isn't a non-empty string of alphanumeric characters", '$spec'
    unless defined $offset and $offset == length $spec;
  croakf '%s parameter specifies %d options (expected: %d)', '$spec', $spec_length_got, $spec_length_expected
    if defined $spec_length_expected and $spec_length_got != $spec_length_expected;

  $spec_as_hash
}

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts ( $\%;\@ ) {
  my ( $spec, $opts, $argv ) = @_;

  my $spec_as_hash = ref $spec eq 'HASH' ? $spec : parse_spec $spec;
  croakf "%s parameter isn't an empty hash", '%$opts'
    if %$opts;
  $argv = \@ARGV unless defined $argv;

  my @argv_backup = @$argv;
  my @error;
  # Guideline 4, Guideline 9
  while ( @$argv and my ( $name, $rest ) = ( $argv->[ 0 ] =~ m/\A - (.) (.*)/ox ) ) {
    # Guideline 10
    shift @$argv, last
      if $argv->[ 0 ] eq EOOD;
    @error = ( 'illegal option', $name ), last
      unless exists $spec_as_hash->{ $name }; ## no critic ( ProhibitNegativeExpressionsInUnlessAndUntilConditions )

    my $indicator = $spec_as_hash->{ $name };
    if ( $indicator =~ m/\A ${ \( OAICC ) } \z/ox ) {
      # Case: Option has an option-argument
      # Shift delimeted option name
      shift @$argv;
      # Extract option-argument value
      my $value;
      if ( $rest ne '' ) {
        $value = $rest;
      } else {
        # Guideline 7
        @error = ( 'option requires an argument', $name ), last
          unless @$argv;
        # Guideline 6, Guideline 8
        @error = ( 'option requires an argument', $name ), last
          unless defined( $value = shift @$argv );
      }
      # Store option-argument value
      if ( $indicator eq ':' ) {
        # Standard behaviour: Overwrite option-argument
        $opts->{ $name } = $value
      } else {
        # Create and fill list of option-arguments ( $indicator eq ',' )
        $opts->{ $name } = [] unless exists $opts->{ $name };
        push @{ $opts->{ $name } }, $value
      }
    } else {
      # Case: Option is a flag
      if ( not exists $opts->{ $name } ) {
        # Initialisation
        $opts->{ $name } = TRUE
      } elsif ( $indicator eq '!' ) {
        # Negate logically
        $opts->{ $name } = not $opts->{ $name }
      } elsif ( $indicator eq '+' ) {
        # Increment
        ++$opts->{ $name }
      }
      # Guideline 5
      if ( $rest eq '' ) {
        # Shift delimeted option name
        shift @$argv
      } else {
        $argv->[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
      }
    }

  }

  if ( @error ) {
    # Restore to avoid side effects
    @$argv = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = ();
    # Prepare and print warning message:
    # Program name, type of error, and invalid option character
    require File::Basename;
    warn sprintf( "%s: %s -- %s\n", File::Basename::basename( $0 ), @error ) ## no critic ( RequireCarping )
  }

  @error == 0
}

sub processopts ( \@@ ) {
  my $argv          = shift;
  my $spec_as_array = do { my $t = 0; [ grep $t ^= 1, @_ ] }; ## no critic ( RequireBlockGrep )

  # Check each option specification individually (1)
  my $spec_as_hash;
  parse_spec $_, %$spec_as_hash, 1 for @$spec_as_array;

  return FALSE unless getopts $spec_as_hash, my %opts, @$argv;

  # This ordered processing could be a feature
  for ( my $i = 0 ; $i < @_ ; $i += 2 ) {
    # If $_[ $i ] refers to a flag with no indicator, the split still returns
    # the empty string (not undef!) as the value for the indicator
    my ( $name, $indicator ) = split //, $_[ $i ];
    if ( exists $opts{ $name } ) {
      my $value         = delete $opts{ $name };
      my $dest          = $_[ $i + 1 ];
      my $dest_ref_type = ref $dest;
      if ( $dest_ref_type eq 'SCALAR' ) {
        ${ $dest } = $value
      } elsif ( $dest_ref_type eq 'ARRAY' and $indicator eq ',' ) {
        @{ $dest } = @$value
      } elsif ( $dest_ref_type eq 'CODE' ) {
        # Callbacks are called in scalar context
        last if $dest->( $value, $name, $indicator ) eq EOOD
      } else {
        croakf "'%s' is an unsupported destination reference type for the '%s' indicator", $dest_ref_type, $indicator
      }
    }
  }

  TRUE
}

1
