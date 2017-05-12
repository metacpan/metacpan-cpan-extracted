package Form::Factory::Action::Meta::Attribute::Control;
$Form::Factory::Action::Meta::Attribute::Control::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: Form control attribute-traits


has placement => (
    is        => 'ro',
    isa       => 'Num',
    required  => 1,
    default   => 0,
);


has control => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'text',
);


has options => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
);


has features => (
    is          => 'ro',
    isa         => 'HashRef[HashRef]',
    required    => 1,
    default     => sub { {} },
);


around new => sub {
    my ($next, $class, $name, %options) = @_;

    my $meta = delete $options{__meta};

    my $real_name = $name;
       $real_name =~ s/^\+//;

    for my $feature_name (keys %{ $options{features} }) {
        my $feature_class = Form::Factory->control_feature_class($feature_name);
        next unless $feature_class->does('Form::Factory::Feature::Role::BuildAttribute');

        $feature_class->build_attribute(
            $options{features}{$feature_name}, $meta, $real_name, \%options
        );
    }

    $class->$next($name, %options);
};


around clone_and_inherit_options => sub {
    my ($next, $self, %options) = @_;

    # Merge features
    if ($options{features}) {
        my $parent_features = $self->features;
        my $child_features  = $options{features};

        $options{features}  = { %$parent_features, %$child_features };
        for my $key (keys %{ $options{features} }) {
            delete $options{features}{$key} unless $options{features}{$key};
        }
    }

    $self->$next(%options);
};


package Moose::Meta::Attribute::Custom::Trait::Form::Control;
$Moose::Meta::Attribute::Custom::Trait::Form::Control::VERSION = '0.022';
sub register_implementation { 'Form::Factory::Action::Meta::Attribute::Control' }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Action::Meta::Attribute::Control - Form control attribute-traits

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  has_control name => (
      control   => 'text',
      placement => 1,
      options   => {
          label => 'The Name',
      },
      features  => {
          required => 1,
          length   => {
              maximum => '20',
          },
      },
  );

=head1 DESCRIPTION

Any control attribute created with the L<Form::Factory::Processor/has_control> subroutine, will have this trait assigned.

=head1 ATTRIBUTES

=head2 placement

This is the sort order of the controls in an action. Normally, controls will be sorted in the order they appear in the class definition, but this lets you modify that. This is mostly useful when an action is composed of different roles or inherits controls from a parent class. This allows you to order your controls relative to the controls defined in the other classes.

=head2 control

This is the short name of the control. See L<Form::Factory::Interface/CONTROLS> for a list of built-in controls.

=head2 options

This is a hash of options to pass to the control constructor.

=head2 features

This is a hash of feature definitions to attach ot the control. Each key is the short name of a control-feature to attach. The value is either a "1" to indicate no additional arguments or a hash reference of arguments to pass to the feature's constructor.

=head1 METHODS

=head2 new

Makes sure that features are setup properly.

=head2 clone_and_inherit_options

Modifies the L<Moose::Meta::Attribute> version to handle the merging of L<features>.

=head1 SEE ALSO

L<Form::Factory::Processor>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
