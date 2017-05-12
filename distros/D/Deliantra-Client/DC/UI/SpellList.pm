package DC::UI::SpellList;

use common::sense;

use DC::Macro;

our @ISA = DC::UI::Table::;

sub new {
   my $class = shift;

   my $self = $class->SUPER::new (
      binding  => [],
      commands => [],
      @_,
   )
}

my $TOOLTIP_ALL = "\n\n<small>Left click - ready spell\nMiddle click - invoke spell\nRight click - further options</small>";

my @TOOLTIP_NAME = (align => 0, can_events => 1, can_hover => 1, tooltip =>
   "<b>Name</b>. The name of the spell.$TOOLTIP_ALL");
my @TOOLTIP_SKILL = (align => 0, can_events => 1, can_hover => 1, tooltip =>
   "<b>Skill</b>. The skill (or magic school) required to be able to attempt casting this spell.$TOOLTIP_ALL");
my @TOOLTIP_LVL = (align => 1, can_events => 1, can_hover => 1, tooltip =>
   "<b>Effective Casting Level</b>. The effective level of the spell - figures in caster level, attuned and repelled.$TOOLTIP_ALL");
my @TOOLTIP_MIN = (align => 1, can_events => 1, can_hover => 1, tooltip =>
   "<b>Minmimum</b>. Minimum level (without attuned/repelled adjustment) that the caster needs in the associated skill to be able to attempt casting this spell.$TOOLTIP_ALL");
my @TOOLTIP_SP  = (align => 1, can_events => 1, can_hover => 1, tooltip =>
   "<b>Spell points / Grace points</b>. Amount of spell or grace points used by each invocation.$TOOLTIP_ALL");

sub rebuild_spell_list {
   my ($self) = @_;

   $DC::UI::ROOT->on_refresh ($self => sub {
      $self->clear;

      return unless $::CONN;

      my @add;

      push @add,
         1, 0, (new DC::UI::Label text => "Spell Name", @TOOLTIP_NAME),
         2, 0, (new DC::UI::Label text => "Skill", @TOOLTIP_SKILL),
         3, 0, (new DC::UI::Label text => "Min"  , @TOOLTIP_MIN),
         4, 0, (new DC::UI::Label text => "Lvl"  , @TOOLTIP_LVL),
         5, 0, (new DC::UI::Label text => "Sp/Gp", @TOOLTIP_SP),
      ;

      my $row = 0;

      for (sort { $a cmp $b } keys %{ $self->{spell} }) {
         my $spell = $self->{spell}{$_};

         $row++;

         my $spell_cb = sub {
            my ($widget, $ev) = @_;

            if ($ev->{button} == 1) {
               $::CONN->user_send ("cast $spell->{name}");
            } elsif ($ev->{button} == 2) {
               $::CONN->user_send ("invoke $spell->{name}");
            } elsif ($ev->{button} == 3) {
               my $shortname = DC::shorten $spell->{name}, 14;
               (new DC::UI::Menu
                  items => [
                     ["bind <i>cast $shortname</i> to a key"   => sub { DC::Macro::quick_macro ["cast $spell->{name}"] }],
                     ["bind <i>invoke $shortname</i> to a key" => sub { DC::Macro::quick_macro ["invoke $spell->{name}"] }],
                  ],
               )->popup ($ev);
            } else {
               return 0;
            }

            1
         };

         my $tooltip = (DC::asxml $spell->{message}) . $TOOLTIP_ALL;

         #TODO: add path info to tooltip
         #push @add, 6, $row, new DC::UI::Label text => $spell->{path};

         push @add, 0, $row, new DC::UI::Face
            face       => $spell->{face},
            can_hover  => 1,
            can_events => 1,
            tooltip    => $tooltip,
            on_button_down => $spell_cb,
         ;

         push @add, 1, $row, new DC::UI::Label
            expand     => 1,
            text       => $spell->{name},
            align      => 0,
            can_hover  => 1,
            can_events => 1,
            tooltip    => $tooltip,
            on_button_down => $spell_cb,
         ;

         push @add,
            2, $row, (new DC::UI::Label text => $::CONN->{skill_info}{$spell->{skill}}, @TOOLTIP_SKILL),
            3, $row, (new DC::UI::Label text => $spell->{minlevel}, @TOOLTIP_MIN),
            4, $row, (new DC::UI::Label text => $spell->{level}, @TOOLTIP_LVL),
            5, $row, (new DC::UI::Label text => $spell->{mana} ? "$spell->{mana} sp" : "$spell->{grace} gp", @TOOLTIP_SP),
         ;
      }

      $self->add_at (@add);
   });
}

sub add_spell {
   my ($self, $spell) = @_;

   $self->{spell}->{$spell->{name}} = $spell;
   $self->rebuild_spell_list;
}

sub remove_spell {
   my ($self, $spell) = @_;

   delete $self->{spell}->{$spell->{name}};
   $self->rebuild_spell_list;
}

sub clear_spells {
   my ($self) = @_;

   $self->{spell} = {};
   $self->rebuild_spell_list;
}

1

