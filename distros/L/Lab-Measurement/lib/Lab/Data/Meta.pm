#!/usr/bin/perl -w

package Lab::Data::Meta;
our $VERSION = '3.542';

use strict;
use Carp;
use Lab::Data::XMLtree;
use File::Basename;
use Cwd 'abs_path';
use Data::Dumper;
require Exporter;

our @ISA = qw(Exporter Lab::Data::XMLtree);

our $AUTOLOAD;

our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

my $declaration = {
    data_complete => ['SCALAR'],    # boolean

    dataset_title       => ['SCALAR'],
    dataset_description => ['SCALAR'],    # multiline
    sample              => ['SCALAR'],
    data_file           => ['SCALAR'],    # relativ zur descriptiondatei

    block => [
        'ARRAY', 'id',
        {
            original_filename => ['SCALAR']
            ,                             # nur von GPplus-Import unterstützt
            timestamp   => ['SCALAR'],    # Format %Y/%m/%d-%H:%M:%S
            description => ['SCALAR'],
            label       => ['SCALAR'],
        }
    ],
    column => [
        'ARRAY',
        'id',
        {
            unit        => ['SCALAR'],
            label       => ['SCALAR'],    # evtl. weg
            description => ['SCALAR'],    # evtl. weg
            min => ['SCALAR'],  # unnütz, aber von GPplus-Import unterstützt
            max => ['SCALAR'],  # dito
        }
    ],
    axis => [
        'ARRAY',
        'id',
        {
            label       => ['SCALAR'],
            unit        => ['SCALAR'],
            expression  => ['SCALAR'],
            min         => ['SCALAR'],
            max         => ['SCALAR'],
            description => ['SCALAR'],    # evtl. weg
        }
    ],
    plot => [
        'HASH',
        'name',
        {
            type     => ['SCALAR'],       # line, pm3d
            xaxis    => ['SCALAR'],
            xformat  => ['SCALAR'],
            yaxis    => ['SCALAR'],
            yformat  => ['SCALAR'],
            zaxis    => ['SCALAR'],
            zformat  => ['SCALAR'],
            cbaxis   => ['SCALAR'],
            cbformat => ['SCALAR'],
            logscale => ['SCALAR'],       # z.b: 'x' oder 'yzxcb'
            time     => ['SCALAR']
            , # ??? (was: wie oben (anders als in GnuPlot) (Achsen müssen %s-Format haben))
            grid    => ['SCALAR'],    # z.B. 'ytics' oder 'xtics ytics'
            palette => ['SCALAR'],
            label   => [
                'ARRAY', 'id',
                {
                    text => ['SCALAR'],
                    x    => ['SCALAR'],
                    y    => ['SCALAR'],
                }
            ],
        }
    ],
    constant => [
        'ARRAY',
        'id',
        {
            name  => ['SCALAR'],
            value => ['SCALAR'],
        }
    ],
};

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless $class->SUPER::new( $declaration, pop @_ ), $class;

    # this pop is here as a clumsy work-around to
    # when xmltree creates a new Lab::Meta with a declaration
    # as first argument
}

sub new_from_file {
    my $proto    = shift;
    my $class    = ref($proto) || $proto;
    my $filename = shift;
    if ( my $self = $class->read_xml( $declaration, $filename ) ) {
        my $filepath = abs_path($filename);
        my ( $file, $path, $suffix ) = fileparse( $filepath, qr/\.[^.]*/ );
        $path =~ s/\\/\//g;
        $self->{__abs_path} = $path;
        return $self;
    }
    warn "Cannot load meta data from file!\n";
}

sub save {
    my $self     = shift;
    my $filename = shift;
    $self->save_xml( $filename, $self, 'metadata' );
    my $filepath = abs_path($filename);
    my ( $file, $path, $suffix ) = fileparse( $filepath, qr/\.[^.]*/ );
    $path =~ s/\\/\//g;
    $self->{__abs_path} = $path;
}

sub get_abs_path {

    # I think this should really be someone else's job!
    my $self = shift;
    return $self->{__abs_path};
}
1;

__END__

=encoding utf8

=head1 NAME

Lab::Data::Meta - Meta data for datasets

=head1 SYNOPSIS

    use Lab::Data::Meta;
    
    my $meta2=new Lab::Data::Meta({
        dataset_title  => "testtest",
        column         => [
            {label  =>'hallo'},
            {label  =>'selber hallo',
             unit   =>'mV'},
        ],
        axis           => [
            {
                unit        => 's',
                description => 'the time',
            },
            {
                unit        => 'eV',
                description => 'kinetic energy',
            },
        ],
    });

=head1 DESCRIPTION

This module maintains meta information on a dataset.
It's build on top of L<Lab::Data::XMLtree|Lab::Data::XMLtree>.

=head1 CONSTRUCTOR

=head2 new

    $meta=new Lab::Data::Meta(\%metainfo);

Currently, C<Lab::Data::Meta> supports the following bits of meta information:

    data_complete               => ['SCALAR'],  # boolean

    dataset_title               => ['SCALAR'],
    dataset_description         => ['SCALAR'],  # multiline
    sample                      => ['SCALAR'],
    data_file                   => ['SCALAR'],  # relativ zur descriptiondatei

    block                   => [
        'ARRAY',
        'id',
        {
            original_filename   => ['SCALAR'],  # nur von GPplus-Import unterstützt
            timestamp           => ['SCALAR'],  # Format %Y/%m/%d-%H:%M:%S
            description         => ['SCALAR'],
            label               => ['SCALAR'],
        }
    ],
    column                  => [
        'ARRAY',
        'id',
        {
            unit                => ['SCALAR'],
            label               => ['SCALAR'],  # evtl. weg
            description         => ['SCALAR'],  # evtl. weg
            min                 => ['SCALAR'],  # unnütz, aber von GPplus-Import unterstützt
            max                 => ['SCALAR'],  # dito
        }
    ],
    axis                    => [
        'ARRAY',
        'id',
        {
            label               => ['SCALAR'],
            unit                => ['SCALAR'],
            expression          => ['SCALAR'],
            min                 => ['SCALAR'],
            max                 => ['SCALAR'],
            description         => ['SCALAR'],  # evtl. weg
        }
    ],
    plot                    => [
        'HASH',
        'name',
        {
            type                => ['SCALAR'],  # line, pm3d
            xaxis               => ['SCALAR'],
            xformat             => ['SCALAR'],
            yaxis               => ['SCALAR'],
            yformat             => ['SCALAR'],
            zaxis               => ['SCALAR'],
            zformat             => ['SCALAR'],
            cbaxis              => ['SCALAR'],
            cbformat            => ['SCALAR'],
            logscale            => ['SCALAR'],  # z.b: 'x' oder 'yzxcb'
            time                => ['SCALAR'],  # ??? (was: wie oben (anders als in GnuPlot) (Achsen müssen %s-Format haben))
            grid                => ['SCALAR'],  # z.B. 'ytics' oder 'xtics ytics'
            palette             => ['SCALAR'],
            label               => [
                'ARRAY',
                'id',
                {
                    text        => ['SCALAR'],
                    x           => ['SCALAR'],
                    y           => ['SCALAR'],
                }
            ],
        }
    ],
    constant                => [
        'ARRAY',
        'id',
        {
            name                => ['SCALAR'],
            value               => ['SCALAR'],
        }
    ],

=head2 new_from_file

    $meta=new_from_file Lab::Data::Meta($filename);

=head1 METHODS

=head2 save

    $meta->save($filename);

=head2 get_abs_path

    my $path=get_abs_path();

=head1 AUTHOR/COPYRIGHT

Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>), 2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
