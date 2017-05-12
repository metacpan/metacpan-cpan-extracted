package Gtk2::GoBoard::Constants;

use base Exporter;

@EXPORT = qw(
   MARK_TRIANGLE MARK_SQUARE MARK_CIRCLE MARK_SMALL_B MARK_SMALL_W MARK_B
   MARK_W MARK_GRAYED MARK_MOVE MARK_LABEL MARK_HOSHI MARK_KO
   MARK_REDRAW
);

# marker types for each board position (ORed together)

sub MARK_TRIANGLE (){ 0x0001 }
sub MARK_SQUARE   (){ 0x0002 }
sub MARK_CIRCLE   (){ 0x0004 }
sub MARK_SMALL_B  (){ 0x0008 } # small stone, used for scoring or marking
sub MARK_SMALL_W  (){ 0x0010 } # small stone, used for scoring or marking
sub MARK_B        (){ 0x0020 } # normal black stone
sub MARK_W        (){ 0x0040 } # normal whit stone
sub MARK_GRAYED   (){ 0x0080 } # in conjunction with MARK_[BW], grays the stone
sub MARK_LABEL    (){ 0x0100 }
sub MARK_HOSHI    (){ 0x0200 } # this is a hoshi point (not used much)
sub MARK_MOVE     (){ 0x0400 } # this is a regular move
sub MARK_KO       (){ 0x0800 } # this is a ko position
sub MARK_REDRAW   (){ 0x8000 }

1;

