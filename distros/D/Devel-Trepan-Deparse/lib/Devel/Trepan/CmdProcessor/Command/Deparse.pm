# -*- coding: utf-8 -*-
# Copyright (C) 2014-2015, 2018 Rocky Bernstein <rocky@cpan.org>

use rlib '../../../..';


use warnings; no warnings 'redefine';
use B;
use B::DeparseTree;
use B::DeparseTree::Printer; # qw(short_str);
use Data::Printer;

package Devel::Trepan::CmdProcessor::Command::Deparse;


use Scalar::Util qw(looks_like_number);
use English qw( -no_match_vars );
use Getopt::Long qw(GetOptionsFromArray);
Getopt::Long::Configure("pass_through");

use B::DeparseTree::Fragment;
use Devel::Trepan::Deparse;
use Devel::Trepan::DB::LineCache;

use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Deparse source code via B::DeparseTree';
use constant MIN_ARGS   => 0; # Need at least this many
use constant MAX_ARGS   => undef;
use constant NEED_STACK => 0;


use Devel::Trepan::CmdProcessor::Command qw(@CMD_ISA @CMD_VARS set_name);

use strict;

use vars qw(@ISA @EXPORT);
@ISA = qw(Devel::Trepan::CmdProcessor::Command);

use vars @CMD_VARS;  # Value inherited from parent

our $NAME = set_name();
=head2 Synopsis:

=cut
our $HELP = <<'HELP';
=pod

B<deparse> [I<address options>] [0xOP-address | . ]

B<deparse> [I<B::DeparseTree-options>] {I<filename> | I<subroutine>}

In the first form with an OP address, "," or no arguments, deparse
around where the program is currently stopped. If "dump" or "tree" is
given we show lower-level output from L<B::DeparseTree::Print>.  In
the former case, just for the opcode and in the later case for the
deparsed tree.

In the second form with a function or filename, L<B::DeparseTree>
shows information for that file or function.

B::DeparseTree options:

    -t  | --tree        Show full optree
    -l  | --line        Add '# line' comment
          --offsets     show all offsets
    -a  | --address     Add 'OP addresses in '# line' comment
    -p  | --parent <n>  Show parent text to level <n>
    -q  | --quote       Expand double-quoted strings
    -d  | --debug       Show debug information
    -h  | --help        run 'help deparse' (this text)


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
    $Getopt::Long::autoabbrev = 1;
    my $opts = {};
    my $result =
	&GetOptionsFromArray($args,
			     'h|help'      => \$opts->{'help'},
			     't|tree'      => \$opts->{'tree'},
			     'l|line'      => \$opts->{'line'},
			     'offsets'     => \$opts->{'offsets'},
			     'p|parent:i'  => \$opts->{'parent'},
			     'a|address'   => \$opts->{'address'},
			     'q|quote'     => \$opts->{'quote'},
			     'debug'       => \$opts->{'debug'}
        );
    $opts;
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

# FIXME combine with Command::columnize_commands
use Array::Columnize;
sub columnize_addrs($$)
{
    my ($proc, $commands) = @_;
    my $width = $proc->{settings}->{maxwidth};
    my $r = Array::Columnize::columnize($commands,
                                       {displaywidth => $width,
                                        colsep => '    ',
                                        ljust => 1,
                                        lineprefix => '  '});
    chomp $r;
    return $r;
}

# This method runs the command
sub run($$)
{
    my ($self, $args) = @_;
    my @args     = @$args;
    @args = splice(@args, 1, scalar(@args), -2);
    my $options = parse_options($self, \@args);

    my $proc     = $self->{proc};
    if ($options->{'help'}) {
	my $help_cmd = $proc->{commands}{help};
	$help_cmd->run( ['help', 'deparse'] );
	return;
    }

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

    if ($options->{'tree'} || $options->{'offsets'}) {
	my $deparse = B::DeparseTree->new();
	if ($funcname eq "DB::DB") {
	    $funcname = "main::main";
	}
	$deparse->coderef2info(\&$funcname);
	if ($options->{'tree'}) {
	    Data::Printer::p $deparse->{optree};
	} elsif ($options->{'offsets'}) {
	    my @addrs = sort keys %{$deparse->{optree}}, "\n";
	    @addrs = map sprintf("0x%x", $_), @addrs;
	    my $msg = columnize_addrs($proc, \@addrs);
	    $proc->section("Addresses in $funcname");
	    $proc->msg($msg);
	}
	return;
    }

    my $text;
    # FIXME: we assume func below, add parse options like filename, and
    if ($want_runtime_position) {
	# FIXME: ideally the variable $deparse would be internal only
	# to deparse_offset However some branches need $deparse is
	# used for other purposes rather than duplicate this code, it
	# is here once, on the most likely branches it is not used.
	my $deparse = B::DeparseTree->new();

	if ($addr) {
	    my $op_info = deparse_offset($funcname, $addr);
	    if (!$op_info) {
		$proc->errmsg(sprintf("Can't find info for op at 0x%x", $addr));
		return;
	    }
	    if ($want_prev_position) {
		$op_info = get_prev_addr_info($op_info);
	    }
	    if ($op_info) {
		my $parent_count = $options->{parent};
		if (looks_like_number($options->{parent})) {
		    my $maxwidth = $proc->{settings}->{maxwidth};
		    my $sep = ' -' x ($maxwidth / 2 > 20 ? 20 : $maxwidth / 2);
		    for (my $i=0; $i <= $parent_count && $op_info; $i++) {
			$proc->msg($proc->bolden(sprintf("%02d %s:", $i, $op_info->{type})));
			pmsg($proc, $op_info->{text});
			$op_info = get_parent_addr_info($op_info);
			$proc->msg($sep) if $i <= ($parent_count-1) && $op_info;
		    }
		    return;
		}

		my $parent_info = get_parent_addr_info($op_info);
		if ($op_info->{parent}) {
		    if ($options->{debug}) {
			use Data::Printer;
			p $op_info ;
			$proc->msg('- -' x 20);
			p $parent_info;
		    }
		    my $op = $op_info->{op};

		    my $mess = '';
		    if ($addr != $op_info->{addr}) {
			$mess .= "a subchild of ";
		    }

		    $mess .= $op_info->{type};

		    if ($op->can('name')) {
			$mess .= sprintf(', %s ', $op->name);
		    } else {
			$mess .= ', '
		    }
		    if ($proc->{op_addr} and $addr == $proc->{op_addr}) {
			$mess .= sprintf("%s\n\tat address 0x%x:", $op, $proc->{op_addr});
		    }
		    $proc->msg($mess);
		    my $extract_texts = extract_node_info($op_info);
		    if ($extract_texts) {
			pmsg($proc, join("\n", @$extract_texts))
		    } else {
			pmsg($proc, $op_info->{text});
		    }
		} else {
		    pmsg($proc, $op_info->{text});
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
	    my ($op_info) = deparse_offset($funcname, $addr);
	    if ($op_info) {
		if (scalar(@args) == 2 ) {
		    address_options($proc, $op_info, $args[1])
		} else {
		    my $parent_info = deparse_offset($funcname, $op_info->{parent});
		    if ($parent_info) {
			pmsg_info($proc, $options, '', $op_info);
			pmsg_info($proc, $options, ' contained in', $parent_info);
			return;
		    }
		    pmsg_info($proc, $options, 'code to run next', $op_info);
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
	my $deparse_opts='';
	foreach my $opt ('dumper', 'line', 'address') {
	    if ($options->{$opt}) {
		$deparse_opts .= ('-' . substr($deparse_opts, 0, 1))
	    }
	}
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
