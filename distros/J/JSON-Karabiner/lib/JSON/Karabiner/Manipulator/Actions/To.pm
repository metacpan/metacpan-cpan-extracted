package JSON::Karabiner::Manipulator::Actions::To ;
$JSON::Karabiner::Manipulator::Actions::To::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;
use parent 'JSON::Karabiner::Manipulator::Actions';

sub new {
  my $class = shift;
  my ($type, $value) = @_;
  my $obj = $class->SUPER::new($type, $value);
  $obj->{data} = $value || [],
  $obj->{shell_command} => 0,
  $obj->{select_input_source} => 0,
  $obj->{select_input_source_data} => '',
  $obj->{set_variable} => 0,
  $obj->{mouse_key} => 0,
  return $obj;
}

sub add_key_code {
  my $s = shift;
  my @key_codes;
  if (ref $s) {
    @key_codes = @_;
  } else {
    @key_codes = ($s, @_);
    $s = $main::current_action;
  }
  my $last_arg = $key_codes[-1];
  my $input_type = 'key_code';
  if ($last_arg && $last_arg =~ /^any|consumer_key_code|pointing_button$/) {
    $input_type = $last_arg;
    pop @key_codes;
  }
  croak 'No key code passed' if !@key_codes;
  croak 'You can only set one key_code, consumer_key_code, pointing_button or any'  if ($s->{code_set});
  #TODO: validate $key_code

  $s->_is_exclusive($input_type);

  foreach my $key_code (@key_codes) {
    my %hash;
    my $letter_code;
    my $ms;
    if ($key_code =~ /-([A-Z])|-(\d+)$/) {
      $letter_code = $1;
      $ms = $2;
      $key_code =~ s/-(.*?)$//;
    }

    $hash{$input_type} = $key_code;
    $hash{lazy} = JSON::true if $letter_code && $letter_code eq 'L';
    $hash{halt} = JSON::true if $letter_code && $letter_code eq 'H';
    $hash{repeat} = JSON::true if $letter_code && $letter_code eq 'R';
    $hash{hold_down_milliseconds} = $ms if $ms;
    $s->_push_data(\%hash);
    $s->{last_key_code} = \%hash;
  }
}

sub _push_data {
  my $s = shift;
  my $data = shift;
  if ($s->{def_name} eq 'to_delayed_action') {
    if ($s->{delayed_type} eq 'invoked') {
      push @{$s->{data}{to_if_invoked}}, $data;
    } else {
      push @{$s->{data}{to_if_canceled}}, $data;
    }
  } else {
    push @{$s->{data}}, $data;
  }
}

sub add_shell_command {
  my $s = shift;

  $s->_is_exclusive('shell_command');
  my $value = shift;
  my %hash;
  $hash{shell_command} = $value;
  $s->_push_data(\%hash);
}

sub add_select_input_source {
  my $s = shift;
  $s->_is_exclusive('select_input_source');
  my $option = shift;
  my $value = shift;
  if ($option !~ /^language|input_source_id|input_mode_id$/) {
    croak "Invalid option: $option";
  }

  #TODO: determing if key alredy exists
  # find existing hash ref
  my $existing = $s->{select_input_source_data};
  my $select_input_source = $existing || { };

  $select_input_source->{$option} = $value;
  $s->_push_data( { select_input_source => $select_input_source } ) if !$existing;
}

sub add_set_variable {
  my $s = shift;
  $s->_is_exclusive('set_variable');
  my $name = shift;
  croak 'No name passed' unless defined $name;
  my $value = shift;
  croak 'No value passed' unless defined $value;

  if ($value =~ /^\d+$/) {
    $value = $value + 0;
  }

  my %hash;
  $hash{set_variable}{name} = $name;
  $hash{set_variable}{value} = $value;
  $s->_push_data(\%hash);
}

