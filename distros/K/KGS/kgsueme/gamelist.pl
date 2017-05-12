package gamelist;

use KGS::Constants;

use Glib::Object::Subclass
   Gtk2::VPaned;

sub new {
   my ($class, %arg) = @_;
   my $self = $class->Glib::Object::new;
   $self->{$_} = delete $arg{$_} for keys %arg;

   $self->signal_connect (destroy => sub {
      %{$_[0]} = ();
   });

   $self->set(position_set => 1);
   gtk::state $self, "gamelist::vpane", undef, position => 120;

   $self->{model1} = new Gtk2::ListStore Glib::Scalar,
        Glib::String, Glib::String, Glib::String, Glib::String, Glib::Int, Glib::String, Glib::String;
   gtk::state $self->{model1}, "gamelist::model1", undef, modelsortorder => [4, 'descending'];

   $self->add(my $sw = new Gtk2::ScrolledWindow);
   $sw->set_policy("never", "always");
   $sw->add($self->{view1} = new Gtk2::TreeView $self->{model1});
   $self->{view1}->set (rules_hint => 1, search_column => 2);

   $self->{model2} = new Gtk2::ListStore Glib::Scalar,
        Glib::String, Glib::String, Glib::String, Glib::String, Glib::Int,
        Glib::String, Glib::String, Glib::Int, Glib::Int, Glib::Int, Glib::String;
   gtk::state $self->{model2}, "gamelist::model1", undef, modelsortorder => [4, 'descending'];

   $self->add(my $sw = new Gtk2::ScrolledWindow);
   $sw->set_policy("never", "always");
   $sw->add($self->{view2} = new Gtk2::TreeView $self->{model2});
   $self->{view2}->set_search_column(1);
   $self->{view2}->set (rules_hint => 1, search_column => 2);

   for my $view ($self->{view1}, $self->{view2}) {
      push @{$self->{rlcolumns}}, my $column =
         Gtk2::TreeViewColumn->new_with_attributes ("Room", $gtk::text_renderer, text => 1);
      $column->set_sort_column_id(1);
      $column->set(resizable => 1);
      $column->set(sizing => 'fixed');
      gtk::state $column, "gamelist::model::Room", undef, column_size => 80;
      $view->append_column ($column);

      push @{$self->{rlcolumns}}, my $column =
         Gtk2::TreeViewColumn->new_with_attributes ("T", $gtk::text_renderer, text => 2);
      $column->set_sort_column_id(2);
      $column->set(sizing => 'grow-only');
      $view->append_column ($column);

      push @{$self->{rlcolumns}}, my $column =
         Gtk2::TreeViewColumn->new_with_attributes ("Owner", $gtk::text_renderer, text => 3);
      $column->set_sort_column_id(3);
      $column->set(resizable => 1);
      $column->set(sizing => 'fixed');
      gtk::state $column, "gamelist::model::Owner", undef, column_size => 100;
      $view->append_column ($column);

      push @{$self->{rlcolumns}}, my $column =
         Gtk2::TreeViewColumn->new_with_attributes ("Rk", $gtk::text_renderer, text => 4);
      $column->set_sort_column_id(5);
      $column->set(sizing => 'grow-only');
      $view->append_column ($column);
   }

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Info", $gtk::text_renderer, text => 6);
   $column->set(resizable => 1);
   $column->set(sizing => 'autosize');
   gtk::state $column, "gamelist::model::Info", undef, column_size => 80;
   $self->{view1}->append_column ($column);

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Notes", $gtk::text_renderer, text => 7);
   $column->set(resizable => 1);
   $column->set(sizing => 'autosize');
   gtk::state $column, "gamelist::model::Notes", undef, column_size => 200;
   $self->{view1}->append_column ($column);

   ###########

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Opponent", $gtk::text_renderer, text => 6);
   $column->set(resizable => 1);
   $column->set(sizing => 'fixed');
   gtk::state $column, "gamelist::model::Opponent", undef, column_size => 120;
   $self->{view2}->append_column ($column);

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Rk", $gtk::text_renderer, text => 7);
   $column->set_sort_column_id(8);
   $column->set(sizing => 'grow-only');
   $self->{view2}->append_column ($column);

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Mv", $gtk::int_renderer, text => 9);
   $column->set_sort_column_id(9);
   $column->set(sizing => 'grow-only');
   $self->{view2}->append_column ($column);

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Ob", $gtk::int_renderer, text => 10);
   $column->set_sort_column_id(10);
   $column->set(sizing => 'grow-only');
   $self->{view2}->append_column ($column);

   push @{$self->{rlcolumns}}, my $column =
      Gtk2::TreeViewColumn->new_with_attributes ("Info", $gtk::text_renderer, text => 11);
   $column->set(resizable => 1);
   $column->set(sizing => 'autosize');
   gtk::state $column, "gamelist::model::Info", undef, column_size => 120;
   $self->{view2}->append_column ($column);

   ###########

   $self->{view1}->signal_connect(row_activated => sub {
      my ($widget, $path, $column) = @_;
      my $game = $self->{model1}->get ($self->{model1}->get_iter ($path), 0);
      $self->{app}->open_game (%$game); # challenging private game sis allowed
      1;
   });

   $self->{view2}->signal_connect(row_activated => sub {
      my ($widget, $path, $column) = @_;
      my $game = $self->{model2}->get ($self->{model2}->get_iter ($path), 0);
      $self->{app}->open_game (%$game) unless $game->is_private;
      1;
   });

   $self;
}

sub update {
   my ($self, $room, $add, $update, $remove) = @_;

   $self->{games}{$room->{name}} = $room->{games};

   my $m1 = $self->{model1};
   my $m2 = $self->{model2};

   for (@$remove) {
      (delete $_->{model})->remove (delete $_->{iter}) if $_->{model};
   }

   for (@$add, @$update) {
      my $owner = $_->owner;
      if ($_->is_inprogress) {
         (delete $_->{model})->remove (delete $_->{iter}) if $_->{model} && $_->{model} != $m2;#d#
         $_->{model} = $m2;
         $m2->set ($_->{iter} ||= $m2->append,
                      0, $_,
                      1, $room->{name},
                      2, $_->type_char,
                      3, $owner->{name},
                      4, $owner->rank_string,
                      5, $owner->rank_number,
                      6, $_->opponent_string,
                      7, $_->{black}->rank_string,
                      8, $_->{black}->rank_number,
                      9, $_->moves,
                     10, $_->{observers},
                     11, $_->rules,
                  );
      } else {
         (delete $_->{model})->remove (delete $_->{iter}) if $_->{model} && $_->{model} != $m1;#d#
         $_->{model} = $m1;
         $m1->set ($_->{iter} ||= $m1->append,
                      0, $_,
                      1, $room->{name},
                      2, $_->type_char,
                      3, $owner->{name},
                      4, $owner->rank_string,
                      5, $owner->rank_number,
                      6, $_->rules,
                      7, $_->{notes},
                  );
      }
   }
}

1;

