package Lab::Moose;
#ABSTRACT: Convenient loaders and constructors for L<Lab::Moose::Instrument>, L<Lab::Moose::DataFolder> and L<Lab::Moose::DataFile>
$Lab::Moose::VERSION = '3.600';
use warnings;
use strict;
use 5.010;

use MooseX::Params::Validate;

use Module::Load;
use Exporter 'import';
use Lab::Moose::Connection;
use Carp;


our @EXPORT = qw/instrument datafolder datafile/;


sub instrument {
    my (
        $instrument_type, $connection_type, $connection, $connection_options,
        $instrument_options
        )
        = validated_list(
        \@_,
        type            => { isa => 'Str' },
        connection_type => { isa => 'Str', optional => 1 },
        connection      => { isa => 'Lab::Moose::Connection', optional => 1 },
        connection_options => { isa => 'HashRef', optional => 1 },
        instrument_options => { isa => 'HashRef', default => {} },
        );

    $instrument_type = "Lab::Moose::Instrument::$instrument_type";
    load $instrument_type;

    if (   $connection && $connection_type
        || $connection && $connection_options ) {
        croak "give either 'connection' or 'connection_type' arguments";
    }

    if ($connection) {
        return $instrument_type->new(
            connection => $connection,
            %{$instrument_options}
        );
    }

    $connection_type = "Lab::Moose::Connection::$connection_type";

    load $connection_type;

    if ( not $connection_options ) {
        $connection_options = {};
    }

    $connection = $connection_type->new( %{$connection_options} );

    return $instrument_type->new(
        connection => $connection,
        %{$instrument_options}
    );

}


sub datafolder {
    load 'Lab::Moose::DataFolder';
    return Lab::Moose::DataFolder->new(@_);
}


sub datafile {
    my (%args) = validated_hash(
        \@_,
        type                           => { isa => 'Str' },
        MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1
    );

    my $type = delete $args{type};

    $type = "Lab::Moose::DataFile::$type";

    load $type;

    return $type->new(%args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose - Convenient loaders and constructors for L<Lab::Moose::Instrument>, L<Lab::Moose::DataFolder> and L<Lab::Moose::DataFile>

=head1 VERSION

version 3.600

=head1 SYNOPSIS

 use Lab::Moose;

 my $vna = instrument(
     type => 'RS_ZVA',
     connection_type => 'LinuxGPIB',
     connection_options => {timeout => 2}
 );
 
 my $folder = datafolder();
 my $file = datafile(
     type => 'Gnuplot3D',
     folder => $folder,
     filename => 'data.dat',
     columns => ['gate', 'bias', 'current'],
 );

 my $meta_file = datafile(
     type => 'Meta',
     folder => $folder,
     filename => 'file.yml'
 );

=head1 SUBROUTINES

=head2 instrument

Load an instrument driver module and call the constructor.

Create instrument with a new connection:

 my $instr = instrument(
     instrument_type => $type,
     instrument_options => {%instrument_options},
     connection_type => $connection_type,
     connection_options => {%connection_options},
 );

Create instrument with existing connection:

 my $instr = instrument(
     instrument_type => $type,
     connection => $connection_object,
     instrument_options => {%instrument_options},
 );

The C<instrument_options> hashref is optional in both cases.

=head2 datafolder

 my $folder = datafolder(%args);

Load L<Lab::Moose::DataFolder> and call it's C<new> method with C<%args>.

=head2 datafile

 my $file = datafile(type => $type, %args);

Load Lab::Moose::DataFile::C<$type> and call it's C<new> method with C<%args>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
