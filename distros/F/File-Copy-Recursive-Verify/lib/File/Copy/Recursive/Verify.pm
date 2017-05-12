package File::Copy::Recursive::Verify;
use strict;
use warnings;

our $VERSION = '0.1.0';

use Path::Tiny;
use Try::Tiny::Retry ':all';
use File::Copy::Verify qw(verify_copy);

use Class::Tiny qw(src_dir dst_dir),
  {
    tries              => 10,
    hash_algo          => 'MD5',
    src_hash           => {},
    dst_hash           => {},
  };

use parent 'Exporter';

our @EXPORT_OK = qw(verify_rcopy rcopy);

=encoding utf-8

=head1 NAME

File::Copy::Recursive::Verify - data-safe recursive copy

=head1 SYNOPSIS

    use File::Copy::Recursive::Verify qw(verify_rcopy);

    verify_rcopy($dir_a, $dir_b);

    #OOP equivalent

    File::Copy::Recursive::Verify->new(
        src_dir => $dir_a,
        dst_dir => $dir_b,
    )->copy();

    #some complex copy - I know SHA-256 hash of subdir/a.dat file
    #tree $dir_a:
    #.
    #├── c.dat
    #└── subdir
    #    ├── a.dat
    #    └── b.dat

    verify_rcopy($dir_a, $dir_b, {tries => 3, hash_algo => 'SHA-256', src_hash => {'subdir/a.dat' => '0'x64}});

    #OOP equivalent

    File::Copy::Recursive::Verify->new(
        src_dir => $dir_a,
        dst_dir => $dir_b,
        tries   => 3,
        hash_algo => 'SHA-256',
        src_hash => {'subdir/a.dat' => 0x64},
    )->copy();

=head1 DESCRIPTION

Use L<File::Copy::Verify> for recursive copy.

=head1 FUNCTIONS

=head2 verify_rcopy($src_dir, $dst_dir, $options)

functional api

Recusive copy of C<dir_a> to C<dir_b>.

Retry mechanism is via L<Try::Tiny::Retry> (Each file will try verify_copy 10 times with exponential backoff in default).

As verification digest are use fastest I<MD5> in default.

C<$options> is HashRef of L<attributes|/attributes>.

return I<HashRef> of copied files (key source, value destination)

=cut

sub verify_rcopy {
    my ($src_dir, $dst_dir, $options) = @_;

    return File::Copy::Recursive::Verify->new(
        src_dir => $src_dir,
        dst_dir => $dst_dir,
        %$options
    )->copy();
}

=head2 rcopy

alias of C<verify_rcopy>

=cut

sub rcopy;
*rcopy = \&verify_rcopy;

=head1 METHODS

=head2 new(%attributes)

=head3 %attributes

=head4 src_dir

source dir

=head4 src_hash

source I<HashRef> of path -> hash

=head4 dst_dir

destination dir

=head4 dst_hash

destination I<HashRef> of path -> hash

=head4 hash_algo

hash algorithm

default I<MD5>

=head4 tries

number of tries

more about retry - L<Try::Tiny::Retry>

=head2 copy;

start recursive copy 

return I<HashRef> of copied files (key source, value destination)

=cut

sub copy {
    my ($self) = @_;

    return path($self->src_dir)->visit(
        sub {
            my ($path, $copied) = @_;

            return if $path->is_dir();

            my $rel_src = $path->relative($self->src_dir);
            my $dst = path($self->dst_dir, $rel_src);
            $dst->parent->mkpath();
            my $rel_dst = $dst->relative($self->dst_dir);

            retry {
                File::Copy::Verify->new(
                    src       => $path,
                    src_hash  => $self->src_hash->{$rel_src->stringify()},
                    dst       => $dst,
                    dst_hash  => $self->dst_hash->{$rel_dst->stringify()},
                    hash_algo => $self->hash_algo
                )->copy();

                $copied->{$path} = $dst;
            }
            delay_exp { $self->tries, 1e5 }
            catch {
                die $_;
            };
        },
        { recurse => 1 }
    );
}

=head1 LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Jan Seidl E<lt>seidl@avast.comE<gt>

=cut

1;
