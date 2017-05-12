package Gtk2::Ex::Email::Compose;

use warnings;
use strict;
use Gtk2;
use Gtk2::Ex::Email::AAnotebook;

=head1 NAME

Gtk2::Ex::Email::Compose - Presents a email compose window.

=head1 VERSION

Version 0.1.0

=cut

our $VERSION = '0.1.0';

=head1 SYNOPSIS

    use Gtk2::Ex::Email::Compose;
    use Gtk2;
    use Data::Dumper;
    
    Gtk2->init;
    
    my $ecw=Gtk2::Ex::Email::Compose->new;
    
    my $window=$ecw->window({title=>'some thing'});
    
    my $addressVBox=$ecw->getAddressVBox;
    my $attachmentVBox=$ecw->getAttachmentVBox;
    
    $ecw->setAddressbookCB(sub{
    					 use Data::Dumper;
    					 print Dumper($_[1]);
    				 },
    				 {
    				  ecw=>$ecw,
    				  addresses=>$addressVBox,
    				  }
    				 );
    
    $ecw->setCloseCB(sub{
    					 use Data::Dumper;
    					 print Dumper($_[1]);
    				 },
    				 {
    				  ecw=>$ecw,
    				  }
    				 );
    
    $ecw->setDraftCB(sub{
    					 use Data::Dumper;
    					 print Dumper($_[1]);
    				 },
    				 {
    				  ecw=>$ecw,
    				  addresses=>$addressVBox,
    				  attachment=>$attachmentVBox
    				  }
    				 );
    
    $ecw->setSendCB(sub{
    				  use Data::Dumper;
    				  print Dumper($_[1]{addresses});
    			  },
    			  {
    			   ecw=>$ecw,
    			   addresses=>$addressVBox,
    			   attachment=>$attachmentVBox,
    			   }
    			  );
    
    $ecw->setSpellcheckCB(sub{
    						  use Data::Dumper;
    						  print Dumper($_[1]);
    					  },
    					  {
    					   ecw=>$ecw,
    					   }
    					  );
    
    Gtk2->main;

=head1 METHODS

=head2 new

This initiates the object.

    my $ecw=Gtk2::Ex::Email::Compose->new;

=cut

sub new{
	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  gui=>{},
			  };
	bless $self;
	
	return $self;
}

=head2 getAAnotebook

This gets the notebook created by Gtk2::Ex::Email::AAnotebook.

    my $notebook=$ecw->getAAnotebook;

=cut

sub getAAnotebook{
	my $self=$_[0];

	return $self->{AAnotebook};
}

=head2 getAddressVBox

This gets the Gtk2::Ex::Email::AddressVBox object created
by Gtk2::Ex::Email::AAnotebook.

    my $addressVBox=$ecw->getAddressVBox;

=cut

sub getAddressVBox{
	my $self=$_[0];

	return $self->{AAnotebook}->getAddressVBox;
}

=head2 getAttachmentVBox

This gets the Gtk2::Ex::Email::AttachmentVBox object created
by Gtk2::Ex::Email::AAnotebook.

    my $attachmentVBox=$ecw->getAttachmentVBox;

=cut

sub getAttachmentVBox{
	my $self=$_[0];

	return $self->{AAnotebook}->getAttachmentVBox;
}

=head2 getBody

This gets the body.

    my $body=$ecw->getBody;

=cut

sub getBody{
	my $self=$_[0];

	return $self->{gui}{bodyBuffer}->get_text;
}

=head2 getSubject

This gets the subject.

    my $subject=$ecw->getSubject;

=cut

sub getSubject{
	my $self=$_[0];
	
	return 	$self->{gui}{subject}->get_text;
}

=head2 setAddressbookCB

This sets the callback for when the addressbook button is clicked.

Two options are taken. The first is the callback and the
second is any data to be passed to the callback.

    $ecw->setAddressbookCB(sub{
                               use Data::Dumper;
                               print Dumper($_[1]);
                              },
                              {
                               ecw=>$ecw,
                              }
                           );

=cut

sub setAddressbookCB{
	my $self=$_[0];
	my $callback=$_[1];
	my $data=$_[2];

	$self->{gui}{close}->signal_connect(clicked=>$callback, $data);

}

=head2 setBody

This sets the body.

One arguement is taken and that is the body
to set. If it is not defined, '' will be used.

    $ecw->setBody($body);

=cut

sub setBody{
	my $self=$_[0];
	my $text=$_[1];

	if (!defined($text)) {
		$text='';
	}

	return 	$self->{gui}{bodyBuffer}->set_text($text);
}

=head2 setCloseCB

This sets the callback for when the close button is clicked.

