package Enbld::Command::Freeze;

use strict;
use warnings;

use 5.010001;

use parent qw/Enbld::Command/;

use Encode;

require Enbld::App::Configuration;
require Enbld::Error;
require Enbld::Message;
require Enbld::Feature;
require Enbld::Home;

sub do {
    my $self = shift;

    $self->setup;

    my $str = do { local $/; <DATA> };

    print $str;

    my $home = $ENV{PERL_ENBLD_HOME} ? '$ENV{PERL_ENBLD_HOME}' :
        '$ENV{HOME}/.enbld';

    say 'use lib "' . $home . '/extlib/lib/perl5/";';
    say "";
    say 'use Enbld;';
    say "";
    say "enbld '" . Enbld::App::Configuration->envname . "' => build {";
    say "";

    output_targets();

    print "\n";

    output_rcfiles();


    say "};";

    return $self;
}

sub output_targets {
    return unless Enbld::App::Configuration->config;

    foreach my $name ( sort keys %{ Enbld::App::Configuration->config } ) {
        my $config = Enbld::App::Configuration->search_config( $name );

        next unless $config->enabled;

        my $lines = $config->DSL;

        foreach my $line ( @{ $lines } ) {
            print '    ' . encode( 'UTF-8', $line );
        }

        print "\n";
    }
}

sub output_rcfiles {
    return unless Enbld::App::Configuration->rcfile;

    foreach my $file ( sort keys %{ Enbld::App::Configuration->rcfile } ) {
        my $rcfile = Enbld::App::Configuration->search_rcfile( $file );

        my $lines = $rcfile->DSL;

        foreach my $line ( @{ $lines } ) {
            print '    ' . $line;
        }

        print "\n";
    }
}

1;

__DATA__
#!/usr/bin/perl

use strict;
use warnings;

use utf8;

