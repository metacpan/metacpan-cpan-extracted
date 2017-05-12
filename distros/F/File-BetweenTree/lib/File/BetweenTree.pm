package File::BetweenTree;

# Copyright (C) 2013 by Mitsuru Yasuda. All rights reserved.
# mail bugs, comments and feedback to dsyrtm@gmail.com

use strict;
use warnings;
use Carp ':DEFAULT', 'confess';
use Fcntl qw(:seek O_RDONLY);

our $VERSION = '1.02';

sub new {
	my ($class, $file, $recsep) = @_;
	my $self;

	$self->{_sep_} = $recsep || ($^O =~ /win32/i) ? "\015\012"
	                           :($^O =~ /mac/i)   ? "\015" : "\012";
	bless($self, $class);
	sysopen $self->{fh}, $file, O_RDONLY or return;
	binmode $self->{fh};

	return $self;
}
sub search {
	my($self,
	   $my_min,
	   $my_max,
	   $mode,
	   $result_limit,
	   $result_offset,
	   $order_by,
	   $col_sep,
	   $col_num,
	  ) = @_;
	$my_max = '' ? $my_min : $my_max;
	$result_limit  ||= 1000;
	$result_offset ||= 0;
	$order_by      ||= 'ASC';
	$col_sep       ||= ',';
	$col_num       ||= 0;
	$mode          ||= 0;

	croak "0 mode, only the number" if
	!$mode && ($my_min =~ /[^\-\.\d]/ || $my_max =~ /[^\-\.\d]/);

	my $read_size = 1 << 12;

	# debug reverse
	if (!$mode && ( $my_min > $my_max )) {
	  ($my_min, $my_max) = ($my_max, $my_min);
	}
	elsif ($mode && ($my_min cmp $my_max) eq 1 ) {
	  ($my_min, $my_max) = ($my_max, $my_min);
	}

	seek $self->{fh}, 0, SEEK_END;
	  my $size = tell $self->{fh};

	$self->{col_sep} = $col_sep;
	$self->{col_num} = $col_num;
	my($row,$tip,$str);

	my $_var = int ($size / 2);
	my $_pos = $_var;
	my $_min = 0;
	my $_top = 0;# minimum of _max 
	my $_max = $size;
	while (1) {
	  ($str,$tip,$row)=$self->scoop($_pos);
	  $_var = int ($_var / 2);
	  # want to approach the my_max
	  if ($mode) {
	    if ( ($my_max cmp $str) eq -1 && ( $_max > $_pos ) ) {
	      $_max = $_pos; $self->{_mon_} .= "<=|";
	    } elsif (($my_max cmp $str) eq 1 && ($_top < $_pos)) {
	      $_top = $_pos; $self->{_mon_} .= "=>|";
	    } else { $self->{_mon_} .= "  |" }
	  }
	  else {
	    if ( ($my_max-$str) < 0 && ( $_max > $_pos ) ) {
	      $_max = $_pos; $self->{_mon_} .= "<=|";
	    } elsif (($my_max-$str) > 0 && ($_top < $_pos)) {
	      $_top = $_pos; $self->{_mon_} .= "=>|";
	    } else { $self->{_mon_} .= "  |" }
	  }
	  
	  # adjust the minimum value
	  if (
	    ( $mode && ($my_min cmp $str) < 1 ) || 
	    (!$mode &&  $my_min <=  $str)    
	  ) {
	    $self->{_mon_} .= "<- $_pos $_var\n";
	    $_pos -= $_var;
	  }
	  else {
	    $self->{_mon_} .= "-> $_pos $_var | min\n";
	    $_min = $_pos; $_pos += $_var;

	  }

	  last if( $_var < $read_size );#
	}

	# adjust the maximum value
	$_var = int(($_max - $_top) / 2);
	$_pos = $_top + $_var;
	while (1) {
	  ($str,$tip,$row)=$self->scoop($_pos);
	  $_var = int ($_var / 2);
	  if (($mode && ($my_max cmp $str) >= 0
	  || (!$mode &&  $my_max >=  $str))){
	    $_pos += $_var;
	    $self->{_mon_} .= "=>|   $_pos $_var\n";
	  }
	  else {

	    $_max = $_pos + $tip; $_pos -= $_var;
	    $self->{_mon_} .= "<=|   $_pos $_var | max\n";
	  }
	  last if( $_var < $read_size );#
	}

	# Locate The Data From Block
	my (@z, @_add);
	my ($dat, $ll, $_z, $_s, $count, $spare);
	my $t = '';
	my $_sep = '';
	$self->{_mon_} = "roughly_offset_addr:$_min "
	                ."search_length:".($_max-$_min)."\n\n"
	                . $self->{_mon_};

	if ($order_by =~ /DESC/i) {
	  my $read_pos = $_max;
	  while (1) {

	    $count++;

	    $read_pos -= $read_size;
	    if ($read_pos < 0) { $read_size += $read_pos; $read_pos = 0 }

	    seek $self->{fh}, $read_pos, 0;
	    read $self->{fh}, $dat, $read_size;

	    $dat .= $t;
	    @z = reverse split $self->{_sep_}, $dat;
	    shift @z if ($count eq 1 && $_max ne $size );

	    for $ll ( 1 .. $#z ){

	      $_z = shift @z;
	      $_s = (split $col_sep, $_z)[$col_num];

	      unless (!$mode && $_s =~ /[^\-\.\d]/) {
	        push @_add, $_z if ((
	          (!$mode && $my_min <= $_s && $_s <= $my_max ) ||
	          ( $mode && ($my_min cmp $_s) < 1 && ($_s cmp $my_max) < 1 ))
	          && (--$result_offset < 0)
	          && (--$result_limit >= 0));

	        $spare = $_z if(
	        (!$spare && !$mode &&  $my_min >=  $_s) ||
	        (!$spare &&  $mode && ($my_min cmp $_s) >= 0) );
	      }

	    last if $result_limit <= 0;
	    }
	  $t = shift @z;
	  $_s = (split $col_sep, $t)[$col_num] || '';

	  push @_add, $t if(($read_pos eq 0)
	    &&((!$mode && $my_min <= $_s && $_s <= $my_max )
	    ||(  $mode && ($my_min cmp $_s) < 1 && ($_s cmp $my_max) < 1 )));

	  last if ($read_pos <= $_min || $result_limit <= 0);
	  }
	}

	else { # AEC

	  my $read_pos = $_min;
	  my $eof = 1;
	  while (1) {

	    $count++;

	    seek $self->{fh}, $read_pos, 0;
	    read $self->{fh}, $dat, $read_size;

	      $dat = $t . $_sep . $dat;
	     #$_sep = $dat =~  /($self->{_sep_})$/  ? $1 : '';
	      $_sep = $dat =~ s/($self->{_sep_})$// ? $1 : '';

	      @z = split $self->{_sep_}, $dat;
	      shift @z if ($count eq 1 && $_min ne 0);

	    $read_pos += $read_size;
	      $eof = 0 if ($read_pos >= $_max);

	    for $ll ( $eof .. $#z ){

	      $_z = shift @z;
	      $_s = (split $col_sep, $_z)[$col_num];

	      unless (!$mode && $_s =~ /[^\-\.\d]/) {
	        push @_add, $_z if ((
	          ( $mode && ($my_min cmp $_s) < 1 && ($_s cmp $my_max) < 1) || 
	          (!$mode && $my_min <= $_s && $_s <= $my_max ))
	          && (--$result_offset < 0)
	          && (--$result_limit >= 0));

	        $spare = $_z if( # && $#z >= 0 
	          ( $mode  && ($my_min cmp $_s) >= 0) ) ||
	          (!$mode  && $my_min >= $_s);
	      }

	      last if $result_limit <= 0;
	    }
	    $t = shift @z;

	    last if
	    ($read_pos >= $_max || $read_pos > $size || $result_limit <= 0);
	  }
	}

	$self->{_mon_} = "file_read:$count " . $self->{_mon_};

	$spare = '' unless defined $spare;
	return @_add ? \@_add : ['NULL', $spare];

}
sub scoop {
	my ($self, $_pos) = @_;
	my ($row, $tip);
	seek $self->{fh}, $_pos, 0; read $self->{fh}, $row, 1024;
	($tip, $row) = split /$self->{_sep_}/, $row; $tip = length($tip)+1;
	my $str = (split($self->{col_sep}, $row))[$self->{col_num}];
	return ($str,$tip,$row);
}
sub mon     {
	"Process:\n-----------------------\n".
	shift->{_mon_};
}
sub DESTROY {
	my $self = shift;
	defined $self->{fh} && close $self->{fh};
}
sub view {
	#
	# viewing by specifying a pointer
	# 
	# Example:
	# print $bt->view(0, 1024);
	#
	my ($self, $offset_byts, $length) = @_;
	my $dat;
	seek $self->{fh}, $offset_byts, 0;
	read $self->{fh}, $dat, $length;
	join "\n", split $self->{_sep_}, $dat;
}

