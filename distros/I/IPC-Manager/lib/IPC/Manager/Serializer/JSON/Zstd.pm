package IPC::Manager::Serializer::JSON::Zstd;
use strict;
use warnings;

our $VERSION = '0.000035';

use parent 'IPC::Manager::Serializer::JSON';

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

use Object::HashBase qw{
    <level
    <dictionary
    +cctx
    +dctx
    +cdict
    +ddict
};

use constant DEFAULT_LEVEL => 3;

my $HAVE_ZSTD;

sub _have_zstd {
    return $HAVE_ZSTD if defined $HAVE_ZSTD;
    return $HAVE_ZSTD = eval { require Compress::Zstd; Compress::Zstd->VERSION('0.20'); 1 } ? 1 : 0;
}

sub viable { _have_zstd() }

sub init {
    my $self = shift;

    croak "Compress::Zstd 0.20 or newer is required for IPC::Manager::Serializer::JSON::Zstd"
        unless _have_zstd();

    $self->{+LEVEL} //= DEFAULT_LEVEL;

    if (defined $self->{+DICTIONARY}) {
        require Compress::Zstd::CompressionContext;
        require Compress::Zstd::DecompressionContext;
        require Compress::Zstd::CompressionDictionary;
        require Compress::Zstd::DecompressionDictionary;

        $self->{+CDICT} = Compress::Zstd::CompressionDictionary->new_from_file($self->{+DICTIONARY}, $self->{+LEVEL})
            or croak "Could not load zstd compression dictionary from '$self->{+DICTIONARY}'";
        $self->{+DDICT} = Compress::Zstd::DecompressionDictionary->new_from_file($self->{+DICTIONARY})
            or croak "Could not load zstd decompression dictionary from '$self->{+DICTIONARY}'";
        $self->{+CCTX} = Compress::Zstd::CompressionContext->new;
        $self->{+DCTX} = Compress::Zstd::DecompressionContext->new;
    }

    return $self;
}

sub serialize {
    my ($invocant, $obj) = @_;

    croak "Compress::Zstd 0.20 or newer is required for IPC::Manager::Serializer::JSON::Zstd"
        unless _have_zstd();

    my $json = $invocant->SUPER::serialize($obj);

    if (blessed $invocant) {
        if ($invocant->{+CCTX}) {
            my $bytes = $invocant->{+CCTX}->compress_using_dict($json, $invocant->{+CDICT});
            croak "Failed to compress payload with zstd dictionary" unless defined $bytes;
            return $bytes;
        }
        my $bytes = Compress::Zstd::compress($json, $invocant->{+LEVEL});
        croak "Failed to compress payload with zstd" unless defined $bytes;
        return $bytes;
    }

    my $bytes = Compress::Zstd::compress($json, DEFAULT_LEVEL);
    croak "Failed to compress payload with zstd" unless defined $bytes;
    return $bytes;
}

sub deserialize {
    my ($invocant, $bytes) = @_;

    croak "Compress::Zstd 0.20 or newer is required for IPC::Manager::Serializer::JSON::Zstd"
        unless _have_zstd();

    my $json;
    if (blessed($invocant) && $invocant->{+DCTX}) {
        $json = $invocant->{+DCTX}->decompress_using_dict($bytes, $invocant->{+DDICT});
    }
    else {
        $json = Compress::Zstd::decompress($bytes);
    }

    croak "Failed to decompress zstd payload" unless defined $json;

    return $invocant->SUPER::deserialize($json);
}

sub TO_JSON {
    my $self = shift;
    my @args;
    push @args, level      => $self->{+LEVEL}      if defined $self->{+LEVEL}      && $self->{+LEVEL} != DEFAULT_LEVEL;
    push @args, dictionary => $self->{+DICTIONARY} if defined $self->{+DICTIONARY};
    return [ref($self), @args];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IPC::Manager::Serializer::JSON::Zstd - JSON serializer with zstd compression for IPC::Manager.

=head1 DESCRIPTION

Subclass of L<IPC::Manager::Serializer::JSON> that compresses serialized
payloads with L<Compress::Zstd> before sending them and decompresses them on
receipt. JSON encoding/decoding is delegated to the parent class; only the
on-the-wire bytes are different.

When L<Compress::Zstd> 0.20 or newer is installed C<JSON::Zstd> is selected as
the default serializer for L<IPC::Manager>. If C<Compress::Zstd> is missing or
older, IPC::Manager falls back to L<IPC::Manager::Serializer::JSON>.

The class methods C<serialize>/C<deserialize> use C<Compress::Zstd>'s default
compression level (3) and no preset dictionary. To configure a custom
compression level or use a preset dictionary, construct an instance via
C<new(level =E<gt> $level, dictionary =E<gt> $path)> and call the same methods
on it. Instances are cached by L<IPC::Manager> when specified through the
arrayref form in C<ipcm_spawn> / C<ipcm_connect>, so each unique
C<[$class, %args]> spec produces a single shared serializer object that
peer connections reuse.

=head1 SYNOPSIS

    use IPC::Manager;

    # Class form (default level, no dictionary)
    my $ipcm = ipcm_spawn(serializer => 'JSON::Zstd');

    # Arrayref form (custom level and/or dictionary)
    my $ipcm = ipcm_spawn(
        serializer => ['JSON::Zstd', level => 9, dictionary => '/path/to/dict'],
    );

=head1 METHODS

=over 4

=item $bool = IPC::Manager::Serializer::JSON::Zstd->viable

Returns true when L<Compress::Zstd> 0.20 or newer is loadable, false
otherwise.

=item $self = IPC::Manager::Serializer::JSON::Zstd->new(%args)

Construct a configured serializer instance. Recognized arguments:

=over 4

=item level => $integer

Zstd compression level. Defaults to C<3> (Compress::Zstd's library default).

=item dictionary => $path

Path to a zstd preset dictionary file. Both endpoints must have access to a
dictionary at the same path with the same content. When set, the constructor
loads the file once and reuses it for every C<serialize>/C<deserialize> call.

=back

=item $bytes = $serializer->serialize($obj)

=item $bytes = IPC::Manager::Serializer::JSON::Zstd->serialize($obj)

JSON-encode C<$obj> and zstd-compress the result. The class form uses default
level 3 and no dictionary; the instance form honours the C<level> and
C<dictionary> the instance was built with.

=item $obj = $serializer->deserialize($bytes)

=item $obj = IPC::Manager::Serializer::JSON::Zstd->deserialize($bytes)

Zstd-decompress C<$bytes> and JSON-decode the result. The class form expects
input produced without a dictionary; the instance form decodes with the
instance's dictionary if one was configured.

=back

=head1 SOURCE

The source code repository for IPC::Manager can be found at
L<https://github.com/exodist/IPC-Manager>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
