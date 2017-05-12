package Jifty::DBI::Record::Plugin;

use warnings;
use strict;

use base qw/Exporter/;

=head1 NAME

Jifty::DBI::Record::Plugin - Record model mixins for Jifty::DBI

=head1 SYNOPSIS

  # Define a mixin
  package MyApp::FavoriteColor;
  use base qw/ Jifty::DBI::Record::Plugin /;

  # Define which methods you want to put in the host model
  our @EXPORT = qw(
      favorite_complementary_color
  );

  use Jifty::DBI::Schema;
  use Jifty::DBI::Record schema {
      column favorite_color =>
          type is 'text',
          label is 'Favorite Color',
          valid_values are qw/ red green blue yellow /;
  };

  sub favorite_complementary_color {
      my $self = shift; # whatever host object thing we've mixed with
      my $color = $self->favorite_color;
      return $color eq 'red'    ? 'green'
           : $color eq 'green'  ? 'red'
           : $color eq 'blue'   ? 'orange'
           : $color eq 'yellow' ? 'purple'
           :                      undef;
  }

  # Use the mixin
  package MyApp::Model::User;

  use Jifty::DBI::Schema;
  use Jifty::DBI::Record schema {
      column name =>
          type is 'text',
          label is 'Name';
  };

  # Mixins
  use MyApp::FavoriteColor;

  sub name_and_color {
      my $self  = shift;
      my $name  = $self->name;
      my $color = $self->favorite_color;

      return "The favorite color of $name is $color.";
  }

  sub name_and_complementary_color {
      my $self  = shift;
      my $name  = $self->name;
      my $color = $self->favorite_complementary_color;

      return "The complement of $name's favorite color is $color.";
  }

=head1 DESCRIPTION

By using this package you may provide models that are built from one or more mixins. In fact, your whole table could be defined in the mixins without a single column declared within the model class itself.

=head2 MODEL MIXINS

To build a mixin, just create a model that inherits from this package, C<Jifty::DBI::Record::Plugin>. Then, add the schema definitions you want inherited.

  package MyApp::FasterSwallow;
  use base qw/ Jifty::DBI::Record::Plugin /;
  
  use Jifty::DBI::Schema;
  use Jifty::DBI::Record schema {
      column swallow_type =>
          type is 'text',
          valid are qw/ african european /,
          default is 'african';
  };

=head3 @EXPORT

A mixin may define an C<@EXPORT> variable, which works exactly as advertised in L<Exporter>. That is, given the name of any methods or variable names in the mixin, the host model will gain those methods. 

  our @EXPORT = qw( autocomplete_swallow_type );

  sub autocomplete_swallow_type {
      my $self  = shift;
      my $value = quotemeta(shift);

      # You should probably find a better way than actually doing this...

      my @values;
      push @values, 'african'  if 'african'  =~ /$value/;
      push @values, 'european' if 'european' =~ /$value/;

      return @values;
  }

That way if you have any custom methods you want to throw into the host model, just define them in the mixin and add them to the C<@EXPORT> variable.

=head3 register_triggers

Your mixin may also want to register triggers for the records to which it will be added. You can do this by defining a method named C<register_triggers>:

  sub register_triggers {
      my $self = shift;
      $self->add_trigger( 
          name      => 'before_create', 
          callback  => \&before_create,
          abortable => 1,
      );
  }

  sub before_create {
      # do something...
  }

See L<Class::Trigger>.

=head3 register_triggers_for_column

In addition to the general L</register_triggers> method described above, the mixin may also implement a C<register_triggers_for_column> method. This is called for each column in the table. This is primarily helpful for registering the C<after_set_*> and C<before_set_*> columns.

For example:

  sub register_triggers_for_column {
      my $self   = shift;
      my $column = shift;

      return unless $column ne 'updated_on';

      $self->add_trigger( 
          name      => 'after_set_'.$column, 
          callback  => \&touch_update_time,
          abortable => 1,
      );
  }

  sub touch_update_time {
      my $self = shift;
      $self->set_updated_on(DateTime->now);
  }

This has the additional advantage of being callable when new columns are added to a table while the application is running. This can happen when using database-backed models in Jifty (which, as of this writing, has not been released or made part of the development trunk of Jifty, but is part of the virtual-models branch).

See L<Class::Trigger>.

=head2 MODELS USING MIXINS

To use your model plugin, just use the mixins you want to get columns from. You should still include a schema definition, even if it's empty:

  package MyApp::Model::User;

  use Jifty::DBI::Schema;
  use MyApp::Record schema {
  };

  # Mixins
  use MyApp::FavoriteColor;
  use MyApp::FasterSwallow;
  use Jifty::Plugin::User::Mixin::Model::User;
  use Jifty::Plugin::Authentication::Password::Mixin::Model::User;

=cut

sub import {
    my $self = shift;
    my $caller = caller;
    for ($self->columns) {
        $caller->_init_methods_for_column($_);
        $caller->COLUMNS->{ $_->name } = $_ unless $_->virtual;
    }
    $self->export_to_level(1,undef);
    
    if (my $triggers =  $self->can('register_triggers') ) {
        $triggers->($caller)
    }

    if (my $triggers_for_column =  $self->can('register_triggers_for_column') ) {
        for my $column (keys %{$caller->_columns_hashref}) {
            $triggers_for_column->($caller, $column)
        }
    }

    push(@{ $caller->RECORD_MIXINS }, $self)
}

=head1 SEE ALSO

L<Jifty::DBI::Record>, L<Class::Trigger>

=head1 LICENSE

Jifty::DBI is Copyright 2005-2007 Best Practical Solutions, LLC.
Jifty is distributed under the same terms as Perl itself.

=cut

1;
