package Form::Sensible::Renderer::HTML::RenderedForm;

use Moose; 
use namespace::autoclean;
use Data::Dumper;
use Form::Sensible::DelegateConnection;
use Carp qw/croak/;
use File::ShareDir;

has 'form' => (
    is          => 'rw',
    isa         => 'Form::Sensible::Form',
    required    => 1,
    #weak_ref    => 1,
);

has 'template' => (
    is          => 'rw',
    isa         => 'Template',
    required    => 1,
);

has 'template_fallback_order' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    default     => sub { return [ shift->form->name ]; },
    lazy        => 1,
);

has 'stash' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

has 'css_prefix' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'fs_',
);

has 'form_template_prefix' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    builder     => '_default_form_template_prefix',
    lazy        => 1,
);

has 'subform_renderers' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1
);


has 'status_messages' => (
    is          => 'rw',
    isa         => 'HashRef[ArrayRef]',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

has 'error_messages' => (
    is          => 'rw',
    isa         => 'HashRef[ArrayRef]',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);

has 'render_hints' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { 
                            my $self = shift;
                            return { %{$self->render_hints_for('HTML', $self->form)} };
                       },
    lazy        => 1,
);

has 'display_name_delegate' => (
    is          => 'rw',
    isa         => 'Form::Sensible::DelegateConnection',
    required    => 1,
    default     => sub {
                            return FSConnector( sub { 
                                                my $caller = shift;
                                                my $display_name = shift;
                                                my $origin_object = shift;
                                                
                                                ## by default we simply return what we were given
                                                return $display_name;
                                   });
                   },
    lazy        => 1,
    coerce      => 1,
);

sub _default_form_template_prefix {
    my $self = shift;
    
    my $hints = $self->render_hints_for('HTML', $self->form);
    if (exists($hints->{form_template_prefix})) {
        return $hints->{form_template_prefix};
    } else {
        return 'form';
    }
}

sub render_hints_for {
    my $self = shift;
    
    return Form::Sensible::Renderer->render_hints_for(@_);
}

sub add_status_message {
    my ($self, $message) = @_;
    
    push @{$self->status_messages}, $message;
}

sub add_error_message {
    my ($self, $fieldname, $message) = @_;
    #print "in add_error_message for $message\n";
    if (!exists($self->error_messages->{$fieldname})) {
        $self->error_messages->{$fieldname} = [];
    }
    push @{$self->error_messages->{$fieldname}}, $message;
}

sub add_errors_from_validator_result {
    my ($self, $validator_result) = @_;
    
    foreach my $field ($self->form->fieldnames) {
        if (exists($validator_result->error_fields->{$field})) {
            foreach my $message (@{$validator_result->error_fields->{$field}}) {
                $self->add_error_message($field, $message);
            }
        }
        if (exists($validator_result->missing_fields->{$field})) {
            foreach my $message (@{$validator_result->missing_fields->{$field}}) {
                $self->add_error_message($field, $message);
            }
        }
    }
}

## render form start using $action as our form action
sub start {
    my ($self, $action, $method) = @_;
    
    if (!$method) {
        $method = 'post';
    }
    my $vars = {
                    'form'  => $self->form,
                    'method' => $method,
                    'action' => $action,
               };

    if ($self->form->render_hints->{'display_name'}) {
        $vars->{'form_display_name'} = $self->display_name_delegate->($self, $self->form->render_hints->{'display_name'}, $self->form);
    }
    my $output;
    $self->process_first_template($vars, \$output, $self->form_template_prefix . '_start');

    return $output;
}

## render all messages - mostly just passes status/error messages to the messages template.
sub messages {
    my ($self, $additionalmessages) = @_;
    
    ## if we haven't already added error_messages and we have a validator_result in the form
    ## then we add the errors immediately before processing.
    if ((!scalar keys %{$self->error_messages}) && defined($self->form->validator_result)) {
        $self->add_errors_from_validator_result($self->form->validator_result);
    }
    
    my $output;
    $self->process_first_template({}, \$output, $self->form_template_prefix . '_messages');
    
    return $output;
}

