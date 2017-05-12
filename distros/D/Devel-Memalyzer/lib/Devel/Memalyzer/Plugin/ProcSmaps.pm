package Devel::Memalyzer::Plugin::ProcSmaps;
use strict;
use warnings;

use base 'Devel::Memalyzer::Base';

BEGIN {
    die( __PACKAGE__ . ' cannot be used without a proc filesystem')
        unless -e '/proc';
}

sub collect {
    my $self = shift;
    my ( $pid ) = @_;

    return $self->capture_smaps( $pid );
}

sub smaps {
    my $self = shift;
    my ( $pid ) = @_;
    return "/proc/$pid/smaps";
}

sub capture_smaps {
    my $self = shift;
    my ( $pid ) = @_;
    my $smaps_file = $self->smaps( $pid );

    my %data;
    next unless -e $smaps_file && -r $smaps_file;
    open( my $smap, '<', $smaps_file ) || die( "Error opening smaps: $!" );
    my $module;
    while( my $line = <$smap> ) {
        chomp( $line );
        if ( $module ) {
            $line =~ m/^Size:\s+(\d+)/i;
            $data{ $module } += $1;
            $module = undef;
            next;
        }
        next unless $line =~ m{(/lib/perl5/.*$)};
        $module = $1;
        $data{ $module } ||= 0;
    }
    close( $smap );
    return %data;
}

1;

__END__

=head1 NAME

Devel::Memalyzer::Plugin::ProcSmaps - Plugin to get compiled perl module memory
usage from /proc/smaps

=head1 DESCRIPTION

Adds a column for every compiled perl module to your output. Does not collect
information for normal perl modules.

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

