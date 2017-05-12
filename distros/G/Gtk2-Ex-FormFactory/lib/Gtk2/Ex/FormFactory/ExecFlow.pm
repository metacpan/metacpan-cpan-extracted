package Gtk2::Ex::FormFactory::ExecFlow;

use strict;

use base qw( Gtk2::Ex::FormFactory::Widget );

sub get_type {"execflow"}

sub get_add_columns             { shift->{add_columns}                  }
sub get_path_by_id_href         { shift->{path_by_id_href}              }

sub set_add_columns             { shift->{add_columns}          = $_[1] }
sub set_path_by_id_href         { shift->{path_by_id_href}      = $_[1] }

sub new {
    my $class = shift;
    my %par = @_;
    my ($add_columns) = $par{'add_columns'};

    $add_columns ||= [];

    my $self = $class->SUPER::new(@_);

    $self->set_add_columns($add_columns);

    return $self;
}

sub build_widget {
    my $self = shift;
    
    my $model = Gtk2::TreeStore->new(
        "Glib::String", "Glib::String", "Glib::String",
        ("Glib::String") x @{$self->get_add_columns}
    );
    my $tree_view = Gtk2::TreeView->new_with_model($model);

    for my $i ( 0..1+@{$self->get_add_columns} ) {
        my $column = Gtk2::TreeViewColumn->new_with_attributes(
	        "col$i",
	        Gtk2::CellRendererText->new,
	        'text' => $i < 2 ? $i : $i + 1
        );
        $tree_view->append_column($column);
    }

    $tree_view->set_headers_visible(0);
    $tree_view->set_rules_hint(1);
 
    $self->set_gtk_widget($tree_view);
    
    1;
}

sub empty_widget {
    my $self = shift;

    $self->get_gtk_widget->get_model->clear;
    $self->set_path_by_id_href({});

    1;
}

sub object_to_widget {
    my $self = shift;

    my $job = $self->get_object_value;
    return unless $job;

    $self->empty_widget;
    $self->add_job_to_model($job, undef);

    $self->get_gtk_widget->expand_all;

    1;
}

sub add_job_to_model {
    my $self = shift;
    my ($job, $parent_iter) = @_;
    
    my $model = $self->get_gtk_widget->get_model;
    
    my $iter = $model->append($parent_iter);
    $model->set($iter, 0 => $job->get_info);
    $model->set($iter, 1 => $job->get_progress_stats);
    $model->set($iter, 2 => $job->get_id);

    my $i = 3;
    foreach my $add_col ( @{$self->get_add_columns} ) {
        my $method = "get_$add_col";
        $model->set($iter, $i => $job->$method());
        ++$i;
    }

    my $path = $model->get_path($iter);
    $self->get_path_by_id_href->{$job->get_id} = $path;

    if ( $job->get_type eq 'group' ) {
        foreach my $child_job ( @{$job->get_jobs} ) {
            $self->add_job_to_model($child_job, $iter);
        }
    }

    1;
}

sub update_job {
    my $self = shift;
    my ($job) = @_;

    my $path = $self->get_path_by_id_href->{$job->get_id};
    
    return if !$path;

    my $model = $self->get_gtk_widget->get_model;
    my $iter  = $model->get_iter($path);
    
    $model->set($iter, 0 => $job->get_info);
    $model->set($iter, 1 => $job->get_progress_stats);
    
    my $i = 3;
    foreach my $add_col ( @{$self->get_add_columns} ) {
        my $method = "get_$add_col";
        $model->set($iter, $i => $job->$method());
        ++$i;
    }

    1;
}

sub add_job {
    my $self = shift;
    my ($job) = @_;

    my $group      = $job->get_group;
    my $group_path = $self->get_path_by_id_href->{$group->get_id};

    return $self->add_job_to_model($job) if !$group_path;
    
    my $model = $self->get_gtk_widget->get_model;
    my $iter  = $model->get_iter($group_path);
        
    $self->add_job_to_model($job, $iter);
    
    $self->get_gtk_widget->expand_row($group_path, 0);
    $self->get_gtk_widget->expand_row(
        $self->get_path_by_id_href->{$job->get_id},
        1
    );

    1;
}

sub remove_job {
    my $self = shift;
    my ($job) = @_;

    $self->remove_job_with_id($job->get_id);

    1;
}

sub remove_job_with_id {
    my $self = shift;
    my ($job_id) = @_;

    my $path = $self->get_path_by_id_href->{$job_id};
    my $model = $self->get_gtk_widget->get_model;

    $model->remove($model->get_iter($path));

    $self->rebuild_job_path_index;

    1;
}

sub rebuild_job_path_index {
    my $self = shift;
    
    my %path_by_job_id;
    my $model = $self->get_gtk_widget->get_model;
    
    $model->foreach(sub{
        #-- Storing the Gtk2::TreePath doesn't work here, weird
        #-- stuff happens. So we store the string and turn it
        #-- into a Gtk2::TreePath after the foreach iteration.
        $path_by_job_id{$model->get($_[2],2)} = $_[1]->to_string;
        return 0;
    });

    #-- Turn path strings into Gtk2::TreePath objects
    foreach my $job_id ( sort {$a <=> $b} keys %path_by_job_id ) {
        $path_by_job_id{$job_id} =
            Gtk2::TreePath->new_from_string($path_by_job_id{$job_id});
    }

    $self->set_path_by_id_href(\%path_by_job_id);
    
    1;
}

1;

__END__

=head1 NAME

Gtk2::Ex::FormFactory::ExecFlow - Display a Event::ExecFlow job plan

=head1 SYNOPSIS

  Gtk2::Ex::FormFactory::ExecFlow->new (
    ...
    Gtk2::Ex::FormFactory::Widget attributes
  );

=head1 DESCRIPTION

This class implements a Event::ExecFlow job plan viewer in a
Gtk2::Ex::FormFactory framework using a Gtk2::TreeView to display
the hierarchical job structure.

Besides updating the whole TreeView by assigning a new Event::ExecFlow::Job
object to the widget it offers methods for updating single jobs
efficiently. 

The value of the associated application object attribute is an
Event::ExecFlow::Job object.

=head1 OBJECT HIERARCHY

  Gtk2::Ex::FormFactory::Intro

  Gtk2::Ex::FormFactory::Widget
  +--- Gtk2::Ex::FormFactory::ExecFlow

  Gtk2::Ex::FormFactory::Layout
  Gtk2::Ex::FormFactory::Rules
  Gtk2::Ex::FormFactory::Context
  Gtk2::Ex::FormFactory::Proxy

=head1 ATTRIBUTES

This module has no additional attributes over those derived
from Gtk2::Ex::FormFactory::Widget. 

=back

For more attributes refer to L<Gtk2::Ex::FormFactory::Widget>.

=head1 METHODS

=over 4

=item $widget->B<add_job> ($job)

This adds B<$job> to the widget. If the job is part of a job
group the group must be added already to the widget.

=item $widget->B<update_job> ($job)

Updates the state of B<$job> in the TreeView.

=item $widget->B<remove_job> ($job)

Removes B<$job> from the TreeView.

=item $widget->B<remove_job_with_id> ($job_id)

Use this method to remove a job from the TreeView if you
just know it's ID and don't have a $job object at hand.

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

