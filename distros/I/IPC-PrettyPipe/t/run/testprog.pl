#!perl

use strict;
use warnings;
use IO::Handle;
use Data::Dumper;
use File::Spec::Functions qw[ catfile ];

use Getopt::Long;

my @fh = ( [ \*STDIN, '<' ], [ \*STDOUT, '>' ], [ \*STDERR, '>' ], );

my %opt;

GetOptions( \%opt,
	    qw[
		  logdir=s
		  long=s
		  sleep=i
		  s=s
		  name=s
	  ] )
  or die;

die( "must specify name\n" )
  unless defined $opt{name};

die( "must specify logdir\n" )
  unless defined $opt{logdir};

my %LOG = %opt;


sleep( $opt{sleep} ) if defined $opt{sleep};

while ( @ARGV ) {

    my $fd = shift @ARGV;

    my ( $fh, my $mode )
      = @{ $fh[$fd]
          // [ IO::Handle->new_from_fd( $fd, $ARGV[0] ), shift @ARGV ] };

    die( "can't open $fd\n" )
      unless defined $fh;

    if ( $mode eq '<' or $mode eq 'r' ) {

	my @input = $fh->getlines;

	$LOG{$fd} = \@input;

        print STDOUT @input if $fd == 0;

    }
    else {

        $fh->say( "$opt{name} $fd");

    }


}

my $logfile = catfile( $opt{logdir}, $opt{name} ) . ".log";
open( LOG, '>', $logfile )
  or die( "error creating $logfile\n" );

print LOG Dumper( \%LOG );

close LOG;
