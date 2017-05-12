=head1 NAME

Games::EverQuest::LogLineParser - Perl extension for parsing lines from the
EverQuest log file.

=head1 SYNOPSIS

   use Games::EverQuest::LogLineParser;

   my $eqlog_file = 'c:/everquest/eqlog_Soandso_veeshan.txt';

   open(my $eq_log_fh, $eqlog_file) || die "$eqlog_file: $!";

   while (<$eq_log_fh>)
      {
      my $parsed_line = parse_eq_line($_);
      next unless $parsed_line;
      do_something($parsed_line);
      }

=head1 DESCRIPTION

C<Games::EverQuest::LogLineParser> provides functions related to parsing the
interesting bits from an EverQuest log file.

=head2 Functions

=over 4

=item C<parse_eq_line($eq_line)>

Returns a hash ref, containing variable keys depending on the determined line
type of the given log line. If the line was not recognized, then false is
returned.

Two keys that will always be present, if the line was recognized, are
C<time_stamp> and C<line_type>. The first will contain the time string from
the line, while the latter will be a string indicating how the line was
classified. A given C<line_type> hash ref, will always contain the same keys,
though some of the values may be C<undef> or empty.

For a list of line types (and associated keys) see the L<LINE TYPES> section
below.

=item C<parse_eq_line_type($line_type, $eq_line)>

If you expect a line to be of a certain type, and want to test or parse it as
that type, you can use this function. Call it with the expected line type
and the log line to test or parse.

Returns a hash ref, containing variable keys depending on the type of line
that was passed. If the line could not be parsed as the given line type,
then false is returned.

Two keys that will always be present, if the line was recognized, are
C<time_stamp> and C<line_type>. The first will contain the time string from
the line, while the latter will be a string indicating how the line was
classified. A given C<line_type> hash ref, will always contain the same keys,
though some of the values may be C<undef> or empty.

For a list of line types (and associated keys) see the L<LINE TYPES> section
below.

=item C<parse_eq_time_stamp($parsed_line->{'time_stamp'})>

Given the C<time_stamp> value from a parsed line, returns a hash ref with the
following structure:

   ## sample input [Mon Oct 13 00:42:36 2003]
   {
    day   => 'Mon',
    month => 'Oct',
    date  => '13',
    hour  => '00',
    min   => '42',
    sec   => '36',
    year  => '2003',
   }

=item C<all_possible_line_types()>

Returns a list of all possible line types for the hash refs that are returned by
C<parse_eq_line()>.

=item C<all_possible_keys()>

Returns a list of all possible keys for the hash refs that are returned by
C<parse_eq_line()>.

=back

=head1 EXPORT

By default the C<parse_eq_line>, C<parse_eq_line_type>, C<parse_eq_time_stamp>,
C<all_possible_line_types> and C<all_possible_keys> subroutines are exported.

=head1 SCRIPTS

Several scripts have been included as both tools and examples. All default to
STDOUT for output, but accept an optional file name for the second argument
as well.

=over 4

=item eqlog2csv.pl <eqlog_file> [output_file]

   Converts an EverQuest log file into a CSV file (uses '|' character rather than commas).

=item eqlog_line_type_frequency.pl <eqlog_file> [output_file]

   Reports the frequency of all line types seen in the given EverQuest log file.

=item eqlog_unrecognized_lines.pl <eqlog_file> [output_file]

   Prints unrecognized lines from an EverQuest log file.

=back

=head1 LINE TYPES

=over 4

=cut

package Games::EverQuest::LogLineParser;

use 5.006;
use strict;
use warnings;

use Carp;

require Exporter;

our @ISA = qw/ Exporter /;

our @EXPORT = qw/ parse_eq_line parse_eq_line_type parse_eq_time_stamp
                  all_possible_line_types all_possible_keys /;

our @EXPORT_OK = qw( coins_to_platinum );

our $VERSION = '0.09';

my (@line_types, %line_types);


# $BAZAAR_PRICE is used in many bzrlog regexps.
my $BAZAAR_PRICE = qr/(?: (\d+)p)?(?: (\d+)g)?(?: (\d+)s)?(?: (\d+)c)?/;

## returns a parsed line hash ref if the line is understood, else false
sub parse_eq_line
   {
   my ($line) = @_;

   return unless length $line > 28;

   $line =~ tr/\r\n//d;

   my $time_stamp = substr($line, 0, 27, '');

   for my $line_type (@line_types)
      {
      if (my @parts = $line =~ $line_type->{'rx'})
         {
         my $parsed_line = $line_type->{'handler'}->(@parts);
         $parsed_line->{'time_stamp'} = $time_stamp;
         if(exists $parsed_line->{platinum}) {
            $parsed_line->{value} = coins_to_platinum(%$parsed_line);
         }
         return $parsed_line;
         }
      }

   return;

   }

## returns a parsed line hash ref if the line is of the given type, else false
sub parse_eq_line_type
   {
   my ($line_type_name, $line) = @_;

   confess "invalid line type ($line_type_name)"
      unless exists $line_types{$line_type_name};

   return unless length $line > 28;

   $line =~ tr/\r\n//d;

   my $time_stamp = substr($line, 0, 27, '');

   if (my @parts = $line =~ $line_types{$line_type_name}->{'rx'})
      {
      my $parsed_line = $line_types{$line_type_name}->{'handler'}->(@parts);
      $parsed_line->{'time_stamp'} = $time_stamp;
      if(exists $parsed_line->{platinum}) {
         $parsed_line->{value} = coins_to_platinum(%$parsed_line);
      }
      return $parsed_line;
      }

   return;

   }

