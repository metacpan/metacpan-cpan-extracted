package JSON::Karabiner::Manipulator ;
$JSON::Karabiner::Manipulator::VERSION = '0.017';
use strict;
use warnings;
use Carp;
use Exporter;
our @EXPORT = qw'new_manipulator add_action add_description add_condition add_parameter add_key_code
  add_key_code add_any add_optional_modifiers add_mandatory_modifiers add_simultaneous add_simultaneous_options add_consumer_key_code add_pointing_button add_shell_command add_select_input_source add_set_variable add_mouse_key add_modifiers
  add_identifier add_description add_value add_bundle_identifiers add_file_path add_input_source add_keyboard_types add_variable add_description _dump_json _fake_write_file write_file set_filename set_title set_rule_name set_save_dir';

sub import {
  strict->import;
  warnings->import;
  goto &Exporter::import
}

sub new_manipulator {
  my @caller = caller(0);
  my $called_directly = $caller[0] eq 'main' ? 1 : 0;
  if ($main::current_manip && $called_directly) {
    write_file($main::file_title_written);
  }
  my $class = 'JSON::Karabiner::Manipulator';

  # trash the first arg if this is using the old school OO interface
  shift if $_[0] && $_[0] =~ /^JSON::Karabiner::Manipulator$/;

  my @kb_obj_args = @_;

  # derive the filename from the called script
  { no warnings 'once';
    if (!$main::save_to_file_name && $called_directly) {

      my $program_name = $0;
      $program_name =~ s/^.*[\/\\]//;
      $program_name =~ s/\..*$//;
      $program_name = "$program_name.json";
      push @kb_obj_args, $program_name;
      $main::save_to_file_name = $program_name;
    } else {
      push @kb_obj_args, $main::save_to_file_name if $main::save_to_file_name;
    }

    if ($called_directly) {
      unshift @kb_obj_args, $main::rule_name if $main::rule_name;
      my $save_to_dir = $main::save_to_dir;
      if ($save_to_dir) {
        push @kb_obj_args, { mod_file_dir => $save_to_dir };
      }
    }
  }


  my $self = {
    actions => {},
    _disable_validity_tests => 0,
    _kb_obj_args => \@kb_obj_args,
    _fake_write_flag => 0,
  };
  bless $self, $class;
  {
    no warnings 'once';
    $main::current_manip = $self;
  }
  return $self;
}

sub set_filename {
  my $fn = shift;
  croak 'You must pass a file name' unless $fn;

  if ($fn !~ /\.json$/) {
    $fn = $fn . '.json';
  }

  $main::save_to_file_name = $fn;
}

sub set_save_dir {
  my $sd = shift;
  croak 'You must pass a file name' unless $sd;
  { no warnings 'once';
    $main::save_to_dir = $sd;
  }
}

sub set_title {
  my $title = shift;
  croak 'You must pass a file name' unless $title;

  $main::file_title_written = $title;
}

sub set_rule_name {
  my $rule_name = shift;
  croak 'You must pass a rule name' unless $rule_name;

  { no warnings 'once';
    $main::rule_name = $rule_name;
  }
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $program = $AUTOLOAD;
  my ($func) = $program =~ /.*::(.*)$/;
  my @action_functions = qw (add_key_code add_any add_optional_modifiers add_mandatory_modifiers add_simultaneous add_simultaneous_options add_consumer_key_code add_pointing_button add_shell_command add_select_input_source add_set_variable add_mouse_key add_modifiers);

  my $is_action_function = grep { $_ eq $func } @action_functions;
  if ($is_action_function) {
    my $current_action;
    {
      no warnings 'once';
      $current_action = $main::current_action;
    }
    $current_action->$func(@_);
    return;
  }

  my @condition_functions = qw(add_identifier add_description add_value add_bundle_identifiers add_file_path add_input_source add_keyboard_types add_variable add_description);

  my $is_condition_function = grep { $_ eq $func } @condition_functions;
  if ($is_condition_function) {
    my $current_condition;
    {
      no warnings 'once';
      $current_condition = $main::current_condition;
    }
    $current_condition->$func(@_);
    return;
  }

}

sub _get_args {
  my @args = @_;
  croak "No args passed" unless @args;

  my $s = shift;
  my $type;
  if (ref $s) {
    $type = shift;
  } else {
    $type = $s;
    $s = $main::current_manip;
  }
  return ($s, $type, @_);
}

sub add_action {
  my ($s, $type) = _get_args(@_);
  croak 'To add a action, you must tell me which kind you\'d like to add' if !$type;

  my $uctype = ucfirst($type);
  my $package = "JSON::Karabiner::Manipulator::Actions::" . $uctype;
  eval "require $package";
  my $action = $package->new($type);
  my %hash = %{$s->{actions}};
  $type = $action->{def_name};
  $hash{$type} = $action->{data};
  $s->{actions} = \%hash;
  return $action;
}

sub add_condition {
  my ($s, $type) = _get_args(@_);
  croak 'To add a condition, you must tell me which kind you\'d like to add' if !$type;

  my $uctype = ucfirst($type);
  my $package = "JSON::Karabiner::Manipulator::Conditions::" . $uctype;
  eval "require $package";
  my $condition = $package->new($type);
  if (defined $s->{actions}{conditions}) {
    push @{$s->{actions}{conditions}}, $condition;
  } else {
    $s->{actions}{conditions} = [ $condition ];
  }
  return $condition;
}

