package Hardware::Vhdl::Automake::PreProcessor::Cish;

# VHDL file preprocessor
# to do:
#  #define and #undef of functions, replace in code

use Math::Expression;
use File::Basename;
use File::Spec::Functions qw/rel2abs/;
use List::Util qw/first/;
use Carp;
use strict;
use warnings;

our $file_slurp_limit = 16000;
our $VERSION          = "1.00";

sub pp_style { 'delegate' }

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = [
        {
            files_used => {},
            macros  => {
                '__LINE__' => { search => '__LINE__' },
                '__FILE__' => { search => '__FILE__' },
              },
            ungot => '',
            arithenv => undef,
        },
        {
            line    => '',
            copyon  => 1,
            linenum => 0,
            source  => undef,
            incsection => undef,
            endat => undef,
            ifstack => [],
        }
      ];
    my $perm  = $self->[0];
    my $state = $self->[1];
    if ( exists $args{sourcefile} ) {
        my $fhi;
        open $fhi, "<$args{sourcefile}" || croak "Could not read '$args{sourcefile}'\n";
        $state->{fhi} = $fhi;
        binmode $state->{fhi};
        $state->{filebuf}                        = '';
        $state->{source}                         = $args{sourcefile};
        $perm->{files_used}{ $args{sourcefile} } = undef;
    } else {
        croak "No source code specified" unless defined $state->{source};
    }

    if ( defined $args{incsection} && $args{incsection} ne '') {
        $state->{incsection} = $args{incsection};
        $state->{incsection_found} = 0;
        $state->{copyon} = 0;
    }
    #print "## new PreProcessor::Cish is reading $state->{source}\n";
    bless $self, $class;
    $self->update_macro_re;
    $self;
}

sub files_used {
    keys %{ $_[0]->[0]{files_used} };
}

sub linenum {
    # returns the line number of the last line fetched
    $_[0]->[-1]{linenum};
}

sub sourcefile {
    # returns the source file of the last line fetched
    $_[0]->[-1]{source};
}

sub unget {
    my $perm  = shift->[0];
    $perm->{ungot} = $_[0] . $perm->{ungot};
}

sub _just_get_a_line {
    my $self  = shift;
    my $state = $self->[-1];
    $state->{line} = undef;    # default return value
    my $bufname = exists $state->{sourcestring} ? 'sourcestring' : 'filebuf';

# Just what is used as a newline may vary from OS to OS. Unix traditionally uses \012, one type of DOSish I/O uses \015\012, and Mac OS uses \015.

    GET_LINE: {
        my $rem;
        if (defined $state->{endat}) { $rem = $state->{endat} - tell($state->{fhi}) } # REMainding bytes we are allowed to read from the file
        if ( $state->{$bufname} =~ m/^(.*?(\015\012?|\012\015?))(.*)$/s ) {
            $state->{line}     = $1;
            $state->{$bufname} = $3;
        } elsif ( exists $state->{fhi} && !eof $state->{fhi} && (!defined $rem || ($rem > 0))) {
            local $/ = \$file_slurp_limit;
            if (defined $rem && $file_slurp_limit > $rem) { $/ = \$rem }
            $state->{$bufname} .= readline $state->{fhi};
            redo GET_LINE;
        } else {
            $state->{line}     = $state->{$bufname};
            $state->{$bufname} = '';
        }
    }
    $state->{line} = undef if $state->{line} eq '';
}

sub macro_define {
    my ($self, $macname, $macdef) = @_;
    my $perm  = $self->[0];
    $macdef = '' if !defined $macdef;
    if (exists $perm->{macros}{$macname}) {
        carp "Macro '$macname', defined at $perm->{macros}{$macname}{defined_in} line $perm->{macros}{$macname}{linenum}, was redefined";
    }
    $perm->{macros}{$macname} = { search => $macname, replace => $macdef, defined_in => $self->[-1]{source}, defined_line => $self->[-1]{linenum} };
    $self->update_macro_re;
}