## parses the time_stamp into a hash ref
## sample input [Mon Oct 13 00:42:36 2003]
sub parse_eq_time_stamp
   {
   my ($time_stamp) = @_;

   $time_stamp =~ tr/][:/ /;

   my ($day, $month, $date, $hour, $min, $sec, $year) = split ' ', $time_stamp;

   return
      {
      day   => $day,
      month => $month,
      date  => $date,
      hour  => $hour,
      min   => $min,
      sec   => $sec,
      year  => $year
      };

   }

## returns all possible line types
sub all_possible_line_types
   {

   return map { $_->{'handler'}->()->{'line_type'} } @line_types;

   }

## returns all possible keys from the set of all parsed line hash refs
## 'time_stamp' and 'value' are special-cased, as they're automatically
## added after the line is parsed.

sub all_possible_keys
   {

   my %all_keys;

   for my $line_type (@line_types)
      {
      for my $key (keys %{ $line_type->{'handler'}->() })
         {
         $all_keys{$key}++;
         }
      }

   return ( sort (keys %all_keys, 'time_stamp', 'value') );

   }

## Converts a list of coins into a decimalised platinum figure.
## eg: 12pp 5gp 3sp 6cp = 12.536
sub coins_to_platinum {
   my %coins = @_;

   return  $coins{platinum}            + 
          ($coins{gold    } || 0)/  10 + 
          ($coins{silver  } || 0)/ 100 +
          ($coins{copper  } || 0)/1000;
}

=item MELEE_DAMAGE

   input line:

      [Mon Oct 13 00:42:36 2003] You slash a Bloodguard crypt sentry for 88 points of damage.

   output hash ref:

      {
         line_type  => 'MELEE_DAMAGE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'You',
         attack     => 'slash',
         attackee   => 'A Bloodguard crypt sentry',
         amount     => '88',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) (slash|hit|kick|pierce|bash|punch|crush|bite|maul|backstab|claw|strike)(?:s|es)? (?!by non-melee)(.+?) for (\d+) points? of damage\.\z/,
   handler => sub
      {
      my ($attacker, $attack, $attackee, $amount) = @_;
      return
         {
         line_type  => 'MELEE_DAMAGE',
         attacker   => $attacker,
         attack     => $attack,
         attackee   => $attackee,
         amount     => $amount,
         };
      }

   };

=item YOU_MISS_MOB

   input line:

      [Mon Oct 13 00:42:36 2003] You try to kick a Bloodguard crypt sentry, but miss!

   output hash ref:

      {
         line_type  => 'YOU_MISS_MOB',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attack     => 'slash',
         attackee   => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou try to (\w+) (.+?), but miss!\z/,
   handler => sub
      {
      my ($attack, $attackee) = @_;
      return
         {
         line_type  => 'YOU_MISS_MOB',
         attack     => $attack,
         attackee   => $attackee,
         };
      }
   };

=item OTHER_MISSES

   input line:

      [Mon Oct 13 00:42:36 2003] A Bloodguard crypt sentry tries to hit YOU, but misses!

   output hash ref:

      {
         line_type  => 'OTHER_MISSES',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'A Bloodguard crypt sentry',
         attack     => 'hit',
         attackee   => 'YOU',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso tries to slash a Bloodguard crypt sentry, but misses!

   output hash ref:

      {
         line_type  => 'OTHER_MISSES',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'Soandso',
         attack     => 'slash',
         attackee   => 'a Bloodguard crypt sentry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) tries to (\w+) (.+?), but misses!\z/,
   handler => sub
      {
      my ($attacker, $attack, $attackee) = @_;
      return
         {
         line_type  => 'OTHER_MISSES',
         attacker   => $attacker,
         attack     => $attack,
         attackee   => $attackee,
         };
      }
   };

=item FACTION_HIT

   input line:

      [Mon Oct 13 00:42:36 2003] Your faction standing with Loyals got worse.

   output hash ref:

      {
         line_type      => 'FACTION_HIT',
         time_stamp     => '[Mon Oct 13 00:42:36 2003] ',
         faction_group  => 'Loyals',
         faction_change => 'worse',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour faction standing with (.+?) got (better|worse)\.\z/,
   handler => sub
      {
      my ($faction_group, $faction_change) = @_;
      return
         {
         line_type      => 'FACTION_HIT',
         faction_group  => $faction_group,
         faction_change => $faction_change,
         };
      }

   };

=item YOU_REPEL_HIT

   input line:

      [Mon Oct 13 00:42:36 2003] A Bloodguard crypt sentry tries to hit YOU, but YOU parry!

   output hash ref:

      {
         line_type  => 'YOU_REPEL_HIT',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'A Bloodguard crypt sentry',
         attack     => 'hit',
         repel      => 'parry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) tries to (\w+) YOU, but YOU (\w+)!\z/,
   handler => sub
      {
      my ($attacker, $attack, $repel) = @_;
      return
         {
         line_type  => 'YOU_REPEL_HIT',
         attacker   => $attacker,
         attack     => $attack,
         repel      => $repel,
         };
      }

   };

=item MOB_REPELS_HIT

   input line:

      [Mon Oct 13 00:42:36 2003] You try to slash a Bloodguard crypt sentry, but a Bloodguard crypt sentry ripostes!

   output hash ref:

      {
         line_type  => 'MOB_REPELS_HIT',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attack     => 'slash',
         attackee   => 'A Bloodguard crypt sentry',
         repel      => 'riposte',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou try to (\w+) (.+?), but \2 (\w+)s!\z/,
   handler => sub
      {
      my ($attack, $attackee, $repel) = @_;
      $repel ||= '';
      $repel = 'parry' if $repel eq 'parrie';
      return
         {
         line_type  => 'MOB_REPELS_HIT',
         attack     => $attack,
         attackee   => $attackee,
         repel      => $repel,
         };
      }

   };

=item SLAIN_BY_YOU

   input line:

      [Mon Oct 13 00:42:36 2003] You have slain a Bloodguard crypt sentry!

   output hash ref:

      {
         line_type  => 'SLAIN_BY_YOU',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         slayee     => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have slain (.+?)!\z/,
   handler => sub
      {
      my ($slayee) = @_;
      return
         {
         line_type  => 'SLAIN_BY_YOU',
         slayee     => $slayee,
         };
      }

   };

=item SKILL_UP

   input line:

      [Mon Oct 13 00:42:36 2003] You have become better at Abjuration! (222)

   output hash ref:

      {
         line_type   => 'SKILL_UP',
         time_stamp  => '[Mon Oct 13 00:42:36 2003] ',
         skill_upped => 'Abjuration',
         skill_value => '222',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have become better at (.+?)! \((\d+)\)\z/,
   handler => sub
      {
      my ($skill_upped, $skill_value) = @_;
      return
         {
         line_type   => 'SKILL_UP',
         skill_upped => $skill_upped,
         skill_value => $skill_value,
         };
      }

   };

=item SLAIN_BY_OTHER

   input line:

      [Mon Oct 13 00:42:36 2003] a Bloodguard crypt sentry has been slain by Soandso!

   output hash ref:

      {
         line_type  => 'SLAIN_BY_OTHER',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         slayee     => 'A Bloodguard crypt sentry',
         slayer     => 'Soandso',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) has been slain by (.+?)!\z/,
   handler => sub
      {
      my ($slayee, $slayer) = @_;
      return
         {
         line_type  => 'SLAIN_BY_OTHER',
         slayee     => $slayee,
         slayer     => $slayer,
         };
      }

   };

