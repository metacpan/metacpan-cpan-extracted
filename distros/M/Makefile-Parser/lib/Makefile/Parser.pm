package Makefile::Parser;

use strict;
use warnings;

use File::Spec;
use Cwd qw/ realpath /;
use List::MoreUtils qw( uniq pairwise ) ;
use Text::Balanced qw( gen_extract_tagged );
#use Smart::Comments;

#our $Debug = 0;
our $Strict = 0;
our $VERSION = '0.216';
our $Error;
our $Runtime = undef;

# usage: $class->new;
sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self = bless {
        _vars    => {},       # all the definitions of variables
        _tars    => undef,    # all the targets
        _default => undef,    # default target
        _depends => {},       # all the dependencies
        _imps    => [],       # targets in implicit rules
    }, $class;
    return $self;
}

my $extract_interp_1 = gen_extract_tagged('\$[(]', '[)]', '');
my $extract_interp_2 = gen_extract_tagged('\$[{]', '[}]', '');

sub _extract_interp {
    my ($res) = $extract_interp_1->($_[0]);
    if (!$res) {
        ($res) = $extract_interp_2->($_[0]);
    }
    $res;
}

# usage: $obj->parse($filename);
sub parse {
    my ($self, $file, $vars) = @_;
    $file ||= 'Makefile';
    my %init_vars = %$vars if $vars;

    $self->{_file} = $file;
    $self->{_vars} = {
        MAKE  => $0,
        CC    => 'cc',
        SHELL => 'sh',
        %init_vars,
    };
    undef $self->{_tars};
    undef $self->{_default};
    $self->{_depends} = {};
    $self->{_imps} = [];

    my $rvars = $self->{_vars};
    my $in;
    unless (open $in, $file) {
        $Error = "Cannot open $file for reading: $!";
        return undef;
    }

    my $state = 'S_IDLE';
    my ($var, $value, $tar_name, $tar, $colon_type, $depends, $cmd);
    my @cmds;
    my %tars;
    #%$rvars = ();
    my $first_tar = 1;
    while (<$in>) {
        next if /^\s*#/ and $state ne 'S_IN_VAL';
        next if /^\s*$/ and $state ne 'S_IN_VAL';
        #$tar_name = '' unless defined $var;
        #warn "(tar: $tar_name) Switching to tate $state with $_";
        #warn $state if $state ne 'S_IDLE';
        chomp;
        #if (/TEST_VERBOSE=/) {
            #### line: $_
            #### state: $state
        #}

        # expand the value of use-defined variables:
        #s/\$[\{\(](\w+)[\}\)]/exists $rvars->{$1} ? $rvars->{$1} : $&/ge;
        $_ = $self->_process_refs($_);

        if (($state eq 'S_IDLE' or $state eq 'S_CMD') and /^(\w+) \s* :?= \s* (.*)$/xo) {
            $var = $1;
            $value = $2;
            #warn "matched $var = $value\n";
            if ($value =~ m{\\\s*$}) {
                $value .= "\n";
                $state = 'S_IN_VAL' ;
            } else {
                $value =~ s/#.*//m;
                $rvars->{$var} = $value;
                ### variable: $var
                ### value: $value
                $state = 'S_IDLE';
            }
            #warn "$1 * $2 * $3";

        } elsif ($state eq 'S_IN_VAL') {
            #warn $1;
            my $line = $_;
            #warn "adding value line $line\n";
            $value .= "$line\n";
            if ($line !~ m{\\\s*$}) {
                $state = 'S_IDLE' ;
                #warn "Processing value '$value'\n";
                $value =~ s/[ \t]*\\\n[ \t]*/ /sg;
                $value =~ s/#.*//smg;
                #warn "Finale value '$value'\n";
                $value =~ s/\n//gs;
                $value =~ s/^\s+|\s+$//gs;
                $rvars->{$var} = $value;
                #warn "$var <=> $value\n";
            }

        } elsif (($state eq 'S_IDLE' or $state eq 'S_CMD') and /^(\.\w+) (\.\w+) \s* (::?)\s*$/xo) {
            $_ = "%$2 $3 %$1\n";
            #warn $_;
            redo;

        } elsif (($state eq 'S_IDLE' or $state eq 'S_CMD') and /^(\S[^:]*) (::?) \s* (.*)$/xo) {
            $tar_name = $1;
            $colon_type = $2;
            $depends = $3;
            $tar_name =~ s/^\s+|\s+$//g;

            my $cmd;
            if ($depends =~ s/;(.*)//) {
                $cmd = $1;
            }

            # Ignore .SUFFIXES currently:
            next if $tar_name eq '.SUFFIXES';

            #warn "Adding target $tar_name...\n";
            $tar = Makefile::Target->new($tar_name, $colon_type);
            if (my $old_tars = $tars{$tar_name}) {
                if ($colon_type eq ':') {
                    $tar->add_prereq($old_tars->[0]->prereqs);
                    if (my @cmd = $old_tars->[0]->commands) {
                        $tar->add_command(@cmd);
                    }
                    @$old_tars = $tar;
                } else {
                    push @$old_tars, $tar;
                }
            } else {
                $tars{$tar_name} = [$tar];
            }
            if ($tar_name =~ m/%/) {
                push @{$self->{_imps}}, $tar_name;
            }
            if ($first_tar) {
                $self->{_default} = $tar;
                $first_tar = 0;
            }
            if ($depends =~ s/\s+\\$//o) {
                $state = 'S_IN_DEPENDS';
            } else {
                $depends =~ s/\^\\$/\\/;
                $state = 'S_CMD';
            }
            my @depends = split /\s+/, $depends;
            map { $self->{_depends}->{$_} = 1 } @depends;
            $tar->add_depend(@depends);
            $tar->add_command($cmd) if defined $cmd;
        }
        elsif ($state eq 'S_IN_DEPENDS' and /^\s+ (.*)$/xo) {
            $depends = $1;
            if ($depends !~ s/\s+\\$//o) {
                $depends =~ s/\^\\$/\\/;
                my @depends = split /\s+/, $depends;
                map { $self->{_depends}->{$_} = 1 } @depends;
                $tar->add_depend(@depends);
                $state = 'S_CMD';
            }
        }
        elsif ($state eq 'S_CMD' and /^\s+(.*)/o) {
            $cmd = $1;
            if ($cmd =~ s/\s+\\$//o) {
                $state = 'S_IN_CMD';
            } else {
                $tar->add_command($cmd);
            }
        }
        elsif ($state eq 'S_IN_CMD' and /^\s+(.*)/o) {
            $cmd .= " $1";
            if ($cmd !~ s/\s+\\$//o) {
                $tar->add_command($cmd);
                $state = 'S_CMD';
            }
        }
        elsif ($Strict) {
            $Error = "syntax error: line $.: $_\n";
            return undef;
        } else {
            warn "I dunno how to do with it: $_\n";
        }
    }
    $self->{_tars} = \%tars;
    $self->post_parse;
    #warn Data::Dumper->Dump([\%tars], ['TARGETS']);
    close $in;
    return $self;
}

