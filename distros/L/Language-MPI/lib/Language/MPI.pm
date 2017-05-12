# MPI.pm

=pod

=head1 NAME

Language::MPI - 2008.0217 Message Parsing Interpreter

=head1 SYNOPSIS

Processor for the Message Parsing Interpreter text
composition language, based on the MPI found in MU* online
environments, adapted for more general semantics.

http://en.wikipedia.org/wiki/Message_Parsing_Interpreter

=head1 USAGE

	use Language::MPI;
	$node = new Language::MPI($noderef);
	$node->setvar("varname", "varval");
	$results = $node->parse("tick {set:varname,{time:}} tock");
	$val = $node->readvar("varname");

MPI assumes an operating environment consisting of a set
of nodes each of which has a set of named properties.  How
these nodes and properties are stored and structured is up
to the application except that:

=over

=item * noderefs are perl scalars used by application
supplied functions.  Something with a printable value is
encouraged but not required.

=item * properties may be identified by and resolve to
plain text strings.

=back

MPI, in the interest of more general usage, expects some
support subroutines to be supplied by app to access nodes
and properties.  Should any of these not be supplied, errors
are trapped to prevent crashing.  Functions not needing
these should still work properly.  Should the application
designer wish, app data to be passed to these callbacks may
be set into and read from the object by the setvar() and
readvar() methods.

=over

=item mpi_neighbors($thisnode, $pattern, $obj)

$thisnode is a noderef.
$pattern is a string pattern used to specify which nodes
'neighboring' the current node are of interest.
returns list of noderefs;

=item mpi_prop($thisnode, $propname, $obj)

$propname is the string name of a property.
returns propval;

=item mpi_props($thisnode, $proppat, $obj)

$propat is a string specifier to a property directory or a
subset of properties.
returns list of propnames;

=item mpi_propset($thisnode, $propname, $val, $obj)

=back

=head1 INSTALATION

	perl Makefile.PL
	make
	make install

Or simply copy the MPI.pm file to Language/ under the perl
modules directory.  README and the man file for this package
exist as pod data in MPI.pm.

=head1 STATUS

Some MPI standard functions incomplete or unimplimented.  Testing incomplete.

=head1 Etc

This code developed using perl 5.8.8.  Might work with perl
5.6.0 or older with proper libraries.  Uses strict and warning.

Copyright (c)2007 Peter Hanely. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 LANGUAGE

=head2 VARS

=over

=item Variable names of alphabetic characters are general MPI use.

=item Names beginning with an underscore "_" are reserved
for mpi internal variables and should not be used by the
application.

=item Names beginning with "\" are suggested for application
values placed in the mpi object.

=cut

use strict;
use warnings;
# warning good for debug, but produce noise from good code
no warnings qw(uninitialized);
#use Carp;

package Language::MPI;

our ($VERSION, @ISA, @EXPORT_OK, $perl_list);
#use vars qw($VERSION, @ISA, @EXPORT_OK, $perl_list);

BEGIN
{
  require Exporter;
  our ($VERSION, @ISA, @EXPORT_OK);

  @ISA = qw(Exporter);
  @EXPORT_OK = qw(parse setvar readvar simp_functions);
  
  $VERSION = "2008.0217";
}

# control functions alter execution of their parameters,
# and thus parse their own parameters.
my %ctrl_functions =
(	'debug'	=> \&func_debug,
	'debugif'	=> \&func_debugif,
	'filter'	=> \&func_filter,
	'fold'		=> \&func_fold,
	'for'		=> \&func_for,
	'foreach'	=> \&func_foreach,
#	'func'	=> \&func_func,
	'if'		=> \&func_if,
	'lit'		=> \&func_lit,
	'lsort'		=> \&func_lsort,
	'neighbors'	=> \&func_neighbors,
	'parse'		=> \&func_parse,
	'while'	=> \&func_while,
	'with'	=> \&func_with
);

