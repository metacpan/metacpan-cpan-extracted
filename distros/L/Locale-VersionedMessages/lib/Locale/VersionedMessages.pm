package Locale::VersionedMessages;
# Copyright (c) 2010-2015 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################

require 5.008;
use strict;
use warnings;

our $VERSION;
$VERSION='0.96';

########################################################################
# METHODS
########################################################################

sub new {
  my($class) = @_;

  my $self = {
              'err'    => '',
              'set'    => {},
              'mess'   => {},
              'search' => [],
             };

  bless $self, $class;

  return $self;
}

sub version {
  my($self) = @_;
  return $VERSION;
}

sub err {
   my($self) = @_;
   return $$self{'err'};
}

no strict 'refs';
sub set {
   my($self,@set) = @_;

   $$self{'err'} = '';
   if (! @set) {
      return sort keys %{ $$self{'set'} };
   }

   foreach my $set (@set) {
      if ($set !~ /^[a-zA-Z0-9_]+$/) {
         $$self{'err'} = "Set must be alphanumeric/underscore: $set";
         return;
      }

      my $m = "Locale::VersionedMessages::Sets::$set";
      eval "require $m";
      if ($@) {
         chomp($@);
         $$self{'err'} = "Unable to load set: $set: $@";
         return;
      }

      my $def_locale   = ${ "${m}::DefaultLocale" };
      my @all_locale   = @{ "${m}::AllLocale" };
      my %messages     = %{ "${m}::Messages" };

      $$self{'set'}{$set} = { 'def_loc'  => $def_locale,
                              'all_loc'  => { map {$_,1} @all_locale },
                              'messages' => \%messages,
                              'search'   => [],
                            };
   }

   return;
}
use strict 'refs';

sub query_set_default {
   my($self,$set) = @_;
   $$self{'err'} = '';

   if (! exists $$self{'set'}{$set}) {
      $$self{'err'} = "Set not loaded: $set";
      return;
   }

   return $$self{'set'}{$set}{'def_loc'};
}

sub query_set_locales {
   my($self,$set) = @_;
   $$self{'err'} = '';

   if (! exists $$self{'set'}{$set}) {
      $$self{'err'} = "Set not loaded: $set";
      return;
   }

   return sort keys %{ $$self{'set'}{$set}{'all_loc'} };
}

sub query_set_msgid {
   my($self,$set) = @_;
   $$self{'err'} = '';

   if (! exists $$self{'set'}{$set}) {
      $$self{'err'} = "Set not loaded: $set";
      return;
   }

   return sort keys %{ $$self{'set'}{$set}{'messages'} };
}

sub search {
   my($self,@locale) = @_;
   $$self{'err'} = '';

   my $set;
   if (@locale  &&  exists $$self{'set'}{$locale[0]}) {
      $set = shift(@locale);
   }

   if ($set  &&  @locale) {
      $$self{'set'}{$set}{'search'} = [@locale];

   } elsif (@locale) {
      $$self{'search'} = [@locale];

   } elsif ($set) {
      $$self{'set'}{$set}{'search'} = [];

   } else {
      $$self{'search'} = [];
   }

   return;
}

sub query_search {
   my($self,$set) = @_;
   $$self{'err'} = '';

   if ($set) {
      if (! exists $$self{'set'}{$set}) {
         $$self{'err'} = "Set not loaded: $set";
         return;
      }

      return @{ $$self{'set'}{$set}{'search'} };
   }

   return @{ $$self{'search'} };
}

no strict 'refs';
sub _load_lexicon {
   my($self,$set,$locale) = @_;
   return  if (exists $$self{'mess'}{$set}{$locale});

      if ($set !~ /^[a-zA-Z0-9_]+$/) {
         $$self{'err'} = "Set must be alphanumeric/underscore: $set";
         return;
      }

   my $m = "Locale::VersionedMessages::Sets::${set}::${locale}";
   eval "require $m";
   if ($@) {
      chomp($@);
      $$self{'err'} = "Unable to load lexicon: $set [$locale]: $@";
      return;
   }

   $$self{'mess'}{$set}{$locale} = { %{ "${m}::Messages" } };

   foreach my $msgid (sort keys %{ $$self{'mess'}{$set}{$locale} }) {
      if (! exists $$self{'set'}{$set}{'messages'}{$msgid}) {
         $$self{'err'} = "Undefined message ID in lexicon: $set [$locale $msgid]";
         return;
      }
   }
}
use strict 'refs';

