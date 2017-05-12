package EWS::Client::Folder;
BEGIN {
  $EWS::Client::Folder::VERSION = '1.143070';
}

use Moose;
with 'EWS::Folder::Role::Reader';
# could add future roles for updates, here

has client => (
    is => 'ro',
    isa => 'EWS::Client',
    required => 1,
    weak_ref => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Folder Entries from Microsoft Exchange Server




=pod

=head1 NAME

EWS::Client::Folder - Folder Entries from Microsoft Exchange Server

=head1 VERSION

version 1.143070

=head1 DESCRIPTION

This module allows you to perform operations on the folder entries in a
Microsoft Exchange server. At present only read operations are supported,
allowing you to retrieve folder entries and all sub folders. The
results are available in an iterator and convenience methods exist to access
the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Client::Folder->new( \%arguments )

You would not normally call this constructor. Use the L<EWS::Client>
constructor instead.

Instantiates a new folder reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<client> => C<EWS::Client> object (required)

An instance of C<EWS::Client> which has been configured with your server
location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

