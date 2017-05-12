package Form::Factory::Action::Meta::Class;
$Form::Factory::Action::Meta::Class::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: The meta-class role for form actions


has features => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
    default  => sub { {} },
);


sub get_controls {
    my ($meta, @control_names) = @_;
    my @controls;

    if (@control_names) {
        @controls = grep { $_ } 
                     map { $meta->find_attribute_by_name($_) } 
                           @control_names;
    }

    else {
        @controls = $meta->get_all_attributes;
    }

    @controls = sort { $a->placement <=> $b->placement }
                grep { $_->does('Form::Factory::Action::Meta::Attribute::Control') } 
                       @controls;
}


sub get_all_features {
    my $meta = shift;
    my %all_features;

    # For all the classes implemented, find the features we use
    for my $class (reverse $meta->linearized_isa) {
        my $other_meta = $meta->initialize($class);

        next unless $other_meta->can('meta');
        next unless $other_meta->meta->can('does_role');
        next unless $other_meta->meta->does_role('Form::Factory::Action::Meta::Class');

        # Make sure inherited features don't clobber each other
        while (my ($name, $feature_config) = each %{ $other_meta->features }) {
            my $full_name = join('#', $name, $other_meta->name);
            $all_features{$full_name} = $feature_config;
        }
    }

    # Now, do the same for the roles we implement as well
    for my $role ($meta->calculate_all_roles) {

        next unless $role->can('meta');
        next unless $role->meta->can('does_role');
        next unless $role->meta->does_role('Form::Factory::Action::Meta::Role');

        # Make sure these don't clobber the inherited features
        while (my ($name, $feature_config) = each %{ $role->features }) {
            my $full_name = join('#', $name, $role->name);
            $all_features{$full_name} = $feature_config;
        }
    }

    return \%all_features;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Action::Meta::Class - The meta-class role for form actions

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

=head1 DESCRIPTION

All form actions have this role attached to its meta-class.

=head1 ATTRIBUTES

=head2 features

This is a hash of features. The keys are the short name of the feature to attach and the value is a hash of options to pass to the feature's constructor on instantiation.

=head1 METHODS

=head2 get_controls

  my @attributes = $action->meta->get_controls(@names);

Returns all the controls for this action. This includes controls inherited from parent classes as well. This returns a list of attributes which do L<Form::Factory::Action::Meta::Attribute::Control>.

You may pass a list of control names if you only want a subset of the available controls. If no list is given, all controls are returned.

=head2 get_all_features

  my $features = $action->meta->get_all_features;

Returns all the feature specs for the form. This includes all inherited features and features configured in implemented roles as well. These are returned in the same format as the L</features> attribute.

=head1 SEE ALSO

L<Form::Factory::Action>, L<Form::Factory::Control>, L<Form::Factory::Feature>, L<Form::Factory::Processor>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
