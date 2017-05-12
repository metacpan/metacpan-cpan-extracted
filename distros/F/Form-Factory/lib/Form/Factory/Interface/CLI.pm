package Form::Factory::Interface::CLI;
$Form::Factory::Interface::CLI::VERSION = '0.022';
use Moose;

with qw( Form::Factory::Interface );

use Carp ();

# ABSTRACT: Command-line interface builder for form factory


has renderer => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { sub { print @_ } },
);


has get_args => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { sub { \@ARGV } },
);


has get_file => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { 
        sub { 
            my ($interface, $name) = @_;
            my $fh;

            if ($name eq '-') {
                $fh = \*STDIN;
            }
            else {
                open $fh, '<', $name or Carp::croak("cannot read $name: $!\n");
            }

            do { local $/; <$fh> };
        }
    },
);


sub render_control {
    my ($self, $control, %options) = @_;

    return if $control->does('Form::Factory::Control::Role::HiddenValue');

    my $arg;
    if ($control->does('Form::Factory::Control::Role::AvailableChoices')) {
        my @values = map { $_->value } @{ $control->available_choices };
        $arg = '[ ' . join(' | ', @values) . ' ]';
    }
    elsif ($control->does('Form::Factory::Control::Role::BooleanValue')) {
        $arg = ''
    }
    elsif ($control->does('Form::Factory::Control::Role::PresetValue')) {
        $arg = '';
    }
    elsif ($control->does('Form::Factory::Control::Role::MultiLine')) {
        $arg = 'FILE';
    }
    else {
        $arg = 'TEXT';
    }

    my $description = $control->documentation || '';

    $self->renderer->($self,
        sprintf("    --%-20s %s\n", $control->name . ' '. $arg, $description)
    );
}


sub consume_control {
    my ($self, $control, %options) = @_;

    my @argv = @{ $self->get_args->($self) };
    my ($fetch, @values);
    for my $argv (@argv) {
        if ($fetch) {
            push @values, $argv;
            undef $fetch;
        }

        elsif ($argv eq '--' . $control->name) {
            if ($control->does('Form::Factory::Control::Role::BooleanValue')) {
                push @values, $control->true_value;
            }
            else {
                $fetch++;
            }
        }
    }

    return {} unless @values > 0;

    my $get_value = sub {
        my $value = shift;
        if ($control->does('Form::Factory::Control::Role::MultiLine')) {
            return $self->get_file->($self, $value);
        }
        else {
            return $value;
        }
    };

    if ($control->does('Form::Factory::Control::Role::ListValue')) {
        my @result;
        push @result, $get_value->($_) for @values;
        $control->current_values(\@result);
    }

    else {
        Carp::croak(sprintf("the --%s option should be used only once\n", $control->name))
            if @values > 1;
     
        $control->current_value($get_value->($values[0]));
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::CLI - Command-line interface builder for form factory

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  #/usr/bin/perl
  use strict;
  use warnings;

  use Form::Factory;

  my $cli = Form::Factory->new_interface('CLI');
  my $action = $cli->new_action(shift @ARGV);
  
  $action->consume_and_clean_and_check_and_process;

  if ($action->is_valid and $action->is_success) {
      print "done.\n";
  }
  else {
      my $messages = $action->results->all_messages;
      print $messages;
      print "usage: $0 OPTIONS\n\n";
      print "Options:\n";
      $action->render;
  }

=head1 DESCRIPTION

Provides a simple interface for building command-line tools that manipulate actions.

=head1 ATTRIBUTES

=head2 renderer

This is a subroutine responsible for returning the usage parameters back to the user. The default prints to C<STDOUT>.

=head2 get_args

This is a subroutine responsible for return a list of command-line arguments. The default implementation returns a reference to C<@ARGV>.

=head2 get_file

This is a subroutine responsible for returning the contents of files used on the command-line. It is passed the interface object and then the name of the file to load. The default implementation slurps up the named file or, in the case of the name begin "-", returns the contents of C<STDIN>.

=head1 METHODS

=head2 render_control

Prints a usage line for each control.

=head2 consume_control

Consumes the command-line arguments and files specified on the command-line to fill in the action.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
