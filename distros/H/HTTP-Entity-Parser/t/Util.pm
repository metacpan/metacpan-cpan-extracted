package t::Util;

use strict;
use warnings;
use base qw/Exporter/;
use IO::File qw//;
use Carp;

our @EXPORT = qw/slurp paml_loadfile build_env/;

sub slurp {
    my $file = shift;
    open my $fh, "<:unix", $file or die "$!";
    scalar do { local $/; <$fh> };
}

sub paml_loadfile {
    my ($path) = @_;

    my $data = do {

        my $io = IO::File->new($path, '<')
          || croak(qq[Couldn't open path '$path' in read mode: $!]);

        $io->binmode
          || croak(qq[Couldn't binmode filehandle: $!]);

        my $exp = -s $path;
        my $buf = do { local $/; <$io> };
        my $got = length $buf;

        $io->close
          || croak(qq[Couldn't close filehandle: $!]);

        ($exp == $got)
          || croak(qq[I/O read mismatch, expexted: $exp got: $got]);

        $buf;
    };

    if (substr($data, 0, 1) eq '{') {
        substr($data, 0, 0, '+');
    }

    my $struct = eval($data);

    (!$@)
      || croak(qq[LoadFile couldn't eval data: $@]);

    $struct;
}

sub build_env {
    my ($headers, $body_fh) = @_;
    my %env;
    foreach my $key ( keys %$headers ) {
        my $val = $headers->{$key};
        $key = uc $key;
        $key =~ s/-/_/g;
        if ($key !~ /^(?:CONTENT_LENGTH|CONTENT_TYPE)$/) {
            $key = "HTTP_" . $key;
        }
        $env{$key} = $val;
    }
    $env{'psgi.input'} = $body_fh;
    return \%env;
}

1;