sub post_parse {
    my $self = shift;
    my $rdepends = $self->{_depends};
    my $rimps = $self->{_imps};
    for (keys %$rdepends) {
        next if /%/;
        #warn "Trying to match implicit rules one by one against $_...\n";
        $self->solve_imp($_);
    }
    for (@$rimps) {
        delete $self->{_tars}->{$_};
    }
}

sub solve_imp {
    my ($self, $depend) = @_;
    my $rimps = $self->{_imps};
    for my $imp (@$rimps) {
        my $obj = $self->target($imp);
        die "Rules for $imp not found" unless $obj and ref $obj;
        my $regex = quotemeta($imp);
        $regex =~ s/\\%/(.+)/;  # `%' can match any nonempty substring
        #warn "Processing regex $regex...\n";
        if ($depend =~ m/^$regex$/) {
            #warn "Succeeded to match $imp against $depend!\n";
            my $matched_part = $1;
            my $tar = Makefile::Target->new($depend, $obj->colon_type);
            my $dep;
            my @deps = map {
                s/%/$matched_part/;
                $self->{_depends}->{$_} = 1;
                #warn "Recursively solving dependent gole $_...\n";
                $self->solve_imp($_);
                $dep = $_;
                $_
            } $obj->depends;
            $tar->add_depend(@deps);
            my @cmds = map {
                s/\$</$dep/g;
                s/\$\*/$matched_part/g;
                $_
            } $obj->commands;
            $tar->add_command(@cmds);
            $self->{_tars}->{$depend} = [$tar];
        }
    }
}

sub var {
    my ($self, $var) = @_;
    $self->parse if !defined $self->{_file};
    return $self->{_vars}->{$var};
}

sub vars {
    my $self = shift;
    $self->parse if !defined $self->{_file};
    return keys %{$self->{_vars}};
}

sub target {
    my ($self, $tar_name) = @_;
    $self->parse if !defined $self->{_file};
    return $self->{_default} if !defined $tar_name;
    my $tars = $self->{_tars}->{$tar_name};
    $tars ||= [];
    wantarray ? @$tars : $tars->[0];
}

sub targets {
    my $self = shift;
    $self->parse if !defined $self->{_file};
    return map { @$_ } values %{$self->{_tars}};
}

sub roots {
    my $self = shift;
    $self->parse if !defined $self->{_file};
    my %depends = %{$self->{_depends}};
    my %tars = %{$self->{_tars}};
    my @roots = ();
    my ($key, $val);
    while (($key, $val) = each %tars) {
        #next if $key =~ m/%/;
        next if $depends{$key};
        push @roots, $key;
    }
    return @roots;
}

