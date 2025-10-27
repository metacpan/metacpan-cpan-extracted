# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::Chunk;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::Base';

use Carp;
use Fcntl qw(SEEK_SET);

our $VERSION = v0.15;

my %_properties = (
    chunk_cachehash     => {},
    chunk_subchunks     => {rawtype => __PACKAGE__},
    chunk_outer_type    => {},
    chunk_inner_type    => {},
    chunk_outer_size    => {},
    chunk_inner_size    => {},
    chunk_outer_magic   => {},
);


sub peek {
    my ($self, %opts) = @_;
    my $wanted = $opts{wanted} || 0;
    my $required = $opts{required} || 0;
    my $buffer;

    if (defined($self->{_peek_buffer}) && length($self->{_peek_buffer}) >= $required) {
        return $self->{_peek_buffer};
    }

    croak 'Cannot peek as no offset and size is known' unless defined($self->{inner_start}) && defined($self->{inner_size});

    $wanted = $required if $required > $wanted;
    $wanted = 4096 if $wanted < 4096; # enforce some minimum

    croak 'Requested peek too big: '.$wanted if $wanted > 65536;

    $wanted = $self->{inner_size} if $wanted > $self->{inner_size};

    {
        my $fh = $self->{inode}->_get_fh;
        $fh->seek($self->{inner_start}, SEEK_SET) or die $!;
        $fh->read($buffer, $wanted);
    }

    croak 'Cannot peek required amount of data' if length($buffer) < $required;

    return $self->{_peek_buffer} = $buffer;
}
# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts, properties => \%_properties);

    # Complete...
    $self->{lifecycle}  //= 'current';
    $self->{end}        //= $self->{start} + $self->{size};
    $self->{size}       //= $self->{end}   - $self->{start};

    if (defined($self->{inner_start}) && (defined($self->{inner_end}) || defined($self->{inner_end}))) {
        $self->{inner_end}        //= $self->{inner_start} + $self->{inner_size};
        $self->{inner_size}       //= $self->{inner_end}   - $self->{inner_start}
    }

    {
        my $pv = ($self->{properties_values} //= {})->{$self->{lifecycle}} //= {};
        my $inode = $self->{inode};

        $pv->{chunk_outer_size}  = {raw => $self->{size}};
        $pv->{chunk_inner_size}  = {raw => $self->{inner_size}};

        $pv->{chunk_subchunks}   = [map {{raw => $_}} @{$self->{subchunks}}] if defined $self->{subchunks};
        $pv->{chunk_inner_type}  = $self->{inner_type}  if defined $self->{inner_type};
        $pv->{chunk_outer_type}  = $self->{outer_type}  if defined $self->{outer_type};
        $pv->{chunk_outer_magic} = $self->{outer_magic} if defined $self->{outer_magic};

        if (defined $inode) {
            eval { $pv->{chunk_cachehash} = {raw => sprintf('%u-%u@%s', $self->{start}, $self->{end}, $inode->get('stat_cachehash'))} };
        }
    }

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::Chunk - generic module for extracting information from filesystems

=head1 VERSION

version v0.15

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Inode $inode = ...;

    my File::Information::Chunk $chunk = $inode->get(...);

This package inherits from L<File::Information::VerifyBase>.

=head1 METHODS

=head2 peek

    my $data = $chunk->peek( [ %opts ] );

Peeks the first few bytes of a chunk's body.
This implements the same interface as L<File::Information::Inode/peek>.
See there for details.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
