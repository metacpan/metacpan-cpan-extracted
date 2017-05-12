# -*- coding: utf-8 -*-
# Copyright (C) 2014-2015 Rocky Bernstein <rocky@cpan.org>

use rlib '../../../..';

use warnings; no warnings 'redefine';
use English qw( -no_match_vars );
use B;
use B::DeparseTree;
use B::DeparseTree::Printer; # qw(short_str);

package Devel::Trepan::CmdProcessor::Command::Deparse;
use English qw( -no_match_vars );
use Devel::Trepan::DB::LineCache;
use Getopt::Long qw(GetOptionsFromArray);

use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Deparse source code via B::DeparseTree';
use constant MIN_ARGS   => 0; # Need at least this many
use constant MAX_ARGS   => undef;
use constant NEED_STACK => 0;


use Devel::Trepan::CmdProcessor::Command qw(@CMD_ISA @CMD_VARS set_name);
use vars qw(@ISA);

use strict;

use vars qw(@ISA); @ISA = @CMD_ISA;
@ISA = qw(Devel::Trepan::CmdProcessor::Command);

use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<deparse> [I<address options>] [0xOP-address | . ]  [dump | tree]
B<deparse> [I<B::DeparseTree-options>] {I<filename> | I<subroutine>}

In the first form with an OP address, "," or no arguments, deparse
around where the program is currently stopped. If "dump" or "tree" is
given we show lower-level output from L<B::DeparseTree::Print>.  In
the former case, just for the opcode and in the later case for the
deparsed tree.

In the second form with a function or filename, L<B::DeparseTree>
shows information for that file or function.

B::DeparseTree options:

    -d  Output data values using Data::Dumper
    -l  Add '# line' comment
    -a  Add 'OP addresses in '# line' comment
    -P  Disable prototype checking
    -q  Expand double-quoted strings

Options



Deparse Perl source code using L<B::DeparseTree>.

Without arguments, deparses the current statement, if we can.

=head2 Examples:

  deparse             # deparse current statement
  deparse -a          # deparse current statement showing
                      # line and OP address
  deparse 0xcafebabe  # decode an opcode address.
  deparse @0xcafebabe # same as above
  deparse file.pm
  deparse -l file.pm

=head2 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>, and
L<B::DeparseTree> for more information on deparse options.

=cut
HELP

# FIXME: Should we include all files?
# Combine with BREAK completion.
sub complete($$)
{
    my ($self, $prefix) = @_;
    my $filename = $self->{proc}->filename;
    # For line numbers we'll use stoppable line number even though one
    # can enter line numbers that don't have breakpoints associated with them
    my @completions = sort DB::subs();
    Devel::Trepan::Complete::complete_token(\@completions, $prefix);
}

sub parse_options($$)
{
    my ($self, $args) = @_;
    my @opts = ();
    my $result =
	&GetOptionsFromArray($args,
			     '-d'  => sub {push(@opts, '-d') },
			     '-l'  => sub {push(@opts, '-l') },
			     '-P'  => sub {push(@opts, '-P') },
			     '-a'  => sub {push(@opts, '-a') },
			     '-q'  => sub {push(@opts, '-q') }
        );
    @opts;
}

# Elide string with ... if it is too long, and
# show control characters in string.
sub short_str($;$) {
    my ($str, $maxwidth) = @_;
    $maxwidth ||= 20;

    if (length($str) > $maxwidth) {
	my $chop = $maxwidth - 3;
	$str = substr($str, 0, $chop) . '...' . substr($str, -$chop);
    }
    $str =~ s/\cK/\\cK/g;
    $str =~ s/\f/\\f/g;
    $str =~ s/\n/\\n/g;
    $str =~ s/\t/\\t/g;
    return $str
}

