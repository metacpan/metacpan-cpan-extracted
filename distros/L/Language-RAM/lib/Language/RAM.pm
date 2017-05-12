package Language::RAM;

use 5.006;
use strict;
use warnings;

=head1 NAME

Language::RAM - A "Random Access Machine" Emulator

=head1 VERSION

Version 0.012

=cut

our $VERSION = '0.012';


=head1 SYNOPSIS

This module provides a library and an interpreter to emulate a basic
"Random Access Machine". This computer model uses an assembler-like syntax
and can be used to test simple algorithms for their complexity.

You can use C<ram.pl> to run Random Access Machines and get
extensive information on memory usage, memory changes and complexity.
See C<ram.pl --help> for details.

    use Language::RAM;

    my $input = "INPUT 0\nOUTPUT 1\na <-- s[0]\na <-- a * s[0]\ns[1] <-- a\nHALT";

    my %machine = Language::RAM::asl($input);
    die "$machine{'error'}" if ($machine{'error'} ne '');

    my $ret = Language::RAM::run(\%machine, [8]); # Returns 8^2
    if($ret) {
      print STDERR "Error from machine: $machine{'error'}\n";
    }

    my %output = Language::RAM::get_output(\%machine);
    print "OUTPUT FROM MACHINE:\n";
    foreach (sort { $a <=> $b } keys %output) {
      printf "%4d=%d\n", $_, $output{$_} // 0;
    }

=head1 EXPORT

To use Language::RAM, you only need C<asl>, C<run>, C<get_output>, C<get_code_stats>,
C<get_mem_stats>, C<get_line>, C<get_first_memory_snapshot>, C<get_snapshots>
and C<replay_snapshot>.

=head1 GENERAL

=head2 asl(input)

Return random access machine from input string (one command per line).

The returned hash has the following keys/values:

=over 4

=item B<input_layout>=I<list ref>

Range of input slots defined by INPUT command.

=item B<output_layout>=I<list ref>

Range of output slots defined by OUTPUT command.

=item B<error>=I<string>

Empty string. Not empty on errors.

=item B<code>=I<hash ref>

Hash of address => AST-Token.

=item B<memory>=I<hash ref>

Hash of slot name => value.

=item B<ip>=I<current address>

=item B<stats>=I<hash ref>

=over 4

=item B<memory_usage>=I<hash ref>

Hash of slot name => [(reads writes)].

=item B<command_usage>=I<hash ref>

Hash of address => counter.

=back

=item B<snaps>=I<hash ref>

Memory snapshots of each assignment.
Hash of step => [(ip, address, new_value)].

=item B<steps>=I<step counter>

=back

=cut

sub asl {
  my %machine = (
    code => {},
    lines => {},
    error => ''
  );
  my $ip = -1;
  foreach (split /\n/, $_[0]) {
    $_ =~ s/\A\s+|\s+\Z//g;
    next if $_ eq '';
    my ($n_ip, $value) = &ast($_, \%machine, $ip);
    return %machine unless defined $value;
    next if $n_ip == -1;
    $ip = $n_ip;
    $machine{'code'}{$ip} = $value;
  }
  return %machine;
}

=head2 run(machine, input, limit, snapshots)

Run machine until it halts or stepcounter reaches limit.

=over 4

=item B<machine>=I<machine ref>

=item B<input>=I<list ref>

Values will be loaded into memory before execution according to paramters given
by INPUT.

=item B<limit>=I<number>

=item B<snapshots>=I<boolean>

Set to true to generate detailed memory snapshots of each command.

=back

Returns empty string on success, error string on error.

=cut

