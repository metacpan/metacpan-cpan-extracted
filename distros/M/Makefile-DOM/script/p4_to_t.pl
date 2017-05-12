#!/usr/bin/env perl

use strict;
use warnings;

#use Smart::Comments;
use Getopt::Std;
use PPI;
use IPC::Run3;
use File::Path;
use File::Slurp;
use List::MoreUtils qw( any );

my @dummy_comments = (
    '# Create the answer to what should be produced by this Makefile',
    '# The Contents of the MAKEFILE ...',
    '# COMPARE RESULTS',
    '# END of Contents of MAKEFILE',
);

my %opts;
getopts('o:', \%opts);
die "No output directory specified\n"
    unless $opts{o};

my $outdir = $opts{o};
eval { mkpath($outdir) };
if ($@) {
    print "Couldn't create $outdir: $@";
}

my @files = map glob, @ARGV;
die "No input file specified.\n" unless @files;

for my $infile (@files) {
    next if -d $infile or $infile =~ /(\.swp|~)$/;
    my $p4 = read_file($infile);
    $p4 =~ s/<<\s*\\EOF\b/<<'EOF'/smg;
    my $doc = PPI::Document->new(\$p4);
    my @matched;
    for my $elem ($doc->elements) {
        my $content = $elem->content;
        if ($elem->class =~ /Comment$/) {
            chomp($content);
            next if (any { $_ eq $content } @dummy_comments) or
                $content =~ /-\*-perl-\*-/i or
                $content =~ /^\s*#\s*$/ or
                $content =~ /^\s*#\s*-+\s*$/;
            push @matched, $content;
        }
    }
    my $body = process_comments($p4, \@matched);
    my $pattern = <<'_EOC_';
if\s+\(((?:!\s*)?-[a-z])\s+(\S+)\)\s+\{
\s+\$test_passed = (\d+);
\}
_EOC_
    my $count = $body =~ s/$pattern/\&X::file_test('$1', $2, $3);\n/g;

    $pattern = <<'_EOC_';
if \(\(-f (\S+)\)\|\|\(-f (\S+)\)\|\|\(-f (\S+)\)\|\|\(-f (\S+)\)\) \{
\s+\$test_passed = 0;
\}
_EOC_
    $count += 4 * ($body =~ s/$pattern/
        \&X::file_test('-f', $1, 0);
        \&X::file_test('-f', $2, 0);
        \&X::file_test('-f', $3, 0);
        \&X::file_test('-f', $4, 0);/g);
    if ($body =~ /\$test_passed\b/) {
        warn "WARNING: \$test_passed involved...\n";
    }

    warn "info: $count file test(s) found\n" if $count;
    write_file('tmp.pl', preamble(), $body);
    my $stdout;
    run3 [$^X, 'tmp.pl'], undef, \$stdout, undef;
    #print $stdout;
    if ($infile =~ /([^\/\\]+)$/) {
        my $base = $1;
        my $outfile = "$outdir/$base.t";
        warn "Generating $outfile...\n";
        write_file($outfile, $stdout);
    }
}

sub process_comments {
    my $p4 = shift;
    my $matched = shift;
    for my $match (@$matched) {
        (my $value = $match) =~ s/^#\s+//g;
        (my $quoted = $value) =~ s/\\/\\\\/g;
        $quoted =~ s/'/\\'/g;
        if ($p4 =~ s/\G(.*?)\Q$match\E/${1}\&X::comment('$quoted');/ms) {
        } else {
            die "Can't find matched comment '$match' in the source";
        }
    }
    $p4;
}

