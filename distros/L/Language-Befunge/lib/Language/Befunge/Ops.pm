#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::Ops;
# ABSTRACT: definition of the various operations
$Language::Befunge::Ops::VERSION = '5.000';

use File::Spec::Functions qw{ catfile };   # For the 'y' instruction.
use Language::Befunge::Debug;


sub num_push_number {
    my ($lbi, $char) = @_;

    # Fetching char.
    my $ip  = $lbi->get_curip;
    my $num = hex( $char );

    # Pushing value.
    $ip->spush( $num );

    # Cosmetics.
    debug( "pushing number '$num'\n" );
}

sub str_enter_string_mode {
    my ($lbi) = @_;

    # Cosmetics.
    debug( "entering string mode\n" );

    # Entering string-mode.
    $lbi->get_curip->set_string_mode(1);
}


sub str_fetch_char {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Moving pointer...
    $lbi->_move_ip_once($lbi->get_curip);

   # .. then fetch value and push it.
    my $ord = $lbi->get_storage->get_value( $ip->get_position );
    my $chr = $lbi->get_storage->get_char( $ip->get_position );
    $ip->spush( $ord );

    # Cosmetics.
    debug( "pushing value $ord (char='$chr')\n" );
}


sub str_store_char {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Moving pointer.
    $lbi->_move_ip_once($lbi->get_curip);

    # Fetching value.
    my $val = $ip->spop;

    # Storing value.
    $lbi->get_storage->set_value( $ip->get_position, $val );
    my $chr = $lbi->get_storage->get_char( $ip->get_position );

    # Cosmetics.
    debug( "storing value $val (char='$chr')\n" );
}

sub math_addition {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "adding: $v1+$v2\n" );
    my $res = $v1 + $v2;

    # Checking over/underflow.
    $res > 2**31-1 and $lbi->abort( "program overflow while performing addition" );
    $res < -2**31  and $lbi->abort( "program underflow while performing addition" );

    # Pushing value.
    $ip->spush( $res );
}


sub math_substraction {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "substracting: $v1-$v2\n" );
    my $res = $v1 - $v2;

    # checking over/underflow.
    $res > 2**31-1 and $lbi->abort( "program overflow while performing substraction" );
    $res < -2**31  and $lbi->abort( "program underflow while performing substraction" );

    # Pushing value.
    $ip->spush( $res );
}


sub math_multiplication {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "multiplicating: $v1*$v2\n" );
    my $res = $v1 * $v2;

    # checking over/underflow.
    $res > 2**31-1 and $lbi->abort( "program overflow while performing multiplication" );
    $res < -2**31  and $lbi->abort( "program underflow while performing multiplication" );

    # Pushing value.
    $ip->spush( $res );
}


sub math_division {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "dividing: $v1/$v2\n" );
    my $res = $v2 == 0 ? 0 : int($v1 / $v2);

    # Can't do over/underflow with integer division.

    # Pushing value.
    $ip->spush( $res );
}


sub math_remainder {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "remainder: $v1%$v2\n" );
    my $res = $v2 == 0 ? 0 : int($v1 % $v2);

    # Can't do over/underflow with integer remainder.

    # Pushing value.
    $ip->spush( $res );
}

sub dir_go_east {
    my ($lbi) = @_;
    debug( "going east\n" );
    $lbi->get_curip->dir_go_east;
}


sub dir_go_west {
    my ($lbi) = @_;
    debug( "going west\n" );
    $lbi->get_curip->dir_go_west;
}


sub dir_go_north {
    my ($lbi) = @_;
    debug( "going north\n" );
    $lbi->get_curip->dir_go_north;
}


sub dir_go_south {
    my ($lbi) = @_;
    debug( "going south\n" );
    $lbi->get_curip->dir_go_south;
}


sub dir_go_high {
    my ($lbi) = @_;
    debug( "going high\n" );
    $lbi->get_curip->dir_go_high;
}


sub dir_go_low {
    my ($lbi) = @_;
    debug( "going low\n" );
    $lbi->get_curip->dir_go_low;
}


