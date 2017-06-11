package File::DataClass;

use 5.010001;
use strict;
use warnings;
use version; our $VERSION = qv( sprintf '0.73.%d', q$Rev: 1 $ =~ /\d+/gmx );

1;

__END__

=pod

=begin html

<a href="https://travis-ci.org/pjfl/p5-file-dataclass"><img src="https://travis-ci.org/pjfl/p5-file-dataclass.svg?branch=master" alt="Travis CI Badge"></a>
<a href="https://roxsoft.co.uk/coverage/report/file-dataclass/latest"><img src="https://roxsoft.co.uk/coverage/badge/file-dataclass/latest" alt="Coverage Badge"></a>
<a href="http://badge.fury.io/pl/File-DataClass"><img src="https://badge.fury.io/pl/File-DataClass.svg" alt="CPAN Badge"></a>
<a href="http://cpants.cpanauthors.org/dist/File-DataClass"><img src="http://cpants.cpanauthors.org/dist/File-DataClass.png" alt="Kwalitee Badge"></a>

=end html

=head1 Name

File::DataClass - Structured data file IO with caching and searching

=head1 Version

This document describes version v0.73.$Rev: 1 $ of L<File::DataClass>

=head1 Synopsis

   use File::DataClass::Schema;

   $schema = File::DataClass::Schema->new
      ( path    => [ 'path to a file' ],
        result_source_attributes => { source_name => {}, },
        tempdir => [ 'path to a directory' ] );

   $schema->source( 'source_name' )->attributes( [ qw( list of attr names ) ] );
   $rs = $schema->resultset( 'source_name' );
   $result = $rs->find( { name => 'id of field element to find' } );
   $result->$attr_name( $some_new_value );
   $result->update;
   @result = $rs->search( { 'attr name' => 'some value' } );

=head1 Description

Provides methods for manipulating structured data stored in files of
different formats

The documentation for this distribution starts in the class
L<File::DataClass::Schema>

L<File::DataClass::IO> is a L<Moo> based implementation of L<IO::All>s API.
It implements the file and directory methods only

=head1 Configuration and Environment

Defines the distributions C<VERSION> number using a polyglot interpreted by
both Perl and hooks in the C<VCS>

=head1 Subroutines/Methods

None

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<version>

=back

=head1 Incompatibilities

On C<mswin32> and C<cygwin> it is assumed that NTFS is being used and
that it does not support C<mtime> so caching on those platforms is
disabled

Due to the absence of an C<mswin32> environment for testing purposes that
platform is not supported

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-DataClass. Patches are
welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

The class structure and API where taken from L<DBIx::Class>

The API for the file IO was taken from L<IO::All>

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2017 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
