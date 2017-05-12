package Form::Factory::Action;
$Form::Factory::Action::VERSION = '0.022';
use Moose::Role;

use Carp ();
use Form::Factory::Feature::Functional;
use Form::Factory::Result::Gathered;
use Form::Factory::Result::Single;

#requires qw( run );

# ABSTRACT: Role implemented by actions


has form_interface => (
    is        => 'ro',
    does      => 'Form::Factory::Interface',
    required  => 1,
);


has globals => (
    is        => 'ro',
    isa       => 'HashRef[Str]',
    required  => 1,
    default   => sub { {} },
);


has results => (
    is        => 'rw',
    isa       => 'Form::Factory::Result',
    required  => 1,
    lazy      => 1,
    default   => sub { Form::Factory::Result::Gathered->new },
    handles   => [ qw(
        is_valid is_success is_failure
        is_validated is_outcome_known

        all_messages regular_messages field_messages
        info_messages warning_messages error_messages
        regular_info_messages regular_warning_messages regular_error_messages
        field_info_messages field_warning_messages field_error_messages

        content
    ) ],
);


has result => (
    is        => 'rw',
    isa       => 'Form::Factory::Result::Single',
    required  => 1,
    lazy      => 1,
    default   => sub { Form::Factory::Result::Single->new },
    handles   => [ qw(
        success failure

        add_message
        info warning error
        field_info field_warning field_error
    ) ],
);


has features => (
    is          => 'ro',
    isa         => 'ArrayRef',
    required    => 1,
    lazy        => 1,
    initializer => '_init_features',
    default     => sub { [] },
);

sub _meta_features {
    my $self = shift;
    my $all_features = $self->meta->get_all_features;

    my @features;
    for my $feature_name (keys %$all_features) {
        my $feature_options = $all_features->{ $feature_name };
        my $feature_class = Form::Factory->feature_class($feature_name);

        my $feature = $feature_class->new(
            %$feature_options,
            action => $self,
        );
        push @features, $feature;
    }

    return \@features;
}

sub _init_features {
    my ($self, $features, $set, $attr) = @_;
    push @$features, @{ $self->_meta_features };
    $set->($features);
}


has controls => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    lazy      => 1,
    builder   => '_build_controls',
);

sub _build_controls {
    my $self = shift;
    my $interface  = $self->form_interface;
    my $features = $self->features;

    my %controls;
    my @meta_controls = $self->meta->get_controls;
    for my $meta_control (@meta_controls) {

        # Construct any deferred options
        my %options = %{ $meta_control->options };
        OPTION: for my $key (keys %options) {
            my $value = $options{$key};

            next OPTION unless blessed $value;
            next OPTION unless $value->isa('Form::Factory::Processor::DeferredValue');

            $options{$key} = $value->code->($self, $key);
        }

        # Build the control constructor arguments
        my $control_name = $meta_control->name;
        my %control_args = (
            control => $meta_control->control,
            options => {
                name   => $control_name,
                action => $self,
                ($meta_control->has_documentation 
                    ? (documentation => $meta_control->documentation) : ()),
                %options,
            },
        );

        # Let any BuildControl features modify the constructor arguments
        my %feature_classes;
        my $meta_features = $meta_control->features;
        for my $feature_name (keys %$meta_features) {
            my $feature_class = Form::Factory->control_feature_class($feature_name);
            $feature_classes{$feature_name} = $feature_class;

            next unless $feature_class->does('Form::Factory::Feature::Role::BuildControl');

            $feature_class->build_control(
                $meta_features->{$feature_name}, $self, $control_name, \%control_args
            );
        }

        # Construct the control
        my $control = $interface->new_control(
            $control_args{control} => $control_args{options},
        );

        # Construct and attach the features for the control
        my @init_control_features;
        for my $feature_name (keys %$meta_features) {
            my $feature_class = $feature_classes{$feature_name};

            my $feature = $feature_class->new(
                %{ $meta_features->{$feature_name} },
                action  => $self,
                control => $control,
            );
            push @$features, $feature;
            push @{ $control->features }, $feature;

            push @init_control_features, $feature
                if $feature->does('Form::Factory::Feature::Role::InitializeControl');
        }

        # Have InitializeControl features work on the constructed control
        for my $feature (@init_control_features) {
            $feature->initialize_control;
        }

        # Add the control to the list
        $controls{ $meta_control->name } = $control;
    }

    return \%controls;
}


