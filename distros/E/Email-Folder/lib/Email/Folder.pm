use strict;
use warnings;
package Email::Folder;
{
  $Email::Folder::VERSION = '0.860';
}
# ABSTRACT: read all the messages from a folder as Email::Simple objects

use Carp;
use Email::Simple;
use Email::FolderType 0.6 qw/folder_type/;


sub new {
    my $class  = shift;
    my $folder = shift || carp "Must provide a folder name\n";
    my %self = @_;

    my $reader;

    if ($self{reader}) {
        $reader = $self{reader};
    } else {
        $reader = "Email::Folder::".folder_type($folder);
    }
    eval "require $reader" or die $@;

    $self{_folder} = $reader->new($folder, @_);

    return bless \%self, $class;
}


sub messages {
    my $self = shift;

    my @messages = $self->{_folder}->messages;
    my @ret;
    while (my $body = shift @messages) {
        push @ret, $self->bless_message( $body );
    }
    return @ret;
}



sub next_message {
    my $self = shift;

    my $body = $self->{_folder}->next_message or return;
    $self->bless_message( $body );
}



sub bless_message {
    my $self    = shift;
    my $message = shift || die "You must pass a message\n";

    return Email::Simple->new($message);
}



sub reader {
    my $self = shift;
    return $self->{_folder};
}

1;


__END__
=pod

=encoding UTF-8

=head1 NAME

Email::Folder - read all the messages from a folder as Email::Simple objects

=head1 VERSION

version 0.860

=head1 SYNOPSIS

 use Email::Folder;

 my $folder = Email::Folder->new("some_file");

 print join "\n", map { $_->header("Subject") } $folder->messages;

=head1 METHODS

=head2 new($folder, %options)

Takes the name of a folder, and a hash of options

If a 'reader' option is passed in then that is
used as the class to read in messages with.

=head2 messages

Returns a list containing all of the messages in the folder.  Can only
be called once as it drains the iterator.

=head2 next_message

acts as an iterator.  reads the next message from a folder.  returns
false at the end of the folder

=head2 bless_message($message)

Takes a raw RFC822 message and blesses it into a class.

By default this is an Email::Simple object but can easily be overridden
in a subclass.

For example, this simple subclass just returns the raw rfc822 messages,
and exposes the speed of the parser.

 package Email::RawFolder;
 use base 'Email::Folder';
 sub bless_message { $_[1] };
 1;

=head2 reader

read-only accessor to the underlying Email::Reader subclass instance

=head1 SEE ALSO

L<Email::LocalDelivery>, L<Email::FolderType>, L<Email::Simple>

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