# simple functions have their parameters parsed by calling code.
my %simp_functions =
(	'abs'	=> \&func_abs,
	'add'	=> \&func_add,
	'and'	=> \&func_and,
	'attr'	=> \&func_attr,
	'convsecs'	=> \&func_convsecs,
	'convtime'	=> \&func_convtime,
	'count'	=> \&func_count,
	'date'	=> \&func_date,
	'debug'	=> \&func_debug,
	'debugif'	=> \&func_debugif,
	'dec'	=> \&func_dec,
	'default'	=> \&func_default,
	'delprop'	=> \&func_delprop,
	'dice'	=> \&func_dice,
	'dist'	=> \&func_dist,
	'div'	=> \&func_div,
	'eq'	=> \&func_eq,
	'escape'	=> \&func_escape,
	'eval'	=> \&func_eval,
	'exec'	=> \&func_exec,
	'filter'	=> \&func_filter,
	'fold'	=> \&func_fold,
	'for'	=> \&func_for,
	'foreach'	=> \&func_foreach,
	'ftime'	=> \&func_ftime,
	'fullname'	=> \&func_fullname,
	'func'	=> \&func_func,
	'ge'	=> \&func_ge,
	'gt'	=> \&func_gt,
	'if'	=> \&func_if,
	'inc'	=> \&func_inc,
	'index'	=> \&func_index,
	'instr'	=> \&func_instr,
	'isnum'	=> \&func_isnum,
	'lcommon'	=> \&func_lcommon,
	'le'	=> \&func_le,
	'list'	=> \&func_list,
	'listprops'	=> \&func_listprops,
	'lit'	=> \&func_lit,
	'lmember'	=> \&func_lmember,
	'lrand'	=> \&func_lrand,
	'lremove'	=> \&func_lremove,
	'lsort'	=> \&func_lsort,
	'lt'	=> \&func_lt,
	'ltimestr'	=> \&func_ltimestr,
	'lunion'	=> \&func_lunion,
	'lunique'	=> \&func_lunique,
	'max'	=> \&func_max,
	'midstr'	=> \&func_midstr,
	'min'	=> \&func_min,
	'mklist'	=> \&func_mklist,
	'mod'	=> \&func_mod,
	'mult'	=> \&func_mult,
	'name'	=> \&func_name,
	'ne'	=> \&func_ne,
	'neighbors2'	=> \&func_neighbors2,
	'nl'	=> \&func_nl,
	'not'	=> \&func_not,
	'null'	=> \&func_null,
	'or'	=> \&func_or,
	'parse'	=> \&func_parse,
	'prop'	=> \&func_prop,
	'rand'	=> \&func_rand,
	'secs'	=> \&func_secs,
	'select'	=> \&func_select,
	'set'	=> \&func_set,
	'sign'	=> \&func_sign,
	'smatch'	=> \&func_smatch,
	'stimestr'	=> \&func_stimestr,
	'store'	=> \&func_store,
	'strip'	=> \&func_strip,
	'strlen'	=> \&func_strlen,
	'sublist'	=> \&func_sublist,
	'subst'	=> \&func_subst,
	'subt'	=> \&func_subt,
	'time'	=> \&func_time,
	'timestr'	=> \&func_timestr,
	'timesub'	=> \&func_timesub,
	'tolower'	=> \&func_tolower,
	'toupper'	=> \&func_toupper,
	'tzoffset'	=> \&func_tzoffset,
	'v'	=> \&func_v,
	'version'	=> \&func_version,
	'while'	=> \&func_while,
	'with'	=> \&func_with,
	'xor'	=> \&func_xor
);

=head1 MPI primitives

=cut

=head2 {abs:num}

=cut

sub func_abs
{ my ($this, $val) = @_;
  abs $val->[0];
}

=head2 {add:num1,num2...}

=cut

sub func_add
{ my ($this, $val) = @_;
  my ($num, $tot);
  foreach $num (@$val)
  { $tot += $num; }
  $tot;
}

=head2 {and:num1,num2...}

=cut

sub func_and
{ my ($this, $val) = @_;
  my ($num, $tot);
  $tot = 1;
  foreach $num (@$val)
  { #$tot &&= $num;
    if (!$num) { $tot = 0; }
  }
  $tot;
}

=head2 {attr:attribute...,text}

=cut

sub func_attr
{ my ($this, $val) = @_;
  #stub
  $$val[-1];
}

sub func_convsecs
{ my ($this, $val) = @_;

}

sub func_convtime
{ my ($this, $val) = @_;

}

=head2 {count:array}

=cut

sub func_count
{ my ($this, $val) = @_;
  my (@arry);
  @arry = &unpack_list($val->[0]);
  return (scalar (@arry));
}

=head2 {date:}

=cut

sub func_date
{ my ($sec, $min, $hour, $mday, $mon, $year) = gmtime (time());
  if ($year < 1000) { $year += 1900; }
  $mon++;
  "$mon/$mday/$year";
}

sub func_debug
{ }

sub func_debugif
{ }

=head2 {dec:var,dec}

=cut

sub func_dec
{ my ($this, $val) = @_;
  my ($var, $inc) = @$val;
  $inc = $inc || 1;
  $this->{$var} -= $inc;
}

=head2 {default:var1,var2...}

=cut

sub func_default
{ my ($this, $val) = @_;
  my ($indx) = 0;
  while (($indx < @$val) && !($val->[$indx])) { $indx ++ }
  if ($indx < @$val) { $val->[$indx]; }
  else { ""; }
}