## return the form field names.
sub fieldnames {
    my ($self) = @_;
    
    return @{$self->form->fieldnames};
}

## render all the form fields in the order provided by the form object.
sub fields {
    my ($self, $manual_hints) = @_;

    my @rendered_fields;
    foreach my $field (@{$self->form->field_order}) {
        my $new_hints = { %{$manual_hints || {}} };
        if ($manual_hints && exists($manual_hints->{$field})) {
            $new_hints = $manual_hints->{$field};
        }
        my $rendered_field = $self->render_field($field, $new_hints);
        push @rendered_fields, $rendered_field;
    }
    return join("\n",@rendered_fields);
}

sub render_field {
    my ($self, $fieldname, $manual_hints) = @_;

    my $field = $self->form->field($fieldname);
    my $fieldtype = $field->field_type;
    
    if (exists($self->subform_renderers->{$fieldname})) {
        ## handle fields that are subforms.  
        return $self->subform_renderers->{$fieldname}->complete(undef, $manual_hints);
    } else {
        my %custom_vars = %{$manual_hints->{stash_vars} || {}};
        my $vars =  {
                        'form'  => $self->form,
                        'field' => $field,
                        'field_name' => $fieldname,
                        'field_display_name' => $self->display_name_delegate->($self, $field->display_name, $field),
                        %custom_vars,
                    };
        
        ## if we have field-specific render_hints, we have to add them
        ## ourselves.  First we check any already-set render_hints,
        ## Then, check render_hints for this renderer
        ## Then, any manual hints added in the template.
        $vars->{render_hints} = { %{$self->render_hints}, %{$self->render_hints_for('HTML', $field)}, %{$manual_hints||{}} };

        if (exists($self->error_messages->{$fieldname}) && 
            ref($self->error_messages->{$fieldname}) eq 'ARRAY' &&
            $#{$self->error_messages->{$fieldname}} > -1) {
                $vars->{has_errors} = 1;
        }
        
        if (exists($self->status_messages->{$fieldname}) && 
            ref($self->status_messages->{$fieldname}) eq 'ARRAY' &&
            $#{$self->status_messages->{$fieldname}} > -1) {
                $vars->{has_status_messages} = 1;
        }
        
        ## allow render_hints to override field type - allowing a number to be rendered
        ## as a select with a range, etc.  also allows text to be rendered as 'hidden'  
        if (exists($vars->{'render_hints'}) && exists($vars->{'render_hints'}{'field_type'})) { 
            $fieldtype = $vars->{'render_hints'}{'field_type'};
        }
        
        $vars->{'field_type'} = $fieldtype;
        
        ## Order for trying templates should be:
        ## formname/fieldname_field
        ## formname/fieldtype
        ## fieldname_field
        ## fieldtype

        my $output;
        
        my $wrapper = "field_wrapper.tt";
        if (exists($vars->{'render_hints'}->{'field_wrapper'})) {
            $wrapper = $vars->{'render_hints'}->{'field_wrapper'};
        }
        if ($wrapper) {
            $vars->{'FS_wrapper'} = $wrapper;
        }
        
        $self->process_first_template($vars, \$output, $fieldname . "_field", $fieldtype );
        
        # this code exists to retain compatibility with the old 'wrap_fields_with' field wrapping.
        # The old 'wrap_fields_with' wrapped the entire rendered field with label.  This is inappropriate
        # in most cases and thus it has been replaced with real Template::Toolkit WRAPPER functionality.
        # This code exists ONLY for backwards compatibility and will be removed.
        if (exists($vars->{'render_hints'}->{'wrap_fields_with'})) {
           # Have to prevent re-wrapping of the wrapper provided.
           $vars->{'FS_wrapper'} = undef;
           my $wrapper_output;
           my %wrapper_vars = ( %{$vars}, field_output => $output );
           $self->process_first_template(\%wrapper_vars, \$wrapper_output, $vars->{'render_hints'}->{'wrap_fields_with'} );
           return $wrapper_output;
        } 
        
        return $output;
        
    }
}

## pass in the vars / output / template_names to use.  This method handles automatic fallback
## of templates from most specific to least specific.  

