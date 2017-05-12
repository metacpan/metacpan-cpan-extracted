# vi: set autoindent shiftwidth=4 tabstop=8 softtabstop=4 expandtab:
package DB;

use 5.006001;
use strict;
use warnings;

use Carp;
use B qw(svref_2object comppadlist class);
use B::Showlex;
use Curses;
use Curses::UI;
use Curses::UI::Common;
use Data::Dumper;
use Cwd;
use File::Basename;

use Devel::PDB::Source;

use vars qw(*dbline $usercontext $db_stop $ini_warn);

our $VERSION = '1.6';

our $single;
our $sub;
our $trace;
our $signal;
our $stack_depth;
our @stack;
our $current_sub;

my @compiled;
my $inited = 0;
my $cui;
my $sv_win;
my $sv;
my $exit    = 0;
my $db_exit = 0;
my $yield;
my %sources;
my $new_single;
my $current_source;
my $evalarg;
my $package;
my $filename;
my $line;
my @watch_exprs;
my $update_watch_list;

my $std_file_win;
my $std_file;
my $help_win;
my $help;

my $lower_win;
my $auto_win;
my $watch_win;
my $padvar_list;
my $watch_list;

my $padlist_scope;
my %padlist;
my @padlist_disp;

my $stdout;
my $stderr;
my $output;

my $user_conf_readed  = 0;
my $ui_window_focused = 0;

$trace = $signal = $single = 0;
$stack_depth = 0;
@stack       = (0);

my %def_style = (
    -bg  => 'white',
    -fg  => 'blue',
    -bbg => 'blue',
    -bfg => 'white',
    -tbg => 'white',
    -tfg => 'blue',
);

#
# Set or return window colour style
#
sub window_style {
    if (@_) {
        my %h = @_;
        while (my ($k, $v) = each %h) {
            $def_style{$k} = $v if ($k =~ /^-[tbs]?[fb]g$/);
        }
    }
    return %def_style;
}

BEGIN {
    $Devel::PDB::scriptName  = $0;
    @Devel::PDB::script_args = @ARGV;    # copy args
    $ini_warn                = $^W;

    # This is the flag that says "a debugger is running, please call
    # DB::DB and DB::sub". We will turn it on forcibly before we try to
    # execute anything in the user's context, because we always want to
    # get control back.
    $db_stop = 0;                        # Compiler warning ...
    $db_stop = 1 << 30;                  # ... because this is only used in an eval() later.
}

END {
    open STDOUT, ">>&", $stdout if $stdout;
    $single = 0;

    # Save actual breakpoints and watches
    save_state_file(config_file("conf.rc"));

    my @ab = ({
            -label    => '< Quit >',
            -value    => 1,
            -shortcut => 'q'
        },
        {   -label    => '< Show STD* files >',
            -value    => 2,
            -shortcut => 'f'
        },
        {   -label    => '< Restart >',
            -value    => 3,
            -shortcut => 'r'
        },
        {   -label    => '< Save config & Quit >',
            -value    => 4,
            -shortcut => 's'
        },
        {   -label    => '< Save config & Restart >',
            -value    => 'a',
            -shortcut => 5
        },
    );

    my $exitloop = ($db_exit || !$cui) ? 1 : 0;
    while (!$exitloop) {
        my $t = $cui->dialog(
            -title   => 'Exiting',
            -buttons => \@ab,
            -message => 'Choose one of this functions : ',
            window_style(),
        );

        if ($t == 1) {
            $exitloop = 1;
        } elsif ($t == 2) {
            db_view_std_files(1);
        } elsif ($t == 3) {
            DoRestart();
        } elsif ($t == 4) {
            save_state_file(config_file("conf"));
            $exitloop = 1;
        } elsif ($t == 5) {
            save_state_file(config_file("conf"));
            DoRestart();
        }
    }
    endwin();
}

#
# Method for restarting debugger
#
sub DoRestart {

    # There is problem with Destroyer in Curses::UI
    endwin();

    # We must destroyed $cui
    $cui = undef;

    my @flags = ();

    # If warn was on before, turn it on again.
    push @flags, '-w' if $ini_warn;

    # Rebuild the -I flags that were on the initial # command line.
    my %h_inc = @INC;
    foreach (split(" ", `perl -e 'print "\@INC";'`)) {
        delete($h_inc{$_});
    }

    foreach (keys %h_inc) {
        push @flags, '-I', $_;
    }

    # Turn on taint if it was on before.
    push @flags, '-T' if ${^TAINT};

    if ($Devel::PDB::scriptName eq '-e') {
        my $cl;
        my $lines = *{$main::{'_<-e'}}{ARRAY};
        for (1 .. $#$lines) {    # The first line is PERL5DB
            chomp($cl = $lines->[$_]);
            push @flags, '-e', $cl;
        }
    } elsif ($Devel::PDB::scriptName !~ /perl/) {
        push @flags, $Devel::PDB::scriptName;
    }

    # print "$$ doing a restart with $fname\n" ;
    exec "perl", "-d:PDB", @flags, @Devel::PDB::script_args;
}

#
# print any error which is put as arguments
#
sub print_error {
    $cui->error(
        -title   => "Error",
        -message => join("\n", @_),
        DB::window_style(),
    ) if ($cui);
}

#
# returns true if line is breakable
#
sub checkdbline($$) {
    my ($fname, $lineno) = @_;

    return 0 unless $fname;    # we're getting an undef here on 'Restart...'

    local ($^W)     = 0;                        # spares us warnings under -w
    local (*dbline) = $main::{'_<' . $fname};

    my $flag = $dbline[$lineno] != 0;
    return $flag;

}    # end of checkdbline

#
# sets a breakpoint 'through' a magic
# variable that perl is able to interpert
#
sub setdbline($$$) {
    my ($fname, $lineno, $value) = @_;
    local (*dbline) = $main::{'_<' . $fname};

    $dbline{$lineno} = $value;
}    # end of setdbline

sub getdbline($$) {
    my ($fname, $lineno) = @_;
    local (*dbline) = $main::{'_<' . $fname};
    return $dbline{$lineno};
}    # end of getdbline

sub getdbtextline {
    my ($fname, $lineno) = @_;
    local (*dbline) = $main::{'_<' . $fname};
    return $dbline[$lineno];
}    # end of getdbline

sub cleardbline($$;&) {
    my ($fname, $lineno, $clearsub) = @_;
    local (*dbline) = $main::{'_<' . $fname};
    my $value;    # just in case we want it for something

    $value = $dbline{$lineno};
    delete $dbline{$lineno};
    &$clearsub($value) if $value && $clearsub;

    return $value;
}    # end of cleardbline

sub clearalldblines(;&) {
    my ($clearsub) = @_;
    my ($key, $value, $brkPt, $dbkey);
    local (*dbline);

    while (($key, $value) = each %main::) {    # key loop
        next unless $key =~ /^_</;
        *dbline = $value;

        foreach $dbkey (keys %dbline) {
            $brkPt = $dbline{$dbkey};
            delete $dbline{$dbkey};
            next unless $brkPt && $clearsub;
            &$clearsub($brkPt);                # if specificed, call the sub routine to clear the breakpoint
        }

    }    # end of key loop

}    # end of clearalldblines

sub getdblineindexes {
    my ($fname) = @_;
    local (*dbline) = $main::{'_<' . $fname};
    return keys %dbline;
}    # end of getdblineindexes

#
# Return list of breakpoints from files which are add as arguments
#
sub getbreakpoints {
    my (@fnames) = @_;
    my ($fname, @retList);

    foreach $fname (@fnames) {
        next unless $main::{'_<' . $fname};
        local (*dbline) = $main::{'_<' . $fname};
        push @retList, values %dbline;
    }
    return @retList;
}    # end of getbreakpoints

#
# Return filename from param and remove _< character from begin
#
sub retfilename {
    my $f = shift;
    $f =~ s/^_<//;
    return $f;
}

#
# Construct a hash of the files
# that have breakpoints to save
#
sub breakpoints_to_save {
    my %brkList = ();

    foreach my $file (keys %main::) {    # file loop
        next unless $file =~ /^_</ && exists $main::{$file};

        #my @k = getdblineindexes(retfilename($file));
        local (*dbline) = $main::{$file};
        my @a = ();
        while (my ($k, $d) = each %dbline) {
            push(@a, {'line' => $k, 'breakpoint' => $d}) if ($d);
        }
        $brkList{$file} = \@a if (scalar(@a));
    }    # end of file loop
    return \%brkList;

}    # end of breakpoints_to_save