=head2 {delprop:var[,obj]}

=cut

sub func_delprop
{ my ($this, $val) = @_;
  my ($prop, $obj) = @$val;
  $obj = $obj || $this->{'_node'};
  if (defined &mpi_propset)
  { eval (&mpi_propset($obj, $prop, "", $this)); }
}

=head2 {dice:range[,count[,bonus]]}

=cut

sub func_dice
{ my ($this, $val) = @_;
  my ($range, $count, $bonus) = @$val;
  my ($indx, $tot);
  if ($count <= 0) { $count = 1; }
  for ($indx = 0; $indx < $count; $indx ++)
  { $tot += int(rand($range)+1); }
  $tot+$bonus;
}

=head2 {dist:x1,y2...}

=cut

sub func_dist
{ my ($this, $val) = @_;
  my ($x1, $y1, $z1, $x2, $y2, $z2) = @$val;
  if (@$val == 4)
  { ($x2, $y2) = ($z1, $x2); }
  my ($dx, $dy, $dz) = ($x2-$x1, $y2-$y1, $z2-$z1);
  sqrt($dx*$dx + $dy*$dy + $dz*$dz);
}

=head2 {div:num,num1...}

=cut

sub func_div
{ my ($this, $val) = @_;
  int($val->[0]/$val->[1]);
}

=head2 {eq:var1,var2}

=cut

sub func_eq
{ my ($this, $val) = @_;
  $val->[0] eq $val->[1];
}

sub func_escape
{ }

=head2 {eval:vars...}

=cut

sub func_eval
{ my ($this, $val) = @_;
  my ($tot, $param);
  foreach $param(@$val)
  { $tot .= &parse($this, $param); }
  $tot;
}

=head2 {exec:prop[,node]}

=cut

sub func_exec
{ my ($this, $val) = @_;
  my ($prop, $obj) = @$val;
  my ($tmp) = "";
  my ($propval) = eval {&mpi_prop($obj || $this->{'_node'}, $prop, $this)};
  if ($propval)
  { $tmp = &parse($this, $propval) || "" };
  $tmp;
}

sub func_filter
{ }

sub func_fold
{ }

=head2 {for:varname,start,end,increment,commands}

=cut

# control function, parses its own parameters
sub func_for
{ my ($this, $params) = @_;
  my ($varname,$start,$end,$increment,$command, $result, $results);
  ($varname, $params) = &parse_parameter($this, $params);
  ($start, $params) = &parse_parameter($this, $params);
  ($end, $params) = &parse_parameter($this, $params);
  ($increment, $command) = &parse_parameter($this, $params);
  $this->{$varname} = $start;
  if ($increment > 0)
  { while ($this->{$varname} <= $end)
    { ($result, $params) = &parse_parameters($this, $command);
      $results .= join '', @$result;
      $this->{$varname} += $increment;
    }
  }
  elsif ($increment < 0)
  { while ($this->{$varname} <= $end)
    { ($result, $params) = &parse_parameters($this, $command);
      $results .= join '', @$result;
      $this->{$varname} += $increment;
    }
  }
  else # sanity case
  { ($result, $params) = &parse_parameters($this, $command);
    $results .= join '', @$result;
  }
  ($results, $params);
}

=head2 {foreach:varname,list,command[,list seperator]}

=cut

sub func_foreach
{ my ($this, $params) = @_;
  my ($varname,$list,$expr,$sep, @list, $val, $res, $result);
  ($varname, $params) = &parse_parameter($this, $params);
  ($list, $expr) = &parse_parameter($this, $params);
  ($params) = &skip_param($this, $expr);
  #$sep = $sep || "\n";
  @list = unpack_list($list, $sep);
  foreach $val(@list)
  { $this->{$varname} = $val;
    ($res) = &parse_parameter($this, $expr);
    $result .= $res;
  }
  ($res, $params);
}

sub func_ftime
{ }

sub func_fullname
{ }

=head2 {func:name,var1:var2...,commands}

=cut

sub func_func
{ my ($this, $val) = @_;
  my ($func, $vars, $code) = @$val;
  $this->{"_f_$func"} = $code;
  $this->{"_f_$func v"} = $vars;
  "$func, $vars, $code";
}

=head2 {ge:var1,var2}

=cut

sub func_ge
{ my ($this, $val) = @_;
  $val->[0] >= $val->[1];
}

=head2 {gt:var1,var2}

=cut

sub func_gt
{ my ($this, $val) = @_;
  $val->[0] > $val->[1];
}

=head2 {if:condition,true[,false]}