sub dir_go_away {
    my ($lbi) = @_;
    debug( "going away!\n" );
    $lbi->get_curip->dir_go_away;
}


sub dir_turn_left {
    my ($lbi) = @_;
    debug( "turning on the left\n" );
    $lbi->get_curip->dir_turn_left;
}


sub dir_turn_right {
    my ($lbi) = @_;
    debug( "turning on the right\n" );
    $lbi->get_curip->dir_turn_right;
}


sub dir_reverse {
    my ($lbi) = @_;
    debug( "180 deg!\n" );
    $lbi->get_curip->dir_reverse;
}


sub dir_set_delta {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    my ($new_d) = $ip->spop_vec;
    debug( "setting delta to $new_d\n" );
    $ip->set_delta( $new_d );
}

sub decis_neg {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching value.
    my $val = $ip->spop ? 0 : 1;
    $ip->spush( $val );

    debug( "logical not: pushing $val\n" );
}


sub decis_gt {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching values.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "comparing $v1 vs $v2\n" );
    $ip->spush( ($v1 > $v2) ? 1 : 0 );
}


sub decis_horiz_if {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching value.
    my $val = $ip->spop;
    $val ? $ip->dir_go_west : $ip->dir_go_east;
    debug( "horizontal if: going " . ( $val ? "west\n" : "east\n" ) );
}


sub decis_vert_if {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching value.
    my $val = $ip->spop;
    $val ? $ip->dir_go_north : $ip->dir_go_south;
    debug( "vertical if: going " . ( $val ? "north\n" : "south\n" ) );
}


sub decis_z_if {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching value.
    my $val = $ip->spop;
    $val ? $ip->dir_go_low : $ip->dir_go_high;
    debug( "z if: going " . ( $val ? "low\n" : "high\n" ) );
}


sub decis_cmp {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching value.
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "comparing $v1 with $v2: straight forward!\n"), return if $v1 == $v2;

    my $dir;
    if ( $v1 < $v2 ) {
        $ip->dir_turn_left;
        $dir = "left";
    } else {
        $ip->dir_turn_right;
        $dir = "right";
    }
    debug( "comparing $v1 with $v2: turning: $dir\n" );
}

sub flow_space {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    $lbi->_move_ip_till($ip, qr/ /);
    $lbi->move_ip($lbi->get_curip);

    my $char = $lbi->get_storage->get_char($ip->get_position);
    $lbi->_do_instruction($char);
}


sub flow_no_op {
    my ($lbi) = @_;
    debug( "no-op\n" );
}


sub flow_comments {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    $lbi->_move_ip_once($ip);             # skip comment ';'
    $lbi->_move_ip_till( $ip, qr/[^;]/ ); # till just before matching ';'
    $lbi->_move_ip_once($ip);             # till matching ';'
    $lbi->_move_ip_once($ip);             # till just after matching ';'

    my $char = $lbi->get_storage->get_char($ip->get_position);
    $lbi->_do_instruction($char);
}


sub flow_trampoline {
    my ($lbi) = @_;
    $lbi->_move_ip_once($lbi->get_curip);
    debug( "trampoline! (skipping next instruction)\n" );
}


sub flow_jump_to {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    my $count = $ip->spop;
    debug( "skipping $count instructions\n" );
    $count == 0 and return;
    $count < 0  and $ip->dir_reverse; # We can move backward.
    $lbi->_move_ip_once($lbi->get_curip) for (1..abs($count));
    $count < 0 and $ip->dir_reverse;
}


sub flow_repeat {
    my ($lbi) = @_;
    my $ip  = $lbi->get_curip;
    my $pos = $ip->get_position;

    my $kcounter = $ip->spop;
    debug( "repeating next instruction $kcounter times.\n" );

    # fetch instruction to repeat
    $lbi->move_ip($lbi->get_curip);
    my $char = $lbi->get_storage->get_char($ip->get_position);

    $char eq 'k' and return;     # k cannot be itself repeated
    $kcounter == 0 and return;   # nothing to repeat
    $kcounter  < 0 and return;   # oops, error

    # reset position back to where k is, and repeat instruction
    $ip->set_position($pos);
    $lbi->_do_instruction($char) for (1..$kcounter);
}


