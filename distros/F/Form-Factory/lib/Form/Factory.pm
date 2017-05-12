package Form::Factory;
$Form::Factory::VERSION = '0.022';
use Moose;

use Carp ();
use Class::Load;

# ABSTRACT: a general-purpose form handling API


sub new_interface {
    my $class = shift;
    my $name  = shift;
    my $class_name = $class->interface_class($name);
    return $class_name->new(@_);
}


sub interface_class { _load_class_from_name(Interface => $_[1]) }


sub control_class { _load_class_from_name(Control => $_[1]) }


sub feature_class { _load_class_from_name(Feature => $_[1]) }


sub control_feature_class { _load_class_from_name('Feature::Control' => $_[1]) }


sub _class_name_from_name {
    my ($prefix, $name) = @_;

    # Remove anything like #Foo, which is used to differentiate between features
    # added by different classes in get_all_features()
    $name =~ s/\#(.*)$//;

    # Turn a foo_bar_baz name into FooBarBaz
    $name =~ s/(?:[^A-Za-z]+|^)([A-Za-z])/\U$1/g;

    return join('::', 'Form::Factory', $prefix, ucfirst $name);
}

sub _load_class_from_name {
    my ($given_type, $name) = @_;
    my $ERROR;

    my $custom_type = join('::', $given_type, 'Custom');
    for my $type ($given_type, $custom_type) {
        my $class_name = _class_name_from_name($type, $name);

        if (not eval { Class::Load::load_class($class_name) }) {
            $ERROR ||= $@ if $@;
            $ERROR ||= "failed to load $type class named $name";;
        }
        elsif ($type eq $custom_type) {
            $class_name = $class_name->register_implementation;

            if (eval { Class::Load::load_class($class_name) }) {
                return $class_name;
            }
            else {
                undef $ERROR;
                $ERROR ||= $@ if $@;
                $ERROR ||= "failed to load $type class named $name";;
            }
        }
        else {
            return $class_name;
        }
    }

    Carp::croak($ERROR);
}


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory - a general-purpose form handling API

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  ### CGI, HTML example
  my $interface = Form::Factory->new_interface('HTML');
  my $action  = $interface->new_action('MyApp::Action::Login');

  ### Drawing the form contents
  $action->unstash('login');
  $action->globals->{after_login} = '/index.html';
  $action->stash('login');
  $action->render;
  $action->render_control(button => {
      name  => 'submit',
      label => 'Login',
  });
  $action->results->clear_all;
  
  ### Processing the form result
  my $q = CGI->new;
  $action->unstash('login');
  $action->consume_and_clean_and_check_and_process( request => $q->Vars );

  if ($action->is_valid and $action->is_success) {
      $action->stash('login');
      print $q->redirect($action->globals->{after_login});
  }
  else {
      print q{<p class="errors">};
      print $action->error_messages;
      print q{</p>};
  }

=head1 DESCRIPTION

B<ALPHA API>. This code is not fully tested (if you look in the test files you will see a long list of tests planned, but no yet implemented). It is currently being employed on a non-production project. The API I<will> change. See L</TODO> for more.

This API is designed to be a general purpose API for showing and processing forms. This has been done before. I know. However, I believe this provides some distinct advantages. 

You should check out the alternatives because this might be more complex than you really need. That said, why would you want this?

=head2 MODULAR AND EXTENSIBLE

This forms processor makes heavy use of L<Moose>. Nearly every class is replaceable or extensible in case it does not work the way you need it to. It is initially implemented to support HTML forms and command-line interfaces, but I would like to see it support XForms, XUL, PDF forms, GUI forms via Wx or Curses, etc.

=head2 ENCAPSULATED ACTIONS

The centerpiece of this API is the way an action is encapsulated in a single object. In a way, a form object is a glorified functor with a C<run> method responsible for taking the action. Wrapped around that is the ability to describe what kind of inputs are expected, how to clean up and verify the inputs, how to report errors so that they can be used, how entered values can be sent back to the orignal user, etc.

The goal here is to create self-contained actions that specify what they are in fairly generic terms, take specific action when the input checks out, to handle exceptions in a way that is convenient in forms processing (where exceptions are often more common than not) and send back output cleanly.

=head2 MULTIPLE IMPLEMENTATIONS

