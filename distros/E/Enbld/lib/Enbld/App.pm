package Enbld::App;

use strict;
use warnings;

use Getopt::Long;

sub new {
    my $class = shift;

    my $self = {
        cmd         =>  'usage',
        argv        =>  [],
    };

    return bless $self, $class;
}

sub parse_options {
    my $self = shift;

    local @ARGV;
    push @ARGV, @_;

    my $make_test;
    my $force;
    my $current;

    Getopt::Long::Configure( "bundling" );
    Getopt::Long::GetOptions(
            'v|version'     => sub { $self->{cmd} = 'version' },
            'h|help'        => sub { $self->{cmd} = 'help' },
            't|test'        => sub { $make_test++ },
            'f|force'       => sub { $force++ },
            'c|current'     => sub { $current++ },
            );

    if ( @ARGV ) {
        $self->{cmd}    = shift @ARGV;
        $self->{argv}   = \@ARGV;
    }

    require Enbld::Feature;
    Enbld::Feature->initialize(
            make_test   =>  $make_test,
            force       =>  $force,
            current     =>  $current,
            );

    return $self;
}

sub envbuild {
    my $self = shift;

    require Enbld::Message;
    Enbld::Message->set_verbose;

    require Enbld::Command;
    my $cmd = Enbld::Command->new(
            cmd         => $self->{cmd},
            argv        => $self->{argv},
            );

    $cmd->do;
}

1;
