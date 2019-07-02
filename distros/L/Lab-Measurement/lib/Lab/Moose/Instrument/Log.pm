package Lab::Moose::Instrument::Log;
$Lab::Moose::Instrument::Log::VERSION = '3.682';
#ABSTRACT: Role for Lab::Moose::Instrument connection logging.

use Moose::Role;
use Carp;
use namespace::autoclean;
use YAML::XS;
use IO::Handle;

has log_file => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_log_file',
);

has log_fh => (
    is        => 'ro',
    isa       => 'FileHandle',
    builder   => 'log_build_fh',
    predicate => 'has_log_fh',
    lazy      => 1,
);

has log_id => (
    is      => 'ro',
    isa     => 'Int',
    writer  => '_log_id',
    default => 0,
);


my @wrapped_methods = qw/binary_read write binary_query clear/;
requires(@wrapped_methods);

sub log_build_fh {
    my $self = shift;
    my $file = $self->log_file();
    open my $fh, '>', $file
        or croak "cannot open logfile '$file': $!";
    $fh->autoflush();
    return $fh;
}

sub _log_retval {
    my ( $arg_ref, $retval ) = @_;

    if ( $retval !~ /[^[:ascii:]]/ ) {
        $arg_ref->{retval} = $retval;
    }
    else {
        $arg_ref->{retval_enc} = 'hex';
        $arg_ref->{retval} = unpack( 'H*', $retval );
    }
}

for my $method (@wrapped_methods) {
    around $method => sub {
        my $orig   = shift;
        my $self   = shift;
        my @params = @_;

        if ( !( $self->has_log_fh() || $self->has_log_file() ) ) {
            return $self->$orig(@params);
        }

        my %arg;
        if ( ref $params[0] eq 'HASH' ) {
            %arg = %{ $params[0] };
        }
        else {
            %arg = @params;
        }

        my $retval = $self->$orig(@params);

        if ( $method =~ /read|query/ ) {
            _log_retval( \%arg, $retval );
        }

        my %methods = (
            binary_read  => 'Read',
            write        => 'Write',
            binary_query => 'Query',
            clear        => 'Clear',
        );

        $arg{method} = $methods{$method};

        my $id = $self->log_id();
        $arg{id} = $id;
        $self->_log_id( ++$id );

        my $fh = $self->log_fh();
        print {$fh} Dump( \%arg );

        return $retval;
        }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Instrument::Log - Role for Lab::Moose::Instrument connection logging.

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose 'instrument';
 my $instr = instrument(
     type => '...',
     connection_type => '...',
     connection_options => {...},
     # write into newly created logfile:
     log_file => '/tmp/instr.log',
     # alternative: write into filehandle:
     log_fh => $filehandle,
 );

=head1 DESCRIPTION

Log all of the instrument's C<read, write, query, clear> function calls into a
logfile or an existing filehandle.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