sub stash {
    my ($self, $moniker) = @_;

    my $controls = $self->controls;
    my %controls;
    for my $control_name (keys %$controls) {
        my $control = $controls->{ $control_name };
        $controls{$control_name}{value} = $control->value;
    }

    my %stash = (
        globals  => $self->globals,
        controls => \%controls,
        results  => $self->results,
        result   => $self->result,
    );

    $self->form_interface->stash($moniker => \%stash);
}


sub unstash {
    my ($self, $moniker) = @_;

    my $stash = $self->form_interface->unstash($moniker);
    return unless defined $stash;

    my $globals = $stash->{globals} || {};
    for my $key (keys %$globals) {
        $self->globals->{$key} = $globals->{$key};
    }

    my $controls       = $self->controls;
    my $controls_state = $stash->{controls} || {};
    for my $control_name (keys %$controls) {
        my $state   = $controls_state->{$control_name};
        my $control = $controls->{$control_name};
        eval { $control->value($state->{value}) };
    }

    $self->results($stash->{results} || Form::Factory::Result::Gathered->new);
    $self->result($stash->{result} || Form::Factory::Result::Single->new);
}


sub clear {
    my ($self) = @_;

    %{ $self->globals } = ();

    my $controls       = $self->controls;
    for my $control_name (keys %$controls) {
        my $control = $controls->{ $control_name };
        delete $control->{value};
    }

    $self->results->clear_all;
    $self->result(Form::Factory::Result::Single->new);
}


sub render {
    my $self = shift;
    my %params = @_;
    my @names  = defined $params{controls} ?    @{ delete $params{controls} } 
               :                             map { $_->name } 
                                                   $self->meta->get_controls
               ;

    $params{results} = $self->results;

    my $controls = $self->controls;
    $self->form_interface->render_control($controls->{$_}, %params) for @names;
    return;
}


sub setup_and_render {
    my ($self, %options) = @_;

    $self->unstash($options{moniker});
    my %globals = %{ $options{globals} || {} };
    for my $key (keys %globals) {
        $self->globals->{$key} = $globals{$key};
    }
    $self->render(%options);
    $self->results->clear_all;
    $self->stash($options{moniker});

    return;
}


sub render_control {
    my ($self, $name, $options, %params) = @_;

    my %options = %{ $options || {} };
    $options{action} = $self;

    $params{results} = $self->results;

    my $interface = $self->form_interface;
    my $control   = $interface->new_control($name => \%options);

    $interface->render_control($control, %params);

    return $control;
}


sub consume {
    my $self   = shift;
    my %params = @_;
    my @names  = defined $params{controls} ?    @{ delete $params{controls} } 
               :                             map { $_->name } 
                                                   $self->meta->get_controls
               ;

    my $controls = $self->controls;
    $self->form_interface->consume_control($controls->{$_}, %params) for @names;
}


sub consume_control {
    my ($self, $name, $options, %params) = @_;

    my %options = %{ $options || {} };
    $options{action} = $self;

    $params{results} = $self->results;

    my $interface = $self->form_interface;
    my $control   = $interface->new_control($name => \%options);

    $interface->consume_control($control, %params);

    return $control;
}


