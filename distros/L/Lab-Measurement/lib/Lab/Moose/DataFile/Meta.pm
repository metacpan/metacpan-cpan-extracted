package Lab::Moose::DataFile::Meta;
#ABSTRACT: YAML Metadata file
$Lab::Moose::DataFile::Meta::VERSION = '3.682';
use 5.010;
use warnings;
use strict;

use Moose;
use MooseX::Params::Validate;

use Carp;

use Time::HiRes qw/gettimeofday tv_interval/;
use YAML::XS;
use Fcntl 'SEEK_SET';

use namespace::autoclean;


extends 'Lab::Moose::DataFile';

has mode => (
    is       => 'ro',
    default  => '>>',
    init_arg => undef
);

has meta_data => (
    is       => 'ro',
    isa      => 'ArrayRef | HashRef',
    writer   => '_meta_data',
    init_arg => undef
);

has start_time => (
    is       => 'ro',
    isa      => 'ArrayRef[Int]',
    init_arg => undef,
    writer   => '_start_time'
);

sub log {
    my $self = shift;
    my ($meta)
        = validated_list( \@_, meta => { isa => 'ArrayRef | HashRef' } );

    my $existing_meta = $self->meta_data();
    if ( defined $existing_meta ) {
        my $meta_type          = ref $meta;
        my $existing_meta_type = ref $existing_meta;

        if ( $meta_type ne $existing_meta_type ) {
            croak "meta has reftype $meta_type "
                . "while existing meta has reftype $existing_meta_type";
        }

        if ( $meta_type eq 'ARRAY' ) {
            $existing_meta = [ @{$existing_meta}, @{$meta} ];
        }
        else {
            $existing_meta = { %{$existing_meta}, %{$meta} };
        }

        $self->_meta_data($existing_meta);
    }
    else {
        $self->_meta_data($meta);
    }

    my $fh = $self->filehandle();

    truncate $fh, 0
        or croak "truncate failed: $!";
    seek $fh, 0, SEEK_SET
        or croak "seek failed: $!";

    print {$fh} Dump( $self->meta_data );
}

__PACKAGE__->meta->make_immutable();


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::DataFile::Meta - YAML Metadata file

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 my $file = Lab::Moose::DataFile::Meta->new(
     folder => $folder,
     filename => 'metafile.yml'
 );

 $file->log(meta => {key1 => $value1, key2 => $value2});

=head1 METHODS

=head2 log

Log either an hashref or an arrayref to the log file.
Augment the file's contents. The new keys/items will be merged with the
existing ones. Rewrites the file with the new contents.
You may not mixup calls with hashref and arrayref arguments.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
