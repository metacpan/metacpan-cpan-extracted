

=head1 NAME

File::Corresponding::File::Found - A file that was found in the file
system, given a matching profile

=cut

use strict;
package File::Corresponding::File::Found;
$File::Corresponding::File::Found::VERSION = '0.004';
use Moose;

use Data::Dumper;
use MooseX::Types::Path::Class qw( Dir File );

use File::Corresponding::File::Profile;



=head1 PROPERTIES

=head2 file : Path::Class

File that was found.

=cut
has file => (
    is => 'ro',
    isa => File,
    coerce => 1,
);




=head2 matching_profile : File::Corresponding::File::Profile

Profile that was used to match against.

=cut
has matching_profile => (is => 'ro', isa => 'File::Corresponding::File::Profile');



1;



__END__