=cut

sub func_if
{ my ($this, $params) = @_;
  my ($check, $ret);
  ($check, $params) = &parse_parameter($this, $params);
  if ($check)
  { ($ret, $params) = &parse_parameter($this, $params);
    ($params) = &skip_param($this, $params);
  }
  else
  { ($params) = &skip_param($this, $params);
    ($ret, $params) = &parse_parameter($this, $params);
  }
  $ret;
}

=head2 {inc:var,inc}

=cut

sub func_inc
{ my ($this, $val) = @_;
  my ($var, $inc) = @$val;
  $inc = $inc || 1;
  $this->{$var} += $inc;
}

=head2 {index:prop[,obj]}

=cut

sub func_index
{ my ($this, $val) = @_;
  my ($prop, $obj) = @$val;
  $obj = $obj || $this->{"_node"};
  $prop = eval {&mpi_prop($obj, $prop, $this)};
  if ($prop)
  { eval {&mpi_prop($obj, $prop, $this)} || ""; }
}

=head2 {insrt:string1,string2}

=cut

sub func_instr
{ my ($this, $val) = @_;
  my ($str1, $str2) = @$val;
  index($str1, $str2) + 1;
}

sub func_isnum
{ my ($this, $val) = @_;
  my ($num) = @$val;
  if (!$num) { $num = '0e0'; }
  $num;
}

=head2 {lcommon:list1,list2}

=cut

sub func_lcommon
{ my ($this, $val) = @_;
  my ($l1, $l2) = @$val;
  my (%h, $i, @res);
  foreach $i(&unpack_list($l1))
  { $h{$i} = 1; }
  foreach $i(&unpack_list($l2))
  { if ($h{$i})
    { push @res, $i;
      undef $h{$i}; # remove duplicates.
    }
  }
  &pack_list(@res);
}

=head2 {le:var1,var2}

=cut

sub func_le
{ my ($this, $val) = @_;
  $val->[0] <= $val->[1];
}

=head2 {list:props[,obj]}

=cut

sub func_list
{ my ($this, $val) = @_;
  my ($list, $obj) = @$val;
  my (@list, $i);
  $obj = $obj || $this->{"_node"};
  foreach $i(eval{&mpi_props($obj, $list, $this)})
  { push @list, eval(&mpi_prop($obj, $i, $this)); }
  &pack_list(@list);
}

=head2 {listprops:props[,obj]}

=cut

sub func_listprops
{ my ($this, $val) = @_;
  my ($list, $obj) = @$val;
  $obj = $obj || $this->{"_node"};
  &pack_list(eval{&mpi_props($obj, $list, $this)});
}

=head2 {lit:expression to not parse}

=cut

sub func_lit
{ my ($this, $param) = @_;
  my ($lit);
  ($param, $lit) = &skip_parameters($this, $param);
  $lit;
}

=head2 {lmember:list,item[,delimiter]}

=cut

sub func_lmember
{ my ($this, $val) = @_;
  my ($list, $item, $del) = @$val;
  my ($i, @list);
  @list = &unpack_list($list, $del);
  for ($i = 0; $i < @list && $list[$i] ne $item; $i++) { }
  if ($list[$i] eq $item) { return $i+1; }
  0;
}

=head2 {lrand:list[,delimiter]}

=cut

sub func_lrand
{ my ($this, $val) = @_;
  my ($list, $del) = @$val;
  my ($i, @list);
  @list = &unpack_list($list, $del);
  $list[int(rand @list)];
}

=head2 {lremove:list1,list2}

=cut

sub func_lremove
{ my ($this, $val) = @_;
  my ($l1, $l2) = @$val;
  my (%h, $i, @res);
  foreach $i(&unpack_list($l1))
  { $h{$i} = 1; }
  foreach $i(&unpack_list($l2))
  { if (!$h{$i})
    { push @res, $i;
      $h{$i} = 1; # remove duplicates.
    }
  }
  &pack_list(@res);
}

sub func_lsort
{ my ($this, $params) = @_;
  my ($list, @list, $var1, $var2, $code);
  ($list, $params) = &parse_parameter($this, $params);
  # do fancy sort later
  &pack_list(sort &unpack_list($list));
}

=head2 {lt:num1,num2}

=cut

sub func_lt
{ my ($this, $val) = @_;
  $val->[0] < $val->[1];
}

sub func_ltimestr
{ }

=head2 {lunion:list1,list2}

=cut

sub func_lunion
{ my ($this, $val) = @_;
  my ($l1, $l2) = @$val;
  my (%h, $i);
  foreach $i(&unpack_list($l1))
  { $h{$i} = 1; }
  foreach $i(&unpack_list($l2))
  { $h{$i} = 1; }
  &pack_list(keys %h);
}

