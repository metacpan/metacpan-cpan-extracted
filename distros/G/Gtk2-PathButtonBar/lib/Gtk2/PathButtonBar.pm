package Gtk2::PathButtonBar;

use Gtk2 '-init';
use warnings;
use strict;

=head1 NAME

Gtk2::PathButtonBar - Creates a bar for path manipulation.

=head1 VERSION

Version 0.1.2

=cut

our $VERSION = '0.1.2';


=head1 SYNOPSIS

This creates a collection of buttons and a entry widget to help with browsing a
path or etc.

It is composed of two lines. The first line contains a set of buttons. The first button
is a button that blanks the current path. This is the 'goRoot' button and displays what ever
the user has decided the root is by setting the 'root' key when invoking the new funtions.
The buttons after that are ones that correspond to a chunk of the path, broken up by what ever
the delimiter is set to. When any of these are pressed, the entry text is changed as well to
relfect it. The 'goRoot' button clears the path to ''.

The second line starts with a label. The label is the same as on the 'goRoot' button and is
what ever the root is set as. After that there is a single line text entry widget. This allows
the path to be set by typing it in. After the text entry widget, there is a button labeled 'Go'.
When this button is pressed, it updates the button bar with what is in text entry widget.

Any time the path is updated, '$self->{exec}' is ran through eval.

    use Gtk2;
    use Gtk2::PathButtonBar;
    
    Gtk2->init;
    
    my $window = Gtk2::Window->new();
    
    my $pbb=Gtk2::PathButtonBar->new({exec=>'print "path=".${$myself}->{path}."\na=".${$myself}->{vars}{a}."\n";',
                                    vars=>{a=>1},
                                    });
    
    print $pbb->{vbox}."\n";
    
    $window->add($pbb->{vbox});
    
    $window->show;

=head1 FUNCTIONS

=head2 new

This initiates this widget. This takes it's arguements in the form of a hash.
The accepted keys can be found below.

=head3 delimiter

This is what will be considered a delimiter between directories or whatever. The
default is '/'.

=head3 exec

This is a string that will be executed any time any change is done. Change the
text in the string entry box does not constitute a change till the 'Go' button is pressed.

For example, setting it to the following, would cause it to print the current path
followed a new line and then a 'a=' what ever '$self->{vars}{a}' is set to.

    exec=>'print "path=".${$myself}->{path}."\na=".${$myself}->{vars}{a}."\n:;

If you wish to pass any sort of variables to this, it is strongly suggested you do it by
using the 'vars' key in the hash passed to the new function.

Upon a failure to execute the code in exec, it will issue a warning.

=head3 root

This is what will be displayed as being the root. This wills how up in the 'goRoot' button
and in the label before the entry box.

If it is not defined, it defaults to what ever the delimiter is. If the delimiter is not set,
that means this will display '/', which works nicely for most unix FS stuff.

=head3 path

This is the path that the it will originally be set to.

=head3 vars

This is meant to contain variables that will be used with '$self->{exec}'.

=cut

