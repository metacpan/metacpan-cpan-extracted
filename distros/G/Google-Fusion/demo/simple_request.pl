#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use Google::Fusion;

my %opts;
GetOptions( \%opts,
    'client_id=s',
    'client_secret=s',
    'token_store=s',
    'sql=s',
    );

# make sure all required were given
foreach( qw/client_id client_secret token_store sql/ ){
    if( not $opts{$_} ){
	die( "Required param not defined: $_\n" );
    }
}

# Initialise the Fusion object and force the auth_client to be built to see
# if enough parameters were given (it's lazy by default)
my $fusion = Google::Fusion->new( 
    client_id	    => $opts{client_id},
    client_secret   => $opts{client_secret},
    token_store	    => $opts{token_store},
    );
my $result = $fusion->query( $opts{sql} );

foreach( @{ $result->rows } ){
    print join( ',', @{ $_ } ) . "\n";
}

exit( 0 );

=head1 NAME

simple_request.pl - Simple example of a single request on the command line

=head1 SYNOPSIS

  fusion_tables_demo.pl --client_id 372296649547.apps.googleusercontent.com \
    --client_secret AseL38Set3rjlfql7ljCuw4i --token_store /tmp/my_temporary_oauth_store \
    --sql="SHOW TABLES"

The first time you run the scirpt you will be prompted to open a URL in your browser and
after authorizing your application, paste the access code into the console to continue.
On subsequent requests you should not need to re-authorize your application. 

=head1 COPYRIGHT

Copyright 2011, Robin Clarke

=head1 AUTHOR

Robin Clarke C<perl@robinclarke.net>

=cut
