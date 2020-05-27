package JSON::Karabiner::Manipulator::Conditions ;
$JSON::Karabiner::Manipulator::Conditions::VERSION = '0.018';
use strict;
use warnings;
use JSON;
use Carp;


sub new {
  my $class = shift;
  my $type = shift;

  my $self = {
    def_name => $type,

  };
  bless $self, $class;
  {
    no warnings 'once';
    $main::current_condition = $self;
  }
  return $self;
}

sub TO_JSON {
  my $obj = shift;
  my $name = $obj->{def_name};
  my $value = $obj->{data};
  my @data_hash = @{$obj->{data}};
  my %super_hash = ();
  foreach my $hash (@data_hash) {
    my %hash = %$hash;
    %super_hash = (%super_hash, %hash);
  }
  %super_hash = (%super_hash, type => $name);
  return { %super_hash };

}

# ABSTRACT: parent class for condition classes

1;

__END__

=pod

=head1 NAME

JSON::Karabiner::Manipulator::Conditions - parent class for condition classes

=head1 SYNOPSIS

  # add the condition
  add_condition('variable_if');

  # add data to it with the appropriate method
  add_variable('some_var_name' => 'some_value')

=head1 DESCRIPTION

Condtions make the C<from> and C<to> actions conditional upon the values of other
data. This gives you more control over when and under what environments your actions
will occur. Below is an overview of how to set the conditions available to you
via Karabiner.

Note that the condition objects must be created before you can add data to them.
See the example in the Synopsis above.

=head3 'device_if' and 'device_unless'

  add_identifier('vendor_id' => 5, 'product_id' => 2222);
  add_identifier('vendor_id' => 6, 'product_id' => 2223);
  add_description 'some description';

See L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/device/>

=head3 'event_changed_if' and 'event_chaned_unless'

  add_value 'true' ;
  add_description 'some description';

See L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/event-changed/>

=head3 'frontmost_application_if' and 'frontmost_application_unless'

  add_bundle_identifiers 'bundle_id_one', 'bundle_id_two';
  add_file_paths 'file_path1', 'file_path2';
  add_description 'some description';

See L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/frontmost-application/>

=head3 'input_source_if', and 'input_source_unless'

  add_input_source ('language' => 'languare regex', 'input_source_id' => 'input source id regex');
  add_input_source ('language' => 'languare regex', 'input_source_id' => 'input source id regex');
  add_description 'some description';

See L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/input-source/>

=head3 'keyboard_type_if', and 'keyboard_type_unless'

  add_keyboard_types 'keybd_type1', 'keybd_type2'
  add_description 'some description'

SeE L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/keyboard-type/>

=head3 'variable_if', and 'variable_unless'

  add_variable 'variable_name' => 'value';

See L<Karabiner official documentation|https://karabiner-elements.pqrs.org/docs/json/complex-modifications-manipulator-definition/conditions/variable/>

=head1 VERSION

version 0.018

=head1 AUTHOR

Steve Dondley <s@dondley.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Steve Dondley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