#
# When we restore breakpoints from a state file
# they've often 'moved' because the file
# has been editted.
#
# We search for the line starting with the original line number,
# then we walk it back 20 lines, then with line right after the
# orginal line number and walk forward 20 lines.
#
# NOTE: dbline is expected to be 'local'
# when called
#
sub fix_breakpoints {
    my (@brkPts) = @_;
    my ($startLine, $endLine, $nLines, $brkPt);
    my (@retList);
    local ($^W) = 0;

    $nLines = scalar @dbline;

    foreach $brkPt (@brkPts) {

        #$startLine = $brkPt->{'line'} > 20 ? $brkPt->{'line'} - 20 : 0 ;
        #$endLine   = $brkPt->{'line'} < $nLines - 20 ? $brkPt->{'line'} + 20 : $nLines ;
        #
        #for( (reverse $startLine..$brkPt->{'line'}), $brkPt->{'line'} + 1 .. $endLine ) {
        #   next unless $brkPt->{'text'} eq $dbline[$_] ;
        #   $brkPt->{'line'} = $_ ;
        #   push @retList, $brkPt ;
        #   last ;
        #}
        push @retList, $brkPt;
    }    # end of breakpoint list

    return @retList;

}    # end of fix_breakpoints

sub set_breakpoints {
    my ($fname, $newList) = @_;

    local (*dbline) = $main::{$fname};

    my $offset = 0;
    $offset = 1 if $dbline[1] =~ /use\s+.*Devel::_?PDB/;

    foreach my $brkPt (@$newList) {
        if (!checkdbline(retfilename($fname), $brkPt->{'line'} + $offset)) {
            print_error("Breakpoint $fname:$brkPt->{'line'} in config file is not breakable.");
            next;
        }

        #$dbline{$brkPt->{'line'}} = { %$brkPt } ; # make a fresh copy
        $dbline{$brkPt->{'line'}} = exists($brkPt->{'breakpoint'}) ? $brkPt->{'breakpoint'} : 1;
    }

}

my %postponed_file = ();

#
# Restore breakpoints saved above
#
sub restore_breakpoints_from_save {
    my ($brkList) = @_;
    my ($key, $list, @newList);

    while (($key, $list) = each %$brkList) {    # reinsert loop
        $postponed_file{$key} = $list;

        next unless exists $main::{$key};

        @newList = fix_breakpoints(@$list);
        set_breakpoints($key, \@newList);
    }    # end of reinsert loop

}    # end of restore_breakpoints_from_save ;

#
# Loading watches and breakpoint from state file(it is param)
#
sub load_state_file {
    my ($fName) = @_;

    if (-e $fName && -r $fName) {
        no strict;
        local ($files, $expr_list);
        do $fName;
        if ($@) {
            print_error($@);
        }

        %postponed_file = ();

        restore_breakpoints_from_save($files);

        # Don't load saved watches against
        my %h = map { $_->{name} => 1 } @watch_exprs;
        foreach $rh (@$expr_list) {
            push @watch_exprs, {name => $rh->{name}} unless exists($h{$rh->{name}});
        }
        $update_watch_list = 1;

        if ($current_source) {
            my $view = $current_source->view;
            $view->intellidraw if (defined $view);
        }
    }
}    # end of Restore State

#
# Save watches and breakpoints to state filename(it is param)
#
sub save_state_file {
    my ($fname) = @_;
    my ($files, $d, $saveStr);

    $files = breakpoints_to_save();

    $d = Data::Dumper->new([$files, \@watch_exprs], [qw(files expr_list)]);

    $d->Indent(1);
    $d->Purity(1);
    $d->Terse(0);
    if (Data::Dumper->can('Dumpxs')) {
        $saveStr = $d->Dumpxs();
    } else {
        $saveStr = $d->Dump();
    }

    local (*F);
    open F, ">$fname" || die "Couldn't open file $fname";
    print F $saveStr || die "Couldn't write file";
    close F;
}    # end of save_state_file

my $_log_opened = 0;

#
# Internal method for printing anything to file
# 1. name of text
# 2. variable
#
sub log_dumper {
    my ($name, $a) = @_;

    my $fDUMP = config_file("dump");
    local (*W);
    open(W, ($_log_opened ? ">" : "") . ">$fDUMP")
      or die "Can't open dump file : $fDUMP\n";
    $_log_opened = 1;
    print W "$name";

    if ($a) {
        local $Data::Dumper::Purity   = 0;
        local $Data::Dumper::Terse    = 0;
        local $Data::Dumper::Indent   = 2;
        local $Data::Dumper::Sortkeys = 1;
        print W Dumper($a);
    }
    print W "\n";
    close(W);
}

#
# UI for exiting
#
sub ui_db_quit {
    return
      if not $cui->dialog(
        -title   => 'Quit Debugger',
        -buttons => ['yes', 'no'],
        -message => 'Do you really want to quit?',
        window_style(),
      );
    save_state_file(config_file("conf.rc"));

    $single = 0;
    for (my $i = 0; $i <= $stack_depth; ++$i) {
        $stack[$i] = 0;
    }

    $db_exit = 1;

    #print(STDERR $_, "\n") foreach (@compiled);
    exit(0);
}

sub db_cont {
    $new_single = 0;
    for (my $i = 0; $i <= $stack_depth; ++$i) {
        $stack[$i] &= ~1;
    }
    $yield = 1;
}

#
# Key for step into method
#
sub db_step_in {
    $new_single = 1;
    $yield      = 1;
}

#
# Key for step over - next step
#
sub db_step_over {
    $new_single = 2;
    $yield      = 1;
}

#
# Key for step from given method
#
sub db_step_out {
    $new_single = 0;
    $stack[-1] &= ~1;
    $yield = 1;
}

#
# $code is 0 or 1 and $r is ref to error string
# 0 - Set breakpoint, If breakpoint exist on given line, than remove
# 1 - Set breakpoint with condition
# StringRef - Problem with condition in breakpoint, that reedit
#
sub db_toggle_break {
    my ($code, $r) = shift;
    local (*dbline) = $main::{'_<' . $current_source->filename};
    $current_source->toggle_break($code, $r);
}

#
# Add watch expression
#
sub db_add_watch_expr {
    my $text = shift;
    my $expr = $cui->question(
        -question => "Please enter an expression to watches\n"
          . "Global variables must be set as '\$main::varname'\n"
          . 'Array or Hash must set as Reference like \@a, otherwise show size',
        -title => "Add watch expresion",
        (defined($text) && length($text) ? (-answer => $text) : ()),
        window_style(),
    );
    if (defined($text) && length($text)) {
        my $pos = -1;
        for (my $i = 0; $pos == -1 && $i < scalar(@watch_exprs); $i++) {
            $pos = $i if ($watch_exprs[$i]->{name} eq $text);
        }
        splice(@watch_exprs, $pos, 1, {name => $expr}) if ($expr && $pos >= 0);
    } else {
        return if !$expr;
        push @watch_exprs, {name => $expr};
    }
    $update_watch_list = 1;
}

sub db_edit_watch_expr {
    my $watch_list = shift;

    my $id   = $watch_list->get_active_id;
    my $item = $watch_list->{-named_list}->[$id];
    db_add_watch_expr($item->{name});
}

#
# List breapoints
#
sub ui_list_breakpoints {
    my @a = ();
    foreach my $file (keys %main::) {    # file loop
        next unless $file =~ /^_</ && exists $main::{$file};

        local (*dbline) = $main::{$file};
        while (my ($k, $d) = each %dbline) {
            next unless ($d);
            my $str = retfilename($file) . " line:$k ";
            if ($d =~ /\0/) {
                my ($s, $action) = split(/\0/, $d);
                $str .= "test ( $action )";
            }
            push(@a, $str);
        }
    }    # end of file loop

    my $filename = $cui->tempdialog(
        'Devel::PDB::Dialog::FileBrowser',
        -title           => "List all breakpoints",
        -files           => \@a,
        -its_breakpoints => 1,
        window_style(),
    );

    if ($filename) {
        my @a1 = split(" ", $filename);
        my @a2 = split(":", $a1[1]);
        my $source = $current_source = get_source($a1[0]);
        if ($source) {
            $sv->source($source);
            $sv->goto(int($a2[1]) + 1);
        }
        $sv->intellidraw;
    } else {
        clearalldblines ();

        my %h = ();
        foreach (@a) {
            my @a1 = split(" ");
            my @a2 = split(":", $a1[1]);

            my $fname = '_<' . $a1[0];
            $h{$fname} = [] if (!exists($h{$fname}));
            push(@{$h{$fname}}, {line => $a2[1]});
        }
        restore_breakpoints_from_save(\%h);
        $update_watch_list = 1;

        my $view = $current_source->view;
        $view->intellidraw if (defined $view);
    }
}

