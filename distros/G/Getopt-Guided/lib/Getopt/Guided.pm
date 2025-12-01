# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v1.0.0';

use Carp           qw( croak );
use Exporter       qw( import );
use File::Basename qw( basename );

# Option-Argument Indicator Character Class
sub OAICC () { '[,:]' }

@Getopt::Guided::EXPORT_OK = qw( getopts );

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  croak "getopts: \$spec parameter isn't a string of alphanumeric characters, stopped"
    unless $spec =~ m/\A (?: [[:alnum:]] ${ \( OAICC ) } ?)+ \z/x;
  my @chars = split( //, $spec );
  {
    my %dups;
    for ( @chars ) {
      next if m/\A ${ \( OAICC ) } \z/x;
      croak 'getopts: $spec parameter contains duplicate option characters, stopped'
        if exists $dups{ $_ };
      ++$dups{ $_ }
    }
  }
  croak "getopts: \$opts parameter hash isn't empty, stopped"
    if %$opts;

  my @argv_backup = @ARGV;
  my @error;
  # Guideline 4, Guideline 9
  while ( @ARGV and my ( $first, $rest ) = ( $ARGV[ 0 ] =~ m/\A-(.)(.*)/ ) ) {
    # Guideline 10
    shift @ARGV, last if $ARGV[ 0 ] eq '--';
    my $pos = index( $spec, $first );
    if ( $pos >= 0 ) {
      # The option-argument indicator "," or ":" is the character that follows
      # an option character if the option requires an option-argument
      my $ind = $chars[ $pos + 1 ];
      if ( defined $ind and $ind =~ m/\A ${ \( OAICC ) } \z/x ) {
        shift @ARGV;
        if ( $rest eq '' ) {
          # Guideline 7
          @error = ( 'option requires an argument', $first ), last
            unless @ARGV;
          # Guideline 6, Guideline 8
          @error = ( 'option requires an argument', $first ), last
            unless defined( my $argv = shift @ARGV );
          if ( $ind eq ':' ) {
            # Option-argument overwrite situation!
            $opts->{ $first } = $argv
          } else {
            # Create and fill list of option-arguments
            $opts->{ $first } = [] unless exists $opts->{ $first };
            push @{ $opts->{ $first } }, $argv
          }
        } else {
          # Guideline 5
          @error = ( "option with argument isn't last one in group", $first );
          last;
        }
      } else {
        ++$opts->{ $first };
        if ( $rest eq '' ) {
          shift @ARGV
        } else {
          # Guideline 5
          $ARGV[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
        }
      }
    } else {
      @error = ( 'illegal option', $first ), last
    }
  }

  if ( @error ) {
    # Restore to avoid side effects
    @ARGV = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = ();
    # Prepare and print warning message:
    # Program name, type of error, and invalid option character
    warn sprintf( "%s: %s -- %s\n", basename( $0 ), @error ); ## no critic ( RequireCarping )
  }

  @error == 0
}

1
