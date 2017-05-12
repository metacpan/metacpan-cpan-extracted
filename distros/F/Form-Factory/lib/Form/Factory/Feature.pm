package Form::Factory::Feature;
$Form::Factory::Feature::VERSION = '0.022';
use Moose::Role;

use Scalar::Util qw( blessed );

# ABSTRACT: Interface for objects that modify how actions work


has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my $class_name = blessed $self;
        unless ($class_name =~ s/^Form::Factory::Feature::Control:://) {
            $class_name =~ s/^Form::Factory::Feature:://;
        }
        $class_name =~ s/(\p{Lu})/_\l$1/g;
        $class_name =~ s/\W+/_/g;
        $class_name =~ s/_+/_/g;
        $class_name =~ s/^_//;
        return lc $class_name;
    },
);


has action => (
    is        => 'ro',
    does      => 'Form::Factory::Action',
    required  => 1,
    weak_ref  => 1,
);


has result => (
    is        => 'ro',
    isa       => 'Form::Factory::Result::Single',
    required  => 1,
    lazy      => 1,
    default   => sub { Form::Factory::Result::Single->new },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature - Interface for objects that modify how actions work

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Feature::Foo;
  use Moose;

  with qw( Form::Factory::Feature );

  package Form::Factory:;Feature::Custom::Foo;
  sub register_implementation { 'MyApp::Feature::Foo' }

=head1 DESCRIPTION

A feature modifies what the form does during processing.

=head1 ATTRIBUTES

=head2 name

The short name of the feature. This is automatically built from the feature's class name.

=head2 action

The action this feature has been attached to.

=head2 result

This is the L<Form::Factory::Result::Single> recording the success or failure of the parts of this feature.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