=item CORPSE_MONEY

   input line:

      [Mon Oct 13 00:42:36 2003] You receive 67 platinum, 16 gold, 20 silver and 36 copper from the corpse.

   output hash ref:

      {
         line_type  => 'CORPSE_MONEY',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => '67',
         gold       => '16',
         silver     => '20',
         copper     => '36',
         value      => 68.8360,
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou receive (.+?)from the corpse\.\z/,
   handler => sub
      {
      my ($money) = @_;
      $money ||= '';
      $money =~ s/and//;
      my %moneys = reverse split '[ ,]+', $money;
      return
         {
         line_type  => 'CORPSE_MONEY',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         };
      }

   };

=item DAMAGE_SHIELD

   input line:

      [Mon Oct 13 00:42:36 2003] a Bloodguard crypt sentry was hit by non-melee for 8 points of damage.

   output hash ref:

      {
         line_type  => 'DAMAGE_SHIELD',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'A Bloodguard crypt sentry',
         amount     => '8',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) was hit by non-melee for (\d+) points? of damage\.\z/,
   handler => sub
      {
      my ($attacker, $amount) = @_;
      return
         {
         line_type  => 'DAMAGE_SHIELD',
         attacker   => $attacker,
         amount     => $amount,
         };
      }

   };

=item DIRECT_DAMAGE

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso hit a Bloodguard crypt sentry for 300 points of non-melee damage.

   output hash ref:

      {
         line_type  => 'DIRECT_DAMAGE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'Soandso',
         attackee   => 'A Bloodguard crypt sentry',
         amount     => '300',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) hit (.+?) for (\d+) points? of non-melee damage\.\z/,
   handler => sub
      {
      my ($attacker, $attackee, $amount) = @_;
      return
         {
         line_type  => 'DIRECT_DAMAGE',
         attacker   => $attacker,
         attackee   => $attackee,
         amount     => $amount,
         };
      }

   };

=item DAMAGE_OVER_TIME

   input line:

      [Mon Oct 13 00:42:36 2003] A Bloodguard crypt sentry has taken 3 damage from your Flame Lick.

   output hash ref:

      {
         line_type  => 'DAMAGE_OVER_TIME',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attackee   => 'A Bloodguard crypt sentry',
         amount     => '3',
         spell      => 'Flame Lick',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) has taken (\d+) damage from your (.+?)\.\z/,
   handler => sub
      {
      my ($attackee, $amount, $spell) = @_;
      return
         {
         line_type  => 'DAMAGE_OVER_TIME',
         attackee   => $attackee,
         amount     => $amount,
         spell      => $spell,
         };
      }

   };

=item LOOT_ITEM

   input line:

      [Mon Oct 13 00:42:36 2003] --You have looted a Flawed Green Shard of Might.--

   output hash ref:

      {
         line_type  => 'LOOT_ITEM',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         looter     => 'You',
         item       => 'Flawed Green Shard of Might',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] --Soandso has looted a Tears of Prexus.--

   output hash ref:

      {
         line_type  => 'LOOT_ITEM',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         looter     => 'Soandso',
         item       => 'Tears of Prexus',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A--(\S+) (?:has|have) looted a (.+?)\.--\z/,
   handler => sub
      {
      my ($looter, $item) = @_;
      return
         {
         line_type  => 'LOOT_ITEM',
         looter     => $looter,
         item       => $item,
         };
      }

   };