sub run {
  my $machine = $_[0];
  my $limit = -1;
  $limit = $_[2] if(@_ >= 3);

  $machine->{'input'} = $_[1];
  $machine->{'error'} = '';
  $machine->{'ip'} = 0;
  $machine->{'steps'} = 0;
  $machine->{'memory'} = {};
  $machine->{'snaps'} = {} if $_[3];

  foreach my $index ( 0 .. $#{$$machine{'input_layout'}}) {
    my $id = $$machine{'input_layout'}->[$index];
    my $input = $machine->{'input'}[$index];
    (defined $input) or $input = 0;
    $machine->{'memory'}{$id} = $input;
  }

  while($limit == -1 || $machine->{'steps'} < $limit) {
    my $current = $machine->{'code'}{$machine->{'ip'}};

    unless($current) {
      return $machine->{'error'} = "Reached nocode at $machine->{'ip'}";
    }

    unless(exists $machine->{'stats'}{'command_usage'}{$machine->{'ip'}}) {
      $machine->{'stats'}{'command_usage'}{$machine->{'ip'}} = 0;
    }
    ++$machine->{'stats'}{'command_usage'}{$machine->{'ip'}};

    $machine->{'snaps'}{$machine->{'steps'}} = [($machine->{'ip'})] if $_[3];

    &eval($current, $machine, 0, $_[3]) or return $machine->{'error'};

    ++$machine->{'ip'};
    ++$machine->{'steps'};
  }

  if($limit > 0 && $machine->{'steps'} == $limit) {
    return $machine->{'error'} = "Readed op limit at $machine->{'ip'}(aborted after $limit ops)";
  }
  return '';
}

=head2 get_output(machine)

Return output from machine.

=over 4

=item B<machine>=I<machine ref>

=back

Returns a hash of slot => value.

=cut

sub get_output {
  my %ret;
  foreach (@{$_[0]->{'output_layout'}}) {
    $ret{$_} = $_[0]->{'memory'}{$_};
  }
  return %ret;
}

=head2 get_code_stats(machine)

Return code statistics from machine.

=over 4

=item B<machine>=I<machine ref>

=back

Returns a hash of address => counter.

=cut

sub get_code_stats {
  return %{$_[0]->{'stats'}{'command_usage'}};
}

=head2 get_mem_stats(machine)

Return memory statistics from machine.

=over 4

=item B<machine>=I<machine ref>

=back

Returns a hash of slot => counter.

=cut

sub get_mem_stats {
  return %{$_[0]->{'stats'}{'memory_usage'}};
}

=head2 get_line(machine, id)

Return line at id.

=over 4

=item B<machine>=I<machine ref>

=item B<id>=I<number>

=back

Returns line as string.

=cut

sub get_line {
  return $_[0]->{'lines'}{$_[1]};
}

=head2 get_first_memory_snapshot(machine)

Returns a memory snapshot (a hash) of index => value of the memory at step -1
(before the machine starts).

=over 4

=item B<machine>=I<machine ref>

=back

=cut

sub get_first_memory_snapshot {
  my %snapshot = ();
  my $machine = $_[0];
  my $snapshots = &get_snapshots($machine);

  foreach (keys %$snapshots) {
    next unless exists $$snapshots{$_}->[1];
    $snapshot{$$snapshots{$_}->[1]} = 0;
  }

  foreach my $index ( 0 .. $#{$$machine{'input_layout'}}) {
    my $id = $$machine{'input_layout'}->[$index];
    my $input = $$machine{'input'}->[$index];
    (defined $input) or $input = 0;
    $snapshot{$id} = $input;
  }

  return %snapshot;
}

=head2 get_snapshots(machine)

Returns a hash ref of step => [(ip, addr, value)].

=over 4

=item B<machine>=I<machine ref>

=back

=cut

sub get_snapshots {
  return $_[0]->{'snaps'};
}

=head2 replay_snapshot(machine, memory, from, to)

Replay steps from to to of machine in memory.

=over 4

=item B<machine>=I<machine ref>

=item B<memory>=I<ref to memory snapshot>

=item B<from>=I<step number to start at>

=item B<to>=I<step number to stop at>

=back

=cut

sub replay_snapshot {
  foreach ($_[2]..$_[3]) {
    my $step = $_[0]->{'snaps'}{$_};
    next unless exists $$step[1];
    $_[1]->{$$step[1]} = $$step[2];
  }
}

=head1 ABSTRACT SYNTAX TREE

=head2 ast(line, machine, ip)

Return AST of line.

=over 4

=item B<line>=I<string>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns (ip, ast).

=over 4

=item B<ip>=<address>

Address of line (either generated or read from line, see README).

-1 if line is INPUT/OUTPUT statement.

=item B<ast>=<ast reference>

undef on error.

=back

=cut

