package Image::Processor::Mail::GetImages;

use strict;

use base 'Image::Processor::Base';

use Mail::MboxParser;

sub store_only {
    my ($self,$set) = @_;
    return $self->{'store_only'} if !$set;
    $self->{'store_only'} = $set;
}

sub mbox_file {
    my ($self,$set) = @_;
    return $self->{'mbox_file'} if !$set;
    $self->{'mbox_file'} = $set;
}

sub attachment_output_directory {
    my ($self,$set) = @_;
    if (!-d $set && $set) { $self->error("Directory $set doesn't exist\n"); }
    return $self->{'attachment_output_directory'} if !$set;
    $self->{'attachment_output_directory'} = $set;
}


sub process_mails {
    my ($self) = @_;
    $self->graceful_exit(
        "You have not set 'attachment_output_directory'")
            if !$self->attachment_output_directory();
    chdir( $self->mbox_file() );
    foreach my $file ( <*> ) {
        # print "Working on $file\n";
        process_file($file);
    }
}

sub process_file {
    my ($self,$file) = @_;
    $self->graceful_exit(
        "You have not 'attachment_output_directory'")
            if !$self->attachment_output_directory();

    $file = "/$file" if $file;
    my $file_to_open = $self->mbox_file() . "$file";

    my $mb = Mail::MboxParser->new($file_to_open, decode => 'ALL');
    my $store_only = $self->store_only() || '(jpg|gif)$';

    while (my $msg = $mb->next_message) {
        $msg->store_all_attachments(
                   path => $self->attachment_output_directory(), 
                   store_only => $store_only
                   );
    }
}

1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Image::Processor::Mail::GetMailImages - Perl extension for Woking with disk stores of images

=head1 SYNOPSIS

  use Image::Processor::Mail::GetMailImages;
  Part of the Image::Processor module

=head1 DESCRIPTION

Image::Processor::Mail::GetMailImages

=head2 EXPORT

None this is all OOP.

=head2 METHODS

    'store_only' accepts the following
    'mbox_file' accepts the following
    'attachment_output_directory' accepts the following
    'process_mails' accepts the following
    'process_file' accepts the following


=head1 AUTHOR

Aaron Johnson E<lt>solution@gina.netE<gt>


=head1 SEE ALSO

L<perl>.

=cut