sub address_options($$$)
{
    my ($proc, $op_info, $what) = @_;
    if ($what eq 'dump') {
	$proc->msg(B::DeparseTree::Printer::format_info($op_info));
    } elsif ($what eq 'tree') {
	$proc->msg(B::DeparseTree::Printer::format_info_walk($op_info, 0));
    }

}

sub get_addr($$)
{
    my ($deparse, $addr) = @_;
    return unless $addr;
    my $op_info = $deparse->{optree}{$addr};
    if ($op_info) {
	# use Data::Printer; Data::Printer::p $op_info;
	# my $text = $deparse->indent_info($op_info);
	return $op_info;
    }
    return undef;
}

sub get_prev_addr($$);

sub get_prev_addr($$) {
    my ($deparse, $op_info) = @_;

    return undef unless $op_info && $op_info->{parent};
    my $parent_addr = $op_info->{parent};
    my $parent_info = $deparse->{optree}{$parent_addr};
    return undef unless $parent_info;
    my @body = @{$parent_info->{body}};
    return undef unless @body;
    my $prev_info = shift @body;
    while (@body) {
	return $prev_info if ($body[0] == $op_info);
	$prev_info = shift @body;
    }
    return undef;
}

# Print Perl text, possibly syntax highlighted.
sub pmsg($$$)
{
    my ($proc, $text,$short) = @_;
    $text = B::DeparseTree::Printer::short_str($text, $proc->{settings}{maxwidth}) if $short;
    $text = Devel::Trepan::DB::LineCache::highlight_string($text)
	if $proc->{settings}{highlight};
    $proc->msg($text, {unlimited => 1});
}

