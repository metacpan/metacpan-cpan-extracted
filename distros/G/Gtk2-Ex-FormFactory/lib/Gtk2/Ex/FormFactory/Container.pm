package Gtk2::Ex::FormFactory::Container;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_content			{ shift->{content}			}
sub get_title			{ shift->{title}			}

sub set_content			{ shift->{content}		= $_[1]	}
sub set_title			{ shift->{title}		= $_[1]	}

sub isa_container		{ 1 }

sub new {
	my $class = shift;
	my %par = @_;
	my ($content, $title) = @par{'content','title'};
	
	my $self = $class->SUPER::new(@_);

	#-- Handle some defaults for 'content' parameter
	if ( not defined $content ) {
		$content = [];
	} elsif ( ref $content ne 'ARRAY' ) {
		$content = [ $content ];
	}
	
	#-- For convenience the developer may write pairs of
	#-- the Widget's short name and a hash ref with its
	#-- attributes instead of adding real objects. This
	#-- loop search for such non-objects and creates
	#-- objects accordingly.
	my @content_with_objects;
	for ( my $i=0; $i < @{$content}; ++$i ) {
		if ( not defined $content->[$i] ) {
		  die "Child #$i of ".$self->get_type."/".$self->get_name.
		      " is not defined";
		}
		if ( not ref $content->[$i] ) {
			#-- No object, so derive the class name
			#-- from the short name
			my $class = $content->[$i];
			$class =~ s/^(.)/uc($1)/e;
			$class =~ s/_(.)/uc($1)/eg;
			$class =~ s/_//g;
			$class = "Gtk2::Ex::FormFactory::$class";
			
			#-- And create the object
			my $object = $class->new(%{$content->[$i+1]});
			push @content_with_objects, $object;
			
			#-- Skip next entry in @content
			++$i;

		} else {
			#-- Regular objects are taken as is
			push @content_with_objects, $content->[$i];
		}
	}
	
	$self->set_content(\@content_with_objects);
	$self->set_title($title);

	return $self;
}

sub debug_dump {
    my $self = shift;
    my ($level) = @_;

    $self->SUPER::debug_dump($level);

    foreach my $c ( @{$self->get_content} ) {
        if ( $c ) {
            $c->debug_dump($level+1);
        }
        else {
            print "  "x($level+1),"UNDEF\n";
        }
    }

    1;
}

sub build {
	my $self = shift;

	#-- First build the widget itself
	$self->SUPER::build(@_);
	
	#-- Now build the children
	$self->build_children;

	1;
}

sub build_children {
	my $self = shift;
	
	$Gtk2::Ex::FormFactory::DEBUG &&
		print "$self->build_children\n";

	my $layouter = $self->get_form_factory->get_layouter;

	foreach my $child ( @{$self->get_content} ) {
		$child->set_parent($self);
		$child->set_form_factory($self->get_form_factory);
		$child->build;
		$layouter->add_widget_to_container ($child, $self);
	}
	
	1;	
}

sub add_child_widget {
	my $self = shift;
	my ($child) = @_;

	push @{$self->get_content}, $child;

	return unless $self->get_built;

        my $form_factory = $self->get_form_factory;
	my $layouter     = $form_factory->get_layouter;

        $form_factory->register_all_widgets($child);

	$child->set_parent($self);
	$child->set_form_factory($form_factory);
	$child->build;

	$layouter->add_widget_to_container($child, $self);

	$child->connect_signals;
	$child->update_all;
	$child->get_gtk_parent_widget->show_all;

	1;
}

sub remove_child_widget {
	my $self = shift;
	my ($child) = @_;
	
	my $found;
	my $i = 0;
	foreach my $c ( @{$self->get_content} ) {
		$found = 1, last if $c eq $child;
		++$i;
	}

	die "Widget '".$child->get_name.
	    "' no child of container '".
	    $self->get_name."'" unless $found;

	splice @{$self->get_content}, $i, 1;
	
	return unless $self->get_built;

	my $child_gtk_widget = $child->get_gtk_parent_widget;
	my $gtk_widget       = $self->get_gtk_widget;
	
	$gtk_widget->remove($child_gtk_widget);

	$child->cleanup;

	1;	
}

sub update_all {
	my $self = shift;
	
	$self->SUPER::update(@_);
        foreach my $c ( @{$self->get_content} ) {
            $c->update_all;
        }
	
	1;
}

sub apply_changes_all {
	my $self = shift;
	
	$self->SUPER::apply_changes(@_);
        
        foreach my $c ( @{$self->get_content} ) {
            $c->apply_changes_all;
        }
	
	1;
}

sub commit_proxy_buffers_all {
	my $self = shift;
	
	$self->SUPER::commit_proxy_buffers(@_);

        foreach my $c ( @{$self->get_content} ) {
            $c->commit_proxy_buffers_all;
        }
	
	1;
}

sub discard_proxy_buffers_all {
	my $self = shift;
	
	$self->SUPER::discard_proxy_buffers(@_);

        foreach my $c ( @{$self->get_content} ) {
            $c->discard_proxy_buffers_all;
        }
	
	1;
}

sub connect_signals {
	my $self = shift;
	
	$self->SUPER::connect_signals(@_);

        foreach my $c ( @{$self->get_content} ) {
            $c->connect_signals;
        }
	
	1;
}

sub cleanup {
	my $self = shift;
	
        foreach my $c ( @{$self->get_content} ) {
            $c->cleanup;
        }

	$self->SUPER::cleanup(@_);

	$self->set_content([]);

	1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::Container - A container in a FormFactory framework

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::Container->new (
    title      => Visible title of this container,
    content    => [ List of children ],
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This is an abstract base class for all containers in the
Gtk2::Ex::FormFactory framework.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::Container
       +--- Gtk2::Ex::FormFactory::Buttons
       +--- Gtk2::Ex::FormFactory::Expander
       +--- Gtk2::Ex::FormFactory::Form
       +--- Gtk2::Ex::FormFactory::HBox
       +--- Gtk2::Ex::FormFactory::Notebook
       +--- Gtk2::Ex::FormFactory::Table
       +--- Gtk2::Ex::FormFactory::VBox
       +--- Gtk2::Ex::FormFactory::Window

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

=item B<title> = SCALAR [optional]

Each container may have a title. How this title actually is rendered
depends on the implementation of a particular container resp.
the implementation of this container in Gtk2::Ex::FormFactory::Layout.
Default is to draw a frame with this title around the container
widget.

=item B<content> = ARRAYREF of Gtk2::Ex::FormFactory::Widget's [optional]

This is a reference to an array containing the children of this container.

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

=head1 METHODS

=over 4

=item $container->B<add_child_widget> ( $widget )

With this method you add a child widget to a container widget.
If the container actually wasn't built yet the widget
is just appended to the content list of the container
and will be built later together with the container.

Otherwise the widget will be built, shown and updated, so
adding widgets at runtime is no problem.

=item $container->B<remove_child_widget> ( $widget )

Removes a child widget from this container. If the container
is built the widget will be destroyed completely and the $widget
reference may not be used furthermore.

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