sub ast {
  my $l = $_[0];
  $l =~ s(//.+\Z)();
  $l =~ s/\A\s+|\s+\Z//g;

  my $ip = $_[2] + 1;
  if($l =~ /\A(\d+):\s*(.+)/) {
    $ip = $1;
    $l = $2;
  }

  while(exists $_[1]->{'code'}{$ip}) {
    ++$ip;
  }

  if($l =~ /\A(INPUT|OUTPUT)(.*)\Z/) {
    if($2 eq '') {
      $_[1]->{'error'} = "$ip> $1 expects an argument";
      return (-1, undef);
    }
    my $ret = &ast_eval_io($2, $_[1]);
    if($1 eq 'INPUT') {
      $_[1]->{'input_layout'} = $ret;
    } else {
      $_[1]->{'output_layout'} = $ret;
    }
    return (-1, $ret);
  }

  $_[1]->{'lines'}{$ip} = $l;

  return ($ip, &get_ast($l, $_[1], $ip));
}

=head2 ast_eval_io(line, machine)

Return INPUT/OUTPUT layout.

=over 4

=item B<line>=I<string>

=item B<machine>=I<machine ref>

=back

Returns a reference to a list of indices or undef on error.

=cut

sub ast_eval_io {
  if(index($_[0], ' ') != -1) {
    my @parms = split /\s+/, $_[0];
    my $ret = [()];

    foreach (@parms) {
      next if $_ eq '';
      my $r = &ast_eval_io($_, $_[1]);
      return undef unless $r;
      push @{$ret}, @{$r};
    }

    if(@{$ret} == 0) {
      $_[1]->{'error'} = 'Command expects argument';
    }
    return $ret;
  } else {
    if($_[0] =~ /\A(\d+)..(\d+)\Z/) {
      my @ret = ();
      for(my $i = $1; $i <= $2; $i++) {push @ret, $i;}
      return \@ret;
    } elsif($_[0] =~ /\A(\d+)\Z/) {
      return [$1];
    } else {
      $_[1]->{'error'} = "Argument not numeric: $_[0]";
      return undef;
    }
  }
}

=head2 get_ast(input, machine, ip)

Return AST-Token from line.

=over 4

=item B<input>=I<string>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Return AST-Token or undef.

=cut

sub get_ast {
  if($_[0] =~ /\A(\-?\d+(?:\.\d+)?)\Z/) {
    &ast_imm($1);
  } elsif ($_[0] =~ /\A(a|i|i1|i2|i3)\Z/) {
    &ast_reg($1 eq 'i' ? 'i1' : $1);
  } elsif ($_[0] =~ /\As\[\s*(.+?)\s*\]\Z/) {
    &ast_mem($1, $_[1], $_[2]);
  } elsif ($_[0] =~ /\Ajump\s+(.+)\s*\Z/) {
    &ast_jump($1, $_[1], $_[2]);
  } elsif ($_[0] =~ /\A(.+?)\s*<--?\s*(.+?)\s*\Z/) {
    &ast_assign($1, $2, $_[1], $_[2]);
  } elsif ($_[0] =~ /\A(.+?)\s*(<|<=|!?=|>=|>)\s*0\Z/) {
    &ast_cond($1, $2, $_[1], $_[2]);
  } elsif ($_[0] =~ /\Aif\s+(.+?)\s+then\s+(.+)\Z/) {
    &ast_cond_jump($1, $2, $_[1], $_[2]);
  } elsif ($_[0] =~ /\A(.+?)\s*(\+|\-|\*|div|mod)\s*(.+)\Z/) {
    &ast_algo($1, $2, $3, $_[1], $_[2]);
  } elsif ($_[0] eq 'HALT') {
    return [('halt')];
  } else {
    $_[1]->{'error'} = "Unknown input: $_[0]";
    return undef;
  }
}

=head2 ast_imm(value)

Returns AST-Token for immutable values.

=over 4

=item B<value>=I<number>

=back

Returns C<[('imm', value)]>.

=cut

sub ast_imm {
  return [('imm', $_[0])];
}

=head2 ast_reg(register)

Returns AST-Token for a register (a, i1..i3).

=over 4

=item B<register>=I<register>

=back

Returns C<[('reg', register)]>.

=cut

sub ast_reg {
  return [('reg', $_[0])];
}

=head2 ast_algo(left, op, right, machine, ip)

Returns AST-Token for an arithmetic expression.

=over 4

=item B<left>=I<left side of expression>

=item B<op>=I<operation>

=item B<right>=I<right side of expression>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('algo', type, left, op, right)]> or undef on error.

=over 4

=item B<type>=I<boolean>

True if left side of expression is register a, otherwise false.

