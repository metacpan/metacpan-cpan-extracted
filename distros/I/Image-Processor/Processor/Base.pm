package Image::Processor::Base;

use strict;

sub new {
    my ($class) = shift;
    my $self = {};
    bless $self , $class;
    return $self;
}

sub running_in {
    my ($self,$set) = @_;
    return $self->{'running_in'} if !$set;
    $self->{'running_in'} = $set;
}

sub cdrom {
    my ($self,$set) = @_;
    return $self->{'cdrom'} if !$set;
    $set = $self->trim_path($set);
    $self->{'cdrom'} = $set;
}

sub trim_path {
    my ($self,$path) = @_;
    $path =~ s![/\\]$!!;
    return $path;
}

sub output_directory {
    my ($self,$set) = @_;
    return $self->{'output_directory'} if !$set;
    $self->{'output_directory'} = $set;
}

sub source_directory {
    my ($self,$set) = @_;
    return $self->{'source_directory'} if !$set;
    $self->{'source_directory'} = $set;
}

sub error {
    my ($self,$message) = @_;
    warn $message;
        
}

sub graceful_exit {
    my ($self,$message) = @_;
    die "Immage::Processor could not complete because: $message\n"; 
}
1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor::Base - Perl extension for Woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor::Base;
  Part of the Image::Processor module.  Most interaction is performed via Image::Processor
  so please refer to its documentation for more information.

=head1 DESCRIPTION

Image::Processor::Base

=head2 EXPORT

None this is all OOP.

=head2 METHODS

    'new' - constructs the object. Assigns no attributes.
    
    'running_in' - returns or sets how the app is being run, either console or web

    'cdrom' - sets which device to use if working with CD's 

    'output_directory' - returns or sets the directory in which output will go.
                         this value is appended with the CD order id if applicable

    'source_directory' - sets were the data is to be retrieved from. this does not
                         have to be set if you use the cdrom setting. see examples

    'error' - this will print any message sent to it via the warn function
    
    'graceful_exit' - this will print any message sent to it and 'die', the
                      default messages sent to it usually include hints as to
                      what caused the exit. if you add to this utility please
                      use robust informative error messages.

=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
