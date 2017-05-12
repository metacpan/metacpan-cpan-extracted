package IO::Capture::Extended;
use strict;
use warnings;
our $VERSION = 0.13;
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(
    grep_print_statements
    statements
    matches
    matches_ref
    all_screen_lines
); 
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );


sub grep_print_statements {
    my $self = shift;
    my $string = shift;
    my @found_statements;
 
    for my $statement (@{$self->{'IO::Capture::messages'}}) {
        push @found_statements, $statement if $statement =~ /$string/;
    }
    return wantarray ? @found_statements : scalar(@found_statements);
}

sub statements {
    my $self = shift;
    return scalar(@{$self->{'IO::Capture::messages'}});
};

sub matches {
    my @matches = _matches_engine(@_);
    return wantarray ? @matches : scalar(@matches);
}

sub matches_ref {
    my @matches = _matches_engine(@_);
    return \@matches;
}

sub _matches_engine {
    my ($self, $regex) = @_;
    die "Not enough arguments: $!" 
        if (! defined $regex);
    my $str = join('', @{$self->{'IO::Capture::messages'}});
    my @matches = $str =~ m/$regex/g;
}

sub all_screen_lines {
    my $self = shift;
    my @screen_lines;
    @screen_lines = split(/\n/, join('', @{$self->{'IO::Capture::messages'}}));
    return wantarray ? @screen_lines : scalar(@screen_lines);
}

########## DOCUMENTATION ##########

=head1 NAME

IO::Capture::Extended - Extend functionality of IO::Capture

=head1 SYNOPSIS

All documentation is contained in IO::Capture::Extended::Overview.

    perldoc IO::Capture::Extended::Overview

=cut

1;