sub process_first_template {
    my $self = shift;
    my $vars = shift;
    my $output = shift;
    my @template_names = @_;
    
    ## prefill anything provided already into the stash
    my $stash_vars = { %{$self->stash } };
    
    if (!exists($stash_vars->{'render_hints'})) {
        $stash_vars->{'render_hints'} = $self->render_hints;
    }
    
    $stash_vars->{'form'} = $self->form;
    $stash_vars->{'error_messages'} = $self->error_messages;
    $stash_vars->{'status_messages'} = $self->status_messages;
    $stash_vars->{'css_prefix'} = $self->css_prefix;
    
    ## copy the vars array into the stash_vars
    foreach my $key (keys %{$vars}) {
      $stash_vars->{$key} = $vars->{$key};  
    } 
                         
    my @templates_to_try;
    
    foreach my $path (@{$self->template_fallback_order}) {
        foreach my $template_name (@template_names) {
            push @templates_to_try, $path . '/' . $template_name;
        }
    }
    
    push @templates_to_try, @template_names;
    
    my $template_found = 0;
    foreach my $template_name (@templates_to_try) {
        if ($template_name !~ /.tt$/) {
            $template_name .= '.tt';
        }
        my $res = $self->template->process($template_name, $stash_vars, $output);
        if ($res) {
            $template_found = 1;
            last;
        } else {
            my $error = $self->template->error();
            if ($error->info =~ /parse error/) {
                croak 'Error processing ' . $template_name . ': ' . $error;
            }
        }
    }
    
    if (!$template_found) {
        ## crap.  throw an error or something, we couldn't find ANY matching template.
#        croak "Unable to find any template for processing, tried: " . join(", ", @templates_to_try) . " in " . join(':',@{$self->template});
    }
    return $output;
}

## render end of form.  Probably just </form> most of the time.
sub end {
    my ($self) = @_;
    
    my $output;
    
    $self->process_first_template({}, \$output, $self->form_template_prefix . '_end');

    return $output;
}

