package JSON::Karabiner::Manipulator::Actions::From ;
$JSON::Karabiner::Manipulator::Actions::From::VERSION = '0.017';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Actions';


sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || {},
  $obj->{has_mandatory_modifiers} = 0;
  $obj->{has_optional_modifiers} = 0;
  $obj->{has_code_set} = 0;
  return $obj;
}

sub add_key_code {
  my $s = shift;
  my @key_codes = @_;
  my $last_arg = $key_codes[-1];
  my $input_type = 'key_code';
  if ($last_arg && $last_arg =~ /^any|consumer_key_code|pointing_button$/) {
    $input_type = $last_arg;
    pop @key_codes;
  }
  croak 'No key code passed' if !@key_codes;
  croak 'You can only set one key_code, consumer_key_code, pointing_button or any'  if ($s->{code_set});
  #TODO: validate $key_code

  if (scalar @key_codes > 1) {
    croak 'Only one input type can be entered for "from" defintions';
  }
  my ($letter_code, $ms);
  if ($key_codes[0] =~ /-([A-Z])|(\d+)$/) {
    $letter_code = $1;
    $ms = $2;
  }
  croak 'Specifiers such as lazy, repeat, halt, and hold_down_in_milliseconds do not apply in "from" actions'
    if $letter_code || $ms;
  if (exists $s->{data}{$input_type}) {
    croak 'From action already has that property';
  }
  $s->{data}{$input_type} = $key_codes[0];

  $s->{code_set} = 1;
}

sub add_any {
  my $s = shift;
  croak 'You must pass a value' if !$_[0];
  $s->add_key_code(@_, 'any');
}

sub add_optional_modifiers {
  my $s = shift;
  $s->_add_modifiers('optional', @_);
}

sub add_mandatory_modifiers {
  my $s = shift;
  $s->_add_modifiers('mandatory', @_);
}

sub _add_modifiers {
  my $s = shift;
  my $mod_type = shift;
  my $values = \@_;
  croak "This action already has $mod_type modifiers" if $s->{"has_${mod_type}_modifiers"};

  $s->{data}{modifiers}{$mod_type} = \@_;
  $s->{"has_${mod_type}_modifiers"} = 1;
}

sub add_simultaneous {
  my $s = shift;
  my @keys = @_;
  my $key_type = shift @keys if $keys[0] =~ /key_code|pointing|any/i;
  my @hashes;
  if (defined $s->{data}{simultaneous}) {
    @hashes = @{$s->{data}{simultaneous}};
  }
  foreach my $key ( @keys ) {
    push @hashes, { $key_type || 'key_code' => $key };
  }
  $s->{data}{simultaneous} =  \@hashes ;
}

sub add_simultaneous_options {
  my $s = shift;
  my $option = shift;
  my @values = @_;
  my @allowed_options = qw ( detect_key_down_uninterruptedly
                             key_down_order key_up_when to_after_key_up );
  my $exists = grep { $_ = $option } @allowed_options;
  croak "Simultaneous option is not a valid option" if $exists;
  my $value = $values[0];

  #TODO: detect if option already exists and die if it does
  #TODO: offer suggestions if error thrown
  croak "Simultaneous option $option has already been set" if ($s->{"so_${option}_is_set"} == 1);

  if ($option eq 'detect_key_down_uninterruptedly') {
    if ($value !~ /true|false/) {
      croak "$value is not a valid option for $option";
    }
  } elsif ($option eq 'key_down_order' || $option eq 'key_up_order') {
    if ($value !~ /insenstive|strict|strict_inverse/) {
      croak "$value is not a valid option for $option";
    }
  } elsif ($option eq 'key_up_when') {
    if ($value !~ /any|when/) {
      croak "$value is not a valid option for $option";
    }
  } elsif ($option eq 'to_after_key_up') {
    #TODO: Figure out how this is supposed to work
    croak 'This option is currently unspported by JSON::Karabiner';
  }

  $s->{"so_${option}_is_set"} = 1;

}

# ABSTRACT: From defintion

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Actions::From - From defintion

=head1 SYNOPSIS

  add_action('from');

  # Use methods to add data to the action:
  add_key_code('h');
  add_optional_modifiers('control', 'left_shift');

=head1 DESCRIPTION

The C<from> action describes the key and button presses that you want Karbiner
to modify. For example, you may want Karbiner to do something when you hit
C<Control-Shift-h>.

Below are the methods used to add data to the C<from> action. Consult the
official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/> about the C<from> data structure.

=head1 METHODS

=head3 new($type)

The constructor method is not called directly. The C<from> action object is more
typically created via the manipulator object's C<add_action()> method.

=head3 add_key_code($value)

Add a C<key_code> property to a C<from> action:

  add_key_code('h');

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/>

=head3 add_any($value)

Add an C<any> property to a C<from> action:

  add_any($value);

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/any/>

=head3 add_consumer_key_code($value)

Add an C<consumer_key_code> property to a C<from> action:

  add_consumer_key_code('MUSIC_NEXT');

=head3 add_pointing_button($value)

Add an C<pointing_button> property to a C<from> action:

  add_pointing_button('button2');

=head3 add_optional_modifiers(@values)

Add an C<optional_modifiers> property to keycodes in a C<from> action:

  add_optional_modifiers('control', 'shift', 'command');

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/modifiers/>

See official L<Karbiner documentation|>

=head3 add_mandatory_modifiers(@values)

Add an C<mandatory_modifiers> property to keycodes in a C<from> action:

  add_mandatory_modifiers('shift', 'command');

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/modifiers/>

=head3 add_simulatneous([ $key_code_type = 'key_code' ], @values)

Add an C<simultaneous> property to a C<from> action:

  add_simultaneous('a', 'j');

An optional C<key_code_type> can be passed in as the first argument:

  add_simulataneous('pointing_button', 'button1', 'button2')

If no C<key_code_type> value is detected, a default value of C<key_code> is used.

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/simultaneous/>

=head3 add_simulatneous_options([ $key_code_type = 'key_code' ], @values)

Add an C<simultaneous> property to a C<from> action:

  add_simultaneous_options('key_down_order', 'strict');

Multiple options by set my calling this method multiple times.

See official L<Karbiner documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/from/simultaneous-options/>

=head1 VERSION

version 0.017

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