sub add_mouse_key {
  my $s = shift;
  $s->_is_exclusive('mouse_key');
  my $name = shift;
  croak 'No name passed' unless $name;
  my $value = shift;
  croak 'No value passed' unless defined $value;

  #TODO: make sure $names have not been set already
  #TODO: make sure names are valid
  my %hash;
  $hash{mouse_key}{$name} = $value;
  $s->_push_data(\%hash);
}

sub add_modifiers {
  my $s = shift;
  my $lkc = $s->{last_key_code};
  croak 'Nothing to attach the modifiers to' if !$lkc;
  my $existing = [];
  if (exists $lkc->{modifiers} ) {
    $existing = $lkc->{modifiers};
  }

  #TODO: check that modifiers are valid
  my @modifiers = @_;
  push @$existing, @modifiers;
  $lkc->{modifiers} = $existing;
}

# ABSTRACT: To action object

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Actions::To - To action object

=head1 SYNOPSIS

  add_action 'to';

  # Use methods to add data to the C<to> action:
  add_key_code 'h', 'i', 'x';
  add_modifiers 'control', 'left_shift';

  # Other "to" actions may be added as well:

  add_action 'to_if_alone';

=head1 DESCRIPTION

The C<To> actions describe what Karbiner will do when the C<from> action
associated with the C<to> action is triggered. For example, you may want
Karbiner to execute a shell script if C<control-shift-h> is pressed.

Below are the methods used to add data to the C<to> action. Note that the
methods below also apply to the other C<to> actions (C<to_if_alone>,
C<to_after_key_up>, etc.)

Consult the official L<Karbiner
documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/>
about the C<to> data structure.

=head3 new($type)

The constructor method is not called directly. The C<to> action object is more
typically created via the manipulator object's C<add_action()> method.

=head3 add_key_code(@values)

Add a C<key_code> property to a C<to> action:

  add_key_code 'h', 'i', 'x';

Special properties for key codes (C<lazy>, C<repeat>, C<halt> and C<hold_down_millisecond>
can be attached with the following special notation:

  add_key_code 'h-L'   # adds a "lazy" property to key code
  add_key_code 'h-R'   # adds a "repeat" property to key code
  add_key_code 'h-H'   # adds a "halt" property to key code
  add_key_code 'h-200' # adds a "hold_down_milliseconds" property to the key
                        # code with the value set to the number specified after the dash

=head3 add_consumer_key_code($value)

Add a C<consumer_key_code> property to a C<from> action:

  add_consumer_key_code 'MUSIC_NEXT';

=head3 add_pointing_button($value)

Add a C<pointing_button> property to a C<from> action:

  add_pointing_button 'button2';

=head3 add_shell_command($command)

Add a C<shell_command> property to a C<to> action:

  add_shell_command 'ls';

=head3 add_select_input_source($option, $value)

Add a C<select_input_source> property to a C<to> action:

  select_input_source 'language', 'language regex';

Multiple option/value pairs may be set by calling this method multiple times.

https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/select-input-source/

=head3 add_select_input_source($option, $value)

Add a C<select_input_source> property to a C<to> action:

  add_select_input_source 'language', 'language regex';

Multiple option/value pairs may be set by calling this method multiple times.

=head3 add_set_variable($name, $value)

Add a C<set_value> property to a C<to> action:

  add_set_variable 'some_variable', '1';

=head3 add_mouse_key($name, $value)

Add a C<mouse_key> property to a C<to> action:

  add_mouse_key 'speed_multiplier', '1.0';

Multiple name/value pairs may be set by calling this method multiple times.

https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/to/mouse-key/

=head3 add_modifiers(@modifiers)

Add a C<modifiers> property to a keys in a C<to> action:

  add_modifiers 'left_shift', 'left_command';

The modifiers can only be applied to the last key/buttons added to the object.
In other words, if you need to apply to modifier to more than one key, add the
keys that require modifiers individually and then add the modifiers.

=head1 VERSION

version 0.018

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