=item BUY_ITEM

   input line:

      [Mon Oct 13 00:42:36 2003] You give 1 gold 2 silver 5 copper to Cavalier Aodus.

   output hash ref:

      {
         line_type  => 'BUY_ITEM',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => 0,
         gold       => '1',
         silver     => '2',
         copper     => '4',
         value      => 0.124,
         merchant   => 'Cavalier Aodus',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou give (.+?) to (.+?)\.\z/,
   handler => sub
      {
      my ($money, $merchant) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         line_type  => 'BUY_ITEM',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         merchant   => $merchant,
         };
      }

   };

=item ENTERED_ZONE

   input line:

      [Mon Oct 13 00:42:36 2003] You have entered The Greater Faydark.

   output hash ref:

      {
         line_type  => 'ENTERED_ZONE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         zone       => 'The Greater Faydark',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have entered (.+?)\.\z/,
   handler => sub
      {
      my ($zone) = @_;
      return
         {
         line_type  => 'ENTERED_ZONE',
         zone       => $zone,
         };
      }

   };

=item SELL_ITEM

   input line:

      [Mon Oct 13 00:42:36 2003] You receive 120 platinum from Magus Delin for the Fire Emerald Ring(s).

   output hash ref:

      {
         line_type  => 'SELL_ITEM',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => '120',
         gold       => 0,
         silver     => 0,
         copper     => 0,
         value      => 120.000,
         merchant   => 'Magus Delin',
         item       => 'Fire Emerald Ring',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou receive (.+?) from (.+?) for the (.+?)\(s\)\.\z/,
   handler => sub
      {
      my ($money, $merchant, $item) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         line_type  => 'SELL_ITEM',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         merchant   => $merchant,
         item       => $item,
         };
      }
   };

=item SPLIT_MONEY

   input line:

      [Mon Oct 13 00:42:36 2003] You receive 163 platinum, 30 gold, 25 silver and 33 copper as your split.

   output hash ref:

      {
         line_type  => 'SPLIT_MONEY',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => '163',
         gold       => '30',
         silver     => '25',
         copper     => '33',
         value      => 166.2830,
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou receive (.+?) as your split\.\z/,
   handler => sub
      {
      my ($money) = @_;
      $money ||= '';
      $money =~ s/and//;
      my %moneys = reverse split '[ ,]+', $money;
      return
         {
         line_type  => 'SPLIT_MONEY',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         };
      }

   };

=item YOU_SLAIN

   input line:

      [Mon Oct 13 00:42:36 2003] You have been slain by a Bloodguard crypt sentry!

   output hash ref:

      {
         line_type  => 'YOU_SLAIN',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         slayer     => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have been slain by (.+?)!\z/,
   handler => sub
      {
      my ($slayer) = @_;
      return
         {
         line_type  => 'YOU_SLAIN',
         slayer     => $slayer,
         };
      }

   };

=item TRACKING_MOB

   input line:

      [Mon Oct 13 00:42:36 2003] You begin tracking a Bloodguard crypt sentry.

   output hash ref:

      {
         line_type  => 'TRACKING_MOB',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         trackee    => 'A Bloodguard crypt sentry',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou begin tracking (.+?)\.\z/,
   handler => sub
      {
      my ($trackee) = @_;
      return
         {
         line_type  => 'TRACKING_MOB',
         trackee    => $trackee,
         };
      }

   };

=item YOU_CAST

   input line:

      [Mon Oct 13 00:42:36 2003] You begin casting Ensnaring Roots.

   output hash ref:

      {
         line_type  => 'YOU_CAST',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spell      => 'Ensnaring Roots',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou begin casting (.+?)\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type  => 'YOU_CAST',
         spell      => $spell,
         };
      }

   };

=item SPELL_RESISTED

   input line:

      [Mon Oct 13 00:42:36 2003] Your target resisted the Ensnaring Roots spell.

   output hash ref:

      {
         line_type  => 'SPELL_RESISTED',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spell      => 'Ensnaring Roots',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour target resisted the (.+?) spell\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type  => 'SPELL_RESISTED',
         spell      => $spell,
         };
      }

   };

=item FORGET_SPELL

   input line:

      [Mon Oct 13 00:42:36 2003] You forget Ensnaring Roots.

   output hash ref:

      {
         line_type  => 'FORGET_SPELL',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spell      => 'Ensnaring Roots',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou forget (.+?)\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type  => 'FORGET_SPELL',
         spell      => $spell,
         };
      }

   };

=item MEMORIZE_SPELL

   input line:

      [Mon Oct 13 00:42:36 2003] You have finished memorizing Ensnaring Roots.

   output hash ref:

      {
         line_type  => 'MEMORIZE_SPELL',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spell      => 'Ensnaring Roots',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have finished memorizing (.+?)\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type  => 'MEMORIZE_SPELL',
         spell      => $spell,
         };
      }

   };

=item YOU_FIZZLE

   input line:

      [Mon Oct 13 00:42:36 2003] Your spell fizzles!

   output hash ref:

      {
         line_type  => 'YOU_FIZZLE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour spell fizzles!\z/,
   handler => sub
      {
      return
         {
         line_type  => 'YOU_FIZZLE',
         };
      }

   };