{
    sub _run_features {
        my $self     = shift;
        my $method   = shift;
        my %params   = @_;
        my $features = $self->features;

        # Only run the requested control-specific features
        if (defined $params{controls}) {
            my %names = map { $_ => 1 } @{ $params{controls} };

            for my $feature (@$features) {
                next unless $feature->does('Form::Factory::Feature::Role::Control');
                next unless $feature->does(
                    Form::Factory::_class_name_from_name('Feature::Role', $method)
                );
                next unless $names{ $feature->control->name };

                $feature->$method;
            }
        }

        # Run all features now
        else {
            for my $feature (@$features) {
                next unless $feature->does(
                    Form::Factory::_class_name_from_name('Feature::Role', $method)
                );

                $feature->$method;
            }
        }
    }
}

sub clean {
    my $self = shift;
    $self->_run_features(clean => @_);
}


sub check {
    my $self = shift;
    $self->_run_features(check => @_);

    $self->gather_results;
}


sub process {
    my $self = shift;
    return unless $self->is_valid;

    $self->set_attributes_from_controls;

    $self->_run_features('pre_process');
    $self->run;
    $self->_run_features('post_process');

    $self->gather_results;

    my @errors = $self->error_messages;
    $self->result->is_success(@errors == 0);
}


sub consume_and_clean_and_check_and_process {
    my $self = shift;
    $self->consume(@_);
    $self->clean;
    $self->check;
    $self->process;
}


sub set_attribute_from_control {
    my ($self, $name) = @_;
    my $meta = $self->meta;

    my $control   = $self->control->{$name};
    my $attribute = $meta->find_attribute_by_name($name);
    $control->set_attribute_value($self, $attribute);
}


sub set_attributes_from_controls {
    my $self = shift;
    my $meta = $self->meta;

    my $controls = $self->controls;
    while (my ($name, $control) = each %$controls) {
        my $attribute = $meta->find_attribute_by_name($name);
        Carp::croak("attribute for control $name not found on $self")
            unless defined $attribute;
        $control->set_attribute_value($self, $attribute);
    }
}


