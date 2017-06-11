package Data::DTO::GELF;

# ABSTRACT: The DTO object for GELF version 1.1
our $VERSION = '1.3'; # VERSION 1.3
our $VERSION=1.3;
use strict;
use warnings;

use Moose;
use namespace::autoclean;

use JSON::Tiny qw(encode_json);
use Sys::Hostname;
use Data::UUID;
use POSIX qw(strftime);

use Data::DTO::GELF::Types qw( LogLevel );

our $GELF_VERSION = 1.1;

has 'version' => (
    is      => 'ro',
    isa     => 'Str',
    builder => '_build_version',
);

has 'host' => (
    is      => 'rw',
    isa     => 'Str',
    builder => '_build_host',
);

has 'short_message' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    builder => '_long_to_short'
);

has 'full_message' => (
    is  => 'rw',
    isa => 'Str',
);

has 'timestamp' => (
    is      => 'ro',
    isa     => 'Int',
    builder => '_build_timestamp',
);

has 'level' => (
    is     => 'ro',
    isa    => LogLevel,
    coerce => 1,
);
has 'facility' => (
    is  => 'rw',
    isa => 'Str',
);

has 'line' => (
    is  => 'rw',
    isa => 'Int',
);

has 'file' => (
    is  => 'rw',
    isa => 'Str',
);

sub BUILD {
    my $self = shift;
    my $args = shift;
    foreach my $key1 ( keys $args ) {
        if ( ( substr $key1, 0, 1 ) eq "_" ) {
            $self->meta->add_attribute( "$key1" => ( accessor => $key1 ) );
            $self->meta->get_attribute($key1)
                ->set_value( $self, $args->{$key1} );
        }
    }

    my ($package,   $filename, $line,       $subroutine, $hasargs,
        $wantarray, $evaltext, $is_require, $hints,      $bitmask
    ) = caller($Log::Log4perl::caller_depth);
    $self->line($line);
    $self->file($filename);
    $self->facility($package);
}

sub _build_version {
    my $self = shift;
    return $GELF_VERSION;
}

sub _build_host {
    my $self = shift;
    return hostname();
}

sub _build_timestamp {
    my $self = shift;
    return time();
}

sub message {
    my $self = shift;
    my $m    = shift;
    if ( defined $m ) {
        $self->full_message($m);
    }
    else {
        return $self->full_message();
    }

    return;
}

sub _long_to_short {
    my $self = shift;
    return substr $self->full_message(), 0, 50;
}

sub TO_JSON {
    my $self = shift;
    { $self->short_message() }    #fire off lazy message builder
    return {%$self};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::DTO::GELF - The DTO object for GELF version 1.1

=head1 VERSION

version 1.3

=head1 AUTHOR

Brandon "Dimentox Travanti" Husbands <xotmid@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Brandon "Dimentox Travanti" Husbands.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
