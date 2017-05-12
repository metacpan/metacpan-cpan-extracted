package Image::Processor::Interface::Console;

use strict;
use base ( 'Image::Processor::Base' );

# handles all the Console interaction

sub prompt_for_directory_creation {
    my ($self,$set) = @_;
    return $self->{'prompt_for_directory_creation'} if !$set;
    $self->{'prompt_for_directory_creation'} = $set;
}

sub console_get_drive {
    my ($self) = @_;
    $self->running_in('console');
    print "Please indicate which drive your CD is in";
    $_=<>;
    chomp;
    
    $self->cdrom($_);
    $self->read_info_cd();
}

sub console_prompt {
    my ($self,$string) = @_;
    print "$string ";
    $_=<>;
    chomp;
    return $_;
}

sub prompt_for_output_directory {
    my ($self) = @_;
    $self->output_directory( 
            $self->console_prompt("Output directory")
            );

    $self->process();
}

sub prompt_to_verify_directory_creation {
    my ($self) = @_;
    if (!-d $self->output_directory) {
        if ($self->prompt_for_directory_creation) {
            if ($self->console_prompt(
                  "Directory - " . $self->output_directory . "\ndoes not exist do you want me to create it?"
                  ) =~ /y/i)
            {
                $self->create_path($self->output_directory());
            } else {
                print "Nothing more for me to do then, bye!\n\n";
                die;   
            
            }
        } else {
            $self->create_path($self->output_directory());
        }
    }
}

sub prompt_for_caption {
    my ($self,$set) = @_;
    return $self->{'prompt_for_caption'} if !$set;
    $self->{'prompt_for_caption'} = $set;
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor::Interface::Console - Perl extension for Woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor::Interface::Console;
  Part of the Image::Processor module

=head1 DESCRIPTION

Image::Processor::Interface::Console

=head2 EXPORT

None this is all OOP.

=head2 METHODS

    'prompt_for_directory_creation' - turns on an off prompting for directory creation. default is off.
    
    'console_get_drive' - requests a drive from which to get the images

    'console_prompt' - provides for adding your own prompt. it expects a message for the prompt and
    returns a chomped response.

    'prompt_for_output_directory' - asks the user to enter where the output should go.

    'prompt_to_verify_directory_creation' - actual process of comfirming each directory if
            'prompt_for_directory_creation' is on and the directory doesn't exist.


=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