__END__


=head1 NAME

File::BetweenTree.pm - binary search of variable length.


=head1 SYNOPSIS

	use File::BetweenTree;

	# Object interface
	$bt = File::BetweenTree->new("log_file") or
			die "Can't open file: $!";

	# .. Gets between a and b
	$result_array_ref = $bt->search($a, $b);

	# .. or only a
	$result_array_ref = $bt->search($a);

	# .. process monitor
	print $bt->mon;


=head1 DESCRIPTION

This module tracks the data instantly from "Sorted file of variable length" 
with a binary search. It is simple to use,
memory efficient and search instantly from the files of 100 million.

You can choose to search in ascending or descending order.Further Can set 
the offset and the number of results.
you can set the input record separator string on a per file basis.


=head1 OBJECT INTERFACE
 
These are the methods in C<File::BetweenTree>' object interface:

=head2 new($file, [ $rec_sep ]);

C<new> takes as arguments a filename, an optional record separator.
set the default record separator according to this OS.


=head2 C<search>

C<search> is able to find all of the intermediate element "two elements".

	search(
	$a, $b, [mode], [limit], [offset], [order_by], [col_sep], [col_num]
	);

look for the data between <$a> and <$b>.
<$a>, the maximum and minimum values are <$b>.

It can be the same value <$b> a <$a>.

