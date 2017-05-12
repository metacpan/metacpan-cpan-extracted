package Hadoop::Streaming::Reducer::Input;
$Hadoop::Streaming::Reducer::Input::VERSION = '0.143060';
use Moo;
use Hadoop::Streaming::Reducer::Input::Iterator;

#ABSTRACT: Parse input stream for reducer

has handle => (
    is       => 'ro',
    does     => 'FileHandle',
    required => 1,
);

has buffer => (
    is   => 'rw',
);


sub next_key
{
    my $self = shift;
    my $line = $self->buffer ? $self->buffer : $self->next_line;
    return if not defined $line;
    my ( $key, $value ) = split /\t/, $line, 2;
    return $key;
}


sub next_line {
    my $self = shift;
    return if $self->handle->eof;
    $self->buffer( $self->handle->getline );
    $self->buffer;
}


sub getline {
    my $self = shift;
    if (defined $self->buffer) {
        my $buf = $self->buffer;
        $self->buffer(undef);
        return $buf;
    } else {
        return $self->next_line;
    }
}


sub iterator {
    my $self = shift;
    Hadoop::Streaming::Reducer::Input::Iterator->new( input => $self );
}


sub each
{
    my $self = shift;
    my $line = $self->getline or return;
    chomp $line;
    split /\t/, $line, 2;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hadoop::Streaming::Reducer::Input - Parse input stream for reducer

=head1 VERSION

version 0.143060

=head1 METHODS

=head2 next_key 

    $Input->next_key();

Parses the next line into key/value (splits on tab) and returns the key portion.

Returns undef if there is no next line.

=head2 next_line

    $Input->next_line();

Reads the next line into buffer and returns it.

Returns undef if there are no more lines (end of file).

=head2 getline

    $Input->getline();

Returns the next available line. Clears the internal line buffer if set.

=head2 iterator

    $Input->iterator();

Returns a new Hadoop::Streaming::Reducer::Input::Iterator for this object.

=head2 each

    $Input->each();

Grabs the next line and splits on tabs.  Returns an array containing the output of the split.

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
