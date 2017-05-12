package Form::Factory::Feature::Role::BuildAttribute;
$Form::Factory::Feature::Role::BuildAttribute::VERSION = '0.022';
use Moose::Role;

requires qw( build_attribute );

# ABSTRACT: control features that modify the action attribute


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Role::BuildAttribute - control features that modify the action attribute

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::AddPredicate;
  use Moose;

  with qw(
      Form::Factory::Feature
      Form::Factory::Feature::Role::BuildAttribute
      Form::Factory::Feature::Role::Control
  );

  sub build_attribute {
      my ($class, $options, $meta, $name, $attr) = @_;
      $attr->{predicate} = 'has_' . $name;
  }

  package Form::Factory::Feature::Control::Custom::AddPredicate;
  sub register_implementation { 'MyApp::Feature::FillFromRecord' }

=head1 DESCRIPTION

Control features that implement this role are given the opportunity to directly modify the action attribute just before it is added to the meta-class. 

This is done by implementing the C<build_attribute> class method. This method will be passed a hash representing the feature arguments for this feature (since the feature will not yet exist as an object). It will then be passed the meta-class object, the name of the attribute being added, and a normalized hash of attribute parameters.

You may use these arguments to manipulate the attribute before it is created, create additional attributes, etc.

=head1 ROLE METHODS

=head2 build_attribute

The C<build_attribute> method should be implemented something like this:

  sub build_attribute {
      my ($class, $options, $meta, $name, $attr) = @_;

      # do something ...
  }

This method is called while the action class is being compiled. This method can be used to modify how the action attribute is created.

The C<$class> is the feature class this subroutine belongs to. The feature will not have been created nearly this early.

The C<$options> are the feature options passed to the C<has_control> statement.

The C<$meta> is the metaclass object that the attribute is about to be added to.

The C<$name> is the name of the attribute being added to the metaclass.

The C<$attr> is the arguments that are about to be passed to the attribute constructor. This the hash of argumentst that will be passed to the attribute constructor shortly. Modifying this hash will change the attribute construction.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
