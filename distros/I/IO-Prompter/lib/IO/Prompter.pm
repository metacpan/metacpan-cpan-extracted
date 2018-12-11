use 5.010;
package IO::Prompter;
use utf8;

use warnings;
no if $] >= 5.018000, warnings => 'experimental';
use strict;
use Carp;
use Contextual::Return qw< PUREBOOL BOOL SCALAR METHOD VOID LIST RETOBJ >;
use Scalar::Util qw< openhandle looks_like_number >;
use Symbol       qw< qualify_to_ref >;

our $VERSION = '0.004015';

my $fake_input;     # Flag that we're faking input from the source

my $DEFAULT_TERM_WIDTH   = 80;
my $DEFAULT_VERBATIM_KEY = "\cV";

# Completion control...
my $COMPLETE_DISPLAY_FIELDS = 4;  #...per line
my $COMPLETE_DISPLAY_GAP    = 3;  #...spaces

my $COMPLETE_KEY  = $ENV{IO_PROMPTER_COMPLETE_KEY} // qq{\t};
my $COMPLETE_HIST = $ENV{IO_PROMPTER_HISTORY_KEY}  // qq{\cR};
my $COMPLETE_NEXT = qq{\cN};
my $COMPLETE_PREV = qq{\cP};

my $COMPLETE_INIT  = qr{ [\Q$COMPLETE_KEY$COMPLETE_HIST\E] }xms;
my $COMPLETE_CYCLE = qr{ [$COMPLETE_NEXT$COMPLETE_PREV] }xms;

