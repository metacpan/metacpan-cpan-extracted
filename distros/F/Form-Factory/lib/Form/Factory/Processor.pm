package Form::Factory::Processor;
$Form::Factory::Processor::VERSION = '0.022';
use Moose;
use Moose::Exporter;

use Carp ();
use Form::Factory::Action;
use Form::Factory::Action::Meta::Class;
use Form::Factory::Action::Meta::Attribute::Control;
use Form::Factory::Processor::DeferredValue;

Moose::Exporter->setup_import_methods(
    as_is     => [ qw( deferred_value ) ],
    with_meta => [ qw(
        has_control use_feature
        has_cleaner has_checker has_pre_processor has_post_processor
    ) ],
    also      => 'Moose',
);

# ABSTRACT: Moos-ish helper for action classes


sub init_meta {
    my $package = shift;
    my %options = @_;

    Moose->init_meta(%options);

    my $meta = Moose::Util::MetaRole::apply_metaroles(
        for             => $options{for_class},
        class_metaroles => {
            class => [ 'Form::Factory::Action::Meta::Class' ],
        },
    );

    Moose::Util::apply_all_roles(
        $options{for_class}, 'Form::Factory::Action',
    );

    return $meta;
}


sub _setup_control_defaults {
    my $meta = shift;
    my $name = shift;
    my $args = @_ == 1 ? shift : { @_ };

    # Setup default unless this is an inherited control attribute
    unless ($name =~ /^\+/) {
        $args->{control}  ||= 'text';
        $args->{options}  ||= {};
        $args->{features} ||= {};
        $args->{traits}   ||= [];

        $args->{is}       ||= 'ro';
        $args->{isa}      ||= Form::Factory->control_class($args->{control})->default_isa;

        unshift @{ $args->{traits} }, 'Form::Control';

    }

    Carp::croak(qq{the "required" setting is used on $name, but is forbidden on controls})
        if $args->{required};

    for my $value (values %{ $args->{features} }) {
        $value = {} if $value and not ref $value;
    }

    $args->{__meta} = $meta;

    return ($meta, $name, $args);
}

sub has_control {
    my ($meta, $name, $args) = _setup_control_defaults(@_);
    $meta->add_attribute( $name => $args );
}


sub use_feature {
    my $meta = shift;
    my $name = shift;
    my $args = @_ == 1 ? shift : { @_ };

    $meta->features->{$name} = $args;
}


sub deferred_value(&) {
    my $code = shift;

    return Form::Factory::Processor::DeferredValue->new(
        code => $code,
    );
}


sub _add_function {
    my ($type, $meta, $name, $code) = @_;
    Carp::croak("bad code given for $type $name") unless defined $code;
    $meta->features->{functional}{$type . '_code'}{$name} = $code;
}

sub has_cleaner        { _add_function('cleaner', @_) }
sub has_checker        { _add_function('checker', @_) }
sub has_pre_processor  { _add_function('pre_processor', @_) }
sub has_post_processor { _add_function('post_processor', @_) }


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Processor - Moos-ish helper for action classes

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  has_control name => (
      control => 'text',
      options => {
          label => 'Your Name',
      },
      features => {
          trim     => 1,
          required => 1,
          length   => {
              minimum => 3,
              maximum => 15,
          },
      },
  );

  has_cleaner convert_to_underscores => sub {
      my $self = shift;
      my $name = $self->controls->{name}->current_value;
      $name =~ s/\W+/_/g;
      $self->controls->{name}->current_value($name);
  };

  has_checker do_not_car_for_names_start_with_r => sub {
      my $self = shift;
      my $value = $self->controls->{name}->current_value;

      if ($value =~ /^R/i) {
          $self->error('i do not like names start with "R," get a new name');
          $self->result->is_valid(0);
      }
  };

  has_pre_processor log_start => sub {
      my $self = shift;
      MyApp->logger->debug("START Foo " . Time::HiRes::time());
  };

  has_post_processor log_stop => sub {
      my $self = shift;
      MyApp->logger->debug("STOP Foo " . Time::HiRes::time());
  };

  sub run {
      my $self = shift;
      MyApp->do_something_to_your_name($self->name);
  }

=head1 DESCRIPTION

This is the helper class used to define actions. This class automatically imports the subroutines described in this documentaiton as well as any defined in L<Moose>. It also grants your action class and its meta-class the correct roles.

=head1 METHODS

=head2 init_meta

Sets up the roles and meta-class information for your action class.

=head2 has_control

  has_control $name => (
      %usual_has_options,

      control  => $control_short_name,
      options  => \%control_options,
      features => \%control_features,
  );

This works very similar to L<Moose/has>. This applies the L<Form::Factory::Action::Meta::Attribute::Control> trait to the attribute and sets up other defaults.

The following defaults are set:

=over

=item is

Control attributes are read-only by default.

=item isa

Control attributes are string by default. Be careful about using an C<isa> setting that differs from the control's value. If you do, make sure you use features to make certain the type is the correct kind of thing or that a coercion to the correct type of thing is also setup.

=item control

This will default to "text" if not set.

=item options

An empty hash reference is used by default.

=item features

An empty hash references is used by default.

=back

You may pass any options you could pass to C<has> as well as the additional options for features, control options, etc. This also supports the C<'+name'> syntax for altering attributes that are inherited from a parent class. Currently, only the C<features> option is supported for this, which allows you to add new features or even to turn off features from the parent class. For example, if a control is setup in a parent like this:

  has_control name => (
      control   => 'text',
      features  => {
          trim     => 1,
          required => 1,
          length   => {
              maximum => 20,
              minimum => 3,
           },
      },
  );

A child class may choose to turn the required off and change the length checks by placing this in the subclass definition:

  has_control '+name' => (
      features => {
          required => 0,
          length   => {
              maximum => 20,
              minimum => 10,
          },
      },
  );

The C<trim> feature in the parent would remain in place as originally defined, the required feature is now turned off in the child class, and the length feature options have been replaced. This is done with a shallow merge, so top-level keys in the child class will replace top-level keys in the parent, but any listed in the parent, but not the child remain unchanged.

B<DO NOT> use the C<required> attribute option on controls. If you try to do so, the call to C<has_control> will croak because this will not work with how attributes are setup. If you need an attribute to be required, do not use a control or use the required feature instead.

=head2 use_feature

This function is used to make an action use a particular form feature. It's usage is as follows:

  use_feature $name => \%options;

The C<%options> are optional. So,

  use_feature $name;

will also work if you do not need to pass any features.

The C<$name> is a short name for the feature class. For example, the name "require_none_or_all" will load the feature defined in L<Form::Factory::Feature::RequireNoneOrAll>.

=head2 deferred_value

  has_control publish_on => (
      control => 'text',
      options => {
          default_value => deferred_value {
              my ($action, $control_name) = @_;
              DateTime->now->iso8601,
          },
      },
  );

This is a helper for deferring the calculation of a value. This works similar to L<Scalar::Defer> to defer the calculation, but with an important difference. The subroutine is passed the action object (such as it exists while the controls are being constructed) and the control's name. The control itself doesn't exist yet when the subroutine is called.

=head2 has_cleaner

  has_cleaner $name => sub { ... }

Adds some code called during the clean phase.

=head2 has_checker

  has_checker $name => sub { ... }

Adds some code called during the check phase.

=head2 has_pre_processor

  has_pre_processor $name => sub { ... }

Adds some code called during the pre-process phase.

=head2 has_post_processor

  has_post_processor $name => sub { ... }

Adds some code called during the post-process phase.

=head1 SEE ALSO

L<Form::Factory::Action>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