=item LOCATION

   input line:

      [Mon Oct 13 00:42:36 2003] Your Location is -63.20, 3846.55, -42.76

   output hash ref:

      {
         line_type  => 'LOCATION',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         coord_1    => '-63.20',
         coord_2    => '3846.55',
         coord_3    => '-42.76',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour Location is (.+?)\z/,
   handler => sub
      {
      my ($location_coords) = @_;
      $location_coords ||= '';
      my @coords = split /[\s,]+/, $location_coords;
      return
         {
         line_type  => 'LOCATION',
         coord_1    => $coords[0],
         coord_2    => $coords[1],
         coord_3    => $coords[2],
         };
      }

   };

=item YOU_SAY

   input line:

      [Mon Oct 13 00:42:36 2003] You say, 'thanks!'

   output hash ref:

      {
         line_type  => 'YOU_SAY',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spoken     => 'thanks!',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou say, '(.+)'\z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         line_type  => 'YOU_SAY',
         spoken     => $spoken,
         };
      }

   };

=item YOU_OOC

   input line:

      [Mon Oct 13 00:42:36 2003] You say out of character, 'one potato, two potato'

   output hash ref:

      {
         line_type  => 'YOU_OOC',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spoken     => 'one potato, two potato',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou say out of character, '(.+)'\z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         line_type  => 'YOU_OOC',
         spoken     => $spoken,
         };
      }

   };

=item YOU_SHOUT

   input line:

      [Mon Oct 13 00:42:36 2003] You shout, 'one potato, two potato'

   output hash ref:

      {
         line_type  => 'YOU_SHOUT',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spoken     => 'one potato, two potato',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou shout, '(.+)'\z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         line_type  => 'YOU_SHOUT',
         spoken     => $spoken,
         };
      }

   };

=item YOU_AUCTION

   input line:

      [Mon Oct 13 00:42:36 2003] You auction, 'one potato, two potato'

   output hash ref:

      {
         line_type  => 'YOU_AUCTION',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spoken     => 'one potato, two potato',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou auction, '(.+)'\z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         line_type  => 'YOU_AUCTION',
         spoken     => $spoken,
         };
      }

   };

=item OTHER_SAYS

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso says, 'I aim to please :)'

   output hash ref:

      {
         line_type  => 'OTHER_SAYS',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'I aim to please :)',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) says,? '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'OTHER_SAYS',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item YOU_TELL_OTHER

   input line:

      [Mon Oct 13 00:42:36 2003] You told Soandso, 'lol, i was waiting for that =)'

   output hash ref:

      {
         line_type  => 'YOU_TELL_OTHER',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speakee    => 'Soandso',
         spoken     => 'lol, i was waiting for that =)',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou told (\w+),? '(.+)'\z/,
   handler => sub
      {
      my ($speakee, $spoken) = @_;
      return
         {
         line_type  => 'YOU_TELL_OTHER',
         speakee    => $speakee,
         spoken     => $spoken,
         };
      }

   };

=item MERCHANT_TELLS_YOU

   input line:

      [Mon Oct 13 00:42:36 2003] Magus Delin tells you, 'I'll give you 3 gold 6 silver per Geode'

   output hash ref:

      {
         line_type  => 'MERCHANT_TELLS_YOU',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => 0,
         gold       => '3',
         silver     => '6',
         copper     => 0,
         value      => 0.360,
         merchant   => 'Magus Delin',
         item       => 'Geode',
      };

   comments:

      none

=cut

## this must be before OTHER_TELLS_YOU

push @line_types,
   {
   rx      => qr/\A([^,]+?) tells you, 'I\'ll give you (.+?) (?:per|for the) (.+?)\.?'\z/,
   handler => sub
      {
      my ($merchant, $money, $item) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         line_type  => 'MERCHANT_TELLS_YOU',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         merchant   => $merchant,
         item       => $item,
         };
      }

   };

=item MERCHANT_PRICE

   input line:

      [Mon Oct 13 00:42:36 2003] Gaelsori Heriseron tells you, 'That'll be 1 platinum 2 gold 5 silver 9 copper for the Leather Wristbands.'

   output hash ref:

      {
         line_type  => 'MERCHANT_PRICE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         platinum   => '1',
         gold       => '2',
         silver     => '5',
         copper     => '9',
         value      => 1.259,
         merchant   => 'Gaelsori Heriseron',
         item       => 'Leather Wristbands',
      };

   comments:

      none

=cut

## this must be before OTHER_TELLS_YOU

push @line_types,
   {
   rx      => qr/\A([^,]+?) tells you, 'That\'ll be (.+?) (?:per|for the) (.+?)\.?'\z/,
   handler => sub
      {
      my ($merchant, $money, $item) = @_;
      $money ||= '';
      my %moneys = reverse split ' ', $money;
      return
         {
         line_type  => 'MERCHANT_PRICE',
         platinum   => $moneys{'platinum'} || 0,
         gold       => $moneys{'gold'}     || 0,
         silver     => $moneys{'silver'}   || 0,
         copper     => $moneys{'copper'}   || 0,
         merchant   => $merchant,
         item       => $item,
         };
      }

   };