sub flow_kill_thread {
    my ($lbi) = @_;
    debug( "end of Instruction Pointer\n" );
    $lbi->get_curip->set_end('@');
}


sub flow_quit {
    my ($lbi) = @_;
    debug( "end program\n" );
    $lbi->set_newips( [] );
    $lbi->set_ips( [] );
    $lbi->get_curip->set_end('q');
    $lbi->set_retval( $lbi->get_curip->spop );
}

sub stack_pop {
    my ($lbi) = @_;
    debug( "popping a value\n" );
    $lbi->get_curip->spop;
}


sub stack_duplicate {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    my $value = $ip->spop;
    debug( "duplicating value '$value'\n" );
    $ip->spush( $value );
    $ip->spush( $value );
}


sub stack_swap {
    my ($lbi) = @_;
    my $ ip = $lbi->get_curip;
    my ($v1, $v2) = $ip->spop_mult(2);
    debug( "swapping $v1 and $v2\n" );
    $ip->spush( $v2 );
    $ip->spush( $v1 );
}


sub stack_clear {
    my ($lbi) = @_;
    debug( "clearing stack\n" );
    $lbi->get_curip->sclear;
}

sub block_open {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    debug( "block opening\n" );

    # Create new TOSS.
    $ip->ss_create( $ip->spop );

    # Store current storage offset on SOSS.
    $ip->soss_push( $ip->get_storage->get_all_components );

    # Set the new Storage Offset.
    $lbi->_move_ip_once($lbi->get_curip);
    $ip->set_storage( $ip->get_position );
    $ip->dir_reverse;
    $lbi->_move_ip_once($lbi->get_curip);
    $ip->dir_reverse;
}


sub block_close {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # No opened block.
    $ip->ss_count <= 0 and $ip->dir_reverse, debug("no opened block\n"), return;

    debug( "block closing\n" );

    # Restore Storage offset.
    $ip->set_storage( $ip->soss_pop_vec );

    # Remove the TOSS.
    $ip->ss_remove( $ip->spop );
}


sub bloc_transfer {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    $ip->ss_count <= 0 and $ip->dir_reverse, debug("no SOSS available\n"), return;

    # Transfering values.
    debug( "transfering values\n" );
    $ip->ss_transfer( $ip->spop );
}

sub store_get {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching coordinates.
    my ($v) = $ip->spop_vec;
    $v += $ip->get_storage;

    # Fetching char.
    my $val = $lbi->get_storage->get_value( $v );
    $ip->spush( $val );

    debug( "fetching value at $v: pushing $val\n" );
}


sub store_put {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching coordinates.
    my ($v) = $ip->spop_vec;
    $v += $ip->get_storage;

    # Fetching char.
    my $val = $ip->spop;
    $lbi->get_storage->set_value( $v, $val );

    debug( "storing value $val at $v\n" );
}

sub stdio_out_num {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetch value and print it.
    my $val = $ip->spop;
    debug( "numeric output: $val\n");
    print( "$val " ) or $ip->dir_reverse;
}


sub stdio_out_ascii {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetch value and print it.
    my $val = $ip->spop;
    my $chr = chr $val;
    debug( "ascii output: '$chr' (ord=$val)\n");
    print( $chr ) or $ip->dir_reverse;
}


sub stdio_in_num {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    my ($in, $nb) = ('', 0);
    my $last = 0;
    while(!$last) {
        my $char = $lbi->get_input();
        $in .= $char if defined $char;
        my $overflow;
        ($nb, $overflow) = $in =~ /(-?\d+)(\D*)$/;
        if((defined($overflow) && length($overflow)) || !defined($char)) {
            # either we found a non-digit character: $overflow
            # or else we reached EOF: !$char
            return $ip->dir_reverse() unless defined $nb;
            $nb < -2**31  and $nb = -2**31;
            $nb > 2**31-1 and $nb = 2**31-1;
            $in = $overflow;
            $last++;
        }
    }
    $lbi->set_input( $in );
    $ip->spush( $nb );
    debug( "numeric input: pushing $nb\n" );
}


