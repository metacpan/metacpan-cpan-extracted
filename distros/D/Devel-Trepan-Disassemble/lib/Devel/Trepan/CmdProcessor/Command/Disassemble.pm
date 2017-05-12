# -*- coding: utf-8 -*-
# Copyright (C) 2011-2012, 2015 Rocky Bernstein <rocky@cpan.org>
use warnings; no warnings 'redefine';

use rlib '../../../..';

# Our local modules

package Devel::Trepan::CmdProcessor::Command::Disassemble;

## FIXME:: Make conditional
use Syntax::Highlight::Perl::Improved ':FULL';
use Devel::Trepan::DB::Colors;
use Devel::Trepan::DB::LineCache;

my $perl_formatter = Devel::Trepan::DB::Colors::setup();

use Getopt::Long qw(GetOptionsFromArray);
use B::Concise qw(set_style);

use if !@ISA, Devel::Trepan::CmdProcessor::Command ;

use constant ALIASES    => qw(disasm);
use constant CATEGORY   => 'data';
use constant SHORT_HELP => 'Disassemble subroutine(s)';
use constant MIN_ARGS  => 0;  # Need at least this many
use constant MAX_ARGS  => undef;  # Need at most this many - undef -> unlimited.
use constant NEED_STACK => 0;

# OPf_ flags from Perl's op.h
# Note weird bit combiniation 3, 'want list', we have to handle separately

sub interpret_flags($)
{
    my $op_flags = shift;
    my @OP_FLAGS = (
	'want void',
	'want scalar',
	'want kids',
	'parenthesized',
	'reference',
	'modify lvalue',
	'arg stacked',
	'special',
	);
    my @flags_str = ();
    if ( ($op_flags & 0b11) == 0b11 ) {
	push @flags_str, 'want list';
	$op_flags ^= 0b11;
    }
    while ($op_flags) {
	my $flag_str = shift @OP_FLAGS;
	unshift(@flags_str, $flag_str) if $op_flags & 1;
	$op_flags /= 2;
    }
    return @flags_str ? (': ' . join(', ', @flags_str)) : '';
}

use strict;

use vars qw(@ISA $DEFAULT_OPTIONS);
@ISA = qw(Devel::Trepan::CmdProcessor::Command);

use vars @CMD_VARS;  # Value inherited from parent

$DEFAULT_OPTIONS = {
    line_style => 'terse',
    order      => '-basic',
    tree_style => '-ascii',
};

our $NAME = set_name();
=head2 Synopsis

=cut
our $HELP = <<'HELP';
=pod

B<disassemble> [I<options>] [I<subroutine>|I<package-name> ...]

I<options>:

    [-]-no-highlight
    [-]-highight={plain|dark|light}
    [-]-concise
    [-]-basic
    [-]-terse
    [-]-linenoise
    [-]-debug
    [-]-compact
    [-]-exec
    [-]-tree
    [-]-loose
    [-]-vt
    [-]-ascii
    [-]-from <line-number>
    [-]-to <line-number>

Disassembles the Perl interpreter OP tree using L<B::Concise>.

Flags C<-from> and C<-to> respectively exclude lines less than or
greater that the supplied line number.  If no C<-to> value is given
and a subroutine or package is not given then the C<-to> value is
taken from the "listsize" value as a count, and the C<-from> value is
the current line.

Use L<C<set max list>|Devel::Trepan::CmdProcessor::Set::Max::List> or
L<C<show max list>|Devel::Trepan::CmdProcessor::Show::Max::List> to
see or set the number of lines to list.

C<-no-highlight> will turn off syntax highlighting. C<-highlight=dark> sets for a dark
background, C<light> for a light background and C<plain> is the same as C<-no-highlight>.


Other flags are are the corresponding I<B::Concise> flags and that
should be consulted for their meaning.

