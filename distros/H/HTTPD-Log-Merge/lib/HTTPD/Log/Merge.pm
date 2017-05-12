package HTTPD::Log::Merge;

#------------------------------------------------------------------------------
#
# Standard pragmas
#
#------------------------------------------------------------------------------

require v5.6.0;

use strict;
use warnings;

use vars qw( $VERSION );

$VERSION = 1.00;

use IO::File;
use Date::Parse;
use HTTPD::Log::Filter;

sub compare_times
{
    my $self = shift;
    ( $self->{c} ) = 
        sort { $self->{t}[$a] <=> $self->{t}[$b] }
        @{$self->{indexes}}
    ;
}

sub new
{
    my $class = shift;
    my %args = @_;

    my $self = bless \%args, $class;
    die "logfile option required\n" unless $self->{logfile};
    die "logfile option should be and arrayref\n" 
        unless ref( $self->{logfile} ) eq 'ARRAY'
    ;
    die "two or more logfiles required\n" unless @{$self->{logfile}} > 1;
    $self->{out_fh} ||= *STDOUT;
    $self->{fh} = [ 
        map { IO::File->new( $_ ) or die "Can't open $_: $!\n"; } 
        @{$self->{logfile}}
    ];
    $self->{filter} = [
        map {
            my $filter = HTTPD::Log::Filter->new() 
                or die "Can't create filter\n"
            ;
            my $format = $filter->detect_format( filename => $_ );
            my $capture = $format eq 'SQUID' ? 'time' : 'date';
            $filter->capture( [ $capture ] );
            $filter;
        }
        @{$self->{logfile}}
    ];

    $self->{indexes} = [ 0 .. @{$self->{logfile}}-1 ];
    for ( @{$self->{indexes}} )
    {
        $self->get_line( $_ );
    }
    $self->compare_times();
    return $self;
}

sub get_line
{
    my $self = shift;
    my $index = shift;

    $self->{line}[$index] = $self->{fh}[$index]->getline;
    unless ( defined $self->{line}[$index] )
    {
        $self->{t}[$index] = time;
        return;
    }
    $self->{filter}[$index]->filter( $self->{line}[$index] )
        or die 
            "Badly formatted line: $self->{line}[$index]\n",
            $self->{filter}->re,
            "\n"
    ;
    my $time;
    eval { $time = $self->{filter}[$index]->time };
    unless( $time )
    {
        my $date = $self->{filter}[$index]->date
            or die "Can't get date for $self->{logfile}[$index]\n"
        ;
        $time = str2time( $date );
    }
    $self->{t}[$index] = $time;
}

sub merge
{
    my $self = shift;

    my $old_fh = select( $self->{out_fh} );
    while ( grep { defined( $_ ) } @{$self->{line}} )
    {
        print $self->{line}[$self->{c}];
        $self->get_line( $self->{c} );
        $self->compare_times();
    }
    select( $old_fh );
    print STDERR "\n" if $self->{verbose};
}

#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

HTTPD::Log::Merge

=head1 SYNOPSIS

    my $merge = HTTPD::Log::Merge->new(
        logfile => \@logfiles,
        verbose => 1,
        out_fh => \*STDOUT,
    );
    $merge->merge;

=head1 DESCRIPTION

HTTPD::Log::Merge is a simple module for merging httpd logfiles. It takes a
list of log files and merges them based on the date of each entry in the
logfile. It works for NSCA style httpd logs (Common Log Format, Extended Log
Format and the like) - see L<HTTPD::Log::Filter> for more information on
supported log formats.

=head1 CONSTRUCTOR

The constructor for HTTPD::Log::Merge takes the following options passed as a
hash:

=head2 logfile

This option should contain an array ref of paths to httpd logfiles. The option
is required, and there need to be two or more logfiles.

=head2 out_fh

A filehandle to output merged logfile to. Defaults to STDOUT.

=head2 verbose

Print interesting stuff to STDERR.

=head1 METHODS

=head2 merge

Does exactly what it says on the can!

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

# True ...

1;