# Print Perl text, possibly syntax highlighted.
# We add leader info which may have op addresses
# if desired
sub pmsg_info($$$$)
{
    my ($proc, $options, $leader, $info) = @_;
    return unless $info;
    my $text = $info->{text};
    if (grep($_ eq '-a', @{$options})) {
	$leader = sprintf "OP: 0x%0x $leader", ${$info->{op}};
    }
    $proc->msg("# ${leader}...") if $leader;
    pmsg($proc, $text, 1);
}

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @args     = @$args;
    @args = splice(@args, 1, scalar(@args), -2);
    my @options = parse_options($self, \@args);
    my $proc     = $self->{proc};
    my $filename = $proc->{list_filename};
    my $frame    = $proc->{frame};
    my $funcname = $proc->{frame}{fn};
    my $addr;
    my $want_runtime_position = 0;
    my $want_prev_position = exists($proc->{frame_index}) && ($proc->{frame_index} != 0);
    if (scalar @args == 0) {
	# Use function if there is one. Otherwise use
	# the current file.
	if ($proc->{stack_size} > 0 && $funcname) {
	    $want_runtime_position = 1;
	    $addr = $proc->{op_addr};
	}
    } elsif (scalar @args <= 2) {
	if ($args[0] =~ /^@?(0x[0-9a-fA-F]+)/) {
	    $want_runtime_position = 1;
	    $addr = hex($1);
	} elsif ($args[0] eq '.') {
	    $want_runtime_position = 1;
	    $addr = $proc->{op_addr};
	} else {
	    $filename = $args[0];
	    my $subname = $filename;
	    $subname = "main::$subname" if index($subname, '::') == -1;
	    my $matches = $self->{dbgr}->subs($subname);
	    if ($matches >= 1) {
		$funcname = $subname;
		$want_runtime_position = 1;
	    } else {
		my $canonic_name = map_file($filename);
		if (is_cached($canonic_name)) {
		    $filename = $canonic_name;
		}
	    }
	}
    } else {
	$proc->errmsg('Expecting and address or one file or function name');
	return;
    }

    my $text;
    # FIXME: we assume func below, add parse options like filename, and
    if ($want_runtime_position) {
	my $deparse = B::DeparseTree->new();
	if ($addr) {
	    if ($funcname eq "DB::DB") {
		$deparse->main2info;
	    } else {
		$deparse->coderef2info(\&$funcname);
	    }
	    my ($op_info) = get_addr($deparse, $addr);
	    if ($op_info) {
		my $parent_info = get_addr($deparse, $op_info->{parent});
		if ($want_prev_position) {
		    my $prev_info = get_prev_addr($deparse, $op_info);
		    pmsg_info($proc, \@options, "called location", $prev_info);
		    pmsg_info($proc, \@options, 'code to be run after function return',
				$op_info);
		    pmsg_info($proc, \@options, 'contained in', $parent_info);
		} else {
		    my $mess =
			($proc->{op_addr} && $addr == $proc->{op_addr}) ?
			'code to be run next' :
			sprintf("code at address 0x%x", $addr);
		    pmsg_info($proc, \@options, $mess, $op_info);
		    pmsg_info($proc, \@options, 'contained in', $parent_info);
		}
		address_options($proc, $op_info, $args[1]) if $args[1];
		return;
	    } else {
		$proc->errmsg(sprintf("Can't find info for op at 0x%x", $addr));
		# use Data::Printer; Data::Printer::p $deparse->{optree};
	    }
	    return;
	} elsif (scalar @args >= 1 and ($args[0]) =~ /^@?(0x[0-9a-fA-F]+)/) {
	    my $addr = hex($1);
	    my $coderef = \&$funcname;
	    my $info = $deparse->coderef2info($coderef);
	    my ($op_info, $mess) = get_addr($deparse, hex($addr));
	    if ($op_info) {
		if (scalar(@args) == 2 ) {
		    address_options($proc, $op_info, $args[1])
		} else {
		    my $parent_info = get_addr($deparse, $op_info->{parent});
		    if ($parent_info) {
			pmsg_info($proc, \@options, '', $op_info);
			pmsg_info($proc, \@options, ' contained in', $parent_info);
			return;
		    }
		    pmsg_info($proc, \@options, 'code to run next', $op_info);
		}
		address_options($proc, $op_info, $args[1]) if $args[1];
	    } else {
		$proc->errmsg(sprintf("Can't find info for op at %s", $addr));
	    }
	} else {
	    my @package_parts = split(/::/, $funcname);
	    my $prefix = '';
	    $prefix = join('::', @package_parts[0..scalar(@package_parts) - 1])
		if @package_parts;
	    my $short_func = $package_parts[-1];
	    $text = "package $prefix;\nsub $short_func" . $deparse->coderef2text(\&$funcname);
	    pmsg($proc, $text, 0);
	    return;
	}
    } else  {
	my $options = join(',', @options);
	if (!-r $filename) {
	    $proc->errmsg("No readable perl script: " . $filename)
	} else {
	    my $cmd="$EXECUTABLE_NAME  -MO=DeparseTree,-sC,$options $filename";
	    $text = `$cmd 2>&1`;
	    if ($? >> 8 == 0) {
		pmsg($proc, $text, 0);
	    } else {
		$proc->errmsg("Error running $cmd");
		$proc->errmsg($text);
	    }
	}
	return;
    }
}

unless (caller) {
    require Devel::Trepan::CmdProcessor;
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $cmd = __PACKAGE__->new($proc);
    require Devel::Trepan::DB::Sub;
    require Devel::Trepan::DB::LineCache;
    # cache_file(__FILE__);
    my $root_cv = B::main_root;
    $proc->{frame} = {
	line => __LINE__ - 1,
	file => __FILE__,
	fn   => 'DB::DB',
	pkg  => __PACKAGE__,
	addr => $$root_cv,
    };
    $proc->{stack_size} = 1,
    $cmd->run([$NAME]);
    print '-' x 30, "\n";
    # $cmd->run([$NAME, '-l']);
    # print '-' x 30, "\n";
    $proc->{frame}{fn} = 'run';
    $proc->{settings}{highlight} = 'dark';
    $cmd->run([$NAME]);
}

1;
