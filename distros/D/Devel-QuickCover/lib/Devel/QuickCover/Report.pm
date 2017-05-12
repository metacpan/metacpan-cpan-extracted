package Devel::QuickCover::Report;

use strict;
use warnings;

use JSON::XS    qw(encode_json   decode_json);
use Sereal      qw(encode_sereal decode_sereal);
use Path::Tiny  qw(path);

sub new {
    my ($class) = @_;
    my $self = bless {
        data    => {
            files       => {},
            subs        => {},
            metadata    => {},
        },
        changes => 0,
    }, $class;

    return $self;
}

sub load {
    my ($self, $file) = @_;

    my $data = path($file)->slurp_raw;
    my $decoded = Sereal::decode_sereal($data);

    if (exists $decoded->{files}) {
        $self->{data} = $decoded;
    } else {
        $self->{data} = {
            files       => $decoded,
            metadata    => {},
        };
    }
    $self->{changes} = 0;
}

sub save {
    my ($self, $file) = @_;

    my $encoded = Sereal::encode_sereal($self->{data});
    path($file)->spew_raw($encoded);
    $self->{changes} = 0;
}

sub merge {
    my ($self, $file) = @_;

    my $json = path($file)->slurp;
    my $decoded = decode_json($json);
    my $files = $self->{data}{files};
    my $subs = $self->{data}{subs};

    # I don't think custom merging functions are needed
    @{$self->{data}{metadata}}{keys %{$decoded->{metadata}}} =
        values %{$decoded->{metadata}};

    for my $name (keys %{$decoded->{files}}) {
        my $coverage = $decoded->{files}{$name};
        for my $line (@{$coverage->{covered}}) {
            $files->{$name}->{$line}++;
        }
        for my $line (@{$coverage->{present}}) {
            $files->{$name}->{$line} //= 0;
        }
        for my $sub (keys %{$coverage->{subs}}) {
            $subs->{$name}->{$sub} ||= $coverage->{subs}->{$sub};
        }
        $self->{changes} += @{$coverage->{covered}};
    }
}

sub metadata {
    my ($self) = @_;

    return $self->{data}{metadata};
}

sub coverage {
    my ($self) = @_;

    return $self->{data}{files};
}

sub subs {
    my ($self) = @_;

    return $self->{data}{subs};
}

sub filenames {
    my ($self) = @_;

    return [keys %{$self->{data}{files}}];
}

sub changes {
    my ($self) = @_;

    return $self->{changes};
}

1;
