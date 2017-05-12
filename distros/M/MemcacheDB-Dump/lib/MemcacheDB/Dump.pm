package MemcacheDB::Dump;
use strict;
use warnings;

use Carp;
use BerkeleyDB;

our $VERSION = "0.04";

sub new {
    my ($class, $path) = @_;
    tie my %bdb, "BerkeleyDB::Btree",
    -Filename   => $path,
    -Flags      => DB_RDONLY or carp "open $path failed";

    bless { bdb => \%bdb }, $class;
}

sub DESTROY {
    my $self = shift;
    untie %{ $self->{bdb} };
}

sub run {
    my ($self) = @_;
    my %ret;
    while ( my ($key, $val) = each %{ $self->{bdb} } ) {
        $ret{$key} = getBody($val);
    }
    \%ret;
}

sub keys {
    my ($self) = @_;
    keys %{ $self->{bdb} };
}

sub get {
    my ($self, $key) = @_;
    exists $self->{bdb}->{$key} or return;
    getBody($self->{bdb}->{$key});
}

sub getBody {
    my ($val) = @_;
    itemBody(itemDecode($val));
}

# MemcacheDB is just fread an item struct below.
# https://code.google.com/p/memcachedb/source/browse/branches/memcachedb-1.2.0/memcachedb.h#179
#XXX this is NOT sane way to extract C struct. because your C compiler may put other padding bytes for the alignment.
sub itemDecode {
    my ($val) = @_;
    my ($nBytes, $nSuffix, $nKey, $padA, $padB, @body) = unpack("LC4C*", $val);
    {
        nBytes  => $nBytes,
        nSuffix => $nSuffix,
        nKey    => $nKey,
        body    => \@body,
    };
}

sub itemBody {
    my ($item) = @_;
    my $offset = $item->{nKey} + $item->{nSuffix} + 1;
    my $length = $item->{nBytes} - 1 - 2; # -2 for remove \r\n padding
    pack "C*", @{ $item->{body} }[ $offset .. $offset+$length ];
}

sub _pp {
    my ($bin) = @_; 
    my @list = unpack("C*", $bin);
    join "", map { ($_ >= 32 && $_ <= 126) ? chr($_) : sprintf("\\x%02X", $_) } @list;
}

1;
__END__

=encoding utf-8

=head1 NAME

MemcacheDB::Dump - It's new $module

=head1 SYNOPSIS

    use MemcacheDB::Dump;

    my $dumper = MemcacheDB::Dump->new('/path/to/db/file');

    my $hashref = $dumper->run;

    my $value = $dumper->get('some key');

    my @keys = $dumper->keys;


=head1 DESCRIPTION

MemcacheDB (http://memcachedb.org/) is a KVS designed for persistent.
MemcacheDB::Dump is dumper for MemcacheDB's backend strage file.

=head1 LICENSE

Copyright (C) ajiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

ajiyoshi E<lt>yoichi@ajiyoshi.orgE<gt>

=cut