sub stdio_in_ascii {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;
    my $in = $lbi->get_input();
    return $ip->dir_reverse unless defined $in;
    my $ord = ord $in;
    $ip->spush( $ord );
    debug( "ascii input: pushing $ord\n" );
}


sub stdio_in_file {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetch arguments.
    my $path = $ip->spop_gnirts;
    my $flag = $ip->spop;
    my ($vin) = $ip->spop_vec;
    $vin += $ip->get_storage;

    # Read file.
    debug( "input file '$path' at $vin\n" );
    open F, "<", $path or $ip->dir_reverse, return;
    my $lines;
    {
        local $/; # slurp mode.
        $lines = <F>;
    }
    close F;

    # Store the code and the result vector.
    my ($size) = $flag % 2
        ? ( $lbi->get_storage->store_binary( $lines, $vin ) )
        : ( $lbi->get_storage->store( $lines, $vin ) );
    $ip->spush_vec( $size, $vin );
}


sub stdio_out_file {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetch arguments.
    my $path = $ip->spop_gnirts;
    my $flag = $ip->spop;
    my ($vin) = $ip->spop_vec;
    $vin += $ip->get_storage;
    my ($size) = $ip->spop_vec;
    my $data = $lbi->get_storage->rectangle( $vin, $size );

    # Cosmetics.
    my $vend = $vin + $size;
    debug( "output $vin-$vend to '$path'\n" );

    # Treat the data chunk as text file?
    if ( $flag & 0x1 ) {
        $data =~ s/ +$//mg;    # blank lines are now void.
        $data =~ s/\n+\z/\n/;  # final blank lines are stripped.
    }

    # Write file.
    open F, ">", $path or $ip->dir_reverse, return;
    print F $data;
    close F;
}


sub stdio_sys_exec {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching command.
    my $path = $ip->spop_gnirts;
    debug( "spawning external command: $path\n" );
    system( $path );
    $ip->spush( $? == -1 ? -1 : $? >> 8 );
}

