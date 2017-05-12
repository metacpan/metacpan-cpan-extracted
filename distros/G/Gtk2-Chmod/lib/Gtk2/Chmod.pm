package Gtk2::Chmod;

use warnings;
use strict;
use Gtk2;
use File::Stat::Bits;

=head1 NAME

Gtk2::Chmod - Provides a dialog for getting values to use with chmod.

=head1 VERSION

Version 0.0.0

=cut

our $VERSION = '0.0.0';


=head1 SYNOPSIS

    use Gtk2;
    use Gtk2::Chmod;
    
    Gtk2->init;
    
    my %returned=Gtk2::Chmod->ask('/etc/passwd');
    if($returned{error}){
        print "Error!\n".$returned{errorString}."\n";
    }else{
        use Data::Dumper;
        print Dumper(\%returned);
    }

=head1 METHODS

=head2 ask

This creates a dialog that provides a dialog for getting
what mode should be used for a file/directory when doing
chmod.

The data is returned as a hash

The initial settings are based off of the file/direcotry specified.

    my %returned=Gtk2::Chmod->ask($item);
    if($returned{error}){
        print "Error!\n".$returned{errorString}."\n";
    }else{
        use Data::Dumper;
        print Dumper(\%returned);

       if($returned{pressed} eq 'ok'){
           if(-d $item){
               chmod($returned{dirmode}, $item);
           }else{
               chmod($returned{filemode}, $item);
           }
       }

    }

=cut

