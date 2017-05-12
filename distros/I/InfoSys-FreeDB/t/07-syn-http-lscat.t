use strict;
use Error qw(:try);
use File::Spec;
use IO::File;
use Test::More;

# Globals
my $todo = 2;
my $done = 0;

# Start plan
plan ( tests => $todo );

# 1) Read options
if ( &read_options() ) {
    ok( 0, 'Read t/options' ); $done++; $todo--;
    my_skip( 'cannot proceed' );
}
ok( 1, "Read t/options" ); $done++; $todo--;

# 5-15) Test http lscat synopsis
&test_syn();

# Exit
exit(0);

sub test_syn {
    SKIP: {
        # Check for skip
        if ( ! $::opt{test_http_lscat_syn} ) {
            my $fn = File::Spec->catfile( 't', 'options' );
            my_skip( "test_http_lscat_syn is not set in file '$fn'" );
        }

        # 2) Require synopsis
        my $fn = File::Spec->catfile( 'gen', 'syn-http-lscat.pl' );
        try {
            require( $fn );
        }
        catch Error::Simple with {
            my $e = shift;
            ok( 0, "Requiring file '$fn' failed: " . $e->{-text} ); $done++; $todo--;
            my_skip( "Requiring file '$fn' failed." );
        };
        ok( 1, "Require file '$fn'" ); $done++; $todo--;
    }
}


sub read_options {
    my $fn = File::Spec->catfile( 't', 'options' );
    my $fh = IO::File->new("< $fn");
    defined($fh) ||
       return(1);
    %::opt = ();
    while ( my $line = $fh->getline() ) {
        $line =~ s/\s+$//;
        $line =~ s/#.*$//;
        my ($attr, $val) = $line =~ /([^:]+):(.*)/;
        if ( ! defined( $attr ) ) { $attr = '' }
        if ( ! defined( $val ) ) { $val = '' }
        $attr =~ s/^\s+//; $attr =~ s/\s+$//;
        $val =~ s/^\s+//; $val =~ s/\s+$//;
        $attr ||
            next;
        $val ||
            next;
        $::opt{$attr} = $val;
    }
   return(0);
}

sub my_skip {
    my $msg = shift;

    skip( $msg, $todo );
}

