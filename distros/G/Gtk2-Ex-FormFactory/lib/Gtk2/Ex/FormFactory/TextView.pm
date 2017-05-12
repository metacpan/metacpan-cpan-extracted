package Gtk2::Ex::FormFactory::TextView;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type { "text_view" }

sub get_parse_tags              { shift->{parse_tags}                   }
sub set_parse_tags              { shift->{parse_tags}           = $_[1] }

sub new {
	my $class = shift;
	my %par = @_;
	my  ($scrollbars, $properties, $parse_tags) =
        @par{'scrollbars','properties','parse_tags'};
	
	my $self = $class->SUPER::new(@_);
	
	$scrollbars ||= [ "automatic", "automatic" ];

	if ( not $properties or not exists $properties->{wrap_mode} ) {
		$properties->{wrap_mode} = "word-char";
	}

	$self->set_scrollbars ($scrollbars);
	$self->set_properties ($properties);
	$self->set_parse_tags ($parse_tags);
	
	return $self;
}

sub object_to_widget {
	my $self = shift;

        if ( not $self->get_parse_tags ) {
            $self->get_gtk_widget->get_buffer->set_text($self->get_object_value);
            return;
        }

        my $buffer = $self->get_gtk_widget->get_buffer;
        $buffer->set_text("");
        my $iter   = $buffer->get_end_iter;
        
        my $text = $self->get_object_value;
        
        my $processed = 0;
        while ( $text =~ m!(.*?)(<tag\s+name=["'])(.*?)(["']\s*>)(.*?)(</tag>)!sg ) {
            my ($pre, $tag_open, $tag_name, $tag_rest, $content, $tag_close) =
                ($1, $2, $3, $4, $5, $6);
            $processed += length($1.$2.$3.$4.$5.$6);
            $buffer->insert($iter, $pre);
            $buffer->insert_with_tags_by_name($iter, $content, $tag_name);
        }
        
        my $rest = substr($text, $processed);

        $buffer->insert($iter, $rest);

	1;
}

sub widget_to_object {
	my $self = shift;
	
	my $buffer = $self->get_gtk_widget->get_buffer;
	
	$self->set_object_value (
		$buffer->get_text(
			$buffer->get_start_iter,
			$buffer->get_end_iter,
			1,
		)
	);
	
	1;
}

sub empty_widget {
	my $self = shift;
	
	$self->get_gtk_widget->get_buffer->set_text("");
	
	1;
}

sub backup_widget_value {
	my $self = shift;
	
	my $buffer = $self->get_gtk_widget->get_buffer;
	
	$self->set_backup_widget_value (
		$buffer->get_text(
			$buffer->get_start_iter,
			$buffer->get_end_iter,
			1,
		)
	);
	
	1;
}

sub restore_widget_value {
	my $self = shift;
	
	$self->get_gtk_widget
	     ->get_buffer
	     ->set_text($self->get_backup_widget_value);
	
	1;
}

sub get_widget_check_value {
	$_[0]->get_gtk_widget->get_buffer->get_text;
}

sub connect_changed_signal {
	my $self = shift;

	$self->get_gtk_widget->get_buffer->signal_connect (
	  changed => sub { $self->widget_value_changed },
	);
	
	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::TextView - A TextView in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::TextView->new (
    parse_tags      => Boolean to indicate tag markup in value,
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a TextView in a Gtk2::Ex::FormFactory framework.
The content of the TextView is the value of the associated application
object attribute.

By default the TextView gets automatic horizontal and vertical scrollbars
and word wrapping enabled, unless you specify your own values for these
settings.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::TextView

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

=item B<parse_tags> = Boolean [optional]

Set this to a true value to indicate the value of this widget
contains tag markup. The syntax of tag markup is as follows:

  <tag name="TAGNAME">Some text</tag>
  <tag name='TAGNAME'>Some text</tag>

Text with this markup will get the correspondent GtkTextView tag
applied. Please refer to the Gtk2 documentation of GtkTextTagTable
to learn more about tags. Use a B<customize_hook> of your
Gtk2::Ex::FormFactory::TextView objekt to attach a custom tag table
to this widget.

=back

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