sub message {
   my($self,$set,$msgid,@args) = @_;
   $$self{'err'} = '';

   # Parse arguments

   my($locale,%vals);
   if (@args  &&  @args % 2) {
      $locale = shift(@args);
      %vals   = @args;
      if (! exists $$self{'set'}{$set}{'all_loc'}{$locale}) {
         $$self{'err'} = "Set not defined in locale: $set [ $locale ]";
         return '';
      }

   } else {
      %vals  = @args;
   }

   # Look up the message.

   my @locale;
   if ($locale) {
      @locale = ($locale);

   } elsif (exists $$self{'set'}{$set}{'search'}  &&
            @{ $$self{'set'}{$set}{'search'} }) {
      @locale = @{ $$self{'set'}{$set}{'search'} };

   } elsif (exists $$self{'search'}  &&
            @{ $$self{'search'} }) {
      @locale = (@{ $$self{'search'} }, $$self{'set'}{$set}{'def_loc'});

   } else {
      @locale = ($$self{'set'}{$set}{'def_loc'});
   }

   my $message;

   foreach my $l (@locale) {
      next  if (! exists $$self{'set'}{$set}{'all_loc'}{$l});

      if (! exists $$self{'mess'}{$set}{$l}) {
         $self->_load_lexicon($set,$l);
         if ($$self{'err'}) {
            if (wantarray) {
               return ('');
            } else {
               return '';
            }
         }
      }

      if (exists $$self{'mess'}{$set}{$l}{$msgid}) {
         $locale  = $l;
         $message = $$self{'mess'}{$set}{$l}{$msgid}{'text'};
         last;
      }
   }

   if (! $message) {
      $$self{'err'} = "Message not found in specified lexicons: $msgid";
      return;
   }

   $message = $self->_fix_message($set,$msgid,$message,$locale,%vals);

   if (wantarray) {
      return ($message,$locale);
   } else {
      return $message;
   }
}

sub query_msg_locales {
   my($self,$set,$msgid) = @_;
   $$self{'err'} = '';

   if (! exists $$self{'set'}{$set}) {
      $$self{'err'} = "Set not loaded: $set";
      return ();
   }
   if (! exists $$self{'set'}{$set}{'messages'}{$msgid}) {
      $$self{'err'} = "Message ID not defined in set: $set [$msgid]";
      return ();
   }

   my %all_loc = %{ $$self{'set'}{$set}{'all_loc'} };
   my $def_loc = $$self{'set'}{$set}{'def_loc'};
   delete $all_loc{$def_loc};

   my @locale = ($def_loc);
   foreach my $locale (sort keys %all_loc) {
      $self->_load_lexicon($set,$locale);
      return ()  if ($$self{'err'});
      if (exists $$self{'mess'}{$set}{$locale}{$msgid}) {
         push(@locale,$locale);
      }
   }

   return @locale;
}

sub query_msg_vers {
   my($self,$set,$msgid,$locale) = @_;
   $$self{'err'} = '';

   if (! exists $$self{'set'}{$set}) {
      $$self{'err'} = "Set not loaded: $set";
      return '';
   }
   if (! exists $$self{'set'}{$set}{'messages'}{$msgid}) {
      $$self{'err'} = "Message ID not defined in set: $set [$msgid]";
      return '';
   }

   $locale = $$self{'set'}{$set}{'def_loc'}  if (! $locale);

   if (! exists $$self{'set'}{$set}{'all_loc'}{$locale}) {
      $$self{'err'} = "Lexicon not available for set: $set [$locale]";
      return '';
   }

   if (exists $$self{'mess'}{$set}{$locale}{$msgid}) {
      return $$self{'mess'}{$set}{$locale}{$msgid}{'vers'};
   }
   return 0;
}

