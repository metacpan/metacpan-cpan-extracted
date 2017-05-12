# ----------------------------------------------------------
# + Extras.pm - Copyright (C) 2K09 by Manuel Gebele 
# - <forensixs[at]gmx[dot]de>, Germany.
#
# vim: set nu ts=3 sw=3 tw=78 et sr
# ----------------------------------------------------------
package IBM::ThinkPad::ACPI::Extras;
# ----------------------------------------------------------
use 5.008008;
use strict;
use warnings;

use Carp  qw( croak  );
use POSIX qw( getuid );

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
   tp_extras_read
   tp_extras_write
);

our $VERSION = '0.01';

my $EXTRAS_PATH;
my $FH;

# ----------------------------------------------------------
BEGIN {
   $EXTRAS_PATH = '/proc/acpi/ibm';
   if (! -e $EXTRAS_PATH) {
      croak "Missing $EXTRAS_PATH! Is the IBM ThinkPad " .
            "ACPI Extras Driver module loaded?";
   }
}
# ----------------------------------------------------------

my %ffiles; # establish the feature files (ibm/*)
$ffiles{$_} = "$EXTRAS_PATH/$_" for (
   qw(
      bay beep bluetooth brightness
      cmos
      driver
      ecdump
      fan
      hotkey
      led light
      thermal
      video volume
      wan
   )
);

sub _init {
   my ($feature, $access_mode) = @_;
   my $file = $ffiles{$feature};
   
   local *HNDL;
   
   # verify that feature exists
   defined $file || croak "unknown feature '$feature'";
   
   # prepare the global file-handle
   open HNDL, "$access_mode $file" 
      or croak "Cannot open '$file': $!";
   
   return *HNDL;
}

sub _get_status {
   my $pattern = shift || ($_ = 'ecdump');
   my $stat;

   if ($_) {
      # return the complete file content
      my $ecdump;
      chomp($ecdump = do { local $/; <$FH> });
      return $ecdump;
   }

   # ibm/*, each other feature, read the specified status line
   my @line = grep /^$pattern:/, <$FH>;

   $stat = $line[0] || return;
   ($stat =~ s/^\w+:\s+(.+)$/$1/);
     
   chomp($stat);

   return $stat;
}

sub _get_commands {
   my @cmds = (); # contains supported commands

   for (grep /^commands:/, <$FH>) {
      s/^\w+:\s(.+)$/$1/;
      if (m[
         ^
         (\w+),
         \s
         (\w+)
         (?:,\s(\w+)(?:,\s(<\w+>))?)?
         $
         ]x
      ) {
         push @cmds, ($1, $2);
         
         # reset (ibm/hotkey)
         push @cmds, $3 if defined $3;
         
         # <mask> e.g. 0xffff (ibm/hotkey)
         push @cmds, (0x0000..0xffff) if defined $4;
      }
      elsif (m[
            ^
            (?:\D[^-])+
            (\d)
            -
            (\d+)
            (?:,\s(\w+),\s(\w+))?
            .+
            $
            ]x
         ) {
         # push @cmds, (0..$2); may prone for local DoS
         # 65535 (0xffff) should be the biggest value:
         # (ibm_acpi.c (static int fan_read(char *p)))
         push @cmds, (0..($2 <= 65535) ? $2 : 65535);
         
         # auto and disengaded (ibm/fan)
         push @cmds, ($3, $4) if defined $3;
      }
      # handle ibm/led seperately
      elsif (/^<led>/) {
         for my $x (qw( on off blink )) {
            push @cmds, "$_ $x" for 0..7;
         }
      }
      # only one command
      else { push @cmds, $_ }
   }

   return @cmds;
}

# ----------------------------------------------------------
#               [ U S E R  I N T E R F A C E ]
# ----------------------------------------------------------

sub tp_extras_read {
   my($f, $w) = @_;
   my(@cmds, $stat);
   
   $FH = _init($f, '<'); # global filehandle
   
   if (!defined $w && $f !~ /ecdump/) {
      croak "Empty var detected (second arg).\n"
          . "This is only allowed in combination "
          . "with 'ecdump' and not with '$f'.";
   }
   
   if (defined $w && $w =~ /^commands$/) {
      @cmds = _get_commands();
      if (! @cmds) {
         croak "No commands available for $f";
      }
      
      return @cmds;
   }

   $stat = ($f =~ /ecdump/) ? _get_status() : _get_status($w);
   if (!defined $stat) {
      croak "No '$w' status available for $f";
   }

   close $FH;
   undef $FH;

   return $stat;
}

sub tp_extras_write {
   my($f, $c) = @_; # $c -> command
   my $uid    = getuid();
   
   $_ = $f;
   if (/driver/ || /ecdump/ || /thermal/) {
      croak "No commands can be written to $f";
   }
   
   if ($uid != 0) {
      croak "U must to be root to write to $f";
   }
   
   $FH = _init($f, '+<');
   croak "Unknown command '$c'"
      unless (grep $c eq $_, _get_commands());
   
   print $FH $c;

   close $FH;
   undef $FH;
}

# ----------------------------------------------------------
END {
   if (defined $FH) {
      close $FH or croak "Cannot close global file-handle";
   }
}
# ----------------------------------------------------------

1;

=head1 NAME

IBM::ThinkPad::ACPI::Extras - Perl interface to the IBM ThinkPad ACPI features

=head1 SYNOPSIS

  use IBM::ThinkPad::ACPI::Extras;

  # Read status of the 'light' feature
  my $light_status = tp_extras_read('light', 'status');

  # Read possible commands of the 'led' feature
  my @led_commands = tp_extras_read('led', 'commands');

  # Read complete EC dump
  print tp_extras_read('ecdump');

  # For the next examples you'll need root privileges!
  # Turn LED 1 off (battery)
  tp_extras_write('led', '1 off');

  # Turn LED 1 on
  tp_extras_write('led', '1 on');

  # Turn ThinkLight on
  tp_extras_write('light', 'on');


=head1 DESCRIPTION

See the README file that came with the IBM::ThinkPad::ACPI::Extras
package for more information.

=head2 Public methods

=over

=item B<tp_extras_read($feature, $keyword)>

The C<tp_extras_read> method is called to read the specified
$feature file and looks there for the $keyword (e.g. status).

=item B<tp_extras_write($feature, $command)>

The C<tp_extras_write> method is called to send the $command
to the corresponding $feature file.

=back

=head1 EXPORT

B<tp_extras_read>
B<tp_extras_write>

=head1 AUTHOR

Manuel Gebele, E<lt>forensixs[at]gmx.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Manuel Gebele.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
