package Devel::MAT::InternalTools;

use strict;
use warnings;

our $VERSION = '0.25';

package Devel::MAT::Tool::help;

use base qw( Devel::MAT::Tool );
use constant CMD => "help";

sub run_cmd
{
   my $self = shift;
   my $pmat = $self->{pmat};

   my @commands = sort map {
      my $class = "Devel::MAT::Tool::$_";
      $class->can( "CMD" ) ? ( $class->CMD ) : ()
   } $pmat->available_tools;

   Devel::MAT::Cmd->printf( "%s\n", $_ ) for @commands;
}

0x55AA;