sub refresh_stack_menu {
    my ($str, $name, $i, $sub_offset, $subStack);

    #
    # CAUTION:  In the effort to 'rationalize' the code
    # are moving some of this function down from DB::DB
    # to here.  $sub_offset represents how far 'down'
    # we are from DB::DB.  The $DB::subroutine_depth is
    # tracked in such a way that while we are 'in' the debugger
    # it will not be incremented, and thus represents the stack depth
    # of the target program.
    #
    $sub_offset = 1;
    $subStack   = [];

    # clear existing entries
    for ($i = 0; $i <= ($DB::subroutine_depth || 0); $i++) {
        my @a = caller $i + $sub_offset;
        my ($package, $filename, $line, $subName) = caller $i + $sub_offset;
        last if !$subName;
        push @$subStack, {'name' => $subName, 'pck' => $package, 'filename' => $filename, 'line' => $line};
    }

    #$self->{stack_menu}->menu->delete(0, 'last') ; # delete existing menu items
    #for( $i = 0 ; $subStack->[$i] ; $i++ ) {
    #	$str = defined $subStack->[$i+1] ? "$subStack->[$i+1]->{name}" : "MAIN" ;
    #	my ($f, $line) = ($subStack->[$i]->{filename}, $subStack->[$i]->{line}) ; # make copies of the values for use in 'sub'
    #	$self->{stack_menu}->command(-label => $str, -command => sub { $self->goto_sub_from_stack($f, $line) ; } ) ;
    #}
}    # end of refresh_stack_menu