=head2 Examples:

 disassemble       # disassemble the curren tline for listsize lines
 dissasm           # default alias; same as above
 disasm -from 15 -to 19  # disassmble lines 15-19
 disasm main::fib  # disassemble the main::fib() subroutine
 disasm fib.pl     # disassemble file fib.pl
 disassm -debug -exec  # block style, rather than tree, like B::Debug


=head2 See also:

L<C<list>|Devel::Trepan::CmdProcessor::Command::List>, and
L<C<deparse>|Devel::Trepan::CmdProcessor::Command::Deparse>, L<C<set
highlight>|Devel::Trepan::CmdProcessor::Set::Highlight>, L<C<set max
list>|Devel::Trepan::CmdProcessor::Set::Max::List>, and L<C<show max
list>|Devel::Trepan::CmdProcessor::Show::Max::List>.

=cut
HELP

sub complete($$)
{
    no warnings 'once';
    my ($self, $prefix) = @_;
    my @subs = keys %DB::sub;
    my @opts = (qw(-concise -terse -linenoise -debug -basic -exec -tree
                   -compact -loose -vt -ascii -from -to),
		@subs);
    Devel::Trepan::Complete::complete_token(\@opts, $prefix) ;
}

sub parse_options($$)
{
    my ($self, $args) = @_;
    my $opts = $DEFAULT_OPTIONS;
    my $result = &GetOptionsFromArray(
	$args,
	'-concise'    => sub { $opts->{line_style} = 'concise'},
	'-terse'      => sub { $opts->{line_style} = 'terse'},
	'-linenoise'  => sub { $opts->{line_style} = 'linenoise'},
	'-debug'      => sub { $opts->{line_style} = 'debug'},
	# FIXME: would need to check that ENV vars B_CONCISE_FORMAT, B_CONCISE_TREE_FORMAT
	# and B_CONCISE_GOTO_FORMAT are set
	# '-env'        => sub { $opts->{line_style} = 'env'},

	'-basic'      => sub { $opts->{order} = '-basic'; },
	'-exec'       => sub { $opts->{order} = '-exec'; },
	'-tree'       => sub { $opts->{order} = '-tree'; },

	'-compact'      => sub { $opts->{tree_style} = '-compact'; },
	'-loose'        => sub { $opts->{tree_style} = '-loose'; },
	'-vt'           => sub { $opts->{tree_style} = '-vt'; },
	'-ascii'        => sub { $opts->{tree_style} = '-ascii'; },
	'-highlight=s'  => \$opts->{highlight},
	'-no-highlight' => sub { $opts->{highlight} = 0; },
	'from=i'        => \$opts->{from},
	'to=i'          => \$opts->{to},
	#'addr=s'        => \$opts->{addr},
	);
    $opts->{highlight} = 0 if defined($opts->{highlight}) && $opts->{highlight} eq 'plain';
    $opts;
}

sub highlight_string($)
{
    my ($string) = shift;
    $perl_formatter->reset();
    $string = $perl_formatter->format_string($string);
    chomp $string;
    $string;
  }