Two options are taken. The first is the callback and the
second is any data to be passed to the callback.

    $ecw->setCloseCB(sub{
                         use Data::Dumper;
                         print Dumper($_[1]);
                        },
                        {
                         ecw=>$ecw,
                        }
                     );

=cut

sub setCloseCB{
	my $self=$_[0];
	my $callback=$_[1];
	my $data=$_[2];

	$self->{gui}{close}->signal_connect(clicked=>$callback, $data);

}

=head2 setDraftCB

This sets the callback for when the draft button is clicked.

Two options are taken. The first is the callback and the
second is any data to be passed to the callback.

    $ecw->setDraftCB(sub{
                         use Data::Dumper;
                         print Dumper($_[1]);
                        },
                        {
                         ecw=>$ecw,
                        }
                      );

=cut

sub setDraftCB{
	my $self=$_[0];
	my $callback=$_[1];
	my $data=$_[2];

	$self->{gui}{draft}->signal_connect(clicked=>$callback, $data);

}

=head2 setSendCB

This sets the callback for when the send button is clicked.

Two options are taken. The first is the callback and the
second is any data to be passed to the callback.

    $ecw->setSendCB(sub{
                        use Data::Dumper;
                        print Dumper($_[1]);
                       },
                       {
                        ecw=>$ecw,
                       }
                     );

=cut

sub setSendCB{
	my $self=$_[0];
	my $callback=$_[1];
	my $data=$_[2];

	$self->{gui}{send}->signal_connect(clicked=>$callback, $data);

}

=head2 setSpellcheckCB

This sets the callback for when the spell check button is clicked.

Two options are taken. The first is the callback and the
second is any data to be passed to the callback.

    $ecw->setSpellcheckCB(sub{
                        use Data::Dumper;
                        print Dumper($_[1]);
                       },
                       {
                        ecw=>$ecw,
                       }
                     );

=cut

sub setSpellcheckCB{
	my $self=$_[0];
	my $callback=$_[1];
	my $data=$_[2];

	$self->{gui}{spellcheck}->signal_connect(clicked=>$callback, $data);

}

=head2 setSubject

This sets the subject.

One arguement is taken and that is the subject
to set. If it is not defined, '' will be used.

    my $subject=$ecw->getSubject('some subject');

=cut

sub setSubject{
	my $self=$_[0];
	my $text=$_[1];

	if (!defined($text)) {
		$text='';
	}

	$self->{gui}{subject}->set_text($text);

	return 1;
}

=head2 window

This builds the compose window and returns a
Gtk2::Window object.

One arguement is taken and it is a hash.

=head3 hash args

=head4 addresses

This is the hash that contains the addresses
to pass to Gtk2::Ex::Email::AddressVBox->vbox.

=head4 displayAddressbook

If set to true, it displays the 'Addressbook' button.

The default is true.

=head4 displayClose

If set to true, it displays the 'Close' button.

The default is true.

=head4 displayDraft

If set to true, it displays the 'Draft' button.

The default is true.

=head4 displaySend

If set to true, it displays the 'Send' button.

The default is true.

=head4 displaySpellcheck

If set to true, it displays the 'Spell Check' button.

The default is true.

=head4 files

This is the array that contains the files
to pass to Gtk2::Ex::Email::AttachmentVBox->vbox.

=head4 subject

If this is defined, the subject will be set to it.

=head4 title

The window title.

    my $window=$ecm->window(\%args);

=cut

