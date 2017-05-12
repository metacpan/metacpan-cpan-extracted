package Lingua::EN::Grammarian;
our $VERSION = '0.000005';

use 5.010; use warnings;
use Carp;

# Standard config files...
my $CAUTIONS_FILE = 'grammarian_cautions';
my $ERRORS_FILE   = 'grammarian_errors';

# Standard config file search path...
my @CONFIG_PATH = ( '/usr/local/share/grammarian/', "$ENV{HOME}/", "$ENV{PWD}/" );


# Export interface...
my @DEF_EXPORTS = qw<
    extract_cautions_from
    extract_errors_from
>;

my @ALL_EXPORTS = (
    @DEF_EXPORTS,
    qw<
        get_coverage_stats
        get_error_at
        get_next_error_at
        get_caution_at
        get_next_caution_at
        get_vim_error_regexes
        get_vim_caution_regexes
    >
);

sub import {
    my $self = shift;
    my @exports = @_ ? @_ : @DEF_EXPORTS;
    my $caller = caller;
    for my $exported_sub (map { /^:all$/i ? @ALL_EXPORTS : $_ } @exports) {
        no strict 'refs';
        my $impl = *{$exported_sub}{CODE};
        croak "$self does not provide $exported_sub()"
            if $exported_sub !~ /^(?:get_|extract_)/ || !$impl;
        *{$caller.'::'.$exported_sub} = $impl;
    }
}

# The data extracted from those files...
my %CAUTIONS_FOR;
my $CAUTIONS_REGEX;
my @VIM_CAUTION_REGEX_COMPONENTS;

my %CORRECTIONS_FOR;
my %EXPLANATION_FOR;
my $ERRORS_REGEX;
my @VIM_ERROR_REGEX_COMPONENTS;

my $VIM_REGEX_MAX_LEN = 20000;

# Improved \b...
my $SPACE_TRANSITION = qr{
  #  Preceded by...             And followed by...
     (?<=[[:space:][:punct:]])  (?=[^[:space:][:punct:]])
  |                         \A  (?=[^[:space:][:punct:]])
  | (?<=[^[:space:][:punct:]])  (?=[[:space:][:punct:]]|\z)
}xms;

# Extract that data...
if (! _load_cautions()) {
    warn qq{No "grammarian_cautions" file found in config search path:\n}
       . qq{\n}
       . join(q{}, map { qq{    $_\n} } @CONFIG_PATH)
       . qq{\n}
       . qq{(Did you forget to install it from the distribution?)\n};
}

if (! _load_errors()) {
    warn qq{No "grammarian_errors" file found in config search path:\n}
       . qq{\n}
       . join(q{}, map { qq{    $_\n} } @CONFIG_PATH)
       . qq{\n}
       . qq{(Did you forget to install it from the distribution?)\n};
}

sub _rewrite (&$) {
    my ($transform, $text) = @_;
    $transform->() for $text;
    return $text;
}