my %COMPLETE_MODE = (
    $COMPLETE_KEY
        => [split /\s+/, $ENV{IO_PROMPTER_COMPLETE_MODES}//q{list+longest  full}],
    $COMPLETE_HIST
        => [split /\s+/, $ENV{IO_PROMPTER_HISTORY_MODES} // q{full}],
);

my $FAKE_ESC    = "\e";
my $FAKE_INSERT = "\cF";
my $MENU_ESC    = "\e";
my $MENU_MK     = '__M_E_N_U__';

my %EDIT = (
    BACK    => qq{\cB},
    FORWARD => qq{\cF},
    START   => qq{\cA},
    END     => qq{\cE},
);
my $EDIT_KEY = '['.join(q{},values %EDIT).']';

# Extracting key letters...
my $KL_EXTRACT = qr{ (?| \[  ( [[:alnum:]]++ )  \]
                       | \(  ( [[:alnum:]]++ )  \)
                       | \<  ( [[:alnum:]]++ )  \>
                       | \{  ( [[:alnum:]]++ )  \}
                     )
                   }xms;
my $KL_DEF_EXTRACT = qr{ \[  ( [[:alnum:]]++ )  \] }xms;


# Auxiliary prompts for -Yes => N construct...
my @YESNO_PROMPTS = (
    q{Really?},
    q{You're quite certain?},
    q{Definitely?},
    q{You mean it?},
    q{You truly mean it?},
    q{You're sure?},
    q{Have you thought this through?},
    q{You understand the consequences?},
);


# Remember returned values for history completion...
my %history_cache;

# Track lexically-scoped default options and wrapper subs...
my @lexical_options  = [];
my @lexical_wrappers = [];

# Export the prompt() sub...
sub import {
    my (undef, $config_data, @other_args) = @_;

    # Handle -argv requests...
    if (defined $config_data && $config_data eq '-argv') {
        scalar prompt(-argv, @other_args);
    }

    # Handle lexical options...
    elsif (ref $config_data eq 'ARRAY') {
        push @lexical_options, $config_data;
        $^H{'IO::Prompter::scope_number'} = $#lexical_options;
    }

    # Handle lexical wrappers...
    elsif (ref $config_data eq 'HASH') {
        push @lexical_options, [];
        $lexical_wrappers[ $#lexical_options ] = $config_data;
        $^H{'IO::Prompter::scope_number'} = $#lexical_options;
        for my $subname (keys %{$config_data}) {
            my @args = @{$config_data->{$subname}};
            no strict 'refs';
            no warnings 'redefine';
            *{caller().'::'.$subname} = sub {
                my $scope_number = (caller 0)[10]{'IO::Prompter::scope_number'};
                return prompt(@{$lexical_wrappers[$scope_number]{$subname}//[]}, @_);
            };
        }
    }

    # Handler faked input specifications...
    elsif (defined $config_data) {
        $fake_input = $config_data;
    }

    no strict 'refs';
    *{caller().'::prompt'} = \&prompt;
}

# Prompt for, read, vet, and return input...
sub prompt {
    # Reclaim full control of print statements while prompting...
    local $\ = '';

    # Locate any lexical default options...
    my $hints_hash = (caller 0)[10] // {};
    my $scope_num = $hints_hash->{'IO::Prompter::scope_number'} // 0;

    # Extract and sanitize configuration arguments...
    my $opt_ref = _decode_args(@{$lexical_options[$scope_num]}, @_);

    _warn( void => 'Useless use of prompt() in void context' )
        if VOID && !$opt_ref->{-void};

    # Set up yesno prompts if required...
    my @yesno_prompts
        = ($opt_ref->{-yesno}{count}//0) > 1 ? @YESNO_PROMPTS : ();

    # Work out where the prompts go, and where the input comes from...
    my $in_filehandle  = $opt_ref->{-in}  // _open_ARGV();
    my $out_filehandle = $opt_ref->{-out} // qualify_to_ref(select);
    if (!openhandle $in_filehandle) {
        open my $fh, '<', $in_filehandle
            or _opt_err('Unacceptable', '-in', 'valid filehandle or filename');
        $in_filehandle = $fh;
    }
    if (!openhandle $out_filehandle) {
        open my $fh, '>', $out_filehandle
            or _opt_err('Unacceptable', '-out', 'valid filehandle or filename');
        $out_filehandle = $fh;
    }

    # Track timeouts...
    my $in_pos = do { no warnings;  tell $in_filehandle } // 0;

    # Short-circuit if not valid handles...
    return if !openhandle($in_filehandle) || !openhandle($out_filehandle);

    # Work out how they're arriving and departing...
    my $outputter_ref = -t $in_filehandle && -t $out_filehandle
                            ? _std_printer_to($out_filehandle, $opt_ref)
                            : _null_printer()
                            ;
    my $inputter_ref = _generate_unbuffered_reader_from(
                            $in_filehandle, $outputter_ref, $opt_ref
                       );

    # Clear the screen if requested to...
    if ($opt_ref->{-wipe}) {
        $outputter_ref->(-nostyle => "\n" x 1000);
    }

    # Handle menu structures...
    my $input;
    REPROMPT_YESNO:
    if ($opt_ref->{-menu}) {
        # Remember top of (possibly nested) menu...
        my @menu = ( $opt_ref->{-menu} );
        my $top_prompt = $opt_ref->{-prompt};
        $top_prompt =~ s{$MENU_MK}{$opt_ref->{-menu}{prompt}}xms;
        $menu[-1]{prompt} = $top_prompt;

        MENU:
        while (1) {
            # Track the current level...
            $opt_ref->{-menu_curr_level} = $menu[-1]{value_for};

            # Show menu and retreive choice...
            $outputter_ref->(-style => $menu[-1]{prompt});
            my $tag = $inputter_ref->($menu[-1]{constraint});

            # Handle a failure by exiting the loop...
            last MENU if !defined $tag;
            $tag =~ s{\A\s*(\S*).*}{$1}xms;

            # Handle <ESC> by moving up menu stack...
            if ($tag eq $MENU_ESC) {
                $input = undef;
                last MENU if @menu <= 1;
                pop @menu;
                next MENU;
            }

            # Handle defaults by selecting and ejecting...
            if ($tag =~ /\A\R?\Z/ && exists $opt_ref->{-def}) {
                $input = $tag;
                last MENU;
            }

            # Otherwise, retrieve value for selected tag and exit if not a nested menu...
            $input = $menu[-1]{value_for}{$tag};
            last MENU if !ref $input;

            # Otherwise, go down the menu one level...
            push @menu,
                _build_menu($input,
                             "Select from $menu[-1]{key_for}{$tag}: ",
                             $opt_ref->{-number} || $opt_ref->{-integer}
                );
            $menu[-1]{prompt} .= '> ';
        }
    }

    # Otherwise, simply ask and ye shall receive...
    else {
        $outputter_ref->(-style => $opt_ref->{-prompt});
        $input = $inputter_ref->();
    }

    # Provide default value if available and necessary...
    my $defaulted = 0;
    if (defined $input && $input =~ /\A\R?\Z/ && exists $opt_ref->{-def}) {
        $input = $opt_ref->{-def};
        $defaulted = 1;
    }

    # The input line is usually chomped before being returned...
    if (defined $input && !$opt_ref->{-line}) {
        chomp $input;
    }

    # Check for a value indicating failure...
    if (exists $opt_ref->{-fail} && $input ~~ $opt_ref->{-fail}) {
        $input = undef;
    }

    # Setting @ARGV is a special case; process it like a command-line...
    if ($opt_ref->{-argv}) {
        @ARGV = map { _shell_expand($_) }
                    grep {defined}
                            $input =~ m{
                                    ( '  [^'\\]* (?: \\. [^'\\]* )* ' )
                                |   ( "  [^"\\]* (?: \\. [^"\\]* )* " )
                                |   (?: ^ | \s)  ( [^\s"'] \S*        )
                            }gxms;
        return 1;
    }

    # "Those who remember history are enabled to repeat it"...
    if (defined $input and $opt_ref->{-history} ne 'NONE') {
        my $history_set = $history_cache{ $opt_ref->{-history} } //= [] ;
        @{ $history_set } = ($input, grep { $_ ne $input } @{ $history_set });
    }

    # If input timed out insert the default, if any...
    my $timedout = $in_pos == do{ no warnings; tell $in_filehandle } // 0;
    if ($timedout && exists $opt_ref->{-def}) {
        $input = $opt_ref->{-def};
        $defaulted = 1;
    }

    # A defined input is a successful input...
    my $succeeded = defined $input;

    # The -yesno variants also need a 'y' to be successful...
    if ($opt_ref->{-yesno}{count}) {
        $succeeded &&= $input =~ m{\A \s* y}ixms;
        if ($succeeded && $opt_ref->{-yesno}{count} > 1) {
            my $count = --$opt_ref->{-yesno}{count};
            $opt_ref->{-prompt}
                = @yesno_prompts ? shift(@yesno_prompts) . q{ }
                : $count > 1     ? qq{Please confirm $count more times }
                :                   q{Please confirm one last time }
                ;
            goto REPROMPT_YESNO;    # Gasp, yes goto is the cleanest way!
        }
    }

    # Verbatim return doesn't do fancy tricks...
    if ($opt_ref->{-verbatim}) {
        return $input // ();
    }

    # Failure in a list context returns nothing...
    return if LIST && !$succeeded;

    # Otherwise, be context sensitive...
    return
        PUREBOOL { $_ = RETOBJ; next handler;      }
            BOOL { $succeeded;                     }
          SCALAR { $input;                         }
          METHOD {
                    defaulted => sub { $defaulted  },
                    timedout  => sub {
                        return q{} if !$timedout;
                        return "timed out after $opt_ref->{-timeout} second"
                             . ($opt_ref->{-timeout} == 1 ? q{} : q{s});
                    },
                 };
}


# Simulate a command line expansion for the -argv option...
sub _shell_expand {
    my ($text) = @_;

    # Single-quoted text is literal...
    if ($text =~ m{\A ' (.*) ' \z}xms) {
        return $1;
    }

    # Everything else has shell variables expanded...
    my $ENV_PAT = join '|', reverse sort keys %ENV;
    $text =~ s{\$ ($ENV_PAT)}{$ENV{$1}}gxms;

    # Double-quoted text isn't globbed...
    if ($text =~ m{\A " (.*) " \z}xms) {
        return $1;
    }

    # Everything else is...
    return glob($text);
}

# No completion is the default...
my $DEFAULT_COMPLETER = sub { q{} };

# Translate std constraints...
my %STD_CONSTRAINT = (
    positive  => sub { $_ > 0      },
    negative  => sub { $_ < 0      },
    zero      => sub { $_ == 0     },
    even      => sub { $_ % 2 == 0 },
    odd       => sub { $_ % 2 != 0 },
);

# Create abbreviations...
$STD_CONSTRAINT{pos} = $STD_CONSTRAINT{positive};
$STD_CONSTRAINT{neg} = $STD_CONSTRAINT{negative};

# Create antitheses...
for my $constraint (keys %STD_CONSTRAINT) {
    my $implementation = $STD_CONSTRAINT{$constraint};
    $STD_CONSTRAINT{"non$constraint"}
        = sub { ! $implementation->(@_) };
}

# Special style specifications require decoding...

sub _decode_echo {
    my $style = shift;

    # Not a special style...
    return $style if ref $style || $style !~ m{/};

    # A slash means yes/no echoes...
    my ($yes, $no) = split m{/}, $style;
    return sub{ /y/i ? $yes : $no };
}

sub _decode_echostyle {
    my $style = shift;

    # Not a special style...
    return $style if ref $style || $style !~ m{/};

    # A slash means yes/no styles...
    my ($yes, $no) = split m{/}, $style;
    return sub{ /y/i ? $yes : $no };
}

sub _decode_style {
    # No special prompt styles (yet)...
    return shift;
}

# Generate safe closure around active sub...
sub _gen_wrapper_for {
    my ($arg) = @_;
    return ref $arg ne 'CODE'
           ? sub { $arg }
           : sub { eval { for (shift) { no warnings; return $arg->($_) // $_ } } };
}

# Create recognizer...
my $STD_CONSTRAINT
    = '^(?:' . join('|', reverse sort keys %STD_CONSTRAINT) . ')';

# Translate name constraints to implementations...
sub _standardize_constraint {
    my ($option_type, $constraint_spec) = @_;

    return ("be an acceptable $option_type", $constraint_spec)
        if ref $constraint_spec;

    my @constraint_names = split /\s+/, $constraint_spec;
    my @constraints =
        map { $STD_CONSTRAINT{$_}
              // _opt_err('invalid',-$option_type,'"pos", "neg", "even", etc.')
            } @constraint_names;

    return (
        'be ' . join(' and ', @constraint_names),
        sub {
            my ($compare_val) = @_;
            for my $constraint (@constraints) {
                return 0 if !$constraint->($compare_val);
            }
            return 1;
        }
    );
}


# Convert args to prompt + options hash...
sub _decode_args {
    my %option = (
        -prompt    => undef,
        -complete  => $DEFAULT_COMPLETER,
        -must      => {},
        -history   => 'DEFAULT',
        -style     => sub{ q{} },
        -nostyle   => sub{ q{} },
        -echostyle => sub{ q{} },
        -echo      => sub { my $char = shift; $char eq "\t" ? q{ } : $char },
        -return    => sub { "\n" },
    );

    DECODING:
    while (defined(my $arg = shift @_)) {
        if (my $type = ref $arg) {
            _warn( reserved =>
                'prompt(): Unexpected argument (' . lc($type) . ' ref) ignored'
            );
        }
        else {
            my $redo;
            given ($arg) {
                # The sound of one hand clapping...
                when (/^-_/) {
                    $redo = 1;
                }

                # Non-chomping option...
                when (/^-line$/) {
                    $option{-line}++;
                }
                when (/^-l/) {
                    $option{-line}++;
                    $redo = 1;
                }

                # The -yesno variants...
                when (/^-YesNo$/) {
                    my $count = @_ && looks_like_number($_[0]) ? shift @_ : 1;
                    $option{-yesno} = {
                        must => { '[YN]' => qr{\A \s* [YN] }xms },
                        count  => $count,
                    };
                }
                when (/^-YN/) {
                    $option{-yesno} = {
                        must => { '[YN]' => qr{\A \s* [YN] }xms },
                        count  => 1,
                    };
                    $redo = 2;
                }
                when (/^-yesno$/) {
                    my $count = @_ && looks_like_number($_[0]) ? shift @_ : 1;
                    $option{-yesno} = {
                        must => { '[yn]' => qr{\A \s* [YN] }ixms },
                        count  => $count,
                    };
                }
                when (/^-yn/) {
                    $option{-yesno} = {
                        must => { '[yn]' => qr{\A \s* [YN] }ixms },
                        count  => 1,
                    };
                    $redo = 2;
                }
                when (/^-Yes$/) {
                    my $count = @_ && looks_like_number($_[0]) ? shift @_ : 1;
                    $option{-yesno} = {
                        must => { '[Y for yes]' => qr{\A \s* (?: [^y] | \Z) }xms },
                        count  => $count,
                    };
                }
                when (/^-Y/) {
                    $option{-yesno} = {
                        must => { '[Y for yes]' => qr{\A \s* (?: [^y] | \Z) }xms },
                        count  => 1,
                    };
                    $redo = 1;
                }
                when (/^-yes$/) {
                    my $count = @_ && looks_like_number($_[0]) ? shift @_ : 1;
                    $option{-yesno} = { count  => $count };
                }
                when (/^-y/) {
                    $option{-yesno} = { count  => 1 };
                    $redo = 1;
                }

                # Load @ARGV...
                when (/^-argv$/) {
                    $option{-argv} = 1;
                }

                when (/^-a/) {
                    $option{-argv} = 1;
                    $redo = 1;
                }

                # Clear screen before prompt...
                state $already_wiped;
                when (/^-wipe(first)?$/) {
                    $option{-wipe} = $1 ? !$already_wiped : 1;
                    $already_wiped = 1;
                }
                when (/^-w/) {
                    $option{-wipe} = 1;
                    $already_wiped = 1;
                    $redo = 1;
                }

                # Specify a failure condition...
                when (/^-fail$/) {
                    _opt_err('Missing', -fail, 'failure condition') if !@_;
                    $option{-fail} = shift @_;
                }

                # Specify a file request...
                when (/^-f(?:ilenames?)?$/) {
                    $option{-must}{'0: be an existing file'} = sub { -e $_[0] };
                    $option{-must}{'1: be readable'}         = sub { -r $_[0] };
                    $option{-complete}                       = 'filenames';
                }

                # Specify prompt echoing colour/style...
                when (/^-style/) {
                    _opt_err('Missing -style specification') if !@_;
                    my $style = _decode_style(shift @_);
                    $option{-style} = _gen_wrapper_for($style);
                }

                # Specify input colour/style...
                when (/^-echostyle/) {
                    _opt_err('Missing -echostyle specification') if !@_;
                    my $style = _decode_echostyle(shift @_);
                    $option{-echostyle} = _gen_wrapper_for($style);
                }


                # Specify input and output filehandles...
                when (/^-stdio$/) { $option{-in}  = *STDIN;
                                   $option{-out} = *STDOUT;
                                  }
                when (/^-in$/)    { $option{-in}  = shift @_; }
                when (/^-out$/)   { $option{-out} = shift @_; }

                # Specify integer and number return value...
                when (/^-integer$/)       {
                    $option{-integer} = 1;
                    if (@_ && (ref $_[0] || $_[0] =~ $STD_CONSTRAINT)) {
                        my ($errmsg, $constraint)
                            = _standardize_constraint('integer',shift);
                        $option{-must}{$errmsg} = $constraint;
                    }
                }
                when (/^-num(?:ber)?$/)   {
                    $option{-number}  = 1;
                    if (@_ && (ref $_[0] || $_[0] =~ $STD_CONSTRAINT)) {
                        my ($errmsg, $constraint)
                            = _standardize_constraint('number',shift);
                        $option{-must}{$errmsg} = $constraint;
                    }
                }
                when (/^-i/)              { $option{-integer} = 1; $redo = 1; }
                when (/^-n/)              { $option{-number}  = 1; $redo = 1; }

                # Specify void context is okay...
                when (/^-void$/)          { $option{-void} = 1;               }

                # Specify verbatim return value...
                when (/^-verb(?:atim)?$/) { $option{-verbatim} = 1;           }
                when (/^-v/)              { $option{-verbatim} = 1; $redo = 1;}

                # Specify single character return...
                when (/^-sing(?:le)?$/)   { $option{-single} = 1;             }
                when (/^-[s1]/)           { $option{-single} = 1; $redo = 1;  }

                # Specify a default...
                when (/^-DEF(?:AULT)?/) {
                    _opt_err('Missing', '-DEFAULT', 'string') if !@_;
                    $option{-def} = shift @_;
                    $option{-def_nocheck} = 1;
                    _opt_err('Invalid', '-DEFAULT', 'string')
                        if ref($option{-def});
                }
                when (/^-def(?:ault)?/) {
                    _opt_err('Missing', '-default', 'string') if !@_;
                    $option{-def} = shift @_;
                    _opt_err('Invalid', '-default', 'string')
                        if ref($option{-def});
                }
                when (/^-d(.+)$/)   { $option{-def} = $1; }

                # Specify a timeout...
                when (/^-t(\d+)/)   {
                    $option{-timeout} = $1;
                    $arg =~ s{\d+}{}xms;
                    $redo = 1;
                }
                when (/^-timeout$/) {
                    _opt_err('Missing', -timeout, 'number of seconds') if !@_;
                    $option{-timeout} = shift @_;
                    _opt_err('Invalid', -timeout,'number of seconds')
                        if !looks_like_number($option{-timeout});
                }

                # Specify a set of input constraints...
                when (/^-g.*/) {
                    _opt_err('Missing', -guarantee, 'input restriction') if !@_;
                    my $restriction = shift @_;
                    my $restriction_type = ref $restriction;

                    $option{-must}{'be a valid input'} = $restriction;

                    # Hashes restrict input to their keys...
                    if ($restriction_type eq 'HASH') {
                        $restriction_type = 'ARRAY';
                        $restriction = [ keys %{$restriction} ];
                    }
                    # Arrays of strings matched (and completed) char-by-char...
                    if ($restriction_type eq 'ARRAY') {
                        my @restrictions = @{$restriction};
                        $option{-guarantee}
                            = '\A(?:'
                            . join('|', map {
                                  join(q{}, map { "(?:\Q$_\E" } split(q{}, $_))
                                . ')?' x length($_)
                              } @restrictions)
                            . ')\z'
                            ;
                        if ($option{-complete} == $DEFAULT_COMPLETER) {
                            $option{-complete} = \@restrictions;
                        }
                    }
                    # Regexes matched as-is...
                    elsif ($restriction_type eq 'Regexp') {
                        $option{-guarantee} = $restriction;
                    }
                    else {
                        _opt_err( 'Invalid', -guarantee,
                                  'array or hash reference, or regex'
                        );
                    }
                }

                # Specify a set of key letters...
                when ('-keyletters_implement') {
                    # Extract all keys and default keys...
                    my @keys  = ($option{-prompt} =~ m{$KL_EXTRACT}gxms);

                    # Convert default to a -default...
                    my @defaults = ($option{-prompt} =~ m{$KL_DEF_EXTRACT}gxms);
                    if (@defaults > 1) {
                        _warn( ambiguous =>
                            "prompt(): -keyletters found too many defaults"
                        )
                    }
                    elsif (@defaults) {
                        push @_, -default => $defaults[0];
                    }

                    # Convert key letters to a -guarantee...
                    @keys = ( map({uc} @keys), map({lc} @keys) );
                    if (@defaults == 1) {
                        push @keys, q{};
                    }
                    push @_, -guarantee => \@keys;

                }
                when (/^-key(?:let(?:ter)?)(?:s)?/) {
                    push @_, '-keyletters_implement';
                }
                when (/^-k/) {
                    push @_, '-keyletters_implement';
                    $redo = 1;
                }

                # Specify a set of return constraints...
                when (/^-must$/) {
                    _opt_err('Missing', -must, 'constraint hash') if !@_;
                    my $must = shift @_;
                    _opt_err('Invalid', -must, 'hash reference')
                        if ref($must) ne 'HASH';
                    for my $errmsg (keys %{$must}) {
                        $option{-must}{$errmsg} = $must->{$errmsg};
                    }
                }

                # Specify a history set...
                when (/^-history/) {
                    $option{-history}
                        = @_ && $_[0] !~ /^-/ ? shift @_
                        :                       undef;
                    _opt_err('Invalid', -history, 'history set name')
                        if ref($option{-history});
                }
                when (/^-h(.*)/)   { $option{-history} = length($1) ? $1 : undef; }

                # Specify completions...
                when (/^-comp(?:lete)?/) {
                    _opt_err('Missing', -complete, 'completions') if !@_;
                    my $comp_spec = shift @_;
                    my $comp_type = ref($comp_spec) || $comp_spec || '???';
                    if ($comp_type =~ m{\A(?: file\w* | dir\w* | ARRAY | HASH | CODE )\Z}xms) {
                        $option{-complete} = $comp_spec;
                    }
                    else {
                        _opt_err( 'Invalid', -complete,
                                    '"filenames", "dirnames", or reference to array, hash, or subroutine');
                    }
                }

                # Specify what to echo when a character is keyed...
                when (/^-(echo|ret(?:urn)?)$/) {
                    my $flag = $1 eq 'echo' ? '-echo' : '-return';
                    if ($flag eq '-echo' && !eval { no warnings 'deprecated'; require Term::ReadKey }) {
                        _warn( bareword => "Warning: next input will be in plaintext\n");
                    }
                    my $arg = @_ && $_[0] !~ /^-/ ? shift(@_)
                            : $flag eq '-echo'    ? q{}
                            :                       qq{\n};
                    $option{$flag} = _gen_wrapper_for(_decode_echo($arg));
                }
                when (/^-e(.*)/) {
                    if (!eval { no warnings 'deprecated'; require Term::ReadKey }) {
                        _warn( bareword => "Warning: next input will be in plaintext\n");
                    }
                    my $arg = $1;
                    $option{-echo} = _gen_wrapper_for(_decode_echo($arg));
                }
                when (/^-r(.+)/) {
                    my $arg = $1;
                    $option{-return} = _gen_wrapper_for(_decode_echo($arg));
                }
                when (/^-r/) {
                    $option{-return} = sub{ "\n" };
                }

                # Explicit prompt replaces implicit prompts...
                when (/^-prompt$/) {
                    _opt_err('Missing', '-prompt', 'prompt string') if !@_;
                    $option{-prompt} = shift @_;
                    _opt_err('Invalid', '-prompt', 'string')
                        if ref($option{-prompt});
                }
                when (/^-p(\S*)$/) {
                    $option{-prompt} = $1;
                }

                # Menus inject a placeholder in the prompt string...
                when (/^-menu$/) {
                    _opt_err('Missing', '-menu', 'menu specification') if !@_;
                    $option{-menu}         = ref $_[0] ? shift(@_) : \shift(@_);
                    $option{-prompt}      .= $MENU_MK;
                    $option{-def_nocheck}  = 1;
                }

                # Anything else of the form '-...' is a misspelt option...
                when (/^-\w+$/) { _warn(misc => "prompt(): Unknown option $arg ignored"); }

                # Anything else is part fo the prompt...
                default       { $option{-prompt} .= $arg; }
            }

            # Handle option bundling...
            redo DECODING if $redo && $arg =~ s{\A -.{$redo} (?=.)}{-}xms;
        }
    }

    # Precompute top-level menu, if menuing...
    if (exists $option{-menu}) {
        $option{-menu} = _build_menu($option{-menu},
                                     undef,
                                     $option{-number}||$option{-integer}
                         );
    }

    # Handle return magic on -single...
    if (defined $option{-single} && length($option{-echo}('X')//'echoself')) {
        $option{-return} //= sub{ "\n" };
    }

    # Adjust prompt as necessary...
    if ($option{-argv}) {
        my $progname = $option{-prompt} // $0;
        $progname =~ s{^.*/}{}xms;

        my $HINT = '[enter command line args here]';
        $option{-prompt} = "> $progname  $HINT\r> $progname ";

        $option{-complete} = 'filenames';

        my $not_first;
        $option{-echo}   = sub{
            my $char = shift;
            $option{-prompt} = "> $progname ";  # Sneaky resetting to handle completions
            return $char if $not_first++;
            return "\r> $progname  " . (q{ } x length $HINT) . "\r> $progname $char";
        }
    }
    elsif (!defined $option{-prompt}) {
        $option{-prompt} = '> ';
    }
    elsif ($option{-prompt} =~ m{ \S \z}xms) {
        # If prompt doesn't end in whitespace, make it so...
        $option{-prompt} .= ' ';
    }
    elsif ($option{-prompt} =~ m{ (.*) \n \z}xms) {
        # If prompt ends in a newline, remove it...
        $option{-prompt} = $1;
    }

    # Steal history set name if -h given without a specification...
    $option{-history} //= $option{-prompt};

    # Verify any default satisfies any constraints...
    if (exists $option{-def} && !$option{-def_nocheck}) {
        if (!_verify_input_constraints(\q{},undef,undef,\%option)) {
            _warn( misc =>
                'prompt(): -default value does not satisfy -must constraints'
            );
        }
    }

    return \%option;
}

#====[ Error Handlers ]=========================================

sub _opt_err {
    my ($problem, $option, $expectation) = @_;
    Carp::croak "prompt(): $problem value for $option (expected $expectation)";
}

sub _warn {
    my ($category, @message) = @_;

    return if !warnings::enabled($category);

    my $message = join(q{},@message);
    warn $message =~ /\n$/ ? $message : Carp::shortmess($message);
}


#====[ Utility subroutines ]====================================

# Return the *ARGV filehandle, "magic-opening" it if necessary...
sub _open_ARGV {
    if (!openhandle \*ARGV) {
        $ARGV = shift @ARGV // '-';
        open *ARGV or Carp::croak(qq{prompt(): Can't open *ARGV: $!});
    }
    return \*ARGV;
}

my $INTEGER_PAT = qr{ \A \s*+ [+-]?+ \d++ (?: [Ee] \+? \d+ )? \s*+ \Z }xms;

my $NUMBER_PAT  = qr{
    \A \s*+ [+-]?+
    (?:
        \d++ (?: [.,] \d*+ )?
    |   [.,] \d++
    )
    (?: [eE] [+-]?+ \d++ )?
    \s*+ \Z
}xms;

# Verify interactive constraints...
sub _verify_input_constraints {
    my ($input_ref, $local_fake_input_ref, $outputter_ref, $opt_ref, $extras)
        = @_;

    # Use default if appropriate (but short-circuit checks if -DEFAULT set)...
    my $input = ${$input_ref};
    if (${$input_ref} =~ m{^\R?$}xms && exists $opt_ref->{-def}) {
        return 1 if $opt_ref->{-def_nocheck};
        $input = $opt_ref->{-def}
    }
    chomp $input;

    my $failed;
    # Integer constraint is hard-coded...
    if ($opt_ref->{-integer} && $input !~ $INTEGER_PAT) {
        $failed = $opt_ref->{-prompt} . "(must be an integer) ";
    }

    # Numeric constraint is hard-coded...
    if (!$failed && $opt_ref->{-number} && $input !~ $NUMBER_PAT) {
        $failed = $opt_ref->{-prompt} . "(must be a number) ";
    }

    # Sort and clean up -must list...
    my $must_ref = $opt_ref->{-must} // {};
    my @must_keys     = sort keys %{$must_ref};
    my %clean_key_for = map { $_ => (/^\d+[.:]?\s*(.*)/s ? $1 : $_) } @must_keys;
    my @must_kv_list  = map { $clean_key_for{$_} => $must_ref->{$_} } @must_keys;

    # Combine -yesno and -must constraints...
    my %constraint_for = (
        %{ $extras // {} },
        %{ $opt_ref->{-yesno}{must} // {} },
        @must_kv_list,
    );
    my @constraints = (
        keys %{ $extras // {} },
        keys %{ $opt_ref->{-yesno}{must} // {} },
        @clean_key_for{@must_keys},
    );

    # User-specified constraints...
    if (!$failed && keys %constraint_for) {
        CONSTRAINT:
        for my $msg (@constraints) {
            my $constraint = $constraint_for{$msg};
            next CONSTRAINT if eval { no warnings; local $_ = $input; $input ~~ $constraint; };
            $failed = $msg =~ m{\A [[:upper:]] }xms ? "$msg "
                    : $msg =~ m{\A \W }xms          ? $opt_ref->{-prompt}
                                                    . "$msg "
                    :                                 $opt_ref->{-prompt}
                                                    . "(must $msg) "
                    ;
            last CONSTRAINT;
        }
    }

    # If any constraint not satisfied...
    if ($failed) {
        # Return failure if not actually prompting at the moment...
        return 0 if !$outputter_ref;

        # Redraw post-menu prompt with failure message appended...
        $failed =~ s{.*$MENU_MK}{}xms;
        $outputter_ref->(-style => _wipe_line(), $failed);

        # Reset input collector...
        ${$input_ref}  = q{};

        # Reset faked input, if any...
        if (defined $fake_input && length($fake_input) > 0) {
            $fake_input =~ s{ \A (.*) \R? }{}xm;
            ${$local_fake_input_ref} = $1;
        }

        no warnings 'exiting';
        next INPUT;
    }

    # Otherwise succeed...
    return 1;
}

# Build a sub to read from specified filehandle, with or without timeout...
sub _generate_buffered_reader_from {
    my ($in_fh, $outputter_ref, $opt_ref) = @_;

    # Set-up for timeouts...
    my $fileno      = fileno($in_fh) // -1;
    my $has_timeout = exists $opt_ref->{-timeout} && $fileno >= 0;
    my $timeout     = $opt_ref->{-timeout};
    my $readbits    = q{};
    if ($has_timeout && $fileno >= 0) {
        vec($readbits,$fileno,1) = 1;
    }

    # Set up local faked input, if any...
    my $local_fake_input;
    my $orig_fake_input;
    if (defined $fake_input && length($fake_input) > 0) {
        $fake_input =~ s{ \A (.*) \R? }{}xm;
        $orig_fake_input = $local_fake_input = $1;
    }

    return sub {
        my ($extra_constraints) = @_;

        INPUT:
        while (1) {
            if (!$has_timeout || select $readbits, undef, undef, $timeout) {
                my $input;

                # Real input comes from real filehandles...
                if (!defined $local_fake_input) {
                    $input = readline $in_fh;
                }
                # Fake input has to be typed...
                else {
                    $input = $local_fake_input;
                    sleep 1;
                    for ($local_fake_input =~ m/\X/g) {
                        _simulate_typing();
                        $outputter_ref->(-echostyle => $opt_ref->{-echo}($_));
                    }
                    readline $in_fh;

                    # Check for simulated EOF...
                    if ($input =~ m{^ \s* (?: \cD | \cZ ) }xms) {
                        $input = undef;
                    }
                }

                if (defined $input) {
                    _verify_input_constraints(
                        \$input, \$local_fake_input, $outputter_ref, $opt_ref, $extra_constraints
                    );
                }

                return defined $input && $opt_ref->{-single}
                            ? substr($input, 0, 1)
                            : $input;
            }
            else {
                return;
            }
        }
    }
}

sub _autoflush {
    my ($fh) = @_;
    my $prev_selected = select $fh;
    $| = 1;
    select $prev_selected;
    return;
}

sub _simulate_typing {
    state $TYPING_SPEED = 0.07; # seconds per character
    select undef, undef, undef, rand $TYPING_SPEED;
}

sub _term_width {
    my ($term_width) = eval { no warnings 'deprecated'; Term::ReadKey::GetTerminalSize(\*STDERR) };
    return $term_width // $DEFAULT_TERM_WIDTH;
}

sub _wipe_line {
    return qq{\r} . q{ } x (_term_width()-1) . qq{\r};
}

# Convert a specification into a list of possible completions...
sub _current_completions_for {
    my ($input_text, $opt_ref) = @_;
    my $completer = $opt_ref->{-complete};

    # Isolate the final whitespace-separated word...
    my ($prefix, $lastword)
        = $input_text =~ m{
            (?| ^ (.*\s+) (.*)
              | ^ ()      (.*)
            )
          }xms;

    # Find candidates...
    my @candidates;
    given (ref($completer) || $completer // q{}) {
        # If completer is sub, recursively call it with input words...
        when ('CODE') {
            ($prefix, @candidates)
                = _current_completions_for(
                    $input_text,
                    { %{$opt_ref},
                      -complete => $completer->(split /\s+/, $input_text, -1)
                    }
                  );
        }

        # If completer is array, grep the appropriate elements...
        when ('ARRAY') {
            @candidates = grep { /\A\Q$lastword\E/ } @{$completer};
        }

        # If completer is hash, grep the appropriate keys...
        when ('HASH') {
            @candidates = grep { /\A\Q$lastword\E/ } keys %{$completer};
        }

        # If completer is 'file...', glob up the appropriate filenames...
        when (/^file\w*$/) {
            @candidates = glob($lastword.'*');
        }

        # If completer is 'dir...', glob up the appropriate directories...
        when (/^dir\w*$/) {
            @candidates = grep {-d} glob($lastword.'*');
        }
    }

    chomp @candidates;
    return ($prefix, @candidates);
}


sub _current_history_for {
    my ($prefix, $opt_ref) = @_;

    my $prefix_len = length($prefix);
    return q{}, map { /\A (.*?) \R \Z/x ? $1 : $_ }
               grep { substr($_,0,$prefix_len) eq $prefix }
                    @{ $history_cache{$opt_ref->{-history}} };
}

sub _longest_common_prefix_for {
    my $prefix = shift @_;
    for my $comparison (@_) {
        ($comparison ^ $prefix) =~ m{ \A (\0*) }xms;
        my $common_length = length($1);
        return q{} if !$common_length;
        $prefix = substr($prefix, 0, $common_length);
    }
    return $prefix;
}

sub _display_completions {
    my ($input, @candidates) = @_;

    return q{} if @candidates <= 1;

    # How big is each field in the table?
    my $field_width
        = _term_width() / $COMPLETE_DISPLAY_FIELDS - $COMPLETE_DISPLAY_GAP;

    # Crop the possibilities intelligently to that width...
    for my $candidate (@candidates) {
        substr($candidate, 0, length($input)) =~ s{ \A .* [/\\] }{}xms;
        $candidate
            = sprintf "%-*s", $field_width, substr($candidate,0,$field_width);
    }

    # Collect them into rows...
    my $display = "\n";
    my $gap     = q{ } x $COMPLETE_DISPLAY_GAP;
    while (@candidates) {
        $display .= $gap
                  . join($gap, splice(@candidates, 0, $COMPLETE_DISPLAY_FIELDS))
                  . "\n";
    }

    return $display;
}

sub _generate_unbuffered_reader_from {
    my ($in_fh, $outputter_ref, $opt_ref) = @_;

    my $has_readkey = eval { no warnings 'deprecated'; require Term::ReadKey };

    # If no per-character reads, fall back on buffered input...
    if (!-t $in_fh || !$has_readkey) {
        return _generate_buffered_reader_from($in_fh, $outputter_ref, $opt_ref);
    }

    # Adapt to local control characters...
    my %ctrl = eval { Term::ReadKey::GetControlChars($in_fh) };
    delete $ctrl{$_} for grep { $ctrl{$_} eq "\cA" } keys %ctrl;

    $ctrl{EOF}       //= "\4";
    $ctrl{INTERRUPT} //= "\3";
    $ctrl{ERASE}     //= $^O eq 'MSWin32' ? "\10" : "0177";

    my $ctrl           = join '|', values %ctrl;

    my $VERBATIM_KEY = $ctrl{QUOTENEXT} // $DEFAULT_VERBATIM_KEY;

    # Translate timeout for ReadKey (with 32-bit MAXINT workaround for Windows)...
    my $timeout = !defined $opt_ref->{-timeout} ? 0x7FFFFFFF    # 68 years
                : $opt_ref->{-timeout} == 0     ? -1
                :                                 $opt_ref->{-timeout}
                ;

    return sub {
        my ($extra_constraints) = @_;

        # Short-circuit on unreadable filehandle...
        return if !openhandle($in_fh);

        # Set up direct reading, and prepare to clean up on abnormal exit...
        Term::ReadKey::ReadMode('raw', $in_fh);
        my $prev_SIGINT = $SIG{INT};
        local $SIG{INT} = sub { given ($prev_SIGINT) {
                                    when ('IGNORE')  { }
                                    Term::ReadKey::ReadMode('restore', $in_fh);
                                    when ('DEFAULT') { exit(1) }
                                    when (undef)     { exit(1) }
                                    default {
                                        package main;
                                        no strict 'refs';
                                        $prev_SIGINT->()
                                    }
                                }
                          };

        # Set up local faked input, if any...
        my $local_fake_input;
        my $orig_fake_input;
        if (defined $fake_input && length($fake_input) > 0) {
            $fake_input =~ s{ \A (.*) \R? }{}xm;
            $orig_fake_input = $local_fake_input = $1;
        }

        my $input = q{};
        my $insert_offset = 0;
        INPUT:
        while (1) {
            state $prev_was_verbatim = 0;
            state $completion_level  = 0;
            state $completion_type   = q{};

            # Get next character entered...
            my $next = Term::ReadKey::ReadKey($timeout, $in_fh);

            # Finished with completion mode?
            if (($next//q{}) !~ m{ $COMPLETE_INIT | $COMPLETE_CYCLE }xms) {
                $completion_level = 0;
                $completion_type = q{};
            }

            # Are we faking input?
            my $faking = defined $local_fake_input;

            # If not EOF...
            if (defined $next) {
                # Remember where we were parked...
                my $prev_insert_offset = $insert_offset;

                # Handle interrupts...
                if ($next eq $ctrl{INTERRUPT}) {
                    $SIG{INT}();
                    next INPUT;
                }

                # Handle verbatim quoter...
                elsif (!$prev_was_verbatim && $next eq $VERBATIM_KEY) {
                    $prev_was_verbatim = 1;
                    next INPUT;
                }

                # Handle completions...
                elsif (!$prev_was_verbatim
                       && ( $next =~ $COMPLETE_INIT
                         || $completion_level > 0 && $next =~ $COMPLETE_CYCLE
                       )
                ) {
                    state @completion_list;  # ...all candidates for completion
                    state @completion_ring;  # ..."next" candidate cycle
                    state $completion_ring_first;  # ...special case first time
                    state $completion_prefix;      # ...skipped before completing

                    # Track completion type and level (switch if necessary)...
                    if ($next =~ $COMPLETE_INIT && index($completion_type, $next) < 0) {
                        $completion_type = index($COMPLETE_KEY, $next) >= 0 ? $COMPLETE_KEY : $COMPLETE_HIST;
                        $completion_level = 1;
                    }
                    else {
                        $completion_level++;
                    }

                    # If starting completion, cache completions...
                    if ($completion_level == 1) {
                        ($completion_prefix, @completion_list)
                           = index($COMPLETE_KEY, $next) >= 0
                                ? _current_completions_for($input, $opt_ref)
                                : _current_history_for($input, $opt_ref);
                        @completion_ring = (@completion_list, q{});
                        $completion_ring_first = 1;
                    }

                    # Can only complete if there are completions to be had...
                    if (@completion_list) {
                        # Select the appropriate mode...
                        my $mode = $COMPLETE_MODE{$completion_type}[$completion_level-1]
                                // $COMPLETE_MODE{$completion_type}[-1];

                        # 'longest mode' finds longest consistent prefix...
                        if ($mode =~ /longest/) {
                            $input
                                = $completion_prefix
                                . _longest_common_prefix_for(@completion_list);
                        }
                        # 'full mode' suggests next full match...
                        elsif ($mode =~ /full/) {
                            if (!$completion_ring_first) {
                                if ($next eq $COMPLETE_PREV) {
                                    unshift @completion_ring,
                                            pop @completion_ring;
                                }
                                else {
                                    push @completion_ring,
                                         shift @completion_ring;
                                }
                            }
                            $input = $completion_prefix . $completion_ring[0];
                            $completion_ring_first = 0;
                        }
                        # 'list mode' lists all possibilities...
                        my $list_display = $mode =~ /list/
                            ? _display_completions($input, @completion_list)
                            : q{};

                        # Update prompt with selected completion...
                        $outputter_ref->( -style =>
                            $list_display,
                            _wipe_line(),
                            $opt_ref->{-prompt}, $input
                        );

                        # If last completion was unique choice, completed...
                        if (@completion_list <= 1) {
                            $completion_level = 0;
                        }
                    }
                    next INPUT;
                }

                # Handle erasures (including pushbacks if faking)...
                elsif (!$prev_was_verbatim && $next eq $ctrl{ERASE}) {
                    if (!length $input) {
                        # Do nothing...
                    }
                    elsif ($insert_offset) {
                        # Can't erase past start of input...
                        next INPUT if $insert_offset >= length($input);

                        # Erase character just before cursor...
                        substr($input, -$insert_offset-1, 1, q{});

                        # Redraw...
                        my $input_pre  = substr($input.' ',0,length($input)-$insert_offset+1);
                        my $input_post = substr($input.' ',length($input)-$insert_offset);
                        my $display_pre 
                            = join q{}, map { $opt_ref->{-echo}($_) } $input_pre =~ m/\X/g;
                        my $display_post
                            = join q{}, map { $opt_ref->{-echo}($_) } $input_post =~ m/\X/g;
                        $outputter_ref->( -echostyle =>
                              "\b" x length($display_pre)
                            . join(q{}, map { $opt_ref->{-echo}($_) } $input =~ m/\X/g)
                            . q{ } x length($opt_ref->{-echo}(q{ }))
                            . "\b" x length($display_post)
                        );
                    }
                    else {
                        my $erased = substr($input, -1, 1, q{});
                        if ($faking) {
                            substr($local_fake_input,0,0,$erased);
                        }
                        $outputter_ref->( -nostyle =>
                            map { $_ x (length($opt_ref->{-echo}($_)//'X')) }
                                "\b", ' ', "\b"
                        );
                    }
                    next INPUT;
                }

                # Handle EOF (including cancelling any remaining fake input)...
                elsif (!$prev_was_verbatim && $next eq $ctrl{EOF}) {
                    Term::ReadKey::ReadMode('restore', $in_fh);
                    close $in_fh;
                    undef $fake_input;
                    return length($input) ? $input : undef;
                }

                # Handle escape from faking...
                elsif (!$prev_was_verbatim && $faking && $next eq $FAKE_ESC) {
                    my $lookahead = Term::ReadKey::ReadKey(0, $in_fh);

                    # Two <ESC> implies the current faked line is deferred...
                    if ($lookahead eq $FAKE_ESC) {
                        $fake_input =~ s{ \A }{$orig_fake_input\n}xm;
                    }
                    # Only one <ESC> implies the current faked line is replaced...
                    else {
                        $in_fh->ungetc(ord($lookahead));
                    }
                    undef $local_fake_input;
                    $faking = 0;
                    next INPUT;
                }

                # Handle returns...
                elsif (!$prev_was_verbatim && $next =~ /\A\R\z/) {
                    # Complete faked line, if faked input incomplete...
                    if ($faking && length($local_fake_input)) {
                        for ($local_fake_input =~ m/\X/g) {
                            _simulate_typing();
                            $outputter_ref->(-echostyle => $opt_ref->{-echo}($_));
                        }
                        $input .= $local_fake_input;
                    }

                    # Add newline to the accumulated input string...
                    $input .= $next;

                    # Check that input satisfied any constraints...
                    _verify_input_constraints(
                        \$input, \$local_fake_input, $outputter_ref,
                        $opt_ref, $extra_constraints,
                    );

                    # Echo a default value if appropriate...
                    if ($input =~ m{\A\R?\Z}xms && defined $opt_ref->{-def}) {
                        my $def_val = $opt_ref->{-def};

                        # Try to find the key, for a menu...
                        if (exists $opt_ref->{-menu_curr_level}) {
                            for my $key ( keys %{$opt_ref->{-menu_curr_level}}) {
                                if ($def_val ~~ $opt_ref->{-menu_curr_level}{$key}) {
                                    $def_val = $key;
                                    last;
                                }
                            }
                        }

                        # Echo it as if it had been typed...
                        $outputter_ref->(-echostyle => $opt_ref->{-echo}($def_val));
                    }

                    # Echo the return (or otherwise, as specified)...
                    $outputter_ref->(-echostyle => $opt_ref->{-return}($next));

                    # Clean up, and return the input...
                    Term::ReadKey::ReadMode('restore', $in_fh);

                    # Handle fake EOF...
                    if ($faking && $input =~ m{^ (?: \cD | \cZ) }xms) {
                        return undef;
                    }

                    return $input;
                }

                # Handle anything else...
                elsif ($prev_was_verbatim || $next !~ /$ctrl/) {
                    # If so, get the next fake character...
                    if ($faking) {
                        $next = length($local_fake_input)
                                    ? substr($local_fake_input,0,1,q{})
                                    : q{};
                    }

                    # Handle editing...
                    if ($next eq $EDIT{BACK}) {
                        $insert_offset += ($insert_offset < length $input) ? 1 : 0;
                    }
                    elsif ($next eq $EDIT{FORWARD}) {
                        $insert_offset += ($insert_offset > 0) ? -1 : 0;
                    }
                    elsif ($next eq $EDIT{START}) {
                        $insert_offset = length($input);
                    }
                    elsif ($next eq $EDIT{END}) {
                        $insert_offset = 0;
                    }

                    # Handle non-editing...
                    else {
                        # Check for input restrictions...
                        if (exists $opt_ref->{-guarantee}) {
                            next INPUT if ($input.$next) !~ $opt_ref->{-guarantee};
                        }

                        # Add the new input char to the accumulated input string...
                        if ($insert_offset) {
                            substr($input, -$insert_offset, 0) = $next;
                            $prev_insert_offset++;
                        }
                        else {
                            $input .= $next;
                        }
                    }

                    # Display the character (or whatever was specified)...

                    if ($insert_offset || $prev_insert_offset) {
                        my $input_pre  = substr($input,0,length($input)-$prev_insert_offset);
                        my $input_post = substr($input,length($input)-$insert_offset);
                        my $display_pre 
                            = join q{}, map { $opt_ref->{-echo}($_) } $input_pre =~ m/\X/g;
                        my $display_post
                            = join q{}, map { $opt_ref->{-echo}($_) } $input_post =~ m/\X/g;
                        $outputter_ref->( -echostyle =>
                              "\b" x length($display_pre)
                            . join(q{}, map { $opt_ref->{-echo}($_) } $input =~ m/\X/g)
                            . "\b" x length($display_post)
                        );
                    }
                    elsif ($next !~ $EDIT_KEY) {
                        $outputter_ref->(-echostyle => $opt_ref->{-echo}($next));
                    }

                    # Not verbatim after this...
                    $prev_was_verbatim = 0;
                }
                else {
                    # Not verbatim after mysterious ctrl input...
                    $prev_was_verbatim = 0;

                    next INPUT;
                }
            }
            if ($opt_ref->{-single} || !defined $next || $input =~ m{\Q$/\E$}) {
                # Did we get an acceptable value?
                if (defined $next) {
                    _verify_input_constraints(
                       \$input, \$local_fake_input, $outputter_ref,
                       $opt_ref, $extra_constraints,
                    );
                }

                # Reset terminal...
                Term::ReadKey::ReadMode('restore', $in_fh);

                # Return failure if failed before input...
                return undef if !defined $next && length($input) == 0;

                # Otherwise supply a final newline if necessary...
                if ( $opt_ref->{-single}
                &&   exists $opt_ref->{-return}
                &&   $input !~ /\A\R\z/ ) {
                    $outputter_ref->(-echostyle => $opt_ref->{-return}(q{}));
                }

                return $input;
            }
        }
    }
}

# Build a menu...
sub _build_menu {
    my ($source_ref, $initial_prompt, $is_numeric) = @_;
    my $prompt = ($initial_prompt//q{}) . qq{\n};
    my $final = q{};
    my %value_for;
    my %key_for;
    my @selectors;

    given (ref $source_ref) {
        when ('HASH') {
            my @sorted_keys = sort(keys(%{$source_ref}));
            @selectors = $is_numeric ? (1..@sorted_keys) : ('a'..'z','A'..'Z');
            @key_for{@selectors}   = @sorted_keys;
            @value_for{@selectors} = @{$source_ref}{@sorted_keys};
            $source_ref = \@sorted_keys;
            $_ = 'ARRAY';
            continue;
        }
        when ('SCALAR') {
            $source_ref = [ split "\n", ${$source_ref} ];
            $_ = 'ARRAY';
            continue;
        }
        when ('ARRAY') {
            my @source = @{$source_ref};
            @selectors = $is_numeric ? (1..@source) : ('a'..'z','A'..'Z');
            if (!keys %value_for) {
                @value_for{@selectors} = @source;
            }
            ITEM:
            for my $tag (@selectors) {
                my $item = shift(@source) // last ITEM;
                chomp $item;
                $prompt .= sprintf("%4s. $item\n", $tag);
                $final = $tag;
            }
            if (@source) {
                _warn( misc =>
                    "prompt(): Too many menu items. Ignoring the final " . @source
                );
            }
        }
    }

    my $constraint = $is_numeric       ? '(?:' . join('|',@selectors) .')'
                   : $final =~ /[A-Z]/ ? "[a-zA-$final]"
                   :                     "[a-$final]";
    my $constraint_desc = $is_numeric  ? "[1-$selectors[-1]]" : $constraint;
    $constraint = '\A\s*' . $constraint . '\s*\Z';

    return {
        data       => $source_ref,
        key_for    => \%key_for,
        value_for  => \%value_for,
        prompt     => "$prompt\n",
        is_numeric => $is_numeric,
        constraint => { "Enter $constraint_desc: " => qr/$constraint|$MENU_ESC/ },
    };
}

# Vocabulary that _stylize understands...
my %synonyms = (
    bold      => [qw<boldly strong heavy emphasis emphatic highlight highlighted fort forte>],
    dark      => [qw<darkly dim deep>],
    faint     => [qw<faintly light soft>],
    underline => [qw<underlined underscore underscored italic italics>],
    blink     => [qw<blinking flicker flickering flash flashing>],
    reverse   => [qw<reversed inverse inverted>],
    concealed => [qw<hidden blank invisible>],
    reset     => [qw<normal default standard usual ordinary regular>],
    bright_   => [qw< bright\s+ vivid\s+ >],
    red       => [qw< scarlet vermilion crimson ruby cherry cerise cardinal carmine
                      burgundy claret chestnut copper garnet geranium russet
                      salmon titian coral cochineal rose cinnamon ginger gules >],
    yellow    => [qw< gold golden lemon cadmium daffodil mustard primrose tawny
                      amber aureate canary champagne citrine citron cream goldenrod honey straw >],
    green     => [qw< olive jade pea emerald lime chartreuse forest sage vert >],
    cyan      => [qw< aqua aquamarine teal turquoise ultramarine >],
    blue      => [qw< azure cerulean cobalt indigo navy sapphire >],
    magenta   => [qw< amaranthine amethyst lavender lilac mauve mulberry orchid periwinkle
                      plum pomegranate violet purple aubergine cyclamen fuchsia modena puce
                      purpure >],
    black     => [qw< charcoal ebon ebony jet obsidian onyx raven sable slate >],
    white     => [qw< alabaster ash chalk ivory milk pearl silver argent >],
);

# Back-mapping to standard terms...
my %normalize
    = map { join('|', map { "$_\\b" } reverse sort @{$synonyms{$_}}) => $_ }
          keys %synonyms;

my $BACKGROUND = qr{
     (\S+) \s+ (?: behind | beneath | below | under(?:neath)? )\b
   | \b (?:upon|over|on) \s+ (?:an?)? \s+ (.*?) \s+ (?:background|bg|field) \b
   | \b (?:upon\s+ | over\s+ | (?:(on|upon|over)\s+a\s+)?  (?:background|bg|field) \s+ (?:of\s+|in\s+)? | on\s+) (\S+)
}ixms;

# Convert a description to ANSI colour codes...
sub _stylize {
    my $spec = shift // q{};

    # Handle arrays and hashes as args...
    if (ref($spec) eq 'ARRAY') {
        $spec = join q{ }, @{$spec};
    }
    elsif (ref($spec) eq 'HASH') {
        $spec = join q{ }, keys %{$spec};
    }

    # Ignore punctuation...
    $spec =~ s/[^\w\s]//g;

    # Handle backgrounds...
    $spec =~ s/$BACKGROUND/on_$+/g;

    # Apply standard translations...
    for my $pattern (keys %normalize) {
        $spec =~ s{\b(on_|\b) $pattern}{($1//q{}).$normalize{$pattern}}geixms;
    }

    # Ignore anything unknown...
    $spec =~ s{((?:on_)?(\S+))}{ exists $synonyms{$2} ? $1 : q{} }gxmse;

    # Build ANSI terminal codes around text...
    my $raw_text = join q{}, @_;
    my ($prews, $text, $postws) = $raw_text =~ m{\A (\s*) (.*?) (\s*) \Z}xms;
    my @style = split /\s+/, $spec;
    return $prews
         . ( @style ? Term::ANSIColor::colored(\@style, $text) : $text )
         . $postws;
}

# Build a subroutine that prints printable chars to the specified filehandle...
sub _std_printer_to {
    my ($out_filehandle, $opt_ref) = @_;
    no strict 'refs';
    _autoflush($out_filehandle);
    if (eval { require Term::ANSIColor}) {
        return sub {
            my $style = shift;
            my @loc = (@_);
            s{\e}{^}gxms for @loc;
            print {$out_filehandle} _stylize($opt_ref->{$style}(@loc), @loc);
        };
    }
    else {
        return sub {
            shift; # ...ignore style
            my @loc = (@_);
            s{\e}{^}gxms for @loc;
            print {$out_filehandle} @loc;
        };
    }
}

# Build a subroutine that prints to nowhere...
sub _null_printer {
    return sub {};
}

1; # Magic true value required at end of module
__END__

=head1 NAME

IO::Prompter - Prompt for input, read it, clean it, return it.


=head1 VERSION

This document describes IO::Prompter version 0.004015


=head1 SYNOPSIS

    use IO::Prompter;

    while (prompt -num, 'Enter a number') {
        say "You entered: $_";
    }

    my $passwd
        = prompt 'Enter your password', -echo=>'*';

    my $selection
        = prompt 'Choose wisely...', -menu => {
                wealth => [ 'moderate', 'vast', 'incalculable' ],
                health => [ 'hale', 'hearty', 'rude' ],
                wisdom => [ 'cosmic', 'folk' ],
          }, '>';


=head1 CAVEATS

=over

=item 1.

Several features of this module are known to have problems under
Windows. If using that platform, you may have more success
(and less distress) by trying IO::Prompt::Tiny, IO::Prompt::Simple,
or IO::Prompt::Hooked first.

=item 2.

By default the C<prompt()> subroutine does not return a string; it
returns an object with overloaded string and boolean conversions.
This object B<I<always>> evaluates true in boolean contexts, unless the
read operation actually failed. This means that the object evaluates
true I<even when the input value is zero or
an empty string.> See L<"Returning raw data"> to turn off this 
(occasionally counter-intuitive) behaviour.

=back

=head1 DESCRIPTION

IO::Prompter exports a single subroutine, C<prompt>, that prints a
prompt (but only if the program's selected input and output streams are
connected to a terminal), then reads some input, then chomps it, and
finally returns an object representing that text.

The C<prompt()> subroutine expects zero-or-more arguments.

Any argument that starts with a hyphen (C<->) is treated as a named
option (many of which require an associated value, that may be passed as
the next argument). See L<"Summary of options"> and L<"Options
reference"> for details of the available options.

Any other argument that is a string is treated as (part of) the prompt
to be displayed. All such arguments are concatenated together before the
prompt is issued. If no prompt string is provided, the string
C<< '> ' >> is used instead.

Normally, when C<prompt()> is called in either list or scalar context,
it returns an opaque object that autoconverts to a string. In scalar
boolean contexts this return object evaluates true if the input
operation succeeded. In list contexts, if the input operation fails
C<prompt()> returns an empty list instead of a return object. This
allows failures in list context to behave correctly (i.e. be false).

If you particularly need a list-context call to C<prompt()> to always
return a value (i.e. even on failure), prefix the call with C<scalar>:

    # Only produces as many elements
    # as there were successful inputs...
    my @data = (
        prompt(' Name:'),
        prompt('  Age:'),
        prompt('Score:'),
    );

    # Always produces exactly three elements
    # (some of which may be failure objects)...
    my @data = (
        scalar prompt(' Name:'),
        scalar prompt('  Age:'),
        scalar prompt('Score:'),
    );

In void contexts, C<prompt()> still requests input, but also issues a
warning about the general uselessness of performing an I/O operation
whose results are then immediately thrown away.
See L<"Useful useless uses of C<prompt()>"> for an exception to this.

The C<prompt()> function also sets C<$_> if it is called in a boolean
context but its return value is not assigned to a variable. Hence, it is
designed to be a drop-in replacement for C<readline> or C<< <> >>.

=head1 INTERFACE

All the options for C<prompt()> start with a hyphen (C<->).
Most have both a short and long form. The short form is always
the first letter of the long form.

Most options have some associated value. For short-form options, this
value is specified as a string appended to the option itself. The
associated value for long-form options is always specified as a
separated argument, immediately following the option (typically
separated from it by a C<< => >>).

Note that this implies that short-form options may not be able to
specify every possible associated value (for example, the short-form
C<-d> option cannot specify defaults with values C<'efault'> or
C<'$%^!'>).  In such cases, just use the long form of the option
(for example: S<< C<< -def => 'efault' >> >> or C<< -default=>'$%^!' >>).


=head2 Summary of options

Note: For options preceded by an asterisk, the short form is actually
a Perl file operator, and hence cannot be used by itself.
Either use the long form of these options,
or L<bundle them with another option|"Bundling short-form options">,
or add a L<"no-op"|"Escaping otherwise magic options"> to them.


    Short   Long
    form    form               Effect
    =====   =============      ======================================

    -a      -argv              Prompt for @ARGV data if !@ARGV

            -comp[lete]=>SPEC  Complete input on <TAB>, as specified

    -dSTR   -def[ault]=>STR    What to return if only <ENTER> typed
            -DEF[AULT]=>STR    (as above, but skip any -must checking)

  * -e[STR] -echo=>STR         Echo string for each character typed

            -echostyle=>SPEC   What colour/style to echo input in

  * -f      -filenames         Input should be name of a readable file

            -fail=>VALUE       Return failure if input smartmatches value

            -guar[antee]=>SPEC Only allow the specified words to be entered

    -h[STR] -hist[ory][=>SPEC] Specify the history set this call belongs to

            -in=>HANDLE        Read from specified handle

    -i      -integer[=>SPEC]   Accept only valid integers (that smartmatch SPEC)

    -k      -keyletters        Accept only keyletters (as specified in prompt)

  * -l      -line              Don't autochomp

            -menu=>SPEC        Specify a menu of responses to be displayed

            -must=>HASHREF     Specify requirements/constraints on input

    -n      -num[ber][=>SPEC]  Accept only valid numbers (that smartmatch SPEC)

            -out=>HANDLE       Prompt to specified handle

            -prompt=>STR       Specify prompt explicitly

  * -rSTR   -ret[urn]=>STR     After input, echo this string instead of <CR>

  * -s -1   -sing[le]          Return immediately after first key pressed

            -stdio             Use STDIN and STDOUT for prompting

            -style=>SPEC       What colour/style to display the prompt text in

    -tNUM   -time[out]=>NUM    Specify a timeout on the input operation

    -v      -verb[atim]        Return the input string (no context sensitivity)

            -void              Don't complain in void context

  * -w      -wipe              Clear screen
            -wipefirst         Clear screen on first prompt() call only

  * -y      -yes    [=> NUM]   Return true if [yY] entered, false otherwise
    -yn     -yesno  [=> NUM]   Return true if [yY] entered, false if [nN]
    -Y      -Yes    [=> NUM]   Return true if Y entered, false otherwise
    -YN     -YesNo  [=> NUM]   Return true if Y entered, false if N

  * -_                         No-op (handy for bundling ambiguous short forms)


=head2 Automatic options

Any of the options listed above (and described in detail below) can be
automatically applied to every call to C<prompt()> in the current
lexical scope, by passing them (via an array reference) as the arguments
to a C<use IO::Prompter> statement.

For example:

    use IO::Prompter;

    # This call has no automatically added options...
    my $assent = prompt "Do you wish to take the test?", -yn;

    {
        use IO::Prompter [-yesno, -single, -style=>'bold'];

        # These three calls all have: -yesno, -single, -style=>'bold' options
        my $ready = prompt 'Are you ready to begin?';
        my $prev  = prompt 'Have you taken this test before?';
        my $hints = prompt 'Do you want hints as we go?';
    }

    # This call has no automatically added options...
    scalar prompt 'Type any key to start...', -single;

The current scope's lexical options are always I<prepended> to the
argument list of any call to C<prompt()> in that scope.

To turn off any existing automatic options for the rest of the current
scope, use:

    use IO::Prompter [];


=head2 Prebound options

You can also ask IO::Prompter to export modified versions of C<prompt()>
with zero or more options prebound. For example, you can request an
C<ask()> subroutine that acts exactly like C<prompt()> but has the C<-
yn> option pre-specified, or a C<pause()> subroutine that is C<prompt()>
with a "canned" prompt and the C<-echo>, C<-single>, and C<-void> options.

To specify such subroutines, pass a single hash reference when
loading the module:

    use IO::Prompter {
        ask     => [-yn],
        pause   => [-prompt=>'(Press any key to continue)', -echo, -single, -void],
    }

Each key will be used as the name of a separate subroutine to be
exported, and each value must be an array reference, containing the
arguments that are to be automatically supplied.

The resulting subroutines are simply lexically scoped wrappers around
C<prompt()>, with the specified arguments prepended to the normal
argument list, equivalent to something like:

    my sub ask {
        return prompt(-yn, @_);
    }

    my sub pause {
        return prompt(-prompt=>'(Press any key to continue)', -echo, -single, -void, @_);
    }

Note that these subroutines are lexically scoped, so if you want to use
them throughtout a source file, they should be declared in the outermost
scope of your program.


=head2 Options reference

=head3 Specifying what to prompt

=over 4

C<< -prompt => I<STRING> >>

C<< -pI<STRING> >>

=back

By default, any argument passed to C<prompt()> that does not begin with
a hyphen is taken to be part of the prompt string to be displayed before
the input operation. Moreover, if no such string is specified in the
argument list, the function supplies a default prompt (C<< '> ' >>)
automatically.

The C<-prompt> option allows you to specify a prompt explicitly, thereby
enabling you to use a prompt that starts with a hyphen:

    my $input
        = prompt -prompt=>'-echo';

or to disable prompting entirely:

    my $input
        = prompt -prompt => "";

Note that the use of the C<-prompt> option doesn't override other string
arguments, it merely adds its argument to the collective prompt.

=head4 Prompt prettification

If the specified prompt ends in a non-whitespace character, C<prompt()>
adds a single space after it, to better format the output. On the other
hand, if the prompt ends in a newline, C<prompt()> removes that
character, to keep the input position on the same line as the prompt.

You can use that second feature to override the first, if necessary. For
example, if you wanted your prompt to look like:

    Load /usr/share/dict/_

(where the _ represents the input cursor), then a call like:

    $filename = prompt 'Load /usr/share/dict/';

would not work because it would automatically add a space, producing:

    Load /usr/share/dict/ _

But since a terminal newline is removed, you could achieve the desired effect
with:

    $filename = prompt "Load /usr/share/dict/\n";

If for some reason you I<do> want a newline at the end of the prompt (i.e.
with the input starting on the next line) just put two newlines at the end
of the prompt. Only the very last one will be removed.


=head3 Specifying how the prompt looks

=over 4

C<< -style  => I<SPECIFICATION> >>

=back

If the C<Term::ANSIColor> module is available, this option can be used
to specify the colour and styling (e.g. bold, inverse, underlined, etc.)
in which the prompt is displayed.

You can can specify that styling as a single string:

    prompt 'next:' -style=>'bold red on yellow';

or an array of styles:

    prompt 'next:' -style=>['bold', 'red', 'on_yellow'];

The range of styles and colour names that the option understands is
quite extensive. All of the following work as expected:

    prompt 'next:' -style=>'bold red on yellow';

    prompt 'next:' -style=>'strong crimson on gold';

    prompt 'next:' -style=>'highlighted vermilion, background of cadmium';

    prompt 'next:' -style=>'vivid russet over amber';

    prompt 'next:' -style=>'gules fort on a field or';

However, because C<Term::ANSIColor> maps everything back to the
standard eight ANSI text colours and seven ANSI text styles, all of the
above will also be rendered identically. See that module's
documentation for details.

If C<Term::ANSIColor> is not available, this option is silently ignored.

Please bear in mind that up to 10% of people using your interface will
have some form of colour vision impairment, so its always a good idea
to differentiate information by style I<and> colour, rather than by colour
alone. For example:

    if ($dangerous_action) {
        prompt 'Really proceed?', -style=>'bold red underlined';
    }
    else {
        prompt 'Proceed?', -style=>'green';
    }

Also bear in mind that (even though C<-style> does support the C<'blink'>
style) up to 99% of people using your interface will have Flashing Text
Tolerance Deficiency. Just say "no".


=head3 Specifying where to prompt

=over 4

C<< -out => FILEHANDLE >>

C<< -in => FILEHANDLE >>

C<< -stdio >>

=back

The C<-out> option (which has no short form) is used to specify
where the prompt should be written to. If this option is not specified,
prompts are written to the currently C<select>-ed filehandle. The most
common usage is:

    prompt(out => *STDERR)

The C<-in> option (which also has no short form) specifies where the input
should be read from. If this option is not specified, input is read from
the C<*ARGV> filehandle. The most common usage is:

    prompt(in => *STDIN)

in those cases where C<*ARGV> has been opened to a file, but you still
wish to interact with the terminal (assuming C<*STDIN> is opened to that
terminal).

The C<-stdio> option (which again has no short form) is simply a shorthand
for: C<< -in => *STDIN, -out => *STDOUT >>. This is particularly useful when
there are arguments on the commandline, but you don't want prompt to treat
those arguments as filenames for magic C<*ARGV> reads.


=head3 Specifying how long to wait for input

=over 4

C<< -timeout => I<N> >>

C<< -tI<N> >>

=back

Normally, the C<prompt()> function simply waits for input. However,
you can use this option to specify a timeout on the read operation.
If no input is received within the specified I<N> seconds, the call
to C<prompt()> either returns the value specified by
L<the C<-default> option|"Specifying what to return by default">
(if any), or else an object indicating the read failed.

Note that, if the short form is used, I<N> must be an integer. If the long
form is used, I<N> may be an integer or floating point value.

You can determine whether an input operation timed out, even if a
default value was returned, by calling the C<timedout()> method on the
object returned by C<prompt()>:

    if (prompt('Continue?', -y1, -timeout=>60) && !$_->timedout) {
        ...
    }

If a time-out occurred, the return value of C<timedout()> is a string
describing the timeout, such as:

    "timed out after 60 seconds"


=head3 Providing a menu of responses

=over

=item C<< -menu => I<SPECIFICATION> >>

=back

You can limit the allowable responses to a prompt, by providing a menu.

A menu is specified using the C<-menu> option, and the menu choices
are specified as an argument to the option, either as a reference to
an array, hash, or string, or else as a literal string.

If the menu is specified in a hash, C<prompt()> displays the keys of the
hash, sorted alphabetically, and with each alternative marked with a
single alphabetic character (its "selector key").

For example, given:

    prompt 'Choose...',
           -menu=>{ 'live free'=>1, 'die'=>0, 'transcend'=>-1 },
           '>';

C<prompt()> will display:

    Choose...
        a. die
        b. live free
        c. transcend
    > _

It will then only permit the user to enter a valid selector key (in the
previous example: 'a', 'b', or 'c'). Once one of the alternatives is
selected, C<prompt()> will return the corresponding value from the hash
(0, 1, or -1, respectively, in this case).

Note that the use of alphabetics as selector keys inherently limits the
number of usable menu items to 52. See L<"Numeric menus"> for a way to
overcome this limitation.

A menu is treated like a special kind of prompt, so that any
other prompt strings in the C<prompt()> call will appear either before or
after the menu of choices, depending on whether they appear before or
after the menu specification in the call to C<prompt()>.

If an array is used to specify the choices:

    prompt 'Choose...',
           -menu=>[ 'live free', 'die', 'transcend' ],
           '>';

then each array element is displayed (in the original array order) with
a selector key:

    Choose...
        a. live free
        b. die
        c. transcend
    > _

and C<prompt()> returns the element corresponding to the selection (i.e.
it returns 'live free' if 'a' is entered, 'die' if 'b' is entered, or
'transcend' if 'c' is entered).

Hence, the difference between using an array and a hash is that the
array allows you to control the order of items in the menu, whereas a
hash allows you to show one thing (i.e. keys) but have something related
(i.e. values) returned instead.

If the argument after C<-menu> is a string or a reference to a string, the
option splits the string on newlines, and treats the resulting list as if it
were an array of choices. This is useful, for example, to request the user
select a filename:

    my $files = `ls`;
    prompt 'Select a file...', -menu=>$files, '>';


=head4 Numbered menus

As the previous examples indicate, each menu item is given a unique
alphabetic selector key. However, if the C<-number> or C<-integer>
option is specified as well:

    prompt 'Choose...',
           -number,
           -menu=>{ 'live free'=>1, 'die'=>0, 'transcend'=>-1 },
           '>';

C<prompt()> will number each menu item instead, using consecutive integers
as the selector keys:

    Choose...
        1. die
        2. live free
        3. transcend
    > _

This allows for an unlimited number of alternatives in a single menu,
but prevents the use of C<-single> for one-key selection from menus if
the menu has more than nine items.


=head4 Hierarchical menus

If you use a hash to specify a menu, the values of the hash do not have
to be strings. Instead, they can be references to nested hashes or
arrays.

This allows you to create hierarchical menus, where a selection at the
top level may lead to a secondary menu, etc. until an actual choice is
possible. For example, the following call to prompt:

    my $choices = {
        animates => {
            animals => {
                felines => [qw<cat lion lynx>],
                canines => [qw<dog fox wolf>],
                bovines => [qw<cow ox buffalo>],
            },
            fish => [qw<shark carp trout bream>],
        },
        inanimates => {
            rocks     => [qw<igneous metamorphic sedimentary>],
            languages => [qw<Perl Python Ruby Tcl>],
        },
    };

    my $result = prompt -1, 'Select a species...', -menu=>$choices, '> ';

might result in an interaction like this:

    Select a species...
    a.  animates
    b.  inanimates
    > a

    Select from animates:
    a.  animals
    b.  fish
    > b

    Select from fish:
    a.  shark
    b.  carp
    c.  trout
    d.  bream
    > c

At which point, C<prompt()> would return the string C<'trout'>.

Note that you can nest an arbitrary number of hashes, but that each
"bottom" level choice has to be either a single string, or an array
of strings.


=head4 Navigating hierarchical menus

Within a hierarchical menu, the user must either select a valid option
(by entering the corresponding letter), or else may request that they be
taken back up a level in the hierarchy, by entering C<< <ESC> >>.
Pressing C<< <ESC> >> at the top level of a menu causes the call to
C<prompt()> to immediately return with failure.


=head3 Simulating a command-line

=over 4

C<< -argv >>

C<< -a  >>

=back

The C<prompt()> subroutine can be used to request that the user provide
command-line arguments interactively. When requested, the input
operation is only carried out if C<@ARGV> is empty.

Whatever the user enters is broken into a list and assigned to C<@ARGV>.

The input is first C<glob>bed for file expansions, and has any
environment variables (of the form C<$VARNAME> interpolated). The
resulting string is then broken into individual words, except where
parts of it contain single or double quotes, the contents of which are
always treated as a single string.

This feature is most useful during development, to allow a program to be
run from within an editor, and yet pass it a variety of command-lines. The
typical usage is (at the start of a program):

    use IO::Prompter;
    BEGIN { prompt -argv }

However, because this pattern is so typical, there is a shortcut:

    use IO::Prompter -argv;

You can also specify the name with which the program args, are to
be prompted, in the usual way (i.e. by providing a prompt):

    use IO::Prompter -argv, 'demo.pl';

Note, however, the critical difference between that shortcut
(which calls C<prompt -argv> when the module is loaded) and:

    use IO::Prompter [-argv];

(which sets C<-argv> as an automatic option for every subsequent call to
C<prompt()> in the current lexical scope).

Note too that the C<-argv> option also implies C<-complete=>'filenames'>.


=head3 Input autocompletion

=over 4

C<< -comp[lete] => I<SPECIFICATION> >>

=back

When this option is specified, the C<prompt()> subroutine will complete
input using the specified collection of strings. By default, when
completion is active, word completion is requested using the C<< <TAB> >>
key, but this can be changed by setting the C<$IO_PROMPTER_COMPLETE_KEY>
environment variable. Once completion has been initiated, you can use
the completion key or else C<< <CTRL-N> >> to advance to the next completion
candidate. You can also use C<< <CTRL-P> >> to back up to the previous
candidate.

The specific completion mechanism can be defined either using a
subroutine, an array reference, a hash reference, or a special string:

    Specification       Possible completions supplied by...

      sub {...}         ...whatever non-subroutine specification
                        (as listed below) is returned when the
                        subroutine is called. The subroutine is passed
                        the words of the current input text, split on
                        whitespace, as its argument list.

        [...]           ...the elements of the array

        {...}           ...the keys of the hash

     'filenames'        ...the list of files supplied by globbing the
                        last whitespace-separated word of the input text

     'dirnames'         ...the list of directories supplied by globbing the
                        last whitespace-separated word of the input text

If an array or hash is used, only those elements or keys that begin with
the last whitespace-separated word of the current input are offered as
completions.

For example:

    # Complete with the possible commands...
    my $next_cmd
        = prompt -complete => \%cmds;

    # Complete with valid usernames...
    my $user
        = prompt -complete => \@usernames;

    # Complete with valid directory names...
    my $file
        = prompt -complete => 'dirnames';

    # Complete with cmds on the first word, and filenames on the rest...
    my $cmdline
        = prompt -complete => sub { @_ <= 1 ? \%cmds : 'filenames' };


=head4 Completing from your own input history

The C<prompt()> subroutine also tracks previous input and allows you to
complete with that instead. No special option is required, as the
feature is enabled by default.

At the start of a prompted input, the user can cycle backwards through
previous inputs by pressing C<< <CTRL-R> >> (this can be changed
externally by setting the C<$IO_PROMPTER_HISTORY_KEY> environment
variable, or internally by assigning a new keyname to
C<$ENV{IO_PROMPTER_HISTORY_KEY}>). After the first C<< <CTRL-R> >>,
subsequent C<< <CTRL-R> >>'s will recall earlier inputs. You can also
use C<< <CTRL-N> >> and C<< <CTRL-P> >>
(as in L<user-specified completions|"Input autocompletion">) to move
back and forth through your input history.

If the user has already typed some input, the completion mechanism
will only show previous inputs that begin with that partial input.


=head4 History sets

=over 4

=item C<< -h[NAME] >>

=item C<< -hist[ory] [=> NAME] >>

=back

By default, IO::Prompter tracks every call to C<prompt()> within a
program, and accumulates a single set of history completions for all of
them. That means that, at any prompt, C<< <CTRL-R> >> will take the user
back through I<every> previous input, regardless of which call to
C<prompt()> originally retrieved it.

Sometimes that's useful, but sometimes you might prefer that different
calls to C<prompt()> retained distinct memories. For example, consider
the following input loop:

    while (my $name = prompt 'Name:') {
        my $grade   = prompt 'Grade:', -integer;
        my $comment = prompt 'Comment:';
        ...
    }

If you're entering a name, there's no point in C<prompt()> offering
to complete it with previous grades or comments. In fact, that's
just annoying.

IO::Prompter allows you to specify that a particular call to
C<prompt()> belongs to a particular "history set". Then it completes
input history using only the history of those calls belonging to the
same history set.

So the previous example could be improved like so:

    while (my $name = prompt 'Name:', -hNAME) {
        my $grade   = prompt 'Grade:', -hGRADE, -integer;
        my $comment = prompt 'Comment:', -hOTHER;
        ...
    }

Now, when prompting for a name, only those inputs in the C<'NAME'>
history set will be offered as history completions. Likewise only
previous grades will be recalled when prompting for grades and earlier
only comments when requesting comments.

If you specify the C<-h> or C<-history> option without providing the
name of the required history set, C<prompt()> uses the prompt text
itself as the name of the call's history set. So the previous example
would work equally well if written:

    while (my $name = prompt 'Name:', -h) {
        my $grade   = prompt 'Grade:', -h, -integer;
        my $comment = prompt 'Comment:', -h;
        ...
    }

though now the names of the respective history sets would now be
C<'Name: '>, C<'Grade: '>, and C<'Comment: '>. This is by far the more
common method of specifying history sets, with explicitly named sets
generally only being used when two or more separate calls to
C<prompt()> have to share a common history despite using distinct
prompts. For example:

    for my $n (1..3) {
        $address .= prompt "Address (line $n):", -hADDR;
    }

If you specify C<'NONE'> as the history set, the input is not
recorded in the history. This is useful when inputting passwords.


=head4 Configuring the autocompletion interaction

By default, when user-defined autocompletion is requested, the
C<prompt()> subroutine determines the list of possible completions,
displays it above the prompt, and completes to the longest common
prefix. If the completion key is pressed again immediately, the
subroutine then proceeds to complete with each possible completion in a
cyclic sequence. This is known as "list+longest full" mode.

On the other hand, when historical completion is requested, C<prompt()>
just immediately cycles through previous full inputs. This is known as "full"
mode.

You can change these behaviours by setting the
C<$IO_PROMPTER_COMPLETE_MODES> and C<$IO_PROMPTER_HISTORY_MODES>
environment variables I<before the module is loaded> (either in your shell,
or in a C<BEGIN> block before the module is imported).

Specifically, you can set the individual string values of either of
these variables to a whitespace-separated sequence containing any of the
following:

    list         List all options above the input line

    longest      Complete to the longest common prefix

    full         Complete with each full match in turn

For example:

    # Just list options without actually completing...
    BEGIN{ $ENV{IO_PROMPTER_COMPLETE_MODES} = 'list'; }

    # Just cycle full alternatives on each <TAB>...
    BEGIN{ $ENV{IO_PROMPTER_COMPLETE_MODES} = 'full'; }

    # For history completion, always start with the
    # longest common prefix on the first <CTRL-R>,
    # then just list the alternatives on a subsequent press...
    BEGIN{ $ENV{IO_PROMPTER_HISTORY_MODES} = 'longest list'; }


=head3 Specifying what to return by default

=over

C<< -DEF[AULT] => I<STRING> >>

C<< -def[ault] => I<STRING> >>

C<< -dI<STRING> >>

=back

If a default value is specified, that value will be returned if the user
enters an empty string at the prompt (i.e. if they just hit
C<< <ENTER>/<RETURN> >> immediately) or if the input operation times out under
L<the C<timeout> option|"Specifying how long to wait for input">.

Note that the default value is not added to the prompt, unless you
do so yourself. A typical usage might therefore be:

    my $frequency
        = prompt "Enter polling frequency [default: $DEF_FREQ]",
                 -num, -def=>$DEF_FREQ;

You can determine if the default value was autoselected (as opposed to
the same value being typed in explicitly) by calling the C<defaulted()>
method on the object returned by C<prompt()>, like so:

    if ($frequency->defaulted) {
        say "Using default frequency";
    }

If you use the L<< C<-must> option|"Constraining what can be returned" >>
any default value must also satisfy all the constraints you specify,
unless you use the C<-DEFAULT> form, which skips constraint checking
when the default value is selected.

If you use the L<< C<-menu> option|"Providing a menu of responses" >>,
the specified default value will be returned immediately C<< <ENTER>/<RETURN> >> is
pressed, regardless of the depth you are within the menu. Note that the
default value specifies the value to be returned, not the selector key
to be entered. The default value does not even have to be one of the
menu choices.


=head3 Specifying what to echo on input

=over

C<< -echo => I<STR> >>

C<< -eI<STR> >>

=back

When this option is specified, the C<prompt()> subroutine will echo the
specified string once for each character that is entered. Typically this
would be used to shroud a password entry, like so:

    # Enter password silently:
    my $passwd
        = prompt 'Password:', -echo=>"";

    # Echo password showing only asterisks:
    my $passwd
        = prompt 'Password:', -echo=>"*";

As a special case, if the C<-echo> value contains a slash (C</>) and the
any of the <-yesno> options is also specified, the substring before the
slash is taken as the string to echo for a 'yes' input, and the
substring after the slash is echoed for a 'no' input.

Note that this option is only available when the Term::ReadKey module
is installed. If it is used when that module is not available, a warning
will be issued.


=head4 Specifying how to echo on input

C<< -echostyle => I<SPECIFICATION> >>

The C<-echostyle> option works for the text the user types in
the same way that the C<-style> option works for the prompt.
That is, you can specify the style and colour in which the user's
input will be rendered like so:

    # Echo password showing only black asterisks on a red background:
    my $passwd
        = prompt 'Password:', -echo=>"*", -echostyle=>'black on red';

Note that C<-echostyle> is completely independent of C<-echo>:

    # Echo user's name input in bold white:
    my $passwd
        = prompt 'Name:', -echostyle=>'bold white';

The C<-echostyle> option requires C<Term::ANSIColor>, and will
be silently ignored if that module is not available.


=head4 Input editing

When the Term::ReadKey module is available, C<prompt()> also honours a
subset of the usual input cursor motion commands:

=over

=item C<CTRL-B>

Move the cursor back one character

=item C<CTRL-F>

Move the cursor forward one character

=item C<CTRL-A>

Move the cursor to the start of the input

=item C<CTRL-E>

Move the cursor to the end of the input

=back


=head3 Specifying when input should fail

=over 4

C<< -fail => I<VALUE> >>

C<< -fI<STRING> >>

=back

If this option is specified, the final input value is compared with the
associated string or value, by smartmatching just before the call to
C<prompt()> returns. If the two match, C<prompt()> returns a failure
value. This means that instead of writing:

    while (my $cmd = prompt '>') {
        last if $cmd eq 'quit';
        ...
    }

you can just write:

    while (my $cmd = prompt '>', -fail=>'quit') {
        ...
    }


=head3 Constraining what can be typed

=over 4

=item C<< -guar[antee] => SPEC >>

=back

This option allows you to control what input users can provide.
The specification can be a regex or a reference to an array or a hash.

If the specification is a regex, that regex is matched against the input
so far, every time an extra character is input. If the regex ever fails
to match, the guarantee fails.

If the specification is an array, the input so far is matched against
the same number of characters from the start of each of the (string)
elements of the array. If none of these substrings match the input, the
guarantee fails.

If the specification is a hash, the input so far is matched against the
same number of characters from the start of each key of the hash. If
none of these substrings match the input, the guarantee fails.

If the guarantee fails, the input is rejected
(just as L<< the C<-must> option|"Constraining what can be returned" >>
does). However, unlike C<-must>, C<-guarantee> rejects the input
character-by-character as it typed, and I<before> it is even echoed. For
example, if your call to C<prompt()> is:

    my $animal = prompt -guarantee=>['cat','dog','cow'];

then at the prompt:

    > _

you will only be able to type in 'c' or 'd'. If you typed 'c', then you would
only be able to type 'a' or 'o'. If you then typed 'o', you would only be able
to type 'w'.

In other words, C<-guarantee> ensures that you can only type in a valid input,
and simply ignores any typing that would not lead to such an input.

To help users get the input right, specifying C<-guarantee> as an array
or hash reference also automatically specifies a
L<< C<-complete> option|"Input autocompletion" >> with the array or hash
as its completion list as well. So, whenever a C<-guarantee> is in
effect, the user can usually autocomplete the acceptable inputs.

Note, however, that C<-guarantee> can only reject (or autocomplete)
input as it is typed if the Term::ReadKey module is available. If that
module cannot be loaded, C<-guarantee> only applies its test after the
C<< <ENTER>/<RETURN> >> key is pressed, and there will be no autocompletion
available.

=head4 Constraining input to numbers

=over 4

=item C<< -i >>

=item C<< -integer [=> SPEC] >>

=item C<< -n  >>

=item C<< -num[ber] [=> SPEC] >>

=back

If any of these options are specified, C<prompt()> will only accept a valid
integer or number as input, and will reprompt until one is entered.

If you need to restrict the kind of number further (say, to positive
integers), you can supply an extra constraint as an argument to the
long-form option. Any number entered must satisfy this constraint by
successfully smart-matching it. For example:

    $rep_count = prompt 'How many reps?', -integer => sub{ $_ > 0 };

    $die_roll = prompt 'What did you roll?', -integer => [1..6];

    $factor = prompt 'Prime factor:', -integer => \&is_prime;

    $score = prompt 'Enter score:', -number => sub{ 0 <= $_ && $_ <= 100 };

If the constraint is specified as a subroutine, the entered number will be
passed to it both as its single argument and in C<$_>.

You cannot pass a scalar value directly as a constraint, except those strings
listed below. If you want a scalar value as a constraint, use a regex or
array reference instead:

    # Wrong...
    $answer = prompt "What's the ultimate answer?",
                      -integer => 42;

    # Use this instead...
    $answer = prompt "What's the ultimate answer?",
                     -integer => qr/^42$/;

    # Or this...
    $answer = prompt "What's the ultimate answer?",
                     -integer => [42];


Only the following strings may be passed directly as scalar value
constraints. They do mot match exactly, but instead act as specifiers
for one or more built-in constraints. You can also pass a string that
contains two or more of them, separated by whitespace, in which case
they must all be satisfied. The specifiers are:

=over 4

=item C<'pos'> or C<'positive'>

The number must be greater than zero

=item C<'neg'> or C<'negative'>

The number must be less than zero

=item C<'zero'>

The number must be equal to zero

=item C<'even'> or C<'odd'>

The number must have the correct parity

=back

You can also prepend C<"non"> to any of the above to reverse their meaning.

For example:

    $rep_count = prompt 'How much do you bid?', -number => 'positive';

    $step_value = prompt 'Next step:', -integer => 'even nonzero';


=head4 Constraining input to filenames

=over 4

=item C<< -f >>

=item C<< -filenames >>

=back

You can tell C<prompt()> to accept only valid filenames, using the
C<-filenames> option (or its shortcut: C<-f>).

This option is equivalent to the options:

    -must => {
        'File must exist'       => sub { -e },
        'File must be readable' => sub { -r },
    },
    -complete => 'filenames',

In other words C<-filenames> requires C<prompt()> to accept only the name
of an existing, readable file, and it also activates filename completion.


=head4 Constraining input to "keyletters"

=over

=item C<< -k >>

=item C<< -key[let[ter]][s] >>

=back

A common interaction is to offer the user a range of actions, each of
which is specified by keying a unique letter, like so:

    INPUT:
    given (prompt '[S]ave, (R)evert, or (D)iscard:', -default=>'S') {
        when (/R/i) { revert_file()  }
        when (/D/i) { discard_file() }
        when (/S/i) { save_file()    }
        default     { goto INPUT;    }
    }

This can be cleaned up (very slightly) by using a guarantee:

    given (prompt '[S]ave, (R)evert, or (D)iscard:', -default=>'S',
                  -guarantee=>qr/[SRD]/i
    ) {
        when (/R/i) { revert_file()  }
        when (/D/i) { discard_file() }
        default     { save_file()    }
    }

However, it's still annoying to have to specify the three key letters
twice (and the default choice three times) within the call to
C<prompt()>. So IO::Prompter provides an option that extracts this
information directly from the prompt itself:

    given (prompt '[S]ave, (R)evert, or (D)iscard:', -keyletters) {
        when (/R/i) { revert_file()  }
        when (/D/i) { discard_file() }
        default     { save_file()    }
    }

This option scans the prompt string and extracts any purely alphanumeric
character sequences that are enclosed in balanced brackets of any kind
(square, angle, round, or curly). It then makes each of these character
sequences a valid input (by implicitly setting the C<-guarantee>
option), and adds the first option in square brackets (if any) as the
C<-default> value of the prompt.

Note that the key letters don't have to be at the start of a word, don't
have to be a single character, and can be either upper or lower case.
For example:

    my $action = prompt -k, '(S)ave, Save(a)ll, (Ex)it without saving';

Multi-character key letters are often a good choice for options with
serious or irreversible consequences.

A common idiom with key letters is to use the C<-single> option as well,
so that pressing any key letter immediately completes the input, without
the user having to also press C<< <ENTER>/<RETURN> >>:

    given (prompt -k1, '[S]ave, (R)evert, or (D)iscard:') {
        when (/R/i) { revert_file()  }
        when (/D/i) { discard_file() }
        default     { save_file()    }
    }



=head3 Preserving terminal newlines

=over 4

=item C<< -l  >>

=item C<< -line >>

=back

The (encapsulated) string returned by C<prompt()> is automatically chomped by
default. To prevent that chomping, specify this option.


=head3 Constraining what can be returned

=over 4

=item C<< -must => HASHREF >>

=back

This option allows you to specify requirements and constraints on the input
string that is returned by C<prompt()>. These limitations are specified as the
values of a hash.

If the C<-must> option is specified, once input is complete every value in the
specified hash is smartmatched against the input text. If any of them fail to
match, the input is discarded, the corresponding hash key is printed as an
error message, and the prompt is repeated.

Note that the values of the constraint hash cannot be single strings or
numbers, except for certain strings (such as C<'pos'>, C<'nonzero'>, or
C<'even'>, as described in L<"Constraining input to numbers">).

If you want to constrain the input to a single string or number (a very
unusual requirement), just place the value in an array, or match it
with a regex:

    # This doesn't work...
    my $magic_word = prompt "What's the magic word?",
                            -must => { 'be polite' => 'please' };

    # Use this instead...
    my $magic_word = prompt "What's the magic word?",
                            -must => { 'be polite' => ['please'] };

    # Or, better still...
    my $magic_word = prompt "What's the magic word?",
                            -must => { 'be polite' => qr/please/i };


The C<-must> option allows you to test inputs against multiple
conditions and have the appropriate error messages for each displayed.
It also ensures that, when C<prompt()> eventually returns, you are
guaranteed that the input meets all the specified conditions.

For example, suppose the user is required to enter a positive odd prime
number less than 100. You could enforce that with:

    my $opnlt100 = prompt 'Enter your guess:',
                          -integer,
                          -must => { 'be odd'                 => 'odd',
                                     'be in range'            => [1..100],
                                     'It must also be prime:' => \&isprime,
                                   };

Note that, if the error message begins with anything except an uppercase
character, the prompt is reissued followed by the error message in
parentheses with the word "must" prepended (where appropriate).
Otherwise, if the error message does start with an uppercase character,
the prompt is not reissued and the error message is printed verbatim. So
a typical input sequence for the previous example might look like:

    Enter your guess: 101
    Enter your guess: (must be in range) 42
    It must also be prime: 2
    Enter your guess: (must be odd) 7

at which point, the call to C<prompt()> would accept the input and return.

See also L<the C<-guarantee> option|"Constraining what can be typed">,
which allows you to constrain inputs as they are typed, rather than
after they are entered.


=head3 Changing how returns are echoed

=over 4

=item C<< -r[STR] >>

=item C<< -ret[urn] [=> STR] >>

=back

When C<< <ENTER>/<RETURN> >> is pressed, C<prompt()> usually echoes a carriage return.
However, if this option is given, C<prompt()> echoes the specified string
instead. If the string is omitted, it defaults to C<"\n">.

For example:

    while (1) {
        my $expr = prompt 'Calculate:', -ret=>' = ';
        say evaluate($expr);
    }

would prompt for something like this:

    Calculate: 2*3+4^5_

and when the C<< <ENTER>/<RETURN> >> key is pressed, respond with:

    Calculate: 2*3+4^5 = 1030
    Calculate: _

The string specified with C<-return> is also automatically echoed if the
L<< C<-single> option|"Single-character input" >> is used. So if you
don't want the automatic carriage return that C<-single> mode supplies,
specify C<< -return=>"" >>.


=head3 Single-character input

=over 4

=item C<< -s >>

=item C<< -1 >>

=item C<< -sing[le] >>

=back

This option causes C<prompt()> to return immediately once any single
character is input. The user does not have to push the C<< <ENTER>/<RETURN> >>
key to complete the input operation. C<-single> mode input is only
available if the Term::ReadKey module can be loaded.

By default, C<prompt()> echoes the single character that is entered. Use
the L<C<-echo> option|"Specifying what to echo on input"> to change or
prevent that.

    # Let user navigate through maze by single, silent keypresses...
    while ($nextdir = prompt "\n", -single, -echo, -guarantee=>qr/[nsew]/) {
        move_player($nextdir);
    }

Unless echoing has been disabled, by default C<prompt()> also supplies a
carriage return after the input character. Use
L<the C<-return> option|"Changing how returns are echoed"> to change
that behaviour. For example, this:

    my $question = <<END_QUESTION;
    Bast is the goddess of: (a) dogs  (b) cats  (c) cooking  (d) war?
    Your answer:
    END_QUESTION

    my $response = prompt $question, -1, -return=>' is ', -g=>['a'..'d'];
    say $response eq $answer ? 'CORRECT' : 'incorrect';

prompts like this:

    Bast is the goddess of: (a) dogs  (b) cats  (c) cooking  (d) war?
    Your answer: _

accepts a single character, like so:

    Bast is the goddess of: (a) dogs  (b) cats  (c) cooking  (d) war?
    Your answer: b_

and completes the line thus:

    Bast is the goddess of: (a) dogs  (b) cats  (c) cooking  (d) war?
    Your answer: b is CORRECT
    _


=head3 Returning raw data

=over 4

=item C<< -v >>

=item C<< -verb[atim] >>

=back

Normally, C<prompt()> returns a special object that contains the text
input, the success value, and other information such as whether the
default was selected and whether the input operation timed out.

However, if you prefer to have C<prompt()> just return the input text string
directly, you can specify this option.

Note however that, under C<-verbatim>, the input is still
autochomped (unless you also specify
L<the C<-line> option|"Preserving terminal newlines">.


=head3 Prompting on a clear screen

=over 4

=item C<< -w >>

=item C<< -wipe[first] >>

=back

If this option is present, C<prompt()> prints 1000 newlines before
printing its prompt, effectively wiping the screen clear of other text.

If the C<-wipefirst> variant is used, the wipe will only occur if the
particular call to C<prompt()> is the first such call anywhere in your
program. This is useful if you'd like the screen cleared at the start of
input only, but you're not sure which call to C<prompt()> will happen
first: just use C<-wipefirst> on all possible initial calls and only the
actual first call will wipe the screen.


=head3 Requesting confirmations

=over 4

=item C<< -y[n] >> or C<< -Y[N] >>

=item C<< -yes[no] >> or C<< -Yes[No] >>

=item C<< -yes[no] => COUNT >> or C<< -Yes[No] => COUNT >>

=back

This option invokes a special mode that can be used to confirm (or deny)
something. If one of these options is specified, C<prompt> still
returns the user's input, but the success or failure of the object returned
now depends on what the user types in.

A true result is returned if C<'y'> is the first character entered. If
the flag includes an C<n> or C<N>, a false result is returned if C<'n'>
is the first character entered (and any other input causes the prompt to
be reissued). If the option doesn't contain an C<n> or C<N>, any input
except C<'y'> is treated as a "no" and a false value is returned.

If the option is capitalized (C<-Y> or C<-YN>), the first letter of the
input must be likewise a capital (this is a handy means of slowing down
automatic unthinking C<y>..."Oh no!" responses to potentially serious
decisions).

This option is most often used in conjunction with the C<-single> option, like
so:

    $continue = prompt("Continue? ", -yn1);

so that the user can just hit C<y> or C<n> to continue, without having to hit
C<< <ENTER>/<RETURN> >> as well.

If the optional I<COUNT> argument is supplied, the prompting is repeated
that many times, with increasingly insistent requests for confirmation.
The answer must be "yes" in each case for the final result to be true.
For example:

    $rm_star = prompt("Do you want to delete all files? ", -Yes=>3 );

might prompt:

    Do you want to delete all files?  Y
    Really?  Y
    Are you sure?  Y



=head3 Bundling short-form options

You can bundle together any number of short-form options, including those that
take string arguments. For example, instead of writing:

    if (prompt "Continue? ", -yes, -1, -t10, -dn) {

you could just write:

    if (prompt "Continue? ", -y1t10dn) {...}

This often does I<not> improve readability (as the preceding example
demonstrates), but is handy for common usages such as C<-y1> ("ask for
confirmation, don't require an C<< <ENTER>/<RETURN> >>) or C<-vl>
("Return a verbatim and unchomped string").


=head3 Escaping otherwise-magic options

=over 4

C<< -_ >>

=back

The C<-_> option exists only to be an explicit no-op. It allows you to
specify short-form options that would otherwise be interpreted as Perl
file operators or other special constructs, simply by prepending or
appending a C<_> to them. For example:

    my $input
        = prompt -l_;  # option -l, not the -l file operator.

The following single-letter options require an underscore to chaperone them
when they're on their own: C<-e>, C<-l>, C<-r>, C<-s>, C<-w>, and C<-y>.
However, an underscore is not required if two or more are bundled together.


=head2 Useful useless uses of C<prompt()>

Normally, in a void context, a call to C<prompt()> issues a warning that
you are doing an input operation whose input is immediately thrown away.

There is, however, one situation where this useless use of C<prompt()> in a
void context is actually useful:

    say $data;
    prompt('END OF DATA. Press any key to exit', -echo, -single);
    exit;

Here, we're using prompt simply to pause the application after the data is
printed. It doesn't matter what the user types in; the typing itself is the
message (and the message is "move along").

In such cases, the "useless use..." warning can be suppressed using the 
C<< -void >> option:

    say $data;
    prompt('END OF DATA. Press any key to exit', -echo, -single, -void);
    exit;


=head2 Simulating input

IO::Prompter provides a mechanism with which you can "script" a sequence of
inputs to an application. This is particularly useful when demonstrating
software during a presentation, as you do not have to remember what to type,
or concentrate on typing at all.

If you pass a string as an argument to C<use IO::Prompter>, the
individual lines of that string are used as successive input lines to
any call to C<prompt()>. So for example, you could specify several sets
of input data, like so:

    use IO::Prompter <<END_DATA
    Leslie
    45
    165
    Jessie
    28
    178
    Dana
    12
    120
    END_DATA

and then read this data in an input loop:

    while (my $name   = prompt 'Name:') {
           my $age    = prompt 'Age:';
           my $height = prompt 'Height:';

           process($name, $age, $height);
    }

Because the C<use IO::Prompter> supplies input data,
the three calls to C<prompt()> will no longer read
data from C<*ARGV>. Instead they will read it from
the supplied input data.

Moreover, each call to C<prompt()> will simulate the typing-in process
automatically. That is, C<prompt()> uses a special input mode where,
each time you press a keyboard letter, it echoes not that character, but
rather the next character from the specified input. The effect is that
you can just type on the keyboard at random, but have the correct input
appear. This greatly increases the convincingness of the simulation.

If at any point, you hit C<< <ENTER>/<RETURN> >> on the keyboard, C<prompt()>
finishes typing in the input for you (using a realistic typing speed),
and returns the input string. So you can also just hit C<< <ENTER>/<RETURN> >>
when the prompt first appears, to have the entire line of input typed
for you.

Alternatively, if you hit C<< <ESC> >> at any point, C<prompt()> escapes
from the simulated input mode for that particular call to C<prompt()>,
and allows you to (temporarily) type text in directly. If you enter only
a single C<< <ESC> >>, then C<prompt()> throws away the current line of
simulated input; if you enter two C<< <ESC> >>'s, the simulated input is
merely deferred to the next call to C<prompt()>.

All these keyboard behaviours require the Term::ReadKey module to be
available. If it isn't, C<prompt()> falls back on a simpler simulation,
where it just autotypes each entire line for you and pauses at the
end of the line, waiting for you to hit C<< <ENTER>/<RETURN> >> manually.

Note that any line of the simulated input that begins with
a <CTRL-D> or <CTRL-Z> is treated as an input failure (just as
if you'd typed that character as input).

=head1 DIAGNOSTICS

All non-fatal diagnostics can be disabled using a C<no warnings> with the
appropriate category.

=over

=item C<< prompt(): Can't open *ARGV: %s >>

(F)  By default, C<prompt()> attempts to read input from
     the C<*ARGV> filehandle. However, it failed to open
     that filehandle. The reason is specified at the end of
     the message.


=item C<< prompt(): Missing value for %s (expected %s) >>

(F)  A named option that requires an argument was specified,
     but no argument was provided after the option. See
     L<"Summary of options">.


=item C<< prompt(): Invalid value for %s (expected %s) >>

(F)  The named option specified expects an particular type
     of argument, but found one of an incompatible type
     instead. See L<"Summary of options">.


=item C<< prompt(): Unknown option %s ignored >>

(W misc)  C<prompt()> was passed a string starting with
          a hyphen, but could not parse that string as a
          valid option. The option may have been misspelt.
          Alternatively, if the string was supposed to be
          (part of) the prompt, it will be necessary to use
          L<the C<-prompt> option|"Specifying what to
          prompt"> to specify it.


=item C<< prompt(): Unexpected argument (% ref) ignored >>

(W reserved)  C<prompt()> was passed a reference to
              an array or hash or subroutine in a position
              where an option flag or a prompt string was
              expected. This may indicate that a string
              variable in the argument list didn't contain
              what was expected, or a reference variable was
              not properly dereferenced. Alternatively, the
              argument may have been intended as the
              argument to an option, but has become
              separated from it somehow, or perhaps the
              option was deleted without removing the
              argument as well.


=item C<< Useless use of prompt() in void context >>

(W void)  C<prompt()> was called but its return value was
          not stored or used in any way. Since the
          subroutine has no side effects in void context,
          calling it this way achieves nothing. Either make
          use of the return value directly or, if the usage
          is deliberate, put a C<scalar> in front of the
          call to remove the void context.


=item C<< prompt(): -default value does not satisfy -must constraints >>

(W misc)  The C<-must> flag was used to specify one or more
          input constraints. The C<-default> flag was also
          specified. Unfortunately, the default value
          provided did not satisfy the requirements
          specified by the C<-must> flag. The call to
          C<prompt()> will still go ahead (after issuing the
          warning), but the default value will never be
          returned, since the constraint check will reject
          it. It is probably better simply to include the
          default value in the list of constraints.


=item C<< prompt(): -keyletters found too many defaults >>

(W ambiguous)  The C<-keyletters> option was specified,
               but analysis of the prompt revealed two or
               more character sequences enclosed in square
               brackets. Since such sequences are taken to
               indicate a default value, having two or more
               makes the default ambiguous. The prompt
               should be rewritten with no more than one set
               of square brackets.


=item C<< Warning: next input will be in plaintext >>

(W bareword)  The C<prompt()> subroutine was called with
              the C<-echo> flag, but the Term::ReadKey
              module was not available to implement this
              feature. The input will proceed as normal, but
              this warning is issued to ensure that the user
              doesn't type in something secret, expecting it
              to remain hidden, which it won't.


=item C<< prompt(): Too many menu items. Ignoring the final %d >>

(W misc)  A C<-menu> was specified with more than 52 choices.
          Because, by default, menus use upper and lower-
          case alphabetic characters as their selectors,
          there were no available selectors for the extra
          items after the first 52. Either reduce the number
          of choices to 52 or less, or else add the
          C<-number> option to use numeric selectors instead.

=back


=head1 CONFIGURATION AND ENVIRONMENT

IO::Prompter can be configured by setting any of the following
environment variables:

=over

=item C<$IO_PROMPTER_COMPLETE_KEY>

Specifies the key used to initiate
L<user-specified completions|"Input autocompletion">.
Defaults to <TAB>

=item C<$IO_PROMPTER_HISTORY_KEY>

Specifies the key used to initiate
L<history completions|"Completing from your input history">.
Defaults to <CTRL-R>

=item C<$IO_PROMPTER_COMPLETE_MODES>

Specifies the
L<response sequence|"Configuring the autocompletion interaction">
for user-defined completions.  Defaults to C<'list+longest  full'>

=item C<$IO_PROMPTER_HISTORY_MODES>

Specifies the
L<response sequence|"Configuring the autocompletion interaction">
for history completions.  Defaults to C<'full'>.

=back


=head1 DEPENDENCIES

Requires the Contextual::Return module.

The module also works much better if Term::ReadKey is available
(though this is not essential).


=head1 INCOMPATIBILITIES

This module does not play well with Moose (or more specifically, with
Moose::Exporter) because both of them try to play sneaky games with
Scalar::Util::blessed.

The current solution is to make sure that you load Moose before
loading IO::Prompter. Even just doing this:

    use Moose ();
    use IO::Prompter;

is sufficient.


=head1 BUGS AND LIMITATIONS

No unresolved bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-prompter@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Damian Conway C<< <DCONWAY@CPAN.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
