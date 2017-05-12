package FormValidator::Nested::ProfileProvider::YAML;
use Any::Moose;
use Any::Moose 'X::Types::Path::Class';
use namespace::clean -except => 'meta';
with 'FormValidator::Nested::ProfileProvider';

our $EXT     = '.yml';

use FormValidator::Nested::ProfileProvider;

use YAML::Syck; $YAML::Syck::ImplicitUnicode = 1;
use Path::Class;

has 'dir' => (
    is       => 'ro',
    isa      => 'Path::Class::Dir',
    coerce   => 1,
    required => 1,
);

__PACKAGE__->meta->make_immutable;


sub _build_profile_keys {
    my $self = shift;

    my @profile_keys;
    $self->dir->recurse(
        callback => sub {
            my $path = shift;
            if ( $path !~ m/$EXT$/ ) {
                return;
            }
            my $relative_path = $path->relative($self->dir);
            $relative_path =~ s/$EXT$//;
            push @profile_keys, $relative_path;
        }
    );
    return \@profile_keys;
}


sub get_profile_data {
    my $self = shift;
    my $key  = shift;

    my @path = split m{/}, $key;
    $path[-1] .= $EXT;

    my $file = Path::Class::File->new($self->dir, @path);
    if ( !-f $file ) {
        return 0;
    }

    my $profile = YAML::Syck::LoadFile(Path::Class::File->new($self->dir, @path));

    return $profile;
}

1;

