package Devel::Profit::Cmd::Command::File;
use strict;
use warnings;
use IO::File;
use Moose;
extends qw(Devel::Profit::Cmd::Command MooseX::App::Cmd::Command);

has filename => (
    isa           => "Str",
    is            => "rw",
    cmd_aliases   => "file",
    documentation => "read from a specific filename",
);

sub usage_desc {
    my $self = shift;
    return "devel_profit file [--filename other.out]";
}

sub abstract {
    my $self = shift;
    return 'Profile by file';
}

sub run {
    my ( $self, $opt, $args ) = @_;

    my $filename = $self->filename || 'profit.out';
    my $fh = IO::File->new('profit.out') || die "Could not open profit.out";

    my $line = <$fh>;

    my %usecs;
    my $totusecs;
    my %file;

    printf( "%s %s\n", '%Time', 'Filename' );

    while ( my $row = <$fh> ) {
        if ( my ( $file_number, $file, $usecs ) = $row =~ /^(\d+)=(.*)$/ ) {
            $file{$file_number} = $file;
        } else {
            my ( $file_number, $line, $usecs )
                = $row =~ /^(\d+):(\d+) (\d+)$/;
            my $file = $file{$file_number};
            $usecs{"$file"} += $usecs;
            $totusecs += $usecs;
        }
    }

    $self->show( \%usecs, $totusecs );
}

1;