sub new {
	my %args;
	if(defined($_[1])){
		%args= %{$_[1]};
	}

	my $self={error=>undef, set=>undef, errorString=>'', buttons=>{}};
	bless $self;

	if (!defined($args{exec})) {
		$args{exec}='print ${$myself}->{path}."\n";';
	}
	$self->{exec}=$args{exec};

	if (!defined($args{vars})) {
		$args{vars}={};
	}
	$self->{vars}=$args{vars};

#I've not added in the if statement for this yet and in retrospect I like the
#idea of leaving it out.
#	#determines if root will be shown or not
#	if (!defined($args{showRoot})) {
#		$args{showRoot}=1
#	}
#	$self->{showRoot}=$args{showRoot};

	#If the delimiter is not set, set it to '/'.
	if (!defined($args{delimiter})) {
		$args{delimiter}='/';
	}
	$self->{delimiter}=$args{delimiter};

	#If the root is not defined, use the delimiter.
	if (!defined($args{root})) {
		$args{root}=$args{delimiter};
	}
	$self->{root}=$args{root};

	if (!defined($args{path})) {
		$args{path}='';
	}
	$self->{path}=$args{path};

	#con
	$self->{vbox}=Gtk2::VBox->new(0, 1);
	$self->{vbox}->show;

	#the hbox that contains the buttons
	$self->{bhbox}=Gtk2::HBox->new(0, 1);
	$self->{vbox}->pack_start($self->{bhbox}, 0, 0, 1);
	$self->{bhbox}->show;

	#the hbox that contains the string box and go button
	$self->{shbox}=Gtk2::HBox->new(0, 1);
	$self->{vbox}->pack_start($self->{shbox}, 0, 0, 1);
	$self->{shbox}->show;

	#this adds the root label
	$self->{rootLabel}=Gtk2::Label->new($self->{root});
	$self->{rootLabel}->show;
	$self->{shbox}->pack_start($self->{rootLabel}, 0, 0, 1);

	#sets up the entry
	$self->{entry}=Gtk2::Entry->new();
	#sets the entry to the path
	$self->{entry}->set_text($args{path});
	$self->{shbox}->pack_start($self->{entry}, 1, 1, 1);
	$self->{entry}->show;

	#this button calls the go function
	$self->{go}=Gtk2::Button->new();
	$self->{goLabel}=Gtk2::Label->new("Go");
	$self->{go}->add($self->{goLabel});
	$self->{goLabel}->show;
	$self->{go}->show;
	$self->{go}->signal_connect("clicked" => sub{$_[1]->go;}, $self);
	$self->{shbox}->pack_start($self->{go}, 0, 0, 1);

	#this button calls the go function
	$self->{goRoot}=Gtk2::Button->new();
	$self->{goRootLabel}=Gtk2::Label->new($self->{root});
	$self->{goRoot}->add($self->{goRootLabel});
	$self->{goRootLabel}->show;
	$self->{goRoot}->show;
	$self->{goRoot}->signal_connect("clicked" => sub{$_[1]->goRoot;}, $self);
	$self->{bhbox}->pack_start($self->{goRoot}, 0, 0, 1);

	#
	$self->makeButtons();
	
	return $self;
}

=head2 go

This is called when a new path is set by pressing the go button.

There is no reason to ever call this from '$self->{exec}'.

=cut

sub go{
	my $self=$_[0];
	my $myself=\$self;#this is done for simplying coding the exec stuff
                      #If we did not have it here, stuff for in the buttons would go wonky and vice versa.
	$self->{path}=$self->{entry}->get_text;

	$self->{path}=~s/$self->{delimiter}+/$self->{delimiter}/g;
	$self->{path}=~s/^$self->{delimiter}+//;
	$self->{path}=~s/$self->{delimiter}+$//;
	$self->{entry}->set_text($self->{path});

	eval($self->{exec}) or warn("Gtk2::PathButtonBar go: eval failed on for... \n".$self->{exec}."\n");

	$self->makeButtons;
}

=head2 goRoot

This is called when a new path is set by pressing the root button.

If you wish to call this from '$self->{exec}', do it as below.

    ${$myself}->goRoot;

=cut

sub goRoot{
	my $self=$_[0];
	my $myself=\$self;#this is done for simplying coding the exec stuff
                      #If we did not have it here, stuff for in the buttons would go wonky and vice versa.
	$self->{path}='';
	$self->{entry}->set_text($self->{path});

	eval($self->{exec}) or warn("Gtk2::PathButtonBar goRoot: eval failed on for... \n".$self->{exec}."\n");

	$self->makeButtons;
	
}

=head2 makeButtons

This is a internal function that rebuilds the button bar.

If you wish to call this from '$self->{exec}', do it as below.

    ${$myself}->makeButtons;

=cut