=item B<left>=I<ast-token>

=item B<op>=I<string>

=item B<right>=I<ast-token>

=back

=cut

my %algo_right = qw(imm 0 mem 0 mmem 0);
sub ast_algo {
  (my $left = &get_ast($_[0], $_[3], $_[4])) or return undef;
  (my $right = &get_ast($_[2], $_[3], $_[4])) or return undef;

  $left->[0] eq 'reg'
    or return &report($_[3], "$_[4]> Expected reg, got: $left->[0]($_[0])");

  (exists $algo_right{$right->[0]})
    or return &report($_[3], "$_[4]> Expected imm, mem or mmem, got: $right->[0]($_[2])");

  my $type = $left->[1] eq 'a';
  ($type || ($right->[0] eq 'imm' && ($_[1] eq '+' || $_[1] eq '-')))
    or return &report($_[3], "$_[4]> Index register only allows addition or subtraction with imm ($_[0]$_[1]$_[2])");

  return [('algo', $type, $left, $_[1], $right)];
}

=head2 ast_mem(inner, machine, ip)

Returns AST-Token for memory slot.

=over 4

=item B<inner>=I<string>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('mem', imm)]>, C<[('mmem', ast)]> or undef on error.

=cut

sub ast_mem {
  (my $inner = &get_ast(@_)) or return undef;

  ($inner->[0] eq 'imm') and return [('mem', $inner->[1])];

  if($inner->[0] eq 'algo') {
    ($inner->[1] == 0)
      or return &report($_[1], "$_[2]> Cannot use register a in mmem ($_[0])");

    return [('mmem', $inner)];
  } elsif ($inner->[0] eq 'reg' && $inner->[1] ne 'a') {
    return [('mmem', $inner)];
  } else {return &report($_[1], "$_[2]> Expected imm, algo or index register, got: $inner->[0]($_[0])");}
}

=head2 ast_cond(cond, op, machine, ip)

Returns AST-Token for conditional.

=over 4

=item B<cond>=I<string>

=item B<op>=I<string>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('cond', reg, op)]> or undef on error.

=over 4

=item B<reg>=I<ast-token>

=item B<op>=I<string>

=back

=cut

sub ast_cond {
  (my $reg = &get_ast($_[0], $_[2], $_[3])) or return undef;

  ($reg->[0] eq 'reg')
    or return &report($_[2], "$_[3]> Expected reg, got: $reg->[0]($_[0])");

  return [('cond', $reg, $_[1])];
}

=head2 ast_jump(imm, machine, ip)

Returns AST-Token for jump instruction.

=over 4

=item B<imm>=I<number>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('jump', imm)]> or undef on error.

=cut

sub ast_jump {
  (my $dest = &get_ast(@_)) or return undef;

  ($dest->[0] eq 'imm')
    or return &report($_[1], "$_[2]> Expected imm, got: $dest->[0]($_[0])");

  return [('jump', $dest)];
}

=head2 ast_cond_jump(cond, jump, machine, ip)

Returns AST-Token for if cond then jump k.

=over 4

=item B<cond>=I<string>

=item B<jump>=I<string>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('if', cond, jump)]> or undef on error.

=over 4

=item B<cond>=I<ast-token>

=item B<jump>=I<ast-token>

=back

=cut

sub ast_cond_jump {
  (my $cond = &get_ast($_[0], $_[2], $_[3])) or return undef;

  ($cond->[0] eq 'cond')
    or return &report($_[2], "$_[3]> Expected cond, got: $cond->[0]($_[0])");

  (my $jump = &get_ast($_[1], $_[2], $_[3])) or return undef;
  ($jump->[0] eq 'jump')
    or return &report($_[2], "$_[3]> Expected jump, got: $jump->[0]($_[1])");

  return [('if', $cond, $jump)];
}

=head2 ast_assign(left, right, machine, ip)

Returns AST-Token for assignment.

=over 4

=item B<left>=I<left side of expression>

=item B<right>=I<right side of expression>

=item B<machine>=I<machine ref>

=item B<ip>=I<current address>

=back

Returns C<[('assign', left, right)]> or undef on error.

=over 4

=item B<left>=I<ast-token>

=item B<right>=I<ast-token>

=back

=cut

