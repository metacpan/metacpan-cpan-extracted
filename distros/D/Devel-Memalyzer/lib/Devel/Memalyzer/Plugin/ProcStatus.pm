package Devel::Memalyzer::Plugin::ProcStatus;
use strict;
use warnings;

BEGIN {
    die( __PACKAGE__ . ' cannot be used without a proc filesystem')
        unless -e '/proc';
}

use base 'Devel::Memalyzer::Base';

sub collect {
    my $self = shift;
    my ( $pid ) = @_;
    return $self->capture_status( $pid );
}

sub status {
    my $self = shift;
    my ( $pid ) = @_;
    return "/proc/$pid/status";
}

sub capture_status {
    my $self = shift;
    my ( $pid ) = @_;
    open( my $status, '<', $self->status( $pid )) || die( "Error opening status: $!" );
    my %data;
    while( my $line = <$status> ){
        next unless $line =~ m/^Vm/;
        chomp( $line );
        my ( $key, $value ) = split( /:\s+/, $line );
        $value =~ s/\s.*$//;
        $data{ $key } = $value;
    }
    return %data;
}

1;

__END__

=head1 NAME

Devel::Memalyzer::Plugin::ProcStatus - Collect process memory statistics from
/proc/$pid/status

=head1 DESCRIPTION

Adds all Vm*: entries from /proc/$pid/status as columsn in your output.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