########################################################################
# MESSAGE SUBSTITUTIONS
########################################################################

# This takes a message and performs substitutions for each of
# the different substitution values.
#
sub _fix_message {
   my($self,$set,$msgid,$message,$locale,%vals) = @_;

   # No substitutions.

   my @vals;
   if (exists $$self{'set'}{$set}{'messages'}{$msgid}{'vals'}) {
      @vals = @{ $$self{'set'}{$set}{'messages'}{$msgid}{'vals'} };
   }
   if (! @vals) {
      if (%vals) {
         $$self{'err'} = "Message does not contain substitutions, but " .
                         "values were supplied: $msgid";
         return '';
      }
      return $message;
   }

   # Check each substitution.

   foreach my $val (sort @vals) {
      my $done;
      if (! exists $vals{$val}) {
         $$self{'err'} = "A required substitution value was not passed in: " .
                         "$msgid [$val]";
         return '';
      }
      ($message,$done) = $self->_substitute($set,$msgid,$locale,
                                            $message,$val,$vals{$val});
      return ''  if ($$self{'err'});
      if (! $done) {
         $$self{'err'} = "The message in a lexicon does not contain a required " .
                         "substitution: $msgid [$locale $val]";
         return '';
      }
      delete $vals{$val};
   }
   foreach my $val (sort keys %vals) {
      $$self{'err'} = "An invalid value was passed in: $msgid [$val]";
      return '';
   }

   return $message;
}

# This does the acutal substitution for a single substitution value.
#
# If the substitution is found, $done = 1 will be returned.
#
sub _substitute {
   my($self,$set,$msgid,$locale,$message,$var,$val) = @_;
   my $done     = 0;

   # Simple substitutions: [foo]

   if ($message =~ s/\[\s*$var\s*\]/$val/sg) {
      $done = 1;
   }

   # Formatted substitutions: [ foo : FORMAT ]

   my $fmt_re = qr/\s*:\s*(%.*?)/;

   while ($message =~ s/\[\s*$var$fmt_re\s*\]/__L_M_TMP__/s) {
      my $fmt = $1;

      no warnings;
      $val = sprintf($fmt,$val);
      use warnings;
      if ($val eq $fmt) {
         $$self{'err'} = "Invalid sprintf format: $msgid [$locale $var]";
         return;
      }
      $message =~ s/__L_M_TMP__/$val/s;
      $done    = 1;
   }

   # Quant substitutions: [ foo : quant [ : FORMAT ] ... ]

   my ($msg,$d) = $self->_quant($set,$msgid,$locale,$message,$var,$val);
   return       if ($$self{'err'});
   $message     = $msg;
   $done        = $d  if ($d);

   return ($message,$done);
}

# This tests a string for any quant substitutions and returns the
# string.
#
sub _quant {
   my($self,$set,$msgid,$locale,$mess,$var,$val) = @_;

   my $val_orig = $val;
   my $fmt_re   = qr/\s*:\s*(%.*?)/;
   my $brack_re = qr/\s+\[([^]]*?)\]/;
   my $sq_re    = qr/\s+'([^']*?)'/;
   my $dq_re    = qr/\s+"([^"]*?)"/;
   my $ws_re    = qr/\s+(\S*)/;
   my $tok_re   = qr/(?:$brack_re|$sq_re|$dq_re|$ws_re)/;
   my $tmp      = '__L_M_TMP__';
   my $done     = 0;

   SUBST:
   while ($mess =~ s/\[\s*$var\s*:\s*quant\s*(?:$fmt_re)?($tok_re+)\s*\]/$tmp/s) {
      my $fmt   = $1;
      my $tokens= $2;

      if ($fmt) {
         no warnings;
         $val = sprintf($fmt,$val);
         use warnings;
         if ($val eq $fmt) {
            $$self{'err'} = "Invalid sprintf format: $msgid [$locale $var]";
            return;
         }
      }

      my @tok;
      while ($tokens =~ s/^$tok_re//) {
         push(@tok, $1 || $2 || $3 || $4);
      }

      if (@tok % 2 == 0) {
         $$self{'err'} = "Default string required in quant substitution: " .
                         "$msgid [$locale $var]";
         return;
      }

      # @tok is (TEST, STRING, TEST, STRING, ..., DEFAULT_STRING)

      while (@tok) {
         my $ele = shift(@tok);

         # DEFAULT_STRING

         if (! @tok) {
            $ele  =~ s/_$var/$val/g;
            $mess =~ s/$tmp/$ele/s;
            $done = 1;
            next SUBST;
         }

         # TEST, STRING

         my $flag = $self->_test($set,$msgid,$locale,$var,$val_orig,$ele);
         return  if ($$self{'err'});

         $ele     = shift(@tok);
         if ($flag) {
            $ele  =~ s/_$var/$val/g;
            $mess =~ s/$tmp/$ele/s;
            $done = 1;
            next SUBST;
         }
      }
   }

   return($mess,$done);
}

