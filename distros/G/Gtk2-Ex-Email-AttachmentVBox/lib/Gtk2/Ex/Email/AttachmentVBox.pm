package Gtk2::Ex::Email::AttachmentVBox;

use warnings;
use strict;
use File::MimeInfo;
use Gtk2;
use Gtk2::SimpleList;

=head1 NAME

Gtk2::Ex::Email::AttachmentVBox - Creates a VBox for handling attachments.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Gtk2::Ex::Email::AttachmentVBox;
    use Gtk2;
    use Data::Dumper;
    
    Gtk2->init;
    
    #init it
    my $avb=Gtk2::Ex::Email::AddressVBox->new();
    
    #get the VBox and add it
    my $vbox=Gtk2::VBox->new;
    $vbox->show;
    my $vbox2=$avb->vbox;
    $vbox->pack_start($vbox2, 1, 1, 1);
    
    #adds a button that calls getFiles
    my $button=Gtk2::Button->new;
    $button->show;
    my $buttonLabel=Gtk2::Label->new('get files');
    $buttonLabel->show;
    $button->add($buttonLabel);
    $vbox->pack_start($button, 1, 1, 1);
    $button->signal_connect(activated=>{
	    								my @files=$avb->getFiles;
		    							print Dumper(\@files);
			    						}
				    		);
    
    #add the VBox to the window
    my $window=Gtk2::Window->new;
    $window->add($vbox);
    $window->show;
    
    #run it
    Gtk2->main;

=head1 METHODS

=head2 new

This initiates the object.

    my $avb=Gtk2::Ex::Email::AttachmentVBox->new();

=cut

sub new{
	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  gui=>{},
			  module=>'Gtk2-Ex-Email-AttachmentVBox',
			  };
	bless $self;
	
	return $self;
}

=head2 addFile

This adds a file to the list.

One arguement is required and it is the file to add.

If it fails, it returns undef, otherwise '1'.

    my $returned=$avb->addFile($someFile);
    if(!$returned){
        print "Error!\n";
    }

=cut

sub addFile{
	my $self=$_[0];
	my $file=$_[1];
	my $function='addFile';

	#make sure we have a file
	if (!defined($file)) {
		warn($self->{module}.' '.$function.': No file specified');
		return undef;
	}

	#make sure it exists
	if (! -e $file) {
		warn($self->{module}.' '.$function.': The file does not exist');
		return undef;
	}

	#gets the mime type
	my $mimetype=mimetype($file);
	if (!defined($mimetype)) {
		warn($self->{module}.' '.$function.': Unable to get mime type');
		return undef;		
	}

	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($file);

	my @topush;
	push(@topush, $mimetype);
	push(@topush, $size);
	push(@topush, $file);

	#adds the new entry
	push(@{$self->{gui}{list}->{data}}, \@topush);

	return 1;
}

=head2 addFileDialog

This calls Gtk2::FileChooserDialog and the file
to the list.

A return of undef means the user canceled. A return of
'1' means a file was added.

    my $returned=$avb->addFileDialog;
    if($returned){
        print "added a file\n";
    }else{
        print "user canceled\n";
    }

=cut

sub addFileDialog{
	my $self=$_[0];

	my $file_chooser =  Gtk2::FileChooserDialog->new (
													  'Select a file to attach...',
													  undef,
													  'open',
													  'gtk-cancel' => 'cancel',
													  'gtk-ok' => 'ok'
													  );

	if ('ok' ne $file_chooser->run){
		$file_chooser->destroy;
		print "test\n";
		return undef;
	}

	my $filename = $file_chooser->get_filename;

	$file_chooser->destroy;

	$self->addFile($filename);

	return 1;
}

=head2 getFiles

Gets a list of the files that should be attached.

    my @files=$avb->getFiles;

=cut

sub getFiles{
	my $self=$_[0];

	my @files;

	my $int=0;
	while (defined( $self->{gui}{list}->{data}[$int][2] )) {
		push( @files, $self->{gui}{list}->{data}[$int][2] );
		
		$int++;
	}
	#unfortunately the defined check will add a new row
	#so there for we remove it
	delete(@{$self->{gui}{list}->{data}}[$int]);

	return @files;
}