sub _inflect_term {
    my ($term) = @_;

    my $PRONOUN_MARKER = qr{
        < (?: I | s?he | we | me | him | us | my | his | our | mine | hers | ours) >
    }xms;

    my %PRONOUN_EXPANSION_FOR = (
        '<I>'    => q{I,you,she,he,it,we,they},
        '<she>'  => q{she,he},
        '<he>'   => q{he,she},
        '<we>'   => q{we,you,they},
        '<me>'   => q{me,you,her,him,it,us,them},
        '<her>'  => q{her,him},
        '<him>'  => q{him,her},
        '<us>'   => q{us,you,them},
        '<my>'   => q{my,your,hers,his,its,our,their},
        '<his>'  => q{her,his},
        '<our>'  => q{our,your,their},
        '<mine>' => q{mine,yours,hers,his,its,ours,theirs},
        '<hers>' => q{hers,his},
        '<ours>' => q{ours,yours,theirs},
    );


    # Preprocess <pronoun> expansions...
    my @components = split /($PRONOUN_MARKER)/, $term;
    $term = q{};
    my $in_parens = 0;
    while (@components) {
        my ($prefix, $pronoun) = splice(@components, 0, 2);
        $in_parens += ($prefix=~tr/(//) - ($prefix=~tr/)//);
        $term .= $prefix;
        if ($pronoun) {
            $term .= ($in_parens ? '' : '(')
                . ($PRONOUN_EXPANSION_FOR{$pronoun} // $pronoun)
                . ($in_parens ? '' : ')')
        }
    }

    # Convert any parenthesized or starred set of alternatives...
    my @inflexions;
    $term =~ s{ (?<root> \S*? (?<last_letter> \S? ) )
                (?:
                      (?<e_star>                  e [*]       )
                    | (?<ch_star>                ch [*]       )
                    | (?<y_star> (?<= [^aeiou] )  y [*]       )
                    | (?<y_s>    (?<= [^aeiou] )  y [(] s [)] )
                    | (?<double_star>               [*][*]    )
                    | (?<star>                      [*]       )
                    | [(] (?<alts> [^)]+ ) [)]
                )
                }
                {
                my $ll = $+{last_letter};
                @inflexions = $+{e_star}      ? ( 'e',    'es',      'ed',     'ing')
                            : $+{ch_star}     ? ( 'ch', 'ches',    'ched',   'ching')
                            : $+{y_star}      ? ( 'y',   'ies',     'ied',    'ying')
                            : $+{y_s}         ? ( 'y',   'ies',                     )
                            : $+{double_star} ? (  '',     's',  $ll.'ed', $ll.'ing')
                            : $+{star}        ? (  '',     's',      'ed',     'ing')
                            : $+{alts}        ? ( ($+{root} ? '' : ()), split(',', $+{alts}) )
                            :                     ();

                qq{$+{root}*};
                }xmse;

    return @inflexions ? map { my $infl = $term; $infl =~ s{[*]}{$_}; $infl} @inflexions
                       : $term;
}

# Parse cautions file and convert to internal data structures...
sub _load_cautions {
    # Gather config from current directory and home directory...
    local @ARGV = grep { -e }
                  map { ("$_.$CAUTIONS_FILE", "$_$CAUTIONS_FILE") }
                  @CONFIG_PATH;

    # If no config, we're done...
    return if !@ARGV;

    # Store sets of terms together...
    my @term_sets = { terms => [], defns => [], inflexions => [] };

    # Parse configuration file...
    LINE:
    while (my $next_line = readline) {
        # Ignore comments...
        next LINE if $next_line =~ m{ \A \h* [#] }xms;

        # Blank lines delimit new term sets...
        if ($next_line =~ m{\A \h* \Z}xms) {
            push @term_sets, { terms => [], defns => [], inflexions => [] };
            next LINE;
        }

        # Parse config line...
        $next_line =~ m{
            \A
                (?<is_silent> -?  )
            \h* (?<term> [^:]*? )
            (?:
                \h*  :
                \h*  (?<defn> .*? )
            )?
            \h*
            \Z
        }xms;

        # Unpack components...
        my $term      = $+{term};
        my $defn      = $+{defn} // q{};
        my $is_silent = length($+{is_silent});

        # Warn of bad config...
        if (!defined $term) {
            warn "Invalid entry in grammarian_cautions: $next_line";
            next LINE;
        }

        # Unpack any inflexions...
        my @inflexions = _inflect_term($term);

        my $original = shift @inflexions;
        if ($defn =~ /\S/) {
            push @{$term_sets[-1]{terms}}, $original;
            push @{$term_sets[-1]{defns}}, $defn;
        }

        # Store patterns to be matched...
        my $order = 0;
        for my $next_inflexion ($original, @inflexions) {
            push @{ $term_sets[-1]{inflexions}[$order++] }, {silent => $is_silent, term => $next_inflexion};
        }
    }


    # Compile list of cautions and the matching regex...
    my @regex_components;
    TERM_SET:
    for my $term_set (@term_sets) {
        next TERM_SET if !@{ $term_set->{terms} };

        use List::Util 'max';
        my $term_width = max map { length } @{ $term_set->{terms} };

        my $caution
            = join q{},
              map  { sprintf("%-*s : %s\n", $term_width, $term_set->{terms}[$_], $term_set->{defns}[$_]) }
              0..$#{ $term_set->{terms} };

        for my $inflexion_set (@{ $term_set->{inflexions} }) {
            my $inflexions = [ map { $_->{term} } @{ $inflexion_set } ];
            for my $term_data (@{ $inflexion_set }) {
                my $term = $term_data->{term};
                my $silent = $term_data->{silent};
                $CAUTIONS_FOR{lc $term} = {
                    display     => $silent,
                    explanation => $caution,
                    inflexions  => $inflexions
                };
                if (!$silent) {
                    push @regex_components, _rewrite { s{\h+}{\\s+}g } $term;
                    push @VIM_CAUTION_REGEX_COMPONENTS, _rewrite { s{\h+}{\\_s\\+}g } $term;
                }
            }
        }

    }

    my $cautions_regex = '\b(?<term>' . join('|', reverse sort @regex_components) . ')\b';
    $CAUTIONS_REGEX = qr{$cautions_regex}i;

    return 1;
}

sub _gen_pres_participle_for {
        my ($verb) = @_;

           $verb =~ s/ie$/y/
        or $verb =~ s/ue$/u/
        or $verb =~ s/([auy])e$/$1/
        or $verb =~ s/ski$/ski/
        or $verb =~ s/[^b]i$//
        or $verb =~ s/^(are|were)$/be/
        or $verb =~ s/^(had)$/hav/
        or $verb =~ s/(hoe)$/$1/
        or $verb =~ s/([^e])e$/$1/
        or $verb =~ m/er$/
        or $verb =~ m/open$/
        or $verb =~ s/([^aeiou][aeiouy]([bdgmnprst]))$/$1$2/;

        return "${verb}ing";
}

sub _gen_verb_errors {
    my ($pres, $third, $past, $pastp, $presp) = @_;

    return (
        ($pres ne $third ? (
            "====[ Incorrect inflexion of verb for the specified pronoun ]=================",
            "              (he,she,it) $pres   -->      (he,she,it) $third                 ",
            "          (I,you,we,they) $third  -->  (I,you,we,they) $pres                  ",

            "====[ Incorrect inflexion of verb after a negated auxiliary ]=================",
            "(did,would,should,could,must,might)n't $third                                 "
           ."                                  --> (did,would,should,could,must,might)n't $pres",
        ):()),

            "====[ Incorrect inflexion of verb after a negated auxiliary ]=================",
            "(did,would,should,could,must,might)n't $past                                  "
           ."                                  --> (did,would,should,could,must,might)n't $pres",

        ($past ne $pastp ? (
            "====[ Incorrect use of participle instead of simple past or past perfect ]====",
            "          (I,you,we,they) $pastp  -->  (I,you,we,they) $past                  "
            ."                                 -->  (I,you,we,they) have $pastp            "
            ."                                 -->  (I,you,we,they) had $pastp             ",

            "              (he,she,it) $pastp  -->      (he,she,it) $past                  "
            ."                                 -->      (he,she,it) has $pastp             "
            ."                                 -->      (he,she,it) had $pastp             ",

            "====[ Incorrect use of simple past instead of past participle ]================",
            " (be,being,been,was,were) $past   -->     (be,being,been,was,were) $pastp      ",
            "    (has,had,have,having) $past   -->        (has,had,have,having) $pastp      ",
            " (be,being,been,was,were) $past   -->     (be,being,been,was,were) $pastp      ",

            "====[ Incorrect inflexion of verb after a negated auxiliary ]=================",
            "(did,would,should,could,must,might)n't $pastp                                 "
           ."                                  --> (did,would,should,could,must,might)n't $pres",
        ):()),

            "====[ Incorrect use of infinitive instead of past participle ]=================",
            " (be,being,been,was,were) $pres   -->     (be,being,been,was,were) $pastp      ",
            "    (has,had,have,having) $pres   -->        (has,had,have,having) $pastp      ",

            "====[ Incorrect use of participle instead of infinitive ]=================",
            "               to ($pastp,$presp) -->     to $pres                             ",
        ($third ne $pres ?
            "                        to $third -->     to $pres                             "
        :()),
        ($past ne $pastp ?
            "                         to $past -->     to $pres                             "
        :()),

            "====[ Incorrect use of present participle instead of past participle ]=========",
            "                    being $presp  -->   being $pastp                            ",

            "====[ Incorrect use of \"try and\" instead of \"try to\" ]=====================",
            "try and ($pres,$past,$pastp,$presp)  -->   try to $pres                        ",

            "====[ Incorrect inflexion of verb after \"try to\" ]===========================",
            "       try to ($past,$pastp,$presp)  -->      try to $pres                     ",
            "     tried to ($past,$pastp,$presp)  -->    tried to $pres                     ",
            "    trying to ($past,$pastp,$presp)  -->   trying to $pres                     ",
    );
}

sub _gen_absolute_adjective_errors {
    my ($adj, $modifier) = @_;
    $modifier //= '';

    my @QUALIFIERS = qw<
        somewhat   highly   extremely   totally   completely   absolutely   utterly
    >;
    my $QUALIFIERS = '(' . join(',', @QUALIFIERS) . ')';

    my @errors = (
        "====[ Incorrect use of modifier with ungradeable adjective ]===================",
        "           more $adj  -->  $adj                                                ",
        "           most $adj  -->  $adj                                                ",
        "          quite $adj  -->  $adj                                                ",
        "         rather $adj  -->  $adj                                                ",
        "           very $adj  -->  $adj                                                ",
        "    $QUALIFIERS $adj  -->  $adj                                                ",
    );

    if ($modifier) {
        $modifier =~ s{ \A [(] | [)] \z}{}xgms;
        for my $mod (split(',', $modifier)) {
            $errors[1] .=  " -->   more $mod $adj";
            $errors[2] .=  " -->   most $mod $adj";
            $errors[3] .=  " -->  quite $mod $adj";
            $errors[4] .=  " --> rather $mod $adj";
            $errors[5] .=  " -->   very $mod $adj";
        }
    }

    return @errors;
}

sub _load_errors {
    # Gather config from search path
    local @ARGV = grep { -e }
                  map { ("$_.$ERRORS_FILE", "$_$ERRORS_FILE") }
                  @CONFIG_PATH;

    # If no config, we're done...
    return if !@ARGV;

    # Extract corrections...
    my @regex_components;
    my $explanation = '????';
    my $last_was_explanation = 1;
    my @insertions;
    LINE:
    while (my $next_line = shift(@insertions) // readline) {

        # Ignore comment and empty lines...
        next LINE if $next_line =~ m{\A \h* (?: [#] | \Z )}xms;

        # Handle explanation lines...
        if ($next_line =~ m{\A \h* ===\S* \h* (.*?) \h* \S*===.* \Z }xms) {
            $explanation = $last_was_explanation ? "$explanation\n$1" : $1;
            $last_was_explanation = 1;
            next LINE;
        }
        $last_was_explanation = 0;

        # Generate errors from a <verb> specification...
        if ($next_line =~ m{\A\h* <verb> \h* (?<pres>\S+) \h* (?<third>\S+) \h* (?<past>\S+) \h* (?<part>\S+)}xms) {
            push @insertions, _gen_verb_errors(@+{qw<pres third past part>}, _gen_pres_participle_for($+{pres}));
            next LINE;
        }

        # Generate errors from an <absolute> specification...
        if ($next_line =~ m{\A\h* <absolute (?: \h*:\h* (?<modifier> \S+) \h*)?> \h* (?<adjective>\S+) }xms) {
            push @insertions, _gen_absolute_adjective_errors( @+{qw< adjective modifier >} );
            next LINE;
        }

        # Extract error --> correction pair...
        $next_line =~ m{
            \A \h*
            (?<error> .*? )
            \h* --> \h*
            (?<correction> .*? )
            \h* \Z
        }xms;
        my ($error, $correction) = @+{'error', 'correction'};

        # Ignore invalid lines...
        next LINE if !defined $error;

        # Expand inflected forms...
        my @error_inflexions = _inflect_term($error);
        my @corrections_inflections
            = map {[_inflect_term($_)]}
              split /\h+-->\h+/,
              $correction;

        # Iterated inflections in parallel...
        for my $next (0..$#error_inflexions) {
            my $error = $error_inflexions[$next];

            # Build normalized transform from error to each correction...
            for my $correction (@corrections_inflections) {
                my $normalized_error = _rewrite { s{\h+}{ }gxms } lc $error;
                push @{$CORRECTIONS_FOR{$normalized_error}},
                     $correction->[$next] // $correction->[-1];

                # Record explanation...
                $EXPLANATION_FOR{$normalized_error} = $explanation;
            }

            # Remember error for eventual regexes (with generalized whitespace)...
            push @regex_components, _rewrite { s{\h+}{\\s+}g } $error;
            push @VIM_ERROR_REGEX_COMPONENTS, _rewrite { s{\h+}{\\_s\\+}g } $error;
        }
    }

    # Build error-detecting regex...
    my $ERRORONEOUS_TERM = join('|', reverse sort @regex_components);
    $ERRORS_REGEX = qr{
        $SPACE_TRANSITION
        ( $ERRORONEOUS_TERM | (?&REPEATED_WORD) )
        $SPACE_TRANSITION

        (?(DEFINE)
            (?<REPEATED_WORD>  (?<WORD> \S++)  \s++  \k<WORD> )
        )
    }ixms;

    return 1;
}

# Apply regexes to detect offending terms...
sub extract_cautions_from {
    my ($text) = @_;

    state %cautions_cache;
    if (!exists $cautions_cache{$text}) {
        my $cache = $cautions_cache{$text} = [];
        while ($text =~ m{\G .*? $CAUTIONS_REGEX}gcxms) {
            push @{$cache}, Lingua::EN::Grammarian::Caution->new($1,\$text);
        }
    }

    return @{ $cautions_cache{$text} };
}

sub extract_errors_from {
    my ($text) = @_;

    state %errors_cache;
    if (!exists $errors_cache{$text}) {
        my $cache = $errors_cache{$text} = [];
        while ($text =~ m{\G .*? $ERRORS_REGEX}gcxms) {
            push @{$cache}, Lingua::EN::Grammarian::Error->new($1,\$text);
        }
    }

    return @{ $errors_cache{$text} };
}

# Report coverage...
sub get_coverage_stats {
    return {
        cautions => scalar keys %CAUTIONS_FOR,
        errors   => scalar keys %CORRECTIONS_FOR,
    }
}

# Identify offences (if any) at a particular location...

sub get_error_at {
    my ($text, $index_or_line, $col) = @_;
    return _problem_in($text, [extract_errors_from($text)], $index_or_line, $col,\do{my $no_next});
}

sub get_next_error_at {
    my ($text, $index_or_line, $col) = @_;
    state $prev_error_index = -1;
    return _problem_in($text, [extract_errors_from($text)], $index_or_line, $col,\$prev_error_index);
}

sub get_caution_at {
    my ($text, $index_or_line, $col) = @_;
    return _problem_in($text, [extract_cautions_from($text)], $index_or_line, $col,\do{my $no_next});
}

sub get_next_caution_at {
    my ($text, $index_or_line, $col) = @_;
    state $prev_caution_index = -1;
    return _problem_in($text, [extract_cautions_from($text)], $index_or_line, $col,\$prev_caution_index);
}

sub _problem_in {
    my ($text, $problems_ref, $index_or_line, $col, $prev_findex_ref) = @_;

    # Convert line/col to index...
    if (defined $col) {
        $index_or_line -= 1;
        $text =~ m{( \A (?:  [^\n]* \n){$index_or_line} [^\n]{$col} )}xms
             or return;
        $index_or_line = length($1);
    }

    # Look for a hit...
    for my $problem (@{$problems_ref}) {
        my $findex = $problem->from->{index};
        my $tindex = $problem->to->{index};

        # Cursor is "in" a problem...
        if ($findex <= $index_or_line && $index_or_line <= $tindex && $findex != (${$prev_findex_ref} // -1)) {
            ${$prev_findex_ref} = $findex;
            return wantarray ? ($problem, 1)  # There's a problem and the cursor *is* over it
                             :  $problem;
        }

        # Cursor not in a problem, so return next problem...
        elsif ($findex > $index_or_line) {
            ${$prev_findex_ref} = $findex;
            return wantarray ? ($problem, 0)  # There's a problem and the cursor *isn't* over it
                             : undef;
        }
    }

    # Otherwise, it's a miss...
    return;
}


# Provide regexes for matching grammar problems in Vim...

sub get_vim_error_regexes {
    _build_vim_regex_from(@VIM_ERROR_REGEX_COMPONENTS);
}

sub get_vim_caution_regexes {
    _build_vim_regex_from(@VIM_CAUTION_REGEX_COMPONENTS);
}

sub _build_vim_regex_from {
    my @regex_components = reverse sort @_;

    my @regexes;
    for my $alternative (@regex_components) {
        $alternative =~ s/'/''/g;
        if (@regexes && length($regexes[-1]) + length($alternative) + 10 < $VIM_REGEX_MAX_LEN) {
            $regexes[-1] .= '\\|' . $alternative;
        }
        else {
            push @regexes, '\\c' . $alternative;
        }
    }
    return map { '\<\%('.$_.'\)\>' } @regexes;
}


my $UPPER_CASE_PAT   = qr{\A [[:upper:]]* \Z}xms;
my $LOWER_CASE_PAT   = qr{\A [[:lower:]]* \Z}xms;
my $TITLE_CASE_PAT   = qr{\A [[:upper:]][[:lower:]]* \Z}xms;

# Convert a term to have the same capitalization as an original paradigm...
my $_recase_like = sub {
    my ($paradigm, $target) = @_;

    # Process two strings word-by-word...
    my @paradigm_words = split($SPACE_TRANSITION, $paradigm);
    my @target_words   = split($SPACE_TRANSITION, $target  );

    while (@paradigm_words < @target_words) {
        push @paradigm_words, $paradigm_words[-1];
    }

    # Accumulate modified target by transforming each word...
    my $modified_target = "";
    for my $next_paradigm (@paradigm_words) {
        # If target completely processed, we're done...
        last if !@target_words;

        # Otherwise, convert target according to pattern of paradigm...
        $modified_target .= $next_paradigm =~ $UPPER_CASE_PAT ? uc(shift @target_words)
                          : $next_paradigm =~ $LOWER_CASE_PAT ? lc(shift @target_words)
                          : $next_paradigm =~ $TITLE_CASE_PAT ? ucfirst(lc(shift @target_words))
                          :                                     shift @target_words
                          ;
    }

    return $modified_target;
};

package Lingua::EN::Grammarian::Error; {
    use Hash::Util::FieldHash 'fieldhash';
    *_rewrite = *Lingua::EN::Grammarian::_rewrite;

    fieldhash my %match_for;
    fieldhash my %startpos_for;
    fieldhash my %endpos_for;

    sub new {
        my ($class, $term, $source_ref) = @_;

        my $newobj = bless \do{my $scalar}, $class;

        my $endindex   = pos(${$source_ref}) - 1;
        my $startindex = pos(${$source_ref}) - length($term);
        my $startline  = 1 + substr(${$source_ref},0,$startindex) =~ tr/\n//;
        my $endline    = 1 + substr(${$source_ref},0,$endindex) =~ tr/\n//;
        my $startcol   = 1 + length(Lingua::EN::Grammarian::_rewrite {s{\A.*\n}{}xms} substr(${$source_ref},0,$startindex));
        my $endcol     = 1 + length(Lingua::EN::Grammarian::_rewrite {s{\A.*\n}{}xms} substr(${$source_ref},0,$endindex));

        $match_for{$newobj}    = $term;
        $startpos_for{$newobj} = { index => $startindex, line => $startline, column => $startcol };
        $endpos_for{$newobj}   = { index => $endindex,   line => $endline,   column => $endcol   };

        return $newobj;
    }

    sub match { my $self = shift; return $match_for{$self} }
    use overload q{""} => sub { my $self = shift; return $match_for{$self} };

    sub from { my $self = shift; return $startpos_for{$self} }
    sub to   { my $self = shift; return $endpos_for{$self}   }

    sub explanation {
        my $self = shift;
        return $EXPLANATION_FOR{lc Lingua::EN::Grammarian::_rewrite {s{\s+}{ }g} $match_for{$self}}
            // "Repeated word";
    }

    sub explanation_hash {
        return {};
    }

    sub suggestions {
        my $self = shift;
        my $term = $match_for{$self};

        # Locate suggestions...
        my $corrections_ref
            = $CORRECTIONS_FOR{lc Lingua::EN::Grammarian::_rewrite {s{\s+}{ }g} $term}
            // [$term =~ m{\A (\S+) \s+ \1 \z}ixms ? $1 : () ];

        # Adjust their casings...
        return map { $_recase_like->($term, $_) } @{$corrections_ref};
    }
}

package Lingua::EN::Grammarian::Caution; {
    use Hash::Util::FieldHash 'fieldhash';

    fieldhash my %match_for;
    fieldhash my %startpos_for;
    fieldhash my %endpos_for;

    sub new {
        my ($class, $term, $source_ref) = @_;

        my $newobj = bless \do{my $scalar}, $class;

        my $endindex   = pos(${$source_ref}) - 1;
        my $startindex = pos(${$source_ref}) - length($term);
        my $startline  = 1 + substr(${$source_ref},0,$startindex) =~ tr/\n//;
        my $endline    = 1 + substr(${$source_ref},0,$endindex) =~ tr/\n//;
        my $startcol   = 1 + length(Lingua::EN::Grammarian::_rewrite { s{\A.*\n}{}xms } substr(${$source_ref},0,$startindex));
        my $endcol     = 1 + length(Lingua::EN::Grammarian::_rewrite { s{\A.*\n}{}xms } substr(${$source_ref},0,$endindex));

        $match_for{$newobj}    = $term;
        $startpos_for{$newobj} = { index => $startindex, line => $startline, column => $startcol };
        $endpos_for{$newobj}   = { index => $endindex,   line => $endline,   column => $endcol   };

        return $newobj;
    }

    sub match { my $self = shift; return $match_for{$self} }
    use overload q{""} => sub { my $self = shift; return $match_for{$self} };

    sub from { my $self = shift; return $startpos_for{$self} }
    sub to   { my $self = shift; return $endpos_for{$self}   }

    sub explanation {
        my $self = shift;
        my $target = lc Lingua::EN::Grammarian::_rewrite {s{\s+}{ }g} $match_for{$self};
        my $suggested = $CAUTIONS_FOR{$target};
        return if !defined $suggested;
        return $suggested->{explanation};
    }

    sub explanation_hash {
        my $self = shift;
        my $target = lc Lingua::EN::Grammarian::_rewrite {s{\s+}{ }g} $match_for{$self};
        my $suggested = $CAUTIONS_FOR{$target};
        return if !defined $suggested;
        return { split /\s+:\s+|\s*\n/, $suggested->{explanation} };
    }

    sub suggestions {
        my $self = shift;
        my $target = lc Lingua::EN::Grammarian::_rewrite {s{\s+}{ }g} $match_for{$self};
        my $suggested = $CAUTIONS_FOR{$target};
        return if !defined $suggested;

        # Reorder suggestions by relevance to term...
        return map  { $_recase_like->($match_for{$self}, $_) }
               sort {
                      $a eq $target  ?  -1
                    : $b eq $target  ?  +1
                    : $a cmp $b
               }
               @{ $suggested->{inflexions} }
    }
}


1; # Magic true value required at end of module
__END__

=head1 NAME

Lingua::EN::Grammarian - Detect grammatical problems in text


=head1 VERSION

This document describes Lingua::EN::Grammarian version 0.000005


=head1 SYNOPSIS

    use Lingua::EN::Grammarian;

    # Create a list of issues...
    my @caution_objs = extract_cautions_from( $text );
    my @error_objs   = extract_errors_from(   $text );

    # Identify a single issue at a known 2D position...
    my $caution_obj  = get_caution_at($text, $line, $col);
    my $error_obj    =   get_error_at($text, $line, $col);

    # Identify a single issue at a known index...
    my $caution_obj  = get_caution_at($text, $index);
    my $error_obj    =   get_error_at($text, $index);

    # Extract information on each issue...
    for my $problem (@cautions_or_errors) {
        my $actual_word_or_phrase  = $problem->match;
        my $start_location_in_text = $problem->from;
        my $end_location_in_text   = $problem->to;
        my $description_of_problem = $problem->explanation;
        my $suggested_correction   = $problem->suggestions;
        ...
    }


=head1 DESCRIPTION

This module provides a data-driven grammar checker for English text.

It builds a list of potential grammar problems from templates specified
in two files (F<grammarian_errors> and F<grammarian_cautions>) and
locates any such problems in a text string. Because the module is
data-driven, it is easy for even non-technical users to refine or
augment the rules used to identify grammatical problems.

Each problem discovered is reported as an object, whose methods can then
be called to retrieve the corresponding substring of the original text,
its location within the original text, a description of the problem, and
a suggested remediation for it.

The module classifies grammatical problems as either I<errors> or
I<cautions>. Errors are grammatical usages that are unequivocally wrong,
such as "I gone home", "principle ingredient", "laying low", "their are
it's collar", "its comprised from", "she do try and learns the words"
"them have be quite unique", etc.

Cautions are words or phrases that are not inherently wrong, but which
are commonly confused or misapplied. For example: "affect" vs "effect",
"infer" vs "imply", "beg the question" vs "raise the question",
"indict" vs "indite", "less" vs "fewer", "disburse" vs "disperse", etc.

Note that Lingua::EN::Grammarian is not a spell-checker.
Neither errors nor cautions contain words that have been misspelt;
they are composed of words that have been misI<used>.

=head1 INTERFACE

=head2 Exportable subroutines

By default, the module exports only two subroutines:

=over

=item C<< extract_errors_from() >>

C<< extract_errors_from() >> expects a single argument: a string in
which it is to locate and identify grammatical errors, according to
the rules in your F<grammarian_errors> file(s).

It returns a list of objects, each of which represents a single error.
The objects are returned in the order in which the errors were
encountered in the text.

See L<"Methods of caution and error objects"> for details of how these
objects may be used.

=item C<< extract_cautions_from() >>

Behaves exactly the same as C<< extract_errors_from() >>, except that it
locates and identifies grammatical cautions (according to your
F<grammarian_cautions> file), not errors.

=back

You can also request a further three subroutines, by passing their
names when the module is loaded. For example:

    use Lingua::EN::Grammarian  'get_error_at', 'get_caution_at';

Note that, if this feature is used, only the explicitly named
subroutines are exported (hence you may also need to add
C<'extract_cautions_from'> or C<'extract_errors_from'>, if you need
either of those subs as well).

You can also request all available subroutines be exported, with:

    use Lingua::EN::Grammarian  ':all';


The various exportable-by-request subroutines are:

=over

=item C<< get_error_at() >>

This subroutine expects two or three arguments: a string in which to
search, followed by a location at which to search. The location may be
either a single integer (which is taken as a zero-based index into the
string), or two integers (which are treated as 1-based line and column
specifiers):

    my $error_obj = get_error_at($text, $index);

    my $error_obj = get_error_at($text, $line, $column);

In either case, the sub returns an object representing the error
occurring at that position in the text. If there is nothing wrong at
that position, the sub returns C<undef> instead.

The idea is that the index or line/column specification represents the
location of a cursor or mouse over the text. Then C<get_error_at()> can
be used to determine whether or not that marker is hovering over a
grammatical error and, if so, the nature of this error.

=item C<< get_caution_at() >>

Works exactly the same as C<get_error_at()>, with exactly the same
interface. But returns an object only if there is a grammatical caution
(not an error) at the specified location in the text.

=item C<< get_coverage_stats() >>

Returns a hash whose entries indicate how many error and caution rules
the module can currently identify. These numbers are, of course,
determined by the configurations in your F<grammarian_errors> and
F<grammarian_cautions> files.

=item C<< get_vim_error_regexes() >>

=item C<< get_vim_caution_regexes() >>

Each of these subroutines returns a list of strings
that represent regexes (in the regex notation used by the Vim editor).
Collectively these strings will match all the error and caution
entries the module can recognize.

A list of strings is returned, rather than a single string, because Vim
seems to impose a limit of about 32000 characters for a single regex
pattern.

Typically, these patterns are passed to Vim's C<matchadd()> function,
to highlight grammatical problems in a buffer.

=back

=head2 Methods of caution and error objects

Each object returned by the various subroutines of
Lingua::EN::Grammarian encapsulates information regarding a single error
or caution located in a particular text.

These objects provide the following methods for querying that information.
None of them takes an argument.

=over

=item C<< match() >>

Returns the substring (of the original text) that was identified as a problem.

=item C<< from() >>

Returns a hash representing the location in the original text at
which the start of the problematic usage was detected. The keys of
this hash are:

=over

=item C<'index'>

The zero-based offset in the string at which the start of the usage was detected.

=item C<'line'>

The 1-based line-number of the line within the string in which the usage
was detected. In other words: one more than the number of newlines
between the start of the string and the start of the problem.

=item C<'column'>

The 1-based column-number of the column within the string at which the
start of the usage was detected. In other words: the number of
characters between the start of the problem and the preceding newline
(or the start of string).

=back

=item C<< to() >>

Returns a hash representing the location in the original text at
which the end of the problematic usage was detected. The keys of
this hash are identical in name and nature to those of the
C<from()> method.

=item C<< explanation() >>

Returns a single string describing the problem that was detected.

This description will be taken from the relevant comments in
F<grammarian_errors> or from the appropriate definitions in
F<grammarian_cautions>. It may consist of multiple lines
(i.e. the string may contain embedded newlines).

=item C<< explanation_hash() >>

For cautions, returns a reference to a hash containing each alternative
as a key, with that alternative's definition as the corresponding value.
This is precisely the same information as returned by the
C<explanation()> method, but in a more structured form.
For example, if C<< $caution->explanation() >> returns:

     "adverse  :  hostile or difficult
      averse   :  disinclined"

then C<< $caution->explanation_hash() >> will return:

    {
     'adverse' => 'hostile or difficult',
     'averse'  => 'disinclined',
    }

For errors (whose explanations are not alternatives),
this method returns a reference to an empty hash.


=item C<< suggestions() >>

Returns a list of strings representing possible alternatives to
the problematical usage.

For errors, this list is constructed from the replacement(s) specified
after C<< --> >> arrows in F<grammarian_errors>.

For cautions, this list is constructed from the other terms specified
in the same paragraph in F<grammarian_cautions>.

The list is sorted "most-likely-replacement-first".

=back

=head1 CONFIGURATION

Lingua::EN::Grammarian's grammar checking is configured via two files:
F<grammarian_errors> and F<grammarian_cautions>. These files may be
placed in any one of more of the following locations:

    /usr/local/share/grammarian/
    ~/   (i.e. your home directory)
    ./   (i.e. the current directory)

whence they are read (in that order) and their contents concatenated
into a single specification.

The two filenames may also be prefixed with a C<.> (to render them
invisible in directory listings). A given directory may contain both a
visible and an invisible configuration file, in which case the invisible
file is concatenated before--and hence is overridden by--the visible
file in the same directory.

The configuration formats for the two files are different, however both
formats ignore blank lines and both use a leading C<#> to specify
comments. However, unlike Perl comments, comments in these two
configuration files can only be specified at the start of a line.

=head2 The F<grammarian_errors> file

This file specifies the rules for detecting grammatical errors
using several different formats.

=head3 Simple error specifications

Each line of the file specifies an erroneous pattern of text,
followed by one or more possible corrections. Error and correction(s)
are separated by a C<< --> >>. Case is always ignored.

For example:

    reply back      --> reply
    koala bear      --> koala
    could care less --> couldn't care less

    can't never     -->  can't ever  --> can never
    more optimal    -->  optimal     --> more optimized  -->  better

In addition to the problem and suggested replacement(s), you can also
specify a description of the specific problem (or the general class
of problem) in a preceding line that starts and ends with C<===>.
The explanation itself then starts after the first whitespace gap,
and ends at the last whitespace gap. For example:

    ===  incorrect use of preposition after "comprise"  ===

    is comprised of -->  comprises


    ====[ A koala is a marsupial, not a bear ]====
    koala bear  --> koala

A single explanation can apply to two or more errors...

    =====/ Unnecessary extra word \========================

    actual fact               --> fact
    and plus                  --> and
    because of the fact that  --> because

    ====={  Incorrect participle  }============================
    has did   -->  has done
    has have  -->  has had


=head3 Parallel error specifications

If either usage contains a (set,of,comma-separated,words,like,this) the
list is expanded into separate rules for each alternative. For example:

    (I,you,we,they) sees  -->  (I,you,we,they) see

    (can't,won't) never   -->  (can't,won't) ever  -->  (can,will) never

    (very,totally) unique -->  unique

are shorthands for:

                  I sees  -->     I see
                you sees  -->   you see
                 we sees  -->    we see
               they sees  -->  they see

             can't never  -->  can't ever  -->  can never
             won't never  -->  won't ever  -->  will never

              very unique -->  unique
           totally unique -->  unique

Note, however, that you can currently only specify one list of
alternatives in any given rule. For example, the following
construction does not (yet) work:

    (to,at,from,with) (I,we,they) --> (to,at,from,with) (me,us,them)


=head3 Shortcuts for parallel specifications

Transformations involving pronouns can be tedious to write (and read).
Both because of the large number of alternatives often required on
each side, and because of the frequent repetition of the same sets
of pronouns:

     about (she,he)  --> about (her,him)

     ring (my,your,her,his,its,our,their) neck --> wring (my,your,her,his,its,our,their) neck

     (she,he,it) have --> (she,he,it) has
     (she,he,it) do   --> (she,he,it) does
     (she,he,it) are  --> (she,he,it) is

So a variety of shortcuts are provided.
You can specify complete sets of pronouns and possessive adjectives
more succinctly with:

    Shortcut     Is expanded to
    ========     ===================================

    <I>          (I,you,she,he,it,we,they)
    <me>         (me,you,her,him,it,us,them)
    <my>         (my,your,hers,his,its,our,their)
    <mine>       (mine,yours,hers,his,its,ours,theirs)

For only the gendered 3rd person pronouns and possessive adjectives:

    <she>        (she,he)
    <he>         (he,she)
    <her>        (her,him)
    <him>        (him,her)
    <his>        (his,her)
    <hers>       (hers,his)

For only the plural pronouns and possessive adjectives:

    <we>         (we,you,they)
    <us>         (us,you,them)
    <our>        (our,your,their)
    <ours>       (ours,yours,theirs)

Note that the abbreviation in angles is always the first alternative of
the corresponding expansion.

This means that the following are exactly the same as the earlier
parenthesized examples:

         about <she>  -->  about <her>

      ring <my> neck  -->  wring <my> neck

      (<he>,it) have  -->  (<he>,it) has

As the last example implies, if one of these shortcuts is placed inside
a set of parentheses, it expands to just the list of pronouns.
Everywhere else, each abbreviation expands to the appropriate list of
pronouns surrounded by parentheses.


=head3 Verb conjugation errors

A line beginning with the marker C<< <verb> >> specifies the
inflection of a verb as follows:

  <verb>   [present]  [3rd person]  [past simple]  [past participle]

For example:

  <verb>      see        sees           saw             seen

Each line in this format is used to generate a large number of standard
error rules involving the specified verb. For example, the previous
specification for I<"see">, produces the following rules:

                (<she>,it) see    -->               (<she>,it) sees
           (I,you,we,they) sees   -->          (I,you,we,they) see
                       <I> seen   -->   <I> saw  -->  <I> have seen

  (be,being,been,was,were) see    --> (be,being,been,was,were) seen
  (be,being,been,was,were) saw    --> (be,being,been,was,were) seen
     (has,had,have,having) see    -->    (has,had,have,having) seen
     (has,had,have,having) saw    -->    (has,had,have,having) seen
                     being seeing -->                    being seen
  (be,being,been,was,were) saw    --> (be,being,been,was,were) seen

             to (sees, seen, saw) -->                        to see

                   try and see    -->                    try to see
            tried (and,to) seen   -->                    try to see
            tried (and,to) saw    -->                    try to see


=head3 Errors with absolutes

If the line begins with the marker "<absolute>", the format is
either

  <absolute>             [adjective]

or:

  <absolute: [modifier]> [adjective]

A line in the first format, such as:

  <absolute>  unique

produces the following set of standard rules:

                        (more,most) unique  --> unique
               (somewhat,extremely) unique  --> unique
         (quite,rather,very,highly) unique  --> unique
    (totally,completely,absolutely) unique  --> unique

A line in the second format, such as:

  <absolute: often>  fatal

produces the following rules:

        (somewhat,highly,extremely) fatal  --> fatal
    (totally,completely,absolutely) fatal  --> fatal

     (more,most) fatal  -->  fatal  -->  (more,most) often fatal
    (quite,very) fatal  -->  fatal  --> (quite,very) often fatal
          rather fatal  -->  fatal  -->       rather often fatal


=head2 The F<grammarian_cautions> file

This file specifies the rules for detecting grammatical cautions
using a single format.

The file should consist of one or more blank-delimited paragraphs.
Each paragraph should contain one or more lines of the form:

    <word or phrase>  :  <description of word or phrase>

Each paragraph represents two or more words or phrases that
are frequently confused or misused. For example:

  adverse   :  hostile or difficult
  averse    :  disinclined

  beg the question    :  to use a circular argument
  raise the question  :  to call for an answer

  council   :  a group that governs, deliberates, or advises
  counsel   :  an individual who advises
  consul    :  an individual who represents a foreign government


=head3 "Invisible" cautions

Any of these specifications may also be prefixed with a C<->, to
indicate that the particular word or phrase is never to be searched for;
that it appears only to provide contrast to--and an alternative
suggestion for--other words or phrases in the same paragraph.

For example, you may wish to be warned about "wont" (which is very
possibly a typo), but not about "won't" (which is most likely correct).
However, when being warned about "wont" you'd still like to be offered
"won't" as an alternative. That's achieved with:

      wont   :  a habitual custom
    - won't  :  will not


=head2 Parallel caution specifications

As with errors in F<grammarian_errors>, you can specify multiple
cautions in a single line, by using a parenthesized list of alternatives.
For example:

    straight(en,ened)  :  in line
    strait(en,ened)    :  tight or narrow or difficult

Note that, if such a list of alternatives is part of a larger
word, it is expanded into each of the alternatives, plus the bare
root word. So the previous example is equivalent to:

    straight      :  in line
    straighten    :  in line
    straightened  :  in line
    strait        :  tight or narrow or difficult
    straiten      :  tight or narrow or difficult
    straitened    :  tight or narrow or difficult


=head2 Shortcuts for parallel caution specifications

The most common use of parallel specifications in F<grammarian_cautions>
is to list all likely inflections of a verb. For example:

    flaunt(s,ed,ing)  :  to show off
    flout(s,ed,ing)   :  to ignore or show contempt for

So there is a shortcut for this:

    flaunt*  :  to show off
    flout*   :  to ignore or show contempt for

This shortcut is smarter than a mere substitution,
as it has a partial understanding of the rules of
English inflection:

    Ending                 Plural   Past    Continuous
    ===============        ======   ====    ==========

    -e*                     -es     -ed        -ing

    -<consonant>y*          -ies    -ied       -ying

    -ch*                    -ches   -ched      -ching

    -<anything else>*       -s      -ed        -ing

This means that rules like:

    indite* :  to write down
    indict* :  to charge with a crime

behave correctly (i.e. you get "inditing", not "inditeing")

A second shortcut (C<**>) is available to handle the case where
a terminal consonant must be doubled when forming participles.

For example, a single C<*> would create errors here:

    rebut*   :  to argue against a proposition

because it would expand to:

    rebut    :  to argue against a proposition
    rebuts   :  to argue against a proposition
    rebuted  :  to argue against a proposition
    rebuting :  to argue against a proposition

In contrast:

    rebut**   :  to argue against a proposition

would correctly expand to:

    rebut     :  to argue against a proposition
    rebuts    :  to argue against a proposition
    rebutted  :  to argue against a proposition
    rebutting :  to argue against a proposition

For less regular words or phrases, you can either list all
the alternatives in a single set of parentheses:

    (partake,partakes,partaken,partaking,partook) :  to consume
    participate*                                  :  to take part in

or list the irregular forms within the same paragraph,
but on separate lines and without descriptions:

    partake(s,n)         :  to consume
    partaking
    partook
    participate*         :  to take part in


=head1 DIAGNOSTICS

=over

=item C<< Invalid entry in grammarian_cautions: %s >>

The module found a non-blank line in one of your C<grammarian_cautions>
files in which there was no term defined. For example, the third
line of this entry would generate this diagnostic, because it lacks
a term before the colon:

    # Out-of-control vehicles do both...
    career  :  to move quickly and out of control, in a specific direction
            :  a long-term occupation


=item C<< Lingua::EN::Grammarian does not provide %s >>

You loaded the module and passed a string naming a particular subroutine
to be exported, but the module does not export that subroutine.
Did you perhaps misspell the subroutine name?

=back



=head1 DEPENDENCIES

This module requires Perl 5.10 or later.

It also requires the L<"Method::Signatures"> and
L<"Hash::Util::FieldHash"> modules.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

The module will not identify overlapping errors or cautions.
For example:

    "...and then he he go home..."

Only the first error (e.g. the doubled word: "he he") will be reported;
any overlapping errors (e.g. the incorrect conjugation: "he go") will
be ignored.


No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lingua-en-grammarian@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
