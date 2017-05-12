use strict;
use warnings;
package HTML::Widget::Plugin::Combo;
{
  $HTML::Widget::Plugin::Combo::VERSION = '0.004';
}
use parent qw(HTML::Widget::Plugin);
# ABSTRACT: a JavaScript combo box widget

use Data::JavaScript::Anon;

sub provided_widgets { qw(combo) }


sub combo {
  my ($self, $factory, $arg) = @_;
  $arg->{attr}{name} ||= $arg->{attr}{id};

  Carp::croak "you must supply a widget id for combo box"
    unless $arg->{attr}{id};

  my %select_arg = (
    id      => "$arg->{attr}{id}_select",
    name    => $arg->{attr}{id},
    options => $arg->{options},
    attr    => { onChange => 'combo_maybetoggle_select(this)' },
  );

  my $start_with_select = 1;
  my $select = eval {
    $factory->select({ %select_arg, value => $arg->{value} });
  };

  unless ($select) {
    $start_with_select = 0;
    $select = $factory->select({ %select_arg });
  }

  my $input = $factory->input({
    id      => "$arg->{attr}{id}_input",
    name    => $arg->{attr}{id},
    value   => $start_with_select ? '' : $arg->{value},
    attr    => { onBlur => 'combo_maybetoggle_input(this)' },
  });

  return join "\n",
    $self->per_page_js($factory),
    $select,
    $input,
    $self->per_combo_js(
      $factory,
      { id => $arg->{attr}{id}, start_with_select => $start_with_select },
    )
  ;
}


# always included; hides the hidden startup field
sub per_combo_js {
  my ($self, $factory, $arg) = @_;

  my $id_js     = Data::JavaScript::Anon->anon_scalar(\$arg->{id});

  my $active    = $arg->{start_with_select} ? 'select' : 'input';
  my $active_js = Data::JavaScript::Anon->anon_scalar(\$active);

  my $inactive    = $arg->{start_with_select} ? 'input' : 'select';
  my $inactive_js = Data::JavaScript::Anon->anon_scalar(\$inactive);

  return <<"END_JAVASCRIPT";
  <script type='text/javascript'>
  combo_setup_stash($id_js, $active_js);
  combo_hide_half($id_js, $inactive_js);
  </script>
END_JAVASCRIPT
}


# provides the main routines, object
sub per_page_js {
  my ($self, $factory, $arg) = @_;

  return '' if $factory->{$self}->{output_js}++;

  return <<'END_JAVASCRIPT';
  <script type='text/javascript'>
combo_registry = new Object();

function combo_setup_stash(field_name, active) {
  stash = combo_registry[field_name] = new Object();

  stash["select"] = document.getElementById(field_name + "_select");
  stash["input"] = document.getElementById(field_name + "_input");
  stash["active"] = active;
}

function combo_has_special_value(option_element) {
  if (option_element.text == "(other)") return true;
  return false;
}

function combo_maybetoggle_select(select_element) {
  selected_option = select_element.options[select_element.selectedIndex];
  if (combo_has_special_value(selected_option)) {
    combo_toggle(select_element.name);
    combo_registry[select_element.name]["input"].select();
    combo_registry[select_element.name]["input"].focus();
  }
}

function combo_maybetoggle_input(input_element) {
  if (input_element.value == "") combo_toggle(input_element.name);
}

function combo_hide_half(element_name, hide_which) {
  var combo = combo_registry[element_name];
  if (combo == null) return false; // This shouldn't happen!
  
  to_hide = combo[hide_which];
  to_hide.parentNode.removeChild(to_hide);
}

function combo_toggle(element_name) {
  var combo = combo_registry[element_name];
  if (combo == null) return false; // This shouldn't happen!

  var active_element = combo[combo["active"]];
  if (combo["active"] == "select") {
    active_element.parentNode.replaceChild( combo["input"], combo["select"] );
    combo["input"].disabled = false;
    combo["select"].disabled = true;
    combo["active"] = "input";
  } else {
    active_element.parentNode.replaceChild( combo["select"], combo["input"] );
    combo["input"].disabled = true;
    combo["select"].disabled = false;
    combo["active"] = "select";
    current_value = combo["select"].options[combo["select"].selectedIndex];
    if (combo_has_special_value(current_value)) {
      combo["select"].selectedIndex = 0;
    }
  }
}
  </script>
END_JAVASCRIPT
}

1;

__END__

=pod

=head1 NAME

HTML::Widget::Plugin::Combo - a JavaScript combo box widget

=head1 VERSION

version 0.004

=head2 combo

This widget produces a combo box.  It's a select box with an option for "other"
that causes it to be replaced with a text input box.

Valid arguments are:

  id      - required
  options - as per select widget
  value   - as per select widget

=head2 per_combo_js

This method returns JavaScript to be run after each combo box is defined.

=head2 per_page_js

This method returns JavaScript to be run once per page.

=head1 AUTHOR

Ricardo SIGNES

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
