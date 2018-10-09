package Log::Any::Adapter::Duperr;

#
# Cunning adapter for logging to a duplicate of STDERR
#

use 5.008001;
use strict;
use warnings;
use utf8::all;

use Carp;
use Log::Any::Adapter::Util ();

use base qw/Log::Any::Adapter::Base/;

our $VERSION = '0.04';

sub init {
    my ($self) = @_;

    # Duplicate STDERR
    open( $self->{fh}, '>&', STDERR ) or croak "Can't dup STDERR: $!";    ## no critic [InputOutput::RequireBriefOpen]

    if ( exists $self->{log_level} ) {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level( $self->{log_level} )
            unless $self->{log_level} =~ /^\d+$/x;
    }
    else {
        $self->{log_level} = Log::Any::Adapter::Util::numeric_level('trace');
    }

    return;
}

foreach my $method ( Log::Any::Adapter::Util::logging_methods() ) {
    no strict 'refs';    ## no critic (ProhibitNoStrict)

    my $method_level = Log::Any::Adapter::Util::numeric_level($method);

    *{$method} = sub {
        my ( $self, $text ) = @_;

        return if $method_level > $self->{log_level};

        $self->{fh}->print("$text\n");
    };
}

foreach my $method ( Log::Any::Adapter::Util::detection_methods() ) {
    no strict 'refs';    ## no critic (ProhibitNoStrict)

    my $base = substr( $method, 3 );

    my $method_level = Log::Any::Adapter::Util::numeric_level($base);

    *{$method} = sub {
        return !!( $method_level <= $_[0]->{log_level} );
    };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Any::Adapter::Duperr - Cunning adapter for logging to a duplicate of STDERR


=head1 SYNOPSIS

    use Log::Any::Adapter ('Duperr');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('Duperr');
     
    # with minimum level 'warn'
     
    use Log::Any::Adapter ('Duperr', log_level => 'warn' );

    # and later

    open(STDERR, ">/dev/null");


=head1 DESCRIPTION

Adapter Duperr are intended to log messages into duplicate of standard
descriptor STDERR.

Logging into a duplicate of standard descriptor might be needed in special
occasions when you need to redefine or even close standard descriptor but you
want to continue displaying messages wherever they are displayed by a standard
descriptor. See more L<Log::Any::Adapter::Dupstd|Log::Any::Adapter::Dupstd>.

These adapters work similarly to ordinary adapters from distributive Log::Any - 
L<Stderr|Log::Any::Adapter::Stderr> (save that inside are used descriptor
duplicate)


=head1 SEE ALSO

L<Log::Any|Log::Any>, L<Log::Any::Adapter|Log::Any::Adapter>, L<Log::Any::For::Std|Log::Any::For::Std>

=head1 AUTHORS

=over 4

=item *

Mikhail Ivanov <m.ivanych@gmail.com>

=item *

Anastasia Zherebtsova <zherebtsova@gmail.com> - translation of documentation
into English

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Mikhail Ivanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
