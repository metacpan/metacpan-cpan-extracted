package Devel::Profit::Cmd::Command::Package;
use strict;
use warnings;
use IO::File;
use PPI;
use PPIx::LineToSub;
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
    return "devel_profit package [--filename other.out]";
}

sub abstract {
    my $self = shift;
    return 'Profile by package';
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
            my $file     = $file{$file_number};
            my $document = get_document($file);
            next unless $document;

            my ( $package, $sub ) = $document->line_to_sub($line);
            $usecs{$package} += $usecs;
            $totusecs += $usecs;
        }
    }

    $self->show( \%usecs, $totusecs );
}

my %cache;

sub get_document {
    my ($file) = @_;
    if ( $cache{$file} ) {
        return $cache{$file};
    }
    my $document = PPI::Document->new($file);
    return unless $document;
    $document->index_line_to_sub;
    $cache{$file} = $document;
    return $document;

}

1;
