package Gtk2::Ex::FormFactory::Timestamp;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

use Time::Local;

sub get_type { "timestamp" }

sub get_format			{ shift->{format}			}
sub set_format			{ shift->{format}		= $_[1]	}

sub get_gtk_mday_widget		{ shift->{gtk_mday_widget}		}
sub get_gtk_mon_widget		{ shift->{gtk_mon_widget}		}
sub get_gtk_year_widget		{ shift->{gtk_year_widget}		}
sub get_gtk_hour_widget		{ shift->{gtk_hour_widget}		}
sub get_gtk_min_widget		{ shift->{gtk_min_widget}		}

sub set_gtk_mday_widget		{ shift->{gtk_mday_widget}	= $_[1]	}
sub set_gtk_mon_widget		{ shift->{gtk_mon_widget}	= $_[1]	}
sub set_gtk_year_widget		{ shift->{gtk_year_widget}	= $_[1]	}
sub set_gtk_hour_widget		{ shift->{gtk_hour_widget}	= $_[1]	}
sub set_gtk_min_widget		{ shift->{gtk_min_widget}	= $_[1]	}

sub get_gtk_tip_widgets {[
	$_[0]->get_gtk_mday_widget,
	$_[0]->get_gtk_mon_widget,
	$_[0]->get_gtk_year_widget,
	$_[0]->get_gtk_hour_widget,
	$_[0]->get_gtk_min_widget,
]}

sub new {
	my $class = shift;
	my %par = @_;
	my ($format) = $par{'format'};
	
	my $self = $class->SUPER::new(@_);
	
	$format ||= '%d.%m.%Y %k:%M';
	
	$self->set_format($format);
	
	return $self;
}

sub cleanup {
	my $self = shift;
	
	$self->SUPER::cleanup(@_);

	$self->set_gtk_mday_widget(undef); 
	$self->set_gtk_mon_widget(undef);
	$self->set_gtk_year_widget(undef);
	$self->set_gtk_hour_widget(undef);
	$self->set_gtk_min_widget(undef);

	1;
}

sub object_to_widget {
	my $self = shift;
	
	my $format = $self->get_format;

	my $unix_time = $self->get_object_value;

	my @d = localtime($unix_time);

	$self->get_gtk_year_widget->set_text(sprintf("%04d",$d[5]+1900));
	$self->get_gtk_mon_widget->set_text(sprintf("%02d",$d[4]+1));
	$self->get_gtk_mday_widget->set_text(sprintf("%02d",$d[3]));
	$self->get_gtk_hour_widget->set_text(sprintf("%02d",$d[2]));
	$self->get_gtk_min_widget->set_text(sprintf("%02d",$d[1]));

	1;
}

sub get_widget_unix_time {
	my $self = shift;

	my $format = $self->get_format;

	my @d = (0, 0, 0, 1, 0, 0);

	$d[5] = $self->get_gtk_year_widget->get_text-1900
		if $format =~ /%Y/;
	$d[4] = $self->get_gtk_mon_widget->get_text-1
		if $format =~ /%m/;
	$d[3] = $self->get_gtk_mday_widget->get_text
		if $format =~ /%d/;
	$d[2] = $self->get_gtk_hour_widget->get_text
		if $format =~ /%k/;
	$d[1] = $self->get_gtk_min_widget->get_text
		if $format =~ /%M/;

	my $unix_time = eval { timelocal(@d) };

	return "$unix_time";
}

sub widget_to_object {
	my $self = shift;

	my $unix_time = $self->get_widget_unix_time;

	if ( not defined $unix_time ) {
		$self->show_error_message (
			message => $self->get_label." is no valid timestamp",
		);
	} else {
		$self->set_object_value ( $unix_time );
	}
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	my @backup;
	foreach my $type (qw( year mon mday hour min )) {
		my $widget = $self->{"gtk_${type}_widget"};
		if ( $widget ) {
			push @backup, $widget->get_text;
		} else {
			push @backup, undef;
		}
	}
	
	$self->set_backup_widget_value (\@backup);
	
	1;
}

sub restore_widget_value {
	my $self = shift;

	my $backup = $self->get_backup_widget_value;

	my $i;
	foreach my $type (qw( year mon mday hour min )) {
		my $widget = $self->{"gtk_${type}_widget"};
		my $value = $backup->[$i];
		if ( $widget ) {
			$widget->set_text($value);
		}
		++$i;
	}
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_widget_unix_time;
}

sub connect_changed_signal {
	my $self = shift;
	
	$_->signal_connect (
	  changed => sub { $self->widget_value_changed },
	) for ( $self->get_gtk_year_widget,
		$self->get_gtk_mon_widget,
		$self->get_gtk_mday_widget,
		$self->get_gtk_hour_widget,
		$self->get_gtk_min_widget );
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Timestamp - Enter a valid timestamp

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Timestamp->new (
    format    => A format string describing the the time fields
    ...    
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a bunch of text entries to manage a
valid timestamp (date and time down to minute level). The
object value is a unix timestamp (in localtime).

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Timestamp

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

Attributes are handled through the common get_ATTR(), set_ATTR()
style accessors, but they are mostly passed once to the object
constructor and must not be altered after the associated FormFactory
was built.

=over 4

=item B<format> = SCALAR [optional]

This is a format string to define which timestamp fields
should be edited and how they should be displayed.

Format wildcards are defined as follows:

  %Y	Year, four digits
  %m	Month, two digits
  %d	Day of month, two digits
  %k	Hour of the day, two digits
  %M	Minutes, two digits

Everything else in the format string will be rendered as
labels between the time field text entries.

The format string defaults to

  %d.%m.%Y %k:%M

All time fields which are not part of the format string
will get a default value of 0.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

=head1 AUTHORS

 Jörn Reder <joern at zyn dot de>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2006 by Jörn Reder.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Library General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307
USA.

=cut
