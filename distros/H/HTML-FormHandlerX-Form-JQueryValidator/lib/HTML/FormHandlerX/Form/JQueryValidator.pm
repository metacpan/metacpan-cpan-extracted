package HTML::FormHandlerX::Form::JQueryValidator;
use strict;
use warnings;

=head1 NAME

HTML::FormHandlerX::Form::JQueryValidator - Perl trait for HTML::FormHandler and JQuery Validator

=head1 VERSION

0.05

=cut

our $VERSION = '0.05';


use JSON;
use URI::Escape;

use Moose::Role;

=head1 SYNOPSIS

 use HTML::FormHandler::Moose;

 with HTML::FormHandlerX::Form::JQueryValidator;

 ...

 $form->to_jquery_validation_profile();

 ....

    <input type="hidden" id="validation_json" value="[% form.as_escaped_json %]">

    <script>
    var validationJSON = JSON.parse(decodeURIComponent($("#validation_json").val() ) );

    $("#story_form").validate({
                rules: validationJSON.rules,
                   highlight: function(label) {
                    $(label).closest('.control-group').addClass('error');
                },
                messages: validationJSON.messages,
                success: function(label) {
                    label
                        .text('OK!').addClass('valid')
                        .closest('.control-group').addClass('success');
                }
            });
     });
     </script>

=head1 DESCRIPTION

This perl role allows you to re-use some form validation rules with the
 JQuery Validation plugin (http://docs.jquery.com/Plugins/Validation)

=cut

=head1 METHODS

=head2 to_jquery_validation_profile

Object method, takes no arguments.

Returns as hashref holding a hash of rules and another of messages for the JQuery Validation plugin, based on the form fields of the object.

=cut

sub to_jquery_validation_profile {
    my $self = shift;

    my $js_profile = { rules => {}, messages => {} };
    foreach my $field ( @{$self->fields}) {
        my $field_rule = { };
        if ($field->required) {
            $field_rule->{required} = 1;
            $js_profile->{messages}{$field->id} = $self->_localize($field->get_message('required'), $field->loc_label);
        }
        if (lc($field->type) eq 'email') {
            $field_rule->{email} = 1;
        }
        if (lc($field->type) eq 'hour') {
            $field_rule->{range} = [0,23];
        }
        if (lc($field->type) eq 'minute' or lc($field->type) eq 'second' ) {
            $field_rule->{range} = [0,59];
        }
        if (lc($field->type) eq 'hour') {
            $field_rule->{range} = [0,23];
        }
        if (lc($field->type) eq 'month') {
            $field_rule->{range} = [1,12];
        }
        if (lc($field->type) eq 'monthday') {
            $field_rule->{range} = [1,31];
        }
        if (lc($field->type) =~ 'url') {
            $field_rule->{url} = 1;
        }
        $js_profile->{rules}{$field->id} = $field_rule;
    }
    return $js_profile;
}

=head2 as_escaped_json

Object method, takes no arguments.

Returns the jquery validation profile as a URI escaped json string, allowing it to be stashed
in a hidden form field and extracted by javascript for use with JQuery Validation plugin

=cut

sub as_escaped_json {
    my $self = shift;
    my $js_profile = $self->to_jquery_validation_profile;
    return uri_escape_utf8(JSON->new->encode($js_profile)),
}


=head1 SEE ALSO

=over 4

=item http://alittlecode.com/files/jQuery-Validate-Demo/

=item http://docs.jquery.com/Plugins/Validation

=item HTML::FormHandler

=item Twitter Bootstrap

=item examples/ dir in source code

=back

=head1 AUTHOR

Aaron Trevena, E<lt>teejay@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Aaron Trevena

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