=head2 {lunique:list}

=cut

sub func_lunique
{ my ($this, $val) = @_;
  my ($l1, $l2) = @$val;
  my (%h, $i, @res);
  foreach $i(&unpack_list($l1))
  { if (!$h{$i})
    { $h{$i} = 1;
      push @res,$i;
    }
  }
  &pack_list(@res);
}

=head2 {max:var1,var2...}

=cut

sub func_max
{ my ($this, $val) = @_;
  my ($tot, $var);
  $tot = $val->[0];
  foreach $var(@$val)
  { if ($tot > $var) { $tot = $var; } }
  $tot;
}

=head2 {midstr:string,start[,end]}

=cut

sub func_midstr
{ my ($this, $val) = @_;
  my ($str, $pos1, $pos2);
  substr ($str, $pos1, $pos2);
}

=head2 {min:var1,var2...}

=cut

sub func_min
{ my ($this, $val) = @_;
  my ($tot, $var);
  $tot = $val->[0];
  foreach $var(@$val)
  { if ($tot > $var) { $tot = $var; } }
  $tot;
}

=head2 {mklist:list items}

=cut

sub func_mklist
{ my ($this, $val) = @_;
  #join "\n", @$val;
  &pack_list(&unpack_list($val));
}

=head2 {mod:num1,num2}

=cut

sub func_mod
{ my ($this, $val) = @_;
  $val->[0] % $val->[1];
}

=head2 {mult:num1,num2...}

=cut

sub func_mult
{ my ($this, $val) = @_;
  my ($num, $tot);
  $tot = 1;
  foreach $num (@$val)
  { $tot *= $num; }
  $tot;
}

sub func_name
{ }

=head2 {ne:var1,var2}

=cut

sub func_ne
{ my ($this, $val) = @_;
  $val->[0] ne $val->[1];
}

=head2 {neighbors:varname,pattern,code}

=cut

sub func_neighbors
{ my ($this, $params) = @_;
  my ($varname,$pattern,$expr, @list, $val, $res, $result);
  ($varname, $params) = &parse_parameter($this, $params);
  ($pattern, $expr) = &parse_parameter($this, $params);
  @list = eval {&mpi_neighbors($this->{'_node'}, $pattern, $this)};
  foreach $val(@list)
  { $this->{$varname} = $val;
    ($res, $params) = &parse_parameter($this, $expr);
    $result .= $res;
  }
  if (@list == 0)
  { $res = "";
    $params = &skip_parameters($this, $expr);
    $params =~ /^\}(.*)/;
    $params = $! || $params;
  }
  ($res, $params);
}

=head2 {neighbors2:pattern}

=cut

sub func_neighbors2
{ my ($this, $params) = @_;
  my ($pattern) = @$params;
  &pack_list(eval {&mpi_neighbors($this->{'_node'}, $pattern, $this)});
}


=head2 {nl:}

=cut

sub func_nl
{ "\n"; }

=head2 {not:var}

=cut

sub func_not
{ my ($this, $val) = @_;
  !($val->[0]);
}

=head2 {null:...}

=cut

sub func_null
{ ""; }

=head2 {or:var1,var2...}

=cut

sub func_or
{ my ($this, $val) = @_;
  my ($num, $tot);
  foreach $num (@$val)
  { #$tot ||= $num;
    if (!$num) { $tot = 0; }
  }
  $tot;
}

sub func_parse
{ }

=head2 {prop:property,node}

=cut

sub func_prop
{ my ($this, $val) = @_;
  my ($prop, $obj) = @$val;
  $obj = $obj || $this->{"_node"};
  eval {&mpi_prop($obj, $prop, $this)} || "";
}

=head2 {rand:props[,obj]}

=cut

sub func_rand
{ my ($this, $val) = @_;
  my ($list, $obj) = @$val;
  my (@list, $i);
  $obj = $obj || $this->{"_node"};
  @list = eval{&mpi_props($obj, $list, $this)};
  eval(&mpi_prop($obj, $list[int(rand @list)], $this));
}

=head2 {secs:}

=cut

sub func_secs
{ time(); }

sub func_select
{ }

=head2 {set:var,val}

=cut

sub func_set
{ my ($this, $val) = @_;
  my ($var, $v) = @$val;
  if ($var =~ /^[a..zA..Z]/) # some vars are reserved for engine use
  { $this->{$var} = $v; }
}

=head2 {sign:num}

=cut

sub func_sign
{ my ($this, $val) = @_;
  $val->[0] <=> 0;
}

=head2 {smatch:string,pattern}

=cut

