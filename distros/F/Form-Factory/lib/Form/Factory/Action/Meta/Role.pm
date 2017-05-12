package Form::Factory::Action::Meta::Role;
$Form::Factory::Action::Meta::Role::VERSION = '0.022';
use Moose::Role;

# ABSTRACT: The meta-class role for form action roles


has features => (
    is        => 'ro',
    isa       => 'HashRef',
    required  => 1,
    default   => sub { {} },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Action::Meta::Role - The meta-class role for form action roles

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Role::Foo;
  use Form::Factory::Processor::Role

=head1 DESCRIPTION

All form action roles have this role attached to its meta-class.

=head1 ATTRIBUTES

=head2 features

This is a hash of features provided by the role. The keys are the short name of the feature to attach and the value is a hash of options to pass to the feature's constructor on instantiation.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