sub markup_basic($$$$$)
{
    my ($lines, $highlight, $proc, $from, $to) = @_;
    my @lines = split /\n/, $lines;
    my $current_line = 0;
    my @newlines = ();
    # use Enbugger 'trepan'; Enbugger->stop;
    my $check_hex_str;
    if ($proc->{frame}{addr}) {
	$check_hex_str = sprintf "0x%x", $proc->{frame}{addr};
    }
    my $filename = $proc->{frame}{file};
    foreach (@lines) {
	my $marker = '    ';
	if (/^#(\s+)(\d+):(\s+)(.+)$/) {
	    my ($space1, $lineno, $space2, $perl_code) = ($1, $2, $3, $4);
	    $current_line = $lineno;
	    my $marked = $perl_code;
	    if ($perl_code eq '-src not supported for -e' ||
		$perl_code eq '-src unavailable under -e') {
		my $opts = {
		    output => $highlight,
		    max_continue => 5,
		};
		$marked = getline($filename, $lineno, $opts);
		$_ = "#${space1}${lineno}:${space2}$marked" if $marked;
	    } else {
		# print "FOUND line $lineno\n";
		if ($highlight) {
		    $marked = highlight_string($perl_code);
		    $_ = "#${space1}${lineno}:${space2}$marked";
		}
	    }
	    ## FIXME: move into DB::Breakpoint and adjust List.pm
	    if (exists($DB::dbline{$lineno}) and
		my $brkpts = $DB::dbline{$lineno}) {
		my $found = 0;
		for my $bp (@{$brkpts}) {
		    if (defined($bp)) {
			$marker = sprintf('%s%02d ', $bp->icon_char, $bp->id);
			$found = 1;
			last;
		    }
		}
	    }
	    ## FIXME move above code

	} elsif (/^(\s+op_flags\s+)(\d+)$/) {
	    # Interpret flag string
	    my $flag = $2;
	    my $bin_flag_str = sprintf '%07b', $flag;
	    $bin_flag_str = $perl_formatter->format_token($bin_flag_str, 'Number') if
		$highlight;
	    $_ = sprintf "%s%s%s", $1, $bin_flag_str, interpret_flags($flag);
	} elsif (/^([A-Z]+) \((0x[0-9a-f]+)\)/) {
	    my ($op, $hex_str) = ($1, $2);
	    # print "FOUND $op, $hex_str\n";
	    if ($check_hex_str && $check_hex_str eq $hex_str) {
		$marker = '=>  ';
		$marker = $proc->bolden($marker) if $highlight;
	    }
	    if ($highlight) {
		$op = $perl_formatter->format_token($op, 'Subroutine');
		$hex_str = $perl_formatter->format_token($hex_str, 'Label');
		$_ = "$op ($hex_str)";
	    }

	}
	$_ = $marker . $_;
	next if $current_line < $from or $current_line > $to;
	push @newlines, $_;
    }
    return join("\n", @newlines);
}