# This parses a condition string and returns 1 if the condition is true for
# this value.
#
sub _test {
   my($self,$set,$msgid,$locale,$var,$n,$test) = @_;

   # $n must be an unsigned integer

   if ($n !~ /^\d+$/) {
      $$self{'err'} = "Quantity test requires an unsigned integer: " .
                      "$msgid [$locale $var]";
      return;
   }

   # Currently, test can only have:
   #   whitespace
   #   _VAR
   #   ( ) && || < <= == != >= >
   #   DIGITS
   # in them.

   my $tmp = $test;
   $tmp    =~ s/(?:\s|\d|_$var|[()&|<=!>])//g;
   if ($tmp) {
      $$self{'err'} = "Quantity test contains invalid characters: " .
                      "$msgid [$locale $var]";
      return;
   }

   # Parse the tests.

   #  1) _VAR => $n

   $test =~ s/\s*_$var\s*/ $n /g;

   #  2) DIGITS % DIGITS => DIGITS

   while ($test =~ s/\s*(\d+)\s*%\s*(\d+)\s*/__L_M_TMP__/) {
      my $m = $1 % $2;
      $test =~ s/__L_M_TMP__/ $m /;
   }

   #  3) DIGITS OP DIGITS => 0 or 1

   while ($test =~ s/\s*(\d+)\s*(==|>=|<=|!=|>|<)\s*(\d+)\s*/__L_M_TMP__/) {
      my($m,$op,$n) = ($1,$2,$3);
      my $x;
      if      ($op eq '==') {
         $x = ($m==$n ? 1 : 0);
      } elsif ($op eq '!=') {
         $x = ($m!=$n ? 1 : 0);
      } elsif ($op eq '>=') {
         $x = ($m>=$n ? 1 : 0);
      } elsif ($op eq '<=') {
         $x = ($m<=$n ? 1 : 0);
      } elsif ($op eq '>') {
         $x = ($m>$n ? 1 : 0);
      } elsif ($op eq '<') {
         $x = ($m<$n ? 1 : 0);
      }
      $test =~ s/__L_M_TMP__/$x/;
   }

   #  Repeat until done:
   #  4) (DIGITS) => DIGITS
   #  5) DIGITS BOP DIGITS => 0 or 1

   while (1) {
      my $done = 1;
      if ($test =~ s/\s*\(\s*(\d+)\s*\)\s*/$1/g) {
         $done = 0;
      }
      while ($test =~ s/\s*(\d+)\s*(\|\||&&)\s*(\d+)\s*/__L_M_TMP__/) {
         my($m,$op,$n) = ($1,$2,$3);
         my $x;
         if      ($op eq '&&') {
            $x = ($m && $n ? 1 : 0);
         } elsif ($op eq '||') {
            $x = ($m || $n ? 1 : 0);
         }
         $test =~ s/__L_M_TMP__/$x/;
         $done = 0;
      }
      last  if ($done);
   }

   # Final check:
   #   6) DIGITS => 0 or 1

   if ($test =~ /^\s*(\d+)\s*$/) {
      return ($1 ? 1 : 0);
   }

   $$self{'err'} = "Quantity test malformed: $msgid [$locale $var]";
   return;
}

1;
# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
