package Lingua::Thesaurus::IO;

use Moose::Role;

has 'storage'          => (is => 'ro', does => 'Lingua::Thesaurus::Storage',
                           required => 1,
         documentation => "storage for parsed terms and relations");

requires 'load';

1;

__END__

=head1 NAME

Lingua::Thesaurus::IO - Role for input/output operations on a thesaurus

=head1 DESCRIPTION

This abstract role specifies that each C<IO> concrete class
will have a C<storage> attribute, and should implement
a C<load> method.
Other methods for dumping thesauri into files will be added
in later release.

=head1 METHODS

=head2 load

  $io_object->load(@files);

Parses the given files, and loads the terms and relations from these
files into the C<storage> object.