sub markup_tree($$$$$)
{
    my ($lines, $highlight, $proc, $from, $to) = @_;
    my @lines = split /\n/, $lines;
    my $current_line = 0;
    my @newlines = ();
    # use Enbugger 'trepan'; Enbugger->stop;
    my $addr = $proc->{frame}{addr};
    my $filename = $proc->{frame}{file};
    my $check_hex_str;
    if ($proc->{frame}{addr}) {
	$check_hex_str = sprintf "0x%x", $proc->{frame}{addr};
    }
    foreach (@lines) {
	my $marker = '    ';
	if (/^(.*)\|-#(\s+)(\d+):(.+)$/) {
	    my ($prefix, $space, $lineno, $perl_code) = ($1, $2, $3, $4);
	    my $marked = $perl_code;
	    # FIXME: DRY code with markup_basic
	    if ($perl_code =~
		/-src (?:(?:not supported for)|(?:unavailable under)) -e/) {
		my $opts = {
		    output => $highlight,
		    max_continue => 5,
		};
		my $filename = $proc->{frame}{file};
		$marked = DB::LineCache::getline($filename, $lineno, $opts);
		$_ = "${prefix}|-#${space}${lineno}: $marked";
	    } else {
		# print "FOUND line $lineno\n";
		if ($highlight) {
		    $marked = highlight_string($perl_code);
		    $_ = "${prefix}|-#${space}${lineno}: $marked";
		}
	    }
	    ## END above FIXME
	    ## FIXME: move into DB::Breakpoint and adjust List.pm
	    if (exists($DB::dbline{$lineno}) and
		my $brkpts = $DB::dbline{$lineno}) {
		my $found = 0;
		for my $bp (@{$brkpts}) {
		    if (defined($bp)) {
			$marker = sprintf('%s%02d ', $bp->icon_char, $bp->id);
			$found = 1;
			last;
		    }
		}
	    }
	    ## FIXME move above code
	} elsif (/^((?:[ |`])*-?)(0x[0-9a-f]+)(.*)$/) {
    	    my ($space, $hex_str, $rest) = ($1, $2, $3);
	    if ($check_hex_str && /$check_hex_str/) {
		$marker = '=>  ';
		$marker = $proc->bolden($marker) if $highlight;
	    }
	    if ($highlight) {
		$hex_str = $perl_formatter->format_token($hex_str, 'Label');
		$_ = "${space}${hex_str}${rest}";
	    }
	}
	$_ = $marker . $_;
	next if $current_line < $from or $current_line > $to;
	push @newlines, $_;
    }
    return join("\n", @newlines);
}

sub markup_tree_terse($$$$$)
{
    my ($lines, $highlight, $proc, $from, $to) = @_;
    my @lines = split /\n/, $lines;
    my $current_line = 0;
    my @newlines = ();
    # use Enbugger; Enbugger->stop;
    my $addr = $proc->{frame}{addr};
    my $check_hex_str;
    if ($proc->{frame}{addr}) {
	$check_hex_str = sprintf "0x%x", $proc->{frame}{addr};
    }
    my $filename = $proc->{frame}{file};
    foreach (@lines) {
    	my $marker = '    ';
    	if (/^(\s*)# (\d+):(.+)$/) {
    	    my ($space, $lineno, $perl_code) = ($1, $2, $3, $4);
	    $current_line = $lineno;
    	    my $marked = $perl_code;
    	    # FIXME: DRY code with markup_basic
    	    if ($perl_code =~
    		/-src (?:(?:not supported for)|(?:unavailable under)) -e/) {
    		my $opts = {
    		    output => $highlight,
    		    max_continue => 5,
    		};
    		my $filename = $proc->{frame}{file};
    		$marked = DB::LineCache::getline($filename, $lineno, $opts);
    	    } else {
    		# print "FOUND line $lineno\n";
    		$marked = highlight_string($perl_code) if $highlight;
    	    }
    	    my $lineno_str = $highlight ?
    		$perl_formatter->format_token($lineno, 'Number') : $lineno ;
    	    $_ = "${space}#${lineno_str}:$marked";
    	    ## END above FIXME
    	    ## FIXME: move into DB::Breakpoint and adjust List.pm
    	    if (exists($DB::dbline{$lineno}) and
		my $brkpts = $DB::dbline{$lineno}) {
    		my $found = 0;
    		for my $bp (@{$brkpts}) {
    		    if (defined($bp)) {
    			$marker = sprintf('%s%02d ', $bp->icon_char, $bp->id);
    			$found = 1;
    			last;
    		    }
    		}
    	    }
    	    ## FIXME move above code
	} elsif (/^(\s*)([A-Z]+) \((0x[0-9a-f]+)\) (\w+) (.*)$/) {
    	    my ($space, $op, $hex_str, $name, $rest) = ($1, $2, $3, $4, $5);
    	    if ($check_hex_str && $check_hex_str eq $hex_str) {
    		$marker = '=>  ';
    		$marker = $proc->bolden($marker) if $highlight;
    	    }
    	    if ($highlight) {
    		$hex_str = $perl_formatter->format_token($hex_str, 'Label');
    		$op = $perl_formatter->format_token($op, 'Subroutine');
    		$name = $perl_formatter->format_token($name, 'Builtin_Function');
    	    }
    	    $_ = "${space}${op} ($hex_str) $name ${rest}";
    	}

    	$_ = $marker . $_;
	next if $current_line < $from or $current_line > $to;
	push @newlines, $_;

    }
    return join("\n", @newlines);
}

sub do_one($$$$)
{
    my ($proc, $title, $options, $args) = @_;
    no strict 'refs';
    $proc->section($title);
    my $walker = B::Concise::compile($options->{order}, '-src', @{$args});
    B::Concise::set_style_standard($options->{line_style});
    B::Concise::walk_output(\my $buf);
    $walker->();			# walks and renders into $buf;
    if ('terse' eq $options->{line_style}) {
	$buf = markup_tree_terse($buf, $options->{highlight}, $proc,
				 $options->{from}, $options->{to});
    } elsif ('-tree' eq $options->{order}) {
	$buf = markup_tree($buf, $options->{highlight}, $proc, $options->{from},
			   $options->{to});
    } elsif ('-basic' eq $options->{order}) {
	$buf = markup_basic($buf, $options->{highlight}, $proc, $options->{from},
			    $options->{to});
    }
    $proc->msg($buf);
}

sub run($$)
{
    my ($self, $args) = @_;
    my @args = @$args;
    shift @args;
    my $proc = $self->{proc};
    $DEFAULT_OPTIONS->{from} =  $DEFAULT_OPTIONS->{to} =
	$DEFAULT_OPTIONS->{highlight} = undef;
    my $options = parse_options($self, \@args);
    $options->{highlight} = $proc->{settings}{highlight} unless
	defined($options->{highlight});
    $perl_formatter = Devel::Trepan::DB::Colors::setup($options->{highlight})
	if $options->{highlight};

    if (scalar(@args)) {
	$options->{from} = 0 unless defined($options->{from});
	$options->{to} = 100000 unless defined($options->{to});
    } else {
	$options->{from} = $proc->{frame}{line} unless defined($options->{from});
	$options->{to} = $DEFAULT_OPTIONS->{from} + $proc->{settings}{maxlist}  unless
	    defined($options->{to});
	if ($proc->funcname && $proc->funcname ne 'DB::DB') {
	    push @args, $proc->funcname;
	} else {
	    do_one($proc, "Package Main", $options, ['-main']);
	}
    }
    unless (scalar(@args)) {
    }

    for my $disasm_unit (@args) {
	no strict 'refs';
	if (%{$disasm_unit.'::'}) {
	    do_one($proc, "Package $disasm_unit", $options,
		   ["-stash=$disasm_unit"]);
	} elsif ($proc->is_method($disasm_unit)) {
	    do_one($proc, "Subroutine $disasm_unit", $options, [$disasm_unit]);
	} elsif (-r $disasm_unit) {
	    do_one($proc, "File $disasm_unit", $options, [$disasm_unit]);
	} else {
	    $proc->errmsg("Don't know $disasm_unit as a package or function");
	}
    }
}


# Demo it
unless (caller) {

    for my $flags (0, 1, 2, 3, 0b1101, 0b100011) {
	printf "%07b: %s\n", $flags, interpret_flags($flags);
    }
    require Devel::Trepan::CmdProcessor;
    eval { use Devel::Callsite;  use B; };
    my $proc = Devel::Trepan::CmdProcessor->new(undef, 'bogus');
    my $root_cv = B::main_root;
    $proc->{frame} = {
	line => __LINE__ - 1,
	file => __FILE__,
	fn   => 'DB::DB',
	pkg  => __PACKAGE__,
	addr => $$root_cv,
    };
    $proc->{settings}{highlight} = 1;
    my $cmd = __PACKAGE__->new($proc);
    $cmd->run([$NAME, '-terse', '--highlight=dark']);
    print '=' x 50, "\n";
    # print '=' x 50, "\n";
    # $cmd->run([$NAME, '-basic', '--highlight']);
    # print '=' x 50, "\n";
    # $cmd->run([$NAME, '-basic', '--highlight', '-from', 10, '-to',  20]);
    # print '=' x 50, "\n";
    # $cmd->run([$NAME, '-basic', '--no-highlight', '-to', 5]);
    # print '=' x 50, "\n";
    # $cmd->run([$NAME, '-basic', '--highlight', '-from', __LINE__-25]);
}

1;
