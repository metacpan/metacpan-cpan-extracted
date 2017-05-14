# $Id: HTMLSurface.pm,v 1.14 2001/11/02 13:46:13 joern Exp $

package JaM::GUI::HTMLSurface;

@ISA = qw ( JaM::GUI::Base );

use strict;
use Carp;
use Gtk::HTML;
use FileHandle;
use Data::Dumper;
use JaM::GUI::Base;
use File::Basename;

sub widget 	    { shift->{widget}	    }
sub image_dir 	    { shift->{image_dir}    }

sub handle	    { my $s = shift; $s->{handle}
		      = shift if @_; $s->{handle}	    }
sub image_pool	    { my $s = shift; $s->{image_pool}
		      = shift if @_; $s->{image_pool}	    }
sub url_in_focus    { my $s = shift; $s->{url_in_focus}
		      = shift if @_; $s->{url_in_focus}	    }
sub button3_callback{ my $s = shift; $s->{button3_callback}
		      = shift if @_; $s->{button3_callback} }
sub mail_link_callback { my $s = shift; $s->{mail_link_callback}
		         = shift if @_; $s->{mail_link_callback} }

sub gtk_attachment_popup    { my $s = shift; $s->{gtk_attachment_popup}
		      	      = shift if @_; $s->{gtk_attachment_popup}	    }


sub new {
	my $type = shift;
	my %par = @_;
	
	my  ($image_dir, $button3_callback, $mail_link_callback) =
	@par{'image_dir','button3_callback','mail_link_callback'};

	my $widget;
	eval {
		$widget = new Gtk::HTML;
	};
	confess ($@) if $@;
	
	my $self = bless {
		widget    => $widget,
		image_dir => $image_dir,
		button3_callback => $button3_callback,
		mail_link_callback => $mail_link_callback,
		handle    => undef,
	}, $type;
	
	$widget->signal_connect ('url_requested',    sub { $self->cb_url_requested (@_) } );
#	$widget->signal_connect ('object_requested', sub { $self->cb_object_requested (@_) } );
	$widget->signal_connect ('on_url',           sub { $self->cb_on_url (@_) } );
#	$widget->signal_connect ('link_clicked',     sub { $self->cb_link_clicked (@_) } );

	$widget->signal_connect ('button_press_event',   sub { $self->cb_button_press (@_) } );
#	$widget->signal_connect ('button_release_event', sub { print Dumper (\@_) } );

	$widget->show;

	# build popup menu for attachments
	my $popup = $self->gtk_attachment_popup (Gtk::Menu->new);
	my $item = Gtk::MenuItem->new ("Save as ...");
	$popup->append($item);
	$item->signal_connect ("activate", sub { $self->cb_save_attachment_file_dialog ( @_ ) } );
	$item->show;

	return $self;
}

sub show_eval {
	my $self = shift;
	my %par = @_;
	my ($file) = @par{'file'};

	my $base_dir = $self->image_dir;
	$file = "$base_dir/$file";
	
	open (IN, $file) or confess "can't read $file";
	my $content = join ('',<IN>);
	close IN;
	
	$content = eval 'qq{'.$content.'}';
	print $@;
	
	$self->begin;
	$self->write ($content);
	$self->end;
	
	1;
}

sub cb_on_url {
	my $self = shift;
	my ($widget, $url) = @_;
	$self->url_in_focus ( $url );
}

sub cb_button_press {
	my $self = shift;
	my ($widget, $event) = @_;
	
	my $url = $self->url_in_focus;

	if ( not $url ) {
		if ( $event->{button} == 3 ) {
			my $cb = $self->button3_callback;
			&$cb ($event);
		}
	} else {
		return $self->url_click ( event => $event );
	}
}

sub url_click {
	my $self = shift;
	my %par = @_;
	my ($event) = @par{'event'};

	my $url = $self->url_in_focus;

	if ( $url =~ /^(https?|ftp):/ ) {
		return 1 if $event->{button} != 1;
		my $browser_prog = $self->config('browser_prog');
		system ("$browser_prog -remote 'openURL($url)' >/dev/null 2>&1 &");
		return 1;
	} elsif ( $url =~ /mailto:([^\s]+)/ ) {
		my $cb = $self->mail_link_callback;
		&$cb( address => $1 );
		return 1;
	}
	
	if ( $event->{button} == 3 ) {
		$self->gtk_attachment_popup->popup (undef, undef, $event->{button}, 0);

	} elsif ( $event->{button} == 1 ) {
		$self->cb_save_attachment_file_dialog;
	}
}

