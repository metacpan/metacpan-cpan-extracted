
=head1 NAME

File::Corresponding::Group - A group of File::Profile objects

=head1 DESCRIPTION

A group of File::Profile objects which define which files belong
together.

=cut

package File::Corresponding::Group;
$File::Corresponding::Group::VERSION = '0.004';
use Moose;

use Data::Dumper;
use File::Path;
use Path::Class;
use Moose::Autobox;

use File::Corresponding::File::Profile;



=head1 PROPERTIES

=head2 name

Name/description of this File Group. It should describe what's common
between the files in the group.

=cut
has 'name' => (is => 'ro', isa => 'Str', default => "");




=head2 file_profiles

Array ref with File::Profile objects that make up the group.

=cut
has 'file_profiles' => (
    is      => 'rw',
    isa     => 'ArrayRef[File::Corresponding::File::Profile]',
    default => sub { [] },
);



=head1 METHODS

=head2 corresponding($file) : ArrayRef[File::Corresponding::File::Found]

Find files corresponding to $file (given the config in
->file_profiles) and return found @$files.

=cut
sub corresponding {
    my $self = shift;
    my ($file) = @_;

    my ($file_base, $fragment, $matching_profile) =
            $self->matching_file_fragment_profile($file);
    $matching_profile or return [];

    my $found_files =
            $self->file_profiles
            ->grep(sub { $_ != $matching_profile })
            ->map(sub { $_->new_found_if_file_exists(
                $matching_profile,
                $file_base,
                $fragment,
            ) });

    return $found_files;
}



=head2 matching_file_fragment_profile($file) : $file_fragment, File::Corresponding::File::Profile | ()

Return two item list with the $file_fragment and first profile that
matches $file, or an empty list if there is no match.

=cut
sub matching_file_fragment_profile {
    my $self = shift;
    my ($file) = @_;

    for my $profile ($self->file_profiles->flatten) {
        my ($file_base, $file_fragment) = $profile->matching_file_fragment($file);
        $file_base and return ($file_base, $file_fragment, $profile);
    }

    return ();
}



1;



__END__