# dump_trace(skip[,count])
#
# Actually collect the traceback information available via C<caller()>. It does
# some filtering and cleanup of the data, but mostly it just collects it to
# make C<print_trace()>'s job easier.
#
# C<skip> defines the number of stack frames to be skipped, working backwards
# from the most current. C<count> determines the total number of frames to
# be returned; all of them (well, the first 10^9) are returned if C<count>
# is omitted.
#
# This routine returns a list of hashes, from most-recent to least-recent
# stack frame. Each has the following keys and values:
sub dump_trace {

    # How many levels to skip.
    my $skip = shift;

    # How many levels to show. (1e9 is a cheap way of saying "all of them";
    # it's unlikely that we'll have more than a billion stack frames. If you
    # do, you've got an awfully big machine...)
    my $count = shift || 1e9;

    # We increment skip because caller(1) is the first level *back* from
    # the current one.  Add $skip to the count of frames so we have a
    # simple stop criterion, counting from $skip to $count+$skip.
    $skip++;
    $count += $skip;

    # These variables are used to capture output from caller();
    my ($p, $file, $line, $sub, $h, $context);

    my ($e, $r, @a, @sub, $args);

    #.....
    my @args = ();
    our $frame = 0;

    # XXX Okay... why'd we do that?
    my $nothard = not $frame & 8;
    local $frame = 0;

    # Do not want to trace this.
    my $otrace = $trace;
    $trace = 0;

    # Start out at the skip count.
    # If we haven't reached the number of frames requested, and caller() is
    # still returning something, stay in the loop. (If we pass the requested
    # number of stack frames, or we run out - caller() returns nothing - we
    # quit.
    # Up the stack frame index to go back one more level each time.
    for (my $i = $skip; $i < $count and ($p, $file, $line, $sub, $h, $context, $e, $r) = caller($i); $i++) {

        # Go through the arguments and save them for later.
        @a = ();
        for my $arg (@args) {
            my $type;
            if (not defined $arg) {    # undefined parameter
                push @a, "undef";
            }

            elsif ($nothard and tied $arg) {    # tied parameter
                push @a, "tied";
            } elsif ($nothard and $type = ref $arg) {    # reference
                push @a, "ref($type)";
            } else {                                     # can be stringified
                local $_ = "$arg";                       # Safe to stringify now - should not call f().

                # Backslash any single-quotes or backslashes.
                s/([\'\\])/\\$1/g;

                # Single-quote it unless it's a number or a colon-separated
                # name.
                s/(.*)/'$1'/s
                  unless /^(?: -?[\d.]+ | \*[\w:]* )$/x;

                # Turn high-bit characters into meta-whatever.
                s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;

                # Turn control characters into ^-whatever.
                s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;

                push(@a, $_);
            } ## end else [ if (not defined $arg)
        } ## end for $arg (@args)

        # If context is true, this is array (@)context.
        # If context is false, this is scalar ($) context.
        # If neither, context isn't defined. (This is apparently a 'can't
        # happen' trap.)
        $context = $context ? '@' : (defined $context ? "\$" : '.');

        # if the sub has args ($h true), make an anonymous array of the
        # dumped args.
        $args = $h ? [@a] : undef;

        # remove trailing newline-whitespace-semicolon-end of line sequence
        # from the eval text, if any.
        $e =~ s/\n\s*\;\s*\Z// if $e;

        # Escape backslashed single-quotes again if necessary.
        $e =~ s/([\\\'])/\\$1/g if $e;

        # if the require flag is true, the eval text is from a require.
        if ($r) {
            $sub = "require '$e'";
        }

        # if it's false, the eval text is really from an eval.
        elsif (defined $r) {
            $sub = "eval '$e'";
        }

        # If the sub is '(eval)', this is a block eval, meaning we don't
        # know what the eval'ed text actually was.
        elsif ($sub eq '(eval)') {
            $sub = "eval {...}";
        }

        # Stick the collected information into @sub as an anonymous hash.
        push(
            @sub,
            {   context => $context,
                sub     => $sub,
                args    => $args,
                file    => $file,
                line    => $line
            });

        # Stop processing frames if the user hit control-C.
        last if $signal;
    } ## end for ($i = $skip ; $i < ...

    # Restore the trace value again.
    $trace = $otrace;
    @sub;
} ## end sub dump_trace

#
# List of stack - methods call
#
sub ui_view_stack {
    my $rev = shift;

    my $i     = -1;
    my @a     = ();
    my %h     = ();
    my %h_ret = ();
    foreach my $rh (dump_trace(2)) {
        if ($rh->{'sub'} =~ /DB::DB/) {
            $i = 1;
            next;
        } elsif ($i < 0) {
            next;
        }
        push(@a, $i);
        $h{$i} =
            $rh->{'sub'} . "("
          . (ref($rh->{args}) eq "ARRAY" ? join(",", @{$rh->{args}}) : "")
          . ") in file "
          . $rh->{file} . ":"
          . $rh->{line};
        $h_ret{$i} = $rh;
        $i++;
    }

    @a = reverse @a;
    my $win = $cui->add(
        'winstackwindow', 'Window',
        -padtop   => 1,
        -border   => 0,
        -centered => 1,
        -title    => 'Stack',
        window_style(),
    );
    my $listbox = $win->add(
        'StackWindow', 'Listbox',
        -title     => "Stack window",
        -y         => 0,
        -border    => 1,
        -padbottom => 1,

        #-width       => $cui->canvaswidth,
        -vscrollbar => 1,
        -values     => \@a,
        -labels     => \%h,

        #-onselchange => \&on_file_active,
        window_style(),
    );
    $win->add(
        "help", "Label",
        -y             => -1,
        -width         => -1,
        -reverse       => 1,
        -paddingspaces => 1,
        -text          => " Ctrl+Q|Ctrl+C|F10|ESC - Exit  |  Ctrl+R|F2 - Reverse  |  Return - jump to given function "
    );
    $listbox->set_routine(
        'option-select',
        sub {
            my $this = shift;

            #$this->{-id_value} = $this->get_active_value;
            $this->loose_focus;
        });

    $listbox->set_binding(sub { shift->loose_focus; }, "\cQ", "\cC", KEY_F(10), CUI_ESCAPE());

    $listbox->set_binding(sub { my $this = shift; my @ar = reverse @a; $this->values(\@ar); }, "\cR", KEY_F(2));

    my $sel = $listbox->modalfocus();
    my $ia = $sel ? $sel->get_active_value() : undef;
    $win->delete("StackWindow");
    $cui->delete("winstackwindow");

    if ($ia) {
        my $source = $current_source = get_source($h_ret{$ia}->{file});
        $sv->source($source) if $source;
        $sv->intellidraw;
        $sv->goto($h_ret{$ia}->{line} + 1);
    }

    $sv_win->focus;
}

#
# UI export information
#
sub ui_db_export {
    my $win = $cui->add(
        'winexportwindow', 'Window',
        -border   => 1,
        -centered => 1,
        -title    => 'Export information from actuall position to file',
        -height   => 14,
        window_style(),
    );

    $win->add("ExportLabel_1", 'Label', -y => 1, -x => 2, -text => 'Number of lines : ', -bold => 1);

    my $lines = 10;
    $win->add(
        "ExportNumber", "TextEntry",
        -y        => 1,
        -x        => 20,
        -width    => 20,
        -text     => $lines,
        -regexp   => '/^\d*$/',
        -onchange => sub { $lines = shift->get(); },
    );

    $win->add("ExportLabel_2", 'Label', -y => 3, -x => 2, -text => 'Filename : ', -bold => 1);

    my $filename = undef;
    $win->add(
        "ExportFilename", "TextEntry",
        -y        => 3,
        -x        => 14,
        -width    => 30,
        -onchange => sub { $filename = shift->get(); },
    );

    $win->add(
        "ExportLabel_3", 'Label',
        -y    => 5,
        -x    => 2,
        -text => 'Variables separated by space or export everything : ',
        -bold => 1,
    );
    my $variables = undef;
    $win->add(
        "ExportVariables", "TextEntry",
        -y        => 6,
        -x        => 2,
        -width    => 30,
        -onchange => sub { $variables = shift->get(); },
    );

    my $use_watches = 0;
    $win->add(
        'ExportWatches', 'Checkbox',
        -label    => "Export all variables from watch tables",
        -y        => 8,
        -x        => 2,
        -onchange => sub { $use_watches = shift->get(); },
        window_style(),
    );

    my $exit = 1;
    $win->add(
        'ExportButtons',
        'Buttonbox',
        -buttons => [{
                -label    => '< Ok >',
                -shortcut => 'o',
                -onpress  => sub { $exit = 0; $win->loose_focus; }
            },
            {   -label    => '< Cancel >',
                -shortcut => 'c',
                -onpress  => sub {
                    $win->loose_focus;
                  }
            }
        ],
        -y => 10,
        -x => 2,
    );

    $win->set_binding(sub { shift->loose_focus; }, "\cQ", "\cC", KEY_F(10), CUI_ESCAPE());
    my $sel = $win->modalfocus();
    $cui->delete("winexportwindow");

    local *W;
    if ($exit) {
    } elsif (!$filename || !length($filename)) {
        print_error("Filename must be set");
    } elsif (!open(W, ">$filename")) {
        print_error("Can't open file $filename : $!");
    } else {
        local (*dbline) = $main::{'_<' . $current_source->filename};

        my $current_line = $current_source->current_line;
        my $from         = $current_line - $lines;
        $from = 0 if ($from < 0);
        my $to = $current_line + $lines;
        my $l = length(sprintf("%d", $to));

        print W "----- Filename : " . $current_source->filename . "----------\n";
        for my $i ($from .. $to) {
            last unless exists $dbline[$i];
            if ($i == 0 && $dbline[$i] =~ /use\s+.*Devel::_?PDB/) {
                $to++;
                next;
            }
            printf W "%s%*d %s", $i == $current_line ? '*' : ' ', $l, $i, $dbline[$i];
        }

        sub print_variables {
            my ($rh) = @_;
            print W $rh->{name} . " -> " . $rh->{long_value} . "\n";
        }
        print W "----- Stack : -------------\n";
        my %h = ();
        %h = map { $_ => 1 } split(" ", $variables) if (length($variables));
        foreach my $rh (@padlist_disp) {
            print_variables($rh) if (!keys(%h) || exists($h{$rh->{name}}));
        }

        if ($use_watches) {
            print W "----- Watches : -----------\n";
            foreach my $rh (@watch_exprs) {
                print_variables($rh);
            }
        }

        close(W);
    }

    $sv_win->focus;
}

#
# UI open file
#
sub ui_open_file {
    my ($title, $files) = @_;

    my $filename = $cui->tempdialog(
        'Devel::PDB::Dialog::FileBrowser',
        -title => $title,
        -files => $files,
        window_style(),
    );
    if ($filename) {
        my $source = $current_source = get_source($filename);
        $sv->source($source) if $source;
        $sv->intellidraw;
    }
}

#
# UI view STD[OUT|ERR] files
#
sub db_view_std_files {
    my ($use_exit) = @_;
    my @ab = ({
            -label    => '< STDOUT >',
            -value    => 1,
            -shortcut => 'o'
        },
        {   -label    => '< STDERR >',
            -value    => 2,
            -shortcut => 'e'
        });
    unshift(
        @ab,
        {   -label    => '< Exit >',
            -value    => -1,
            -shortcut => 'x'
        }) if ($use_exit);

    my $t = $cui->dialog(
        -title   => 'Open STD* files',
        -buttons => \@ab,
        -message => 'Choose which STD* file to open it?',
        window_style(),
    );
    return if ($t == -1);

    my $text = "";
    if (open F, "<" . config_file($t == 2 ? "stderr" : "stdout")) {
        while (<F>) { $text .= $_ }
        close F;
    } else {
        $cui->error(-message => "Cannot read file " . config_file($t == 2 ? "stderr" : "stdout") . ":\n$!");
        exit(127);
    }
    my $win = $cui->add(
        'winmytextviewer', 'Window',
        -border => 0,
        -title  => 'Source',
        window_style(),
    );
    my $textviewer = $win->add(
        "mytextviewer", "TextViewer",
        -homeonblur      => 1,       # cursor to homepos on blur?
        -fg              => -1,
        -bg              => -1,
        -cursor          => 1,
        -border          => 1,
        -padtop          => 0,
        -padbottom       => 1,
        -showlines       => 0,
        -sbborder        => 0,
        -vscrollbar      => 1,
        -hscrollbar      => 1,
        -showhardreturns => 0,
        -wrapping        => 0,       # wrapping slows down the editor :-(
        -text            => $text,
        -title => " Viewing file STD" . ($t == 2 ? "ERR" : "OUT") . " : " . config_file($t == 2 ? "stderr" : "stdout"),
        window_style(),
    );
    $win->add(
        "help", "Label",
        -y             => -1,
        -width         => -1,
        -reverse       => 1,
        -paddingspaces => 1,
        -text          => " Ctrl+Q|Ctrl+C|F10|ESC - Return "
    );
    $textviewer->set_binding(sub { shift->loose_focus; }, "\cQ", "\cC", KEY_F(10), CUI_ESCAPE());
    $textviewer->modalfocus();
    $win->delete("mytextviewer");
    $cui->delete("winmytextviewer");
}

#
# Change vertical size of windows. This change size of windows between Source and Watches+Stack
# 1  - decrease Source window
# -1 - increase Source window
#
sub ui_adjust_vert_parts {
    my $delta = shift;
    return
      if $delta > 0 && $sv_win->{-padbottom} >= $cui->{-height} - $sv_win->{-padtop} - 5
          or $delta < 0 && $lower_win->{-height} <= 5;
    $sv_win->{-padbottom} += $delta;
    $lower_win->{-height} += $delta;
    $cui->layout_contained_objects;
}

#
# Change horizontal size of windows. This change size of windows between Watches expresion and Stack
# 1  - increasing Watches window
# -1 - decreasing Watches window
#
sub ui_adjust_hori_parts {
    my $delta = shift;
    return
      if $delta > 0 && $auto_win->{-width} >= $cui->{-width} - 15
          or $delta < 0 && $auto_win->{-width} <= 15;
    $auto_win->{-width}    += $delta;
    $watch_win->{-padleft} += $delta;
    $cui->layout_contained_objects;
}

#
# Return name for config file
#
sub config_file {
    my $name      = shift;
    my $file_name = File::Basename::basename($Devel::PDB::scriptName);
    my $dir_name  = File::Basename::dirname(Cwd::abs_path($Devel::PDB::scriptName));
    if ($ENV{PDB_use_HOME} && exists($ENV{HOME})) {
        $dir_name = $ENV{HOME} . "/.PDB";
        mkdir($dir_name) unless (-d $dir_name);
    }
    return $dir_name . "/.$file_name" . "-" . $name;
}

my $keys_binded = undef;
my @keys_global = ();
my %keys_hash   = ();

#
# Set key
# 1 - CodeRef for appened action
# 2 - nickname for given action
# 3 - Text which will be printed
# 4 and others are keys for binding
#
sub set_key_binding($$@) {
    my $rf   = shift;
    my $name = shift;
    my $text = shift;
    my @keys = @_;

    if (!defined($keys_binded)) {
        if (open(my $fh, $ENV{HOME} . "/.PDB.keys")) {
            while (<$fh>) {
                chomp;
                my @a = split("=");
                next if (scalar(@a) < 2);
                my @akeys = ();
                foreach my $r (split(",", $a[1])) {
                    if ($r =~ /F/) {
                        $r =~ s/F//;
                        $r = KEY_F(int($r));
                    } elsif ($r =~ /Control-/) {
                        $r =~ s/Control-//;
                        $r = chr(ord(uc($r)) & 0x1F);
                    } elsif ($r =~ /KEY_/) {
                        no strict;
                        $r = $Curses::{$r} ? &{"Curses::" . $r}() : undef;
                    }
                    push(@akeys, $r) if ($r);
                }
                $keys_binded->{$a[0]} = \@akeys;
            }
            close($fh);
        } else {
            $keys_binded = {};
        }
    }

    push(@keys_global, {name => $text, key => \@keys});
    $cui->set_binding($rf, exists($keys_binded->{$name}) ? @{$keys_binded->{$name}} : @keys);

    $text .= " ";
    foreach my $k (exists($keys_binded->{$name}) ? @{$keys_binded->{$name}} : @keys) {
        my $key = $cui->key_to_ascii($k);
        $text .= $key . " ";

        # Add duplicity
        $keys_hash{$key} = [] unless (exists($keys_hash{$key}));
        my $ra = $keys_hash{$key};
        push(@$ra, $name);
    }

    return {-value => $rf, -label => $text};
}

sub val_unctrl {
    local ($_) = @_;

    return \$_ if ref \$_ eq "GLOB";
    if (ord('A') == 193) {    # EBCDIC.
                              # EBCDIC has no concept of "\cA" or "A" being related
                              # to each other by a linear/boolean mapping.
    } else {
        s/([\001-\037\177])/'^'.pack('c',ord($1)^64)/eg;
    }
    $_;
}

#
# Window wieving or editing
# 1 - Editing program params
# 2 - Editing enviroment
# 3 - Viewing Perl special variables
#
sub ui_text_editor {
    my $type = shift;

    my @rows       = ();
    my $str_title  = "";
    my $str_label  = "";
    my $use_editor = 1;

    if ($type == 1) {
        @rows      = @Devel::PDB::script_args;
        $str_title = 'Edit program params';
        $str_label = " Enter => Save ";
    } elsif ($type == 2) {
        $str_title = 'Edit enviroments';
        $str_label = " F2 => Save ";
        foreach my $k (sort keys %ENV) {
            push(@rows, $k . "=" . $ENV{$k});
        }
    } elsif ($type == 3) {
        $str_title  = 'View special variables';
        $use_editor = 0;

        sub rep_dumper {
            my $s = shift;
            $s =~ s/^\$//;
            chomp($s);
            return $s;
        }

        no strict;
        *stab = *{"main::"};
        foreach my $key (sort keys %stab) {
            next if ($key =~ /^_</);
            local (*entry) = $stab{$key};

            my $fileno;

            local $Data::Dumper::Purity   = 0;
            local $Data::Dumper::Terse    = 0;
            local $Data::Dumper::Indent   = 2;
            local $Data::Dumper::Sortkeys = 1;
            if (defined $entry) {
                push(@rows, '$' . &val_unctrl($key) . " = " . $entry);
            } elsif (@entry) {
                local $Data::Dumper::Varname = "\@$key";
                push(@rows, &rep_dumper(Dumper(@entry)));
            } elsif ($key ne "main::"
                && $key ne "DB::"
                && %entry
                && $key !~ /::$/
                && !($package eq "dumpvar" and $key eq "stab")) {
                local $Data::Dumper::Varname = "\%$key";
                push(@rows, &rep_dumper(Dumper(%entry)));
            }
        }
    }

    my $row = scalar(@rows) || 1;

    my $win = $cui->add(
        'winChangeParams', 'Window',
        -border => 1,

        #-y      => int(($LINES - ($row + 3)) / 2), # Buggy
        #-height => $row + 3,
        -centered => 1,
        -title    => $str_title,
        window_style(),
    );
    my $x = $win->add(
        "ChangeParams", $use_editor ? "TextEditor" : "TextViewer",
        -homeonblur => 1,                   # cursor to homepos on blur?
        -fg         => -1,
        -bg         => -1,
        -cursor     => 1,
        -padbottom  => 1,
        -text       => join("\n", @rows),
    );
    $win->add(
        "help", "Label",
        -y             => -1,
        -width         => -1,
        -reverse       => 1,
        -paddingspaces => 1,
        -text          => " Ctrl+Q|Ctrl+C|F10|ESC -> Return    " . $str_label,
    );

    # Setup bindings.
    $x->clear_binding('loose-focus');
    $x->set_binding(sub { shift->loose_focus; }, "\cQ", "\cC", KEY_F(10), CUI_ESCAPE());

    if ($type == 1) {
        $x->set_binding(
            sub {
                my $this = shift;
                @Devel::PDB::script_args = ();
                foreach my $s (split("\n", $this->get())) {
                    my $x = $s;
                    $x =~ s/ //g;
                    push(@Devel::PDB::script_args, $s) if (length($x));
                }
                $this->loose_focus;
            },
            KEY_ENTER(),
            KEY_BTAB(),
            CUI_TAB());
    } elsif ($type == 2) {
        $x->set_binding(
            sub {
                my $this = shift;
                %ENV = ();
                foreach my $s (split("\n", $this->get())) {
                    my $x = $s;
                    $x =~ s/ //g;
                    if (length($x)) {
                        my @a = split("=", $s);
                        $ENV{$a[0]} = $a[1] if (scalar(@a) == 2);
                    }
                }
                $this->loose_focus;
            },
            KEY_F(2));
    } elsif ($type == 3) {
    }

    $x->modalfocus();
    $win->delete('ChangeParams');
    $cui->delete('winChangeParams');
    $sv_win->focus;
}

#
# Print helping keys association
#
sub ui_db_help {
    my @a = ();
    push(@a, "Global");
    foreach my $rh (@keys_global) {
        my $s = "  ";
        foreach (@{$rh->{key}}) {
            $s .= $cui->key_to_ascii($_) . " ";
        }
        push(@a, $s . "\t" . $rh->{name});
    }

    push(@a, "Source Code Window");
    push(@a, "  UP/DOWN/LEFT/RIGHT/PAGE UP/PAGE DOWN\tMove the cursor");
    push(@a, "  H/J/K/L/Ctrl+F/Ctrl+B\tIf you use VI, you will know");
    push(@a, "  /\tSearch using a RegEx in the current opened file");
    push(@a, "  n\tSearch Next");
    push(@a, "  N\tSearch Previous");
    push(@a, "  Ctrl+G\tGoto a specific line");

    push(@a, "Lexical Variable Window / Watch Window");
    push(@a, "  UP/DOWN\tMove the cursor");
    push(@a, "  ENTER\tShow the Data::Dumper output of the highlighted item in a scrollable dialog");
    push(@a, "  DEL\tRemove the highlighted expression (Watch Window only)");

    push(@a, "Compiled File Dialog / Opened File Dialog");
    push(@a, "  TAB\tToggle the focus between the file list and the filter");
    push(@a, "  ENTER\tSelect the highlighted file or apply the filter to the file list");
    push(@a, "Other");
    push(@a, "  Esc,F10\tBack,Exit function");
    push(@a, "  Ctrl+S,Ctrl+L,F6\tExporting to file");

    if (keys %keys_hash) {
        my @ad = ();
        foreach my $k (sort %keys_hash) {
            next if (ref($k));
            my $ra = $keys_hash{$k};
            next if (scalar(@$ra) <= 1);
            push(@ad, $k);
            push(@ad, map { $_ } @$ra);
        }
        push(@a, " ", " ", "Duplicity in keys", " ", @ad) if (@ad);
    }

    dialog_message(
        -title   => "Help Keys",
        -message => join("\n", @a),
    );
}

#
# Create dialog message window with binded key F2 for saving text
#
sub dialog_message {
    my %args = @_;
    Devel::PDB::Dialog::Message->run(%args, window_style());
}

#
# Exporting to file
#
sub export_to_file {
    my ($name, $title, $rh_str) = @_;

    return unless $cui;
    $name ||= "Title";
    my $fname = $cui->question(-question => 'Add filename to export', DB::window_style()) || return;
    if (open(my $fh, ">", $fname)) {
        print $fh "----- $name : " . $title . " ----------\n" if ($title);
        print $fh $$rh_str;
        print $fh "\n";
        close($fh);
    } else {
        DB::print_error("Can't open file $fname : $!");
    }
}

#
# Activate window
#
sub set_active_window {
    my $win = shift;

    if ($win == 2) {
        $ui_window_focused = 1;
        $auto_win->focus;
    } elsif ($win == 3) {
        $ui_window_focused = 2;

        #ui_update_watch_list();
        $watch_win->focus;
    } else {
        $ui_window_focused = 0;
        $sv_win->focus;
    }
}

#
# Initialize ncurses methods
#
sub init {

    # Set own colours
    if (open(my $fh, $ENV{HOME} . "/.PDB.colours")) {
        my %h;
        while (<$fh>) {
            chomp;
            my @a = split(/\s+/);
            $h{$a[0]} = $a[1];
        }
        close($fh);
        window_style(%h);
    }

    # can anybody tell me why $win->notimeout(1) doesn't work?
    $ENV{ESCDELAY} = '0';

    $cui = new Curses::UI(
        -clear_on_exit => 1,
        -color_support => 1,
        -mouse_support => 1,
    );

    if ($Curses::UI::VERSION > 0.9602) {

        # In version 0.9603 has ben removed rootobject, but we need in this modules :
        #	- PDB/SourceView.pm
        #	- PDB/Dialog/Message.pm
        $Curses::UI::rootobject = $cui;
    }

    if ($Curses::UI::color_support) {
        my $old_draw = \&Curses::UI::Widget::draw;
        no warnings;
        *Curses::UI::Widget::draw = sub (;$) {
            my ($this) = @_;
            if (defined $this->{-fg} && defined $this->{-bg}) {
                my $canvas =
                  defined $this->{-borderscr}
                  ? $this->{-borderscr}
                  : $this->{-canvasscr};
                $canvas->bkgdset(COLOR_PAIR($Curses::UI::color_object->get_color_pair($this->{-fg}, $this->{-bg})));
            }
            &$old_draw(@_);
        };
    }

    my $lower_height = int($cui->{-height} * 0.25);
    my $half_width   = int($cui->{-width} * 0.5);

    $sv_win = $cui->add(
        'sv_win', 'Window',
        -padtop    => 1,
        -padbottom => $lower_height,
        -border    => 0,
        -ipad      => 0,
        -title     => 'Source',
    );
    $sv = $sv_win->add(
        'sv', 'Devel::PDB::SourceView',
        -border => 1,

        #-padbottom => 3,
        window_style(),
    );

    $lower_win = $cui->add(
        'lower_win', 'Window',
        -border => 0,
        -y      => -1,
        -height => $lower_height,
        window_style(),
    );

    $auto_win = $lower_win->add(
        'auto_win', 'Window',
        -border => 1,
        -y      => -1,
        -width  => $half_width,
        -title  => 'Auto',
        window_style(),
    );
    $padvar_list = $auto_win->add(
        'padvar_list', 'Devel::PDB::NamedListbox',
        -readonly   => 1,
        -sort_key   => 'name',
        -named_list => \@padlist_disp,
    );
    $padvar_list->userdata($cui);

    $watch_win = $lower_win->add(
        'watch_win', 'Window',
        -border  => 1,
        -x       => -1,
        -y       => -1,
        -padleft => $half_width,
        -title   => 'Watch',
        window_style(),
    );
    $watch_list = $watch_win->add(
        'watch_list', 'Devel::PDB::NamedListbox',

        # -sort_key   => 'name', # For sorting by name
        -named_list => \@watch_exprs,
    );

    my $fConfig = config_file("conf");

    my @aFile       = ();
    my @aEdit       = ();
    my @aView       = ();
    my @aExecution  = ();
    my @aBreakpoint = ();
    my @aSettings   = ();

    set_key_binding(\&ui_db_help, "Keys", "Keys help", "\cK");
    set_key_binding(sub { shift->getobj('menu')->focus }, "Menu", "Main menu", KEY_F(10));

    # Submenu - File
    push(@aFile, set_key_binding(sub { db_view_std_files(0); $sv_win->focus; }, "ViewSTDFiles", "View STD* files", KEY_F(4)));

    push(
        @aFile,
        set_key_binding(
            sub {
                if ($ui_window_focused == 2) {
                    $update_watch_list = 1;
                    return;
                }

                my $ret = $cui->dialog(
                    -title   => 'Restarting program',
                    -buttons => [{
                            -label    => '< Save config first >',
                            -value    => 1,
                            -shortcut => 's'
                        },
                        {   -label    => '< Restart only >',
                            -value    => 2,
                            -shortcut => 'r'
                        },
                        {   -label    => '< Exit - Return >',
                            -value    => 0,
                            -shortcut => 'x'
                        },
                    ],
                    -message => 'Choose option to restarting program',
                    window_style(),
                );
                if ($ret) {
                    save_state_file($fConfig) if ($ret == 1);
                    $db_exit = 1;
                    DoRestart();
                }
            },
            "Restart",
            "Restart program",
            "\cR"
        ));
    push(
        @aFile,
        set_key_binding(
            sub {
                my $filename = $cui->filebrowser(
                    -title => "Find and load Perl module from file ",
                    -mask  => [['\.p[lm]$', 'Perl modules']],
                    DB::window_style(),
                );
                if ($filename) {
                    if (!exists($main::{"_<$filename"})) {

                        # Delete dir from modules in actuall directory
                        my $dir = getcwd();
                        if ($dir) {
                            $dir .= "/";
                            $filename =~ s/$dir//;
                        }
                        require $filename;
                    }
                    my $source = $current_source = get_source($filename);
                    $sv->source($source) if $source;
                    $sv->intellidraw;
                }
                $sv_win->focus;
            },
            "Filebrowser",
            "Find and load Perl module via browser",
            "\cF"
        ));
    push(
        @aFile,
        set_key_binding(
            sub { ui_open_file('Compiled Files', \@compiled); },
            "FilesCompiled", "Show 'Compiled Files' Dialog",
            KEY_F(11)));
    push(
        @aFile,
        set_key_binding(
            sub { ui_open_file('Opened Files', [keys(%sources)]); },
            "FilesOpened", "Show 'Opened Files' Dialog",
            KEY_F(12)));
    push(@aFile, set_key_binding(\&ui_db_export, "Export", "Export information", "\cY"));
    push(
        @aFile,
        set_key_binding(
            sub {
                redrawwin($stdscr);
                ui_update_watch_list();
                refresh_stack_menu();
                $cui->draw;
            },
            "Refresh",
            "Refresh windows",
            "\cN"
        ));
    push(@aFile, set_key_binding(\&ui_db_quit, "Quit", "Quit the debugger", "\cQ", "\cC"));

    # Submenu - Execution
    push(@aExecution, set_key_binding(\&db_cont,      "Continue", "Run|Continue execution", KEY_F(5)));
    push(@aExecution, set_key_binding(\&db_step_out,  "StepOut",  "Step Out",               KEY_F(6)));
    push(@aExecution, set_key_binding(\&db_step_in,   "StepIn",   "Step In",                KEY_F(7)));
    push(@aExecution, set_key_binding(\&db_step_over, "StepOver", "Step Over",              KEY_F(8)));
    push(
        @aExecution,
        set_key_binding(
            sub {
                if ($ui_window_focused == 2) {
                    db_edit_watch_expr($watch_list);
                } else {
                    ui_text_editor(1);
                }
            },
            "ArgumentsEdit",
            "Edit program paramaters or watched variable",
            "\cE"
        ));
    push(@aExecution, set_key_binding(sub { ui_text_editor(2); }, "EnviromentsEdit", "Edit enviroment paramaters", "\cM"));
    push(
        @aExecution,
        set_key_binding(
            sub {
                my $ret = $cui->question(
                    -title    => 'Command Execution',
                    -question => 'Please enter an command to enter',
                    DB::window_style(),
                );
                $usercontext = $ret if ($ret);
            },
            "RunCommand",
            "Run perl command",
            "\cP"
        ));

    # Submenu - Breakpoint
    push(@aBreakpoint,
        set_key_binding(sub { set_active_window(1); db_toggle_break(0, undef) }, "Breakpoint", "Toggle Breakpoint", KEY_F(9)));
    push(
        @aBreakpoint,
        set_key_binding(
            sub { set_active_window(1); db_toggle_break(1, undef) },
            "BreakpointCode", "Toggle Breakpoint Code", "\cO"
        ));
    push(@aBreakpoint, set_key_binding(sub { db_add_watch_expr(undef) }, "WatchExpression", "Add watch expression", "\cW"));
    push(@aBreakpoint, set_key_binding(\&ui_list_breakpoints, "ListBreakpoints", "List all breakpoints", "\cB"));
    push(@aBreakpoint, set_key_binding(\&clearalldblines, "ClearBreakpoints", "Clear all breakpoints"));
    push(@aBreakpoint,
        set_key_binding(sub { @watch_exprs = (); $update_watch_list = 1; }, "ClearWatches", "Clear all watches"));
    push(
        @aBreakpoint,
        set_key_binding(
            sub { &clearalldblines(); @watch_exprs = (); $update_watch_list = 1; },
            "ClearAll", "Clear all settings", "\cX"
        ));

    # Submenu - Settings
    push(
        @aSettings,
        set_key_binding(
            sub {
                my $ret = $cui->dialog(
                    -title   => 'Load saved config files',
                    -buttons => [{
                            -label    => '< User conf >',
                            -value    => 1,
                            -shortcut => 'u'
                        },
                        {   -label    => '< Default conf >',
                            -value    => 2,
                            -shortcut => 'd'
                        },
                        {   -label    => '< Exit >',
                            -value    => 0,
                            -shortcut => 'x'
                        },
                    ],
                    -message => 'Do you really want load config?',
                    window_style(),
                );
                if ($ret) {
                    load_state_file($fConfig, ($ret == 2 ? ".rc" : ""));
                    $user_conf_readed = $ret == 1 ? 1 : 0;
                }
            },
            "ConfigLoad",
            "Load config file",
            "\cL"
        ));
    push(
        @aSettings,
        set_key_binding(
            sub {
                save_state_file($fConfig)
                  if $cui->dialog(
                    -title   => 'Save config file',
                    -buttons => ['yes', 'no'],
                    -message => 'Do you really want save config?',
                    window_style(),
                  );
            },
            "ConfigSave",
            "Save config file",
            "\cS"
        ));

    # Submenu - View
    push(
        @aView,
        set_key_binding(
            sub {
                my $text;
                local $Data::Dumper::Purity   = 0;
                local $Data::Dumper::Terse    = 1;
                local $Data::Dumper::Indent   = 2;
                local $Data::Dumper::Sortkeys = 1;
                $text = (scalar(@Devel::PDB::script_args) ? Dumper(@Devel::PDB::script_args) : "Not arguments putted");
                dialog_message(
                    -title   => "Arguments",
                    -message => $text
                );

            },
            "Arguments",
            "View program parameters",
            "\cA"
        ));
    push(@aView, set_key_binding(sub { set_active_window(1) }, "WindowSource", "Switch to the Source Code Window", KEY_F(1)));
    push(@aView,
        set_key_binding(sub { set_active_window(2) }, "WindowLexical", "Switch to the Lexical Variable Window", KEY_F(2)));
    push(@aView, set_key_binding(sub { set_active_window(3) }, "WindowWatches", "Switch to the Watch Window", KEY_F(3)));
    push(@aView, set_key_binding(sub { ui_view_stack(0) },     "WindowStack",   "View Stack Window",          "\cT"));
    push(@aView, set_key_binding(sub { ui_text_editor(3) },    "ViewVariables", "View special variables",     "\cU"));

    push(@aView,
        set_key_binding(sub { ui_adjust_vert_parts(1) }, "VerticalPartsMin", "Vertical window(Source file) minimize", '{'));
    push(@aView,
        set_key_binding(sub { ui_adjust_vert_parts(-1) }, "VerticalPartsMax", "Vertical window(Source file) maximize", '}'));
    push(@aView,
        set_key_binding(sub { ui_adjust_hori_parts(-1) }, "HorizontalPartsMin", "Horizontal window(Stack) minimize", '['));
    push(@aView,
        set_key_binding(sub { ui_adjust_hori_parts(1) }, "HorizontalPartsMin", "Horizontal window(Stack) maximize", ']'));

    $cui->add(
        'menu',
        'Menubar',
        -menu => [{
                -label   => 'File',
                -submenu => \@aFile,
            },
            {   -label   => 'View',
                -submenu => \@aView,
            },
            {   -label   => 'Execution',
                -submenu => \@aExecution,
            },
            {   -label   => 'Breakpoint',
                -submenu => \@aBreakpoint,
            },
            {   -label   => 'Settings',
                -submenu => \@aSettings,
            },
            {   -label   => 'Help',
                -submenu => [{
                        -label => 'Keys',
                        -value => \&ui_db_help,
                    },
                    {   -label => 'About',
                        -value => sub {
                            dialog_message(
                                -title   => "About",
                                -message => <<EOF
Devel::PDB - A simple Curses-based Perl DeBugger in version $VERSION

PerlDeBugger is a Curses-based Perl debugger with most of the essential functions such as monitoring windows for paddlist, 
call stack, custom watch expressions, etc. 
Suitable for debugging or tracing complicated Perl applications on the spot.

AUTHORS
Ivan Yat-Cheung Wong
Igor Bujna

MODULES
Curses - $Curses::VERSION
Curses:UI - $Curses::UI::VERSION

EOF
                                ,
                                DB::window_style(),
                            );
                        },
                    },
                ]
            },
        ],
        window_style(),
    );

    #open my $fd0, '>stdout';
    #open my $fd1, '>stderr';
    #open STDOUT, ">&$fd0";
    #open STDERR, ">&$fd1";
    #open STDOUT, ">stdout";

    unlink config_file($_) foreach ('stderr', 'stdout');
    open STDERR, ">>" . config_file("stderr");
    open $output, ">>" . config_file("stdout");
    open $stdout, ">>&STDOUT";

    select(STDERR);
    $| = 1;
    select(STDOUT);
    $| = 1;

    $inited = 1;

    # Load actual breakpoints and watches
    load_state_file(config_file("conf.rc"));
}

#
# Return for given filename which find or creater for given param
#
sub get_source {
    my $filename = shift;
    my $source   = $sources{$filename};

    if (!defined $source) {
        local (*dbline) = $main::{"_<$filename"};
        $sources{$filename} = $source = new Devel::PDB::Source(
            filename => $filename,
            lines    => \@dbline,
            breaks   => \%dbline,
        );
    }

    return $source;
}

#
# Updating watch list in Watches window
#
sub ui_update_watch_list {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Maxdepth;
    local $Data::Dumper::Indent;
    local $Data::Dumper::Sortkeys = 1;

    foreach my $expr (@watch_exprs) {
        $evalarg = $expr->{name};
        my $res = &DB::eval;
        $Data::Dumper::Indent   = 0;
        $Data::Dumper::Maxdepth = 2;
        $expr->{value}          = Dumper $res;
        $Data::Dumper::Indent   = 1;
        $Data::Dumper::Maxdepth = 0;
        $expr->{long_value}     = Dumper $res;
    }

    $watch_list->update;
}

#
# Perl Debugger methods
#
my @saved;

sub save {
    @saved = ($@, $!, $,, $/, $\, $^W);
    $,     = '';
    $/     = "\n";
    $\     = '';
    $^W    = 0;
}

sub eval {
    ($@, $!, $,, $/, $\, $^W) = @saved;
    my $res = eval "package $package; $evalarg";

    #my $res = eval 'no strict;($@, $!, $^E, $,, $/, $\, $^W) = @saved;' . "package $package;$evalarg ;";

    save;
    $res;
}

# Main method which is load when program started, stopped or step in position where is breakpoint
sub DB {
    return if $exit;
    save;
    init if !$inited;

    RESTART:
    open STDOUT, ">>&", $stdout;

    ($package, $filename, $line) = caller;

    my $scope = $current_sub ? $current_sub : $package;
    my $renew = !defined $padlist_scope || $scope ne $padlist_scope;
    if ($renew) {
        %padlist       = ();
        @padlist_disp  = ();
        $padlist_scope = $scope;
    }

    # BUGS:
    # compadlist not return, not defined variables.
    # Variables must be defined via (my,our,....etc) or 'use strict;' on yours script
    {
        my ($names, $vals) =
          $scope eq 'main'
          ? comppadlist->ARRAY
          : svref_2object(\&$scope)->PADLIST->ARRAY;
        my @names = $names->ARRAY;
        my @vals  = $vals->ARRAY;
        my $count = @names;

        refresh_stack_menu();

        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Maxdepth;
        local $Data::Dumper::Indent;
        local $Data::Dumper::Sortkeys = 1;

        my %h_pd = map { $_->{name} => $_ } @padlist_disp;

        for (my ($i, $j) = (0, 0); $i < $count; $i++) {
            my $sv = $names[$i];
            next if class($sv) eq 'SPECIAL';
            my $name = $sv->PVX;
            $Data::Dumper::Indent   = 0;
            $Data::Dumper::Maxdepth = 2;
            my $val = Dumper $vals[$i]->object_2svref;
            $val =~ s/^\\// if class($sv) ne 'RV';
            $Data::Dumper::Indent   = 1;
            $Data::Dumper::Maxdepth = 0;
            my $long_val = Dumper $vals[$i]->object_2svref;
            $long_val =~ s/^\\// if class($sv) ne 'RV';

            if ($renew || $val ne $padlist{$name}) {
                my $rh = {name => $name, value => $val, long_value => $long_val};
                $padlist_disp[$j] = $rh;
                $padlist{$name}   = $val;
                $h_pd{$name}      = $rh;
            }
            ++$j;
        }

        # Sorting values in stack by name
        @padlist_disp = ();
        @padlist_disp = sort { $a->{name} cmp $b->{name} } values %h_pd;

        $padvar_list->update($renew);
    }

    #local (*dbline) = $main::{"_<$filename"};
    $sv->source($current_source = get_source($filename));
    $current_source->current_line($line);

    ui_update_watch_list;

    $yield = 0;

    # Breakpoint with action
    my $brkp = $current_source->ret_line_breakpoint();
    my ($stop, $action) = $brkp ? split(/\0/, $brkp) : ();
    if ($action) {
        my $res = eval "return 1 if ($action); return 0;\n";
        if ($@) {
            my $str = $@;
            db_toggle_break(1, \$str);
        }
        $yield = 1 unless ($res);
    }

    $new_single = $single;
    $cui->focus(undef, 1);
    $cui->draw;
    $update_watch_list = 0;
    while (!$yield) {

        # Wait for any key
        $cui->do_one_event;
        if ($update_watch_list) {
            ui_update_watch_list;
            $cui->draw;
        }

        if ($usercontext) {    # User eval
                               #my $usc =  'no strict;($@, $!, $^E, $,, $/, $\, $^W) = @saved;' . "package $package;";
                               #my $arg = "\$^D = \$^D | \$DB::db_stop;\n$usercontext";
                               #eval "$usc $arg;\n";
            eval "$usercontext;\n";
            print_error($@) if ($@);
            $usercontext = undef;
            goto RESTART;
        }
    }
    $single = $new_single;

    open STDOUT, ">>&", $output;
    ($@, $!, $,, $/, $\, $^W) = @saved;
}

sub sub {
    my ($ret, @ret);

    local $current_sub = $sub;
    local $stack_depth = $stack_depth + 1;
    $#stack = $stack_depth;
    $stack[-1] = $single;
    $single &= 1;

    if (wantarray) {
        no strict;
        @ret = &$sub;
        use strict;
        $single |= $stack[$stack_depth--];
        @ret;
    } else {
        if (defined wantarray) {
            no strict;
            $ret = &$sub;
            use strict;
        } else {
            no strict;
            &$sub;
            use strict;
            undef $ret;
        }

        $single |= $stack[$stack_depth--];
        $ret;
    }
}

sub postponed {
    my $file = shift;
    push @compiled, $$file;

    my $key = "_<" . $$file;
    return if (!exists($postponed_file{$key}));

    set_breakpoints($key, $postponed_file{$key});
    delete($postponed_file{$key});

}

package Devel::PDB;

1;

__END__

=head1 NAME

Devel::PDB - A simple Curses-based Perl DeBugger

=head1 SYNOPSIS

    perl -d:PDB foo.pl

=head1 DESCRIPTION

PerlDeBugger is a Curses-based Perl debugger with most of the
essential functions such as monitoring windows for paddlist,
call stack, custom watch expressions, etc. 
Suitable for debugging or tracing complicated Perl applications on the spot.

=begin html

<style>
table.screen tr td, .normal {
    font-family: monospace;
    font-size: 10pt;
    font-weight: bold;
    background-color: #B2B2B2;
    color: #4545B2
}
.border {
    background-color: #4545B2;
    color: #B2B2B2;
}
.caption {
    color: #FFFFFF;
}
</style>
<table class="screen" cellspacing="0" cellpadding="0">
<tr><td>&nbsp;&nbsp;File&nbsp;&nbsp;View&nbsp;&nbsp;Execution&nbsp;&nbsp;Breakpoint&nbsp;&nbsp;Settings&nbsp;&nbsp;Help&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td></tr>
<tr><td><span class="border">&nbsp;<span class="caption">&nbsp;a.pl:5&nbsp;</span>----------------------------------------------------------------------&nbsp;</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;use&nbsp;Devel::PDB;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;#!/usr/bin/perl&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span><span class="border">&nbsp;&nbsp;<span class="normal">m</span>y&nbsp;$a&nbsp;=&nbsp;test();&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</span>&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;print&nbsp;"$a\n";&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;sub&nbsp;test&nbsp;{&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my&nbsp;$hey&nbsp;=&nbsp;10;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;my&nbsp;$guys_this_is_long&nbsp;=&nbsp;20;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;test2();&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;}&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;sub&nbsp;test2&nbsp;{&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">&nbsp;------------------------------------------------------------------------------&nbsp;</span></td></tr>
<tr><td><span class="border">&nbsp;<span class="caption">&nbsp;Auto&nbsp;</span>--------------------------------&nbsp;&nbsp;<span class="caption">&nbsp;Watch&nbsp;</span>-------------------------------&nbsp;</span></td></tr>
<tr><td><span class="border">|</span>$a&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;undef&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span><span class="border">|</span>-&nbsp;no&nbsp;values&nbsp;-&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span><span class="border">|</span>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<span class="border">|</span></td></tr>
<tr><td><span class="border">&nbsp;--------------------------------------&nbsp;&nbsp;--------------------------------------&nbsp;</span></td></tr>
</table>

=end html

=head2 FUNCTIONS

PerlDeBugger currently can:

=over

=item *

step-over, step-in, step-out, run

=item *

set/remove breakpoint

=item *

Evaluate breakpoint

=item *

automatic display of lexical variables

=item *

add/remove custom watch expression

=item *

show/open compiled files

=item *

Stack Trace Window

=item *

Immediate Window for executing arbitrary perl statement

=item *

Other functionalities

=back

=head2 KYES BINDING - standart key

=over

=item Global

=over

=item WindowSource - F1

Switch to the Source Code Window

=item WindowLexical - F2

Switch to the Lexical Variable Window

=item WindowWatches - F3

Switch to the Watch Window

=item ViewSTDFile - F4

Views STDOUT or STDERR file

=item Continue - F5

Continue execution

=item StepOut - F6

Step Out

=item StepIn - F7

Step In

=item SteOver - F8

Step Over

=item Breakpoint - F9

Toggle Breakpoint. Set or remove breakpoint on cursor position.

=item Menu - F10

Open main - top menu

=item FilesCompiled - F11

Show 'I<Compiled Files>' Dialog

=item FilesOpened - F12

Show 'I<Opened Files>' Dialog

=item Quit - Ctrl+Q, Ctrl+C

Quit the debugger

=item BreakpointCode - Ctrl+O

Add/Edit/Remove breakpoint with condition on given line. Can be also removed by F9 - Breakpoint

=item Refresh - Ctrl+N

Refresh all window contents

=item Export - Ctrl+Y

Export information to file from actual source and stack variables or watches

=item WatchExpression - Ctrl+W

Add watch expression

=item Restart - Ctrl+R

Restart program

=item RunCommand - Ctrl+P

Add commands to runned perl script

=item Arguments - Ctrl+A

View arguments(parameters) of runned program

=item ArgumentsEdit - Ctrl+E

Edit arguments(parameters) of runned program

=item EnviromentsEdit - Ctrl+M

Edit enviroments

=item Filebrowser - Ctrl+F

Find Perl module and load this module

=item WindowStack - Ctrl+T

View stack of runned program

=item ConfigSave - Ctrl+S

Save breakpoints and watches to config file

=item ConfigSave - Ctrl+L

Load breakpoints and watches from config file

=item ViewVariables - Ctrl+U

View special variables

=item ListBreakpoints - Ctrl+B

List all breakpoints in files and position

=item ClearBreakpoints -

Clear all breakpoints

=item ClearWatches - 

Clear all watches

=item ClearAll - Ctrl+X

Clear all settings (breakpoints and watches)

=item VerticalPartsMin - {

Minimized window in vertical size

=item VerticalPartsMax - }

Maximized window in vertical size

=item HorizontalPartsMin - [

Minimized window in horizontal size

=item HorizontalPartsMax - ]

Maximized window in horizontal size

=back

=item Source Code Window

=over

=item UP/DOWN/LEFT/RIGHT/PAGE UP/PAGE DOWN

Move the cursor

=item H/J/K/L/Ctrl+F/Ctrl+B

If you use VI, you will know

=item /

Search using a RegEx in the current opened file

=item n

Search Next

=item N

Search Previous

=item Ctrl+G

Goto a specific line

=back

=item Lexical Variable Window / Watch Window

=over

=item UP/DOWN

Move the cursor

=item ENTER

Show the Data::Dumper output of the highlighted item in a scrollable dialog

=item DEL

Remove the highlighted expression (Watch Window only)

=back

=item Compiled File Dialog / Opened File Dialog

=over

=item TAB

Toggle the focus between the file list and the filter

=item ENTER

Select the highlighted file or apply the filter to the file list

=item F6, Ctrl+S, Ctrl+L

Export everything from window to given file

=back

=back

=head2 Config files

Files will be created in directory when program is run .
If in enviroment exist C<PDB_use_HOME> than everything is created into ~/.PDB directory.
Every file begin with program name and continue with:

=over

=item -conf

Configuration files of saved brakpoints and watches

=item -[stdout|stderr]

Output standart STD files from runned program

=item ~/.PDB.keys

Configuration files of rebinded keys. 
For function keys is FX and for Cotrol keys is Control-X.

For example keys 'F10' for open Menu and keys 'Ctrl+C','Ctrl+Q','Q' for Quit.

Menu=F10
Quit=Control-C,Control-Q,Q

=item ~/.PDB.colours

Configuration of own colours as defined in Curses::UI::Color.
Each line has one definition, where frst is key and second is colour with space separattor.

For example set general foreground and background color as RED on WHITE:

-fg red
-bg white

=back

=head1 SEE ALSO

L<perldebug>

=head1 AUTHORS

Ivan Yat-Cheung Wong E<lt>email (at) ivanwong.infoE<gt>

Igor Bujna E<lt>igor.bujna (at) post.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Ivan Y.C. Wong, Igor Bujna

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

