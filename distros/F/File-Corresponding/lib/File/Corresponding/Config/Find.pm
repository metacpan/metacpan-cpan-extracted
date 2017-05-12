
=head1 NAME

File::Corresponding::Config::Find -- Locate config files (e.g. per user)


=head1 SYNOPSIS

  use File::Corresponding::Config::Find;
  my $my_config = ".myapp";

  #Find .myapp in any of the user's home directories
  my $myapp_config_in_home
          = File::Corresponding::Config::Find->new()->user_config($my_config) or die;

  #Find .myapp in the current working directory, or in the user's home directory
  use Path::Class qw/ dir /;
  my $myapp_config_in_cwd_or_home
          = File::Corresponding::Config::Find->new(preferred_dirs => [ dir(".") ])->user_config($my_config)
          or die;


=head1 DESCRIPTION

Locate named config files in the usual places, e.g. the current dir,
the user's home directory (cross platform).

First the preferred_dirs are searched, then the user's document
directory, data directory, and home directory.

=head1 COMMENT

I searched for something like this, couldn't find anything.

So I wrote this module, and named it Config::Find. Which is a name
already taken by a CPAN module.

D'oh!

But now it's written, and it works, so it stays.

=cut

package File::Corresponding::Config::Find;
$File::Corresponding::Config::Find::VERSION = '0.004';
use Moose;



use Data::Dumper;
use Path::Class;
use Moose::Autobox;

use File::HomeDir;



=head1 ATTRIBUTES

=head2 preferred_dirs : ArrayRef[Path::Class]

=cut
has preferred_dirs => (
    is         => "rw",
    isa        => "ArrayRef[Path::Class::Dir]",
    default    => sub { [] },
    auto_deref => 1,
);



=head1 METHODS

=head2 user_config($config_file_name, $preferred_dirs = []) : Path::Class::File $found_file_name | undef

Find an existing readable file called $config_file_name
(e.g. ".myapp") in a) $preferred_dirs, or b) the usual user
directories ($HOME etc).

Return the complete file name to the config file, or undef if none was
found.

=cut
sub user_config {
    my $self = shift;
    my ($config_file_name) = @_;

    my @potential_dirs = (
        $self->preferred_dirs,
        File::HomeDir->my_documents,
        File::HomeDir->my_data,
        File::HomeDir->my_home,
    );
    for my $dir (@potential_dirs) {
        my $file = file($dir, $config_file_name);
        -r $file and return $file;
    }

    return undef;
}



1;



__END__
