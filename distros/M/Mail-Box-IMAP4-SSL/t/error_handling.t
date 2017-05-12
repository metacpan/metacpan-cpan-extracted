package main;
use strict;
use warnings;

#--------------------------------------------------------------------------#
# requirements, fixtures and plan
#--------------------------------------------------------------------------#

use Test::More;
use IO::CaptureOutput qw/capture/;

my %required_options = (
    username    => 'john@example.net',
    password    => 'qwerty',
    server_name => 'imap.example.com',
);

my $package = 'Mail::Box::IMAP4::SSL';

plan tests => 3 + 2 * keys %required_options;

#--------------------------------------------------------------------------#
# tests begin here
#--------------------------------------------------------------------------#

require_ok($package);

#--------------------------------------------------------------------------#
# testing new() with invalid 'transport' argumeng
#--------------------------------------------------------------------------#

{
    my ( $imap, $stdout, $stderr );
    capture sub {
        $imap = Mail::Box::IMAP4::SSL->new( transporter => {} );
      } => \$stdout,
      \$stderr;

    is( $imap, undef, "Using 'transporter' option: no object created" );
    like(
        $stderr,
        qr/\QThe 'transporter' option is not valid for $package\E/,
        "Using 'transporter' option: error message correct"
    );
}

#--------------------------------------------------------------------------#
# testing new() with missing arguments
#--------------------------------------------------------------------------#

for my $missing ( keys %required_options ) {
    my ( $stdout, $stderr, $imap );
    my %options = %required_options;
    delete $options{$missing};

    capture sub {
        $imap = Mail::Box::IMAP4::SSL->new(%options);
      } => \$stdout,
      \$stderr;

    is( $imap, undef, "Missing '$missing': no object created" );
    like(
        $stderr,
        qr/\QThe '$missing' option is required for $package\E/,
        "Missing '$missing': error message correct"
    );
}