sub sys_info {
    my ($lbi) = @_;
    my $ip      = $lbi->get_curip;
    my $storage = $lbi->get_storage;

    my $val = $ip->spop;
    my @infos = ();

    # 1. flags
    push @infos, 0x01  # 't' is implemented.
              |  0x02  # 'i' is implemented.
              |  0x04  # 'o' is implemented.
              |  0x08  # '=' is implemented.
              | !0x10; # buffered IO (non getch).

    # 2. number of bytes per cell.
    # 32 bytes Funge: 4 bytes.
    push @infos, 4;

    # 3. implementation handprint.
    my $handprint = 0;
    $handprint = $handprint * 256 + ord($_) for split //, $lbi->get_handprint;
    push @infos, $handprint;

    # 4. version number.
    my $ver = $Language::Befunge::VERSION;
    $ver =~ s/\D//g;
    push @infos, $ver;

    # 5. ID code for Operating Paradigm.
    push @infos, 1;             # C-language system() call behaviour.

    # 6. Path separator character.
    push @infos, ord( catfile('','') );

    # 7. Number of dimensions.
    push @infos, $ip->get_dims;

    # 8. Unique IP number.
    push @infos, $ip->get_id;

    # 9. Unique team number for the IP (NetFunge, not implemented).
    push @infos, 0;

    # 10. Position of the curent IP.
    my @pos = ( $ip->get_position->get_all_components );
    push @infos, \@pos;

    # 11. Delta of the curent IP.
    my @delta = ( $ip->get_delta->get_all_components );
    push @infos, \@delta;

    # 12. Storage offset of the curent IP.
    my @stor = ( $ip->get_storage->get_all_components );
    push @infos, \@stor;

    # 13. Top-left point.
    my $min = $storage->min;
    # FIXME: multiple dims?
    my @topleft = ( $min->get_component(0), $min->get_component(1) );
    push @infos, \@topleft;

    # 14. Dims of the storage.
    my $max = $storage->max;
    # FIXME: multiple dims?
    my @dims = ( $max->get_component(0) - $min->get_component(0),
                 $max->get_component(1) - $min->get_component(1) );
    push @infos, \@dims;

    # 15/16. Current date/time.
    my ($s,$m,$h,$dd,$mm,$yy)=localtime;
    push @infos, $yy*256*256 + ($mm+1)*256 + $dd;
    push @infos, $h*256*256 + $m*256 + $s;

    # 17. Size of stack stack.
    push @infos, $ip->ss_count + 1;

    # 18. Size of each stack in the stack stack.
    # note: the number of stack is given by previous value.
    my @sizes = reverse $ip->ss_sizes;
    push @infos, \@sizes;

    # 19. $file + params.
    my $str = join chr(0), $lbi->get_file, @{$lbi->get_params}, chr(0)x2;
    my @cmdline = reverse map { ord } split //, $str;
    push @infos, \@cmdline;

    # 20. %ENV
    # 00EULAV=EMAN0EULAV=EMAN
    $str = "";
    $str .= "$_=$ENV{$_}".chr(0) foreach sort keys %ENV;
    $str .= chr(0);
    my @env = reverse map { ord } split //, $str;
    push @infos, \@env;

    my @cells = map { ref($_) eq 'ARRAY' ? (@$_) : ($_) } reverse @infos;

    # Okay, what to do with those cells.
    if ( $val <= 0 ) {
        # Blindly push them onto the stack.
        debug( "system info: pushing the whole stuff\n" );
        $ip->spush(@cells);

    } elsif ( $val <= scalar(@cells) ) {
        # Only push the wanted value.
        debug( "system info: pushing the ${val}th value\n" );
        $ip->spush( $cells[$#cells-$val+1] );

    } else {
        # Pick a given value in the stack and push it.
        my $offset = $val - $#cells - 1;
        my $value  = $ip->svalue($offset);
        debug( "system info: picking the ${offset}th value from the stack = $value\n" );
        $ip->spush( $value );
    }
}

sub spawn_ip {
    my ($lbi) = @_;

    # Cosmetics.
    debug( "spawning new IP\n" );

    # Cloning and storing new IP.
    my $newip = $lbi->get_curip->clone;
    $newip->dir_reverse;
    $lbi->move_ip($newip);
    push @{ $lbi->get_newips }, $newip;
}

sub lib_load {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching fingerprint.
    my $count = $ip->spop;
    my $fgrprt = 0;
    while ( $count-- > 0 ) {
        my $val = $ip->spop;
        $lbi->abort( "Attempt to build a fingerprint with a negative number" )
          if $val < 0;
        $fgrprt = $fgrprt * 256 + $val;
    }

    # Transform the fingerprint into a library name.
    my $lib = "";
    my $finger = $fgrprt;
    while ( $finger > 0 ) {
        my $c = $finger % 0x100;
        $lib .= chr($c);
        $finger = int ( $finger / 0x100 );
    }
    $lib = "Language::Befunge::lib::" . reverse $lib;

    # Checking if library exists.
    eval "require $lib";
    if ( $@ ) {
        debug( sprintf("unknown extension $lib (0x%x): reversing\n", $fgrprt) );
        $ip->dir_reverse;
    } else {
        debug( sprintf("extension $lib (0x%x) loaded\n", $fgrprt) );
        my $obj = $lib->new;
        $ip->load( $obj );
        $ip->spush( $fgrprt, 1 );
    }
}


sub lib_unload {
    my ($lbi) = @_;
    my $ip = $lbi->get_curip;

    # Fetching fingerprint.
    my $count = $ip->spop;
    my $fgrprt = 0;
    while ( $count-- > 0 ) {
        my $val = $ip->spop;
        $lbi->abort( "Attempt to build a fingerprint with a negative number" )
          if $val < 0;
        $fgrprt = $fgrprt * 256 + $val;
    }

    # Transform the fingerprint into a library name.
    my $lib = "";
    my $finger = $fgrprt;
    while ( $finger > 0 ) {
        my $c = $finger % 0x100;
        $lib .= chr($c);
        $finger = int ( $finger / 0x100 );
    }
    $lib = "Language::Befunge::lib::" . reverse $lib;

    # Checking if library exists.
    eval "require $lib";
    if ( $@ ) {
        debug( sprintf("unknown extension $lib (0x%x): reversing\n", $fgrprt) );
        $ip->dir_reverse;
    } else {
        # Unload the library.
        debug( sprintf("unloading library $lib (0x%x)\n", $fgrprt) );
        $ip->unload($lib);
    }
}


sub lib_run_instruction {
    my ($lbi) = @_;
    my $ip   = $lbi->get_curip;
    my $char = $lbi->get_storage->get_char( $ip->get_position );

    # Maybe a library semantics.
    debug( "library semantics\n" );
    my $stack = $ip->get_libs->{$char};

    if ( scalar @$stack ) {
        my $obj = $stack->[-1];
        debug( "library semantics processed by ".ref($obj)."\n" );
        $obj->$char( $lbi );
    } else {
        # Non-overloaded capitals default to reverse.
        debug("no library semantics found: reversing\n");
        $ip->dir_reverse;
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::Ops - definition of the various operations

=head1 VERSION

version 5.000

=head1 DESCRIPTION

This module implements the various befunge operations. Not all those
operations will be supported by the interpreter though, it will depend
on the type of befunge chosen.

=head1 SUBROUTINES

=head2 Numbers

=over 4

=item num_push_number(  )

Push the current number onto the TOSS.

=back

=head2 Strings

=over 4

=item str_enter_string_mode(  )

=item str_fetch_char(  )

=item str_store_char(  )

=back

=head2 Mathematical operations

=over 4

=item math_addition(  )

=item math_substraction(  )

=item math_multiplication(  )

=item math_division(  )

=item math_remainder(  )

=back

=head2 Direction changing

=over 4

=item dir_go_east(  )

=item dir_go_west(  )

=item dir_go_north(  )

=item dir_go_south(  )

=item dir_go_high(  )

=item dir_go_low(  )

=item dir_go_away(  )

=item dir_turn_left(  )

Turning left, like a car (the specs speak about a bicycle, but perl
is _so_ fast that we can speak about cars ;) ).

=item dir_turn_right(  )

Turning right, like a car (the specs speak about a bicycle, but perl
is _so_ fast that we can speak about cars ;) ).

=item dir_reverse(  )

=item dir_set_delta(  )

Hmm, the user seems to know where he wants to go. Let's trust him/her.

=back

=head2 Decision making

=over 4

=item decis_neg(  )

=item decis_gt(  )

=item decis_horiz_if(  )

=item decis_vert_if(  )

=item decis_z_if(  )

=item decis_cmp(  )

=back

=head2 Flow control

=over 4

=item flow_space(  )

A serie of spaces is to be treated as B<one> NO-OP.

=item flow_no_op(  )

=item flow_comments(  )

Bypass comments in B<zero> tick.

=item flow_trampoline(  )

=item flow_jump_to(  )

=item flow_repeat(  )

=item flow_kill_thread(  )

=item flow_quit(  )

=back

=head2 Stack manipulation

=over 4

=item stack_pop(  )

=item stack_duplicate(  )

=item stack_swap(  )

=item stack_clear(  )

=back

=head2 Stack stack manipulation

=over 4

=item block_open(  )

=item block_close(  )

=item bloc_transfer(  )

=back

=head2 Funge-space storage

=over 4

=item store_get(  )

=item store_put(  )

=back

=head2 Standard Input/Output

=over 4

=item stdio_out_num(  )

=item stdio_out_ascii(  )

=item stdio_in_num(  )

=item stdio_in_ascii(  )

=item stdio_in_file(  )

=item stdio_out_file(  )

=item stdio_sys_exec(  )

=back

=head2 System info retrieval

=over 4

=item sys_info(  )

=back

=head2 Concurrent Funge

=over 4

=item spawn_ip(  )

=back

=head2 Library semantics

=over 4

=item lib_load(  )

=item lib_unload(  )

=item lib_run_instruction( )

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