The return value is an array reference. If you can not find a match, 
it returns a NULL data. Nearby value is returned to the second. Become 
undef if the minimum value of the one front does not exist.

	@{$result_array_ref}[0] => NULL
	@{$result_array_ref}[1] => ..Minimum value near

C<mode> is optional; the default is '0'
Search target set number or a text string. Settings are required to 
appropriate an accurate result.

	[mode]
	0 : number string search dedicated
	1 : text string search dedicated.

C<limit> is optional; the default is '1000'

	[limit]
	You can use C<limit> to restrict the scope of the C<search>.

C<offset> is optional; the default is '0'

	[offset]
	This specifies the offset of the first row to return

C<order_by> is optional; the default is 'ASC'
Select a search in ascending or descending order

	[order_by]
	ASC  : ascending
	DESC : descending

C<col_sep> is optional; the default is ','
You can specify a separator to divide the line.

	[col_sep]
	example: value_0:value_1:value_2 => ":"

C<col_num> is optional; the default is '0'
Order of the sequence obtained by dividing the line.

	[col_num]
	example: value_0,value_1,value2 => Value_1 and is "1"


=head1 For example:

	foo.txt
	-------
	0:apple
	1:apple
	2:apple
	3:blackberry
	4:blackberry
	5:lemon
	6:lemon
	7:lemon
	8:orange
	9:orange
	0:pine

	my $result_array_ref = $bt->search(
	   'lemon', # mininum data
	   'orang', # maximum data
	   1,       # mode is text string
	   10,      # result 10 limit
	   0,       # offset 0
	   'ASC',   # order_by: ascending
	   ':',     # separator to divide the line
	   1,       # data of the second from the left
	   );
	print "result = " . join("\n", @{$result_array_ref});

	result = 5:lemon 6:lemon 7:lemon 8:orange 9:orange.


=head1 C<mon>

You can monitor the state of the processing.

	print $bt->mon;

	Process:
	-----------------------
	file_read:1 roughly_start_addr:420200 search_length:2285

	<=|<- 37415913 18707956
	<=|<- 18707957 9353978
	<=|<- 9353979 4676989
	<=|<- 4676990 2338494
	<=|<- 2338496 1169247
	<=|<- 1169249 584623
	<=|<- 584626 292311
	=>|-> 292315 146155 | min
	<=|<- 438470 73077
	=>|-> 365393 36538 | min
	=>|-> 401931 18269 | min
	=>|-> 420200 9134 | min
	<=|<- 429334 4567
	<=|<- 424767 2283
	<=|   421342 1141 | max

=head2 Interpretation above

=item <- : $a Move to low  addr the current pointer.
=item -> : $a Move to high addr the current pointer.
=item <= : $b Move to low  addr the current pointer.
=item => : $b Move to high addr the current pointer.

=item Number of first : current pointer addr.
=item Number of second: Amount of movement of the pointer.

=item | min : Addr with a minimum value determined for the time being.
=item | max : Addr with a maximum value determined for the time being.


=head1 AUTHOR

Mitsuru Yasuda, dsyrtm@cpan.org

	http://simql.com/


=head1 COPYRIGHT & LICENSE

Copyright (C) 2013 by Mitsuru Yasuda &

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
