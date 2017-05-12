package HTML::FormHandlerX::Form::Contact;

use 5.006;

use strict;
use warnings;

=head1 NAME

HTML::FormHandlerX::Form::Contact - An HTML::FormHandler contact form.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

$VERSION = eval $VERSION;

=head1 SYNOPSIS

You know, that contact form you create day-in, day-out.

From a usability perspective in form design, it is advised to only ask for the minimal information you actually need, don't bombard a user with several fields if all you really need is one.

 use HTML::FormHandlerX::Form::Contact;

 my $form = HTML::FormHandlerX::Form::Contact->new( active => [ qw( name email subject message ) ] );

 $form->process( params => { name    => $name,
                             email   => $email,
                             subject => $subject,
                             message => $message,
                           } );

 if ( $form->validated )
 {
    # do something...
 }

=cut 

use HTML::FormHandler::Moose;

extends 'HTML::FormHandler';

=head1 METHODS

=head2 Fields

All fields will be rendered with a wrapper div with an id of C<< field-<field-name> >>.

If a field is activated, it will be a required field.

This supports the idea of keeping your forms as simple as possible, if you don't need it, don't ask for it.

=head3 name

 $form->field('name');

=cut

has_field name => ( type         => 'Text',
                    required     => 1,
                    messages     => { required => 'Your name is required.' },
                    tags         => { no_errors => 1 },
                    wrapper_attr => { id => 'field-name' },
                    inactive     => 1,
                  );

=head3 email

 $form->field('email');

Validation performed as-per L<Email::Valid>.

=cut

has_field email => ( type         => 'Email',
                     required     => 1,
                     messages     => { required => 'Your email is required.' },
                     tags         => { no_errors => 1 },
                     wrapper_attr => { id => 'field-email' },
                     inactive     => 1,
                   );

=head3 telephone

 $form->field('telephone');

Validation ensures there's a number in this field, but nothing more complicated.

=cut

has_field telephone => ( type         => 'Text',
                         required     => 1,
                         messages     => { required => 'Your telephone number is required.' },
                         tags         => { no_errors => 1 },
                         wrapper_attr => { id => 'field-telephone' },
                         inactive     => 1,
                       );

sub validate_telephone
{
    my ( $self, $field ) = @_;
    
    if ( $field->value !~ /\d/ )
    {
        $field->add_error( "Your telephone number doesn't contain any digits." );
    }
}

=head3 subject

 $form->field('subject');

=cut

has_field subject => ( type         => 'Text',
                       required     => 1,
                       messages     => { required => 'The subject is required.' },
                       tags         => { no_errors => 1 },
                       wrapper_attr => { id => 'field-subject' },
                       inactive     => 1,
                     );

=head3 message

 $form->field('message');

=cut

has_field message => ( type         => 'TextArea',
                       required     => 1,
                       messages     => { required => 'The message is required.' },
                       tags         => { no_errors => 1 },
                       wrapper_attr => { id => 'field-message' },
                       inactive     => 1,
                     );

=head3 submit

 $form->field('submit');

The value of the submit button will be 'Send Message' by default.

=cut

has_field submit => ( type         => 'Submit',
                      value        => 'Send Message',
                      wrapper_attr => { id => 'field-submit', },
                    );

=head2 Instance Methods

=head3 html_attributes

This method has been populated to ensure all fields in error have the C<error> CSS class assigned to the labels.

See L<HTML::FormHandler> for more details.

=cut

sub html_attributes
{
    my ($self, $field, $type, $attr, $result) = @_;
    
    if( $type eq 'label' && $result->has_errors )
    {
        push @{$attr->{class}}, 'error';
    }
}

=head1 AUTHOR

Rob Brown, C<< <rob at intelcompute.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-formhandlerx-form-contact at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-FormHandlerX-Form-Contact>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::FormHandlerX::Form::Contact

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-FormHandlerX-Form-Contact>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-FormHandlerX-Form-Contact>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-FormHandlerX-Form-Contact>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-FormHandlerX-Form-Contact/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Rob Brown.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of HTML::FormHandlerX::Form::Contact