my %assign_right = qw(imm 0 mem 0 reg 0);
my %assign_a_right = qw(mmem 0 algo 0);
sub ast_assign {
  (my $left = &get_ast($_[0], $_[2], $_[3])) or return undef;
  (my $right = &get_ast($_[1], $_[2], $_[3])) or return undef;

  if($left->[0] eq 'reg') {
    my $rcheck = exists $assign_right{$right->[0]};

    if($left->[1] eq 'a') {
      ($rcheck || (exists $assign_a_right{$right->[0]}))
        or return &report($_[2], "$_[3]> Expected imm, reg, mem, mmem or algo, got: $right->[0]($_[1])");
    } else {
      ($rcheck || $right->[0] eq 'algo')
        or return &report($_[2], "$_[3]> Expected imm, reg, mem or algo, got: $right->[0]($_[1])");

      (!$right->[1] || $right->[0] ne 'algo') or return &report($_[2], "$_[3]> register a not allowed in i(1|2|3) assignment ($_[1])");
    }
  } elsif ($left->[0] eq 'mem') {
    ($right->[0] eq 'reg')
      or return &report($_[2], "$_[3]> Expected reg, got: $right->[0]($_[1])");
  } elsif ($left->[0] eq 'mmem') {
    ($right->[0] eq 'reg' && $right->[1] eq 'a')
      or return &report($_[2], "$_[3]> Expected register a, got: $right->[0]($_[1])");
  } else {return &report($_[2], "$_[3]> Expected reg, mem or mmem, got: $left->[0]($_[0])");}
  return [('assign', $left, $right)];
}

=head1 EVALUATION

=head2 eval(ast, machine)

Evaluate ast.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef on error.

=cut

my %eval_funcs = (
  imm => \&eval_imm,
  reg => \&eval_mem,
  mem => \&eval_mem,
  mmem => \&eval_mmem,
  algo => \&eval_algo,
  cond => \&eval_cond,
  if => \&eval_if,
  jump => \&eval_jump,
  assign => \&eval_assign
);

sub eval {
  if ($_[0]->[0] eq 'halt') {
    return undef;
  }
  if (exists $eval_funcs{$_[0]->[0]}) {
    return $eval_funcs{$_[0]->[0]}->(@_);
  } else {
    $_[1]->{'error'} = "AST Element $_[0][0] not supported";
    return undef;
  }
}

=head2 eval_imm(ast)

    my $ast = [qw(imm 2)];

Returns immutable value of ast.

=over 4

=item B<ast>=I<ast reference>

=back

=cut

sub eval_imm {
  $_[0]->[1];
}

=head2 eval_mem(ast, machine, type)

    my $ast = [qw(mem 2)];

Returns value of/reference to/address of memory block.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=item B<type>=I<number>

Returns value of memory block if B<type> is 0.

Returns reference to memory block if B<type> is 1.

Returns address of memory block if B<type> is 2.

=back

=cut

sub eval_mem {
  my $type = $_[2];
  (defined $type) or $type = 0;
  unless(exists $_[1]->{'memory'}{$_[0]->[1]}) {
    $_[1]->{'memory'}{$_[0]->[1]} = 0;
  }

  &inc_mem_stat($_[1], $_[0]->[1], $type);

  return $_[1]->{'memory'}{$_[0]->[1]} unless $type > 0;
  return \$_[1]->{'memory'}{$_[0]->[1]} if $type == 1;
  return $_[0]->[1];
}

=head2 eval_mmem(ast, machine, type)

    my $ast = [('mmem', "algo here, see eval_algo")];

Same as C<eval_mem>, but evaluate inner expression.

Returns undef if inner expression could not be evaluated.

=cut

sub eval_mmem {
  return undef unless (defined(my $val = &eval($_[0]->[1], $_[1])));
  return &eval_mem([('mem', $val)], $_[1], $_[2]);
}

=head2 eval_algo(ast, machine)

    my $ast = [('algo', 1, [qw(reg a)], '+', [qw(mem 2)])];

Return result of arithmetic expression.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef if left side, right side or operation failed to evaluate.

=cut

sub eval_algo {
  return undef unless (defined(my $left = &eval($_[0]->[2], $_[1])));
  return undef unless (defined(my $right = &eval($_[0]->[4], $_[1])));

  if($_[0]->[3] eq '+') {
    return $left + $right;
  } elsif($_[0]->[3] eq '-') {
    return $left - $right;
  } elsif($_[0]->[3] eq '*') {
    return $left * $right;
  } elsif($_[0]->[3] eq 'div') {
    return int($left / $right);
  } elsif($_[0]->[3] eq 'mod') {
    return $left % $right;
  } else {
    $_[1]->{'error'} = "Operator not supported: $_[0][3]";
    return undef;
  }
}