sub macro_define_func {
    my ($self, $macname, $fargs, $macdef) = @_;
    $fargs =~ s/\s+//g;
    my @args = split(',', $fargs);
    my $arg_re = join '|', @args;
    #print "# macro function define: name='$macname', arg re='$arg_re', definition='$macdef'\n";
    $self->[0]{macros}{$macname.'('.scalar(@args)} = {
        search => $macname.'(',
        arg_re => qr/^(.*?)\b($arg_re)\b(.*)$/s,
        arg_index => { map { $args[$_] => $_ } 0..$#args },
        replace => $macdef,
        defined_in => $self->[-1]{source},
        defined_line => $self->[-1]{linenum}
      };
    $self->update_macro_re;
}

sub macro_undefine {
    my ($self, $macname) = @_;
    my $perm  = $self->[0];
    delete $perm->{macros}{$macname};
    $self->update_macro_re;
}

sub macro_undefine_func {
    my ($self, $macname, $args) = @_;
    print "# macro function undef: name='$macname', args='$args'\n";
    my @args = split(',', $args);
    delete $self->[0]{macros}{$macname.'('.scalar(@args)};
    $self->update_macro_re;
}

sub update_macro_re {
    my $perm  = shift->[0];
    my @macnames;
    my %macfuncnames;
    for my $search (map { $perm->{macros}{$_}{search} } keys %{$perm->{macros}}) {
        if (substr($search, -1) eq '(') {
            $macfuncnames{quotemeta($search)} = undef;
        } else {
            push @macnames, $search."\\b";
        }
    }
    my $macro_re = join '|', @macnames, keys %macfuncnames;
    #print "# macro regexp = /^(.*?)\\b($macro_re)(.*)\$/s\n";
    $perm->{macro_re} = qr/^ (.*?) ( " | \b(?:$macro_re) ) (.*) $/xs;
}

sub macro_replace {
    # do macro expansion on the non-quoted parts of $state->{line}
    my $self  = shift;
    my $perm  = $self->[0];
    my $state = $self->[-1];
    my $out = $self->_macro_replace_string($state->{line}, []);
    #~ if ( $out =~ m/^(.*?(\015\012?|\012\015?))(.*)$/s ) {
        #~ # deal with multi-line output from macro replacement
        #~ # TBD: doesn't this mean that lines after the first one get processed more than once?
        #~ $state->{line} = $1;
        #~ $perm->{ungot} = $3;
    #~ } else 
    {
        $state->{line} = $out;
    }
}

sub _extract_args {
    my ($self, $line) = @_;
    # Looks for a comma-separated list of args, followed by a ')'.  If found, return the stuff after the ')' and the list of args
    #  if no closing bracket found, returns $line only.
    # Currently needs to find the closing bracket on the current line
    my $in=$line; # text yet to be processed: we nibble this from the left
    my $out=''; # accumulator for bits that have been nibbled and may be added to argument list
    my $bd=0; # bracket depth
    my @args; # arguments found so far
    #print "#> in = '$in'\n";                
    while ($in =~ m/^ (.*?) ( [\(\)\",] ) (.*) $/xms) {
        $out .= $1; # prematch
        my $g = $2; # significant char: bracket, quote or comma
        $in = $3; # postmatch
        if ($g eq ',') {
            if ($bd==0) {
                # a comma, not inside a bracket: what we've found before this must be an argument
                push @args, $out;
                $out = '';
            } else {
                # a comma, from inside a bracket: just add it to the current argument string
                $out .= $g;
            }
        } elsif ($g eq ')') {
            if ($bd==0) {
                # a closing bracket, not inside a bracket: must be the end of the argument list
                return $in, @args, $out;
            } else {
                # a closing bracket, from inside a bracket: decrease the bracket depth count
                $out .= $g;
                $bd--;
            }
        } elsif ($g eq '(') {
            # an opening bracket: increase the bracket depth count
            $out .= $g;
            $bd++;
        } else {
            # must have matched a double-quote character
            if ( $in =~ /^ ( 
                            .*?       # as little text as possible, then...
                            (?<!\\)   # no single backslash before...
                            (?:\\\\)* # as many pairs of backslashes as possible
                            "         # then a dquote char
                        ) 
                        (.*)          # Capture all that follows
                        $/xms ) {
                #print "# after '$out' found quoted: \"$1, text after='$2'\n";
                $out .= $g . $1;
                $in = $2;
            } else {
                # closing quote not found
                #print "# closing quote not found: args='".join("', '", @args)."', out = '$out', input = '$in'\n";                
                $out .= $g;
                $in = '';
            }
        }
        ##print "#> args='".join("', '", @args)."', out = '$out', input = '$in'\n";                
    }
    # if we get here, we've failed to find a closing bracket
    #print "## no closing bracket found: bd=$bd, out='$out', input='$in'\n";
    return $line;
}

sub _macro_replace_string {
    my $self  = shift;
    my $perm  = $self->[0];
    my ($line, $inmac) = @_;
    my $out = '';
    while ($line =~ $perm->{macro_re}) {
        $out .= $1;
        my $macro = $2;
        $line = $3;
        if ($macro eq '"') {
            $out .= $macro;
            if ( $line =~ /^( .*? (?<!\\) (?:\\\\)* ") (.*) $/xs ) {
                #print "# found quoted: \"$1, rem='$2'\n";
                $macro = $1;
                $line = $2;
            } else {
                # closing quote not found
                #print "# _macro_replace_string: closing quote not found: out = '$out', line = '$line'\n";                
                $macro = $line;
                $line = '';
            }
        } elsif (substr($macro, -1) eq '(') {
            # this is a function macro: we need to count the args to it before we know what to look up
            #print "# about to _extract_args: '$line' . '$quoted' . '$self->[-1]{line}'\n";
            my ($post, @args) = $self->_extract_args( $line );
            if (@args) {
                my $mackey =  $macro . scalar @args;
                #print "# found possible function macro '$mackey'\n";
                if (exists $perm->{macros}{$mackey}) {
                    unless (grep {$_ eq $mackey} @$inmac) {
                        $macro = $perm->{macros}{$mackey}{replace};
                        my $argsreplaced = '';
                        while ($macro =~ $perm->{macros}{$mackey}{arg_re}) {
                            $argsreplaced .= $1;
                            my $argname = $2;
                            $argsreplaced .= $args[$perm->{macros}{$mackey}{arg_index}{$argname}];
                            $macro = $3;
                        }
                        $argsreplaced .= $macro;
                        push @$inmac, $mackey;
                        $macro = $self->_macro_replace_string($argsreplaced, $inmac);
                        pop @$inmac;
                        $line = $post;
                    }
                }
            } else {
                print "# found function macro '$macro', argc=?\n";
            }
        } else {
            # this is a simple text-replace macro
            unless (grep {$_ eq $macro} @$inmac) {
                push @$inmac, $macro;
                $macro = $self->_macro_replace_string($perm->{macros}{$macro}{replace}, $inmac);
                pop @$inmac;
            }
        }
        $out .= $macro;
    }
    $out . $line;
}

sub _macro_eval {
    my $self  = shift;
    my $perm  = $self->[0];
    my ($expr) = @_;
    #print "# evaluating expression '$expr'\n";
    if (!defined $perm->{arithenv}) {
        $perm->{arithenv} = Math::Expression->new;
        my $setfunc = sub { $_[0]->{PrintErrFunc}("use of ':=' in expressions to set variables is not allowed: use #evaldef") };
        $perm->{arithenv}->SetOpt(
            VarSetFun => $setfunc,
            VarSetScalar => $setfunc,
            VarIsDefFun => sub { exists $perm->{macros}{$_[1]} ? 1 : 0 },
            VarGetFun => sub { exists $perm->{macros}{$_[1]} ? $perm->{macros}{$_[1]}{replace} : '' },
            FuncEval => sub {
                my ($ae, $fname, @arglist) = @_;
                return $arglist[$#arglist] ? 0 : 1 if $fname eq 'not';
                return time if $fname eq 'time';
                $ae->FuncValue($fname, @arglist); # let Math::Expression deal with the functions it knows
              },
            PrintErrFunc => sub { die sprintf(shift(@_)."\n", @_) },
          );
    }
    my $tree = $perm->{arithenv}->Parse($expr);
    $perm->{arithenv}->EvalToScalar($tree);
}

sub _pp_if {
    my ($cond, $state, $ifstack) = @_;
    if ( $state->{copyon} ) {
        push @$ifstack, $cond;
        $state->{copyon} = $cond;
    } else {
        push @$ifstack, 2;
    }
}

sub _pp_else {
    my ($cond, $state, $ifstack) = @_;
    if (@$ifstack==0) {
        croak "'#else' without '#if'\n";
    } elsif ($cond && $ifstack->[-1]==0) {
        $ifstack->[-1] = 1;
        $state->{copyon} = 1;
    } else {
        $state->{copyon} = 0;
    }
}

sub _pp_cond_def {
    my ($self,$macname,$neg) = @_;
    my $cond = 0;
    if ( exists $self->[0]{macros}{$macname} ) {
        $cond = 1;
    }
    else {
        my $len = length($macname)+1;
        if ( defined(first { substr($_, 0, $len) eq "$macname(" } keys %{$self->[0]{macros}}) ) {
            $cond = 1;
        }
    }
    $cond = 1 - $cond if $neg;
    $cond;
}

sub _pp_cond_expr {
    my ($self, $expr, $neg) = @_;
    my $cond = $self->_macro_eval($expr) ? 1 : 0;
    $cond = 1 - $cond if $neg;
    $cond;
}

sub get_next_line {
    # returns a line and its newline at the end, or the last line (perhaps without a newline) or undef
    my $self  = shift;
    my $perm  = $self->[0];
    my $state = $self->[-1];
    my $ifstack = $state->{ifstack};
    my $done  = 0;

    if ($perm->{ungot} ne '') {
        if ( $perm->{ungot} =~ m/^(.*?(\015\012?|\012\015?))(.*)$/s ) {
            $state->{line} = $1;
            $perm->{ungot} = $3;
        } else {
            $state->{line} = $perm->{ungot}."\n";
            $perm->{ungot} = '';
        }
        $done = 1;
    }

    while ( !$done ) {
        $done = $state->{copyon};
        $self->_just_get_a_line;
        if ( defined $state->{line} ) {
            $state->{linenum}++;

            if ( $state->{line} =~ /^ \s* \#if(n?)def \s+ (\w+) \s* $/x ) {
                my ($neg, $macname) = ($1, $2);
                &_pp_if($self->_pp_cond_def($macname, $neg), $state, $ifstack);
                $done = 0;
            } elsif ( $state->{line} =~ /^ \s* \#(if|ifn|unless) \s+ (.*) $/x ) {
                my ($neg, $expr) = ($1 ne 'if', $2);
                &_pp_if($self->_pp_cond_expr($expr, $neg), $state, $ifstack);
                $done = 0;
            } elsif ( $state->{line} =~ /^ \s* \#elsif(n?)def \s+ (\w+) \s* $/x ) {
                my ($neg, $macname) = ($1, $2);
                &_pp_else($self->_pp_cond_def($macname, $neg), $state, $ifstack);
                $done = 0;
            } elsif ( $state->{line} =~ /^ \s* \#elsif(n?) \s+ (.*) $/x ) {
                my ($neg, $macname) = ($1, $2);
                &_pp_else($self->_pp_cond_expr($macname, $neg), $state, $ifstack);
                $done = 0;
            } elsif ( $state->{line} =~ /^ \s* \#else \s* $/x ) {
                &_pp_else(1, $state, $ifstack);
                $done = 0;
            } elsif ( $state->{line} =~ /^ \s* \#endif \s* $/x ) {
                my $cond = 1;
                if (@$ifstack==0) {
                    croak "'#endif' without '#if'\n";
                }
                $state->{copyon} = $ifstack->[-1]<2;
                pop @$ifstack;
                $done = 0;
            }
            if ( $state->{copyon} ) {
                if ( $state->{line} =~ /^ \s* \#(define|evaldef) \s+ (\w+) (?: \s+ (.*?) )? \s* $/x ) {
                    my ($deftype, $macname, $macdef) = ($1, $2, $3);
                    $self->_get_continued_command(\$macdef);
                    if ($deftype eq 'evaldef') {
                        $macdef = $self->_macro_eval($macdef);
                    }
                    if (defined $macdef) {
                        $self->macro_define($macname, $macdef);
                    } else {
                        $self->macro_undefine($macname);
                    }
                    $done = 0;
                } elsif ( $state->{line} =~ /^ \s* \#define \s+ (\w+) \( \s* ( \w+ (?: \s* , \s* \w+ )* ) \s* \) (?: \s+ (.*?) )? \s* $/x ) {
                    my ($macname, $fargs, $macdef) = ($1, $2, $3);
                    $self->_get_continued_command(\$macdef);
                    $self->macro_define_func($macname, $fargs, $macdef);
                    $done = 0;
                } elsif ( $state->{line} =~ /^ \s* \#undef \s+ (\w+) \s* $/x ) {
                    my $macname = $1;
                    $self->macro_undefine($macname);
                    $done = 0;
                } elsif ( $state->{line} =~ /^ \s* \#undef \s+ (\w+) \( \s* ( \w+ (?: \s* , \s* \w+ )* ) \s* \) \s* $/x ) {
                    $self->macro_undefine_func($1, $2);
                    $done = 0;
                } elsif ( $state->{line} =~ /^ \s* \#include \s+ \" (.+) \" (?: \s+ ([A-Za-z][A-Za-z0-9_]*))? \s* $/x ) {
                    my $isf = $1;
                    my $incsec = $2;
                    die "filename is undef" unless defined $isf;
                    $isf = rel2abs( $isf, dirname( $state->{source} ) );
                    croak "File '$isf' does not exist" unless -f $isf;
                    #print "## preprocessor will #include $isf\n";
                    $perm->{files_used}{$isf} = undef;
                    my $newpp = new( ref $self, sourcefile => $isf, incsection => $incsec );
                    $state = $newpp->[1];
                    $ifstack = $state->{ifstack};
                    push @$self, $state;
                    #print "## preprocessor is including $state->{source}\n";
                    $done = 0;
                } elsif ($state->{line} =~ /^ \s* \#section_(start|end) \s+ ([A-Za-z][A-Za-z0-9_]*) \s* $/x ) {
                    my ($secend, $label) = ($1 eq 'end', $2);
                    #print "## found section end, label = '$label'\n";
                    $done = 0;
                    if ($secend && $state->{incsection}) {
                        $state->{copyon} = 0;
                    }
                } elsif ($state->{line} =~ $perm->{macro_re}) {
                    # ordinary line, not a PP directive - has macro names in it thay may need expanding
                    $perm->{macros}{__LINE__}{replace} = $state->{linenum};
                    $perm->{macros}{__FILE__}{replace} = '"'.$state->{source}.'"';
                    $self->macro_replace;
                }
            } else {
                $done = 0;
                if ($state->{line} =~ /^ \s* \#section_start \s+ ([A-Za-z][A-Za-z0-9_]*) \s* $/x ) {
                    my $label = $1;
                    #print "## found section start, label = '$label'\n";
                    $done = 0;
                    if (defined $state->{incsection} && $label eq $state->{incsection}) {
                        $state->{incsection_found} = 1;
                        $state->{copyon} = 1;
                    }
                }
            }
            if ( $done && @$self > 2 && $state->{line} !~ m/(\015|\012)$/ ) {
                # last line of this file, without a newline, but it's an included file so add a newline.
                $state->{line} .= "\n";
            }
        } else {    # $state->{line} is undef
            if ( @$self > 2 ) {
                # already returned last line of this file, but it's an included file so drop back to the parent (including) file
                #print "## preprocessor has finished including $state->{source}\n";
                # discard the current state
                pop @$self;
                # restore the state from the stack
                $state = $self->[-1];
                $ifstack = $state->{ifstack};
                #print "## preprocessor is returning to $state->{source}\n";
                $done = 0;
            } else {
                #print "## preprocessor has come to the end of $state->{source}\n";
                $done = 1;
            }
        }
    }

    #print "# got line $state->{linenum}: '$state->{line}'\n";
    wantarray ? ( $state->{line}, $state->{source}, $state->{linenum} ) : $state->{line};
}

sub _get_continued_command {
    my ($self, $cmdref) = @_;
    $$cmdref = '' if !defined $$cmdref;
    my $state = $self->[-1];
    while ($$cmdref =~ /^ (.*?) \s* \\$/x) {
        $$cmdref = $1;
        $self->_just_get_a_line;
        last if !defined $state->{line};
        $state->{linenum}++;
        if ( $state->{line} =~ /^ \s* (.*?) \s* $/xs ) {
            $$cmdref .= ' '.$1;
        }
    }
}

1;
