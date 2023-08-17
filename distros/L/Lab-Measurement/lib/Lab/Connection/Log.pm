package Lab::Connection::Log;
#ABSTRACT: Role adding logging capability to connections
$Lab::Connection::Log::VERSION = '3.881';
use v5.20;

use warnings;
use strict;

use Role::Tiny;

use YAML::XS;
use Data::Dumper;
use autodie;
use Carp;

use Lab::Connection::LogMethodCall qw(dump_method_call);

around 'new' => sub {
    my $orig  = shift;
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $twin  = undef;

    # getting fields and _permitted from parent class
    my $self = $class->$orig(@_);

    $self->_construct($class);

    # open the log file
    my $logfile = $self->logfile();
    if ( not defined $logfile ) {
        croak 'missing "logfile" parameter in connection';
    }

    # FIXME: Currently it's not possible to have a filehandle in %fields, as
    # this breaks the dclone used in Sweep.pm.
    open my $fh, '>', $self->logfile();
    close $fh;

    return $self;

};

sub dump_ref {
    my $self = shift;
    my $ref  = shift;
    open my $fh, '>>', $self->logfile();
    print {$fh} Dump($ref);
    close $fh;
}

for my $method (
    qw/Clear Write Read Query BrutalRead LongQuery BrutalQuery
    timeout block_connection unblock_connection is_blocked/
    ) {
    around $method => sub {
        my $orig   = shift;
        my $self   = shift;
        my $retval = $self->$orig(@_);

        # Inside the around modifier, we need to skip 2 levels to get to the
        # true caller.
        my $caller = caller(2);
        if ( $caller !~ /Lab::Connection.*/ ) {

            my $index = $self->log_index();

            my $log = dump_method_call( $index, $method, @_ );

            $log->{retval} = $retval;
            $self->dump_ref($log);

            $self->log_index( ++$index );
        }
        return $retval;
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Connection::Log - Role adding logging capability to connections

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