sub complete {
    my ($self, $action, $method, $manual_hints) = @_;
    
    return join('', $self->start($action, $method), $self->messages, $self->fields($manual_hints), $self->end);
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Renderer::HTML::RenderedForm - A rendered form handle for HTML

=head1 SYNOPSIS

    use Form::Sensible::Renderer::HTML;

    my $renderer = Form::Sensible::Renderer::HTML->new();

    my $renderedform = $renderer->render($form);
    
    print $renderedform->complete('/myform/submit', 'POST');
    

=head1 DESCRIPTION

The Form::Sensible::Renderer::HTML::RenderedForm class defines the result of 
rendering a form as HTML.  It is not generally created directly, but rather is created
by passing a form to the L<Form::Sensible::Renderer::HTML> C<render()> mathod.

=head1 ATTRIBUTES

=over 8

=item C<stash>

The stash used for the template processing.  Additional information is added
to this stash automatically during field and form processing.

=item C<css_prefix>

This is applied to all html element CSS id's and class names.  By default, 
css_prefix is set to C<fs_> 

=item C<render_hints>

Render hints provide information on how to render certain aspects of the form
or field. The usage depends upon the field type in question. The information
is passed through to the field-specific templates as 'render_hints' during
processing.

A hint that is specific to the HTML renderer is C<stash_vars>, this should be
a hash and will be passed to the templates as they are rendered.

    {
        stash_vars => {
            user_prefs => $user_prefs
        }
    }

For example in the this case, C<$user_prefs> could be accessed in any
of the templates (form_start.tt, text.tt etc) as C<[% user_prefs %]>.

Another is C<field_wrapper> which should be the name of a template to act
as a wrapper for each individual field template. This can be useful if each
field has common HTML and only the actual field element changes. For example
in this case:

    {
        field_wrapper => 'field_wrapper_file'
    }

A template called C<field_wrapper_file.tt> will be used. The C<field_wrapper>
hint overrides the built-in wrapper, so only the actual input field will be available
and you will need to provide any enclosing elements or labels.  Note also that it 
uses the standard L<Template|Template::Toolkit> C<WRAPPER> mechanism.  Thus the field wrapper
template will be rendered, and the actual input elements will be available as
C<< [% content %] >> within your wrapper template. So your wrapper template
might end up looking like:

    <tr class="form-row">
      <td>[% field.display_name %]</td>
      <td>[% content %]</td>
    </tr>

For more information on render_hints, see L<Form::Sensible::Overview>.

Note that 'wrap_fields_with' has been deprecated and will be removed in a 
future release.

=item C<status_messages>

An array ref containing the status messages to be displayed on the form.

=item C<error_messages> 

An array ref containing the error messages to be displayed on the form. 

=item C<form_template_prefix>

Non-field related template names are prefixed with this value.  The three
templates used for each form are:  C<start>, C<messages>, and C<end>, 
The default value for C<form_template_prefix> is 'form', so by default
the form templates used are: C<form_start.tt,> 
C<form_messages.tt,> and C<form_end.tt.>

=item C<subform_renderers> has

This contains the references to subform renderers.  Subform rendering is
experimental and is still subject to changes.  It's probably best to leave
this attribute alone for now.

=item C<form> 

A reference to the L<form|Form::Sensible::Form> object that is being rendered.  

=item C<template> 

The template toolkit object to be used to process the templates.  This is 
normally set up prior to rendering and should only be changed if you know 
what you are doing.  In other words, unless you've read the source, it's 
a good idea to leave this alone.

=item C<template_fallback_order>

An array ref containing the order to seek for overriding templates for 
all elements of form rendering. By default, a subdirectory named 
after the C<< $form->name >> is searched first, then the root 
template directory is searched.

=back

=head1 METHODS

=over 8

=item C<add_status_message($message)>

Adds $message to the status messages to be displayed.

=item C<add_error_message($fieldname, $message)>

Adds the error message provided in C<$message> to the 
list of error messages to be displayed. The error message 
is associated with the C<$fieldname> given.

=item C<add_errors_from_validator_result($validator_result)>

Inspects $validator_result and adds any messages found to the
list of errors to be displayed on the form.

=item C<start($action, $method)>

This renders the start of the form and sets it to be 
submitted to the url provided in C<$action>.  C<$action> 
is placed directly in to the C<action> attribute of the 
C<form> element.  Returns the rendered HTML as a string.

=item C<messages()>

This renders the messages portion of the form.  Often (and by default)
this is displayed before the form fields. Returns the rendered messages 
html as a string.

=item C<render_field($fieldname, $render_hints)> 

Renders the field matching C<$fieldname> and returns the rendered HTML for the
field.  If the C<$render_hints> hashref is provided, it will be merged into 
any previously set render hints for the field.  When a key conflict occurs the
passed C<$render_hints> will override any existing configuration.

=item C<fields($manual_hints)>

A shortcut routine that renders all the fields in the form.  Returns all of the fields
rendered as a single string.

=item C<end> sub

Renders the end of the form. Returns the rendered html as a string.

=item C<fieldnames()> 

Returns an array containing the fieldnames in the form (in their render order)

=item C<complete($action, $method, $manual_hints)>

Renders the entire form and returns the rendered results.  Calling 
C<<$form->complete($action, $method) >> routine is functionally 
equivalent to calling:

 $form->start($action, $method) . $form->messages() . $form->fields() . $form->end();

=back

=head2 DELEGATE CONNECTIONS

=over 4

=item display_name_delegate: ($caller, $display_name, $field_or_form_object)

The C<display_name_delegate> provides a hook to allow for localization of form and 
field names.  It is passed the field or form name as well as the field or form object
and is expected to return the translated name.  It is important to return a value.  If 
you are unable to translate the name, returning the passed name unchanged is encouraged.

=back


=head1 AUTHOR

Jay Kuri - E<lt>jayk@cpan.orgE<gt>

=head1 SPONSORED BY

Ionzero LLC. L<http://ionzero.com/>

=head1 SEE ALSO

L<Form::Sensible>

=head1 LICENSE

Copyright 2009 by Jay Kuri E<lt>jayk@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
