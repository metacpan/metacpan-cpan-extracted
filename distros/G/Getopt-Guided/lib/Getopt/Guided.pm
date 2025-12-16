# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v2.0.0';

use Carp           qw( croak );
use File::Basename qw( basename );

# Flag Indicator Character Class
sub FICC () { '[!+]' }
# Option-Argument Indicator Character Class
sub OAICC () { '[,:]' }
# Perl boolean true value ( IV == 1 )
sub TRUE () { !!1 }

@Getopt::Guided::EXPORT_OK = qw( getopts getopts3 );

sub import {
  my $module = shift;

  our @EXPORT_OK;
  my $target = caller;
  for my $function ( @_ ) {
    croak "$module: '$function' is not exported, stopped"
      unless grep { $function eq $_ } @EXPORT_OK;
    no strict 'refs'; ## no critic ( ProhibitNoStrict )
    *{ "$target\::$function" } = $module->can( $function )
  }
}

# Implementation is based on m//gc with \G
sub parse_spec ( $ ) {

  my $spec = shift;

  my $spec_as_hash;
  no warnings qw( uninitialized ); ## no critic ( ProhibitNoWarnings )
  while ( $spec =~ m/\G ( [[:alnum:]] ) ( ${ \( FICC ) } | ${ \( OAICC ) } | )/gcox ) {
    my ( $name, $indicator ) = ( $1, $2 );
    croak "parse_spec: \$spec parameter contains option '$name' multiple times, stopped"
      if exists $spec_as_hash->{ $name };
    $spec_as_hash->{ $name } = $indicator;
  }
  my $offset = pos $spec;
  croak "parse_spec: \$spec parameter isn't a non-empty string of alphanumeric characters, stopped"
    unless defined $offset and $offset == length $spec;

  $spec_as_hash
}

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts3 ( \@$\% ) {
  my ( $argv, $spec, $opts ) = @_;

  my $spec_as_hash = parse_spec $spec;
  croak "getopts: \$opts parameter hash isn't empty, stopped"
    if %$opts;

  my @argv_backup = @$argv;
  my @error;
  # Guideline 4, Guideline 9
  while ( @$argv and my ( $name, $rest ) = ( $argv->[ 0 ] =~ m/\A - (.) (.*)/ox ) ) {
    # Guideline 10
    shift @$argv, last
      if $argv->[ 0 ] eq '--';
    @error = ( 'illegal option', $name ), last
      unless exists $spec_as_hash->{ $name }; ## no critic ( ProhibitNegativeExpressionsInUnlessAndUntilConditions )

    my $indicator = $spec_as_hash->{ $name };
    if ( $indicator =~ m/\A ${ \( OAICC ) } \z/ox ) {
      # Case: Option has an option-argument
      # Guideline 5
      @error = ( "option with argument isn't last one in group", $name ), last
        unless $rest eq '';
      # Shift delimeted option name
      shift @$argv;
      # Guideline 7
      @error = ( 'option requires an argument', $name ), last
        unless @$argv;
      # Guideline 6, Guideline 8
      @error = ( 'option requires an argument', $name ), last
        unless defined( my $value = shift @$argv );
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
      if ( $rest eq '' ) {
        # Shift delimeted option name
        shift @$argv
      } else {
        # Guideline 5
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
    warn sprintf( "%s: %s -- %s\n", basename( $0 ), @error ); ## no critic ( RequireCarping )
  }

  @error == 0
}

sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  getopts3 @ARGV, $spec, %$opts
}

1