=item OTHER_TELLS_YOU

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso tells you, 'hows the adv?'

   output hash ref:

      {
         line_type  => 'OTHER_TELLS_YOU',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'hows the adv?',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A([^,]+?) tells you, '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'OTHER_TELLS_YOU',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item YOU_TELL_GROUP

   input line:

      [Mon Oct 13 00:42:36 2003] You tell your party, 'will keep an eye out'

   output hash ref:

      {
         line_type  => 'YOU_TELL_GROUP',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spoken     => 'will keep an eye out',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou tell your party, '(.+)'\z/,
   handler => sub
      {
      my ($spoken) = @_;
      return
         {
         line_type  => 'YOU_TELL_GROUP',
         spoken     => $spoken,
         };
      }

   };

=item OTHER_TELLS_GROUP

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso tells the group, 'Didnt know that, thanks info'

   output hash ref:

      {
         line_type  => 'OTHER_TELLS_GROUP',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'Didnt know that, thanks info',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) tells the group, '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'OTHER_TELLS_GROUP',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item OTHER_CASTS

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso begins to cast a spell.

   output hash ref:

      {
         line_type  => 'OTHER_CASTS',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         caster     => 'Soandso',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) begins to cast a spell\.\z/,
   handler => sub
      {
      my ($caster) = @_;
      return
         {
         line_type  => 'OTHER_CASTS',
         caster     => $caster,
         };
      }

   };

=item CRITICAL_DAMAGE

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso scores a critical hit! (126)

   output hash ref:

      {
         line_type  => 'CRITICAL_DAMAGE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'Soandso',
         type       => 'hit',
         amount     => '126',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso delivers a critical blast! (3526)

   output hash ref:

      {
         line_type  => 'CRITICAL_DAMAGE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         attacker   => 'Soandso',
         type       => 'blast',
         amount     => '3526',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) (?:delivers|scores) a critical (hit|blast)! \((\d+)\)\z/,
   handler => sub
      {
      my ($attacker, $type, $amount) = @_;
      return
         {
         line_type  => 'CRITICAL_DAMAGE',
         attacker   => $attacker,
         type       => $type,
         amount     => $amount,
         };
      }

   };

=item PLAYER_HEALED

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso has healed you for 456 points of damage.

   output hash ref:

      {
         line_type  => 'PLAYER_HEALED',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         healer     => 'Soandso',
         healee     => 'you',
         amount     => '456',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) (?:have|has) healed (\w+) for (\d+) points of damage.\z/,
   handler => sub
      {
      my ($healer, $healee, $amount) = @_;
      return
         {
         line_type  => 'PLAYER_HEALED',
         healer     => $healer,
         healee     => $healee,
         amount     => $amount,
         };
      }

   };

=item SAYS_OOC

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso says out of character, 'Stop following me :oP'

   output hash ref:

      {
         line_type  => 'SAYS_OOC',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'Stop following me :oP',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) says out of character, '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'SAYS_OOC',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item OTHER_AUCTIONS

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso auctions, 'WMBS - 4k OBO'

   output hash ref:

      {
         line_type  => 'OTHER_AUCTIONS',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'WMBS - 4k OBO',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) auctions, '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'OTHER_AUCTIONS',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item OTHER_SHOUTS

   input line:

      [Mon Oct 13 00:42:36 2003] Soandso shouts, 'talk to vual stoutest'

   output hash ref:

      {
         line_type  => 'OTHER_SHOUTS',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         speaker    => 'Soandso',
         spoken     => 'talk to vual stoutest',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(\w+) shouts, '(.+)'\z/,
   handler => sub
      {
      my ($speaker, $spoken) = @_;
      return
         {
         line_type  => 'OTHER_SHOUTS',
         speaker    => $speaker,
         spoken     => $spoken,
         };
      }

   };

=item PLAYER_LISTING

   input line:

      [Mon Oct 13 00:42:36 2003] [56 Outrider] Soandso (Half Elf) <The Foobles>

   output hash ref:

      {
         line_type  => 'PLAYER_LISTING',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         afk        => '',
         linkdead   => '',
         anon       => '',
         level      => '56',
         class      => 'Outrider',
         name       => 'Soandso',
         race       => 'Half Elf',
         guild      => 'The Foobles',
         zone       => '',
         lfg        => '',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] [65 Deceiver] Soandso (Barbarian) <The Foobles> ZONE: potranquility

   output hash ref:

      {
         line_type  => 'PLAYER_LISTING',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         afk        => '',
         linkdead   => '',
         anon       => '',
         level      => '65',
         class      => 'Deceiver',
         name       => 'Soandso',
         race       => 'Barbarian',
         guild      => 'The Foobles',
         zone       => 'potranquility',
         lfg        => '',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/
      \A                                      ##
      (\ AFK\ |\ <LINKDEAD>)?                 ## AFK or LINKDEAD
      \[                                      ##
      (ANONYMOUS|\d+\ [^]]+)                  ## ANONYMOUS or level and class
      \]                                      ##
      \s+                                     ##
      (\w+)                                   ## player name
      \s+                                     ##
      (?:\((.+?)\))?                          ## player race
      \s*                                     ##
      (?:<(.+?)>)?                            ## guild tag
      \s*                                     ##
      (?:ZONE:\ (\w+))?                       ## zone
      \s*                                     ##
      (LFG)?                                  ## LFG tag
      \z                                      ##
      /x,
   handler => sub
      {
      my ($afk_ld, $anon_level_class, $name, $race, $guild, $zone, $lfg) = @_;
      my ($afk, $linkdead, $anon, $level, $class);
      if (! defined $afk_ld)
         {
         ($afk, $linkdead) = ('', '');
         }
      elsif ($afk_ld eq ' AFK ')
         {
         ($afk, $linkdead) = ('AFK', '');
         }
      else
         {
         ($afk, $linkdead) = ('', 'LINKDEAD');
         }
      if ($anon_level_class && $anon_level_class ne 'ANONYMOUS')
         {
         ($level, $class) = split ' ', $anon_level_class;
         }
      else { $anon = $anon_level_class; }
      return
         {
         line_type  => 'PLAYER_LISTING',
         afk        => ($afk       || ''),
         linkdead   => ($linkdead  || ''),
         anon       => ($anon      || ''),
         level      => ($level     || ''),
         class      => ($class     || ''),
         name       => $name,
         race       => ($race      || ''),
         guild      => ($guild     || ''),
         zone       => ($zone      || ''),
         lfg        => ($lfg       || ''),
         };
      }

   };

