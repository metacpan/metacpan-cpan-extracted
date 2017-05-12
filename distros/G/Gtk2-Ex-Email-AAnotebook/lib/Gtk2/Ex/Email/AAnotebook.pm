package Gtk2::Ex::Email::AAnotebook;

use warnings;
use strict;
use Gtk2;
use Gtk2::Ex::Email::AddressVBox;
use Gtk2::Ex::Email::AttachmentVBox;

=head1 NAME

Gtk2::Ex::Email::AAnotebook - Creates a Gtk2::Notebook object for handling addresses and attachments

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Gtk2::Ex::Email::AAnotebook;
    use Gtk2;
    use Data::Dumper;
    
    Gtk2->init;
    
    my $aanb=Gtk2::Ex::Email::AAnotebook->new();
    
    my $vbox=Gtk2::VBox->new;
    $vbox->show;
    
    my $notebook=$aanb->notebook;
    $vbox->pack_start($notebook, 1, 1, 1);
    
    #get the object for talking to the Gtk2::Ex::Email::AddressVBox
    my $addressVB=$aanb->getAddressVBox;
    
    #get the object for talking to the Gtk2::Ex::Email::AttachmentVBox
    my $attachmentVB=$aanb->getAttachmentVBox;
    
    #adds a button that calls getAddresses
    my $button=Gtk2::Button->new;
    $button->show;
    my $buttonLabel=Gtk2::Label->new('get addresses');
    $buttonLabel->show;
    $button->add($buttonLabel);
    $vbox->pack_start($button, 0, 1, 1);
    $button->signal_connect(clicked=>sub{
	    								my %addresses=$addressVB->getAddresses;
    									print Dumper(\%addresses);
    									}
    						);
    
    #adds a button that calls getFiles
    my $button2=Gtk2::Button->new;
    $button2->show;
    my $buttonLabel2=Gtk2::Label->new('get files');
    $buttonLabel2->show;
    $button2->add($buttonLabel2);
    $vbox->pack_start($button2, 0, 1, 1);
    $button2->signal_connect(clicked=>sub{
    									my @files=$attachmentVB->getFiles;
    									print Dumper(\@files);
    									}
    						);
    
    my $window=Gtk2::Window->new;
    $window->add($vbox);
    $window->show;
    
    Gtk2->main;

=head1 METHODS

=head2 new

This initiates the object.

    my $anb=Gtk2::Ex::Email::AAnotbook->new();

=cut

sub new{
	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  gui=>{},
			  module=>'Gtk2-Ex-Email-AAnotebook',
			  };
	bless $self;
	
	return $self;
}

=head2 getAddressVBox

This gets object created by Gtk2::Ex::Email::AddressVBox. This
should be called after the notebook method is called.

    my $addressVBox=$anb->getAttachmentVBox;

=cut

sub getAddressVBox{
	my $self=$_[0];
	my $function='getAddressVBox';

	if (!defined($self->{addressVB})) {
		warn($self->{module}.' '.$function.': Gtk2::Ex::Email::AddressVBox has not been initiated via the notebook method yet');
		return undef;
	}

	return $self->{addressVB};
}

=head2 getAttachmentVBox

This gets object created by Gtk2::Ex::Email::AttachmentVBox. This
should be called after the notebook method is called.

    my $attachmentVBox=$anb->getAttachmentVBox;

=cut

sub getAttachmentVBox{
	my $self=$_[0];
	my $function='getAttachmentVBox';

	if (!defined($self->{attachmentVB})) {
		warn($self->{module}.' '.$function.': Gtk2::Ex::Email::AttachmentVBox has not been initiated via the notebook method yet');
		return undef;
	}

	return $self->{attachmentVB};
}

=head2 notebook

This initiates the notebook object and returns it.

Two optional arguements are taken. The first is the the
hash reference that will be used for initiating
Gtk2::Ex::Email::AddressVBox and the second is a array
reference that will be used for initiating
Gtk2::Ex::Email::AttachmentVBox.

    my $notebook=$anb->notebook( \%addresses , \@files);

=cut

sub notebook{
	my $self=$_[0];
	my %addresses;
	if(defined($_[1])){
		%addresses= %{$_[1]};
	}
	my @files;
	if(defined($_[2])){
		@files= %{$_[2]};
	}	

	#inits the notbook
	$self->{gui}{notebook}=Gtk2::Notebook->new;
	$self->{gui}{notebook}->show;

	#creates the scrolled window that will hold the address book
	$self->{gui}{addressSW}=Gtk2::ScrolledWindow->new;
	$self->{gui}{addressSW}->show;

	#inits Gtk2::Ex::Email::AddressVBox
	$self->{addressVB}=Gtk2::Ex::Email::AddressVBox->new;
	$self->{gui}{addressVBox}=$self->{addressVB}->vbox(\%addresses);

	#puts the address tab in place
	$self->{gui}{addressLabel}=Gtk2::Label->new('Addresses');
	$self->{gui}{addressLabel}->show;
	$self->{gui}{addressSW}->add_with_viewport($self->{gui}{addressVBox});
	$self->{gui}{addressSW}->set_policy('never', 'always');
	$self->{gui}{notebook}->append_page($self->{gui}{addressSW}, $self->{gui}{addressLabel});

	#inits Gtk2::Ex::Email::AttachmentVBox
	$self->{attachmentVB}=Gtk2::Ex::Email::AttachmentVBox->new;
	$self->{gui}{attachmentVBox}=$self->{attachmentVB}->vbox(\@files);

	#puts the attachment tab in place
	$self->{gui}{attachmentLabel}=Gtk2::Label->new('Attachments');
	$self->{gui}{attachmentLabel}->show;
	$self->{gui}{notebook}->append_page($self->{gui}{attachmentVBox}, $self->{gui}{attachmentLabel});

	return $self->{gui}{notebook};
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-ex-email-aanotebook at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Ex-Email-AAnotebook>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Ex::Email::AAnotebook


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Ex-Email-AAnotebook>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Ex-Email-AAnotebook>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Ex-Email-AAnotebook>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Ex-Email-AAnotebook/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::Ex::Email::AAnotebook
