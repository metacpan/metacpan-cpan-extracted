package Form::Factory::Feature::Functional;
$Form::Factory::Feature::Functional::VERSION = '0.022';
use Moose;

with qw( 
    Form::Factory::Feature 
    Form::Factory::Feature::Role::Clean
    Form::Factory::Feature::Role::Check
    Form::Factory::Feature::Role::PreProcess
    Form::Factory::Feature::Role::PostProcess
);

# ABSTRACT: A generic feature for actions


has cleaner_code => (
    is        => 'ro',
    isa       => 'HashRef[CodeRef]',
    required  => 1,
    default   => sub { {} },
);


has checker_code => (
    is        => 'ro',
    isa       => 'HashRef[CodeRef]',
    required  => 1,
    default   => sub { {} },
);


has pre_processor_code => (
    is        => 'ro',
    isa       => 'HashRef[CodeRef]',
    required  => 1,
    default   => sub { {} },
);


has post_processor_code => (
    is        => 'ro',
    isa       => 'HashRef[CodeRef]',
    required  => 1,
    default   => sub { {} },
);


sub clean {
    my $self = shift;
    $_->($self->action, @_) for values %{ $self->cleaner_code };
}


sub check {
    my $self = shift;
    $_->($self->action, @_) for values %{ $self->checker_code };
}


sub pre_process {
    my $self = shift;
    $_->($self->action, @_) for values %{ $self->pre_processor_code };
}


sub post_process {
    my $self = shift;
    $_->($self->action, @_) for values %{ $self->post_processor_code };
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Feature::Functional - A generic feature for actions

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  package MyApp::Action::Foo;
  use Form::Factory::Processor;

  has_cleaner squeaky => sub {
      my $action = shift;
      # clean up the action input here...
  };

  has_checker black_or_read => sub {
      my $action = shift;
      # check the action input here... 
  };

  has_pre_processor remember_cpp => sub {
      my $action = shift;
      # run code just before processing here...
  };

  has_post_processor industrial_something => sub {
      my $action = shift;
      # run code just after processing here...
  };

=head1 DESCRIPTION

You probably don't want to use this feature directly. The various helpers imported when you use L<Form::Factory::Processor> actually use this feature for implementation. You probably want to use those instead.

=head1 ATTRIBUTES

=head2 cleaner_code

An array of subroutines to run during the clean phase.

=head2 checker_code

An array of subroutines to run during the check phase.

=head2 pre_processor_code

An array of subroutines to run during the pre-process phase.

=head2 post_process_code

An array of subroutines to run during the post-process phase.

=head1 METHODS

=head2 clean

Run all the subroutines in L</cleaner_code>.

=head2 check

Run all the subroutines in L</checker_code>.

=head2 pre_process

Run all the subroutines in L</pre_processor_code>.

=head2 post_process

Run all the subroutines in L</post_processor_code>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