An action presents a blueprint for the data it needs to run. A form interface takes that blueprint and builds the UI to present to the user and consume input from the user and notify the action.

A form interface could be any kind of UI. The way the form interface and action is used will depend on the form interface implementation. The action itself should not need to care (much) about what interface it is used in.

=head2 CONTROLS VERSUS WIDGETS

So far, the attempt has been made to keep controls pretty generic. A control specifies the kind of inputs an action expects for some input, but the interface is responsible for rendering that control as a suitable widget and consuming data from that widget.

=head2 FORM AND CONTROL FEATURES

Forms and controls can be extended with common features. These features can clean up the input, check the input for errors, and provide additional processing to forms. Features can be added to an action class or even to a specific instance to modify the form on the fly.

=head1 METHODS

=head2 new_interface

  my $interface = Form::Factory->new_interface($name, \%options);

This creates a L<Form::Factory::Interface> object with the given options. This is, more or less, a shortcut for:

  my $interface_class = Form::Factory->interface_class($name);
  my $interface       = $interface_class->new(\%options);

=head2 interface_class

  my $class_name = Form::Factory->interface_class('HTML');

Returns the interface class for the named interface. This loads the interface class from the L<Form::Factory::Interface> namespace. 

See L</CLASS LOADING>.

=head2 control_class

  my $class_name = Form::Factory->control_class('full_text');

Returns the control class for the named control. This loads the control class from the L<Form::Factory::Control> namespace.

See L</CLASS LOADING>.

=head2 feature_class

  my $class_name = Form::Factory->feature_class('functional');

Returns the feature class for the named feature. This loads the feature class from the L<Form::Factory::Feature> namespace.

See L</CLASS LOADING>.

=head2 control_feature_class

  my $class_name = Form::Factory->control_feature_class('required');

Returns the control feature class for the named control feature. This loads the control feature class from the L<Form::Factory::Feature::Control> namespace.

See L</CLASS LOADING>.

=head1 CLASS LOADING

This package features a few class loading methods. These methods each load a type of class. The type of class depends on the namespace they are based upon (which is mentioned in the documentation for each class loading method).

Each namespace is divided into two segments: the reserved namespace and the custom namespace. The reserved namespace is reserved for use by the L<Form::Factory> library itself. These will be any class directly under the namespace given. 

For example, interface classes will always be directly under L<Form::Factory::Interface>, such as L<Form::Factory::Interface::HTML> and L<Form::Factory::Interface::CLI>.

The custom namespaces are implemented as an alias under the C<Custom> package namespace. You first define a custom package, which contains a C<register_implementation>, which returns the name of a package that actually implements that class.

For example, you might create an interface class specific to your app. You might define a class as follows:

  package Form::Factory::Interface::Custom::MyAppHTML;
  sub register_implementation { 'MyApp::Form::Factory::Interface::HTML' }

  package MyApp::Form::Factory::Interface::HTML;
  use Moose;

  extends qw( Form::Factory::Interface::HTML );

  # implementation here...

Any custom name is similar. You could then retrieve your custom name via:

  my $class = Form::Factory->interface_class('MyAppHTML');

Though, you probably actually want:

  my $interface = Form::Factory->new_interface('MyAppHTML');

=head1 TODO

This is not definite, but some things I know as of right now I'm not happy with:

=over

=item *

There are lots of tweaks coming to controls.

=item *

Features do not do very much yet, but they must do more, especially control features. I want features to be able to modify control construction, add interface-specific functionality for rendering and consuming, etc. They will be bigger and badder, but this might mean who knows what needs to change elsewhere.

=item *

The interfaces are kind of stupid at this point. They probably need a place to put their brains so they can some more interesting work.

=back

=head1 CODE REPOSITORY

If you would like to take a look at the latest progress on this software, please see the Github repository: L<http://github.com/zostay/FormFactory>

=head1 BUGS

Please report any bugs you find to the Github issue tracker: L<http://github.com/zostay/FormFactory/issues>

If you need help getting started or something (the documentation was originally thrown together over my recent vacation, so it's probably lacking and wonky), you can also contact me on Twitter (L<http://twitter.com/zostay>) or by L<email|/AUTHOR>.

=head1 SEE ALSO

L<Form::Factory::Interface::CLI>, L<Form::Factory::Interface::HTML>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