=item YOUR_SPELL_WEARS_OFF

   input line:

      [Mon Oct 13 00:42:36 2003] Your Flame Lick spell has worn off.

   output hash ref:

      {
         line_type  => 'YOUR_SPELL_WEARS_OFF',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         spell      => 'Flame Lick',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour (.+?) spell has worn off\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type  => 'YOUR_SPELL_WEARS_OFF',
         spell      => $spell,
         };
      }

   };

=item WIN_ADVENTURE

   input line:

      [Mon Oct 13 00:42:36 2003] You have successfully completed your adventure.  You received 22 adventure points.  You have 30 minutes to exit this zone.

   output hash ref:

      {
         line_type  => 'WIN_ADVENTURE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         amount     => '22',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have successfully completed your adventure.  You received (\d+) adventure points.  You have 30 minutes to exit this zone\.\z/,
   handler => sub
      {
      my ($amount) = @_;
      return
         {
         line_type  => 'WIN_ADVENTURE',
         amount     => $amount,
         };
      }

   };

=item SPEND_ADVENTURE_POINTS

   input line:

      [Mon Oct 13 00:42:36 2003] You have spent 40 adventure points.

   output hash ref:

      {
         line_type  => 'SPEND_ADVENTURE_POINTS',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         amount     => '40',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have spent (\d+) adventure points\.\z/,
   handler => sub
      {
      my ($amount) = @_;
      return
         {
         line_type  => 'SPEND_ADVENTURE_POINTS',
         amount     => $amount,
         };
      }

   };

=item GAIN_EXPERIENCE

   input line:

      [Mon Oct 13 00:42:36 2003] You gain party experience!!

   output hash ref:

      {
         line_type  => 'GAIN_EXPERIENCE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         gainer     => 'party',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] You gain experience!!

   output hash ref:

      {
         line_type  => 'GAIN_EXPERIENCE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         gainer     => '',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou gain (?:(party) )?experience!!\z/,
   handler => sub
      {
      my ($gainer) = @_;
      return
         {
         line_type  => 'GAIN_EXPERIENCE',
         gainer     => ($gainer || ''),
         };
      }

   };

=item GAME_TIME

   input line:

      [Mon Oct 13 00:42:36 2003] Game Time: Thursday, April 05, 3176 - 6 PM

   output hash ref:

      {
         line_type  => 'GAME_TIME',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         time       => 'Game Time: Thursday, April 05, 3176 - 6 PM',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AGame Time: (.+)\z/,
   handler => sub
      {
      my ($time) = @_;
      return
         {
         line_type => 'GAME_TIME',
         time      => $time,
         };
      }

   };

=item EARTH_TIME

   input line:

      [Mon Oct 13 00:42:36 2003] Earth Time: Thursday, April 05, 2003 19:25:47

   output hash ref:

      {
         line_type  => 'EARTH_TIME',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         time       => 'Earth Time: Thursday, April 05, 2003 19:25:47',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AEarth Time: (.+)\z/,
   handler => sub
      {
      my ($time) = @_;
      return
         {
         line_type => 'EARTH_TIME',
         time      => $time,
         };
      }

   };

=item MAGIC_DIE

   input line:

      [Mon Oct 13 00:42:36 2003] **A Magic Die is rolled by Soandso.

   output hash ref:

      {
         line_type  => 'MAGIC_DIE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         roller     => 'Soandso',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A\*\*A Magic Die is rolled by (.+?)\.\z/,
   handler => sub
      {
      my ($roller) = @_;
      return
         {
         line_type => 'MAGIC_DIE',
         roller    => $roller,
         };
      }

   };

=item ROLL_RESULT

   input line:

      [Mon Oct 13 00:42:36 2003] **It could have been any number from 0 to 550, but this time it turned up a 492.

   output hash ref:

      {
         line_type  => 'ROLL_RESULT',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         min        => '0',
         max        => '550',
         amount     => '492',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A\*\*It could have been any number from (\d+) to (\d+), but this time it turned up a (\d+)\.\z/,
   handler => sub
      {
      my ($min, $max, $amount) = @_;
      return
         {
         line_type => 'ROLL_RESULT',
         min       => $min,
         max       => $max,
         amount    => $amount,
         };
      }

   };

=item BEGIN_MEMORIZE_SPELL

   input line:

      [Mon Oct 13 00:42:36 2003] Beginning to memorize Call of Sky...

   output hash ref:

      {
         line_type  => 'BEGIN_MEMORIZE_SPELL',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         min        => '0',
         max        => '550',
         amount     => '492',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\ABeginning to memorize (.+?)\.\.\.\z/,
   handler => sub
      {
      my ($spell) = @_;
      return
         {
         line_type => 'BEGIN_MEMORIZE_SPELL',
         spell     => $spell,
         };
      }

   };

=item SPELL_INTERRUPTED

   input line:

      [Mon Oct 13 00:42:36 2003] a Bloodguard caretaker's casting is interrupted!

   output hash ref:

      {
         line_type  => 'SPELL_INTERRUPTED',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         caster     => 'a Bloodguard caretaker',
      };

   input line:

      [Mon Oct 13 00:42:36 2003] Your spell is interrupted.

   output hash ref:

      {
         line_type  => 'SPELL_INTERRUPTED',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         caster     => 'You',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) (?:spell|casting) is interrupted(?:\.|!)\z/,
   handler => sub
      {
      my ($caster) = @_;
      $caster =~ s/(?:\'s|r)\z// if defined $caster;
      return
         {
         line_type => 'SPELL_INTERRUPTED',
         caster    => $caster,
         };
      }

   };

=item SPELL_NO_HOLD

   input line:

      [Mon Oct 13 00:42:36 2003] Your spell would not have taken hold on your target.

   output hash ref:

      {
         line_type  => 'SPELL_NO_HOLD',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYour spell would not have taken hold on your target\.\z/,
   handler => sub
      {
      return
         {
         line_type => 'SPELL_NO_HOLD',
         };
      }

   };

=item LEVEL_GAIN

   input line:

      [Mon Oct 13 00:42:36 2003] You have gained a level! Welcome to level 42!

   output hash ref:

      {
         line_type  => 'LEVEL_GAIN',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         level      => '42',
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\AYou have gained a level! Welcome to level (\d+)!\z/,
   handler => sub
      {
      my ($level) = @_;
      return
         {
         line_type => 'LEVEL_GAIN',
         level     => $level,
         };
      }

   };

=item BAZAAR_TRADER_MODE

   input line:

      [Mon Oct 13 00:42:36 2003] Bazaar Trader Mode *ON*

   output hash ref:

      {
         line_type  => 'BAZAAR_TRADER_MODE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         status     => 1,
      };

   comments:

      status will be '0' for OFF, and '1' for ON.

=cut

push @line_types,
   {
   rx      => qr/\ABazaar Trader Mode \*(ON|OFF)\*\z/,
   handler => sub
      {
      # This gets called during module load with no arguments,
      # but we'd rather the undefined $mode not to cause a warning.
      no warnings 'uninitialized';
      my ($mode) = @_;
      return
         {
         line_type  => 'BAZAAR_TRADER_MODE',
         status     => ($mode eq "ON" ? 1 : 0),
         };
      }
   };


=item BAZAAR_TRADER_PRICE

   input line:

      [Mon Oct 13 00:42:36 2003]  18.) Bone Chips (Price  2g 5s).

   output hash ref:

      {
         line_type  => 'BAZAAR_TRADER_PRICE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         item       => 'Bone Chips',
         platinum   => '0',
         gold       => '2',
         silver     => '5',
         copper     => '0',
         value      => 0.250,
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A \d+\.\) (.+?) \(Price $BAZAAR_PRICE\)\.\z/,
   handler => sub
      {
      my ($item, $pp, $gp, $sp, $cp) = @_;
      return
         {
         line_type  => 'BAZAAR_TRADER_PRICE',
         item       => $item,
         platinum   => $pp || 0,
         gold       => $gp || 0,
         silver     => $sp || 0,
         copper     => $cp || 0,
         };
      }
   };

