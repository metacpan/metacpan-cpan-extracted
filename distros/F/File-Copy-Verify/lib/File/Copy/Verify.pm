package File::Copy::Verify;
use strict;
use warnings;

our $VERSION = '0.1.4';

use Path::Tiny;
use Safe::Isa;
use Class::Tiny qw(src dst src_hash dst_hash), {
    hash_algo    => 'MD5',
    keep_invalid => 0,
};

use parent 'Exporter';
our @EXPORT_OK = qw(verify_copy copy cp verify_move move mv);

=head1 NAME

File::Copy::Verify - data-safe copy

=head1 SYNOPSIS

    use File::Copy::Verify qw(verify_copy);
    use Try::Tiny::Retry;

    retry {
        verify_copy('a', 'b'); #or copy or cp - all variants are exportable
    };

    #OOP equivalent:

    $verify_copy = File::Copy::Verify->new(
        src => 'a',
        dst => 'b',
    );
    retry {
        $verify_copy->copy();
    };


    #I know source SHA-256 hash and I can use for validation
    
    retry {
        File::Copy::Verify::copy('a', 'b', {src_hash => '0'x64, hash_algo => 'SHA-256'});
    };

    #OOP equivalent
    
    $verify_copy = File::Copy::Verify->new(
        src       => 'a',
        src_hash  => '0' x 64,
        dst       => 'b',
        hash_algo => 'SHA-256',
    );
    retry {
        $verify_copy->copy();
    };

=head1 DESCRIPTION

This module calculates hash before and after copying and if the hash doesn't match, then dies. I recommend Try::Tiny::Retry module for copy retry mechanism.
This module is useful for network storages/filesystems, but it is harmful for local storages/filesystems because of overhead. The `verified_copy` function is at least 3 times slower then standard `copy`!

File::Copy::Verify is module for verifying copy. Some storages (in particular net storages) can have troubles with valid copy and C<copy> function from L<File::Copy> doesn't find this problems (like random buffers in copied file).

This module calculates hash before and after copying and if hash doesn't match, then dies. I recommend L<Try::Tiny::Retry> module for copy retry mechanism.

This module is useful for network storages/filesystems, but it is harmful for localstorages/filesystems because of overhead. The C<verify_copy>function is at least 3 times slower then standard C<copy>!

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 src

source path

=head4 dst

destination path

=head4 hash_algo

digest alghoritm used for check

default is fast I<MD5>

more about L<Digest>

=head4 src_hash

manualy set source hash

this is usefully if I know source hash (doesn't calculate again)

=head4 dst_hash

manualy set destination hash

this is usefully if I know destination hash (doesn't calculate again)

=head4 keep_invalid

If is file invalid (means hash-check failed), C<dst> is removed.

This decreases potentional problems with bad-copied files.

If you need keep this bad file anyway. Or for debugging. Use this option.

=cut

sub BUILD {
    my ($self) = @_;

    #coerce src and dst to Path::Tiny object
    if (!$self->src->$_isa('Path::Tiny')) {
        $self->src(path($self->src));
    }

    if (!$self->dst->$_isa('Path::Tiny')) {
        $self->dst(path($self->dst));
    }
}

=head2 copy()

=cut

sub copy {
    my ($self) = @_;

    if (!$self->$_isa(__PACKAGE__)) {
        my ($src, $dst, $options) = @_;

        return __PACKAGE__->new(
            src => $src,
            dst => $dst,
            %$options
        )->copy();
    }

    if (!defined $self->src_hash) {
        $self->src_hash(
            $self->src->digest($self->hash_algo)
        );
    }

    my $dst = $self->src->copy($self->dst);

    if (!defined $self->dst_hash) {
        $self->dst_hash(
            $dst->digest($self->hash_algo)
        );
    }

    if ( uc $self->src_hash ne uc $self->dst_hash ) {
        if (!$self->keep_invalid) {
            $dst->remove();
        }

        die sprintf "Src (%s) hash (%s) and dst (%s) hash (%s) isn't equal",
          $self->src,
          $self->src_hash,
          $dst,
          $self->dst_hash;
    }
}

=head2 move()

=cut
sub move {
    my ($self) = @_;

    if (!$self->$_isa(__PACKAGE__)) {
        my ($src, $dst, $options) = @_;

        return __PACKAGE__->new(
            src => $src,
            dst => $dst,
            %$options
        )->move();
    }

    $self->copy();
    $self->src->remove();
}

=head1 FUNCTIONS

=head2 verify_copy($src, $dst, $options)

C<$options> - same parameters (except C<src> and C<dst>) like in constructor L<new|/new-attributes>

=cut

sub verify_copy;
*verify_copy = \&copy;

=head2 copy

alias for L<verify_copy|/verify_copy-src-dst-options>

=head2 cp

alias for L<verify_copy|/verify_copy-src-dst-options>

=cut

sub cp;
*cp = \&copy;

=head2 verify_move($src, $dst, $options)

same as L<verify_copy|/verify_copy-src-dst-options> and after success copy remove source C<$src> file

=cut

sub verify_move;
*verify_move = \&move;

=head2 move

alias for L<verify_move|/verify_move-src-dst-options>

=head2 mv

alias for L<verify_move|/verify_move-src-dst-options>

=cut

sub mv;
*mv = \&move;

=head1 SEE ALSO

L<File::Copy::Vigilant> - Looks really good, don't support other digests - only MD5, don't support hard-set src or dst hash. Support retry mechanism by default.

L<File::Copy::Reliable> - only "checks that the file size of the copied or moved file is the same as the source".

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
