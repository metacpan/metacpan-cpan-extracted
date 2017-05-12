package Devel::Memalyzer;
use strict;
use warnings;

use base 'Devel::Memalyzer::Base';
use Carp;
use IO qw/Handle File Pipe/;

our $VERSION = 0.001;
our $SINGLETON;

__PACKAGE__->gen_accessors(qw/ output columns headers /);

sub import {
    my $class = shift;
    return unless @_;
    $class->init( @_ );
}

sub singleton { $SINGLETON }

sub init {
    my $class = shift;
    carp( "re-initializing $class, this will destroy your old one and is probably not what you want" )
        if $SINGLETON;
    $SINGLETON = $class->new( @_ );
    return $class->singleton;
}

sub record {
    my $self = shift;
    my ( $pid ) = @_;
    my %data = (
        timestamp => time,
        (map { $_->collect( $pid ) } $self->plugins),
        $self->collect_columns( $pid ),
    );

    $self->sync_headers( \%data );

    my ( $raw ) = $self->output_handles;
    print $raw join( ',', @data{ @{ $self->headers }}) . "\n";
}

sub plugins {
    my $self = shift;
    return unless $self->{ _plugins } || $self->{ plugins };
    $self->{ _plugins } ||= [ map {
        eval "require $_; 1" || die( $@ );
        $_->new;
    } @{ $self->{ plugins }}];
    return @{ $self->{ _plugins }};
}

sub add_column {
    my $self = shift;
    my ( $name, $sub ) = @_;
    $self->columns({}) unless $self->columns();
    $self->columns->{ $name } = $sub;
}

sub del_column {
    my $self = shift;
    my ( $name ) = @_;
    my $columns = $self->columns;
    delete $columns->{ $name };
}

sub collect_columns {
    my $self = shift;
    my ( $pid ) = @_;

    my %data;
    for my $column ( keys %{ $self->columns || {}}) {
        my $sub = $self->columns->{ $column };
        $data{ $column } = $sub->( $pid );
    }
    return %data;
}

sub sync_headers {
    my $self = shift;
    my ( $data ) = @_;

    my $old = $self->headers;
    my $new = [ reverse sort keys %$data ];

    # return if headers are unchanged
    return if $old && join('', @$old) eq join('', @$new);

    $self->headers( $new );

    my ( $raw, $headers )= $self->output_handles;
    print $raw "\n" if $old;
    print $headers join(',', @$new ). "\n";
}

sub output_handles {
    my $self = shift;

    unless( $self->{ output_handles }) {
        my $file = $self->output;

        die( "Refusing to override exisiting output file: '$file'" )
            if -e $file;

        open( my $raw, '>', $self->output . ".raw" ) || die( "Error opening output file: $!" );
        open( my $headers, '>', $self->output . ".head" ) || die( "Error opening output file: $!" );
        $raw->autoflush( 1 );
        $headers->autoflush( 1 );
        $self->{ output_handles } = [ $raw, $headers ];
    }

    return @{ $self->{ output_handles }};
}

sub finish {
    my $self = shift;
    return unless $self->{ output_handles };
    my ($raw, $headers) = @{ $self->{ output_handles }};
    close( $raw ) if $raw;
    close( $headers ) if $headers;
}

sub DESTROY {
    my $self = shift;
    $self->finish;
}

1;

__END__

=pod

=head1 NAME

Devel::Memalyzer - Base framework for analyzing program memory usage

=head1 DESCRIPTION

Devel-Memalyzer is a base framework for analyzing program memory usage. You can
use it to run a program and collect statistics about overall memory usage, or
you can use it in your code itself and record statistics at specific points.

=head1 COMMAND LINE SYNOPSYS

To run a program and collect overall statistics:

    $ memalyzer.pl output.csv "perl -I lib -e 'use MyModule; MyModule->go'"
    $ memalyzer.pl output.csv "scripts/mything.pl"

If you needed to interrupt the process you can use the data that was collected:

    $ memalyzer-combine.pl output.csv

This will take output.csv.head and output.csv.raw and combine them to create
output.csv. This is done automatically if your program finishes itself.

=head1 IN PROGRAM SYNOPSYS

You can also use memalyzer in a program:

    use Devel::Size qw(size total_size);
    use Devel::Memalyzer;
    my $mem = Devel::Memalyzer->new( ... );
    ...
    $mem->record;

    my $obj = MyObj->new;

    # This will add columns to the output.
    for my $thing ( @things ) {
        $mem->add_column( $thing => sub { total_size( obj->$thing )})
    }

    while ( $obj->iteration ) {
        # Records data from plugins as well as your custom columns.
        $mem->record;
    }

This will produce output.csv.head and output.csv.raw, to combine them:

    $ memalyzer-combine.pl output.csv

=head1 SINGLETON SYNOPSYS

Sometimes you want to use Memalyzer in a broader scope and don't want to worry
about passing your object around, in these cases you can use it as a singleton.

    use Devel::Memalyzer

    Devel::Memalyzer->init(
        output => 'output.csv',
        plugins => [ 'Devel::Memalyzer::Plugin::ProcStatus' ];
    );

    my $mem = Devel::Memalyzer->singleton;

You can also initialize the singleton at use-time:

    use Devel::Memalyzer output => 'output.csv',
                         plugins => [ 'Devel::Memalyzer::Plugin::ProcStatus' ];

    my $mem = Devel::Memalyzer->singleton;

=head1 INTERFACE METHODS

These are the methods useful to the average user.

=over 4

=item $obj = $class->new( output => $file, plugins => [ ... ])

Create a new instance of Devel-Memalyzer

=item $obj = $class->init( output => $file, plugins => [ ... ])

Initialize the singleton instance of Devel-Memalyzer

=item $obj = $class->singleton()

Retrieve the singleton instance of Devel-Memalyzer

=item $obj->record()

Write current memory statistics to the data files

=item $obj->add_column( name => sub { ... })

Add a column to future output. The column will have the provided name. The
coderef should return the value that will be inserted into data rows under the
specified column.

=item $obj->del_column( 'name' )

Remove a row from future output (previously recorded rows will not be modified)

=item $obj->finish()

Close the filehandles, you will need to do this if you want to use combine()
and the instance has not been destroyed or is a singleton.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