sub makeButtons{
	my $self=$_[0];

	my @split=split($self->{delimiter}, $self->{path});

	my $splitInt=0;

	my $path='';

	#adds or changes buttons
	while ($splitInt <= $#split) {
		$path=$path.$split[$splitInt].$self->{delimiter};

		#the action works like this...
		#1: Create $myself for allowing a way of accessing self both here and in 'goRoot' and 'go'.
		#2: Gets the new path.
		#3: Sets the entry text.
		#4: rebuilds the buttons
		#5: eval what ever is in '$self->{exec}'.

		#add a new button if it does not exist
		if (defined($self->{buttons}{$splitInt})) {
			$self->{bhbox}->remove($self->{buttons}{$splitInt});
			$self->{buttons}{$splitInt}->destroy;
			$self->{buttons}{$splitInt."Label"}->destroy;
			delete($self->{buttons}{$splitInt});
			delete($self->{buttons}{$splitInt."Label"});
		}

		$self->{buttons}{$splitInt}=Gtk2::Button->new();
		$self->{buttons}{$splitInt."Label"}=Gtk2::Label->new($split[$splitInt].$self->{delimiter});
		$self->{buttons}{$splitInt}->add($self->{buttons}{$splitInt."Label"});
		$self->{buttons}{$splitInt."Label"}->show;
		$self->{buttons}{$splitInt}->show;
		$self->{buttons}{$splitInt}->signal_connect("clicked" => sub{
														my $myself=\$_[1]->{self};
														$_[1]->{self}->{path}=$_[1]->{path};
														$_[1]->{self}->{entry}->set_text($_[1]->{path});
														$_[1]->{self}->makeButtons;
														eval($_[1]->{self}->{exec}) or warn("Gtk2::PathButtonBar goRoot: eval failed on for... \n".$_[1]->{self}->{exec}."\n");
													},
													{
													 self=>$self,
													 path=>$path
													 }
													);
		$self->{bhbox}->pack_start($self->{buttons}{$splitInt}, 0, 0, 1);

		$splitInt++;
	}

	#removes unneeded buttons
	#any button past this point in $splitInt is a old one that is no longer in the page
	while (defined($self->{buttons}{$splitInt})) {
		$self->{bhbox}->remove($self->{buttons}{$splitInt});
		$self->{buttons}{$splitInt}->destroy;
		$self->{buttons}{$splitInt."Label"}->destroy;
		delete($self->{buttons}{$splitInt});
		delete($self->{buttons}{$splitInt."Label"});

		$splitInt++;
	}

}

=head2 setPath

This changes the current path.

One arguement is accepted and that is the path.

    $pbb->setPath($somepath);
    if($self->{error}){
        print "Error!\n";
    }

=cut

sub setPath{
	my $self=$_[0];
	my $path=$_[1];

	$self->errorblank;

	if (!defined($path)) {
		$self->{error}=1;
		$self->{errorString}='No path specified';
		warn('Gtk2-PathButtonBar setPath:1: '.$self->{errorString});
		return undef;
	}

	#this removes the delimiter if it starts with it
	$path=~s/^$self->{delimiter}//;
	$path=~s/$self->{delimiter}$//;

	#set the path
	$self->{entry}->set_text($path);
	$self->{path}=$path;

	#now that we have changed it, update the buttons
	$self->makeButtons;

	return 1;
}

=head2 errorblank

This blanks the error storage and is only meant for internal usage.

It does the following.

    $self->{error}=undef;
    $self->{errorString}="";

=cut

#blanks the error flags
sub errorblank{
        my $self=$_[0];

        $self->{error}=undef;
        $self->{errorString}="";

        return 1;
}

=head1 ERROR CODES

=head2 1

No path specified.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-pathbuttonbar at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-PathButtonBar>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::PathButtonBar


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-PathButtonBar>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-PathButtonBar>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-PathButtonBar>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-PathButtonBar>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::PathButtonBar
