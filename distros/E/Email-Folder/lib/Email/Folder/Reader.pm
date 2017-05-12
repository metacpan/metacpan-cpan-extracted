use strict;
use warnings;
package Email::Folder::Reader;
{
  $Email::Folder::Reader::VERSION = '0.860';
}
# ABSTRACT: reads raw RFC822 mails from a box

use Carp;


sub new {
    my $class = shift;
    my $file  = shift || croak "You must pass a filename";
    bless { eval { $class->defaults },
            @_,
            _file => $file }, $class;
}


sub next_message {
}


sub messages {
    my $self = shift;

    my @messages;
    while (my $message = $self->next_message) {
        push @messages, $message;
    }
    return @messages;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Email::Folder::Reader - reads raw RFC822 mails from a box

=head1 VERSION

version 0.860

=head1 SYNOPSIS

 use Email::Folder::Reader;
 my $box = Email::Folder::Reader->new('somebox');
 print $box->messages;

or, as an iterator

 use Email::Folder::Reader;
 my $box = Email::Folder::Reader->new('somebox');
 while ( my $mail = $box->next_message ) {
     print $mail;
 }

=head1 METHODS

=head2 new($filename, %options)

your standard class-method constructor

=head2 ->next_message

returns the next message from the box, or false if there are no more

=head2 ->messages

Returns all the messages in a box

=head1 AUTHORS

=over 4

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Richard Clamp <richardc@unixbeard.net>

=item *

Pali <pali@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Simon Wistow.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