sub gather_results {
    my $self = shift;
    my $controls = $self->controls;
    $self->results->gather_results( 
        $self->result, 
        map { $_->result } @{ $self->features } 
    );
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Action - Role implemented by actions

=head1 VERSION

version 0.022

=head1 DESCRIPTION

This is the role implemented by all form actions. Rather than doing so directly, you should use L<Form::Factory::Processor> as demonstrated in the L</SYNOPSIS>.

=head2 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  has_control bar => (
      type => 'text',
  );

  sub run {
      my $self = shift;

      # Do something...
  }

=head1 ATTRIBUTES

All form actions have the following attributes.

=head2 form_interface

This is the L<Form::Factory::Interface> that constructed this action. If you need to get at the implementation directly for some reason, here it is. This is mostly used by the action itself when calling the L</render> and L</consume> methods.

=head2 globals

This is a hash of extra parameters to keep with the form. Normally, these are saved with a call to L</stash> and recovered with a call to L</unstash>.

=head2 results

This is a L<Form::Factory::Result::Gathered> object that tracks the general success, failure, messages, and output from the execution of this action.

Actions delegate a number of methods to this object. See L</RESULTS>.

=head2 result

This is a L<Form::Factory::Result::Single> used to record general outcome.

Actions delegate a number of methods to this object. See L</RESULTS>.

=head2 features

This is a list of L<Form::Factory::Feature> objects used to modify the object. This will always contain the features that are attached to the class itself. Additional features may be added here.

=head2 controls

This is a hash of controls attached to this action. For every C<has_control> line in the action class, there should be a matching control in this hash.

=head1 METHODS

=head2 stash

  $action->stash($moniker);

Given a C<$moniker> (a key under which to store the information related to this form), this will stash the form's stashable information under that name using the L<Form::Factory::Stasher> associated with the L</form_interface>.

The globals, values of controls, and the results are stashed. This allows those values to be recovered across requests or between process calls or whatever the implementation requires.

=head2 unstash

  $action->unstash($moniker);

Given a C<$moniker> previously named in a call to L</stash>, it restores the previously stashed state. This is a no-op if nothing is stashed under this moniker.

=head2 clear

This method clears the stashable state of the action.

=head2 render

  $action->render(%options);

Renders the form using the associated L</form_interface>. You may specify the following options:

=over

=item controls

This is a list of control names to render. If not given, all controls will be rendered.

=back

Any other options will be passed on to the L<Form::Factory::Interface/render_control> method.

=head2 setup_and_render

  $self->setup_and_render(%options);

This performs the most common steps to prepare for a render and render:

=over

=item 1

Unstashes from the given C<moniker>.

=item 2

Adds the given C<globals> to the globals.

=item 3

Renders the action.

=item 4

Clears the results.

=item 5

Stashes what we've done back into the given C<moniker>.

=back

=head2 render_control

  my $control = $action->render_control($name, \%options);

Creates and renders a one time control. This is mostly useful for attaching buttons to a form. The control is not added to the list of controls on the action and will not be processed later.

This method returns the control object that was just rendered.

=head2 consume

  $action->consume(%options);

This consumes any input from user and places it into the controls of the form. You may pass the following options:

=over

=item controls

This is a list of names of controls to consume. Any not listed here will not be consumed. If this option is missing, all control values are consumed.

=back

Any additional options will be passed to the L<Form::Factory::Interface/consume_control> method call.

=head2 consume_control

  my $control = $action->consume_control($name, \%options, %params);

Consumes the value of a one time control. This is useful for testing to see if a form submitted using a one-time control has been submitted or not.

This method returns the control object that was consumed.

=head2 clean

  $action->clean(%options);

Takes the values consumed from the user and cleans them up. For example, if you allow users to type in a phone number, this can be used to clear out any unwanted or incorrect punctuation and format the phone number properly.

This method runs through all the requested L<Form::Factory::Feature> objects in L</features> and runs the L<Form::Factory::Feature/clean> method for each.

The following options are used:

=over

=item controls

This is the list of controls to clean. If not given, all features will be run. If given, only the control-features (those implementing L<Form::Factory::Feature::Role::Control> attached to the named controls) will be run. Any form-features or unlisted control-features will not be run.

=back

=head2 check

  $action->check(%options);

The C<check> method is responsible for verifying the correctness of the input. It assumes that L</clean> has already run.

It runs the L<Form::Factory::Feature/check> method of all the selected L</features> attached to the action. It also sets the C<is_valid> flag to true if no errors have been recored yet or to false if they have.

The following options are used:

=over

=item controls

This is the list of controls to check. If not given, all features will be run. If given, only the control-features (those implementing L<Form::Factory::Feature::Role::Control> attached to the named controls) will be run. Any form-features or unlisted control-features will not be run.

=back

=head2 process

  $action->process;

This does nothing if the action did not validate.

In the case the action is valid, this will use L</set_attributes_from_controls> to copy the control values to the action attributes, run the L<Form::Factory::Feature/pre_process> methods for all form-features and control-features, call the L</run> method, run the L<Form::Factory::Feature/post_process> methods for all form-features and control-features, and set the C<is_success> flag to true if no errors are recorded or false if there are.

=head2 consume_and_clean_and_check_and_process

This is a shortcut for taking all the usual workflow actions in a single call:

  $action->consume(@_);
  $action->clean;
  $action->check
  $action->process;

=head1 ROLE METHODS

This method must be implemented by any action implementation.

=head2 run

This is the method that actually does the work. It takes no arguments and is expected to return nothing. You should draw your input from the action attributes (not the controls) and report your results to L</result>.

=head1 HELPER METHODS

These methods are primarily intended for internal use.

=head2 set_attribute_from_control

Given the name of a control, this will copy the current value in the control to the attribute.

=head2 set_attributes_from_controls

This method is used by L</process> to copy the values out of the controls into the form action attributes. This assumes that such a copy will work because the L</clean> and L</check> phases should have already run and passed without error.

=head2 gather_results

Gathers results for all the associated L</controls> and L</result> into L</results>. This is called just before deciding if the action has validated correctly or if the action has succeeded.

=head1 RESULTS

Actions are tied closely to L<Form::Factory::Result>s. As such, a number of methods are delegated to result classes.

The following methods are delegated to L</results> in L<Form::Factory::Result::Gathered>.

=over

=item is_valid

=item is_success

=item is_failure

=item is_validated 

=item is_outcome_known

=item all_messages 

=item regular_messages

=item field_messages

=item info_messages 

=item warning_messages 

=item error_messages

=item regular_info_messages 

=item regular_warning_messages 

=item regular_error_messages

=item field_info_messages 

=item field_warning_messages 

=item field_error_messages

=item content

=back

These methods are delegated to L<result> in L<Form::Factory::Result::Single>.

=over

=item success 

=item failure

=item add_message

=item info 

=item warning 

=item error

=item field_info 

=item field_warning 

=item field_error

=back

=head1 WORKFLOW

=head2 TYPICAL CASE

The action workflow typically goes like this. There are two phases.

=head3 PHASE 1: SHOW THE FORM

Phase 1 is responsible for showing the form to the user. This phase might be skipped altogether in situations where automatic processing is taking place where the robot doing the work already knows what inputs are expected for the action. However, typically, you do something like this:

  my $action = $interface->new_action('Foo');
  $action->unstash('foo');
  $action->render;
  $action->render_control(button => {
      name  => 'submit',
      label => 'Do It',
  });
  $action->stash('foo');

This tells the interface that you want to prepare a form object for class "Foo." 

The call to L</unstash> then pulls in any state saved from the user's prior entry. This will cause any errors that occurred on a previous validation or process execution to show up (assuming that your interface does that work for you). This also means that any previously stashed values entered should reappear in the form so that a failure to save or something won't cause the field information to be lost forever.

The call to L</render> causes all of the controls of the form to be rendered for input.

The call to L</render_control> causes a button to appear in the form.

The call to L</stash> returns the form's stashable information back to the stash, since L</unstash> typically removes it.

=head3 PHASE 2: PROCESSING THE INPUT

Once the user has submitted the form, you will want to process the input and perform the action. This typically looks like this:

  my $action = $interface->new_action('Foo');
  $action->unstash('foo');
  $action->consume_and_clean_and_check_and_process( request => $q->Vars );

  if ($action->is_valid and $action->is_success) {
      # Go on to the next thing
  }
  else {
      $action->stash('foo');
      # Go render the form again and show the errors
  }

We request an instance of the form again and then call L</unstash> to recover any stashed setup. We then call the L</consume_and_clean_and_check_and_process> method, which will consume all the input. Here we use something that looks like a L<CGI> request for the source of input, but it should be whatever is appropriate to your environment and the L<Form::Factory::Interface> implementation used. 

At the end, we check to see if the action checked out and then that the L</run> method ran without problems. If so, we can show the success page or the record view or whatever is appropriate after filling this form.

If there are errors, we should perform the rendering action for L</PHASE 1: SHOW THE FORM> again after doing a L</stash> to make sure the information is ready to be recovered.

=head2 VARATIONS

=head3 PER-CONTROL CLEANING AND CHECKING

Ajax or GUIs will generally want to give their feedback as early as possible. As such, whenever the user finishes entering a value or the application thinks that validation is needed, the app might perform:

  $action->check( controls => [ qw( some_control ) ] );
  $action->clean( controls => [ qw( some_control ) ] );

  unless ($action->is_valid) {
      # Report $action->results->error_messages
  }

You will still run the steps above, but can do a check and clean on a subset of controls when you need to do so to give the user early feedback.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