sub error {
    return $Error;
}

sub _solve_refs_in_tokens ($$) {
    my ($self, $tokens) = @_;
    return '' if !$tokens;
    my $rvars = $self->{_vars};
    my @new_tokens;
    for my $token (@$tokens) {
        if ($token =~ /^\$[{(](.*)[)}]$/) {
            my $s = $1;
            if ($s =~ /^([-\w]+)\s+(.*)$/) {
                my $res = $self->_process_func_ref($1, $2);
                if (defined $res) {
                    push @new_tokens, $res;
                    next;
                }
            } elsif ($s =~ /^(\S+?):(\S+?)=(\S+)$/) {
                my ($var, $from, $to) = ($1, $2, $3);
                my $res = $self->_process_func_ref(
                    'patsubst', "\%$from,\%$to,\$($var)"
                );
                if (defined $res) {
                    push @new_tokens, $res;
                    next;
                }
            }
            if (exists $rvars->{$s}) {
                push @new_tokens, $rvars->{$s};
                next;
            } else {
                # FIXME: undefined var == ''
                #push @new_tokens, '';
                #next;
            }
        } elsif ($token =~ /^\$[@<|]$/) {
            # currently do nothing with the automatic vars
        } elsif ($token =~ /^\$\$$/) {
            push @new_tokens, '$';
            next;
        } elsif ($token =~ /^\$(.)$/) {
            if (exists $rvars->{$1}) {
                push @new_tokens, $rvars->{$1};
                next;
            } else {
                # FIXME: undef var == ''
                # push @new_tokens, '';
                # next;
            }
            ### found single-letter variable: $1
            ### value: $rvars->{$1}
            ### token: $token
        }
        push @new_tokens, $token;
    }
    ### retval: join '', @$tokens
    return join '', @new_tokens;
}

sub _process_refs {
    my ($self, $s) = @_;
    my @tokens = '';
    while (1) {
        if ($s =~ /\G[^\$]+/gc) {
            $tokens[-1] .= $&;
        } elsif (my $res = _extract_interp($s)) {
            push @tokens, $res, '';
        } elsif ($s =~ /\G\$./gc) {
            push @tokens, $&, '';
        } elsif ($s =~ /\G./gc) {
            $tokens[-1] .= $&;
        } else {
            last;
        }
    }
    ### tokens: @tokens
    return $self->_solve_refs_in_tokens(\@tokens);
}

sub _pat2re ($@) {
    my ($pat, $capture) = @_;
    $pat = quotemeta $pat;
    if ($capture) {
        $pat =~ s/\\\%/(\\S*)/g;
    } else {
        $pat =~ s/\\\%/\\S*/g;
    }
    $pat;
}

sub _text2words ($) {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;
    split /\s+/, $text;
}

sub _check_numeric ($$$$) {
    my ($self, $func, $order, $n) = @_;
    if ($n !~ /^\d+$/) {
        warn $self->{_file}, ":$.: ",
            "*** non-numeric $order argument to `$func' function: '$n'.  Stop.\n";
        exit(2);
    }
}

sub _check_greater_than ($$$$$) {
    my ($self, $func, $order, $n, $value) = @_;
    if ($n <= $value) {
        warn $self->{_file}, ":$.: *** $order argument to `$func' function must be greater than $value.  Stop.\n";
        exit(2);
   }
}

sub _trim ($@) {
    for (@_) {
        s/^\s+|\s+$//g;
    }
}

sub _split_args($$$$) {
    my ($self, $func, $s, $m, $n) = @_;
    $n ||= $m;
    my @tokens = '';
    my @args;
    ### $n
    while (@args <= $n) {
        ### split args: @args
        ### split tokens: @tokens
        if ($s =~ /\G\s+/gc) {
            push @tokens, $&, '';
        }
        elsif ($s =~ /\G[^\$,]+/gc) {
            $tokens[-1] .= $&;
        }
        elsif ($s =~ /\G,/gc) {
            if (@args < $n - 1) {
                push @args, [grep { $_ ne '' } @tokens];
                @tokens = '';
            } else {
                $tokens[-1] .= $&;
            }
        }
        elsif (my $res = _extract_interp($s)) {
            push @tokens, $res, '';
        }
        elsif ($s =~ /\G\$./gc) {
            push @tokens, $&, '';
        }
        elsif ($s =~ /\G./gc) {
            $tokens[-1] .= $&;
        }
        else {
            if (@args <= $n - 1) {
                push @args, [grep { $_ ne '' } @tokens];
            }
            last if @args >= $m and @args <= $n;
            warn $self->{_file}, ":$.: ",
            "*** insufficient number of arguments (",
            scalar(@args), ") to function `$func'.  Stop.\n";
            exit(2);
        }
    }
    return @args;
}