=head2 removeSelected

This removes the currently selected file from the list.

    my $returned=$avb->removeSelected;
    if($returned){
        print "removed\n";
    }else{
        print "nothing selected\n";
    }

=cut

sub removeSelected{
	my $self=$_[0];

	my @selected=$self->{gui}{list}->get_selected_indices;

	#nothing selected
	if (!defined($selected[0])) {
		return undef;
	}

	#removes it
	delete(@{$self->{gui}{list}->{data}}[$selected[0]]);

	return 1;
}

=head2 vbox

This creates the VBox that contains the widgets.

One arguement is taken and it is a array of files
to initially attach.

    $avb->vbox(\@files);

=cut

sub vbox{
	my $self=$_[0];
	my @files;
	if(defined($_[1])){
		@files= @{$_[1]};
	}

	#the vbox
	$self->{gui}{vbox}=Gtk2::VBox->new;
	$self->{gui}{vbox}->show;

	#holds the buttons
	$self->{gui}{buttonHB}=Gtk2::HBox->new;
	$self->{gui}{buttonHB}->show;
	$self->{gui}{vbox}->pack_start($self->{gui}{buttonHB}, 0, 1, 1);

	#the add button
	$self->{gui}{add}=Gtk2::Button->new;
	$self->{gui}{add}->show;
	$self->{gui}{addLabel}=Gtk2::Label->new('Add Attachment');
	$self->{gui}{addLabel}->show;
	$self->{gui}{add}->add($self->{gui}{addLabel});
	$self->{gui}{buttonHB}->pack_start($self->{gui}{add}, 0, 1, 1);
	$self->{gui}{add}->signal_connect(clicked=>sub{
										  $_[1]{self}->addFileDialog;
									  },
									  {
									   self=>$self,
									   }
									  );

	#the remove button
	$self->{gui}{remove}=Gtk2::Button->new;
	$self->{gui}{remove}->show;
	$self->{gui}{removeLabel}=Gtk2::Label->new('Remove Attachment');
	$self->{gui}{removeLabel}->show;
	$self->{gui}{remove}->add($self->{gui}{removeLabel});
	$self->{gui}{buttonHB}->pack_start($self->{gui}{remove}, 0, 1, 1);
	$self->{gui}{remove}->signal_connect(clicked=>sub{
										  $_[1]{self}->removeSelected;
									  },
									  {
									   self=>$self,
									   }
									  );

	#the SW window that will hold attachment list
	$self->{gui}{attachmentSW}=Gtk2::ScrolledWindow->new;
	$self->{gui}{attachmentSW}->show;
	$self->{gui}{vbox}->pack_start($self->{gui}{attachmentSW}, 1, 1, 1);

	#the list that will hold the attachmentlist
	$self->{gui}{list}=Gtk2::SimpleList->new(
											 'Mime Type'=>'text',
											 'Size'=>'text',
											 'File'=>'text',
											 );
	$self->{gui}{list}->show;
	$self->{gui}{attachmentSW}->add($self->{gui}{list});

	#add any files if asked to
	if (defined( $files[0] )) {
		my $int=0;
		while (defined( $files[$int] )) {
			$self->addFile($files[$int]);

			$int++;
		}

	}

	return $self->{gui}{vbox};
}

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-ex-email-attachmentvbox at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Ex-Email-AttachmentVBox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Ex::Email::AttachmentVBox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Ex-Email-AttachmentVBox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Ex-Email-AttachmentVBox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Ex-Email-AttachmentVBox>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Ex-Email-AttachmentVBox/>

=back


=head1 ACKNOWLEDGEMENTS

ANDK, #51565, notified be about a missing dependency

=head1 COPYRIGHT & LICENSE

Copyright 2011 Zane C. Bowers-Hadley, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::Ex::Email::AttachmentVBox