=item BAZAAR_SALE

   input line:

      [Mon Oct 13 00:42:36 2003] Letsmekkadyl purchased 17 Bone Chips for ( 3p 2g 3s).

   output hash ref:

      {
         line_type  => 'BAZAAR_SALE',
         time_stamp => '[Mon Oct 13 00:42:36 2003] ',
         buyer      => 'Letsmekkadyl',
         item       => 'Leather Wristbands',
         quantity   => 17,
         platinum   => '3',
         gold       => '2',
         silver     => '3',
         copper     => '0',
         value      => 3.230,
      };

   comments:

      none

=cut

push @line_types,
   {
   rx      => qr/\A(.+?) purchased (\d+) (.+?) for \($BAZAAR_PRICE\)\.\z/,
   handler => sub
      {
      my ($buyer, $qty, $item, $pp, $gp, $sp, $cp) = @_;
      return
         {
         line_type  => 'BAZAAR_SALE',
         platinum   => $pp || 0,
         gold       => $gp || 0,
         silver     => $sp || 0,
         copper     => $cp || 0,
         buyer      => $buyer,
         item       => $item,
         quantity   => $qty,
         };
      }

   };

# Finally, we process every line in @line_types, ready to start.
for my $line_type (@line_types)
  {
  my $line_type_name = $line_type->{'handler'}->()->{'line_type'};
  $line_types{$line_type_name} = $line_type;
  }

1;
__END__

=back

=head1 AUTHOR

Dan Boorstein, E<lt>danboo@cpan.orgE<gt>

Mainted by Paul Fenwick, E<lt>pjf@cpan.orgE<gt>

=head1 BUGS

I imagine the primary source of faults in this module will be in which line
types it understands, and how well it can distinguish them. If you come
across lines in you log files that I haven't handled
(see L<eqlog_unrecognized_lines.pl>), or that are handled incorrectly, please
send the line to me, with an explanation of why it was not parsed in
accordance with your expectations. If you're up to it, a patch (test suite
too please) for handling the offending line would be great.

=head1 TO DO

=over 4

=item - add unrecognized yet useful lines

   MOTD, GUILD_MOTD, BEGIN_MEMORIZE

=item - optimize ordering of @line_types

=back

=head1 SEE ALSO

=cut