sub _trim_tokens ($) {
    my $tokens = shift;
    return if !@$tokens;
    if ($tokens->[0] =~ /^\s+$/) {
        shift @$tokens;
    }
    return if !@$tokens;
    if ($tokens->[-1] =~ /^\s+$/) {
        pop @$tokens;
    }
}

sub _process_func_ref ($$$) {
    my ($self, $name, $args) = @_;
    #### process func ref: $name
    $name = $self->_process_refs($name);
    my @args;
    my $nargs = scalar(@args);
    if ($name eq 'subst') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        ### arguments: @args
        my ($from, $to, $text) = @args;
        $from = quotemeta($from);
        $text =~ s/$from/$to/g;
        return $text;
    }
    if ($name eq 'patsubst') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($pattern, $replacement, $text) = @args;
        my $re = _pat2re($pattern, 1);
        $replacement =~ s/\%/\${1}/g;
        $replacement = qq("$replacement");
        #### pattern: $re
        #### replacement: $replacement
        #### text: $text
        my $code = "s/^$re\$/$replacement/e";
        #### code: $code
        my @words = _text2words($text);
        map { eval $code; } @words;
        return join ' ', grep { $_ ne '' } @words;
    }
    if ($name eq 'strip') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($string) = @args;
        $string =~ s/^\s+|\s+$//g;
        $string =~ s/\s+/ /g;
        return $string;
    }
    if ($name eq 'findstring') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($find, $in) = @args;
        if (index($in, $find) >= 0) {
            return $find;
        } else {
            return '';
        }
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ### regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ### regex: $regex
        my @words = _text2words($text);
        return join ' ', grep /^$regex$/, @words;

    }
    if ($name eq 'filter') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ### regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ### regex: $regex
        my @words = _text2words($text);
        return join ' ', grep /^$regex$/, @words;
    }
    if ($name eq 'filter-out') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($patterns, $text) = @args;
        my @regexes = map { _pat2re($_) }
            split /\s+/, $patterns;
        ### regexes: @regexes
        my $regex = join '|', map { "(?:$_)" } @regexes;
        ### regex: $regex
        my @words = _text2words($text);
        return join ' ', grep !/^$regex$/, @words;
    }
    if ($name eq 'sort') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($list) = @args;
        _trim($list);
        return join ' ', uniq sort split /\s+/, $list;
    }
    if ($name eq 'words') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return scalar(@words);
    }
    if ($name eq 'word') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($n, $text) = @args;
        _trim($n);
        $self->_check_numeric('word', 'first', $n);
        $self->_check_greater_than('word', 'first', $n, 0);
        my @words = _text2words($text);
        return $n > @words ? '' : $words[$n - 1];
    }
    if ($name eq 'wordlist') {
        my @args = $self->_split_args($name, $args, 3);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($s, $e, $text) = @args;
        _trim($s, $e, $text);
        $self->_check_numeric('wordlist', 'first', $s);
        $self->_check_numeric('wordlist', 'second', $e);
        $self->_check_greater_than('wordlist', 'first', $s, 0);
        $self->_check_greater_than('wordlist', 'second', $s, -1);
        my @words = _text2words($text);
        if ($s > $e || $s > @words || $e == 0) {
            return '';
        }
        $e = @words if $e > @words;
        return join ' ', @words[$s-1..$e-1];
    }
    if ($name eq 'firstword') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return @words > 0 ? $words[0] : '';
    }
    if ($name eq 'lastword') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @words = _text2words($text);
        return @words > 0 ? $words[-1] : '';
    }
    if ($name eq 'dir') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { /.*\// ? $& : './' } @names;
    }
    if ($name eq 'notdir') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { s/.*\///; $_ } @names;
    }
    if ($name eq 'suffix') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my $s = join ' ', map { /.*(\..*)/ ? $1 : '' } @names;
        $s =~ s/\s+$//g;
        return $s;
    }
    if ($name eq 'basename') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my $s = join ' ', map { /(.*)\./ ? $1 : $_ } @names;
        $s =~ s/\s+$//g;
        return $s;
    }
    if ($name eq 'addsuffix') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($suffix, $text) = @args;
        #_trim($suffix);
        my @names = _text2words($text);
        return join ' ', map { $_ . $suffix } @names;
    }
    if ($name eq 'addprefix') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($suffix, $text) = @args;
        #_trim($suffix);
        my @names = _text2words($text);
        return join ' ', map { $suffix . $_ } @names;
    }
    if ($name eq 'join') {
        my @args = $self->_split_args($name, $args, 2);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($list_1, $list_2) = @args;
        my @list_1 = _text2words($list_1);
        my @list_2 = _text2words($list_2);
        return join ' ', pairwise {
            no warnings 'uninitialized';
            $a . $b
        } @list_1, @list_2;
    }
    if ($name eq 'wildcard') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($pattern) = @args;
        return join ' ', grep { -e $_ } glob $pattern;
    }
    if ($name eq 'realpath') {
        no warnings 'uninitialized';
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        return join ' ', map { realpath($_) } @names;
    }
    if ($name eq 'abspath') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($text) = @args;
        my @names = _text2words($text);
        my @paths = map { File::Spec->rel2abs($_) } @names;
        for my $path (@paths) {
            my @f = split '/', $path;
            my @new_f;
            for (@f) {
                if ($_ eq '..') {
                    pop @new_f;
                } else {
                    push @new_f, $_;
                }
            }
            $path = join '/', @new_f;
        }
        return join ' ', @paths;
    }
    if ($name eq 'shell') {
        my @args = $self->_split_args($name, $args, 1);
        map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($cmd) = @args;
        my $output = `$cmd`;
        $output =~ s/(?:\r?\n)+$//g;
        $output =~ s/\r?\n/ /g;
        return $output;
    }
    if ($name eq 'if') {
        my @args = $self->_split_args($name, $args, 2, 3);
        #map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        my ($condition, $then_part, $else_part) = @args;
        _trim_tokens($condition);
        $condition = $self->_solve_refs_in_tokens($condition);
        return $condition eq '' ?
                    $self->_solve_refs_in_tokens($else_part)
               :
                    $self->_solve_refs_in_tokens($then_part);
    }
    if ($name eq 'or') {
        my @args = $self->_split_args($name, $args, 1, 1000_000_000);
        #map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        for my $arg (@args) {
            _trim_tokens($arg);
            my $value = $self->_solve_refs_in_tokens($arg);
            return $value if $value ne '';
        }
        return '';
    }
    if ($name eq 'and') {
        my @args = $self->_split_args($name, $args, 1, 1000_000_000);
        #map { $_ = $self->_solve_refs_in_tokens($_) } @args;
        ### arguments for 'and': @args
        my $value;
        for my $arg (@args) {
            _trim_tokens($arg);
            $value = $self->_solve_refs_in_tokens($arg);
            return '' if $value eq '';
        }
        return $value;
    }
    if ($name eq 'foreach') {
        my @args = $self->_split_args($name, $args, 3);
        my ($var, $list, $text) = @args;
        $var = $self->_solve_refs_in_tokens($var);
        $list = $self->_solve_refs_in_tokens($list);
        my @words = _text2words($list);
        # save the original status of $var
        my $rvars = $self->{_vars};
        my $not_exist = !exists $rvars->{$var};
        my $old_val = $rvars->{$var};

        my @results;
        for my $word (@words) {
            $rvars->{$var} = $word;
            #warn "$word";
            push @results, $self->_solve_refs_in_tokens($text);
        }

        # restore the original status of $var
        if ($not_exist) {
            delete $rvars->{$var};
        } else {
            $rvars->{$var} = $old_val;
        }

        return join ' ', @results;
    }
    if ($name eq 'error') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->_solve_refs_in_tokens($text);
        warn $self->{_file}, ":$.: *** $text.  Stop.\n";
        exit(2) if $Runtime;
        return '';
    }
    if ($name eq 'warning') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->_solve_refs_in_tokens($text);
        warn $self->{_file}, ":$.: $text\n";
        return '';
    }
    if ($name eq 'info') {
        my ($text) = $self->_split_args($name, $args, 1);
        $text = $self->_solve_refs_in_tokens($text);
        print "$text\n";
        return '';
    }

    return undef;
}

