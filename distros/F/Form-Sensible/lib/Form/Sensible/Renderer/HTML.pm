package Form::Sensible::Renderer::HTML;

use Moose; 
use namespace::autoclean;
use Template;
use Data::Dumper;
use Form::Sensible::Renderer::HTML::RenderedForm;
extends 'Form::Sensible::Renderer';

has 'include_paths' => (
    is          => 'rw',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    lazy        => 1,
    builder     => '_build_include_path',
);

has 'additional_include_paths' => (
    is        => 'rw',
    isa       => 'ArrayRef[Str]',
    required  => 1,
    lazy      => 1,
    default   => sub { return []; },
    # additional options
);


has 'base_theme' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => 'default'
);


has 'tt_config' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub {
                              my $self = shift;
                              return {
                                      INCLUDE_PATH => $self->complete_include_path(),
                                      WRAPPER => 'pre_process.tt'
                              }; 
                         },
    lazy        => 1,
);

has 'fs_template_dir' => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
    default     => sub { File::ShareDir::dist_dir('Form-Sensible') . '/templates' },
    lazy        => 1,
);


## if template is provided, it will be re-used.  
## otherwise, a new one is generated for each form render.
has 'template' => (
    is          => 'rw',
    isa         => 'Template',
);

has 'default_options' => (
    is          => 'rw',
    isa         => 'HashRef',
    required    => 1,
    default     => sub { return {}; },
    lazy        => 1,
);


sub render {
    my ($self, $form, $stash_prefill, $options) = @_;
    
    my $template_options = $self->default_options;
    
    # steps
    # use or create Template object with options
    # merge stash prefill
    # create RenderedForm object
    # setup RenderedForm object
    # return renderedForm object

    if (!defined($stash_prefill)) {
        $stash_prefill = {};
    }
    my $form_specific_stash = { %{$stash_prefill} };
    
    my $template = $self->template;
    
    ## if there is no $self->template - we have to 
    ## create one, but we don't keep it if we create it,
    ## we just use it for this render.
    if (!defined($template)) {
        $template = $self->new_template( $options->{additional_tt_options} );
    }
    
    my %args = (
                    template => $template,
                    form => $form,
                    stash => $form_specific_stash,
                );

    # load up default options.
    foreach my $key (keys %{$template_options}) {
        $args{$key} = $template_options->{$key};
    }
    
    if (ref($options) eq 'HASH') {
        foreach my $key (keys %{$options}) {
            $args{$key} = $options->{$key};
        }
    }
    
    ## take care of any subforms we have in this form.
    my $subform_init_hash = { %args };
    $args{'subform_renderers'} = {};
    foreach my $field ($form->get_fields()) {
        my $fieldname = $field->name();
        if ($field->isa('Form::Sensible::Field::SubForm')) {
            $subform_init_hash->{'form'} = $field->form;
            #print "FOO!! $fieldname\n";
            $args{'subform_renderers'}{$fieldname} = Form::Sensible::Renderer::HTML::RenderedForm->new( $subform_init_hash );
            #print Dumper($args{'subform_renderers'}{$fieldname});
            
            ## dirty hack for now.  If we have subforms, then we automatically assume we have to be
            ## multipart/form-data.  What we should do is check all the subforms... but we aren't doing that at this point.
            $args{'stash'}{'form_enctype'} = 'multipart/form-data'
        } elsif ($field->isa('Form::Sensible::Field::FileSelector')) {
            $args{'stash'}{'form_enctype'} = 'multipart/form-data';
        }
    }
    
    my $rendered_form = Form::Sensible::Renderer::HTML::RenderedForm->new( %args );
    
    return $rendered_form;
}

sub _build_include_path {
    my $self = shift;
    
    my $path = [];
    if ($self->base_theme ne 'default') {
        push @{$path}, $self->path_to_theme();
    }
    push @{$path}, $self->path_to_theme('default');
    return $path;
}

sub complete_include_path {
    my $self = shift;
    
    return [ @{$self->additional_include_paths}, @{$self->include_paths()} ];
}

sub path_to_theme {
    my ($self, $theme) = @_;
    
    if (!$theme) {
        $theme = $self->base_theme;
    }
    
    return $self->fs_template_dir . '/' . $theme;
}

# create a new Template instance with the provided options. 
sub new_template {
    my ($self, $additional_tt_options ) = @_;
    
    $additional_tt_options ||= {};
    my %template_options = ( %{$self->tt_config}, %$additional_tt_options );

    return Template->new( \%template_options );
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=head1 NAME

Form::Sensible::Renderer::HTML - an HTML based Form renderer

=head1 SYNOPSIS

    use Form::Sensible::Renderer::HTML;
    
    my $object = Form::Sensible::Renderer::HTML->new();

    $object->do_stuff();

=head1 DESCRIPTION

Renders a form as an HTML form.  Returns a 
L<Form::Sensible::Renderer::HTML::RenderedForm|Form::Sensible::Renderer::HTML::RenderedForm> object.

=head1 ATTRIBUTES

=over 8

=item C<template>

The L<Template> object used by this renderer.  You can provide your own by setting this attribute.
If you do not set it, a new Template object is created using the parameter below.

=item C<additional_include_paths> 

If you want to search outside the templates distributed with C<Form::Sensible>
for field or form templates, you can add additional paths as an arrayref here.
This is useful if you want to override the some of the templates for your
fields or forms.

This allows you to override just the elements you need to in your own theme,
with all others being sourced from the Form::Sensible distribution ( IE provided
theme and default theme ) Note that unless configured otherwise, if a template
not found in the theme you selected, the C<default> theme will be searched as
well. 


=item C<include_paths>

An arrayref containing the filesystem paths to search for Form::Sensible's
field templates. This defaults to including your base theme (if provided) and
then the default theme:

    $self->include_paths([ 
                            $self->path_to_theme($self->base_theme),
                            $self->path_to_theme('default');
                        ]);

In most cases, you should not touch C<include_paths>, it is provided only for
the case where Form::Sensible is not able to determine the location of it's
templates on the filesystem. If you wish to add additional template paths, use
the C<additional_include_paths> instead. Note also that care should be taken
overriding C<include_paths> because this fallback behavior is based only on
the include path order.

=item C<base_theme>

The theme to use for form rendering.  Defaults to C<default>, default 
uses C<< <div> >>'s for layout.  There is also 'table' which uses HTML 
tables for form layout.

=item C<tt_config>

The config used when creating a new Template object. If you set this manually,
you will need to be sure to set the Template's C<INCLUDE_PATH> yourself or rendering
will be unable to find any field templates.  You can obtain the include path that 
would have been used by calling C<< $self->complete_include_path() >>

=item C<default_options>

Default options to pass through to the L<RenderedForm|Form::Sensible::Renderer::HTML::RenderedForm>.

=back

=head1 METHODS

=over 8

=item C<render($form, $stash_prefill, $options)>

Returns a L<RenderedForm|Form::Sensible::Renderer::HTML::RenderedForm> for the form provided.

options:

=over

=item additional_tt_options

These are passed to the Template::Toolkit constructor C<< Template->new >>

=back

=item C<new_template()>

Returns a new L<Template|Template> object created using the C<tt_config> attribute.

=item C<path_to_theme($theme)>

Returns the filesystem path to the theme provided.  If no C<$theme> is passed, it will
provide the path to the C<base_theme> for the renderer object.

=item C<complete_include_path()>

Returns the complete calculated include paths to be passed to the Template object taking
into account both the C<include_paths> as well as C<additional_include_paths>.

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