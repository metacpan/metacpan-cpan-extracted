=head1 NAME

File::OSS::Scan::Cache - simple wrapper on L<Cache::FileCache>

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    use File::OSS::Scan::Cache;

    File::OSS::Scan::Cache->init($base_dir);

    File::OSS::Scan::Cache->set( $file_path => $h_file );
    my $cached_file = File::OSS::Scan::Cache->get($file_path);

    File::OSS::Scan::Cache->clear();

=head1 DESCRIPTION

This is an internal module used by L<File::OSS::Scan> to cache scan results into
files, and should not be called directly.

=head1 SEE ALSO

=over 4

=item * L<File::OSS::Scan>

=back

=head1 AUTHOR

Harry Wang <harry.wang@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Harry Wang.

This is free software, licensed under:

    Artistic License 1.0

=cut

package File::OSS::Scan::Cache;

use strict;
use warnings FATAL => 'all';

use Fatal qw( open close );
use Carp;
use English qw( -no_match_vars );
use Data::Dumper; # for debug
use Cache::FileCache;

use File::OSS::Scan::Constant qw(:all);

our $VERSION = '0.04';

our $cache = undef;

sub init {
    my $self = shift;
    my $dir  = shift || return SUCCESS;

    my $hash = {
        'namespace'             => $dir,
        'default_expires_in'    => 'never',
    };

    $cache = new Cache::FileCache($hash);

    return SUCCESS;
}

sub get {
    my ( $self, $key ) = @_;
    my $val  = undef;

    ( defined $cache ) &&
        ( $val = $cache->get($key) );

    return $val;
}

sub set {
    my ( $self, $key, $val ) = @_;

    ( defined $cache ) &&
        ( $cache->set($key, $val) );

    return SUCCESS;
}

sub clear {
    my $self = shift;

    ( defined $cache ) &&
        ( $cache->clear() );

    return SUCCESS;
}

sub clear_all {
    my $self = shift;

    my $pseudo_cache = new Cache::FileCache();
    $pseudo_cache->Clear();

    return SUCCESS;
}



1;
