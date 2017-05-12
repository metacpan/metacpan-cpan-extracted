###
### $Release: 0.0100 $
### $Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $
### $License: MIT License $
###

use strict;
use warnings;


package Kook::Util;
use Data::Dumper;
use Exporter 'import';
our @EXPORT_OK = qw(read_file write_file ob_start ob_get_clean has_metachar meta2rexp repr flatten first glob2 mtime);

sub read_file {
    my ($filename) = @_;
    open my $fh, '<', $filename  or die "$filename: $!\n";
    read $fh, my $s, (-s $filename);
    close $fh;
    return $s;
}

sub write_file {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename  or die "$filename: $!\n";
    print $fh $content;
    close $fh;
}

my $_ob_buf_;

sub ob_start {
    open(MEM, ">", \$_ob_buf_) or die;
    select(MEM);
}

sub ob_get_clean {
    select(STDOUT);
    return $_ob_buf_;
}

sub has_metachar {
    my ($str) = @_;
    $str =~ s/\\.//g;
    return $str =~ /[\*\?\{]/
    #my @chars = split "", $str;
    #for (my $i = 0, my $n = length($str); $i < $n; $i++) {
    #    my $c = $chars[$i];
    #    if ($c eq '\\') {
    #        $i++;
    #    }
    #    elsif ($c eq '*' || $c eq '?' || $c eq '{') {
    #        return 1;
    #    }
    #}
    #return;
    #my @chars = split "", $str;
    #var $skip = 0;
    #for my $c (@chars) {
    #    if    ($skip)      { $skip = 0; }
    #    elsif ($c eq "\\") { $skip = 1; }
    #    elsif ($c eq '*' || $c eq '?' || $c eq '{') {
    #        return 1;
    #    }
    #}
    #return;
}

sub meta2rexp {
    my ($pattern) = @_;
    my $n = length $pattern;
    my @chars = split "", $pattern;
    my @buf = ('^');
    for (my $i = 0; $i < $n; $i++) {
        my $ch = $chars[$i];
        if ($ch eq '\\') {
            $i++;
            $i < $n  or die "'$pattern': invalid backslash.";
            $ch = $chars[$i];
            push @buf, $ch;
        }
        elsif ($ch eq '*') {
            push @buf, '(.*?)';
        }
        elsif ($ch eq '?') {
            push @buf, '(';
            while ($i < $n && $ch eq '?') {
                push @buf, '.';
                $i++;
                $ch = $chars[$i];
            }
            push @buf, ')';
            $i--;
        }
        elsif ($ch eq '{') {
            my $left = $i;
            my $right;
            $i++;
            while ($i < $n) {
                $ch = $chars[$i];
                if ($ch eq '}') {
                    $right = $i;
                    last;
                }
                $i++;
            }
            $right  or die "$pattern: '{' is not closed by '}'.";
            my $words_str = substr $pattern, $left+1, $right-$left-1;
            my @words = split /,/, $words_str;   #/;
            my @arr = map { quotemeta($_) } @words;
            push @buf, '(', join('|', @arr), ')';
        }
        else {
            push @buf, quotemeta($ch);
        }
    }
    push @buf, '$';
    return join '', @buf;
}

sub repr {
    my ($val) = @_;
    my $d = Data::Dumper->new([$val]);
    $d->Indent(0)->Terse(1)->Useqq(1);
    return $d->Dump;
}

##
## ex.
##    my $arr = ["foo", ["bar", ["baz"]]];
##    my @arr2 = flatten @$arr;
##    print repr(\@arr2);  #=> ["foo", "bar", "baz"]
##
sub flatten {
    my $buf = [];
    _flatten($buf, @_);
    return @$buf;
}

sub _flatten {
    my $buf = shift @_;
    for (@_) {
        ref($_) eq 'ARRAY' ? _flatten($buf, @$_) : push(@$buf, $_);
    }
}

sub first(&@) {
    my ($block, @arr) = @_;
    for (@arr) {
        return $_ if $block->($_);
    }
    return;
}

sub glob2 {
    my ($pattern) = @_;
    my @pair = split /\*\*\//, $pattern, 2;
    return glob($pattern) if @pair == 1;
    my ($dirpat, $basepat) = @pair;
    #$dirpat && $dirpat =~ /\/$/ ?  $dirpat =~ s/\/$//
    #                            :  $dirpat .= '*';
    if ($dirpat && $dirpat =~ /\/$/) {
        $dirpat =~ s/\/$//;
    }
    else {
        $dirpat .= '*';
    }
    my @filenames = $dirpat eq '*' ? glob($basepat) : ();
    for my $path (glob($dirpat)) {
        my @dirlist = _listup($path, 'd');
        for my $dir (@dirlist) {
            my @entries = glob2("$dir/$basepat");
            push @filenames, @entries;
        }
    }
    return @filenames;
}

sub _listup {
    my ($path, $kind, $arr) = @_;
    $arr = [] unless $arr;
    if    ($kind eq 'f') { push @$arr, $path if -f $path; }
    elsif ($kind eq 'd') { push @$arr, $path if -d $path; }
    else                 { push @$arr, $path; }
    if (-d $path) {
        opendir DIR, $path  or die "opendir: $path: $!";
        my @entries = readdir DIR;
        closedir DIR;
        for my $e (@entries) {
            next if $e eq '.' || $e eq '..';
            _listup("$path/$e", $kind, $arr);
        }
    }
    return @$arr;
}

sub mtime {
    my ($filename) = @_;
    return (stat $filename)[9];
}


package Kook::Util::CommandOptionParser;
use Data::Dumper;

sub new {
    my ($class, $optdef_strs) = @_;
    my $this = {
        optdef_strs => $optdef_strs,
    };
    $this = bless $this, $class;
    $this->parse_optdefs($optdef_strs);
    return $this;
}

sub parse_optdefs {
    my ($this, $optdef_strs) = @_;
    my $helps = [];
    my $optdefs = {};
    for my $optdef_str (@$optdef_strs) {
        my ($opt, $desc) = split /:/, $optdef_str, 2;   #/;
        $desc =~ s/^\s+//;
        $desc =~ s/\s+$//;
        my @pair = ($opt, $desc);
        push @$helps, \@pair;
        if ($opt =~ /^-(\w)(?:\s+(.+)|\[(\w+)\])?$/  ||
            $opt =~ /^--([a-zA-Z][-\w]+)(?:=(.+)|\[=(.+)\])?$/ ) {
            my ($name, $arg1, $arg2) = ($1, $2, $3);
            if    ($arg1) { $optdefs->{$name} = $arg1; }
            elsif ($arg2) { $optdefs->{$name} = "[$arg2]"; }
            else          { $optdefs->{$name} = 1; }
        }
        else {
            die "$opt: invalid command option definition.";
        }
    }
    $this->{optdefs} = $optdefs;
    $this->{helps}   = $helps;
    return $optdefs, $helps;
}

sub parse {
    my ($this, $cmd_args, $command) = @_;
    my ($opts, $rests) = $this->_parse($cmd_args, $command, 1);
    return $opts, $rests;
}

sub parse2 {
    my ($this, $cmd_args, $command) = @_;
    my ($opts, $longopts, $rests) = $this->_parse($cmd_args, $command, 0);
    return $opts, $longopts, $rests;
}

sub _parse {
    my ($this, $cmd_args, $command, $check_longopts) = @_;
    my $optdefs = $this->{optdefs};
    my $opts = {};
    my $longopts = {};
    my $N = @$cmd_args;
    my $i;
    for ($i = 0; $i < $N; $i++) {
        my $cmd_arg = $cmd_args->[$i];
        if ($cmd_arg eq "--") {
            $i++;
            last;
        }
        ## long opts
        if ($cmd_arg =~ /^--/) {
            $cmd_arg =~ /^--([a-zA-Z_][-\w]+)(?:=(.*))?$/  or
                die "$cmd_arg: invalid option.\n";
            my $name = $1;
            my $arg  = $2;
            if (! $check_longopts) {
                $arg = 1 unless $arg;
                $longopts->{$name} = $arg;
            }
            elsif (! exists $optdefs->{$name}) {
                die "$cmd_arg: unknown command option.\n";
            }
            elsif ($optdefs->{$name} eq 1) {            # --name
                ! $arg  or die "$cmd_arg: argument is not allowed.\n";
                $opts->{$name} = 1;
            }
            elsif ($optdefs->{$name} eq "[N]") {        # --name[=N]
                if ($arg) {
                    $arg =~ /^[-+]?(\d+)$/  or die "$cmd_arg: integer required.\n";
                    #$arg = 0 + $arg;
                }
                else {
                    $arg = 1;
                }
                $opts->{$name} = $arg;
            }
            elsif ($optdefs->{$name} =~ /^\[.*?\]$/) {  # --name[=arg]
                $opts->{$name} = $arg || 1;
            }
            elsif ($optdefs->{$name} eq "N") {          # --name=N
                $arg  or die "$cmd_arg: argument required.\n";
                $arg =~ /^\d+$/  or die "$cmd_arg: integer required.\n";
                #$opts->{$name} = 0 + $arg;
                $opts->{$name} = $arg;
            }
            else {                                      # --name=arg
                $arg  or die "$cmd_arg: argument required.\n";
                $opts->{$name} = $arg;
            }
        }
        ## short ops
        elsif ($cmd_arg =~ /^-/) {
            my @optchars = split "", $cmd_arg;
            my $n = @optchars;
            for (my $j = 1; $j < $n; $j++) {
                my $ch = $optchars[$j];
                if (! exists $optdefs->{$ch}) {
                    die "-$ch: unknown command option.\n";
                }
                elsif ($optdefs->{$ch} eq 1) {           # -x
                    $opts->{$ch} = 1;
                    next;
                }
                elsif ($optdefs->{$ch} eq "[N]") {       # -x[N]
                    my $arg = substr($cmd_arg, $j+1);
                    if ($arg) {
                        $arg =~ /^\d+$/  or die "-$ch$arg: integer required.\n";
                    }
                    #$opts->{$ch} = $arg ? 0 + $arg : "true";
                    $opts->{$ch} = $arg || 1;
                    last;
                }
                elsif ($optdefs->{$ch} =~ /^\[.*\]$/) {  # -x[arg]
                    $opts->{$ch} = substr($cmd_arg, $j+1) || 1;
                    last;
                }
                else {                                   # -x arg
                    my $arg = substr($cmd_arg, $j+1);
                    if (! $arg) {
                        #assert $j+1 == $n;
                        $i++;   # not $j
                        $i < $N  or die "-$ch: ".$optdefs->{$ch}." required.\n";
                        $arg = $cmd_args->[$i];
                    }
                    if ($optdefs->{$ch} eq "N") {        # -x N
                        $arg =~ /^\d+$/  or die "-$ch $arg: integer required.\n";
                        #$arg = 0 + $arg;
                    }
                    $opts->{$ch} = $arg;
                    last;
                }
            }
        }
        ## short ops
        else {
            last;
        }
    }
    ##
    my @rests = splice @$cmd_args, $i;
    return $opts, \@rests if $check_longopts;
    return $opts, $longopts, \@rests;
}

sub help {
    my ($this, $command, $format) = @_;
    $format = "  %-20s: %s\n" unless $format;
    my @buf = ();
    for my $pair (@{$this->{helps}}) {
        my ($optdef_str, $desc) = @$pair;
        push @buf, sprintf($format, $optdef_str, $desc) if $desc;
    }
    return join "", @buf;
}


1;
