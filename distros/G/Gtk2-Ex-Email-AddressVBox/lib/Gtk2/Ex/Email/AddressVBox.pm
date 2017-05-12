package Gtk2::Ex::Email::AddressVBox;

use warnings;
use strict;
use Gtk2;

=head1 NAME

Gtk2::Ex::Email::AddressVBox - Creates a VBox for handling email addresses similar to Claws-Mail.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';


=head1 SYNOPSIS

    use Gtk2::Ex::Email::AddressVBox;
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
    
    #adds a button that calls getAddresses
    my $button=Gtk2::Button->new;
    $button->show;
    my $buttonLabel=Gtk2::Label->new('get addresses');
    $buttonLabel->show;
    $button->add($buttonLabel);
    $vbox->pack_start($button, 1, 1, 1);
    $button->signal_connect(activated=>{
	    								my %addresses=$avb->getAddresses;
		    							print Dumper(\%addresses);
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

    my $avb=Gtk2::Ex::Email::AddressVBox->new();

=cut

sub new{
	my $self={error=>undef,
			  perror=>undef,
			  errorString=>undef,
			  gui=>{
					hboxes=>{},
					},
			  };
	bless $self;
	
	return $self;
}

=head2 addHB

This adds a new HBox to the VBox. The HBox contains
the stuff for a single address.

Two option arguements are taken the first is the type to add
and the second is the address.

    #adds a new blank one
    $avd->addHB();

    #adds a new blank To one
    $avd->addHB('to');

    #adds a new blank CC one
    $avd->addHB('cc');

    #adds a new blank BCC one
    $avd->addHB('bcc');

    #adds a new blank To one set to foo@bar
    $avd->addHB('to', 'foo@bar');

=cut

sub addHB{
	my $self=$_[0];
	my $type=$_[1];
	my $address=$_[2];

	my %hbox;

	#this is the ID of it this specific one... zero is the top and they increase going down
	$hbox{id}=0;

	#once this is set to true, it means that a new one has been added and should not be done again
	$hbox{new}=0;

	#sets the id
	$hbox{id}=rand().rand().rand();

	#creates the first HB
	$hbox{hbox}=Gtk2::HBox->new;
	$hbox{hbox}->show;
	
	#creates the combo box to display to, cc, and bcc
	$hbox{combobox}=Gtk2::ComboBox->new_text;
	$hbox{combobox}->show;
	$hbox{combobox}->append_text('To: ');
	$hbox{combobox}->append_text('CC: ');
	$hbox{combobox}->append_text('BCC: ');
	$hbox{hbox}->pack_start($hbox{combobox}, 0, 1, 0);

	#sets the type
	my $typeSet=undef;
	if (defined($type)) {
		if ($type eq 'to') {
			$hbox{combobox}->set_active(0);
		}
		if ($type eq 'cc') {
			$hbox{combobox}->set_active(1);
		}
		if ($type eq 'bcc') {
			$hbox{combobox}->set_active(2);
		}
	}
	if (!$typeSet) {
		$hbox{combobox}->set_active(0);
	}

	#adds the entry box
	$hbox{entry}=Gtk2::Entry->new;
	$hbox{entry}->show;
	$hbox{hbox}->pack_start($hbox{entry}, 1, 1, 1);

	#sets the address if needed
	if (defined($address)) {
		$hbox{entry}->set_text($address);
	}

	#
	$hbox{entry}->signal_connect (changed => sub {
									  if ($_[1]{self}{gui}{hboxes}{ $_[1]{id} }{new} eq '0'){
										  $_[1]{self}->addHB;
										  $_[1]{self}{gui}{hboxes}{ $_[1]{id} }{new}=1;
									  }
								  },
								  {
								   self=>$self,
								   id=>$hbox{id},
								   }
								  );

	#adds the delete button to the hbox
	$hbox{del}=Gtk2::Button->new;
	$hbox{del}->show;
	$hbox{delLabel}=Gtk2::Label->new('del');
	$hbox{delLabel}->show;
	$hbox{del}->add($hbox{delLabel});
	$hbox{hbox}->pack_start($hbox{del}, 0, 1, 1);
	$hbox{del}->signal_connect(clicked=>sub{
								   my @HBIDs=keys(%{ $self->{gui}{hboxes} });
								   if (defined($HBIDs[1])) {
									   $self->{gui}{hboxes}{ $_[1]{id} }{hbox}->destroy;
									   delete($self->{gui}{hboxes}{ $_[1]{id} });
								   }else {
									   $self->{gui}{hboxes}{ $_[1]{id} }{entry}->set_text('');
								   }
							   },
							   {
								self=>$self,
								id=>$hbox{id},
								}
							   );

	#saves the hbox info
	$self->{gui}{hboxes}{ $hbox{id} }=\%hbox;

	$self->{gui}{vbox}->pack_start($hbox{hbox}, 0, 1, 1);

	return $hbox{id};
}

=head2 getAddresses

This gets the the addresses users have entered. Any that match
'' or /^ *$/ will be ignored.

    my %addresses=$avb->getAddresses;
    if(defined($addresses{to})){
        print 'To: '.join(' ', @{$addresses{to}});
    }
    if(defined($addresses{cc})){
        print 'CC: '.join(' ', @{$addresses{cc}});
    }
    if(defined($addresses{bcc})){
        print 'BCC: '.join(' ', @{$addresses{bcc}});
    }

=cut

sub getAddresses{
	my $self=$_[0];

	#this will be returned
	my %addresses;

	#these will be added later
	my @to;
	my @cc;
	my @bcc;

	my @hboxes=keys(%{$self->{gui}{hboxes}});

	#processes each one
	my $int=0;
	while (defined($hboxes[$int])) {
		my $address=$self->{gui}{hboxes}{ $hboxes[$int] }{entry}->get_text;

		my $typeInt=$self->{gui}{hboxes}{ $hboxes[$int] }{combobox}->get_active;
		
		#figures out the type
		my $type;
		if ($typeInt eq '0') {
			$type='to';
		}
		if ($typeInt eq '1') {
			$type='cc';
		}
		if ($typeInt eq '2') {
			$type='bcc';
		}

		#controls if it will be added or not
		my $add=1;

		#if it is blank do not add it
		if ($address eq '') {
			$add=undef;
		}

		#if it is all spaces do not add it
		if ($address=~/^ *$/) {
			$add=undef;
		}

		#add it
		if ($add) {
			if ($type eq 'to') {
				push(@to, $address);
			}
			if ($type eq 'cc') {
				push(@cc, $address);
			}
			if ($type eq 'bcc') {
				push(@bcc, $address);
			}
		}

		$int++;
	}

	#adds them to the hash
	if (defined($to[0])) {
		$addresses{to}=\@to;
	}
	if (defined($cc[0])) {
		$addresses{cc}=\@cc;
	}
	if (defined($bcc[0])) {
		$addresses{bcc}=\@bcc;
	}

	return %addresses;
}

=head2 vbox

This creates the VBox that contains the widgets.

=head3 args hash

=head4 bcc

This is a array of BCC addresses.

=head4 cc

This is a array of CC addresses.

=head4 to

This is a array of To addresses.

    my $vbox=$avb->vbox({
                         to=>['foo@bar'],
                        });

=cut

sub vbox{
	my $self=$_[0];
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	#this is what will be returned
	$self->{gui}{vbox}=Gtk2::VBox->new;
	$self->{gui}{vbox}->show;

	#adds any To if needed
	my $int=0;
	if (defined($args{to})) {
		if (defined($args{to}[0])) {
			while (defined($args{to}[$int])) {
				$self->addHB('to', $args{to}[$int]);

				$int++;
			}
		}
	}

	#adds any CC if needed
	if (defined($args{cc})) {
		$int=0;
		if (defined($args{cc}[0])) {
			while (defined($args{cc}[$int])) {
				$self->addHB('cc', $args{cc}[$int]);

				$int++;
			}
		}
	}

	#adds any BCC if needed
	if (defined($args{bcc})) {
		$int=0;
		if (defined($args{bcc}[0])) {
			while (defined($args{bcc}[$int])) {
				$self->addHB('bcc', $args{bcc}[$int]);

				$int++;
			}
		}
	}

	#adds the final HBox
	$self->addHB;

	return $self->{gui}{vbox};
}

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-ex-email-addressvbox at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Ex-Email-AddressVBox>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Ex::Email::AddressVBox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Ex-Email-AddressVBox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Ex-Email-AddressVBox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Ex-Email-AddressVBox>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Ex-Email-AddressVBox/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::Ex::Email::AddressVBox