sub func_smatch
{ my ($this, $val) = @_;
  my ($str, $pat) = @$val;
  $str =~ /($pat)/;
  $1
}

sub func_stimestr
{ }

=head2 {store:val,property[,node]}

=cut

sub func_store
{ my ($this, $val) = @_;
  my ($str, $prop, $obj) = @$val;
  $obj = $obj || $this->{'_node'};
  eval {&mpi_propset($obj, $prop, $str, $this)} || "";
}

=head2 {strip:string}

=cut

sub func_strip
{ my ($this, $val) = @_;
  chomp $val->[0];
  $val->[0] =~ s/^\s*//;
  $val->[0] =~ s/\s*$//;
  $val->[0];
}

=head2 {strlen:string}

=cut

sub func_strlen
{ my ($this, $val) = @_;
  length $val->[0];
}

=head2 {sublist:list,pos1,pos2[,sep]}

=cut

sub func_sublist
{ my ($this, $val) = @_;
  my ($list, $pos1, $pos2, $sep) = @$val;
  my @list = &unpack_list($list, $sep);
  if (!defined($pos2)) { $pos2 = @list; }
  &pack_list( splice( @list, $pos1+1, $pos2-$pos1) );
}

=head2 {subst:string,old,new}

=cut

sub func_subst
{ my ($this, $val) = @_;
  my ($str, $old, $new) = @$val;
  $str =~ s/$old/$new/g;
  $str;
}

=head2 {subt:num1,num2...}

=cut

sub func_subt
{ my ($this, $val) = @_;
  my ($num, $tot);
  $tot = shift @$val;
  foreach $num (@$val)
  { $tot -= $num; }
  $tot;
}

=head2 {time:}

=cut

sub func_time
{ my ($sec, $min, $hour, $mday, $mon, $year) = gmtime(time());
  if ($year < 1000) { $year += 1900; }
  "$hour:$min:$sec";
}

sub func_timestr
{ }

sub func_timesub
{ }

=head2 {tolower:string}

=cut

sub func_tolower
{ my ($this, $val) = @_;
  lc $val->[0];
}

=head2 {toupper:string}

=cut

sub func_toupper
{ my ($this, $val) = @_;
  uc $val->[0];
}

sub func_tzoffset
{ }

=head2 {v:varname}

=cut

sub func_v
{ my ($this, $val) = @_;
  $this->{$val->[0]};
}

=head2 {version:}

=cut

sub func_version
{ $VERSION; }

=head2 {while:condition,command}

=cut

sub chk_cond
{ my ($this, $cond) = @_;
  my ($res) = &parse_parameter($this, $cond);
# debug
#  print "cond $res -- ";
  $res;
}

sub func_while
{ my ($this, $params) = @_;
  my ($go,$cond,$expr,$sep, $val, $res, $result, %save, $maxloop);
  $cond = $params;
  ($expr) = &skip_param($this, $params);
  ($params) = &skip_param($this, $expr);
  $maxloop = 255; #sanity
  while (&chk_cond($this, $cond) && ($maxloop >= 0))
  { ($res, $params) = &parse_parameter($this, $expr); 
    $result .= $res;
    $maxloop --;
  }
  ($result, $params);
}

=head2 {with:varname...}

=cut

sub func_with
{ my ($this, $params) = @_;
  my ($varname,$expr,$val, $res, %save);
  ($varname, $expr) = &parse_parameter($this, $params);
  foreach $val(split /:/, $varname)
  { $save{$val} = $this->{$val};
    $this->{$val} = ''; # a 'null' that isn't undef
  }
  ($res, $params) = &parse_parameter($this, $expr);
  foreach $val(split /:/, $varname)
  { $this->{$val} = $save{$val}; }
  ($res, $params);
}

=head2 {xor:num1,num2...}

=cut

sub func_xor
{ my ($this, $val) = @_;
  my ($num, $tot);
  $tot = shift @$val;
  foreach $num (@$val)
  { $tot = ($tot xor $num); }
  $tot;
}

# ====================================================
# core routines
# ====================================================
=head2 -

=cut 

=head1 Public object methods

=cut

=head2 new(noderef);

Create new MPI object.

=cut

sub new
{ my ($class, $node) = @_;
  my (%this);
  $this{'_node'} = $node;
  bless \%this, $class;
}

=head2 $mpi->setvar(var,val);

Sets a variable in the mpi object to a scalar value.

=cut

sub setvar
{ my ($this, $var, $val) = @_;
  $this->{$var} = $val;
}

=head2 $mpi->readvar(var);

Reads a scalar value from the mpi object

=cut

sub readvar
{ my ($this, $var) = @_;
  $this->{$var};
}