sub add_description {
  my ($s, $desc) = _get_args(@_);

  croak 'To add a description, you must provide one' if !$desc;
  $s->{actions}{description} = $desc;
}

sub add_parameter {
  my ($s, $param, $value) = _get_args(@_);
  croak 'To add a parameter, you must tell me which kind you\'d like to add' if !$param;
  croak 'To add a parameter, you must provide a value' if !$value;

  my @acceptable_values = qw( to_if_alone_timeout_milliseconds
                              alone_timeout
                              alone
                              to_if_held_down_threshold_milliseconds
                              held_down_threshold
                              down_threshold
                              held_down
                              down
                              to_delayed_action_delay_milliseconds
                              delayed_action_delay
                              action_delay
                              delay
                              simultaneous_threshold_milliseconds
                              simultaneous_threshold
                              simultaneous
                              );

  my $param_exists = grep { $param eq $_ } @acceptable_values;
  croak "'$param' in an unrecognzed parameter" unless $param_exists;

  # get param full name
  if ($param =~ /alone/) {
    $param = 'to_if_alone_timeout_milliseconds';
  } elsif ($param =~ /down/) {
    $param = 'to_if_held_down_threshold_milliseconds';
  } elsif ($param =~ /delay/) {
    $param = 'to_delayed_action_delay_milliseconds';
  } elsif ($param =~ /simultaneous/) {
    $param = 'simultaneous_threshold_milliseconds';
  }

  $s->{actions}{parameters}{"basic.$param"} = $value;
}

sub TO_JSON {
  my $obj = shift;
  #TODO: Change this under certain conditions
  $obj->{actions}{type} = 'basic';
  $obj->_do_validity_checks($obj->{actions}) unless $obj->{_disable_validity_tests};
  return $obj->{actions};
}

sub _do_validity_checks {
  my $s = shift;
  my $actions = shift;
  my $from = $actions->{from};
  $s->_do_from_validity_checks($from);
}

sub _dump_json {
  my $s = $main::current_manip;
  my @kb_obj_args = @{$s->{_kb_obj_args}};
  if (!@kb_obj_args) {
    croak "The _dump_json method cannot be run on this manipulator.";
  }

  require JSON::Karabiner;
  my $little_title = shift @kb_obj_args;
  unshift @kb_obj_args, 'SET WITH write_file METHOD';
  my $kb_obj = JSON::Karabiner->new( @kb_obj_args );

  my $rule = $kb_obj->add_rule($little_title);
  my $temp_manip = $rule->add_manipulator();
  %{$temp_manip} = %{$s};
  $kb_obj->_dump_json;
}

sub write_file {
  my $s = $main::current_manip;
  shift if $_[0] && (ref $_[0]) =~ /^JSON::Karabiner::Manipulator$/;
  my $title = shift;

  my $filename;
  if ($title && $title =~ /\.json$/) {
    $filename = $title;
  } else {
    $filename = shift || $main::save_to_file_name || $main::file_written;
  }

  my @kb_obj_args = @{$s->{_kb_obj_args}};
  if (!@kb_obj_args) {
    croak "The _write_file method cannot be run on this manipulator.";
  }

  croak 'You must supply a title for the first manipulator' if !$title && !$main::file_title_written;
  if (!$title) {
    $title = $main::file_title_written;
  }

  require JSON::Karabiner;
  my $little_title = shift @kb_obj_args;
  unshift @kb_obj_args, $title;
  $kb_obj_args[1] = $filename;

  my $kb_obj = JSON::Karabiner->new( @kb_obj_args );
  if ($s->{_fake_write_flag}) {
    $kb_obj->{_fake_write_flag} = 1;
  }
  my $rule = $kb_obj->add_rule($little_title);
  my $temp_manip = $rule->add_manipulator();
  %{$temp_manip} = %{$s};
  $kb_obj->write_file();
  $kb_obj->{_fake_write_flag} = 0;
  {
    no warnings 'once';
    $main::file_written = $kb_obj_args[1];
    $main::file_title_written = $kb_obj_args[0];
  }

}

sub _fake_write_file {
  my $s = $main::current_manip;
  my $title = shift;
  my $file_name = shift;

  my @kb_obj_args = @{$s->{_kb_obj_args}};
  if (!@kb_obj_args) {
    croak "The _fake_write method cannot be run on this manipulator.";
  }

  $s->{_fake_write_flag} = 1;
  $s->write_file($title, $file_name);
  $s->{_fake_write_flag} = 0;
}

sub _do_from_validity_checks {
  my $s = shift;
  my $from = shift;

  if (! defined $from) {
    croak "No 'from' action found in the manipulator. You must add a 'from' action.'";
  }

  if (! %$from) {
    croak "The 'from' action is empty. Perform methods on the 'from' action to tell it how to behave.";
  }

  return;

#  my @from_keys = keys %$from;
#  my $has_key_code = grep { $_ =~ /^any|consumer_key_code|key_code$/ } @from_keys;
#  if (!$has_key_code && grep { $_ =~ /modifiers/ } @from_keys) {
#    croak "You cannot have modifiers without anything to modify in a 'from' action.";
#  }
}

# ABSTRACT: manipulator object for containing and outputting its data

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator - manipulator object for containing and outputting its data

=head1 DESCRIPTION

Please see the L<JSON::Karabiner> for more thorough documentation of this module.
Methods are listed below for reference purposes only.

=head3 new()

=head3 add_action($type)

=head3 add_condition($type)

=head3 add_parameter($name, $value)

=head3 add_description($description)

=head1 VERSION

version 0.017

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