sub ask{
	my $item=$_[1];

	my $self={error=>undef, errorString=>''};
	bless($self);

	#the return value
	my %toreturn;
	$toreturn{mode}='0000';
	$toreturn{error}=undef;
	$toreturn{errorString}='';

	if (!-e $item) {
		$toreturn{error}=1;
		$toreturn{errorString}='The file or directory does not exist.';
		warn('Gtk2-Chmod ask:'.$toreturn{error}.':'.$toreturn{errorString});
		return %toreturn;
	}

	#we will be using the mode value later
	my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($item);
	
	#the dialog window
	$self->{window}=Gtk2::Dialog->new('chmod: '.$item,
									  undef,
									  [qw/modal destroy-with-parent/],
									  'gtk-cancel'     => 'cancel',
									  'gtk-ok'     => 'ok',
									  );
	
	#
	$self->{window}->set_position('center-always');

	$self->{window}->set_response_sensitive ('accept', 0);
	$self->{window}->set_response_sensitive ('reject', 0);
	
	$self->{vbox} = $self->{window}->vbox;
	$self->{vbox}->set_border_width(5);

	#the boxes to hold the permissions
	$self->{permhbox}=Gtk2::HBox->new;
	$self->{permhbox}->show;
	$self->{uvbox}=Gtk2::VBox->new;
	$self->{uvbox}->show;
	$self->{permhbox}->pack_start($self->{uvbox}, 1, 1, 0);
	$self->{vs0}=Gtk2::VSeparator->new;
	$self->{vs0}->show;
	$self->{permhbox}->pack_start($self->{vs0}, 1, 1, 0);
	$self->{gvbox}=Gtk2::VBox->new;
	$self->{gvbox}->show;
	$self->{permhbox}->pack_start($self->{gvbox}, 1, 1, 0);
	$self->{vs1}=Gtk2::VSeparator->new;
	$self->{vs1}->show;
	$self->{permhbox}->pack_start($self->{vs1}, 1, 1, 0);
	$self->{ovbox}=Gtk2::VBox->new;
	$self->{ovbox}->show;
	$self->{permhbox}->pack_start($self->{ovbox}, 1, 1, 0);
	$self->{vbox}->pack_start($self->{permhbox}, 1, 1, 0);

	#user perms
	$self->{user}=Gtk2::Label->new('user');
	$self->{user}->show;
	$self->{uvbox}->pack_start($self->{user}, 1, 1, 1);
	$self->{ur}=Gtk2::CheckButton->new('read');
	$self->{ur}->show;
	$self->{uvbox}->pack_start($self->{ur}, 1, 1, 1);
	$self->{uw}=Gtk2::CheckButton->new('write');
	$self->{uw}->show;
	$self->{uvbox}->pack_start($self->{uw}, 1, 1, 1);
	$self->{ux}=Gtk2::CheckButton->new('exec/list');
	$self->{ux}->show;
	$self->{uvbox}->pack_start($self->{ux}, 1, 1, 1);
	$self->{suid}=Gtk2::CheckButton->new('suid');
	$self->{suid}->show;
	$self->{uvbox}->pack_start($self->{suid}, 1, 1, 1);

	#group perms
	$self->{group}=Gtk2::Label->new('group');
	$self->{group}->show;
	$self->{gvbox}->pack_start($self->{group}, 1, 1, 1);
	$self->{gr}=Gtk2::CheckButton->new('read');
	$self->{gr}->show;
	$self->{gvbox}->pack_start($self->{gr}, 1, 1, 1);
	$self->{gw}=Gtk2::CheckButton->new('write');
	$self->{gw}->show;
	$self->{gvbox}->pack_start($self->{gw}, 1, 1, 1);
	$self->{gx}=Gtk2::CheckButton->new('exec/list');
	$self->{gx}->show;
	$self->{gvbox}->pack_start($self->{gx}, 1, 1, 1);
	$self->{sgid}=Gtk2::CheckButton->new('sgid');
	$self->{sgid}->show;
	$self->{gvbox}->pack_start($self->{sgid}, 1, 1, 1);

	#other perms
	$self->{other}=Gtk2::Label->new('other');
	$self->{other}->show;
	$self->{ovbox}->pack_start($self->{other}, 1, 1, 1);
	$self->{or}=Gtk2::CheckButton->new('read');
	$self->{or}->show;
	$self->{ovbox}->pack_start($self->{or}, 1, 1, 1);
	$self->{ow}=Gtk2::CheckButton->new('write');
	$self->{ow}->show;
	$self->{ovbox}->pack_start($self->{ow}, 1, 1, 1);
	$self->{ox}=Gtk2::CheckButton->new('exec/list');
	$self->{ox}->show;
	$self->{ovbox}->pack_start($self->{ox}, 1, 1, 1);

	#split the perm area from the other stuff
	$self->{hs0}=Gtk2::HSeparator->new;
	$self->{hs0}->show;
	$self->{vbox}->pack_start($self->{hs0}, 1, 1, 1);

	#recursive
	$self->{recursive}=Gtk2::CheckButton->new('Recursive?');
	$self->{recursive}->show;
	$self->{vbox}->pack_start($self->{recursive}, 1, 1, 1);

	#split the perm area from the other stuff
	$self->{hs1}=Gtk2::HSeparator->new;
	$self->{hs1}->show;
	$self->{vbox}->pack_start($self->{hs1}, 1, 1, 1);

	#dironly
	$self->{dironlyLabel}=Gtk2::Label->new('Set exec/search bit on directories only?');
	$self->{dironlyLabel}->show;
	$self->{dironlyhbox}=Gtk2::HBox->new;
	$self->{dironlyhbox}->show;
	$self->{vbox}->pack_start($self->{dironlyLabel}, 1, 1, 1);
	$self->{vbox}->pack_start($self->{dironlyhbox}, 1, 1, 1);
	#user
	$self->{udironly}=Gtk2::CheckButton->new('user');
	$self->{udironly}->show;
	$self->{dironlyhbox}->pack_start($self->{udironly}, 1, 1, 1);
	#group
	$self->{gdironly}=Gtk2::CheckButton->new('group');
	$self->{gdironly}->show;
	$self->{dironlyhbox}->pack_start($self->{gdironly}, 1, 1, 1);
	#other
	$self->{odironly}=Gtk2::CheckButton->new('other');
	$self->{odironly}->show;
	$self->{dironlyhbox}->pack_start($self->{odironly}, 1, 1, 1);

	$self->{window}->signal_connect(response => sub {
										$toreturn{pressed}=$_[1];
										#user
										$toreturn{ur}=$self->{ur}->get_active;
										$toreturn{ux}=$self->{ux}->get_active;
										$toreturn{uw}=$self->{uw}->get_active;
										$toreturn{suid}=$self->{suid}->get_active;
										#group
										$toreturn{gr}=$self->{gr}->get_active;
										$toreturn{gx}=$self->{gx}->get_active;
										$toreturn{gw}=$self->{gw}->get_active;
										$toreturn{sgid}=$self->{sgid}->get_active;
										#other
										$toreturn{or}=$self->{or}->get_active;
										$toreturn{ox}=$self->{ox}->get_active;
										$toreturn{ow}=$self->{ow}->get_active;
										#misc
										$toreturn{recursive}=$self->{recursive}->get_active;
										$toreturn{udironly}=$self->{udironly}->get_active;
										$toreturn{gdironly}=$self->{gdironly}->get_active;
										$toreturn{odironly}=$self->{odironly}->get_active;
									}
									);

	#set the switches properly
	#user read
	if (S_IRUSR & $mode) {
		$self->{ur}->set_active(1);
	}
	#user write
	if (S_IWUSR & $mode) {
		$self->{uw}->set_active(1);
	}
	#user suid
	if (S_ISUID & $mode) {
		$self->{suid}->set_active(1);
	}
	#user exec
	if (S_IXUSR & $mode) {
		$self->{ux}->set_active(1);
	}
	#group
	#group read
	if (S_IRGRP & $mode) {
		$self->{gr}->set_active(1);
	}
	#group write
	if (S_IWGRP & $mode) {
		$self->{gw}->set_active(1);
	}
	#group sgid
	if (S_ISGID & $mode) {
		$self->{sguid}->set_active(1);
	}
	#group exec
	if (S_IXGRP & $mode) {
		$self->{gx}->set_active(1);
	}
	#other
	#other read
	if (S_IROTH & $mode) {
		$self->{or}->set_active(1);
	}
	#other write
	if (S_IWOTH & $mode) {
		$self->{ow}->set_active(1);
	}
	#other exec
	if (S_IXOTH & $mode) {
		$self->{ox}->set_active(1);
	}

	#run what has been setup
	my $response=$self->{window}->run;

	#sets up the mode
	#user read
	if ($toreturn{ur}) {
		$toreturn{mode}=$toreturn{mode} + 400;
	}
	#user write
	if ($toreturn{uw}) {
		$toreturn{mode}=$toreturn{mode} + 200;
	}
	#user exec/search
	if ($toreturn{ux}) {
		$toreturn{mode}=$toreturn{mode} + 100;
	}
	#group read
	if ($toreturn{gr}) {
		$toreturn{mode}=$toreturn{mode} + 40;
	}
	#group write
	if ($toreturn{gw}) {
		$toreturn{mode}=$toreturn{mode} + 20;
	}
	#group exec/search
	if ($toreturn{gx}) {
		$toreturn{mode}=$toreturn{mode} + 10;
	}
	#other read
	if ($toreturn{or}) {
		$toreturn{mode}=$toreturn{mode} + 4;
	}
	#other write
	if ($toreturn{ow}) {
		$toreturn{mode}=$toreturn{mode} + 2;
	}
	#other exec/search
	if ($toreturn{ox}) {
		$toreturn{mode}=$toreturn{mode} + 1;
	}
	#setuid
	if ($toreturn{suid}) {
		$toreturn{mode}=$toreturn{mode} + 4000;
	}
	#setgid
	if ($toreturn{sgid}) {
		$toreturn{mode}=$toreturn{mode} + 2000;
	}

	#if we are to set dir only mode for any thing, update the file stuff
	$toreturn{filemode}=$toreturn{mode};
	if ($toreturn{ux} && $toreturn{udironly}) {
		$toreturn{filemode}=$toreturn{filemode} - 100;
	}
	if ($toreturn{gx} && $toreturn{gdironly}) {
		$toreturn{filemode}=$toreturn{filemode} - 10;
	}	
	if ($toreturn{ox} && $toreturn{odironly}) {
		$toreturn{filemode}=$toreturn{filemode} - 1;
	}	

	#mode
	if (length($toreturn{mode}) < 4) {
		my $toadd=4 - length($toreturn{mode});
		$toadd--;
		my $int=0;
		while ($int <= $toadd ) {
			$toreturn{mode}='0'.$toreturn{mode};

			$int++;
		}
		$toreturn{dirmode}=$toreturn{mode};
	}
	#file mode
	if (length($toreturn{filemode}) < 4) {
		my $toadd=4 - length($toreturn{filemode});
		$toadd--;
		my $int=0;
		while ($int <= $toadd ) {
			$toreturn{filemode}='0'.$toreturn{filemode};

			$int++;
		}
	}

	$self->{window}->destroy;

	return %toreturn;
}

