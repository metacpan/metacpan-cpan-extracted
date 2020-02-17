package Keyword::Declare;
our $VERSION = '0.001017';

use 5.012;     # required for pluggable keywords plus /.../r
use warnings;
use Carp;
use List::Util 1.45 'max', 'uniqstr';

use Keyword::Simple;
use PPR;

my $NESTING_THRESHOLD = 100;   # How many nested keyword expansions is probably too many?

my $TYPE_JUNCTION = qr{ [^\W\d] \w*+ (?: [|] [^\W\d] \w*+ )*+ }x;   # How to match a TypeA|TypeB type

my @keyword_impls;  # Tracks all keyword information in every scope

sub import {
    my (undef, $opt_ref) = @_;
    $opt_ref //= {};

    # Don't allow bad arguments to be passed when the module is loaded...
    my $arg_type = ref($opt_ref);
    if (@_ > 2 || $arg_type ne 'HASH') {
        $arg_type ||= $opt_ref;
        croak "Invalid option for: use Keyword::Declare.\n",
              "Expected single hash reference, but found $arg_type instead.\n",
              "Error detected";
    }

    # If debugging requested, set in on for the caller's lexical scope...
    if ($opt_ref->{debug}) {
        ${^H}{'Keyword::Declare debug'} = !!$opt_ref->{debug};
    }

    # Install replacement __DATA__ handler...
    # [REMOVE IF UPSTREAM MODULE (Keyword::Simple) FIXED]
    _install_data_handler();

    # Install the 'keytype' (meta-)keyword...
    Keyword::Simple::define 'keytype', sub {
        # Unpack trailing code...
        my ($src_ref) = @_;

        # Where was this keyword declared???
        my ($file, $line) = (caller)[1,2];

        # These track error messages and help decompose the parameter list...
        # (they have to be package vars, so they're visible to in-regex code blocks in older Perls)
        our ($expected, $failed_at, $block_start, @params) = ('new type name', 0, 0);

        # Match and extract the keyword definition...
        use re 'eval';
        $$src_ref =~ s{
            \A
            (?<syntax>
                            (?&PerlNWS)
                (?{ $expected = "new type name"; $failed_at = pos() })
                (?<typesigil> \$?+ )
                (?<newtype>   (?&PerlIdentifier) )
                              (?&PerlOWS)
                (?{ $expected = "'is <existing type>'"; $failed_at = pos() })
                              is
                              (?&PerlOWS)
                (?{ $expected = "existing typename or literal string or regex after 'is'"; $failed_at = pos() })
                (?<oldtype>
                    (?<oldtyperegex>  (?&PerlMatch)  )
                |
                    (?<oldtypestring> (?&PerlString) )
                |
                    (?<oldtypetype>   $TYPE_JUNCTION )
                )
            )

            $PPR::GRAMMAR
        }{}xms
            or croak "Invalid keytype definition. Expected $expected\nbut found: ",
                     substr($$src_ref, $failed_at) =~ /(\S+)/;

        # Save the information from the keyword definition...
        my %keytype_info = ( %+, location => "$file line $line", hashline => "$line $file" );

        # Set up the sigil...
        my $sigil_decl = q{};
        if ($keytype_info{typesigil}) {
            my $var = qq{$keytype_info{typesigil}$keytype_info{newtype}};
            if ($keytype_info{oldtyperegex}) {
                $keytype_info{oldtyperegex} =~ s{^m}{};
                if ($keytype_info{oldtyperegex} =~ /\(\?\&Perl[A-Z]/) {
                    $keytype_info{oldtyperegex} =~ s{^\s*(\S)}{$1\$PPR::GRAMMAR};
                }
                $sigil_decl = qq{my $var; BEGIN { $var = qr$keytype_info{oldtyperegex} }}
            }
            elsif ($keytype_info{oldtypestring}) {
                $sigil_decl = qq{my $var; BEGIN { $var = $keytype_info{oldtypestring} }}
            }
            else {
                croak "Invalid keytype definition. Can only specify a sigil on new typename ($keytype_info{typesigil}$keytype_info{newtype}) if type is specified as a string or regex";
            }
        }

        # Debug, if requested...
        if (${^H}{"Keyword::Declare debug"}) {
            my $msg = ("#" x 50) . "\n"
                    . " Installed keytype at $keytype_info{location}:\n\n$keytype_info{syntax}\n\n"
                    . ("#" x 50) . "\n";
            $msg =~ s{^}{###}gm;
            warn $msg;
        }

        # Install the lexical type definition...
        $$src_ref
            = qq{BEGIN{\$^H{q{Keyword::Declare keytype:$keytype_info{newtype}=$keytype_info{oldtype}}} = 1;}}
            . $sigil_decl
            . $$src_ref;
    };

    # Install the 'keyword' (meta-)keyword...
    Keyword::Simple::define 'keyword', sub {
        # Unpack trailing code...
        my ($src_ref) = @_;

        # Where was this keyword declared???
        my ($file, $line) = (caller)[1,2];

        # Which keywords are allowed in nested code at this point...
        my @active_IDs = @^H{ grep { m{^ Keyword::Declare \s+ active:}xms } keys %^H };
        my $lexical_keywords
            = @active_IDs ? join '|', reverse sort map { $keyword_impls[$_]{skip_matcher} } @active_IDs
            :               '(?!)';

        # These track error messages and help decompose the parameter list...
        # (they have to be package vars, so they're visible to in-regex code blocks in older Perls)
        our ($expected, $failed_at, $block_start, @params) = ('keyword name', 0, 0);

        # Match and extract the keyword definition...
        use re 'eval';
        $$src_ref =~ s{
            \A
            (?<____K_D___KeywordDeclaration>
                            (?&PerlNWS)
                (?<____K_D___keyword> (?&PerlIdentifier)                  )
                            (?&PerlOWS)
                (?{ $expected = "keyword parameters or block, or 'from' specifier"; $failed_at = pos() })
                (?<____K_D___params>  (?&____K_D___ParamList)                       )
                            (?&PerlOWS)
                (?{ $expected = 'keyword block or attribute'; $failed_at = pos() })
                (?<____K_D___attrs>   (?&PerlAttributes)?+                )
                            (?&PerlOWS)
                (?{ $expected = 'keyword block'; $failed_at = $block_start = pos() })
                (?<____K_D___block>   \{\{\{ .*? \}\}\} | (?&PerlBlock)   )
            )

            (?(DEFINE)
                (?<____K_D___ParamList>
                    \(
                        (?&____K_D___ParamSet)?+
                        (?:
                            (?&PerlOWS) \) (?&PerlOWS) :then\(
                            (?{ push @Keyword::Declare::params, undef; })
                            (?&____K_D___ParamSet)
                        )?+
                    \)
                |
                    # Nothing
                )

                (?<____K_D___ParamSet>
                                        (?&PerlOWS) (?&____K_D___Param)
                    (?: (?&PerlOWS) ,   (?&PerlOWS) (?&____K_D___Param) )*+
                                    ,?+ (?&PerlOWS)
                )

                (?<____K_D___Param>
                    (?{ $expected = 'keyword parameter type'; $failed_at = pos() })
                        (?<____K_D___type> (?&PerlMatch) | (?&PerlString) | $TYPE_JUNCTION )

                    (?{ $expected = 'keyword parameter quantifier or variable'; $failed_at = pos() })
                        (?: (?&PerlOWS)  (?<____K_D___quantifier> [?*+][?+]?+      )  )?+

                    (?{ $expected = 'keyword parameter variable'; $failed_at = pos() })
                        (?: (?&PerlOWS)  (?<____K_D___sigil>    [\$\@]             )
                                         (?<____K_D___name>     (?&PerlIdentifier) )  )?+

                    (?: (?&PerlOWS)  :sep \(
                    (?{ $expected = 'keyword parameter separator :sep'; $failed_at = pos() })
                        (?&PerlOWS)  (?<____K_D___sep>  (?&PerlMatch) | (?&PerlString) | $TYPE_JUNCTION )
                        (?&PerlOWS) \)
                    )?+

                    (?: (?&PerlOWS)  =
                    (?{ $expected = 'keyword parameter default string after ='; $failed_at = pos() })
                        (?&PerlOWS)  (?<____K_D___default>  (?&PerlQuotelikeQ) )  )?+

                    (?{ push @Keyword::Declare::params, { %+ } })
                )


                (?<PerlKeyword>
                    keyword (?&____K_D___KeywordDeclaration)
                |
                    $lexical_keywords
                )
            )

            $PPR::GRAMMAR
        }{}xms
            or croak "Invalid keyword definition. Expected $expected\nbut found: ",
                      substr($$src_ref, $failed_at) =~ /(\S+)/;

        # Save the information from the keyword definition..
        @Keyword::Declare::params = map { _deprefix($_) } @Keyword::Declare::params;
        my %keyword_info = %+;
           %keyword_info = ( %{ _deprefix(\%keyword_info) },
                             desc            => $keyword_info{____K_D___keyword},
                             param_list      => [ @Keyword::Declare::params],
                             location        => "$file line $line",
                             hashline        => "$line $file",
                           );

        # Check for excessive meta-ness...
        if ($keyword_info{keyword} =~ /^(?:keyword|keytype)$/) {
            croak "Can't redefine '$keyword_info{keyword}' keyword";
        }

        # Remember where the block started...
        my $block_location
            = ($line + substr($keyword_info{KeywordDeclaration}, 0, $block_start) =~ tr/\n//) . " $file";

        # Convert any {{{...}}} block...
        if ($keyword_info{block} =~ m{ \A \{\{\{ }xms) {
            $keyword_info{block} = _convert_triple_block(\%keyword_info);
        }

        # Extract and verify any attributes...
        _unpack_attrs(\%keyword_info);

        # Extract various useful components from the parameter list...
        _unpack_signature(\%keyword_info);

        # Prepare for a trailing #line directive to keep trailing line numbers straight...
        $line += $keyword_info{KeywordDeclaration} =~ tr/\n//;

        # Record the keyword definition...
        my $keyword_ID = $keyword_info{ID} = @keyword_impls;
        push @keyword_impls, \%keyword_info;

        # Create the keyword dispatching function...
        my $keyword_defn = _build_keyword_code(\%keyword_info);

        # Report installation of keyword if requested...
        if (${^H}{"Keyword::Declare debug"}) {
            my $msg = ("#" x 50) . "\n"
                      . " Installed keyword macro at $keyword_info{location}:\n\n$keyword_info{syntax}\n\n"
                      . ("#" x 50) . "\n";
            $msg =~ s{^}{###}gm;
            warn $msg;
        }

        # Install the keyword, exporting it as well if it's in an import() or unimport() sub...
        $$src_ref = qq{ if (((caller 0)[3]//q{}) =~ /\\b(?:un)?import\\Z/) { $keyword_defn } }
                  .  q{ Keyword::Declare::_install_data_handler(); }
                  . qq{ BEGIN{ $keyword_defn } }
                  . "\n#line $line $file\n"
                  . $$src_ref;

        # Pre-empt addition of extraneous trailing newline by Keyword::Simple...
        # [REMOVE IF UPSTREAM MODULE (Keyword::Simple) IS FIXED]
        $$src_ref =~ s{\n\z}{};
    };

    # Install the 'unkeyword' (anti-meta-)keyword...
    Keyword::Simple::define 'unkeyword', sub {
        # Unpack trailing code...
        my ($src_ref) = @_;

        # Where was this keyword declared???
        my ($file, $line) = (caller)[1,2];

        # Match and extract the keyword definition...
        use re 'eval';
        $$src_ref =~ s{
            \A
            (?<leadingspace> (?&PerlNWS) )
            (?:
                (?<keyword> (?&PerlIdentifier) )
            |
                (?<unexpected> \S+ )
            )

            $PPR::GRAMMAR
        }{}xms;

        my %keyword_info = %+;

        croak "Invalid unkeyword definition. Expected keyword name (identifier)\n"
            . " but found: $keyword_info{unexpected}"
                if defined $keyword_info{unexpected};

        # Check for excessive meta-ness...
        if ($keyword_info{keyword} =~ /^(?:keyword|keytype)$/) {
            croak "Can't undefine '$keyword_info{keyword}' keyword";
        }

        # Report installation of keyword if requested...
        if (${^H}{"Keyword::Declare debug"}) {
            my $msg = ("#" x 50) . "\n"
                      . " Uninstalled keyword macro: $keyword_info{keyword}(...)\n"
                      . " at $file line $line\n"
                      . ("#" x 50) . "\n";
            $msg =~ s{^}{###}gm;
            warn $msg;
        }

        # How to remove the Keyword::Simple keyword (with workaround for earlier versions)...
        my $keyword_defn = q{Keyword::Simple::undefine( 'KEYWORD' );};
        if ($Keyword::Simple::VERSION < 0.04) {
            $keyword_defn .= "\$^H{'Keyword::Simple/keywords'} =~ s{ KEYWORD:-?\\d*}{}g;" ;
        }

        # How to remove the Keyword::Declare keywords...
        $keyword_defn .= q{
            delete @^H{ grep m{^ Keyword::Declare \s+ active:KEYWORD:}xms, keys %^H };
        };
        $keyword_defn =~ s{KEYWORD}{$keyword_info{keyword}}g;

        # Uninstall the keyword, exporting it as well if it's in an import() or unimport() sub...
        $$src_ref = qq{ if (((caller 0)[3]//q{}) =~ /\\b(?:un)?import\\Z/) { $keyword_defn } }
                  . qq{ BEGIN{ $keyword_defn } }
                  . "\n#line $line $file\n"
                  . $$src_ref;
    };
}

# Keyword::Simple::define() has a bug: it can't define keywords starting with _
# [REMOVE WHEN UPSTREAM MODULE (Keyword::Simple) IS FIXED]
sub _replacement_define {
    package Keyword::Simple;

    my ($kw, $sub) = @_;
    $kw =~ /^[^\W\d]\w*\z/ or croak "'$kw' doesn't look like an identifier";
    ref($sub) eq 'CODE' or croak "'$sub' doesn't look like a coderef";

    if ($Keyword::Simple::VERSION < 0.04) {
        our @meta;
        my $n = @meta;
        push @meta, $sub;

        $^H{+HINTK_KEYWORDS} .= " $kw:$n";
        use B::Hooks::EndOfScope;
        on_scope_end {
            delete $meta[$n];
        };
    }
    else {
        my %keywords = %{$^H{+HINTK_KEYWORDS} // {}};
        $keywords{$kw} = $sub;
        $^H{+HINTK_KEYWORDS} = \%keywords;
    }
}

# Install a __DATA__ keyword to overcome bug in Keyword::Simple...
# [REMOVE WHEN UPSTREAM MODULE (Keyword::Simple) IS FIXED]
sub _install_data_handler {
    my $DATA_HANDLER = sub {
        # Unpack trailing code...
        my ($src_ref) = @_;

        # Convert to data handle...
        my $data = $$src_ref;
        $data =~ s{ \A [^\n]* \n }{}xms;
        $data .= "\n" unless substr($data,-1) eq "\n";

        # Create end-of-__DATA__ marker unlikely to be in the data...
        my $END_DATA = "\3" x 253;  # \3 is ASCII END-OF-TEXT, 253 is max ident length

        # Replace trailing code with code that opens a local *DATA handle...
        $$src_ref = qq{BEGIN {open *DATA, '<', \\<<'$END_DATA'\n$data$END_DATA\n} 1; };
    };
    _replacement_define('__DATA__', $DATA_HANDLER);
}


# Remove special prefix on names of internal named captures...
sub _deprefix {
    my ($hash_ref) = @_;

    return undef if !defined $hash_ref;
    return { map { my $key = $_; $key =~ s{^____K_D___}{}; $key => $hash_ref->{$_} }
                 keys %{$hash_ref} };
}


# Generate the source code that actually installs a keyword...
sub _build_keyword_code {
    my ($keyword_name, $keyword_sig, $keyword_ID, $keyword_block, $block_location, $block_hashline,  $prefix_var)
        = @{shift()}{qw< keyword sig_desc ID block location hashline prefix >};

    # Generate the keyword definition and set up its unique lexical ID...
    return qq{
        \$^H{"Keyword::Declare active:$keyword_name:\Q$keyword_sig\E"} = $keyword_ID;
        Keyword::Declare::_replacement_define('$keyword_name', Keyword::Declare::_get_dispatcher_for('$keyword_name',
            $keyword_ID, sub
#line $block_hashline
            { $keyword_impls[$keyword_ID]{sig_vars_unpack}  do $keyword_block }));
    };
}

# Locate prefix code for keyword...
sub _get_prefix {
    state $source_cache = {};

    my ($trail_ref, $keyword) = @_;

    my $filename = (caller 2)[1];
    my $source = $source_cache->{$filename} //= do { local (*ARGV, $/); @ARGV=$filename; <> };

    my $trailing = $$trail_ref;
    $trailing =~ s/\s+\z//;
    $source =~ s{\b$keyword\s*\Q$trailing\E\s*\z}{};

    return 'qq{' . quotemeta($source) . '}';
}


# Install keyword's source-code generator, and return a dispatcher sub for that keyword
# (building a closure for it, if necessary)...
sub _get_dispatcher_for {
    my ($keyword_name, $keyword_ID, $keyword_generator) = @_;

    # Install the keyword generator sub...
    $keyword_impls[$keyword_ID]{generator} = $keyword_generator;

    # This will dispatch any keyword of the specified name...
    state %dispatcher_for;
    return $dispatcher_for{$keyword_name} //= sub {
        my ($src_ref) = @_;
        my ($package, $file, $line) = caller;
        local $PPR::ERROR;

        # Which variants of this keyword are currently in scope???
        my @candidate_IDs = @^H{ grep { m{^ Keyword::Declare \s+ active:$keyword_name:}xms } keys %^H };

        # Which keywords are allowed in nested code at this point...
        my @active_IDs = @^H{ grep { m{^ Keyword::Declare \s+ active:}xms } keys %^H };
        my $lexical_keywords
            = @active_IDs ? join '|', reverse sort map { $keyword_impls[$_]{skip_matcher} } @active_IDs
            :               '(?!)';
        $lexical_keywords = "(?(DEFINE) (?<PerlKeyword> $lexical_keywords ) )";

        # Which of them match the keyword's actual arguments???
        my @viable_IDs
            = grep { $$src_ref =~ m{ \A $keyword_impls[$_]{sig_matcher} $lexical_keywords $PPR::GRAMMAR }xms }
                   @candidate_IDs;


        # If none of them match...game over!!!
        if (!@viable_IDs) {
            my $error = eval "no strict;sub{\n" . ($PPR::ERROR//q{}) . '}'
                            ? "    $keyword_name  "
                                 . do{ my $src = $$src_ref;
                                       $src =~ s{ \A \s*+ (\S++ [^\n]*+) \n .* }{$1}xs;
                                       $src;
                                   }
                            : do{ my $err = $@;
                                  $err =~ s{^}{    }gm;
                                  $err =~ s{\(eval \d++\) line \d++}
                                           { "$file line " . $PPR::ERROR->line($line) }eg;
                                  $err
                                };
            croak "Invalid "
                . join(" or ", uniqstr map { $keyword_impls[$_]{desc} } @candidate_IDs)
                . " at $file line $line.\nExpected:"
                . join("\n    ", q{}, uniqstr map { $keyword_impls[$_]{syntax} } @candidate_IDs)
                . "\nbut found:\n$error"
                . "\nCompilation failed";
        }

        # If too many of them match...see if we can reduce it to a single match...
        if (@viable_IDs > 1) {
            # Only keep those with the most parameters...
            my $max_sig_len = max map { $keyword_impls[$_]{sig_len} } @viable_IDs;
            @viable_IDs = grep { $keyword_impls[$_]{sig_len} == $max_sig_len } @viable_IDs;

            # Resolve ambiguous matches, if possible...
            if (@viable_IDs > 1) {
                @viable_IDs = _resolve_matches(@viable_IDs);
            }

            # If still too many, see if one is marked :prefer...
            if (@viable_IDs > 1) {
                if (my @preferred_IDs = grep { $keyword_impls[$_]{prefer} } @viable_IDs) {
                    @viable_IDs = @preferred_IDs;
                }
            }

            # If still too many, give up and report the ambiguity...
            if (@viable_IDs > 1) {
                croak "Ambiguous "
                    . join(" or ", uniqstr map { $keyword_impls[$_]{desc} } @viable_IDs)
                    . " at $file line $line:\n    $keyword_name  "
                    . do{ my $src = $$src_ref;
                          $src =~ s{ \A \s*+ ( \S++ [^\n]*+) \n .* }{$1}xs;
                          $src;
                        }
                    . "\nCould be:\n"
                    . join("\n", map { "    $keyword_impls[$_]{syntax}" } @viable_IDs)
                    . "\nCompilation failed";
            }
        }

        # If we get here, we have a unique best candidate, so install it...
        my ($ID) = @viable_IDs;

        # Add in the replacement code...
        _insert_replacement_code($src_ref, $ID, $file, $line, $lexical_keywords);
    }
}

# These help unpack /.../ type specifiers...
my $REGEX_TYPE = qr{ \A (?&PerlMatch) \z $PPR::GRAMMAR }x;

my $REGEX_PAT = qr{
        \A
        (?: (?<delim> / ) | m \s* (?<delim> \S ))
        (?<pattern> .* )
        (?: \k<delim> | [])>\}] )
        (?<modifiers> [imnsxadlup]*+ )
        \z
    }xs;

my %ACTUAL_TYPE_OF = (
  # Specified type...                         # Translated to...


# Autogenerated type translations (from bin/gen_types.pl)...

    'ArrayIndexer'                               => '/(?&PerlArrayIndexer)/',
    'AssignmentOperator'                         => '/(?&PerlAssignmentOperator)/',
    'Attributes'                                 => '/(?&PerlAttributes)/',
    'Comma'                                      => '/(?&PerlComma)/',
    'Document'                                   => '/(?&PerlDocument)/',
    'HashIndexer'                                => '/(?&PerlHashIndexer)/',
    'InfixBinaryOperator'                        => '/(?&PerlInfixBinaryOperator)/',
    'LowPrecedenceInfixOperator'                 => '/(?&PerlLowPrecedenceInfixOperator)/',
    'OWS'                                        => '/(?&PerlOWS)/',
    'PostfixUnaryOperator'                       => '/(?&PerlPostfixUnaryOperator)/',
    'PrefixUnaryOperator'                        => '/(?&PerlPrefixUnaryOperator)/',
    'StatementModifier'                          => '/(?&PerlStatementModifier)/',
    'NWS'                                        => '/(?&PerlNWS)/',
    'Whitespace'                                 => '/(?&PerlNWS)/',
    'Statement'                                  => '/(?&PerlStatement)/',
    'Block'                                      => '/(?&PerlBlock)/',
    'Comment'                                    => '/(?&PerlComment)/',
    'ControlBlock'                               => '/(?&PerlControlBlock)/',
    'Expression'                                 => '/(?&PerlExpression)/',
    'Expr'                                       => '/(?&PerlExpression)/',
    'Format'                                     => '/(?&PerlFormat)/',
    'Keyword'                                    => '/(?&PerlKeyword)/',
    'Label'                                      => '/(?&PerlLabel)/',
    'PackageDeclaration'                         => '/(?&PerlPackageDeclaration)/',
    'Pod'                                        => '/(?&PerlPod)/',
    'SubroutineDeclaration'                      => '/(?&PerlSubroutineDeclaration)/',
    'UseStatement'                               => '/(?&PerlUseStatement)/',
    'LowPrecedenceNotExpression'                 => '/(?&PerlLowPrecedenceNotExpression)/',
    'List'                                       => '/(?&PerlList)/',
    'CommaList'                                  => '/(?&PerlCommaList)/',
    'Assignment'                                 => '/(?&PerlAssignment)/',
    'ConditionalExpression'                      => '/(?&PerlConditionalExpression)/',
    'Ternary'                                    => '/(?&PerlConditionalExpression)/',
    'ListElem'                                   => '/(?&PerlConditionalExpression)/',
    'BinaryExpression'                           => '/(?&PerlBinaryExpression)/',
    'PrefixPostfixTerm'                          => '/(?&PerlPrefixPostfixTerm)/',
    'Term'                                       => '/(?&PerlTerm)/',
    'AnonymousArray'                             => '/(?&PerlAnonymousArray)/',
    'AnonArray'                                  => '/(?&PerlAnonymousArray)/',
    'AnonymousHash'                              => '/(?&PerlAnonymousHash)/',
    'AnonHash'                                   => '/(?&PerlAnonymousHash)/',
    'AnonymousSubroutine'                        => '/(?&PerlAnonymousSubroutine)/',
    'Call'                                       => '/(?&PerlCall)/',
    'DiamondOperator'                            => '/(?&PerlDiamondOperator)/',
    'DoBlock'                                    => '/(?&PerlDoBlock)/',
    'EvalBlock'                                  => '/(?&PerlEvalBlock)/',
    'Literal'                                    => '/(?&PerlLiteral)/',
    'Lvalue'                                     => '/(?&PerlLvalue)/',
    'ParenthesesList'                            => '/(?&PerlParenthesesList)/',
    'ParensList'                                 => '/(?&PerlParenthesesList)/',
    'Quotelike'                                  => '/(?&PerlQuotelike)/',
    'ReturnStatement'                            => '/(?&PerlReturnStatement)/',
    'Typeglob'                                   => '/(?&PerlTypeglob)/',
    'VariableDeclaration'                        => '/(?&PerlVariableDeclaration)/',
    'VarDecl'                                    => '/(?&PerlVariableDeclaration)/',
    'Variable'                                   => '/(?&PerlVariable)/',
    'Var'                                        => '/(?&PerlVariable)/',
    'ArrayAccess'                                => '/(?&PerlArrayAccess)/',
    'Bareword'                                   => '/(?&PerlBareword)/',
    'BuiltinFunction'                            => '/(?&PerlBuiltinFunction)/',
    'HashAccess'                                 => '/(?&PerlHashAccess)/',
    'Number'                                     => '/(?&PerlNumber)/',
    'Num'                                        => '/(?&PerlNumber)/',
    'QuotelikeQW'                                => '/(?&PerlQuotelikeQW)/',
    'QuotelikeQX'                                => '/(?&PerlQuotelikeQX)/',
    'Regex'                                      => '/(?&PerlRegex)/',
    'Regexp'                                     => '/(?&PerlRegex)/',
    'ScalarAccess'                               => '/(?&PerlScalarAccess)/',
    'String'                                     => '/(?&PerlString)/',
    'Str'                                        => '/(?&PerlString)/',
    'Substitution'                               => '/(?&PerlSubstitution)/',
    'QuotelikeS'                                 => '/(?&PerlSubstitution)/',
    'Transliteration'                            => '/(?&PerlTransliteration)/',
    'QuotelikeTR'                                => '/(?&PerlTransliteration)/',
    'ContextualRegex'                            => '/(?&PerlContextualRegex)/',
    'Heredoc'                                    => '/(?&PerlHeredoc)/',
    'Integer'                                    => '/(?&PerlInteger)/',
    'Int'                                        => '/(?&PerlInteger)/',
    'Match'                                      => '/(?&PerlMatch)/',
    'QuotelikeM'                                 => '/(?&PerlMatch)/',
    'NullaryBuiltinFunction'                     => '/(?&PerlNullaryBuiltinFunction)/',
    'OldQualifiedIdentifier'                     => '/(?&PerlOldQualifiedIdentifier)/',
    'QuotelikeQ'                                 => '/(?&PerlQuotelikeQ)/',
    'QuotelikeQQ'                                => '/(?&PerlQuotelikeQQ)/',
    'QuotelikeQR'                                => '/(?&PerlQuotelikeQR)/',
    'VString'                                    => '/(?&PerlVString)/',
    'VariableArray'                              => '/(?&PerlVariableArray)/',
    'VarArray'                                   => '/(?&PerlVariableArray)/',
    'ArrayVar'                                   => '/(?&PerlVariableArray)/',
    'VariableHash'                               => '/(?&PerlVariableHash)/',
    'VarHash'                                    => '/(?&PerlVariableHash)/',
    'HashVar'                                    => '/(?&PerlVariableHash)/',
    'VariableScalar'                             => '/(?&PerlVariableScalar)/',
    'VarScalar'                                  => '/(?&PerlVariableScalar)/',
    'ScalarVar'                                  => '/(?&PerlVariableScalar)/',
    'VersionNumber'                              => '/(?&PerlVersionNumber)/',
    'ContextualMatch'                            => '/(?&PerlContextualMatch)/',
    'ContextualQuotelikeM'                       => '/(?&PerlContextualMatch)/',
    'PositiveInteger'                            => '/(?&PerlPositiveInteger)/',
    'PosInt'                                     => '/(?&PerlPositiveInteger)/',
    'QualifiedIdentifier'                        => '/(?&PerlQualifiedIdentifier)/',
    'QualIdent'                                  => '/(?&PerlQualifiedIdentifier)/',
    'QuotelikeQR'                                => '/(?&PerlQuotelikeQR)/',
    'VString'                                    => '/(?&PerlVString)/',
    'Identifier'                                 => '/(?&PerlIdentifier)/',
    'Ident'                                      => '/(?&PerlIdentifier)/',

# End of autogenerated type translations

    'Integer'                                => '/(?:[+-]?+(?&PPR_digit_seq)(?!\.))/',
    'Int'                                    => '/(?:[+-]?+(?&PPR_digit_seq)(?!\.))/',
    'PositiveInteger'                        => '/(?:[+]?+(?&PPR_digit_seq)(?!\.))/',
    'PosInt'                                 => '/(?:[+]?+(?&PPR_digit_seq)(?!\.))/',
    'Comment'                                => '/\#[^\n]*\n/',
);

our %isa = (

# Autogenerated type ISA hierarchy (from bin/gen_types.pl)...

"AnonArray\34Assignment"=>1,"AnonArray\34BinaryExpression"=>1,"AnonArray\34CommaList"=>1,"AnonArray\34ConditionalExpression"=>1,"AnonArray\34Document"=>1,"AnonArray\34Expr"=>1,"AnonArray\34Expression"=>1,"AnonArray\34List"=>1,"AnonArray\34ListElem"=>1,"AnonArray\34LowPrecedenceNotExpression"=>1,"AnonArray\34PrefixPostfixTerm"=>1,"AnonArray\34Statement"=>1,"AnonArray\34Term"=>1,"AnonArray\34Ternary"=>1,"AnonHash\34Assignment"=>1,"AnonHash\34BinaryExpression"=>1,"AnonHash\34CommaList"=>1,"AnonHash\34ConditionalExpression"=>1,"AnonHash\34Document"=>1,"AnonHash\34Expr"=>1,"AnonHash\34Expression"=>1,"AnonHash\34List"=>1,"AnonHash\34ListElem"=>1,"AnonHash\34LowPrecedenceNotExpression"=>1,"AnonHash\34PrefixPostfixTerm"=>1,"AnonHash\34Statement"=>1,"AnonHash\34Term"=>1,"AnonHash\34Ternary"=>1,"AnonymousArray\34Assignment"=>1,"AnonymousArray\34BinaryExpression"=>1,"AnonymousArray\34CommaList"=>1,"AnonymousArray\34ConditionalExpression"=>1,"AnonymousArray\34Document"=>1,"AnonymousArray\34Expr"=>1,"AnonymousArray\34Expression"=>1,"AnonymousArray\34List"=>1,"AnonymousArray\34ListElem"=>1,"AnonymousArray\34LowPrecedenceNotExpression"=>1,"AnonymousArray\34PrefixPostfixTerm"=>1,"AnonymousArray\34Statement"=>1,"AnonymousArray\34Term"=>1,"AnonymousArray\34Ternary"=>1,"AnonymousHash\34Assignment"=>1,"AnonymousHash\34BinaryExpression"=>1,"AnonymousHash\34CommaList"=>1,"AnonymousHash\34ConditionalExpression"=>1,"AnonymousHash\34Document"=>1,"AnonymousHash\34Expr"=>1,"AnonymousHash\34Expression"=>1,"AnonymousHash\34List"=>1,"AnonymousHash\34ListElem"=>1,"AnonymousHash\34LowPrecedenceNotExpression"=>1,"AnonymousHash\34PrefixPostfixTerm"=>1,"AnonymousHash\34Statement"=>1,"AnonymousHash\34Term"=>1,"AnonymousHash\34Ternary"=>1,"AnonymousSubroutine\34Assignment"=>1,"AnonymousSubroutine\34BinaryExpression"=>1,"AnonymousSubroutine\34CommaList"=>1,"AnonymousSubroutine\34ConditionalExpression"=>1,"AnonymousSubroutine\34Document"=>1,"AnonymousSubroutine\34Expr"=>1,"AnonymousSubroutine\34Expression"=>1,"AnonymousSubroutine\34List"=>1,"AnonymousSubroutine\34ListElem"=>1,"AnonymousSubroutine\34LowPrecedenceNotExpression"=>1,"AnonymousSubroutine\34PrefixPostfixTerm"=>1,"AnonymousSubroutine\34Statement"=>1,"AnonymousSubroutine\34Term"=>1,"AnonymousSubroutine\34Ternary"=>1,"ArrayAccess\34Assignment"=>1,"ArrayAccess\34BinaryExpression"=>1,"ArrayAccess\34CommaList"=>1,"ArrayAccess\34ConditionalExpression"=>1,"ArrayAccess\34Document"=>1,"ArrayAccess\34Expr"=>1,"ArrayAccess\34Expression"=>1,"ArrayAccess\34List"=>1,"ArrayAccess\34ListElem"=>1,"ArrayAccess\34LowPrecedenceNotExpression"=>1,"ArrayAccess\34PrefixPostfixTerm"=>1,"ArrayAccess\34Statement"=>1,"ArrayAccess\34Term"=>1,"ArrayAccess\34Ternary"=>1,"ArrayAccess\34Var"=>1,"ArrayAccess\34Variable"=>1,"ArrayVar\34ArrayAccess"=>1,"ArrayVar\34Assignment"=>1,"ArrayVar\34BinaryExpression"=>1,"ArrayVar\34CommaList"=>1,"ArrayVar\34ConditionalExpression"=>1,"ArrayVar\34Document"=>1,"ArrayVar\34Expr"=>1,"ArrayVar\34Expression"=>1,"ArrayVar\34List"=>1,"ArrayVar\34ListElem"=>1,"ArrayVar\34LowPrecedenceNotExpression"=>1,"ArrayVar\34PrefixPostfixTerm"=>1,"ArrayVar\34Statement"=>1,"ArrayVar\34Term"=>1,"ArrayVar\34Ternary"=>1,"ArrayVar\34Var"=>1,"ArrayVar\34Variable"=>1,"Assignment\34CommaList"=>1,"Assignment\34Document"=>1,"Assignment\34Expr"=>1,"Assignment\34Expression"=>1,"Assignment\34List"=>1,"Assignment\34LowPrecedenceNotExpression"=>1,"Assignment\34Statement"=>1,"Bareword\34Assignment"=>1,"Bareword\34BinaryExpression"=>1,"Bareword\34CommaList"=>1,"Bareword\34ConditionalExpression"=>1,"Bareword\34Document"=>1,"Bareword\34Expr"=>1,"Bareword\34Expression"=>1,"Bareword\34List"=>1,"Bareword\34ListElem"=>1,"Bareword\34Literal"=>1,"Bareword\34LowPrecedenceNotExpression"=>1,"Bareword\34PrefixPostfixTerm"=>1,"Bareword\34Statement"=>1,"Bareword\34Term"=>1,"Bareword\34Ternary"=>1,"BinaryExpression\34Assignment"=>1,"BinaryExpression\34CommaList"=>1,"BinaryExpression\34ConditionalExpression"=>1,"BinaryExpression\34Document"=>1,"BinaryExpression\34Expr"=>1,"BinaryExpression\34Expression"=>1,"BinaryExpression\34List"=>1,"BinaryExpression\34ListElem"=>1,"BinaryExpression\34LowPrecedenceNotExpression"=>1,"BinaryExpression\34Statement"=>1,"BinaryExpression\34Ternary"=>1,"Block\34Document"=>1,"Block\34Statement"=>1,"BuiltinFunction\34Assignment"=>1,"BuiltinFunction\34BinaryExpression"=>1,"BuiltinFunction\34Call"=>1,"BuiltinFunction\34CommaList"=>1,"BuiltinFunction\34ConditionalExpression"=>1,"BuiltinFunction\34Document"=>1,"BuiltinFunction\34Expr"=>1,"BuiltinFunction\34Expression"=>1,"BuiltinFunction\34List"=>1,"BuiltinFunction\34ListElem"=>1,"BuiltinFunction\34LowPrecedenceNotExpression"=>1,"BuiltinFunction\34PrefixPostfixTerm"=>1,"BuiltinFunction\34Statement"=>1,"BuiltinFunction\34Term"=>1,"BuiltinFunction\34Ternary"=>1,"Call\34Assignment"=>1,"Call\34BinaryExpression"=>1,"Call\34CommaList"=>1,"Call\34ConditionalExpression"=>1,"Call\34Document"=>1,"Call\34Expr"=>1,"Call\34Expression"=>1,"Call\34List"=>1,"Call\34ListElem"=>1,"Call\34LowPrecedenceNotExpression"=>1,"Call\34PrefixPostfixTerm"=>1,"Call\34Statement"=>1,"Call\34Term"=>1,"Call\34Ternary"=>1,"CommaList\34Document"=>1,"CommaList\34Expr"=>1,"CommaList\34Expression"=>1,"CommaList\34List"=>1,"CommaList\34LowPrecedenceNotExpression"=>1,"CommaList\34Statement"=>1,"Comment\34NWS"=>1,"Comment\34OWS"=>1,"Comment\34Whitespace"=>1,"ConditionalExpression\34Assignment"=>1,"ConditionalExpression\34CommaList"=>1,"ConditionalExpression\34Document"=>1,"ConditionalExpression\34Expr"=>1,"ConditionalExpression\34Expression"=>1,"ConditionalExpression\34List"=>1,"ConditionalExpression\34LowPrecedenceNotExpression"=>1,"ConditionalExpression\34Statement"=>1,"ContextualMatch\34Assignment"=>1,"ContextualMatch\34BinaryExpression"=>1,"ContextualMatch\34CommaList"=>1,"ContextualMatch\34ConditionalExpression"=>1,"ContextualMatch\34ContextualRegex"=>1,"ContextualMatch\34Document"=>1,"ContextualMatch\34Expr"=>1,"ContextualMatch\34Expression"=>1,"ContextualMatch\34List"=>1,"ContextualMatch\34ListElem"=>1,"ContextualMatch\34LowPrecedenceNotExpression"=>1,"ContextualMatch\34Match"=>1,"ContextualMatch\34PrefixPostfixTerm"=>1,"ContextualMatch\34Quotelike"=>1,"ContextualMatch\34QuotelikeM"=>1,"ContextualMatch\34Regex"=>1,"ContextualMatch\34Regexp"=>1,"ContextualMatch\34Statement"=>1,"ContextualMatch\34Term"=>1,"ContextualMatch\34Ternary"=>1,"ContextualQuotelikeM\34Assignment"=>1,"ContextualQuotelikeM\34BinaryExpression"=>1,"ContextualQuotelikeM\34CommaList"=>1,"ContextualQuotelikeM\34ConditionalExpression"=>1,"ContextualQuotelikeM\34ContextualRegex"=>1,"ContextualQuotelikeM\34Document"=>1,"ContextualQuotelikeM\34Expr"=>1,"ContextualQuotelikeM\34Expression"=>1,"ContextualQuotelikeM\34List"=>1,"ContextualQuotelikeM\34ListElem"=>1,"ContextualQuotelikeM\34LowPrecedenceNotExpression"=>1,"ContextualQuotelikeM\34Match"=>1,"ContextualQuotelikeM\34PrefixPostfixTerm"=>1,"ContextualQuotelikeM\34Quotelike"=>1,"ContextualQuotelikeM\34QuotelikeM"=>1,"ContextualQuotelikeM\34Regex"=>1,"ContextualQuotelikeM\34Regexp"=>1,"ContextualQuotelikeM\34Statement"=>1,"ContextualQuotelikeM\34Term"=>1,"ContextualQuotelikeM\34Ternary"=>1,"ContextualRegex\34Assignment"=>1,"ContextualRegex\34BinaryExpression"=>1,"ContextualRegex\34CommaList"=>1,"ContextualRegex\34ConditionalExpression"=>1,"ContextualRegex\34Document"=>1,"ContextualRegex\34Expr"=>1,"ContextualRegex\34Expression"=>1,"ContextualRegex\34List"=>1,"ContextualRegex\34ListElem"=>1,"ContextualRegex\34LowPrecedenceNotExpression"=>1,"ContextualRegex\34PrefixPostfixTerm"=>1,"ContextualRegex\34Quotelike"=>1,"ContextualRegex\34Regex"=>1,"ContextualRegex\34Regexp"=>1,"ContextualRegex\34Statement"=>1,"ContextualRegex\34Term"=>1,"ContextualRegex\34Ternary"=>1,"ControlBlock\34Document"=>1,"ControlBlock\34Statement"=>1,"DiamondOperator\34Assignment"=>1,"DiamondOperator\34BinaryExpression"=>1,"DiamondOperator\34CommaList"=>1,"DiamondOperator\34ConditionalExpression"=>1,"DiamondOperator\34Document"=>1,"DiamondOperator\34Expr"=>1,"DiamondOperator\34Expression"=>1,"DiamondOperator\34List"=>1,"DiamondOperator\34ListElem"=>1,"DiamondOperator\34LowPrecedenceNotExpression"=>1,"DiamondOperator\34PrefixPostfixTerm"=>1,"DiamondOperator\34Statement"=>1,"DiamondOperator\34Term"=>1,"DiamondOperator\34Ternary"=>1,"DoBlock\34Assignment"=>1,"DoBlock\34BinaryExpression"=>1,"DoBlock\34CommaList"=>1,"DoBlock\34ConditionalExpression"=>1,"DoBlock\34Document"=>1,"DoBlock\34Expr"=>1,"DoBlock\34Expression"=>1,"DoBlock\34List"=>1,"DoBlock\34ListElem"=>1,"DoBlock\34LowPrecedenceNotExpression"=>1,"DoBlock\34PrefixPostfixTerm"=>1,"DoBlock\34Statement"=>1,"DoBlock\34Term"=>1,"DoBlock\34Ternary"=>1,"EvalBlock\34Assignment"=>1,"EvalBlock\34BinaryExpression"=>1,"EvalBlock\34CommaList"=>1,"EvalBlock\34ConditionalExpression"=>1,"EvalBlock\34Document"=>1,"EvalBlock\34Expr"=>1,"EvalBlock\34Expression"=>1,"EvalBlock\34List"=>1,"EvalBlock\34ListElem"=>1,"EvalBlock\34LowPrecedenceNotExpression"=>1,"EvalBlock\34PrefixPostfixTerm"=>1,"EvalBlock\34Statement"=>1,"EvalBlock\34Term"=>1,"EvalBlock\34Ternary"=>1,"Expr\34Document"=>1,"Expr\34Statement"=>1,"Expression\34Document"=>1,"Expression\34Statement"=>1,"Format\34Document"=>1,"Format\34Statement"=>1,"HashAccess\34Assignment"=>1,"HashAccess\34BinaryExpression"=>1,"HashAccess\34CommaList"=>1,"HashAccess\34ConditionalExpression"=>1,"HashAccess\34Document"=>1,"HashAccess\34Expr"=>1,"HashAccess\34Expression"=>1,"HashAccess\34List"=>1,"HashAccess\34ListElem"=>1,"HashAccess\34LowPrecedenceNotExpression"=>1,"HashAccess\34PrefixPostfixTerm"=>1,"HashAccess\34Statement"=>1,"HashAccess\34Term"=>1,"HashAccess\34Ternary"=>1,"HashAccess\34Var"=>1,"HashAccess\34Variable"=>1,"HashVar\34Assignment"=>1,"HashVar\34BinaryExpression"=>1,"HashVar\34CommaList"=>1,"HashVar\34ConditionalExpression"=>1,"HashVar\34Document"=>1,"HashVar\34Expr"=>1,"HashVar\34Expression"=>1,"HashVar\34HashAccess"=>1,"HashVar\34List"=>1,"HashVar\34ListElem"=>1,"HashVar\34LowPrecedenceNotExpression"=>1,"HashVar\34PrefixPostfixTerm"=>1,"HashVar\34Statement"=>1,"HashVar\34Term"=>1,"HashVar\34Ternary"=>1,"HashVar\34Var"=>1,"HashVar\34Variable"=>1,"Heredoc\34Assignment"=>1,"Heredoc\34BinaryExpression"=>1,"Heredoc\34CommaList"=>1,"Heredoc\34ConditionalExpression"=>1,"Heredoc\34Document"=>1,"Heredoc\34Expr"=>1,"Heredoc\34Expression"=>1,"Heredoc\34List"=>1,"Heredoc\34ListElem"=>1,"Heredoc\34Literal"=>1,"Heredoc\34LowPrecedenceNotExpression"=>1,"Heredoc\34PrefixPostfixTerm"=>1,"Heredoc\34Statement"=>1,"Heredoc\34Str"=>1,"Heredoc\34String"=>1,"Heredoc\34Term"=>1,"Heredoc\34Ternary"=>1,"Ident\34Assignment"=>1,"Ident\34Bareword"=>1,"Ident\34BinaryExpression"=>1,"Ident\34CommaList"=>1,"Ident\34ConditionalExpression"=>1,"Ident\34Document"=>1,"Ident\34Expr"=>1,"Ident\34Expression"=>1,"Ident\34List"=>1,"Ident\34ListElem"=>1,"Ident\34Literal"=>1,"Ident\34LowPrecedenceNotExpression"=>1,"Ident\34OldQualifiedIdentifier"=>1,"Ident\34PrefixPostfixTerm"=>1,"Ident\34QualIdent"=>1,"Ident\34QualifiedIdentifier"=>1,"Ident\34Statement"=>1,"Ident\34Term"=>1,"Ident\34Ternary"=>1,"Identifier\34Assignment"=>1,"Identifier\34Bareword"=>1,"Identifier\34BinaryExpression"=>1,"Identifier\34CommaList"=>1,"Identifier\34ConditionalExpression"=>1,"Identifier\34Document"=>1,"Identifier\34Expr"=>1,"Identifier\34Expression"=>1,"Identifier\34List"=>1,"Identifier\34ListElem"=>1,"Identifier\34Literal"=>1,"Identifier\34LowPrecedenceNotExpression"=>1,"Identifier\34OldQualifiedIdentifier"=>1,"Identifier\34PrefixPostfixTerm"=>1,"Identifier\34QualIdent"=>1,"Identifier\34QualifiedIdentifier"=>1,"Identifier\34Statement"=>1,"Identifier\34Term"=>1,"Identifier\34Ternary"=>1,"Int\34Assignment"=>1,"Int\34BinaryExpression"=>1,"Int\34CommaList"=>1,"Int\34ConditionalExpression"=>1,"Int\34Document"=>1,"Int\34Expr"=>1,"Int\34Expression"=>1,"Int\34List"=>1,"Int\34ListElem"=>1,"Int\34Literal"=>1,"Int\34LowPrecedenceNotExpression"=>1,"Int\34Num"=>1,"Int\34Number"=>1,"Int\34PrefixPostfixTerm"=>1,"Int\34Statement"=>1,"Int\34Term"=>1,"Int\34Ternary"=>1,"Integer\34Assignment"=>1,"Integer\34BinaryExpression"=>1,"Integer\34CommaList"=>1,"Integer\34ConditionalExpression"=>1,"Integer\34Document"=>1,"Integer\34Expr"=>1,"Integer\34Expression"=>1,"Integer\34List"=>1,"Integer\34ListElem"=>1,"Integer\34Literal"=>1,"Integer\34LowPrecedenceNotExpression"=>1,"Integer\34Num"=>1,"Integer\34Number"=>1,"Integer\34PrefixPostfixTerm"=>1,"Integer\34Statement"=>1,"Integer\34Term"=>1,"Integer\34Ternary"=>1,"Keyword\34Document"=>1,"Keyword\34Statement"=>1,"Label\34Document"=>1,"Label\34Statement"=>1,"List\34Document"=>1,"List\34Expr"=>1,"List\34Expression"=>1,"List\34LowPrecedenceNotExpression"=>1,"List\34Statement"=>1,"ListElem\34Assignment"=>1,"ListElem\34CommaList"=>1,"ListElem\34Document"=>1,"ListElem\34Expr"=>1,"ListElem\34Expression"=>1,"ListElem\34List"=>1,"ListElem\34LowPrecedenceNotExpression"=>1,"ListElem\34Statement"=>1,"Literal\34Assignment"=>1,"Literal\34BinaryExpression"=>1,"Literal\34CommaList"=>1,"Literal\34ConditionalExpression"=>1,"Literal\34Document"=>1,"Literal\34Expr"=>1,"Literal\34Expression"=>1,"Literal\34List"=>1,"Literal\34ListElem"=>1,"Literal\34LowPrecedenceNotExpression"=>1,"Literal\34PrefixPostfixTerm"=>1,"Literal\34Statement"=>1,"Literal\34Term"=>1,"Literal\34Ternary"=>1,"LowPrecedenceNotExpression\34Document"=>1,"LowPrecedenceNotExpression\34Expr"=>1,"LowPrecedenceNotExpression\34Expression"=>1,"LowPrecedenceNotExpression\34Statement"=>1,"Lvalue\34Assignment"=>1,"Lvalue\34BinaryExpression"=>1,"Lvalue\34CommaList"=>1,"Lvalue\34ConditionalExpression"=>1,"Lvalue\34Document"=>1,"Lvalue\34Expr"=>1,"Lvalue\34Expression"=>1,"Lvalue\34List"=>1,"Lvalue\34ListElem"=>1,"Lvalue\34LowPrecedenceNotExpression"=>1,"Lvalue\34PrefixPostfixTerm"=>1,"Lvalue\34Statement"=>1,"Lvalue\34Term"=>1,"Lvalue\34Ternary"=>1,"Match\34Assignment"=>1,"Match\34BinaryExpression"=>1,"Match\34CommaList"=>1,"Match\34ConditionalExpression"=>1,"Match\34Document"=>1,"Match\34Expr"=>1,"Match\34Expression"=>1,"Match\34List"=>1,"Match\34ListElem"=>1,"Match\34LowPrecedenceNotExpression"=>1,"Match\34PrefixPostfixTerm"=>1,"Match\34Quotelike"=>1,"Match\34Regex"=>1,"Match\34Regexp"=>1,"Match\34Statement"=>1,"Match\34Term"=>1,"Match\34Ternary"=>1,"NullaryBuiltinFunction\34Assignment"=>1,"NullaryBuiltinFunction\34BinaryExpression"=>1,"NullaryBuiltinFunction\34BuiltinFunction"=>1,"NullaryBuiltinFunction\34Call"=>1,"NullaryBuiltinFunction\34CommaList"=>1,"NullaryBuiltinFunction\34ConditionalExpression"=>1,"NullaryBuiltinFunction\34Document"=>1,"NullaryBuiltinFunction\34Expr"=>1,"NullaryBuiltinFunction\34Expression"=>1,"NullaryBuiltinFunction\34List"=>1,"NullaryBuiltinFunction\34ListElem"=>1,"NullaryBuiltinFunction\34LowPrecedenceNotExpression"=>1,"NullaryBuiltinFunction\34PrefixPostfixTerm"=>1,"NullaryBuiltinFunction\34Statement"=>1,"NullaryBuiltinFunction\34Term"=>1,"NullaryBuiltinFunction\34Ternary"=>1,"Num\34Assignment"=>1,"Num\34BinaryExpression"=>1,"Num\34CommaList"=>1,"Num\34ConditionalExpression"=>1,"Num\34Document"=>1,"Num\34Expr"=>1,"Num\34Expression"=>1,"Num\34List"=>1,"Num\34ListElem"=>1,"Num\34Literal"=>1,"Num\34LowPrecedenceNotExpression"=>1,"Num\34PrefixPostfixTerm"=>1,"Num\34Statement"=>1,"Num\34Term"=>1,"Num\34Ternary"=>1,"Number\34Assignment"=>1,"Number\34BinaryExpression"=>1,"Number\34CommaList"=>1,"Number\34ConditionalExpression"=>1,"Number\34Document"=>1,"Number\34Expr"=>1,"Number\34Expression"=>1,"Number\34List"=>1,"Number\34ListElem"=>1,"Number\34Literal"=>1,"Number\34LowPrecedenceNotExpression"=>1,"Number\34PrefixPostfixTerm"=>1,"Number\34Statement"=>1,"Number\34Term"=>1,"Number\34Ternary"=>1,"NWS\34OWS"=>1,"OldQualifiedIdentifier\34Assignment"=>1,"OldQualifiedIdentifier\34Bareword"=>1,"OldQualifiedIdentifier\34BinaryExpression"=>1,"OldQualifiedIdentifier\34CommaList"=>1,"OldQualifiedIdentifier\34ConditionalExpression"=>1,"OldQualifiedIdentifier\34Document"=>1,"OldQualifiedIdentifier\34Expr"=>1,"OldQualifiedIdentifier\34Expression"=>1,"OldQualifiedIdentifier\34List"=>1,"OldQualifiedIdentifier\34ListElem"=>1,"OldQualifiedIdentifier\34Literal"=>1,"OldQualifiedIdentifier\34LowPrecedenceNotExpression"=>1,"OldQualifiedIdentifier\34PrefixPostfixTerm"=>1,"OldQualifiedIdentifier\34Statement"=>1,"OldQualifiedIdentifier\34Term"=>1,"OldQualifiedIdentifier\34Ternary"=>1,"PackageDeclaration\34Document"=>1,"PackageDeclaration\34Statement"=>1,"ParensList\34Assignment"=>1,"ParensList\34BinaryExpression"=>1,"ParensList\34CommaList"=>1,"ParensList\34ConditionalExpression"=>1,"ParensList\34Document"=>1,"ParensList\34Expr"=>1,"ParensList\34Expression"=>1,"ParensList\34List"=>1,"ParensList\34ListElem"=>1,"ParensList\34LowPrecedenceNotExpression"=>1,"ParensList\34PrefixPostfixTerm"=>1,"ParensList\34Statement"=>1,"ParensList\34Term"=>1,"ParensList\34Ternary"=>1,"ParenthesesList\34Assignment"=>1,"ParenthesesList\34BinaryExpression"=>1,"ParenthesesList\34CommaList"=>1,"ParenthesesList\34ConditionalExpression"=>1,"ParenthesesList\34Document"=>1,"ParenthesesList\34Expr"=>1,"ParenthesesList\34Expression"=>1,"ParenthesesList\34List"=>1,"ParenthesesList\34ListElem"=>1,"ParenthesesList\34LowPrecedenceNotExpression"=>1,"ParenthesesList\34PrefixPostfixTerm"=>1,"ParenthesesList\34Statement"=>1,"ParenthesesList\34Term"=>1,"ParenthesesList\34Ternary"=>1,"Pod\34NWS"=>1,"Pod\34OWS"=>1,"Pod\34Whitespace"=>1,"PosInt\34Assignment"=>1,"PosInt\34BinaryExpression"=>1,"PosInt\34CommaList"=>1,"PosInt\34ConditionalExpression"=>1,"PosInt\34Document"=>1,"PosInt\34Expr"=>1,"PosInt\34Expression"=>1,"PosInt\34Int"=>1,"PosInt\34Integer"=>1,"PosInt\34List"=>1,"PosInt\34ListElem"=>1,"PosInt\34Literal"=>1,"PosInt\34LowPrecedenceNotExpression"=>1,"PosInt\34Num"=>1,"PosInt\34Number"=>1,"PosInt\34PrefixPostfixTerm"=>1,"PosInt\34Statement"=>1,"PosInt\34Term"=>1,"PosInt\34Ternary"=>1,"PositiveInteger\34Assignment"=>1,"PositiveInteger\34BinaryExpression"=>1,"PositiveInteger\34CommaList"=>1,"PositiveInteger\34ConditionalExpression"=>1,"PositiveInteger\34Document"=>1,"PositiveInteger\34Expr"=>1,"PositiveInteger\34Expression"=>1,"PositiveInteger\34Int"=>1,"PositiveInteger\34Integer"=>1,"PositiveInteger\34List"=>1,"PositiveInteger\34ListElem"=>1,"PositiveInteger\34Literal"=>1,"PositiveInteger\34LowPrecedenceNotExpression"=>1,"PositiveInteger\34Num"=>1,"PositiveInteger\34Number"=>1,"PositiveInteger\34PrefixPostfixTerm"=>1,"PositiveInteger\34Statement"=>1,"PositiveInteger\34Term"=>1,"PositiveInteger\34Ternary"=>1,"PrefixPostfixTerm\34Assignment"=>1,"PrefixPostfixTerm\34BinaryExpression"=>1,"PrefixPostfixTerm\34CommaList"=>1,"PrefixPostfixTerm\34ConditionalExpression"=>1,"PrefixPostfixTerm\34Document"=>1,"PrefixPostfixTerm\34Expr"=>1,"PrefixPostfixTerm\34Expression"=>1,"PrefixPostfixTerm\34List"=>1,"PrefixPostfixTerm\34ListElem"=>1,"PrefixPostfixTerm\34LowPrecedenceNotExpression"=>1,"PrefixPostfixTerm\34Statement"=>1,"PrefixPostfixTerm\34Ternary"=>1,"QualIdent\34Assignment"=>1,"QualIdent\34Bareword"=>1,"QualIdent\34BinaryExpression"=>1,"QualIdent\34CommaList"=>1,"QualIdent\34ConditionalExpression"=>1,"QualIdent\34Document"=>1,"QualIdent\34Expr"=>1,"QualIdent\34Expression"=>1,"QualIdent\34List"=>1,"QualIdent\34ListElem"=>1,"QualIdent\34Literal"=>1,"QualIdent\34LowPrecedenceNotExpression"=>1,"QualIdent\34OldQualifiedIdentifier"=>1,"QualIdent\34PrefixPostfixTerm"=>1,"QualIdent\34Statement"=>1,"QualIdent\34Term"=>1,"QualIdent\34Ternary"=>1,"QualifiedIdentifier\34Assignment"=>1,"QualifiedIdentifier\34Bareword"=>1,"QualifiedIdentifier\34BinaryExpression"=>1,"QualifiedIdentifier\34CommaList"=>1,"QualifiedIdentifier\34ConditionalExpression"=>1,"QualifiedIdentifier\34Document"=>1,"QualifiedIdentifier\34Expr"=>1,"QualifiedIdentifier\34Expression"=>1,"QualifiedIdentifier\34List"=>1,"QualifiedIdentifier\34ListElem"=>1,"QualifiedIdentifier\34Literal"=>1,"QualifiedIdentifier\34LowPrecedenceNotExpression"=>1,"QualifiedIdentifier\34OldQualifiedIdentifier"=>1,"QualifiedIdentifier\34PrefixPostfixTerm"=>1,"QualifiedIdentifier\34Statement"=>1,"QualifiedIdentifier\34Term"=>1,"QualifiedIdentifier\34Ternary"=>1,"Quotelike\34Assignment"=>1,"Quotelike\34BinaryExpression"=>1,"Quotelike\34CommaList"=>1,"Quotelike\34ConditionalExpression"=>1,"Quotelike\34Document"=>1,"Quotelike\34Expr"=>1,"Quotelike\34Expression"=>1,"Quotelike\34List"=>1,"Quotelike\34ListElem"=>1,"Quotelike\34LowPrecedenceNotExpression"=>1,"Quotelike\34PrefixPostfixTerm"=>1,"Quotelike\34Statement"=>1,"Quotelike\34Term"=>1,"Quotelike\34Ternary"=>1,"QuotelikeM\34Assignment"=>1,"QuotelikeM\34BinaryExpression"=>1,"QuotelikeM\34CommaList"=>1,"QuotelikeM\34ConditionalExpression"=>1,"QuotelikeM\34Document"=>1,"QuotelikeM\34Expr"=>1,"QuotelikeM\34Expression"=>1,"QuotelikeM\34List"=>1,"QuotelikeM\34ListElem"=>1,"QuotelikeM\34LowPrecedenceNotExpression"=>1,"QuotelikeM\34PrefixPostfixTerm"=>1,"QuotelikeM\34Quotelike"=>1,"QuotelikeM\34Regex"=>1,"QuotelikeM\34Regexp"=>1,"QuotelikeM\34Statement"=>1,"QuotelikeM\34Term"=>1,"QuotelikeM\34Ternary"=>1,"QuotelikeQ\34Assignment"=>1,"QuotelikeQ\34BinaryExpression"=>1,"QuotelikeQ\34CommaList"=>1,"QuotelikeQ\34ConditionalExpression"=>1,"QuotelikeQ\34Document"=>1,"QuotelikeQ\34Expr"=>1,"QuotelikeQ\34Expression"=>1,"QuotelikeQ\34List"=>1,"QuotelikeQ\34ListElem"=>1,"QuotelikeQ\34Literal"=>1,"QuotelikeQ\34LowPrecedenceNotExpression"=>1,"QuotelikeQ\34PrefixPostfixTerm"=>1,"QuotelikeQ\34Quotelike"=>1,"QuotelikeQ\34Statement"=>1,"QuotelikeQ\34Str"=>1,"QuotelikeQ\34String"=>1,"QuotelikeQ\34Term"=>1,"QuotelikeQ\34Ternary"=>1,"QuotelikeQQ\34Assignment"=>1,"QuotelikeQQ\34BinaryExpression"=>1,"QuotelikeQQ\34CommaList"=>1,"QuotelikeQQ\34ConditionalExpression"=>1,"QuotelikeQQ\34Document"=>1,"QuotelikeQQ\34Expr"=>1,"QuotelikeQQ\34Expression"=>1,"QuotelikeQQ\34List"=>1,"QuotelikeQQ\34ListElem"=>1,"QuotelikeQQ\34Literal"=>1,"QuotelikeQQ\34LowPrecedenceNotExpression"=>1,"QuotelikeQQ\34PrefixPostfixTerm"=>1,"QuotelikeQQ\34Quotelike"=>1,"QuotelikeQQ\34Statement"=>1,"QuotelikeQQ\34Str"=>1,"QuotelikeQQ\34String"=>1,"QuotelikeQQ\34Term"=>1,"QuotelikeQQ\34Ternary"=>1,"QuotelikeQR\34Assignment"=>1,"QuotelikeQR\34BinaryExpression"=>1,"QuotelikeQR\34CommaList"=>1,"QuotelikeQR\34ConditionalExpression"=>1,"QuotelikeQR\34ContextualRegex"=>1,"QuotelikeQR\34Document"=>1,"QuotelikeQR\34Expr"=>1,"QuotelikeQR\34Expression"=>1,"QuotelikeQR\34List"=>1,"QuotelikeQR\34ListElem"=>1,"QuotelikeQR\34LowPrecedenceNotExpression"=>1,"QuotelikeQR\34PrefixPostfixTerm"=>1,"QuotelikeQR\34Quotelike"=>1,"QuotelikeQR\34Regex"=>1,"QuotelikeQR\34Regexp"=>1,"QuotelikeQR\34Statement"=>1,"QuotelikeQR\34Term"=>1,"QuotelikeQR\34Ternary"=>1,"QuotelikeQW\34Assignment"=>1,"QuotelikeQW\34BinaryExpression"=>1,"QuotelikeQW\34CommaList"=>1,"QuotelikeQW\34ConditionalExpression"=>1,"QuotelikeQW\34Document"=>1,"QuotelikeQW\34Expr"=>1,"QuotelikeQW\34Expression"=>1,"QuotelikeQW\34List"=>1,"QuotelikeQW\34ListElem"=>1,"QuotelikeQW\34LowPrecedenceNotExpression"=>1,"QuotelikeQW\34PrefixPostfixTerm"=>1,"QuotelikeQW\34Quotelike"=>1,"QuotelikeQW\34Statement"=>1,"QuotelikeQW\34Term"=>1,"QuotelikeQW\34Ternary"=>1,"QuotelikeQX\34Assignment"=>1,"QuotelikeQX\34BinaryExpression"=>1,"QuotelikeQX\34CommaList"=>1,"QuotelikeQX\34ConditionalExpression"=>1,"QuotelikeQX\34Document"=>1,"QuotelikeQX\34Expr"=>1,"QuotelikeQX\34Expression"=>1,"QuotelikeQX\34List"=>1,"QuotelikeQX\34ListElem"=>1,"QuotelikeQX\34LowPrecedenceNotExpression"=>1,"QuotelikeQX\34PrefixPostfixTerm"=>1,"QuotelikeQX\34Quotelike"=>1,"QuotelikeQX\34Statement"=>1,"QuotelikeQX\34Term"=>1,"QuotelikeQX\34Ternary"=>1,"QuotelikeS\34Assignment"=>1,"QuotelikeS\34BinaryExpression"=>1,"QuotelikeS\34CommaList"=>1,"QuotelikeS\34ConditionalExpression"=>1,"QuotelikeS\34Document"=>1,"QuotelikeS\34Expr"=>1,"QuotelikeS\34Expression"=>1,"QuotelikeS\34List"=>1,"QuotelikeS\34ListElem"=>1,"QuotelikeS\34LowPrecedenceNotExpression"=>1,"QuotelikeS\34PrefixPostfixTerm"=>1,"QuotelikeS\34Quotelike"=>1,"QuotelikeS\34Statement"=>1,"QuotelikeS\34Term"=>1,"QuotelikeS\34Ternary"=>1,"QuotelikeTR\34Assignment"=>1,"QuotelikeTR\34BinaryExpression"=>1,"QuotelikeTR\34CommaList"=>1,"QuotelikeTR\34ConditionalExpression"=>1,"QuotelikeTR\34Document"=>1,"QuotelikeTR\34Expr"=>1,"QuotelikeTR\34Expression"=>1,"QuotelikeTR\34List"=>1,"QuotelikeTR\34ListElem"=>1,"QuotelikeTR\34LowPrecedenceNotExpression"=>1,"QuotelikeTR\34PrefixPostfixTerm"=>1,"QuotelikeTR\34Quotelike"=>1,"QuotelikeTR\34Statement"=>1,"QuotelikeTR\34Term"=>1,"QuotelikeTR\34Ternary"=>1,"Regex\34Assignment"=>1,"Regex\34BinaryExpression"=>1,"Regex\34CommaList"=>1,"Regex\34ConditionalExpression"=>1,"Regex\34Document"=>1,"Regex\34Expr"=>1,"Regex\34Expression"=>1,"Regex\34List"=>1,"Regex\34ListElem"=>1,"Regex\34LowPrecedenceNotExpression"=>1,"Regex\34PrefixPostfixTerm"=>1,"Regex\34Quotelike"=>1,"Regex\34Statement"=>1,"Regex\34Term"=>1,"Regex\34Ternary"=>1,"Regexp\34Assignment"=>1,"Regexp\34BinaryExpression"=>1,"Regexp\34CommaList"=>1,"Regexp\34ConditionalExpression"=>1,"Regexp\34Document"=>1,"Regexp\34Expr"=>1,"Regexp\34Expression"=>1,"Regexp\34List"=>1,"Regexp\34ListElem"=>1,"Regexp\34LowPrecedenceNotExpression"=>1,"Regexp\34PrefixPostfixTerm"=>1,"Regexp\34Quotelike"=>1,"Regexp\34Statement"=>1,"Regexp\34Term"=>1,"Regexp\34Ternary"=>1,"ReturnStatement\34Assignment"=>1,"ReturnStatement\34BinaryExpression"=>1,"ReturnStatement\34CommaList"=>1,"ReturnStatement\34ConditionalExpression"=>1,"ReturnStatement\34Document"=>1,"ReturnStatement\34Expr"=>1,"ReturnStatement\34Expression"=>1,"ReturnStatement\34List"=>1,"ReturnStatement\34ListElem"=>1,"ReturnStatement\34LowPrecedenceNotExpression"=>1,"ReturnStatement\34PrefixPostfixTerm"=>1,"ReturnStatement\34Statement"=>1,"ReturnStatement\34Term"=>1,"ReturnStatement\34Ternary"=>1,"ScalarAccess\34Assignment"=>1,"ScalarAccess\34BinaryExpression"=>1,"ScalarAccess\34CommaList"=>1,"ScalarAccess\34ConditionalExpression"=>1,"ScalarAccess\34Document"=>1,"ScalarAccess\34Expr"=>1,"ScalarAccess\34Expression"=>1,"ScalarAccess\34List"=>1,"ScalarAccess\34ListElem"=>1,"ScalarAccess\34LowPrecedenceNotExpression"=>1,"ScalarAccess\34PrefixPostfixTerm"=>1,"ScalarAccess\34Statement"=>1,"ScalarAccess\34Term"=>1,"ScalarAccess\34Ternary"=>1,"ScalarAccess\34Var"=>1,"ScalarAccess\34Variable"=>1,"ScalarVar\34Assignment"=>1,"ScalarVar\34BinaryExpression"=>1,"ScalarVar\34CommaList"=>1,"ScalarVar\34ConditionalExpression"=>1,"ScalarVar\34Document"=>1,"ScalarVar\34Expr"=>1,"ScalarVar\34Expression"=>1,"ScalarVar\34List"=>1,"ScalarVar\34ListElem"=>1,"ScalarVar\34LowPrecedenceNotExpression"=>1,"ScalarVar\34PrefixPostfixTerm"=>1,"ScalarVar\34ScalarAccess"=>1,"ScalarVar\34Statement"=>1,"ScalarVar\34Term"=>1,"ScalarVar\34Ternary"=>1,"ScalarVar\34Var"=>1,"ScalarVar\34Variable"=>1,"Statement\34Document"=>1,"Str\34Assignment"=>1,"Str\34BinaryExpression"=>1,"Str\34CommaList"=>1,"Str\34ConditionalExpression"=>1,"Str\34Document"=>1,"Str\34Expr"=>1,"Str\34Expression"=>1,"Str\34List"=>1,"Str\34ListElem"=>1,"Str\34Literal"=>1,"Str\34LowPrecedenceNotExpression"=>1,"Str\34PrefixPostfixTerm"=>1,"Str\34Quotelike"=>1,"Str\34Statement"=>1,"Str\34Term"=>1,"Str\34Ternary"=>1,"String\34Assignment"=>1,"String\34BinaryExpression"=>1,"String\34CommaList"=>1,"String\34ConditionalExpression"=>1,"String\34Document"=>1,"String\34Expr"=>1,"String\34Expression"=>1,"String\34List"=>1,"String\34ListElem"=>1,"String\34Literal"=>1,"String\34LowPrecedenceNotExpression"=>1,"String\34PrefixPostfixTerm"=>1,"String\34Quotelike"=>1,"String\34Statement"=>1,"String\34Term"=>1,"String\34Ternary"=>1,"SubroutineDeclaration\34Document"=>1,"SubroutineDeclaration\34Statement"=>1,"Substitution\34Assignment"=>1,"Substitution\34BinaryExpression"=>1,"Substitution\34CommaList"=>1,"Substitution\34ConditionalExpression"=>1,"Substitution\34Document"=>1,"Substitution\34Expr"=>1,"Substitution\34Expression"=>1,"Substitution\34List"=>1,"Substitution\34ListElem"=>1,"Substitution\34LowPrecedenceNotExpression"=>1,"Substitution\34PrefixPostfixTerm"=>1,"Substitution\34Quotelike"=>1,"Substitution\34Statement"=>1,"Substitution\34Term"=>1,"Substitution\34Ternary"=>1,"Term\34Assignment"=>1,"Term\34BinaryExpression"=>1,"Term\34CommaList"=>1,"Term\34ConditionalExpression"=>1,"Term\34Document"=>1,"Term\34Expr"=>1,"Term\34Expression"=>1,"Term\34List"=>1,"Term\34ListElem"=>1,"Term\34LowPrecedenceNotExpression"=>1,"Term\34PrefixPostfixTerm"=>1,"Term\34Statement"=>1,"Term\34Ternary"=>1,"Ternary\34Assignment"=>1,"Ternary\34CommaList"=>1,"Ternary\34Document"=>1,"Ternary\34Expr"=>1,"Ternary\34Expression"=>1,"Ternary\34List"=>1,"Ternary\34LowPrecedenceNotExpression"=>1,"Ternary\34Statement"=>1,"Transliteration\34Assignment"=>1,"Transliteration\34BinaryExpression"=>1,"Transliteration\34CommaList"=>1,"Transliteration\34ConditionalExpression"=>1,"Transliteration\34Document"=>1,"Transliteration\34Expr"=>1,"Transliteration\34Expression"=>1,"Transliteration\34List"=>1,"Transliteration\34ListElem"=>1,"Transliteration\34LowPrecedenceNotExpression"=>1,"Transliteration\34PrefixPostfixTerm"=>1,"Transliteration\34Quotelike"=>1,"Transliteration\34Statement"=>1,"Transliteration\34Term"=>1,"Transliteration\34Ternary"=>1,"Typeglob\34Assignment"=>1,"Typeglob\34BinaryExpression"=>1,"Typeglob\34CommaList"=>1,"Typeglob\34ConditionalExpression"=>1,"Typeglob\34Document"=>1,"Typeglob\34Expr"=>1,"Typeglob\34Expression"=>1,"Typeglob\34List"=>1,"Typeglob\34ListElem"=>1,"Typeglob\34LowPrecedenceNotExpression"=>1,"Typeglob\34PrefixPostfixTerm"=>1,"Typeglob\34Statement"=>1,"Typeglob\34Term"=>1,"Typeglob\34Ternary"=>1,"UseStatement\34Document"=>1,"UseStatement\34Statement"=>1,"Var\34Assignment"=>1,"Var\34BinaryExpression"=>1,"Var\34CommaList"=>1,"Var\34ConditionalExpression"=>1,"Var\34Document"=>1,"Var\34Expr"=>1,"Var\34Expression"=>1,"Var\34List"=>1,"Var\34ListElem"=>1,"Var\34LowPrecedenceNotExpression"=>1,"Var\34PrefixPostfixTerm"=>1,"Var\34Statement"=>1,"Var\34Term"=>1,"Var\34Ternary"=>1,"VarArray\34ArrayAccess"=>1,"VarArray\34Assignment"=>1,"VarArray\34BinaryExpression"=>1,"VarArray\34CommaList"=>1,"VarArray\34ConditionalExpression"=>1,"VarArray\34Document"=>1,"VarArray\34Expr"=>1,"VarArray\34Expression"=>1,"VarArray\34List"=>1,"VarArray\34ListElem"=>1,"VarArray\34LowPrecedenceNotExpression"=>1,"VarArray\34PrefixPostfixTerm"=>1,"VarArray\34Statement"=>1,"VarArray\34Term"=>1,"VarArray\34Ternary"=>1,"VarArray\34Var"=>1,"VarArray\34Variable"=>1,"VarDecl\34Assignment"=>1,"VarDecl\34BinaryExpression"=>1,"VarDecl\34CommaList"=>1,"VarDecl\34ConditionalExpression"=>1,"VarDecl\34Document"=>1,"VarDecl\34Expr"=>1,"VarDecl\34Expression"=>1,"VarDecl\34List"=>1,"VarDecl\34ListElem"=>1,"VarDecl\34LowPrecedenceNotExpression"=>1,"VarDecl\34PrefixPostfixTerm"=>1,"VarDecl\34Statement"=>1,"VarDecl\34Term"=>1,"VarDecl\34Ternary"=>1,"VarHash\34Assignment"=>1,"VarHash\34BinaryExpression"=>1,"VarHash\34CommaList"=>1,"VarHash\34ConditionalExpression"=>1,"VarHash\34Document"=>1,"VarHash\34Expr"=>1,"VarHash\34Expression"=>1,"VarHash\34HashAccess"=>1,"VarHash\34List"=>1,"VarHash\34ListElem"=>1,"VarHash\34LowPrecedenceNotExpression"=>1,"VarHash\34PrefixPostfixTerm"=>1,"VarHash\34Statement"=>1,"VarHash\34Term"=>1,"VarHash\34Ternary"=>1,"VarHash\34Var"=>1,"VarHash\34Variable"=>1,"Variable\34Assignment"=>1,"Variable\34BinaryExpression"=>1,"Variable\34CommaList"=>1,"Variable\34ConditionalExpression"=>1,"Variable\34Document"=>1,"Variable\34Expr"=>1,"Variable\34Expression"=>1,"Variable\34List"=>1,"Variable\34ListElem"=>1,"Variable\34LowPrecedenceNotExpression"=>1,"Variable\34PrefixPostfixTerm"=>1,"Variable\34Statement"=>1,"Variable\34Term"=>1,"Variable\34Ternary"=>1,"VariableArray\34ArrayAccess"=>1,"VariableArray\34Assignment"=>1,"VariableArray\34BinaryExpression"=>1,"VariableArray\34CommaList"=>1,"VariableArray\34ConditionalExpression"=>1,"VariableArray\34Document"=>1,"VariableArray\34Expr"=>1,"VariableArray\34Expression"=>1,"VariableArray\34List"=>1,"VariableArray\34ListElem"=>1,"VariableArray\34LowPrecedenceNotExpression"=>1,"VariableArray\34PrefixPostfixTerm"=>1,"VariableArray\34Statement"=>1,"VariableArray\34Term"=>1,"VariableArray\34Ternary"=>1,"VariableArray\34Var"=>1,"VariableArray\34Variable"=>1,"VariableDeclaration\34Assignment"=>1,"VariableDeclaration\34BinaryExpression"=>1,"VariableDeclaration\34CommaList"=>1,"VariableDeclaration\34ConditionalExpression"=>1,"VariableDeclaration\34Document"=>1,"VariableDeclaration\34Expr"=>1,"VariableDeclaration\34Expression"=>1,"VariableDeclaration\34List"=>1,"VariableDeclaration\34ListElem"=>1,"VariableDeclaration\34LowPrecedenceNotExpression"=>1,"VariableDeclaration\34PrefixPostfixTerm"=>1,"VariableDeclaration\34Statement"=>1,"VariableDeclaration\34Term"=>1,"VariableDeclaration\34Ternary"=>1,"VariableHash\34Assignment"=>1,"VariableHash\34BinaryExpression"=>1,"VariableHash\34CommaList"=>1,"VariableHash\34ConditionalExpression"=>1,"VariableHash\34Document"=>1,"VariableHash\34Expr"=>1,"VariableHash\34Expression"=>1,"VariableHash\34HashAccess"=>1,"VariableHash\34List"=>1,"VariableHash\34ListElem"=>1,"VariableHash\34LowPrecedenceNotExpression"=>1,"VariableHash\34PrefixPostfixTerm"=>1,"VariableHash\34Statement"=>1,"VariableHash\34Term"=>1,"VariableHash\34Ternary"=>1,"VariableHash\34Var"=>1,"VariableHash\34Variable"=>1,"VariableScalar\34Assignment"=>1,"VariableScalar\34BinaryExpression"=>1,"VariableScalar\34CommaList"=>1,"VariableScalar\34ConditionalExpression"=>1,"VariableScalar\34Document"=>1,"VariableScalar\34Expr"=>1,"VariableScalar\34Expression"=>1,"VariableScalar\34List"=>1,"VariableScalar\34ListElem"=>1,"VariableScalar\34LowPrecedenceNotExpression"=>1,"VariableScalar\34PrefixPostfixTerm"=>1,"VariableScalar\34ScalarAccess"=>1,"VariableScalar\34Statement"=>1,"VariableScalar\34Term"=>1,"VariableScalar\34Ternary"=>1,"VariableScalar\34Var"=>1,"VariableScalar\34Variable"=>1,"VarScalar\34Assignment"=>1,"VarScalar\34BinaryExpression"=>1,"VarScalar\34CommaList"=>1,"VarScalar\34ConditionalExpression"=>1,"VarScalar\34Document"=>1,"VarScalar\34Expr"=>1,"VarScalar\34Expression"=>1,"VarScalar\34List"=>1,"VarScalar\34ListElem"=>1,"VarScalar\34LowPrecedenceNotExpression"=>1,"VarScalar\34PrefixPostfixTerm"=>1,"VarScalar\34ScalarAccess"=>1,"VarScalar\34Statement"=>1,"VarScalar\34Term"=>1,"VarScalar\34Ternary"=>1,"VarScalar\34Var"=>1,"VarScalar\34Variable"=>1,"VersionNumber\34Assignment"=>1,"VersionNumber\34BinaryExpression"=>1,"VersionNumber\34CommaList"=>1,"VersionNumber\34ConditionalExpression"=>1,"VersionNumber\34Document"=>1,"VersionNumber\34Expr"=>1,"VersionNumber\34Expression"=>1,"VersionNumber\34List"=>1,"VersionNumber\34ListElem"=>1,"VersionNumber\34Literal"=>1,"VersionNumber\34LowPrecedenceNotExpression"=>1,"VersionNumber\34Num"=>1,"VersionNumber\34Number"=>1,"VersionNumber\34PrefixPostfixTerm"=>1,"VersionNumber\34Statement"=>1,"VersionNumber\34Term"=>1,"VersionNumber\34Ternary"=>1,"VString\34Assignment"=>1,"VString\34BinaryExpression"=>1,"VString\34CommaList"=>1,"VString\34ConditionalExpression"=>1,"VString\34Document"=>1,"VString\34Expr"=>1,"VString\34Expression"=>1,"VString\34List"=>1,"VString\34ListElem"=>1,"VString\34Literal"=>1,"VString\34LowPrecedenceNotExpression"=>1,"VString\34Num"=>1,"VString\34Number"=>1,"VString\34PrefixPostfixTerm"=>1,"VString\34Statement"=>1,"VString\34Str"=>1,"VString\34String"=>1,"VString\34Term"=>1,"VString\34Ternary"=>1,"VString\34VersionNumber"=>1,"Whitespace\34OWS"=>1,

# End of autogenerated type ISA hierarchy

);

# Convert type aliases into standard PPR types...
sub _resolve_type {
    my ($type, $user_defined_type_for) = @_;

    # Identify valid user-defined types in the current calling scope...
    $user_defined_type_for //= { map { m{ \A Keyword::Declare \s* keytype: (\w+) = (.*) }xms } keys %^H };

    while ($type =~ /\A \w++ \Z/x) {
        $type = $user_defined_type_for->{$type}
             // $ACTUAL_TYPE_OF{$type}
             // croak "Unknown type ($type) for keyword parameter.\nDid you mean: ",
                     join(' or ', grep { lc substr($_,0,1) eq lc substr($type,0,1) } keys %ACTUAL_TYPE_OF);
    }

    if ($type =~ m{\A (?: q\s*\S | ' ) (.*) \S \z }x) {
        return quotemeta $1
    }
    elsif ($type =~ $REGEX_TYPE ) {
        $type =~ $REGEX_PAT or die "Keyword::Declare internal error: weird regex";
        my $pat  = $+{pattern};
        my $mods = $+{modifiers};
        $pat =~ s{(?<!\\)/}{\\/}g;
        return "(?$mods:$pat)";
    }
    elsif ($type =~ $TYPE_JUNCTION) {
        return join '|', map { _resolve_type($_, $user_defined_type_for) } split /[|]/, $type;
    }
    else {
        die 'Keyword::Declare internal error: incomprehensible type: [$type]';
    }

}

# Convert named types and explicit regexes or strings to matcher regex...
sub _convert_type_to_matcher {
    my ($param) = @_;

    my $matcher;

    # Convert type specification to PPR subrule invocations and build a description...
    # ...for named types...
    my $type = $param->{type};
    if ($type =~ m{\A \w++ (?: [|] \w++ )* \Z}x) {
        # Extract component types...
        my @types = split /[|]/, $type;

        # First set up pseudo-inheritance...
        for my $component_type (@types) {
            $isa{$component_type, $type} = 1;
        }

        # Convert component types to regexes...
        $param->{desc} //= do {
            my $desc = $param->{name} ? "<$param->{name}>" : '<'.join(' or ', @types).'>';
            $desc =~ tr/_/ /;
            $desc;
        };
        $type = '/' . join('|', map { _resolve_type( $_ ) } @types) . '/';

    }

    # ...for literal string types...
    if ($type =~ m{\A (?: q\s*\S | ' ) (.*) \S \z }x) {
        $param->{desc}
            //= ($param->{name}
                    ? do{ my $name = "<$param->{name}>"; $name =~ tr/_/ /; $name }
                    : $1
                );
        $matcher = '(?:' . quotemeta($1) . ')';
    }

    # ...for regex types...
    elsif ($type =~ $REGEX_TYPE ) {
        $type =~ $REGEX_PAT or die "Keyword::Declare internal error: weird regex";
        my %match = %+;
        $match{pattern} =~ s{(?<!\\)/}{\\/}g;
        $param->{desc}
            //= ($param->{name}
                    ? do{ my $name = "<$param->{name}>"; $name =~ tr/_/ /; $name }
                    : "/$match{pattern}/$match{modifiers}"
                );
        $matcher = "(?$match{modifiers}:$match{pattern})";
    }

    # Incomprehensible types...
    else {
        die "Keyword::Declare internal error: incomprehensible type: [$type]"
    }

    return $matcher;
}

# This class allows captures from type-regexes to be preserved and accessed...
{
    package Keyword::Declare::Arg;
    use overload
        '""'     => sub { $_[0]{""} },
        fallback => 1
}

# Extract a string or a Keyword::Declare::Arg object from the most recent match...
sub _objectify {
    my ($match_str, $captures_ref) = @_;

    # Trim any leading Perlish whitespace from the match...
    $match_str =~ s{^(?: \s*+ (?: [#].*\n \s*+)*+)}{}x;

    # Just return the match if there were no captures...
    return $match_str if !keys %{$captures_ref};

    my $obj = { q{}=>$match_str, %{$captures_ref} };
    $obj->{':sep'} = delete( $obj->{____KD___sep} ) // q{};
    return bless $obj, 'Keyword::Declare::Arg';
}

# Convert the keyword's parameter list to various useful representations...
sub _unpack_signature {
    my ($keyword_info_ref) = @_;

    # We're setting up all these entries...
    my $sig_vars                          = "";  # List of variables into which keyword args are unpacked
    $keyword_info_ref->{sig_vars_unpack}  = "";  # Statements that unpack keyword args
    $keyword_info_ref->{sig_matcher}      = "";  # Pattern that matches entire arg list
    $keyword_info_ref->{sig_skip_matcher} = "";  # Pattern that matches entire arg list without captures
    $keyword_info_ref->{sig}              = [];  # Array of parameter types
    $keyword_info_ref->{sig_quantified}   = [];  # Array of quantified parameter types
    $keyword_info_ref->{sig_names}        = [];  # Names of each parameter ("" if no unnamed)
    $keyword_info_ref->{sig_defaults}     = {};  # Defaults for any parameter that has them

    # Walk through the parameters...
    my $not_post = 1;
    for my $param (@{$keyword_info_ref->{param_list}}) {
        if (!defined($param)) {
            $not_post = 0;
            next;
        }

        # Generate a regex to match this parameter (note: modifies $param!)...
        my $matcher = _convert_type_to_matcher($param);

        # Generate a regex to match the separator (if any)...
        my $sep;
        if ($param->{sep}) {
            $sep = _convert_type_to_matcher({name=>':sep', type=>$param->{sep}});
        }

        # Resolve implicit quantification (and any default value)...
        if (exists $param->{default}) {
            my $def = $param->{default};
            $def =~ s{\A (?: qq? \s* \S | ["']) (.*) \S \Z }{$1}gx;
            $keyword_info_ref->{sig_defaults}{$param->{name}} = $def;
            $param->{quantifier} //= $param->{sigil} && $param->{sigil} eq '@' ? '*' : '?';
        }
        else {
            $param->{quantifier} //= $param->{sigil} && $param->{sigil} eq '@' ? '+' : '';
        }

        # Matchers handle leading whitespace (unless they ARE whitespace)...
        $matcher = "(?:(?&PerlOWS)$matcher)"
            if $param->{type} !~ m{^/\(\?\&Perl[ON]WS\)/$};

        # Quantified parameters are repeatable...
        my $single_matcher = $matcher;
        if ($param->{quantifier}) {
            # Unseparated parameters are easy...
            if (!$sep) {
                $matcher = "(?:$matcher$param->{quantifier})";
            }
            # Separated parameters are more complex...
            else {
                $matcher = "(?:$matcher(?:(?&PerlOWS)$sep(?&PerlOWS)$matcher)*)";
                $matcher .= '?' if $param->{quantifier} eq '*';
                $single_matcher .= "(?=(?<____KD___sep>$sep))?";
            }
        }


        # Named parameters have to be named captured...
        my $skip_matcher = $matcher;
        if ($param->{name}) {
            $matcher = "(?<$param->{name}>$matcher)";
        }

        # Accumulate the signature matching pattern...
        $keyword_info_ref->{sig_matcher} .= $matcher;
        $keyword_info_ref->{sig_skip_matcher} .= $skip_matcher
            if $not_post;

        # Accumulate signature types and names (if any)...
        push @{ $keyword_info_ref->{sig} },            $param->{type};
        push @{ $keyword_info_ref->{sig_quantified} }, $param->{type}.$param->{quantifier};
        push @{ $keyword_info_ref->{sig_names} },      $param->{name} // q{};

        # Accumulate variable list into which parameters will be unpacked...
        if ($param->{name}) {
            my $match_once = $param->{sigil} ne '$' || $single_matcher =~ /\(\?</
                                ? "m{$single_matcher\$PPR::GRAMMAR}"
                                : "m{}";

            $sig_vars                            .= "$param->{sigil}$param->{name},";
            $keyword_info_ref->{sig_vars_unpack} .= "$param->{sigil}$param->{name} = "
                                                  . ( $param->{sigil} eq '$'
                                                        ? qq{do { my \$arg = shift();
                                                                  \$arg =~ $match_once;
                                                                  Keyword::Declare::_objectify(\$arg,{%+});
                                                                };
                                                            }
                                                        : qq{do { my \@data;
                                                                  my \$arg = shift();
                                                                  while (\$arg =~ /\\S/ && \$arg =~ ${match_once}g) {
                                                                      push \@data,
                                                                           Keyword::Declare::_objectify(\$&,{%+});
                                                                  }
                                                                  \@data;
                                                                };
                                                            }
                                                    )
        }
        else {
            $keyword_info_ref->{sig_vars_unpack} .= 'shift();';
        }
    }

#    use Data::Show; show $keyword_info_ref->{sig_vars_unpack};

    # Build a human readable version of the signature...
    $keyword_info_ref->{sig_desc} = '(' . join(',', @{$keyword_info_ref->{sig_quantified}}) . ')';

    # Build a pretty description for debugging and error messages...
    $keyword_info_ref->{syntax} = "$keyword_info_ref->{keyword}  "
                                . join("  ", map { $_->{desc} } grep {defined} @Keyword::Declare::params);

    # Build a regex that matches the keyword plus its arguments...
    $keyword_info_ref->{matcher} = "$keyword_info_ref->{keyword}$keyword_info_ref->{sig_matcher}";
    $keyword_info_ref->{skip_matcher} = "$keyword_info_ref->{keyword}$keyword_info_ref->{sig_skip_matcher}";

    # Precompute the length of the signature (for multiple-dispatch tie-breaking)...
    $keyword_info_ref->{sig_len} = scalar @{ $keyword_info_ref->{sig} };

    # Consolidate the signature-unpacking code...
    $keyword_info_ref->{sig_vars_unpack} =
        $sig_vars ? "my ($sig_vars); $keyword_info_ref->{sig_vars_unpack}" : q{};
}


# Extract and verify any attrs specified on the keyword...
sub _unpack_attrs {
    my ($keyword_info_ref) = @_;

    # Are there any keyword attrs to unpack???
    if ($keyword_info_ref->{attrs}) {
        # Extract any :prefer or :keepspace attr...
        $keyword_info_ref->{prefer}
            = $keyword_info_ref->{attrs} =~ s{\bprefer\b}{}xms;
        $keyword_info_ref->{keepspace}
            = $keyword_info_ref->{attrs} =~ s{\bkeepspace\b}{}xms;

        # Extract any :desc(...) attr...
        if ($keyword_info_ref->{attrs} =~ s{\bdesc\( (.*?) \)}{}xms) {
            $keyword_info_ref->{desc} = $1;
        }
        else {
            $keyword_info_ref->{desc} = $keyword_info_ref->{keyword};
        }

        # Extract any :prefix(...) attr...
        if ($keyword_info_ref->{attrs} =~ s{\bprefix\( \s* (\$[^\W\d]\w*) \s* \)}{}xms) {
            $keyword_info_ref->{prefix} = $1;
        }

        # Complain about anything else...
        croak ":then attribute specified too late (must come immediately after parameter list)"
            if $keyword_info_ref->{attrs} =~ s{\bthen\b}{}xms;
        croak "Invalid attribute: $keyword_info_ref->{attrs}"
            if $keyword_info_ref->{attrs} =~ /[^\s:]/;
    }
}


# Convert a {{{...}}} interpolated keyword body to a normal body...
sub _convert_triple_block {
    my ($block, $keyword) = @{shift()}{qw< block keyword >};

    # Peel off extra curlies...
    $block = substr($block, 3, -3);

    # Report unclosed «...}> interpolations...
    if ($block =~ m{ <\{ (?<interpolation> (?<leader> \s* \S*) .*? ) (?: <\{ | « | \Z ) }xms) {
        my %match = %+;
        croak qq[Missing }> on interpolation <{$match{leader}...\n]
            . qq[in string-style block of keyword $keyword\ndefined]
                if $match{interpolation} !~ m{ \}> }xms;
    }
    if ($block =~ m{ « (?<interpolation> (?<leader> \s* \S*) .*? ) (?: <\{ | « | \Z ) }xms) {
        my %match = %+;
        croak qq[Missing » on interpolation «$match{leader}...\n]
            . qq[in string-style block of keyword $keyword\ndefined]
                if $match{interpolation} !~ m{ » }xms;
    }

    # Convert the inter polated text to code that does the interpolations...
    $block =~ s{
            « (?<interpolation> .*? ) »
        |
            <\{ (?<interpolation> .*? ) \}>
        |
            (?<literal_code> .+? ) (?= <\{ | « | \z )
    }{
           if (exists $+{literal_code} ) { 'qq{' . quotemeta($+{literal_code}) . '},'; }
        elsif (exists $+{interpolation}) { qq{ do{$+{interpolation}}, };               }
        else { say {*STDERR} 'Keyword::Declare internal error in {{{...}}} block'; exit; }
    }gexms;

    # Build and return the block's new source code...
    return "{ return join '', $block; }";
}


# Transform a keyword invocation into the code generated by the keyword's body...
sub _insert_replacement_code {
    my ($src_ref, $ID, $file, $line, $active_keywords) = @_;

    # Unpack keyword information...
    my $keyword = $keyword_impls[$ID];

    # Remove the arguments from the source code...
    $$src_ref =~ s{ \A ($keyword->{sig_matcher}) $active_keywords $PPR::GRAMMAR }{}xms;
    my %args     = %+;
    for my $argname (keys %args) {
        $args{$argname} = $keyword->{sig_defaults}{$argname} // q{}
            if $args{$argname} eq q{};
    }
    my $arg_list = $1;
    my @args     = @args{ @{$keyword_impls[$ID]{sig_names}} };

    # Tidy them, if requested...
    @args = map {
          !defined($_) ? undef
        : m{\S}        ? do { my $arg = $_;
                              $arg =~ s{\A\s*+(?:\#.*\n\s*+)*+}{};
                              $arg =~ s{\s*+(?:\#.*\n\s*+)*+\z}{};
                              $arg;
                            }
        :                $_
    } @args
        if !$keyword->{keepspace};

    # Adjust the line number so trailing code stays correct...
    $line += $arg_list =~ tr/\n//;

    # Generate replacement code...
    my $replacement_code = $keyword->{generator}->(@args) // q{};

    # If debugging requested, provide a summary of the substitution...
    if (${^H}{"Keyword::Declare debug"}) {
        my $keyword = "    $keyword_impls[$ID]{syntax}";
        my $from    = "    $keyword_impls[$ID]{keyword} $arg_list";
        my $to      = $replacement_code;
           $to =~ s{\A\s*\n|\n\s*\Z}{}gm;
           $to =~ s{\h+}{ }g;
           $to =~ s{^}{    }gm;

        my $msg
            =   ("#" x 50) . "\n"
              . " Keyword macro defined at $keyword_impls[$ID]{location}:\n\n$keyword\n\n"
              . " Converted code at $file line $line:"                . "\n\n$from\n\n"
              . " Into:"                                              . "\n\n$to\n\n"
              . ("#" x 50) . "\n";
        $msg =~ s{^}{###}gm;
        warn $msg;
    }

    # Track possible cycles...
    $$src_ref =~ s{^(\#KDCT:_:_:)(\d+)([^\n]*)}
                  { my ($comment, $count, $trace) = ($1, $2, $3);
                    croak "Likely keyword substitution cycle:\n    $trace\nCompilation abandoned",
                        if $count > $NESTING_THRESHOLD && $trace =~ m{(\w++) --> .+ --> \1};
                    $comment.($count+1).$trace." --> $keyword->{keyword}";
                  }gexms;

    # Install the replacement code...
    $$src_ref = "$replacement_code\n#KDCT:_:_:1 $keyword->{keyword}\n#line $line $file\n" . $$src_ref;

    # Pre-empt addition of extraneous trailing newline by Keyword::Simple...
    # [REMOVE WHEN UPSTREAM MODULE (Keyword::Simple) IS FIXED]
    $$src_ref =~ s{\n\z}{};
}

# Compare two types...
sub _is_narrower {
    my ($type_a, $type_b) = @_;

    # Short-circuit on identity...
    return 0  if $type_a eq $type_b;

    # Otherwise, work out the metatypes of the types...
    my $kind_a = $type_a =~ /\A'|\Aq\W/ ? 'literal'  :  $type_a =~ m{\A/|\Am\W}xms ? 'pattern'  :  'typename';
    my $kind_b = $type_b =~ /\A'|\Aq\W/ ? 'literal'  :  $type_b =~ m{\A/|\Am\W}xms ? 'pattern'  :  'typename';

    # If both are named types, try the standard inheritance hierarchy rules...
    if ($kind_a eq 'typename' && $kind_b eq 'typename') {
        return +1 if $isa{$type_a,$type_b};
        return -1 if $isa{$type_b,$type_a};
    }

    # Otherwise, the metatype names "just happen" to be in narrowness order ;-)...
    return $kind_a cmp $kind_b;
}

# Compare two type signatures (of equal length)...
sub _cmp_signatures {
    my ($sig_a, $sig_b) = @_;

    # Track relative ordering parameter-by-parameter...
    my $partial_ordering = 0;
    for my $n (0 .. $#$sig_a) {
        # Find the ordering of the next pair from the two lists...
        my $is_narrower = _is_narrower($sig_a->[$n], $sig_b->[$n]);

        # If this pair's ordering contradicts the ordering so far, there is no ordering...
        return 0 if $is_narrower && $is_narrower == -$partial_ordering;

        # Otherwise if there's an ordering, it becomes the "ordering so far"...
        $partial_ordering ||= $is_narrower;
    }

    # If we make it through the entire list, return the resulting ordering...
    return $partial_ordering;
}

# Resolve ambiguous argument lists using Perl6-ish multiple dispatch rules...
sub _resolve_matches {
    my @IDs = @_;

    # Extend type hierarchy...
    my @keytype_isa = map { my ($derived, $base) = m{ \A Keyword::Declare \s+ keytype:(\w+)=(\w+) \z}xms;
                            if ($derived) {
                                my @ancestors = map  { my $anc = $_;
                                                       $anc =~ s{ \A $base $; }
                                                                {$derived$;}xms;
                                                       $anc => 1
                                                     }
                                                grep { m{ \A $base $; }xms }
                                                keys %isa;
                                $derived.$;.$base => 1, @ancestors;
                            }
                            else {
                                ();
                            }
                          } keys %^H;
    local %isa = ( %isa, @keytype_isa );

    # Track narrownesses...
    my %narrower = map { $_ => [] } 0..$#IDs;

    # Compare all signatures, recording definitive differences in narrowness...
    for my $index_1 (0 .. $#IDs) {
        for my $index_2 ($index_1+1 .. $#IDs) {
            my $narrowness = _cmp_signatures($keyword_impls[$IDs[$index_1]]{sig},
                                             $keyword_impls[$IDs[$index_2]]{sig});

            if    ($narrowness > 0) { push @{$narrower{$index_1}}, $index_2; }
            elsif ($narrowness < 0) { push @{$narrower{$index_2}}, $index_1; }
        }
    }

    # Was there a signature narrower than all the others???
    my $max_narrower = max map { scalar @{$_} } values %narrower;
    my $unique_narrowest = $max_narrower == $#IDs;

    # If not, return the entire set...
    return @IDs if !$unique_narrowest;

    # Otherwise, return the narrowest...
    return @IDs[ grep { @{$narrower{$_}} >= $max_narrower } keys %narrower ];
}

1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Keyword::Declare - Declare new Perl keywords...via a keyword...named C<keyword>


=head1 VERSION

This document describes Keyword::Declare version 0.001017


=head1 STATUS

This module is an alpha release.
Aspects of its behaviour may still change in future releases.
They have already done so in past releases.


=head1 SYNOPSIS

    use Keyword::Declare;

    # Declare something matchable within a keyword's syntax...
    keytype UntilOrWhile is /until|while/;

    # Declare a keyword and its syntax...
    keyword repeat (UntilOrWhile $type, List $condition, Block $code) {
        # Return new source code as a string (which replaces any parsed syntax)
        return qq{
            while (1) {
                $code;
                redo $type $condition;
                last;
            }
        };
    }

    # Implement method declarator...
    keyword method (Ident $name, List $params?, /:\w+/ @attrs?, Block $body) {
        return build_method_source_code($name, $params//'()', \@attrs, $body);
    }

    # Keywords can have two or more definitions (distinguished by syntax)...
    keyword test (String $desc, Comma, Expr $test) {
        return "use Test::More; ok $test => $desc"
    }

    keyword test (Expr $test) {
        my $desc = "q{$test at line }.__LINE__";
        return "use Test::More; ok $test => $desc"
    }

    keyword test (String $desc, Block $subtests) {
        return "use Test::More; subtest $desc => sub $subtests;"
    }

    # Keywords can be removed from the remainder of the lexical scope...
    unkeyword test;

    # Keywords declared in an import() or unimport() are automatically exported...
    sub import {

        keyword debug (Expr $expr) {
            return "" if !$ENV{DEBUG};
            return "use Data::Dump 'ddx'; ddx $expr";
        }

    }

    # Keywords removals in an unimport() or import() are also automatically exported...
    sub unimport {

        unkeyword debug;

    }



=head1 DESCRIPTION

This module implements a new Perl keyword: C<keyword>, which you can
use to specify other new keywords.

Normally, to define new keywords in Perl, you either have to write them
in XS (shiver!) or use a module like L<Keyword::Simple> or
L<Keyword::API>. Using any of these approaches requires you to grab all
the source code after the keyword, manually parse out the components of
the keyword's syntax, construct the replacement source code, and then
substitute it for the original source code you just parsed.

Using Keyword::Declare, you define a new keyword by specifying its name
and a parameter list corresponding to the syntactic components that must
follow the keyword. You then use those parameters to construct and
return the replacement source code. The module takes care of setting up
the keyword, and of the associated syntax parsing, and of inserting the
replacement source code in the correct place.

For example, to create a new keyword (say: C<loop>) that takes an optional
count and a block, you could write:

    use Keyword::Declare;

    keyword loop (Int $count?, Block $block) {
        if (length $count) {
            return "for (1..$count) $block";
        }
        else {
            return "while (1) $block";
        }
    }

At compile time, when the parser subsequently encounters source
code such as:

    loop 10 {
        $cmd = readline;
        last if valid_cmd($cmd);
    }

then the keyword's $count parameter would be assigned the value C<"10">
and its $code parameter would be assigned the value
S<C<"{\n$cmd = readline;\nlast if valid_cmd($cmd);\n}">>. Then the "body" of
the keyword definition would be executed and its return value would be used as the
replacement source code:

    for (1..10) {
        $cmd = readline;
        last if valid_cmd($cmd);
    }



=head1 INTERFACE

=head2 Declaring a new lexical keyword

The general syntax for declaring new keywords is:

    keyword NAME (PARAM, PARAM, PARAM...) ATTRS { REPLACEMENT }

The name of the new keyword can be any identifier, including the name of
an existing Perl keyword. However, using the name of an existing keyword
usually creates an infinite loop of keyword expansion, so it rarely does
what you actually wanted. In particular, the module will not allow you
to declare a new keyword named C<keyword>, as that way lies madness.

=head2 Specifying keyword parameters

The parameters of the keyword tell it how to parse the source code that
follows it. The general syntax for each parameter is:

                         TYPE  [?*+][?+]  [$@]NAME  :sep(TYPE)  = 'DEFAULT'

                         \__/  \_______/  \______/  \________/  \_________/
    Parameter type.........:       :          :          :           :
    Repetition specifier...........:          :          :           :
    Parameter variable........................:          :           :
    Separator specifier..................................:           :
    Default source code (if argument is missing).....................:

The type specifier is required, but the other four components
are optional. Each component is described in the following sections.


=head3 Keyword parameter types

The type of each keyword parameter specifies how to parse the
corresponding item in the source code after the keyword.

The type of each keyword parameter may be specified as either a type
name, a regex, or a literal string...

=head4 Named types

A named type is simply a convenient label for some standard or
user-defined regex or string. Most of the available named types are
drawn from the PPR module, and are named with just the post-"Perl..."
component of the PPR name.

For example, the C<Expression> type is the same as the PPR named
subpattern C<(?&PerlExpression>) and the C<Variable> type is identical
to the PPR named subpattern C<(?&PerlVariable)>.

The standard named types that are available are:


=for comment Autogenerated type descriptions (from bin/gen_types.pl)...

    ArrayIndexer .................................. An expression or list in square brackets
    AssignmentOperator ............................ A '=' or any operator assignment: '+=', '*=', etc.
    Attributes .................................... Subroutine or variable :attr(ributes) :with : colons
    Comma ......................................... A ',' or '=>'
    Document ...................................... Perl code and optional __END__ block
    HashIndexer ................................... An expression or list in curly brackets
    InfixBinaryOperator ........................... An infix operator of precedence from '**' down to '..'
    LowPrecedenceInfixOperator .................... An 'and', 'or', or 'xor
    OWS ........................................... Optional whitespace (including comments or POD)
    PostfixUnaryOperator .......................... A high-precedence postfix operator like '++' or '--'
    PrefixUnaryOperator ........................... A high-precedence prefix operator like '+' or '--'
    StatementModifier ............................. A postfix 'if', 'while', 'for', etc.
    NWS or Whitespace ............................. Non-optional whitespace (including comments or POD)
    Statement ..................................... Any single valid Perl statement
    Block ......................................... A curly bracket delimited block of statements
    Comment ....................................... A #-to-newline comment
    ControlBlock .................................. An if, while, for, unless, or until and its block
    Expression or Expr ............................ An expression involving operators of any precedence
    Format ........................................ A format declaration
    Keyword ....................................... Any user-defined keyword and its arguments
    Label ......................................... A statement label
    PackageDeclaration ............................ A package declaration or definition
    Pod ........................................... Documentation terminated by a =cut
    SubroutineDeclaration ......................... A named subroutine declaration or definition
    UseStatement .................................. A use <module> or use <version> statement
    LowPrecedenceNotExpression .................... An expression at the precedence of not
    List .......................................... An list of comma-separated expressions
    CommaList ..................................... An unparenthesized list of comma-separated expressions
    Assignment .................................... One or more chained assignments
    ConditionalExpression or Ternary or ListElem... An expression involving the ?: operator;
                                                    also matches a single element of a comma-separated list
    BinaryExpression .............................. An expression involving infix operators
    PrefixPostfixTerm ............................. A term with optional unary operator(s)
    Term .......................................... An expression not involving operators
    AnonymousArray or AnonArray ................... An anonymous array constructor
    AnonymousHash or AnonHash ..................... An anonymous hash constructor
    AnonymousSubroutine ........................... An unnamed subroutine definition
    Call .......................................... A call to a built-in function or user-defined subroutine
    DiamondOperator ............................... A <readline> or <shell glob>
    DoBlock ....................................... A do block
    EvalBlock ..................................... An eval block
    Literal ....................................... Any literal compile-time value
    Lvalue ........................................ Anything that can be assigned to
    ParenthesesList or ParensList ................. A parenthesized list of zero-or-more elements
    Quotelike ..................................... Any quotelike term
    ReturnStatement ............................... A return statement in a subroutine
    Typeglob ...................................... A typeglob lookup
    VariableDeclaration or VarDecl ................ A my, our, or state declaration
    Variable or Var ............................... A variable of any species
    ArrayAccess ................................... An array lookup or a slice
    Bareword ...................................... A bareword
    BuiltinFunction ............................... A call to a builtin-in function
    HashAccess .................................... A hash lookup or key/value slice
    Number or Num ................................. Any number
    QuotelikeQW ................................... A qw/.../
    QuotelikeQX ................................... A `...` or qx/.../
    Regex or Regexp ............................... A /.../, m/.../, or qr/.../
    ScalarAccess .................................. A scalar variable or lookup
    String or Str ................................. Any single- or double-quoted string
    Substitution or QuotelikeS .................... An s/.../.../
    Transliteration or QuotelikeTR ................ A tr/.../.../
    ContextualRegex ............................... A /.../, m/.../, or qr/.../ where it's valid in Perl
    Heredoc ....................................... A heredoc marker (but not the contents)
    Integer or Int ................................ An integer
    Match or QuotelikeM ........................... A /.../ or m/.../
    NullaryBuiltinFunction ........................ A call to a built-in function that takes no arguments
    OldQualifiedIdentifier ........................ An identifier optionally qualified with :: or '
    QuotelikeQ .................................... A single-quoted string
    QuotelikeQQ ................................... A double-quoted string
    QuotelikeQR ................................... A qr/.../
    VString ....................................... A v-string
    VariableArray or VarArray or ArrayVar ......... An array variable
    VariableHash or VarHash or HashVar ............ A hash variable
    VariableScalar or VarScalar or ScalarVar ...... A scalar variable
    VersionNumber ................................. A version number allowed after use
    ContextualMatch or ContextualQuotelikeM ....... A /.../ or m/.../ where it's valid in Perl
    PositiveInteger or PosInt ..................... A non-negative integer
    QualifiedIdentifier or QualIdent .............. An identifier optionally qualified with ::
    QuotelikeQR ................................... A qr/.../
    VString ....................................... A v-string
    Identifier or Ident ........................... An unqualified identifier

=for comment End of autogenerated type descriptions


Which Perl construct each of these will match after a keyword is
intended to be self-evident; see the documentation of the PPR module
for more detail on any of them that aren't.



=head4 Regex and literal parameter types

In addition to the standard named types listed in the previous section,
a keyword parameter can have its type specified as either a regex or a
string, in which case the corresponding component in the trailing source
code is expected to match that pattern or literal.

For example:

    keyword fail ('all'? $all, /hard|soft/ $fail_mode, Block $code) {...}

would accept:

    fail hard {...}
    fail all soft {...}
    # etc.

If a literal or pattern is only parsing a static part of the syntax, there
may not be a need to give it an actual parameter variable. For example:

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {

        my $EXTRACTOR = $what eq 'values' ? 'values' : 'keys';
        my $REPORTER  = $what eq 'pairs' ? $hash.'{$data}' : '$data';

        return qq{for my \$data ($EXTRACTOR $hash) { say join ': ',$REPORTER }
    }

Here the C<'in'> parameter type just parses a fixed syntactic component of the
keyword, so there's no need to capture it into a parameter variable.

Note that types specified as regexes can be given any of the following
trailing modifiers: C</imnsxadlup>. For example:

    keyword list (/ keys | values | pairs /xiaa $what, 'in', HashVar $hash) {...}
                                           ^^^^


=head3 Naming literal and regex types via C<keytype>

Literal and regex parameter types are useful for matching non-standard
syntax that PPR cannot recognize. However, using a regex or a literal
as a type specifier does tend to muddy a keyword definition with large
amounts of line noise (especially the regexes).

So the module allows you to declare a named type that matches whatever
a given literal or regex would have matched in the same place...via the
C<keytype> keyword.

For example, instead of explicit regexes and string literals:

    keyword fail ('all'? $all, /hard|soft/ $fail_mode, Block $code) {...}

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {

...you could predeclare named types that work the same:

    keytype All       is  'all'       ;
    keytype FailMode  is  /hard|soft/ ;

    keytype ListMode  is  /keys|values|pairs/ ;
    keytype In        is  'In'                ;

and then declare the keywords like so:

    keyword fail (All? $all, FailMode $fail_mode, Block $code) {...}

    keyword list (ListMode $what, In, HashVar $hash) {

A C<keytype> can also be used to rename an existing named type
(including other C<keytype>'d names) more meaningfully.
For example:

    keytype Name      is  Ident  ;
    keytype ParamList is  List   ;
    keytype Attr      is  /:\w+/ ;
    keytype Body      is  Block  ;

    keyword method (Name $name, ParamList? $params, Attr? @attrs, Body $body)
    {...}

When you define a new compile-time keytype from a string or regex,
you can also request the module to create a variable of the same name
with the same content, by prefixing the keytype name with a C<$>
sigil. For example:

    keytype $ListMode  is  /keys|values|pairs/ ;
    keytype $In        is  'In'                ;

would create two new keytypes (C<ListMode> and C<In>) and also
two new variables (C<$ListMode> and C<$In>) that contain the
regex adnd string respectively. Note that you would still use
the I<sigilless> forms in the parameter list of a keyword:

    keyword list (ListMode $what, In, HashVar $hash) {
        ...
    }

but could then use the sigilled forms in the body of the keyword:

    keyword list (ListMode $what, In, HashVar $hash) {
        if ($hash =~ $Listmode || $hash eq $In) {
            warn 'Bad name for hash';
        }
        ...
    }

or anywhere else in the same lexical scope as the C<keytype> declaration.


=head3 Junctive named types

Sometimes a keyword may need to take two or more different types of arguments
in the same syntactic slot. For example, you might wish to create a keyword
that accepts either a block or an expression as its argument:

    try { for (1..10) { say foo() } }

    try say foo();

...or a block or regex:

    filter { $_ < 10 } @list;
    filter /important/ @list;

When specifying the a keyword parameter, you can specify two or more
named types for it, by conjoining them with a vertical bar (C<|>) like so:

    keyword try (Block|Expression $trial) {{{
        eval «$trial =~ /^\{/ ? $trial : "{$trial}"»
    }}}

    keyword filter (Regex|Block $selector, ArrayVar $var) {{{
        «$var» = grep «$selector» «$var»;
    }}}

This is known as a I<disjunctive type>.

Disjunctive types can only be constructed from named types (either built-in
or defined by a C<keytype>); they cannot include regex or literal types.
However, this is not an onerous restriction, as it is always possible to
convert a non-named type to a named type using C<keytype>:

    keytype In   is /(?:with)?in/;
    keytype From is 'from';

    keyword list (Regex $rx, From|In, Expression $list) {{{
        say for grep «$rx» «$list»;
    }}}

    list /fluffy/ within cats();
    list /rex/ from dogs();


=head2 Capturing parameter components

Normally, when a keyword parameter matches part of the source code,
the text of that source code fragment becomes the string value of
the corresponding parameter variable. For example:

    keytype Mode     is / first | last | any | all /x;
    keytype NumBlock is / \d+ (?&PerlOWS) (?&PerlBlock) /;

    keyword choose (Mode $choosemode, NumBlock @numblocks) {...}

    # And later...

    choose any
        1 {x==1}
        2 {sqrt 4}
        3 {"Many"}

    # Parameter $choosemode gets: 'any'
    # Parameter @numblocks  gets: ( '1 {x==1}', '2 {sqrt 4}', '3 {"Many"}' )

However, if a parameter's type regex includes one or more named captures
(i.e. via the C<< (?<name> ... ) >> syntax), then the corresponding
parameter variable is no longer bound to a simple string.

Instead, it is bound to a hash-based object of the class
C<Keyword::Declare::Arg>.

This object still stringifies to the original source code fragment,
so the parameter can still be interpolated into a replacement source
code string.

However, the object can also be treated as a hash...whose keys are the
names of the named captures in the type regex, and whose values are the
substrings those named captures matched.

In addition, the C<Keyword::Declare::Arg> object always has an extra key
(namely: the empty string), whose value stores the entire original source
code fragment.

So, for example, if the two parameter types from the previous example,
had included named captures:

    keytype Mode     is / (?<one> first | last | any ) | (?<many> all ) /x;

    keytype NumBlock is / (?<num> \d+ ) (?&PerlOWS) (?<block> (?&PerlBlock) ) /;

    keyword choose (Mode $choosemode, NumBlock @numblocks) {...}

    # And later...

    choose any
        1 {x==1}
        2 {sqrt 4}
        3 {"Many"}

    # $choosemode stringifies to:     'any'
    # $choosemode->{''}     returns:  'any'
    # $choosemode->{'one'}  returns:  'any'
    # $choosemode->{'many'} returns:  undef

    # $numblocks[0] stringifies to:    '1 {x==1}'
    # $numblocks[0]{''}      returns:  '1 {x==1}'
    # $numblocks[0]{'num'}   returns:  '1'
    # $numblocks[0]{'block'} returns:  '{x==1}'

    # et cetera...

This feature is most often used to define keywords whose arguments
consist of a repeated sequence of components, especially when those
components are either inherently complex (as in the previous example)
or they are unavoidably heterogeneous in nature (as below).

For example, to declare an C<assert> keyword that can take and test
a series of blocks and/or expressions:

    keytype BlockOrExpr is / (?<block> (?&PerlBlock) )
                           | (?<expr>  (?&PerlExpression)  )
                           /x;

    keyword assert (BlockOrExpr @test_sequence) {

        # Accumulate transformed tests in this variable
        my @assertions;

        # Build assertion code from sequence of test components
        for my $test (@test_sequence) {

            # Is the next component a block?
            push @assertions, "do $test" if $test->{block};

            # Is the next component a raw expression?
            push @assertions, "($test)"  if $test->{expr};
        }

        # Generate replacement code...
        return "die 'Assertion failed' unless "
             . join ' && ', @assertions;
    }


=head2 Scalar vs array keyword parameters

Declaring a keyword's parameter as a scalar (the usual approach) causes
the source code parser to match the corresponding type of component
exactly once in the trailing source. For example:

    # try takes exactly one trailing block
    keyword try (Block $block) {...}

Declaring a keyword's parameter as an array causes the source code
parser to match the corresponding type of component as many times as it
appears (but at least once) in the trailing source, with each matching
occurrence becoming one element of the array.

    # tryall takes one or more trailing blocks
    keyword tryall (Block @blocks) {...}


=head3 Changing the number of expected parameter matches

An explicit quantifier can be appended to any parameter type to change the
number of repetitions that parameter type will match.
For example:

    # The forpair keyword takes an optional iterator variable
    keyword forpair ( Var? $itervar, '(', HashVar $hash, ')', Block $block) {...}

    # The checkpoint keyword can be followed by zero or more trailing strings
    keyword checkpoint (Str* @identifier) {...}

The available quantifiers are:

=over

=item C<?>

to indicate zero-or-one times, as many times as possible, with backtracking

=item C<*>

to indicate zero-or-more times, as many times as possible, with backtracking

=item C<+>

to explicitly indicate one-or-more times, as many times as possible, with backtracking
(This is also the default quantifier if the parameter variable is declared as an array.)

=item C<??>

to indicate zero-or-one times, as I<few> times as possible, with backtracking

=item C<*?>

to indicate zero-or-more times, as I<few> times as possible, with backtracking

=item C<+?>

to indicate one-or-more times, as I<few> times as possible, with backtracking

=item C<?+>

to indicate zero-or-one times, as many times as possible, I<without> backtracking

=item C<*+>

to indicate zero-or-more times, as many times as possible, I<without> backtracking

=item C<++>

to indicate one-or-more times, as many times as possible, I<without> backtracking

=back

For example:

    # The watch keyword takes as many statements as possible, and at least one...
    keyword watch ( Statement++ @statements) {
        return join "\n", map { "say q{$_}; $_;" } @statements;
    }

    # The begin...end keyword takes as few statements as possible, including none...
    keyword begin ( Statement*? $statements, 'end') {
        return "{ $statements }";
    }

Note that any repetition quantifier is appended to the parameter's type, B<not> after
its variable. As the previous example indicates, any quantifier may be applied to
either a scalar or an array parameter: the quantifier tells the type how often to
match; the kind of parameter determines how that match is made available inside
the keyword body: as a single string or object for scalar parameters, or as a list of
individual strings or objects for array parameters.

=head4 Checking whether optional parameters are present

If an array parameter has a quantifier that makes it I<optional>
(e.g. C<?>, C<*>, C<?+>, C<*?>, etc.), then the parameter array
will be empty (and hence false) whenever the corresponding
syntactic component is missing.

In the same situation, an optional scalar parameter will contain
an empty string (which is also false, of course).

However, it is recommended that the presence or absence of optional
scalar parameters should be tested using the built-in C<length()>
function, not just via a boolean test, because in some cases the
parameter could also have an explicit value of C<"0">, which is false,
but not "missing".

For example:

    keyword save (Int? $count, List $data) {

        # If optional count omitted, then $count will contain an empty string
        if ( !length($count) ) {
            return "save_all($data);";
        }
        else {
            return "save_first($count, $data);";
        }
    }

If the test had been:

        if (!$count) {
            return "save_all($data);";
        }

then a keyword invocation such as:

    save 0 ($foo, $bar, $baz);

would be translated to a call to C<save_all(...)>,
instead of a call to C<save_multiple(0,...)>.


=head3 Separated repetitions

Parameters can be marked as repeating either by being declared as arrays
or by being declared with a type quantifier such as C<*>, C<+>, etc.)
Any repeating parameter may match multiple repetitions of the same
component. For example:

    # tryall takes zero or more trailing blocks
    keyword tryall (Block* @blocks) {...}

...will match zero-or-more code blocks after the keyword.

You can also specify that such parameters should match repeated
components that are explicitly B<separated> by some other interstitial
syntactic element: such as a comma or a colon or a newline or a special
string like '+' or '&&' or 'then'.

Such separators are specified by adding a C<:sep(...)> attribute after
the variable name (but before any default value).

For example, if the C<tryall> blocks should be separated by
commas, you could specify that like so:

    # tryall takes zero or more trailing comma-separated blocks
    keyword tryall (Block* @blocks :sep(',')) {...}
                                 # ^^^^^^^^^

Separators can be specified using any valid parameter type:
string, regex, named type, or junctive. For example:

    # tryall takes zero or more trailing (fat-)comma-separated blocks
    keyword tryall (Block* @blocks :sep( /,|=>/ )) {...}
                                 #       ^^^^^^

    # tryall takes zero or more trailing Comma-separated blocks
    keyword tryall (Block* @blocks :sep( Comma )) {...}
                                 #       ^^^^^

    # tryall takes zero or more trailing Comma-or-colon-separated blocks
    keytype Colon is ':';
    keyword tryall (Block* @blocks :sep( Comma|Colon )) {...}
                                 #       ^^^^^^^^^^^


=head4 Accessing separators

Whenever an array parameter is specified with a C<:sep> attribute, the
actual separators found between instances of a repeated component can be
retrieved via the Keyword::Declare::Arg objects that are returned in the
array.

Each such object stores the separator that occurred immediately I<after>
the corresponding component, and each such trailing separator can be
accessed via the object's special C<':sep'> key. For example:

    # tryall takes zero or more trailing Comma-separated blocks
    keyword tryall (Block* @blocks :sep(Comma)) {
        warn "Separators are: ",
             map { $_->{':sep'} } @blocks;
        ...
    }

    # and later...

    tryall {say 1} , {say 2} => {say 3} , {say 4};
    # Warns: Separators are: ,=>,


=head3 Providing a default for optional parameters

If a parameter is optional (i.e. it has a <?>, C<??>, C<?+>, <*>, <*?>,
or C<*+> quantifier), you can specify a string to be placed in the
parameter variable in cases where the parameter matches zero times.

For example to use C<$_> as the iterator variable, if no explicit variable
is supplied:

    # The forpair keyword takes an optional iterator variable (or defaults to $_)
    keyword forpair ( Var? $itervar = '$_', '(', HashVar $hash, ')', Block $block) {...}

Another common use for defaults is to force optional arguments to default to an
empty string, rather than to C<undef>, so it's easier to interpolate:

    keyword display ( Str? $label = '', ScalarVar $var) {{{
        say '«$label»«$var»=', «$var»
    }}}


Note that the default value represents an alternative piece of source
code to be generated at compile-time, so it must be specified as an
uninterpolated single-quoted string (either C<'...'> or C<q{...}>).

Array parameters can also have a default value specified. However, as
for scalar parameters, the default must still be a single single-quoted
string (not a list or array). For example:

    # The checkpoint keyword defaults to check-pointing CHECKPOINT...
    keyword checkpoint (Str* @identifier = 'CHECKPOINT') {...}

If you provide a default for an unquantified parameter, the module will infer
that you intended the parameter to be optional and will quietly provide a
suitable implicit quantifier (C<?> for scalars, C<*> for arrays). So the
previous examples could also have been written:

    # The forpair keyword takes an optional iterator variable (or defaults to $_)
    keyword forpair ( Var $itervar = '$_', '(', HashVar $hash, ')', Block $block) {...}

    # The checkpoint keyword defaults to check-pointing CHECKPOINT...
    keyword checkpoint (Str @identifier = 'CHECKPOINT') {...}


=head2 Handling whitespace between arguments

Normally, a keyword parses and discards any Perl whitespaces (spaces,
tabs, newlines, comments, POD, etc.) between its arguments. Each
parameter receives the appropriate matching code component with its
leading whitespace removed (unless, of course, that component itself
explicitly matches whitespace, in which case it's preserved).

Occasionally, however, leading whitespace may be significant.
For example, you may wish to implement a C<note> keyword that
differentiates between:

    note (1..3)  --> $filename;

and:

    note( 1..3 ) --> $filename;

You could achieve that by explicitly matching the optional whitespace before the
opening paranthesis:

    keyword note (OWS $ws, ParenList $list, /-->[^;]*/ $comment) {
        return 'say '
             . (length($ws) ? "'(', $list, ')'" : $list);
    }

However, this approach can quickly get tedious and unwieldy when
multiple parameters all need to preserve leading whitespace:

    keyword note (OWS $ws1, ParenList $list, OWS $ws2, /-->[^;]*/ $comment)
    {
        return 'say '
             . (length($ws1) ? "'(', $list, ')'" : $list)
             . ("'$ws2$comment'");
    }

So the module provides an attribute, C<:keepspace>, that causes a keyword to
simply keep any leading whitespace at the start of each parameter:

    keyword note (ParenList $list, /-->[^;]*/ $comment) :keepspace {...}
    {
        return 'say '
             . ($list !~ /^\(/  ? "'(', $list, ')'" : $list)
             . $comment;
    }

When using the :keepspace attribute, be aware that the leading whitespace
preserved at the start of each attribute is Perl's concept of whitespace
(which includes comments, POD, and possibly even heredoc contents), so if
your keyword later needs to strip it out, then:

    $list =~ s{ ^ \s* }{}x;

will not suffice. At a minimum, you'll need to cater for comments as
well:

    $list =~ s{ ^ \s*+ (?: [#].*+\n \s*+)*+ }{}x

and, to be really safe, you need to handle every other Perlish
"whitespace" as well:

    $list =~ s{ ^ (?PerlOWS) $PPR::GRAMMAR }{}x;


=head2 Keywords with trailing context

Sometimes a keyword implementation needs to modify more of the source
code than just its own arguments. For example, a C<let> keyword might
need to install some code after the end of the surrounding block:

    keyword let (Var $var, '=', Expr $value, Statement* $trailing_code, '}')
    {{{
            «trailing_code»
        }
        «$var» = «$value»;
    }}}

But you can't create a keyword like that, because it can't be
successfully parsed as part of a larger Perl code block...because it
"eats" the right-curly that surrounding block needs to close itself.

What's needed here is a way to have a keyword operate on trailing
code, but then not consider that trailing code to be part of its
"official" argument list, so that subsequent parsing doesn't
prematurely consume it.

The module supports this via the C<:then> attribute. You could, for example,
successfully implement the C<let> keyword like so:

    keyword let (Var $var, '=', Expr $value) :then(Statement* $trailing_code, '}')
    {{{
            «trailing_code»
        }
        «$var» = «$value»;
    }}}

The parentheses of the C<:then> act like a second parameter list, which
must match when the keyword is encountered and expanded within the
source, but which is treated like mere "lookahead" when the keyword is
parsed as part of the processing of other keywords.

The C<:then> attribute must come immediately after the keyword's normal
parameter list (i.e. before any other attribute the keyword might have),
and uses exactly the name parameter specification syntax as the normal
parameter list.

Moreover, any arguments the C<:then> parameters match are removed from the
source, and must be replaced or amended as part of the new source code
returned by the keyword body. For example: the new source returned by
the body of C<let> starts with reinstating both the trailing code and
the closing curly:

    keyword let (Var $var, '=', Expr $value) :then(Statement* $trailing_code, '}')
    {{{
            «trailing_code»
        }
        «$var» = «$value»;
    }}}


=head2 Specifying a keyword description

Normally the error messages the module generates refer to the
keyword by name. For example, an error detected in parsing a
C<repeat> keyword with:

    keyword repeat ('while', List $condition, Block $code)
    {...}

might produce the error message:

    Invalid repeat at demo.pl line 28.

which is a reasonable message, but would be slightly better if it was:

    Invalid repeat-while loop at demo.pl line 28.

You can request that a particular keyword be referred to in error
messages using a specific description, by adding the C<:desc>
modifier to the keyword definition. For example:

    keyword repeat ('while', List $condition, Block $code)
    :desc(repeat-while loop)
    {...}


=head2 Simplifying keyword generation with an interpolator

Frequently, the code block that generates the replacement syntax for a
keyword will consist of something like:

    {
        my $code_interpolation = some_expr_involving_a($param);
        return qq{ REPLACEMENT $code_interpolation HERE };
    }

in which the block does some manipulation of one or more of its
parameters, then interpolates the results into a single string,
which it returns as the replacement source code.

So the module provides a shortcut for that structure: the "triple
curly" block. If a keyword's block is delimited by three contiguous
curly brackets, then the entire block is taken to be a single
uninterpolated string that specifies the replacement source code.
Within that single string anything in C<«...»> is treated as a piece
of code to be executed and its result interpolated at that point in
the replacement code.

In other words, a triple-curly block is a literal code template, with
special C<«...»> interpolators.

For example, instead of writing:

    keyword forall (List $list, '->', Params @params, Block $code_block)
    {
        $list =~ s{\)\Z}{,\\\$__acc__)};
        substr $code_block, 1, -1, q{};
        return qq[
            {
                state \$__acc__ = [];
                foreach my \$__nary__ $list {
                    if (!ref(\$__nary__) || \$__nary__ != \\\$__acc__) {
                        push \@{\$__acc__}, \$__nary__;
                        next if \@{\$__acc__} <= $#parameters;
                    }
                    next if !\@{\$__acc__};
                    my ( @parameters ) = \@{\$__acc__};
                    \@{\$__acc__} = ();

                    $code_block
                }
            }
        ]
    }

...you could write:

    keyword forall (List $list, '->', Params @params, Block $code_block)
    {{{
        {
            state $__acc__ = [];
            foreach my $__nary__  « $list =~ s{\)\Z}{,\\\$__acc__)}r »
            {
                if (!ref($__nary__) || $__nary__ != \$__acc__) {
                    push @{$__acc__}, $__nary__;
                    next if @{$__acc__} <= «$#params»;
                }
                next if !@{$__acc__};
                my ( «"@params"» ) = @{$__acc__};
                @{$__acc__} = ();

                « substr $code_block, 1, -1 »
            }
        }
    }}}

...with a significant reduction in the number of sigils that have to be
escaped (and hence a significant decrease in the likelihood of bugs
creeping in).

Note: for those living without the blessings of Unicode, you can also
      use the pure ASCII C<< <{...}> >> to delimit interpolations,
      instead of C<«...»>.


=head2 Declaring multiple variants of a single keyword

You can declare two (or more) keywords with the same name, provided they
all have distinct parameter lists. In other words, keyword definitions
are treated as multimethods, with each variant parsing the following
source code and then the variant which matches best being selected to
provide the replacement code.

For example, you might specify three syntaxes for a C<repeat> loop:

    keyword repeat ('while', List $condition, Block $block) {{{
        while (1) { do «$block»; last if !(«$condition»); }
    }}}

    keyword repeat ('until', List $condition, Block $block) {{{
        while (1) { do «$block»; last if «$condition»; }
    }}}

    keyword repeat (Num $count, Block $block) {{{
        for (1..«$count») «$block»
    }}}

When it encounters a keyword, the module now attempts to (re)parse the
trailing code with each of the definitions of that keyword in the
current lexical scope, collecting every definition that successfuly
parses the source at that point.

If more than one definition was successful, the module first selects the
definition(s) with the most parameters. If more than one definition had
the maximal number of parameters, the module then selects the one whose
parameters matched most specifically. For example, if you had two keywords:

    keyword wait (Int $how_long, Str $msg) {{{
        { sleep «$how_long»; warn «$msg»; }
    }}}

    keyword wait (Num $how_long, Str $msg) {{{
        { use Time::HiRes 'sleep'; sleep «$how_long»; warn «$msg»; }
    }}}

...and wrote:

    wait 1, 'Done';

...then the first keyword would be selected over the second,
because C<Int> is more specific than C<Num> and C<Str> is just
as specific as C<Str>.

If two or more definitions matched equally specifically, the module
looks for one that is marked with a C<:prefer> attribute. If there is no
C<:prefer> indicated (or more than one), the module gives up and reports
a syntax ambiguity.

The order of specificity for a parameter match is determined by the relationships
between the various components of a Perl program, as illustrated in the following
tree (where a child type is more specific that its parent or higher ancestors,
and less specific than its children or deeper descendants):

=for comment Autogenerated type hierarchy (from bin/gen_types.pl)...

    ArrayIndexer

    InfixBinaryOperator

    StatementModifier

    HashIndexer

    OWS
     \..NWS or Whitespace
       |...Pod
        \..Comment

    PostfixUnaryOperator

    Attributes

    LowPrecedenceInfixOperator

    PrefixUnaryOperator

    Document
     \..Statement
       |...Block
       |...PackageDeclaration
       |...Label
       |...UseStatement
       |...Format
       |...Expression or Expr
       |    \..LowPrecedenceNotExpression
       |       \..List
       |          \..CommaList
       |             \..Assignment
       |                \..ConditionalExpression or Ternary or ListElem
       |                   \..BinaryExpression
       |                      \..PrefixPostfixTerm
       |                         \..Term
       |                           |...AnonymousHash or AnonHash
       |                           |...VariableDeclaration or VarDecl
       |                           |...Literal
       |                           |   |...Number or Num
       |                           |   |   |...Integer or Int
       |                           |   |   |    \..PositiveInteger or PosInt
       |                           |   |    \..VersionNumber
       |                           |   |       \..VString
       |                           |   |...Bareword
       |                           |   |    \..OldQualifiedIdentifier
       |                           |   |       \..QualifiedIdentifier or QualIdent
       |                           |   |          \..Identifier or Ident
       |                           |    \..String or Str
       |                           |      |...VString
       |                           |      |...QuotelikeQ
       |                           |      |...QuotelikeQQ
       |                           |       \..Heredoc
       |                           |...Lvalue
       |                           |...AnonymousSubroutine
       |                           |...AnonymousArray or AnonArray
       |                           |...DoBlock
       |                           |...DiamondOperator
       |                           |...Variable or Var
       |                           |   |...ScalarAccess
       |                           |   |    \..VariableScalar or VarScalar or ScalarVar
       |                           |   |...ArrayAccess
       |                           |   |    \..VariableArray or VarArray or ArrayVar
       |                           |    \..HashAccess
       |                           |       \..VariableHash or VarHash or HashVar
       |                           |...Typeglob
       |                           |...Call
       |                           |    \..BuiltinFunction
       |                           |       \..NullaryBuiltinFunction
       |                           |...ParenthesesList or ParensList
       |                           |...ReturnStatement
       |                           |...EvalBlock
       |                            \..Quotelike
       |                              |...Regex or Regexp
       |                              |   |...QuotelikeQR
       |                              |   |...ContextualRegex
       |                              |   |   |...ContextualMatch or ContextualQuotelikeM
       |                              |   |    \..QuotelikeQR
       |                              |    \..Match or QuotelikeM
       |                              |       \..ContextualMatch or ContextualQuotelikeM
       |                              |...QuotelikeQW
       |                              |...QuotelikeQX
       |                              |...Substitution or QuotelikeS
       |                              |...Transliteration or QuotelikeTR
       |                               \..String or Str
       |                                 |...QuotelikeQQ
       |                                  \..QuotelikeQ
       |...SubroutineDeclaration
       |...Keyword
        \..ControlBlock

    Comma

    AssignmentOperator

=for comment End of autogenerated type hierarchy

User-defined named types (declared via the C<keytype> mechanism)
are treated as being more specific than the type they rename.

Junctive types are treated as being less specific than any one of their
components, and exactly as specific as any other junctive type.

Regex and string types are treated as being more specific than
any named or junctive type.

Generally speaking, the mechanism should just do the right thing,
without your having to think about it too much...and will warn you at
compile-time when it can't work out the right thing to do, in which
case you'll need to think about it some more.


=head2 Removing a lexical keyword

The syntax for removing an existing keyword from the remaining lines
in the current scope is:

    unkeyword NAME;

Any attempts to remove non-existent keywords are silently ignored (in the
same way that removing a non-existing hash key doesn't trigger a warning).


=head2 Exporting keywords

Normally a keyword definition takes effect from the statement after
the C<keyword> declaration, to the end of the enclosing lexical block.

However, if you declare a keyword inside a subroutine named C<import>
(i.e. inside the import method of a class or module), then the keyword
is also exported to the caller of that import method.

In other words, simply placing a keyword definition in a module's
C<import> exports that keyword to the lexical scope in which the
module is used.

You can also define new keywords in a module's C<unimport> method,
and they are exported in exactly the same way.

Likewise, if you place an C<unkeyword> declaration in an C<import>
or C<unimport> subroutine, then the specified keyword is removed from
the lexical scope in which the module is C<use>'d or C<no>'d.


=head2 Debugging keywords

If you load the module with the C<'debug'> option:

    use Keyword::Declare {debug=>1};

then keywords and keytypes and unkeywords declared in that lexical scope
will report their own declarations, and will subsequently report how
they transform the source following them. For example:

    use Keyword::Declare {debug=>1};

    keyword list (/keys|values|pairs/ $what, 'in', HashVar $hash) {
        my $EXTRACTOR = $what eq 'values' ? 'values' : 'keys';
        my $REPORTER  = $what eq 'pairs' ? $hash.'{$data}' : '$data';

        return qq{for my \$data ($EXTRACTOR $hash) { say join "\\n", ${REPORTER}_from($hash) }};
    }

    # And later...

    list pairs in %foo;

...would print to STDERR:

    #####################################################
    ### Installed keyword macro at demo.pl line 10:
    ###
    ###list  <what>  in  <hash>
    ###
    #####################################################
    #####################################################
    ### Keyword macro defined at demo.pl line 10:
    ###
    ###    list  <what>  in  <hash>
    ###
    ### Converted code at demo.pl line 19:
    ###
    ###    list  pairs in %foo
    ###
    ### Into:
    ###
    ###    for my $data (keys %foo) { say join "\n", keys_from(\%foo) }
    ###
    #####################################################


=head1 DIAGNOSTICS

=over

=item C<< Invalid option for: use Keyword::Declare >>

Currently the module takes only a simple argument when loaded: a hash
of configuration options. You passed something else to C<use Keyword::Declare;>

A common mistake is to load the module with:

    use Keyword::Declare  debug=>1;

instead of:

    use Keyword::Declare {debug=>1};


=item C<< Can't redefine/undefine 'keyword' keyword >>

You attempted to use the C<keyword> keyword to define a new keyword
named C<keyword>. Or you attempted to use the C<unkeyword> keyword
to remove C<keyword>.

Isn't your life hard enough without attempting to inject that amount of
meta into it???

Future versions of this module may well allow you to overload the
C<keyword> keyword, but this version doesn't. You could always use
C<Keyword> (with a capital 'K') instead.


=item C<< Can't redefine/undefine 'keytype' keyword >>

No, you can't mess with the C<keytype> keyword either.


=item C<< Unknown type (%s) for keyword parameter. Did you mean: %s", >>

You used a type for a keyword parameter that the module did not
recognize. See earlier in this document for a list of the types that the
module knows. You may also have misspelled a type.
Alternatively, did you declare a C<keytype> but then use it in the
wrong lexical scope?


=item C<< :then attribute specified too late >>

A C<:then> attribute must be specified immediately after the closing
parenthesis of the keyword's main parameter list, without any other
attributes between the two. You placed the C<:then> attribute after
some other attribute. Move it so that it follows the parameter list
directly.


=item C<< Invalid attribute: %s >>

Keywords may only be specified with four attributes:
C<:then>, C<:desc>, C<:prefer>, and C<:keepspace>.

You specified some other attribute that the module doesn't know how to
handle (or possibly misspelled one of the valid attribute names).


=item C<< Missing » on interpolation «%s... >>

=item C<< Missing }> on interpolation <{%s... >>

You created a C<keyword> definition with a C<{{{...}}}> interpolator,
within which there was an interpolation that extended to the end of the
interpolator without supplying a closing C<»> or C<< }> >>. Did you
accidentally use just a C<< > >> or a C<< } >> instead?


=item C<< Invalid %s at %s. Expected: %s but found: %s >>

You used a defined keyword, but with the wrong syntax after it.
The error message lists what the valid possibilities were.


=item C<< Ambiguous %s at %s. Could be: %s >>

You used a keyword, but the syntax after it was ambiguous
(i.e. it matched two or more variants of the keyword equally well).

You either need to change the syntax you used (so that it matches only
one variant of the keyword syntax) or else change the definition of one
or more of the keywords (to ensure their syntaxes are no longer ambiguous).


=item C<< Invalid keyword definition. Expected %s but found: %s >>

You attempted to define a keyword, but used the wrong syntax.
The parameter specification is the usual suspect, or else a
syntax error in the block.


=item C<< Likely keyword substitution cycle: %s >>

The module replaced a keyword with some code that contained another
keyword, which the module replaced with some code that contained another
keyword, which the module replaced with...et cetera, et cetera.

If the module detects itself rewriting the same section of code many
times, and with the same keyword being recursively expanded more than
once, then it infers that the expansion process is never going to
end...and simply gives up.

To avoid this problem, don't create a keyword A that generates code that
includes keyword B, where keyword B generates code that includes keyword
C, where keyword C generates code that includes keyword A.

=back


=head1 CONFIGURATION AND ENVIRONMENT

Keyword::Declare requires no configuration files or environment variables.


=head1 DEPENDENCIES

The module is an interface to Perl's pluggable keyword mechanism, which
was introduced in Perl 5.12. Hence it will never work under earlier
versions of Perl.

Currently requires both the Keyword::Simple module and the PPR module.


=head1 INCOMPATIBILITIES

None reported.

But Keyword::Declare probably won't get along well with source filters
or Devel::Declare.


=head1 BUGS AND LIMITATIONS

The module currently relies on Keyword::Simple, so it is subject to all
the limitations of that module. Most significantly, it can only create
keywords that appear at the beginning of a statement (though you can
almost always code around that limitation by wrapping the keyword in
a C<do{...}> block.

Moreover, there is a issue with Keyword::Simple v0.04 which sometimes
causes that module to fail when used by Keyword::Declare under Perl 5.14
and 5.16. Consequently, Keyword::Declare may be unreliable under Perls
before 5.18 if Keyword::Simple v0.04 or later is installed. The current
workaround is to downgrade to Keyword::Simple v0.03 under those early
Perl versions.

Even with the PPR module, parsing Perl code is tricky, and parsing Perl
code to build Perl code that parses other Perl code is even more so.
Hence, there are likely to be cases where this module gets it
spectacularly wrong.

Please report any bugs or feature requests to
C<bug-keyword-declare.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Damian Conway  C<< <DCONWAY@CPAN.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015-2017, Damian Conway C<< <DCONWAY@CPAN.org> >>. All rights reserved.

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