=head2 eval_cond(ast, machine)

    my $ast = [('cond', [qw(reg a)], '<=')];

Return result of conditional (always compares against 0).

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef if left side or operation failed to evaluate.

=cut

sub eval_cond {
  return undef unless (defined(my $val = &eval($_[0]->[1], $_[1])));

  if($_[0]->[2] eq '<') {
    return $val < 0;
  } elsif($_[0]->[2] eq '<=') {
    return $val <= 0;
  } elsif($_[0]->[2] eq '=') {
    return $val == 0;
  } elsif($_[0]->[2] eq '!=') {
    return $val != 0;
  } elsif($_[0]->[2] eq '>=') {
    return $val >= 0;
  } elsif($_[0]->[2] eq '>') {
    return $val > 0;
  } else {
    $_[1]->{'error'} = "Operator not supported: $_[0][2]";
    return undef;
  }
}

=head2 eval_if(ast, machine)

    my $ast = [('if', "cond here, see eval_cond", "jump here, see eval_jump")];

Jump if conditional evaluates to true.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef if conditional returned an error.

=cut

sub eval_if {
  return undef unless (defined(my $cond = &eval($_[0]->[1], $_[1])));
  &eval_jump($_[0]->[2], $_[1]) if $cond;
  return 1;
}

=head2 eval_jump(ast, machine)

    my $ast = [('jump', [qw(imm 2)])];

Jump to address.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef if address could not be evaluated.

=cut

sub eval_jump {
  return undef unless (defined(my $val = &eval($_[0]->[1], $_[1])));
  $_[1]->{'ip'} = $val - 1;
  return 1;
}

=head2 eval_assign(ast, machine)

    my $ast = [('assign', "left side", "right side")];

Evaluate assignment.

=over 4

=item B<ast>=I<ast reference>

=item B<machine>=I<machine reference>

=back

Returns undef if left or right side could not be evaluated.

=cut

sub eval_assign {
  return undef unless (my $left = &eval($_[0]->[1], $_[1], 1));
  return undef unless (defined(my $right = &eval($_[0]->[2], $_[1])));
  $$left = $right;
  &add_snapshot($_[1], &eval($_[0]->[1], $_[1], 2), $right) if $_[1]->{'snaps'};
  return 1;
}

=head1 STATISTICS

=head2 inc_mem_stat(machine, mem, action)

Increases access counter of one memory slot. These stats can later be retrieved
with C<get_mem_stats>.

=over 4

=item B<machine>=I<machine ref>

=item B<mem>=I<memory address>

=item B<action>=I<boolean>

Add write action to memory slot if B<action> is true.

Add read action to memory slot if B<action> is false.

=back

=cut

sub inc_mem_stat {
  return if $_[2] == 2; #Bail if used in stat collection.

  unless(exists $_[0]->{'stats'}{'memory_usage'}{$_[1]}) {
    $_[0]->{'stats'}{'memory_usage'}{$_[1]} = [qw(0 0)];
  }

  ++$_[0]->{'stats'}{'memory_usage'}{$_[1]}[$_[2] ? 1 : 0];
}

=head2 add_snapshot(machine, addr, value)

Add replayable snapshot where memory slot addr changes to value.

=over 4

=item B<machine>=I<machine ref>

=item B<addr>=I<number>

=item B<value>=I<number>

=back

=cut

sub add_snapshot {
  push @{$_[0]->{'snaps'}{$_[0]->{'steps'}}}, ($_[1], $_[2]);
}

=head2 report(machine, message)

Set error string of machine to message.

=over 4

=item B<machine>=I<machine ref>

=item B<message>=I<string>

=back

Returns undef.

=cut

sub report {
  $_[0]->{'error'} = $_[1];
  return undef;
}

=head1 AUTHOR

Fabian Stiewitz, C<< <deprint at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-language-ram at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Language-RAM>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Language::RAM


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Language-RAM>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Language-RAM>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Language-RAM>

=item * Search CPAN

L<http://search.cpan.org/dist/Language-RAM/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Fabian Stiewitz.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Language::RAM
