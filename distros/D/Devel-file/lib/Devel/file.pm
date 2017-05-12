package Devel::file;

=head1 NAME

Devel::file - show source lines around errors and warnings

=head1 VERSION

Version 0.01 - alpha, more of a sketch that a module

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    $ perl -d:file -we 'eval { 12/1 };' -e '/a/;' -e 'die 123'
    Useless use of a constant in void context at -e line 1.
    =W=  -e:1
      1=> eval { 12/1 };
      2:  /a/;
    ...
    Use of uninitialized value in pattern match (m//) at -e line 2.
    =W=  -e:2
      1:  eval { 12/1 };
      2=> /a/;
      3:  die 123
    ...
    123 at -e line 3.
    =E=  -e:3
      2:  /a/;
      3=> die 123
    ...

    perl -d:file script.pl
    PERL5OPT='-d:file' script.pl
    perl -MDevel::file script.pl # run without debugger

=head1 DESCRIPTION

Devel::file appends source code to warnings and fatal errors
as a potential debugging aid.  It provides handlers for die and warn
in order to do this.

This module is still in alpha and is liable to change.

=head1 AUTHOR

Brad Bowman, C<< <perl-cpan at bereft.net> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-devel-file at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-file>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Brad Bowman, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
use strict;
use warnings;
use Carp qw(carp);

my $Verbose = 0;
my $Context = 1;
my $Debug = 0; # debug this module
my $ShowBoth = 0;
my $Formatter = \&format_line;

my $have_debug_info = 0;
my $have_io_all = 0;

# What should $Debug do? make development easier
sub mywarn {
    print STDERR @_, "\n";
}

# minimal "debugger" to use -d and gather the precious things, see perlguts
sub DB::DB {}

sub import {
    my $class = shift;

    $class->_process_options(@_);
    $class->enable();
}

sub _process_options {
    my $class = shift;

    # short options for -d:file=v style
    while ($_ = shift) {
        if (/^v(erbose)?$/) {
            $Verbose = 1;
        } elsif (/^C(ontext)?(\d+)$/) { # C grep-style (AB?)
            $Context = $2;
        } elsif (/^D(ebug)?$/) { # C grep-style (AB?)
            $Debug = 1;
        } elsif (/^ShowBoth(?:=(\d))?$/) { # just for comparison
            $ShowBoth = defined ($1) ? $1 : 1;
        } else {
            carp "Unknown option '$_'";
        }
    }
}

my ($old_warn, $old_die);
sub enable {
    my $class = shift;

    # perl -d:file -le 'print $^P' ==> 831
    if ($^P != 0) { # debugging enabled XXX
        $have_debug_info = 1;
    }

    if ( $ShowBoth || !$have_debug_info ) {
        if ( !$INC{'IO/All.pm'} && !eval 'use IO::All; 1;' ) {
            mywarn "Can't setup $class, No IO::All $@" if $Verbose; 
            return;
        } else {
            $have_io_all = 1;
        }
    }

    if ($Debug) {
        mywarn "$class: using IO::All" if $have_io_all;
        mywarn "$class: using debugger source" if $have_debug_info;
    }

    # XXX Separate for die?
    if ( defined $SIG{__WARN__} && ($SIG{__WARN__} eq \&warn_handler) ) {
        mywarn "$class: handler already installed" if $Debug;
        return;
    }
    $old_warn = $SIG{__WARN__} if $SIG{__WARN__};
    $old_die  = $SIG{__DIE__}  if $SIG{__DIE__};

    $SIG{__WARN__} = \&warn_handler;
    $SIG{__DIE__} = \&die_handler;
}

sub disable {
    my $class = shift;

    return unless $SIG{__WARN__} eq \&warn_handler;
    $SIG{__WARN__} = $old_warn || '';
    $SIG{__DIE__} = $old_die || '';
    $old_warn = $old_die = undef;
}

sub die_handler {

    # Don't process if this is a die in an eval
    # (constant folded evals at compile time: eval {1/0})
    if (defined($^S) && $^S == 1) {
        mywarn "In eval, calling continuation" if $Debug;

        $old_die ? goto &$old_die : die @_;

        mywarn __PACKAGE__ . "This should never appear";
    } else {
        @_ = handler(1 => @_);
    }

    # goto means call stack is cleaner for diagnostics, etc.
    $old_die ? goto &$old_die : die @_;

    # $old_die ? $old_die->(@_) : die @_;
    # goto prevents: perl -Mdiagnostics -MDevel::file -e '12/0'
    #  at /home/bsb/perl-modules/devel-file/lib/Devel/file.pm line 150
    #   Devel::file::die_handler('Illegal division by zero at -e line 1 ...
}

sub warn_handler {
    local $SIG{__WARN__}; # needed to avoid recursion

    @_ = handler(0 => @_);

    if ($old_warn) {
        $old_warn->(@_);
    } else {
        warn @_;
    }
}

sub handler {
    my $in_die = shift;
    no warnings 'uninitialized';

    my $e = shift;  # $e may be an object, 
                    # warn @list is already concatenated
    my $c = $Context;
    $a = $b = $c; # before and after

    # t/syn1.pl has two errors on the line, same file, near each other
    # many errors could overwhelm, only show the first?
    my @locations = $e =~ /at (.+?) line (\d+)[.,]/g;

    mywarn "Original error [[$e]]" if $Debug;
    mywarn "Found: @locations" if $Debug;

    # TODO merge multiple locations in one file
    # how this is handled depends on how things are grouped by perl
    # all syntax errors for a file together or individually
    # (we don't gather them and post-process)
    # I suspect dies come as one extended last gasp, but warns may
    # one-by-one

    my $type = ($in_die) ? 'E' : 'W'; # distinguish warn & die?

    while ( my ($file, $line) = splice(@locations, 0, 2) ) {

        my $target = $line;
        my $from = $line - $b;
        my $to   = $line + $a;
        $from = 1 if $from < 1; # line numbers are 1 based
        # can't tell if $to is past the end of file here

        mywarn "**($file)[$line] $from - $to" if $Debug;

        my $lines;
        if ($have_debug_info) {
            $lines = _debugger_get_lines($file,$from,$to,$target);
        }
        if (($ShowBoth || !$have_debug_info) && $have_io_all) {
            $lines =    _ioall_get_lines($file,$from,$to,$target);
        }

        # This is caught at enable time, I think... local = ???
        # if ($Debug && (!$have_debug_info) && !$have_io_all) { }

        if ($lines) {
            $e .= "=$type=  $file:$line\n$lines...\n";
        }
    }

    return $e;
}

# would be good to be extendable eventually (variable values, ??)
# may want access to DB::* info
sub format_line {
    my ($line, $number, $is_target) = @_;

    # choose something rarely at start of lines, and not confusing
    # eg. >=head
    my $mark = ( $is_target ) ? '=>' : ': ';
    # XXX don't need $mark w/o Context

    sprintf "% 3d$mark %s", $number, $line;
}

sub _debugger_get_lines {
    my ($file, $from, $to, $target) = @_;
    no strict 'refs';
    my $file_sym = "::_<$file";

    # -d inserts a "use Devel::file;" magically, don't show it
    # I think it's at line 0 which shouldn't be shown anyway
    #   (See: lib/perl5db.pl line 8802
    #         for ( 1 .. $#{'::_<-e'} ) {  # The first line is PERL5DB
    #   )
    #$from++ if $file_sym->[$from] =~ /^use Devel::file/;

    # XXX know length of last line number here, 9999 target line
    # (possible line, defined in loop below knows)

    my $lines = '';
    for my $n ($from..$to) {
        my $line = $file_sym->[$n];
        last if !defined($line); # window past end
        chomp($line);

        $lines .= $Formatter->($line, $n, ($n == $target)) . "\n";
    }
    return $lines;
}

sub _ioall_get_lines {
    my ($file, $from, $to, $target) = @_;
    return unless -e $file; # -e file test, ie. not -e cmdline
    my $io = io($file) or return;

    my $lines = '';
    for my $n ($from..$to) {
        my $line = $io->[$n-1]; # array is 0-based
        last if !defined($line); # window past end
        # no chomp needed

        $lines .= $Formatter->($line, $n, ($n == $target)) . "\n";
    }
    return $lines;
}

1;
