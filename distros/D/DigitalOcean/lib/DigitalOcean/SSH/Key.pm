use strict;
package DigitalOcean::SSH::Key;
use Mouse;

#ABSTRACT: Represents a SSH Key object in the DigitalOcean API

our $VERSION = '0.03';

has DigitalOcean => (
    is => 'rw',
    isa => 'DigitalOcean',
);


has id => ( 
    is => 'ro',
    isa => 'Num',
);


has fingerprint => ( 
    is => 'ro',
    isa => 'Str',
);


has public_key => ( 
    is => 'ro',
    isa => 'Str',
);


has name => ( 
    is => 'ro',
    isa => 'Str',
);


has path => (
    is => 'rw',
    isa => 'Str',
);

sub BUILD { 
    my ($self) = @_;

    $self->path('account/keys/' . $self->id);
}


sub update { 
    my $self = shift;
    my (%args) = @_;

    return $self->DigitalOcean->_put_object($self->path, 'DigitalOcean::SSH::Key', 'ssh_key', \%args);
}


sub delete { 
    my ($self) = @_;
    return $self->DigitalOcean->_delete(path => $self->path);
}


__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DigitalOcean::SSH::Key - Represents a SSH Key object in the DigitalOcean API

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    FILL ME IN   

=head1 DESCRIPTION

FILL ME IN

=head1 METHODS

=head2 id

This is a unique identification number for the key. This can be used to reference a specific SSH key when you wish to embed a key into a Droplet.

=head2 fingerprint

This attribute contains the fingerprint value that is generated from the public key. This is a unique identifier that will differentiate it from other keys using a format that SSH recognizes.

=head2 public_key

This attribute contains the entire public key string that was uploaded. This is what is embedded into the root user's authorized_keys file if you choose to include this SSH key during Droplet creation.

=head2 name

This is the human-readable display name for the given SSH key. This is used to easily identify the SSH keys when they are displayed.

=head2 path

Returns the api path for this domain

=head2 update

This method updates an SSH key.

=over 4

=item

B<name> Required, String, The name to give the new SSH key in your account.

=back

    my $updated_ssh_key = $ssh_key->update(name => 'newname');

This method returns the updated L<DigitalOcean::SSH::Key>.

=head2 delete

This deletes the public SSH Key from your account. This will return 1 on success and undef on failure.

=head2 id

=head1 AUTHOR

Adam Hopkins <srchulo@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Hopkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
