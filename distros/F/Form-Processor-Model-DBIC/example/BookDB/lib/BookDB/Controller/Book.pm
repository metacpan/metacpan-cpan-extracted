package BookDB::Controller::Book;

use strict;
use base 'Catalyst::Controller';
use DateTime;
use BookDB::Form::Book;

=head1 NAME

BookDB::Controller::Book

=head1 SYNOPSIS

See L<BookDB>

=head1 DESCRIPTION

Book Controller 

=head1 METHODS

=over 4

=item add

Sets a template.

=cut

sub add : Local {
    my ( $self, $c ) = @_;

	$c->forward('form');
}


=item form

Handles displaying and validating the form
Will save to the database on validation

=cut

sub form : Private {
    my ( $self, $c, $id ) = @_;

	# Name template, otherwise it will use book/add.tt or book/edit.tt
	$c->stash->{template} = 'book/form.tt';

	# Name form, otherwise it will create 'Book::Add' or 'Book::Edit'
	my $validated = $c->update_from_form( $id, 'Book' ); 

    return if !$validated; # This (re)displays the form, because it's the
            	           # 'end' of the method, and the 'default end' action
					       # takes over, which is to render the view

	# get the new book that was just created by the form
	my $new_book = $c->stash->{form}->item;

	# redirect to list. 'show' also a possibility...
    $c->res->redirect($c->uri_for('list'));
}

=item form (without Catalyst plugin)

Handles displaying and validating the form without Catalyst
Will save to the database on validation
You must either put values into your HTML: value="[% form.fif.title %]"
or set up FillInForm. In your forms, "object_class" should be your
Result class, instead of the Catalyst <model><source_name>.

=cut

=pod

sub form : Private 
{
    my ( $self, $c, $id ) = @_;

    my $form = BookDB::Form::Book->new(item_id => $id, schema => $c->model('DB')->schema);
    # put form and template in stash
    $c->stash->{form} = $form;
	$c->stash->{template} = 'book/form.tt';
    $c->forward('View::TT');

    # update form
    $form->update_from_form( $c->req->parameters );
    return unless $c->req->method eq 'POST' && $form->validated;

	# get the new book that was just created by the form
	my $new_book = $form->item;
	# redirect to list. 
    $c->res->redirect($c->uri_for('list'));
}

=cut

=item default

Forwards to list.

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

=item destroy

Destroys a row and forwards to list.

=cut

sub destroy : Local {
    my ( $self, $c, $id ) = @_;

	# delete row in database
	$c->model('DB::Book')->find($id)->delete;
	# redirect to list page
    $c->res->redirect($c->uri_for('list'));
}

=item edit

Display edit form

=cut

sub edit : Local {
    my ( $self, $c, $id ) = @_;
    
	$c->forward('form/' . $id);
}


=item list

Lists books

=cut

sub list : Local {
    my ( $self, $c ) = @_;

    # get an array of row objects
    my $books = [$c->model('DB::Book')->all];
	# set columns in order wanted for list
    my @columns = ('title', 'author', 'publisher', 'year');

	$c->stash->{books} = $books;
	$c->stash->{columns} = \@columns;
    $c->stash->{template} = 'book/list.tt';
}

=item view

Fetches a row and sets a template.

=cut

sub view : Local {
    my ( $self, $c, $id ) = @_;

	$c->stash->{template} = 'book/view.tt';

	my $validated = $c->update_from_form( $id, 'BookView' );
	return if !$validated;

	# form validated
    $c->stash->{message} = 'Book checked out';
}

=item do_return

=cut

sub do_return : Local {
    my ( $self, $c, $id ) = @_;

	$c->stash->{item} = $c->model('DB::Book')->find($id);
    $c->stash->{item}->borrowed(undef);
    $c->stash->{item}->borrower(undef);
    $c->stash->{item}->update;

	$c->res->redirect($c->uri_for('view', $id));
}

=item
=cut


=back

=head1 AUTHOR

Gerda Shank

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