sub window{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#sets the defaults
	if (!defined($args{displaySend})) {
		$args{displaySend}=1;
	}
	if (!defined($args{displayDraft})) {
		$args{displayDraft}=1;
	}
	if (!defined($args{displayClose})) {
		$args{displayClose}=1;
	}
	if (!defined($args{displayAddressbook})) {
		$args{displayAddressbook}=1;
	}
	if (!defined($args{displaySpellcheck})) {
		$args{displaySpellcheck}=1;
	}

	#the the window that will contain it all
	$self->{gui}{window}=Gtk2::Window->new;
	$self->{gui}{window}->set_default_size(750, 450);
	$self->{gui}{window}->show;
	if (defined($args{title})) {
		$self->{gui}{window}->set_title($args{title});
	}

	#this will hold everything in the window
	$self->{gui}{vbox}=Gtk2::VBox->new;
	$self->{gui}{vbox}->show;
	$self->{gui}{window}->add( $self->{gui}{vbox} );

	#this will hold the buttons
	$self->{gui}{buttonHB}=Gtk2::HBox->new;
	$self->{gui}{buttonHB}->show;
	$self->{gui}{vbox}->pack_start( $self->{gui}{buttonHB}, 0, 1, 1 );

	#set up the send button
	if ($args{displaySend}) {
		$self->{gui}{send}=Gtk2::Button->new;
		$self->{gui}{send}->show;
		$self->{gui}{sendLabel}=Gtk2::Label->new('Send');
		$self->{gui}{sendLabel}->show;
		$self->{gui}{send}->add($self->{gui}{sendLabel});
		$self->{gui}{buttonHB}->pack_start($self->{gui}{send}, 0, 1, 1);
	}

	#set up the send button
	if ($args{displayClose}) {
		$self->{gui}{close}=Gtk2::Button->new;
		$self->{gui}{close}->show;
		$self->{gui}{closeLabel}=Gtk2::Label->new('Close');
		$self->{gui}{closeLabel}->show;
		$self->{gui}{close}->add($self->{gui}{closeLabel});
		$self->{gui}{buttonHB}->pack_start($self->{gui}{close}, 0, 1, 1);
	}

	#set up the draft button
	if ($args{displayDraft}) {
		$self->{gui}{draft}=Gtk2::Button->new;
		$self->{gui}{draft}->show;
		$self->{gui}{draftLabel}=Gtk2::Label->new('Draft');
		$self->{gui}{draftLabel}->show;
		$self->{gui}{draft}->add($self->{gui}{draftLabel});
		$self->{gui}{buttonHB}->pack_start($self->{gui}{draft}, 0, 1, 1);
	}

	#set up the draft button
	if ($args{displayAddressbook}) {
		$self->{gui}{addressbook}=Gtk2::Button->new;
		$self->{gui}{addressbook}->show;
		$self->{gui}{addressbookLabel}=Gtk2::Label->new('Addressbook');
		$self->{gui}{addressbookLabel}->show;
		$self->{gui}{addressbook}->add($self->{gui}{addressbookLabel});
		$self->{gui}{buttonHB}->pack_start($self->{gui}{addressbook}, 0, 1, 1);
	}

	#set up the send button
	if ($args{displaySpellcheck}) {
		$self->{gui}{spellcheck}=Gtk2::Button->new;
		$self->{gui}{spellcheck}->show;
		$self->{gui}{spellcheckLabel}=Gtk2::Label->new('Spell Check');
		$self->{gui}{spellcheckLabel}->show;
		$self->{gui}{spellcheck}->add($self->{gui}{spellcheckLabel});
		$self->{gui}{buttonHB}->pack_start($self->{gui}{spellcheck}, 0, 1, 1);
	}

	#the paned seperating the notebook and entry
	$self->{gui}{vpaned}=Gtk2::VPaned->new;
	$self->{gui}{vpaned}->show;
	$self->{gui}{vpaned}->set_position(150);
	$self->{gui}{vbox}->pack_start( $self->{gui}{vpaned}, 1, 1, 1 );

	#AA notebook
	$self->{AAnotebook}=Gtk2::Ex::Email::AAnotebook->new();
	$self->{gui}{AAnotebook}=$self->{AAnotebook}->notebook( $args{addresses}, $args{files} );
	$self->{gui}{vpaned}->add1($self->{gui}{AAnotebook});

	#this vbox holds the stuff for the bottom paned
	$self->{gui}{bottomHPanedVB}=Gtk2::VBox->new;
	$self->{gui}{bottomHPanedVB}->show;
	$self->{gui}{vpaned}->add2( $self->{gui}{bottomHPanedVB} );

	#the subject
	$self->{gui}{subjectHB}=Gtk2::HBox->new;
	$self->{gui}{subjectHB}->show;
	$self->{gui}{subjectLabel}=Gtk2::Label->new('Subject:');
	$self->{gui}{subjectLabel}->show;
	$self->{gui}{subjectHB}->pack_start($self->{gui}{subjectLabel}, 0, 1, 1);
	$self->{gui}{subject}=Gtk2::Entry->new;
	$self->{gui}{subject}->show;
	$self->{gui}{subjectHB}->pack_start($self->{gui}{subject}, 1, 1, 1);
	if (defined($args{subject})) {
		$self->{gui}{subject}->set_text($args{text});
	}
	$self->{gui}{bottomHPanedVB}->pack_start( $self->{gui}{subjectHB}, 0, 1, 1 );

	#the final part
	$self->{gui}{body}=Gtk2::TextView->new;
	$self->{gui}{body}->show;
	$self->{gui}{bodyBuffer}=Gtk2::TextBuffer->new;
	$self->{gui}{body}->set_buffer($self->{gui}{bodyBuffer});
	$self->{gui}{bottomHPanedVB}->pack_start( $self->{gui}{body}, 1, 1, 1 );
	
	return $self->{gui}{window};
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-ex-email-compose at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Ex-Email-Compose>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Ex::Email::Compose


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Ex-Email-Compose>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Ex-Email-Compose>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Ex-Email-Compose>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Ex-Email-Compose/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::Ex::Email::Compose