# unpack a list in either MPI \n delimited string or perl list ref
sub unpack_list
{ my ($list, $sep) = @_;
  my (@list);
  if (ref $list)
  { @list = @$list; }
  else
  { $sep = $sep || "\n";
    @list = split "\n", $list;
  }
  @list;
}

sub pack_list
{ if ($perl_list) {return \@_}
  else
  { join "\n", @_; }
}

# parse 1 parameter, which may contain a mix of plain text and MPI functions
sub parse_parameter
{ my ($this, $text) = @_;
  my ($result, $prefix, $remainder, $match, $value);
  $result = "";
  # find start of MPI function or terminating comma
  while ($text =~ /(,|\}|\{\w+:?)/ )
  { $match = $1;
    # terminating comma or '}', split remaining text into result and remainder
    if ($match =~ /(,|\})/)
    { ($prefix, $remainder) = split $match, $text, 2;
      $result .= $prefix;
      return ($result, $remainder, $match);
    }
    # mpi function, evaluate
    elsif ($match =~ /\{(\w+)/ )
    { ($prefix, $remainder) = split $match, $text, 2;
      $result .= $prefix;
      ($value, $remainder) = &eval_mpi($this, $1, $remainder);
#if (! defined($value))
#{ "catch"; }
      $result .= $value;
      $text = $remainder;
    }
  }
  # nothing left to parse
  ($result.$text, '', '');
}

# skip a parameter
sub skip_param
{ my ($this, $text) = @_;
  my ($match, $prefix, $remainder);
  while ($text =~ /(,|\}|\{\w+:?)/ )
  { $match = $1;
    # terminating comma or }, split remaining text into result and remainder
    if ($match =~ /([,\}])/)
    { ($prefix, $remainder) = split $1, $text, 2;
      return ($remainder, $match);
    }
    # mpi function, recurse in and skip
    elsif ($match =~ /\{(\w+)/ )
    { ($prefix, $remainder) = split $match, $text, 2;
      ($remainder) = &skip_parameters($this, $remainder);
      $text = $remainder;
    }
  }
  # nothing left to parse
  ('');
}

# skip all remaining parameters
sub skip_parameters
{ my ($this, $text) = @_;
  my ($match, $prefix, $prefix1, $remainder);
  while ($text =~ /(\}|\{\w+:?)/ )
  { $match = $1;
    # terminating }, split remaining text into result and remainder
    if ($match =~ /([\}])/)
    { ($prefix, $remainder) = split $1, $text, 2;
      $prefix1 .= $prefix;
      return ($remainder, $prefix1, $1);
    }
    # mpi function, recurse in and skip
    elsif ($match =~ /\{(\w+)/ )
    { ($prefix, $remainder) = split $match, $text, 2;
      $prefix1 .= $prefix.$match;
      ($remainder, $prefix, $match) = &skip_parameters($this, $remainder);
      $prefix1 .= $prefix.$match;
      $text = $remainder;
    }
  }
  # nothing left to parse
  ('');
}

# parse all parameters for the current function
sub parse_parameters
{ my ($this, $text) = @_;
  my @params;
  my ($result, $term);
  $term = "zz";
  while ($term =~ /[^\}]/)
  { ($result, $text, $term) = &parse_parameter($this, $text);
    push @params, $result;
  }
  (\@params, $text);
}
 
# evaluate 1 MPI function
sub eval_mpi
{ my ($this, $function, $text) = @_;
  my ($result, $remainder, $params);
  $function = lc $function;
  $result = "";
  # if function is in control function list, pass raw text and let function parse.
  if ($ctrl_functions{$function})
  { ($result, $remainder) = &{$ctrl_functions{$function}}($this, $text);
  }
  # parse parameters and pass results to function.
  elsif ($simp_functions{$function})
  { ($params, $remainder) = &parse_parameters($this, $text);
    ($result) = &{$simp_functions{$function}}($this, $params);
  }
  # else concat parameters
  elsif ($this->{"_f_$function"})
  { my (@vars, $var, $i, %save);
    ($params, $remainder) = &parse_parameters($this, $text);
    @vars = split /:/, $this->{"_f_$function v"};
    for ($i = 0; $i < @vars; $i++)
    { $var = $vars[$i];
      $save{$var} = $this->{$var};
      $this->{$var} = $params->[$i];
    }
    $result = &parse($this, $this->{"_f_$function"});
    foreach $var(split /:/, $this->{"_f_$function v"})
    { $this->{$var} = $save{$var}; }
  }
  else
  { ($params, $remainder) = &parse_parameters($this, $text);
    $result = join (',', @$params);
  }
  ($result, $remainder);
}