=head1 RETURNED HASH

=head2 error

This is defined if there is a error and the integer is the
error code.

=head2 errorString

This provides a desciption of the current error.

=head2 pressed

If this is set to 'ok' the user has accepted the values.

=head2 ur

Set to '1' if the user has read permissions.

=head2 uw

Set to '1' if the user has write permissions.

=head2 ux

Set to '1' if the user has execute/search permissions.

=head2 suid

Set to '1' if the user has suid permissions.

=head2 gr

Set to '1' if the group has read permissions.

=head2 gw

Set to '1' if the group has write permissions.

=head2 sgid

Set to '1' if the group has sgid permissions.

=head2 ox

Set to '1' if the group has group permissions.

=head2 or

Set to '1' if the other has read permissions.

=head2 ow

Set to '1' if the other has write permissions.

=head2 ox

Set to '1' if the other has group permissions.

=head1 ERROR CODES

To check if a error is set, check $returned{error}. A
more verbose description of the returned error can be
found in $returned{errorString};

=head2 1

The file/directory does not exist.

=head1 AUTHOR

Zane C. Bowers, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-gtk2-chmod at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Gtk2-Chmod>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Gtk2::Chmod


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Gtk2-Chmod>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Gtk2-Chmod>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Gtk2-Chmod>

=item * Search CPAN

L<http://search.cpan.org/dist/Gtk2-Chmod/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Zane C. Bowers, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Gtk2::Chmod