#######################################

package Makefile::Target;

use overload
    '""'  => sub { shift->name },
    'cmp' => sub { my ($a,$b) = @_; "$a" cmp "$b" },
    'eq'  => sub { my ($a,$b) = @_; "$a" eq  "$b" },
    'lt'  => sub { my ($a,$b) = @_; "$a" lt  "$b" };

# usage: $class->new($name, $colon_type)
sub new {
    my $class = shift;
    my $self = {
        _name => shift,
        _colon_type => shift,
        _commands  => [],
        _depends => [],
    };
    return bless $self, $class;
}

sub name {
    return shift->{_name};
}

sub colon_type {
    return shift->{_colon_type};
}

sub prereqs {
    return @{shift->{_depends}};
}

*depends = \&prereqs;

sub add_prereq {
    push @{shift->{_depends}}, @_;
}

*add_depend = \&add_prereq;

sub commands {
    return @{shift->{_commands}};
}

sub add_command {
    my $self = shift;
    my @cmds = @_;
    my $name = $self->name;
    if ($name !~ m/%/) {
        map { s/\$\@/$self->{_name}/g } @cmds;
    }
    push @{$self->{_commands}}, @cmds;
}

sub run_commands {
    my $self = shift;
    my @cmd = $self->commands;
    for my $cmd (@cmd) {
        my ($quiet, $continue);
        while (1) {
            if ($cmd =~ s/^\s*\@//) {
                $quiet = 1;
            } elsif ($cmd =~ s/^\s*-//) {
                $continue = 1;
            } else {
                last;
            }
        }
        $cmd =~ s/^\s+|\s+$//gs;
        next if $cmd =~ /^$/;
        print "$cmd\n" unless $quiet;
        # currently only 'sh' is specified
        system('/bin/sh', '-c', $cmd);
        if ($? != 0 && !$continue) {
            die "$cmd returns nonzero status value: $?\n";
        }
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Makefile::Parser - A simple parser for Makefiles

=head1 VERSION

This document describes Makefile::Parser 0.216 released on 18 November 2014.

=head1 SYNOPSIS

  use Makefile::Parser;

  $parser = Makefile::Parser->new;

  # equivalent to ->parse('Makefile');
  $parser->parse or
      die Makefile::Parser->error;

  # get last value assigned to the specified variable 'CC':
  print $parser->var('CC');

  # get all the variable names defined in the Makefile:
  @vars = $parser->vars;
  print join(' ', sort @vars);

  @roots = $parser->roots; # Get all the "root targets"
  print $roots[0]->name;

  @tars = $parser->targets;  # Get all the targets
  $tar = join("\n", $tars[0]->commands);

  # get the default target, say, the first target
  # defined in Makefile:
  $tar = $parser->target;

  $tar = $parser->target('install');
  # get the name of the target, say, 'install' here:
  print $tar->name;

  # get the dependencies for the target 'install':
  @depends = $tar->depends;

  # access the shell command used to build the current target.
  @cmds = $tar->commands;

  # parse another file using the same Parser object:
  $parser->parse('Makefile.old') or
    die Makefile::Parser->error;

  # get the target who is specified by variable EXE_FILE
  $tar = $parser->target($parser->var('EXE_FILE'));

=head1 DESCRIPTION

This is a simple parser for Makefiles. At this very early stage, the parser
only supports a limited set of features, so it may not recognize most of the
advanced features provided by certain make tools like GNU make. Its initial
purpose is to provide basic support for another module named
L<Makefile::GraphViz>, which is aimed to render the building process
specified by a Makefile using the amazing GraphViz library. The L<Make>
module is not satisfactory for this purpose, so I decided to build one
of my own.

B<WARNING!!!> This stuff is highly experimental and is currently at B<pre-alpha>
stage, so production use is strongly discouraged. Right now it's just a toy for parsing trivial makefiles.

B<IMPORTANT!!!> If you're looking for something more serious for parsing GNU makefiles, please see L<Makefile::Parser::GmakeDB> instead. The GmakeDB parser has passed 51% of GNU make's official test suite as of this writing.

If you're looking for something that can parse makefiles losslessly,
take a look at the L<Makefile::DOM> module which may fit your needs.

=head2 SYNTAX SUPPORTED

The current parser implementation has been trying to support a common
feature set of both MS NMAKE and GNU make. In the future, different
formats of Makefiles will be
handled by individual subclasses such as Makefile::Parser::Gmake.

=over

=item Variable Definition

    MIN_T_FILES = $(PAT_COVER_FILES) t\optest.t t\my_perl.exe.t t\types.cod.t \
        t\catln.t t\exe2hex.t t\hex2bin.t t\bin2hex.t t\bin2asm.t t\ndisasmi.t \
        t\Idu.t t\pat_tree.t t\state_mac.t t\Idu-Util.t t\cidu.t \
        t\opname.t t\error.t t\operand.t t\01disasm.t t\02disasm.t t\03disasm.t \
        t\disasm_cover.t t\ndisasm.t
    T_FILES = t\main.cod.t t\bin2hex.exe.t t\hex2bin.exe.t $(MIN_T_FILES)
    DIRFILESEP = ^\

"Simply expanded" variables' definition sytax in GUN make is also supported:

    FOO := blah blah blah

which is considered invalid in Win32 NMake. "Recursively expanded" variables are
currently treated as "simply expanded" variables.

Variable redefinition can be handled as well:

    CC = cl

    %.obj : %.c
        $(CC) /nologo /c $<

    CC = gcc

    %.o : %.c
        $(CC) -c $<

Variable expansion sytax

    ${abc}

is accepted, whereas Win32 NMAKE will complain about it.

Currently, environment variables defined in the command-line are not imported.

I have no idea what default value should be assigned to built-in variables like
$(MAKE) and $(CC). Currently they will be left untouched if they're not set
explicitly in the Makefile.

Due to the current implementation, expansion of unrecognized built-in varaibles
and variables not previously defined by Makefile will NOT be performed. This
behavior is different from any practial make tools, but is reasonable at
this early stage of this parser.

=item Explicit Rules

    $(CIDU_DLL) : C\idu.obj C\idu.def
        link /dll /nologo /debug /out:$@ /def:C\idu.def C\idu.obj

    $(CIDU_LIB) : $(CIDU_DLL)

    C\idu.obj : C\idu.c C\idu.h
        cd C
        cl /nologo /c /I . idu.c
        cd ..

    smoke : all pat_cover t\pat_cover.t \
            t/pat_cover.ast.ast
        perl util\run-smoke.pl . smoke.html
        perl txt2html.pl t\*.t t\*.ast

    clean:
        copy t\pat_cover.ast.ast.html ..\ /Y
        $(RM_F) encoding.html encoding.pod state_mac.xml encoding.ast \
            pat_tree.ast state_mac.ast \
            main.cod pat_cover.pod pat_cover.html types.cod \
            hex2bin.exe hex2bin.obj

Specital variable $@ will be expanded using its value in the context.

=item Implicit Rules

=over

=item Pattern Rules

    %.obj : %.asm
        masm /t $<;

    %.exe : %.obj
        link /BATCH /NOLOGO $<;

The special varaibles $< and $* will be expanded according to the context.

=item Old-Fashioned Suffix Rules

Currently only double-suffix rules are supported:

    .SUFFIXES: .obj .asm .exe

    .asm.obj :
        masm /t $<

    .obj.exe :
        link /nologo $<

At this moment, .SUFFIXES is a no-op. So any suffix-like things will be treated as
suffixes, excluding the following example:

    .c.o: foo.h
            $(CC) -c $(CFLAGS) $(CPPFLAGS) -o $@ $<

In suffix rules, B<no> prerequisites are allowed according to most make tools.

=back

=item Substitution References

    objects = foo.o bar.o baz.o
    sources = $(objects:.o=.c)  # foo.c bar.c baz.c

=item Functions

Currently the following GNU make makefile builtin functions are
supported:

=over

=item C< $(subst from,to,text) >

=item C< $(patsubst pattern,replacement,text) >

=item C< $(strip string) >

=item C< $(findstring find,text) >

=item C< $(filter pattern...,text) >

=item C< $(filter-out pattern...,text) >

=item C< $(sort list) >

=item C< $(word n,text) >

=item C< $(words text) >

=item C< $(wordlist s,e,text) >

=item C< $(firstword names...) >

=item C< $(lastword names...) >

=item C< $(dir names...) >

=item C< $(notdir names...) >

=item C< $(suffix names...) >

=item C< $(basename names...) >

=item C< $(addsuffix suffix,names...) >

=item C< $(addprefix prefix,names...) >

=item C< $(join list1,list2) >

=item C< $(wildcard pattern...) >

=item C< $(realpath names...) >

=item C< $(abspath names...) >

=item C< $(if condition,then-part[,else-part]) >

=item C< $(or condition1[,condition2[,condition3...]]) >

=item C< $(and condition1[,condition2[,condition3...]]) >

=item C< $(foreach var,list,text) >

=item C< $(error argument...) >

=item C< $(warning argument...) >

=item C< $(info argument...) >

=item C< $(shell cmd...) >

=back

Please consult the GNU make Manual for details and
also take a look at the following file for some use cases:

L<http://github.com/agentzh/makefile-dom-pm/tree/master/t/gmake/sanity/func-refs.t>

=item Commands after ';'

    all : ; echo 'hello, world!'

Specital variable $@ will be expanded using its value in the context.

=back

For the list of features which will be added very soon, take a look at the L</TODO>
section.

=head1 The Makefile::Parser Class

This class provides the main interface to the Makefile parser.

=head2 METHODS

=over

=item C<< $obj = Makefile::Parser->new() >>

It's the constructor for the Parser class. You may provide the path
of your Makefile as the argument which . It
is worth mentioning that the constructor will I<not> call ->parse method
internally, so please remember calling ->parse after you construct
the parser object.

=item C<< $obj->parse() >>

=item C<< $obj->parse($Makefile_name) >>

=item C<< $obj->parse($Makefile_name, { var => value, ... }) >>

This method parse the specified Makefile (default to 'Makefile').

When an error occurs during the parsing procedure,
C<parse> will return
undef. Otherwise, a reference to Parser object itself is returned.
It is recommended to check the return value every time you call this
method. The detailed error info can be obtained by calling the
C<error> method.

You can also pass a hash reference to specify initial variables
and their values. Note that these variables are treated as
"defaults" so assignments in the makefile have higher priority.

=item C<< $obj->error() >>

It returns the error info set by the most recent failing operation, such
as a parsing failure.

=item C<< $obj->var($variable_name) >>

The var method returns the value of the given variable. Since the value of
variables can be reset multiple times in the Makefile, so what you get
is always the last value set to the variable. It's worth noting that
variable reassignment can be handled appropriately during parsing since
the whole parsing process is a one-pass operation compared to the multiple-pass
strategy used by the CPAN module L<Make>.

=item C<< @vars = $obj->vars >>

This will return all the variables defined in the Makefile. The order may be
quite different from the order they appear in the Makefile.

=item C<< $obj->target($target_name) >>

This method returns a Makefile::Target object with the name specified.
It will returns undef if the rules for the given target is not described
in the Makefile. It is worth noting that only targets with a definition
body will be considered as a I<target> here.

When $target_name is omitted, this method will return the default target,
say, the first target defined in Makefile, to the user. This can be handy
if you try to build a make tool on top of this module.

It is important not to send something like "$(MY_LIB)" as the target name.
Only raw values are acceptable. If you really want to do something like
this, please use the following code:

    my $tar = $parser->target($parser->var('MY_LIB'));

but this code will break if you have reassigned values to variable MY_LIB in
your Makefile.

=item C<< @targets = $obj->targets() >>

This returns all the targets in Makefile. The order can be completely
different from the order they appear in Makefile. So the following code
will not work if you want to get the default target (the first target):

    @tars = $parser->targets;
    print $tars[0];

Please use the following syntax instead:

    print $parser->target;

The type of the returned list is an array of Makefile::Target objects.

=item C<< @roots = $obj->roots() >>

The C<roots> method returns the "root targets" in Makefile. The targets
which there're no other targets depends on are called the I<root targets>.
For example, I<install>, I<uninstall>, and I<veryclean>
are all root targets in the Makefile generated by the I<ExtUtils::MakeMaker>
module. On the other hand, I<clean> and I<test> are not, which may be
somewhat counterintuitive. That's because there're some other targets
depend on I<clean>, I<test>, or both.

The type of the returned list is an array of Makefile::Target objects.

=back

=head2 PACKAGE VARIABLES

=over

=item $Makefile::Parser::Strict

When this variable is set to true, the parser will sense syntax errors and
semantic errors in the Makefile. Default off.

=item $Makefile::Parser::Debug

When this variable is set to true, the parser will enter Debug Mode. This
variable is not supposed to be used directly by the user.

=back

=head1 INTERNAL METHODS

=over

=item post_parse

Iterate the Makefile AST to apply implicit rules in the following form:

    %.o : %.c
        $(CC) -c $<

=item solve_imp($depend)

Solve implicit rules as many as possible using one target name that appears
in other target's dependency list.

=back

=head1 The Makefile::Target Class

This class overloads the "" operator so its instances can be automatically
converted to strings using their names.

=head2 METHODS

=over

=item C<< $class->new($target_name, $colon_type) >>

This is the constructor for class Makefile::Target. The first argument is the 
target name which can't be a Makefile variable, the second one is a single
colon or a double colon which is used by the rule definition in Makefile.

This method is usually called internally by the Makefile::Parser class. It
doesn't make much sense to me if the user has a need to call it manually.

=item C<< $obj->name() >>

It will return the name of the current Target object.


=item C<< @prereqs = $obj->prereqs() >>

You can get the list of prerequisites (or dependencies) for the current target.
If no dependency is specified in the Makefile for the target, an empty list will
be returned.


=item C<< @prereqs = $obj->depends() >>

Alias to the C<prereqs> method. This method is only preserved for
the sake of backward-compatibility. Please use C<prereqs> instead.

=item C<< $obj->commands() >>

This method returns a list of shell commands used to build the current target.
If no shell commands is given in the Makefile, an empty array will be returned.

=back

=head1 CODE REPOSITORY

For the very latest version of this module, check out the source from
L<http://github.com/agentzh/makefile-parser-pm>. There is
anonymous access to all.

=head1 TODO

The following syntax will be implemented soon:

=over

=item *

Add support the remaining GNU make makefile builtin functions:

C<origin>, C<value>, C<call>, C<flavor>, and C<eval>.

=item *

Add support for recursively-expanded variables.

=item *

Implement rules with multiple targets

=item *

Serious support for "Recursively expanded" variables in GUN make

=item *

Comments that span multiple lines via trailing backslash

=item *

Lines that don't contain just comments

=item *

Literal "#" escaped by a leading backslash

=item *

The include directive

=item *

Look for 'GNUmakefile' and 'makefile' automatically

=item *

MAKEFILES Variable

=item *

MAKEFILE_LIST Variable

=item *

.VARIABLES Variable

=back

=head1 BUGS

Please feel free to report bugs or send your wish-list
to L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Makefile-Parser>.

=head1 SEE ALSO

L<plmake>, L<makesimple>, L<Makefile::Parser::GmakeDB>, L<Makefile::GraphViz>, L<Make>.

=head1 AUTHOR

Zhang "agentzh" Yichun, C<< <agentzh@gmail.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2011 by Zhang "agentzh" Yichun (章亦春).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

