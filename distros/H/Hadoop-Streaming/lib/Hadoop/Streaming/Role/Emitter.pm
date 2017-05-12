package Hadoop::Streaming::Role::Emitter;
$Hadoop::Streaming::Role::Emitter::VERSION = '0.143060';
use Moo::Role;
use Params::Validate qw/validate_pos/;

#provides qw(run emit counter status);

# ABSTRACT: Role to provide emit, counter, and status interaction with Hadoop::Streaming.


sub emit {
    my ($self, $key, $value) = @_;
    eval {
        $self->put($key, $value);
    };
    if ($@) {
        warn $@;
    }
}


sub put 
{
    my ($self, $key, $value) = validate_pos(@_, 1, 1, 1);
    printf "%s\t%s\n", $key, $value;
}


sub counter
{
    my ( $self, %opts ) = @_;

    my $group   = $opts{group}   || 'group';
    my $counter = $opts{counter} || 'counter';
    my $amount  = $opts{amount}  || 'amount';

    my $msg
        = sprintf( "reporter:counter:%s,%s,%s\n", $group, $counter, $amount );
    print STDERR $msg;
}


sub status
{
    my ($self, $message ) = @_;

    my $msg = sprintf( "reporter:status:%s\n", $message);
    print STDERR $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::Streaming::Role::Emitter - Role to provide emit, counter, and status interaction with Hadoop::Streaming.

=head1 VERSION

version 0.143060

=head1 METHODS

=head2 emit

    $object->emit( $key, $value )

This method emits a key,value pair in the format expected by Hadoop::Streaming.
It does this by calling $self->put().  This catches errors from put and turns 
them into warnings.

=head2 put

    $object->put( $key, $value )

This method emits a key,value pair to STDOUT in the format expected by 
Hadoop::Streaming: ( key \t value \n )

=head2 counter

    $object->counter(
        group   => $group,
        counter => $countername,
        amount  => $count,
    );

This method emits a counter key to STDERR in the format expected by hadoop:
  reporter:counter:<group>,<counter>,<amount>

=head2 status

    $object->status( $message )

This method emits a status message to STDERR in the format expected by Hadoop::Streaming: 
  reporter:status:$message\n

=head1 AUTHORS

=over 4

=item *

andrew grangaard <spazm@cpan.org>

=item *

Naoya Ito <naoya@hatena.ne.jp>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Naoya Ito <naoya@hatena.ne.jp>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