=head2 $mpi->parse(string);

Processes a string for MPI codes

=cut

# parse a text block.  simular to parse_parameter, except not terminating at ','
sub parse
{ my ($this, $text) = @_;
  my ($result, $value, $term);
  # while we have unprocessed text
  #   find MPI, if any.
  #   preceeding text copied to result.
  #   MPI evaluated and retuned values added to result.

  $term = "zz"; # meaningless except not null
  while ($term)
  { ($value, $text, $term) = &parse_parameter($this, $text);
    $result .= $value.$term;
  }

  $result;
}

1;

__END__

use Language::MPI;

# dummy test callbacks
package Language::MPI;

sub mpi_neighbors 
{ my ($thisnode, $pattern) = @_;
  "neighbors:$thisnode,$pattern";
}
sub mpi_prop
{ my ($thisnode, $propname) = @_;
  "$thisnode/$propname";
}

sub mpi_props
{ my ($thisnode, $proppat) = @_;
  ("propa", "propb", "propc");
}

sub mpi_propset
{ my ($thisnode, $propname, $val) = @_;
  "$thisnode,$propname,$val";
}

package main;

$mpi = new Language::MPI('dummy node');

@tests =
( 'plain text, no MPI',
  '{toupper:lower to upper}',
  '1+2 = {add:1,2} = 2+1',
  '{tolower:{toupper:lower to upper to lower}}',
  '{for:i,1,4,1,{v:i} }',
  
  '{abs:-2}',
  '{add:1,2,3}',
  '{and:2,4,6}',
  '{attr:attribute...,text}',
  '{mklist:list,items}',
  '{set:list,{mklist:list,items}}',
  '{count:{v:list}',
  '{date:}',
  '{set:var,1}',
  '{v:var}',
  '{dec:var,2}',
  '{inc:var,4}',
  '{default:1,2}',
  '{dice:6,3,2}',
  '{dist:3,4}',
  '{div:81,9,3}',
  '{eq:var1,var1}',
  '{eval:vars...}',
  '{foreach:var,{v:list},:{v:var}:}',
  '{ge:2,2}',
  '{gt:2,1}',
  '{if:true,true statement,false statement}',
  '{insrt:string1,ing}',
  '{lcommon:{v:list},{mklist:items}}',
  '{le:1,2}',
  '{lmember:{v:list},items}',
  '{lit:{a:dummy,mpi}}',
  '{max:1,2,3}',
  '{min:1,2,3}',
  '{mod:9,4}',
  '{mult:2,4,8}',
  '{ne:var1,var2}',
  '::{nl:}::',
  '{not:true}',
  '{null:a big statement to execute but not keep a value from...}',
  '{or:1,2,0}',
  '{secs:}',
  '{sign:-100}',
  '{smatch:string,ing}',
  '{strip:  string   }',
  '{strlen:string}',
  '{subst:string,ing,ung}',
  '{subt:100,50,25}',
  '{time:}',
  '{version:}',
  '{set:var,3}',
  '{while:{v:var},{v:var}>>{dec:var,1}:}',
  '{with:var,{v:var}}',
  '{xor:1,1,1}',
  'The following are dummy without support functions',
  '{delprop:var,obj}',
  '{exec:prop,node}',
  '{index:prop,obj}',
  '{list:props,obj}',
  '{listprops:props,obj}',
  '{neighbors:varname,pattern,{v:varname}}',
  '{prop:property,node}',
  '{store:val,property,node}',
);

foreach $test (@tests)
{ print "test: $test\n";
  $result = $mpi->parse($test);
  print "result: [[$result]]\n\n";
}

#Makefile.pl
use ExtUtils::MakeMaker;

WriteMakefile
( NAME		=> 'Language::MPI',
  VERSION_FROM	=> 'lib/Language/MPI.pm'
);

__END__

MANIFEST
Makefile.pl
README
lib/Language/MPI.pm

__END__

additional notes:

perldoc ExtUtils::MakeMaker::Tutorial



#abs          add         and          attr        convsecs     convtime
#count        date        debug        debugif     dec          default      
#delprop      dice        dist         div         eq           escape       
#eval         exec        filter       fold
#ftime        fullname    ge          gt           
#inc          index       instr        isnum       lcommon      le          
#list         listprops   lmember     lrand        lremove     
#lsort        lt          ltimestr     lunion      lunique      max          
#midstr       min         mklist       mod         mult         name        
#ne           nl          not          null        or           parse        
#prop         rand        secs         select      set          sign  
#smatch       stimestr    store        strip       strlen       sublist  
#subst        subt        time         timestr     timesub      tolower     
#toupper      tzoffset    v            version     xor
