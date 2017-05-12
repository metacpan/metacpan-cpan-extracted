package ExtUtils::XSpp::Plugin::Cloning;
use strict;
use warnings;

our $VERSION = '0.02';

use Carp ();
use ExtUtils::XSpp ();

=head1 NAME

ExtUtils::XSpp::Plugin::Cloning - An XS++ plugin for controlling cloning on thread creation

=head1 SYNOPSIS

Use it in your XS++ code as follows. No other interface required.

  %module{Your::Module}
  
  %loadplugin{Cloning}
  
  # Objects of this class will just be undef in a cloned interpreter
  class MyThreadSafeClass {
    %PreventCloning;
    ...
  };
  
  # TODO More to come

=head1 DESCRIPTION

C<ExtUtils::XSpp::Plugin::Cloning> is a plugin for C<XS++> (See L<ExtUtils::XSpp>)
for controlling the behavior of a class's objects when the interpreter/thread they
live in is cloned.

Since C<ExtUtils::XSpp>'s plugin interface is considered experimental, so is this
module!

=head1 DIRECTIVES

=head2 C<%PreventCloning>

Specify this directive inside your class to prevent objects of the class
from being cloned on thread spawning. They will simply be undefined in the
new interperter/thread.

This defines a new C<CLONE_SKIP> method in the given class that prevents
the instances from being cloned. Note that due to this implementation detail,
the effect of the C<%PreventCloning> directive is inheritable.

=cut

sub new {
  my $class = shift;
  my $self = {@_};
  bless $self => $class;
  return $self;
}

sub register_plugin {
  my ($class, $parser) = @_;

  $parser->add_class_tag_plugin(
    plugin => $class->new,
    tag    => 'PreventCloning',
  );
}

sub handle_class_tag {
  my ($self, $class, $tag, %args) = @_;

  if ($tag eq 'PreventCloning') {
    $self->_handle_prevent_cloning($class);
    return 1;
  }
  return();
}

sub _handle_prevent_cloning {
  my ($self, $class) = @_;
  my $class_name = $class->perl_name;

  my $cpp_name = '__CLONE';
  foreach my $method (@{$class->methods}) {
    if ($method->name eq 'CLONE_SKIP') {
      Carp::confess("Perl class '$class_name' already has a 'CLONE_SKIP' method");
    }
    if ($cpp_name eq $method->cpp_name) {
      $cpp_name .= '_';
    }
  }

  my $inttype  = ExtUtils::XSpp::Node::Type->new(base => 'int');
  my $chartype = ExtUtils::XSpp::Node::Type->new(base => 'char', pointer => '*');
  my $arg = ExtUtils::XSpp::Node::Argument->new(
    type => $chartype,
    name => 'class_name',
  );
  my $meth = ExtUtils::XSpp::Node::Function->new(
    class     => $class,
    cpp_name  => $cpp_name,
    perl_name => 'CLONE_SKIP',
    arguments => [$arg],
    ret_type  => $inttype,
    code      => ["RETVAL = 1;\n"],
  );
  $meth->set_static("package_static");
  $class->add_methods($meth);

  return;
}

1;
__END__

=head1 AUTHOR

Steffen Mueller <smueller@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Steffen Mueller

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