sub preamble {
    return <<'_EOC_';
use strict;
use warnings;

package X;

use File::Slurp;

our ($block, @blocks, %utouch);
our $count = 0;
our $extra_tests = 0;

sub file_test ($$$) {
    my ($op, $file, $passed) = @_;
    if ($op eq '-f') {
        if ($passed) {
            $X::block->{found} .= " $file";
        } else {
            $X::block->{not_found} .= " $file";
        }
        $extra_tests++;
    } else {
        die "Not supported yet: $op $file $passed";
    }
}

sub comment ($) {
    my $cmt = shift;
    if ($cmt =~ /^TEST\s+#?\d+\b/i) {
        $X::block->{name} = $cmt;
    } else {
        $X::block->{description} .= "$cmt\n"
    }
}

package main;

#use Smart::Comments;
use subs qw(unlink cwd);
use Test::MockClass qw(Cwd);

my $makefile = 'test.mk';
my $mkpath = '#MAKE#';
my $make_path = 'make';
my $workdir = '.';
my $pathsep = '/';
my $description = '';
my $details = '';
my ($answer, $example);

my $delete_command = 'rm';
my $rm_command = 'rm';
my $has_POSIX = eval { require "POSIX.pm" };
my $parallel_jobs = 1;
my $make_name = '#MAKE#';
my $port_type = ($^O eq 'MSWin32' || $^O eq 'Cygwin') ? 'MSWin32' : 'UNIX';
my %extraENV = ();
my $pwd = '#PWD#';

# local vars used by the test scripts
my (@touchedfiles, $VP, $cleanit_error, $delete_error_code);
$delete_error_code = 2;

my $test_passed;
my $vos = 0;

sub cwd {
    #die "Called!";
    "#PWD#";
}

sub resetENV () {
    %extraENV = ();
}

sub get_tmpfile {
    $makefile
}

sub unlink {
    #die "unlink called!";
    rmfiles(@_);
}

sub rmfiles {
    for my $file (@_) {
        if (!exists $utouch{$file}) {
            warn "WARNING: removing file $file which is not touched before\n";
        } else {
            delete $utouch{$file};
        }
    }
}

sub utouch ($@) {
    my $time = shift;
    for my $file (@_) {
        $X::utouch{$file} = $time;
    }
}

sub touch ($@) {
    utouch(0, @_);
}

sub get_logfile {
    1;
}

sub run_make_with_options ($$$$) {
    my $infile = shift;
    $X::block->{filename} = $infile;
    $X::block->{options} = shift;
    shift;
    $X::block->{error_code} = shift;
    $X::block->{source} = X::read_file($infile) if $infile;
    $X::block->{utouch} = {%X::utouch};
    $X::block->{env} = {%extraENV};
}

sub compare_output ($$) {
    $X::block->{stdout} = shift;
    push @X::blocks, $X::block;
    $X::block = {};
}

sub run_make_test ($$$@) {
    my $source = shift;
    if (!defined $source) {
        $source = $X::prev_src;
    } else {
        $X::prev_src = $source;
    }
    $X::block->{source} = $source;
    $X::block->{options} = shift;
    $X::block->{stdout} = shift;
    my $error_code = shift;
    $error_code = 0 if !defined $error_code;
    $X::block->{error_code} = $error_code;
    $X::block->{utouch} = {%X::utouch};
    $X::block->{env} = {%extraENV};
    push @X::blocks, $X::block;
    $X::block = {};
}

END {
    ### @X::blocks;
    package X;

    my $use_ditto = '';
    my @groups;
    my $i;
    my $prev_source;
    my $leading_empty_lines;
    for my $block (@blocks) {
        $i++;

        # === TEST $name
        # $description
        my $str = "=== " . ($block->{name} || "TEST $i:") . "\n";
        $str .= $block->{description} . "\n"
            if $block->{description};

        # --- source
        my $source = $block->{source};
        if (defined $source) {
            if (defined $prev_source and $source eq $prev_source) {
                $use_ditto = "\nuse_source_ditto;\n";
                $str .= "--- source ditto\n";
            } else {
                if ($source =~ /^\n+/s) {
                    $leading_empty_lines = length($&);
                    #die "LEADING: $leading_empty_lines";
                }
                my $opt = '';
                if ($source =~ /#[A-Z]+#/) {
                    $opt = ' preprocess';
                }
                $str .= "--- source$opt\n" . $source . "\n";
            }
        }
        $prev_source = $source;

        # --- pre:  $ExtraENV{$var} = $value
        my %env = %{ $block->{env} };
        if (%env) {
            my @ln;
            while (my ($k, $v) = each %env) {
                $k =~ s/\\/\\\\/g;
                $k =~ s/'/\\'/g;
                $v =~ s/\\/\\\\/g;
                $v =~ s/'/\\'/g;
                push @ln, qq[\$::ExtraENV{'$k'} = '$v'];
            }
            if (@ln > 1) {
                $str .= "\n--- pre\n" . join(";\n", @ln) . ";\n";
            } else {
                $str .= "\n--- pre:  @ln;\n";
            }
        }

        # --- touch
        # --- utouch
        my (@touch, @utouch);
        my %utouch = %{ $block->{utouch} };
        while (my ($file, $time) = each %utouch) {
            if ($time == 0) {
                push @touch, $file;
            } else {
                push @utouch, "$time $file";
            }
        }
        if (@touch) {
            $str .= "--- touch:  " . join(" ", @touch) . "\n";
        }
        if (@utouch == 1) {
            $str .= "--- utouch:  $utouch[0]\n";
        } elsif (@utouch > 1) {
            $str .= "--- utouch\n" . join("\n", @utouch) . "\n";
        }

        # --- options
        # --- goals
        my $options = $block->{options};
        #die $options if $options =~ /other/;
        $options =~ s/\\(.)/$1/g;
        if (defined $options and $options ne '') {
            $options =~ s/^\s+|\s+$//g;
            if ($options =~ /(?:\w+|\S+=\S+|-[\w-]+|\s+)+/) {
                my @args = split /\s+/, $options;
                my @goals = grep { /^\w+$/ } @args;
                $options = join ' ', grep { !/^\w+$/ } @args;
                if (@goals) {
                    $str .= "--- goals:  @goals\n";
                }
            }
            $options =~ s/\n+/ /;
            my $opt = '';
            if ($options =~ /#[A-Z]+#/) {
                $opt = ' preprocess';
            }
            $str .= "--- options$opt:  $options\n"
                if $options !~ /^\s*$/;
        }

        # --- stdout
        my $stdout = $block->{stdout};
        my $stderr;
        $stdout =~
            s{^[^\n]*?(?:Error \d+|No such file or directory|  Stop\.|warning)[^\n]*\n?}
            {$stderr .= $&; ''}emsg;
        if (defined $stdout and $stdout ne '') {
            my $opt = '';
            if ($stdout =~ /#[A-Z]+#/) {
                $opt = ' preprocess';
            }
            if ($stdout =~ /^\s+$/s) {
                $stdout =~ s/\n/\\n/g;
                $str .= qq{--- stdout eval:  "$stdout"\n};
            } else {
                $str .= "--- stdout$opt\n$stdout\n";
            }
        } else {
            $str .= "--- stdout\n";
        }

        # --- stderr
        #$stderr = $block->{stderr};
        if (defined $stderr and $stderr ne '') {
            if ($leading_empty_lines) {
                $stderr =~ s/^(#MAKEFILE#:)(\d): /
                        my $n = $2 - $leading_empty_lines;
                        $n = 1 if $n < 1;
                        $1 . $n . ": "/esmg;
            }
            my $opt = '';
            if ($stderr =~ /#[A-Z]+#/) {
                $opt = ' preprocess';
            }
            $str .= "--- stderr$opt\n$stderr\n";
        } else {
            $str .= "--- stderr\n";
        }

        # --- error_code
        my $error_code = $block->{error_code};
        if (defined $error_code) {
            $error_code >>= 8;
            $str .= "--- error_code:  $error_code\n";
        } else {
            $extra_tests--;
        }

        # --- not_found
        my $not_found = $block->{not_found};
        if (defined $not_found and $not_found !~ /^\s*$/) {
            $str .= "--- not_found: $not_found\n";
        }

        # --- found
        my $found = $block->{found};
        if (defined $found and $found !~ /^\s*$/) {
            $str .= "--- found: $found\n";
        }

        # --- filename
        my $filename = $block->{filename};
        #die $filename;
        if (defined $filename && index($str, $filename) >= 0) {
            $str =~ s/^--- /--- filename:  $filename\n--- /ms;
        }
        push @groups, $str;
    }
    $details =~ s/^/#    /gms;
    $description =~ s/^/#    /gms;
    my $data = join "\n\n\n", @groups;
    my $tests = '';
    if ($extra_tests > 0) {
        $tests = " + $extra_tests";
    } elsif ($extra_tests < 0) {
        $tests = " - " . -$extra_tests;
    }
    print <<_EOF_;
# Description:
$description
#
# Details:
$details

use t::Gmake;

plan tests => 3 * blocks()$tests;
$use_ditto
run_tests;

__DATA__

$data
_EOF_
}

no strict;
no warnings;

_EOC_
}