sub cb_save_attachment_file_dialog {
	my $self = shift;
	my $url = $self->url_in_focus;
	return if not $url;
	
	$self->debug ("url=$url");
	
	my $filename = $url;
	if ( $filename =~ m!^pool://(.*)! ) {
		$filename = $self->image_pool->{$1}->{head}->recommended_filename;
	} else {
		$filename = "";
	}

	my $dir = $self->session_parameters->{'attachment_target_dir'};
	$dir ||= $self->config ('attachment_target_dir');

	$self->show_file_dialog (
		title	 => "Save as...",
		dir 	 => $dir,
		filename => $filename,
		confirm  => 1,
		cb 	 => sub { $self->cb_save_attachment_file_selected ( filename => $_[0], url => $url ) }
	);
	
	1;
}

sub cb_save_attachment_file_selected {
	my $self = shift;
	my %par = @_;
	my ($filename, $url) = @par{'filename','url'};

	$self->debug ("save attachment: url=$url filename=$filename");

	$self->session_parameters->{'attachment_target_dir'} = dirname $filename;

	my $image_dir = $self->image_dir;
	my $source_filename = "$image_dir/$url";
	my $target_filename = $filename;

	if ( not open (OUT, "> $target_filename") ) {
		print STDERR "Error opening $target_filename for writing!\n";
		return 1;
	}
	
	if ( $url =~ m!^pool://(.*)! ) {
		# internal image pool request
		print OUT $self->image_pool->{$1}->{body}->as_string;

	} elsif ( $url =~ m!^mail://(.*)! ) {
		# internal image pool request
		print OUT $self->image_pool->{$1}->{entity}->as_string;

	} elsif ( open (IN, $source_filename) ) {
		# external file request
		while (<IN>) {
			print OUT;
		}
		close IN;
	} else {
		print STDERR "Error opening $source_filename for reading!\n!";
	}

	close OUT;

	1;
}

sub cb_url_requested {
	my $self = shift;
	my ($widget, $url, $handle) = @_;

	my $image_dir = $self->image_dir;
	my $filename = "$image_dir/$url";
	my $fh = new FileHandle;
	
	if ( $url =~ m!^pool://(.*)! ) {
		# internal image pool request
		$widget->write ($handle, $self->image_pool->{$1}->{body}->as_string);
		$widget->end ($handle,'ok');

	} elsif ( open ($fh, $filename) ) {
		# external file request
		while (<$fh>) {
			$widget->write ($handle, $_);
		}
		close $fh;
		$widget->end ($handle,'ok');

	} else {
		# error reading file
		warn ("can't read $filename");
		$widget->end ($handle,'error');
	}
	
	1;
}

sub begin {
	my $self = shift;
	my %par = @_;
	my ($charset) = $par{'charset'};
	
	$charset ||= "iso-8859-1";

	if ( $self->widget->can ("set_default_content_type") ) {
		$self->widget->set_default_content_type("text/html; charset=$charset");
	}

	$self->handle($self->widget->begin);
	$self->image_pool ({});
	$self->write(
		'<meta http-equiv="content-type" '.
		'content="text/html; charset='.$charset.'">'."\n"
	);

	my $color = $self->config('mail_bgcolor');
	$self->write ("<html><body bgcolor=\"$color\">");

	1;
}

sub end {
	my $self = shift;
	$self->write ('</body></html>');
	$self->widget->end ($self->handle, 'ok');
	1;
}

sub write {
	my $self = shift;
	local $_;
	for (@_) { $self->widget->write ($self->handle, $_) if length($_) }
	1;
}


sub fixed {
	shift->write ('<font face="Courier">'.$_[0].'</font>');
}

sub fixed_start {
	shift->write ('<font face="Courier">');
}

sub fixed_end {
	shift->write ('</font>');
}


sub bold {
	shift->write ('<b>'.$_[0].'</b>');
}

sub bold_start {
	shift->write ('<b>');
}

sub bold_end {
	shift->write ('</b>');
}


sub color {
	shift->write ('<font color="'.$_[0].'">'.$_[1].'</font>');
}

sub color_start {
	shift->write ('<font color="'.$_[0].'">');
}

sub color_end {
	shift->write ('</font>');
}


sub pre {
	shift->write ('<pre><font face="Courier">'.$_[0].'</font></pre>');
}

sub pre_start {
	shift->write ('<pre><font face="Courier">');
}

sub pre_end {
	shift->write ('</font></pre>');
}


sub p {
	shift->write ('<p>');
}

sub br {
	shift->write ('<br>');
}

sub hr {
	shift->write ('<hr width="100%">');
}

sub image {
	my $self = shift;
	my %par = @_;
	my ($pool, $name) = @par{'pool','name'};
	
	if ( $pool ) {
		$self->write ('<a href="pool://'.$pool.'"><img border="0" src="pool://'.$pool.'"></a>');
	} else {
		$self->write ('<a href="'.$name.')"><img border="0" src="'.$name.'"></a>');
	}
	1;
}
1;
