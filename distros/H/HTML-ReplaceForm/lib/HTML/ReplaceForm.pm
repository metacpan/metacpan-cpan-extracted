#!/usr/bin/perl

package HTML::ReplaceForm;
use base 'Exporter';
use Carp;
our @EXPORT_OK  = qw(
    replace_form
);
use strict;
use warnings;

our $VERSION = '0.52';

=head1 NAME

HTML::ReplaceForm - easily replace HTML form fields with corresponding values

=head1 SYNOPSIS

  use HTML::ReplaceForm;
 $modified_html = replace_form($html,$data_href);

=head1 DESCRIPTION

This is useful for creating an HTML email message from a web form, while sharing 
a single template that is used for both purposes. 

Keep the form in an include file that is used both on the web and in an email template. 

The real, regular HTML in the form will automatically have the form fields replaced with
corresponding values by the C<replace_form()> function, which you can then use to send 
the HTML email.

=head1 FUNCTIONS

=head2 replace_form

 $modified_html = replace_form($html,$data_href);

Replace form elements with with a hashref of corresponding data.


B<Note:> For now, replace radio and checkboxes with an X if they are marked.
They are troublesome because there are multiple inputs with the same name, and
they have labels next to them.

Args:

 $html       - Any kind of HTML data structure that HTML::TokeParser::Simple accepts 
 $data_href  a hashref of data that corresponds to the form

=cut 

sub replace_form {
    my $html = shift;
    my $data = shift;

    require HTML::TokeParser::Simple;
    my $p = HTML::TokeParser::Simple->new( $html ) || croak $!;

    my $new_html; 
    while ( my $token = $p->get_token ) {
        if ($token->is_tag(qr/(input|textarea|select)/)) {
            no warnings; # 'type' may be undefined. That's OK.
            if ($token->return_attr('type') =~ m/^checkbox$/ ) {
                # If we have a match from the data that matches this value
                if ($token->return_attr('value') eq $data->{ $token->return_attr('name') } ) {
                    # XXX This should be customizable. 
                    $new_html .= '[<strong>X</strong>]';
                }
                else {
                    # delete unchecked elements through neglect
                    $new_html .= '[ ] '
                }
            }
            elsif ($token->return_attr('type') =~ m/^radio$/ ) {
                # If we have a match from the data that matches this value
                if ($token->return_attr('value') eq $data->{ $token->return_attr('name') } ) {
                    # XXX This should be customizable. 
                    $new_html .= '(<strong>X</strong>)';
                }
                else {
                    # delete unchecked elements through neglect
                    $new_html .= '( ) '
                }
            }

            # XXX, there's a probably a bug where the contents of <option> tags needs to be 
            # thrown away, too. 

            # This clause would be needed if the form was refilled first. 
            # For textareas, just through away the tags and leave the contents.
            elsif ( $token->is_tag('textarea') ) {
                    if (my $name = $token->return_attr('name')) {   
                        # This should also be customizable for other templating systems. 
                        $new_html .= qq{<strong>$data->{$name}</strong>};
                        # silently discard any previous contents of the textarea
                        $p->get_tag('/textarea');
                    }
                    else {
                        croak "no name found for: ".$token->as_is;
                    }
            }
            else { 
                if ($token->is_start_tag) {
                    if (my $name = $token->return_attr('name')) {   
                        $new_html .= qq{<strong>$data->{$name}</strong>};
                    }
                    else {
                        croak "no name found for: ".$token->as_is;
                    }
                }         
                else {
                    # just throw away the end tags. 
                }
            }
         }
         # silently discard option tags
         elsif ( $token->is_start_tag('option') ) {
             $p->get_tag('/select');
         }
         else {
            $new_html .= $token->as_is;
         }
    }
    return $new_html;
}

=head2 TODO

There are small bits of HTML design which are currently embedded in here. The user should
have control over these.

 - $data is displayed as <strong>$data</strong>
 - A selected checkbox or radio button is displayed as [<strong>X</strong>]
 - An unselected checkbox or radio button is displayed as  [ ]

=head1 AUTHOR

	Mark Stosberg C<< mark at summersault.com >> 

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

perl(1).

=cut

1;
