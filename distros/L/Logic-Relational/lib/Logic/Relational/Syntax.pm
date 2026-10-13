package Logic::Relational::Syntax;

## no critic (RegularExpressions::RequireExtendedFormatting, ValuesAndVariables::ProhibitLiteralNewlines, ControlStructures::ProhibitCascadingIfElse, RegularExpressions::ProhibitComplexRegexes, Subroutines::ProhibitExcessComplexity, BuiltinFunctions::RequireBlockMap)

use v5.38;
use experimental 'signatures';
use Keyword::Simple;
use Carp                   qw(croak);
use Logic::Relational::DSL ();

our $VERSION = '0.02';

# Export logic syntax keywords when imported
sub import ($class) {
    my ($target_pkg) = caller;

    # 1. logic keyword
    Keyword::Simple::define 'logic', sub ($src_ref) {

        # Match identifier and curly block
        if ( $$src_ref =~ s/\A\s*([a-zA-Z_]\w*)\s*(\{(?:[^{}]++|(?2))*\})//s ) {
            my ( $name, $body ) = ( $1, $2 );
            $body =~
s/\A\s*\{/{\nrequire Logic::Relational::Program;\nrequire Logic::Relational::Goal::Call;\nrequire Logic::Relational::Goal::Unify;\nrequire Logic::Relational::Goal::Identical;\nrequire Logic::Relational::Goal::Not;\nrequire Logic::Relational::Goal::ConstraintFD;\nrequire Logic::Relational::StdLib;\nour \$PROGRAM = Logic::Relational::Program->new();\nLogic::Relational::StdLib::export_to_program(\$PROGRAM);\nuse Logic::Relational::DSL qw(rest slurp term is_goal identical guard save_snapshot load_snapshot);\nour \$AUTOLOAD;\nsub AUTOLOAD (\@args) { my \$sub = \$AUTOLOAD; \$sub =~ s{.*::}{}; require Logic::Relational::Goal::Call; return Logic::Relational::Goal::Call->new(\$sub, \\\@args); }/s;
            my $replacement = <<~"EOF";
                package $name $body
            EOF
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid logic declaration syntax";
        }
    };

    # 2. fact keyword
    Keyword::Simple::define 'fact', sub ($src_ref) {

# Match identifier and optional parenthesized arguments list, followed by semicolon
        if ( $$src_ref =~
            s/\A\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?2))*\)))?\s*;//s )
        {
            my ( $pred, $args ) = ( $1, $2 );
            my $fact_call =
              defined $args
              ? "\$PROGRAM->fact( '$pred', $args );"
              : "\$PROGRAM->fact( '$pred' );";
            my $replacement = "sub $pred;\n$fact_call\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid fact syntax";
        }
    };

    # 2b. facts keyword (grouped block declaration)
    Keyword::Simple::define 'facts', sub ($src_ref) {

        # Match curly block
        if ( $$src_ref =~ s/\A\s*(\{(?:[^{}]++|(?1))*\})//s ) {
            my $block = $1;
            $block =~ s/\A\s*\{//;
            $block =~ s/\}\s*\z//;

            # Strip full-line comments inside facts block
            $block =~ s{^\s*#.*$}{}mg;

            my @facts_code;
            my %seen_preds;
            while ( $block =~
s/^\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?2))*\)))?\s*;\s*(?:#[^\n]*)?//s
              )
            {
                my ( $pred, $args ) = ( $1, $2 );
                push @facts_code, "sub $pred;" unless $seen_preds{$pred}++;
                if ( defined $args ) {
                    push @facts_code, "\$PROGRAM->fact( '$pred', $args );";
                }
                else {
                    push @facts_code, "\$PROGRAM->fact( '$pred' );";
                }
            }
            $block =~ s/\s+//g;
            if ( length($block) > 0 ) {
                croak "Invalid syntax in facts block near '$block'";
            }
            my $replacement = join( "\n", @facts_code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid facts syntax";
        }
    };

    # 2c. table keyword (subgoal tabling / memoization)
    Keyword::Simple::define 'table', sub ($src_ref) {
        if ( $$src_ref =~
s/\A\s*(['"]?[a-zA-Z_]\w*(?:\s*\/\s*(?:\d+|\*))?['"]?(?:\s*,\s*['"]?[a-zA-Z_]\w*(?:\s*\/\s*(?:\d+|\*))?['"]?)*)\s*;//s
          )
        {
            my $list_str = $1;
            my @specs    = split( /\s*,\s*/, $list_str );
            my @code;
            for my $spec (@specs) {
                $spec =~ s/['"\s]+//g;
                push @code, "\$PROGRAM->table('$spec');";
            }
            my $replacement = join( "\n", @code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid table syntax";
        }
    };

    # 3. rule keyword
    Keyword::Simple::define 'rule', sub ($src_ref) {

        # Match identifier, optional parenthesized parameters, and block
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?2))*\))\s*)?(\{(?:[^{}]++|(?3))*\})//s
          )
        {
            my ( $pred, $params, $body ) = ( $1, $2 // '()', $3 );

            my $param_str = $params;
            $param_str =~ s/^\s*\(\s*//;
            $param_str =~ s/\s*\)\s*$//;
            my @param_vars = split( /\s*,\s*/, $param_str );

            my @param_decls;
            my %seen_vars;
            while ( $param_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $var_name = $1;
                next if $seen_vars{$var_name}++;
                push @param_decls,
"my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            }

            my $translated_body = translate_body($body);
            my $decls           = join( "\n", @param_decls );
            my $args            = join( ", ", @param_vars );

            my $replacement = <<~"EOF";
                sub $pred;
                {
                    $decls
                    \$PROGRAM->rule(
                        head => Logic::Relational::Goal::Call->new( '$pred', [ $args ] ),
                        body => $translated_body
                    );
                }
            EOF
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid rule syntax";
        }
    };

    # 4. fresh keyword
    Keyword::Simple::define 'fresh', sub ($src_ref) {

        # Match "my ($v1, $v2) in [1,4,9,16];"
        if ( $$src_ref =~
            s/\A\s*my\s*\(\s*([^)]+?)\s*\)\s+in\s*(\[[^\]]+\])\s*;//s )
        {
            my ( $vars_str, $list_str ) = ( $1, $2 );
            my @code;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $vn = $1;
                push @code,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
                push @code,
"\$PROGRAM->goal(Logic::Relational::Goal::Domain->new( \$$vn, $list_str ));";
            }
            my $replacement = join( "\n", @code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }

        # Match "my ($v1, $v2) in MIN..MAX;"
        elsif ( $$src_ref =~
s/\A\s*my\s*\(\s*([^)]+?)\s*\)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)\s*;//s
          )
        {
            my ( $vars_str, $min, $max ) = ( $1, $2, $3 );
            my @code;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $vn = $1;
                push @code,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
                push @code,
"\$PROGRAM->goal(Logic::Relational::Goal::Domain->new( \$$vn, $min, $max ));";
            }
            my $replacement = join( "\n", @code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }

        # Match "my $var in [1,4,9,16];"
        elsif ( $$src_ref =~
            s/\A\s*my\s+\$([a-zA-Z_]\w*)\s+in\s*(\[[^\]]+\])\s*;//s )
        {
            my ( $var_name, $list_str ) = ( $1, $2 );
            my $replacement = <<~"EOF";
                my \$$var_name = Logic::Relational::DSL::variable('$var_name');
                \$PROGRAM->goal(Logic::Relational::Goal::Domain->new( \$$var_name, $list_str ));
            EOF
            $$src_ref = $replacement . $$src_ref;
        }

        # Match "my $var in MIN..MAX;"
        elsif ( $$src_ref =~
            s/\A\s*my\s+\$([a-zA-Z_]\w*)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)\s*;//s
          )
        {
            my ( $var_name, $min, $max ) = ( $1, $2, $3 );
            my $replacement = <<~"EOF";
                my \$$var_name = Logic::Relational::DSL::variable('$var_name');
                \$PROGRAM->goal(Logic::Relational::Goal::Domain->new( \$$var_name, $min, $max ));
            EOF
            $$src_ref = $replacement . $$src_ref;
        }

        # Match "my ($v1, $v2);"
        elsif ( $$src_ref =~ s/\A\s*my\s*\(\s*([^)]+?)\s*\)\s*;//s ) {
            my $vars_str = $1;
            my @code;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $vn = $1;
                push @code,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
            }
            my $replacement = join( "\n", @code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }

        # Match "my $var;"
        elsif ( $$src_ref =~ s/\A\s*my\s+\$([a-zA-Z_]\w*)\s*;//s ) {
            my $var_name = $1;
            my $replacement =
              "my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid fresh variable syntax";
        }
    };

    # 5. query keyword
    Keyword::Simple::define 'query', sub ($src_ref) {

# Match Program::predicate[(args)] optionally followed by -> expression, terminated by semicolon
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*::\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?3))*\)))?(?:\s*->\s*([^;]+?))?\s*;//s
          )
        {
            my ( $prog, $pred, $args, $var ) = ( $1, $2, $3 // '()', $4 );

            my $arg_str = $args;
            $arg_str =~ s/^\s*\(\s*//;
            $arg_str =~ s/\s*\)\s*$//;

            # Scan for fresh my $var inside args
            my @decls;
            while ( $arg_str =~ s/fresh\s+my\s+\$([a-zA-Z_]\w*)/\$$1/ ) {
                my $var_name = $1;
                push @decls,
"my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            }

            my $decls_code = join( "\n", @decls );

            my $replacement;
            if ($var) {
                $replacement = <<~"EOF";
                    $decls_code
                    $var = \$${prog}::PROGRAM->query(
                        Logic::Relational::Goal::Call->new( '$pred', [ $arg_str ] )
                    );
                EOF
            }
            else {
                $replacement = <<~"EOF";
                    $decls_code
                    \$${prog}::PROGRAM->query(
                        Logic::Relational::Goal::Call->new( '$pred', [ $arg_str ] )
                    );
                EOF
            }
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid query syntax";
        }
    };

    # 6. generator keyword
    Keyword::Simple::define 'generator', sub ($src_ref) {

# Match identifier, arity in parens, optional comma, followed by 'sub' with balanced signature and block
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*\(\s*(\d+)\s*\)\s*,?\s*(sub\s*(?:(\((?:[^()]++|(?4))*\)))?\s*(\{(?:[^{}]++|(?5))*\}))\s*;?//s
          )
        {
            my ( $pred, $arity, $expr ) = ( $1, $2, $3 );
            my $replacement = <<~"EOF";
                sub $pred;
                \$PROGRAM->generator( '$pred', $arity, $expr );
            EOF
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid generator syntax";
        }
    };
    return;
}

# Helper to translate the body of a rule/negation/disjunction
sub translate_body ($body_str) {

    # Strip optional surrounding curly braces
    $body_str =~ s/^\s*\{\s*//s;
    $body_str =~ s/\s*\}\s*$//s;

# Strip comments (excluding CLP(FD) operators #=, #/=, #!=, #<, #>, #<=, #>=, #\=)
    $body_str =~ s{^\s*#(?![\=/<>!\\\\]).*\n}{\n}mg;
    $body_str =~ s{\s+#(?![\=/<>!\\\\]).*\n}{\n}mg;

    my @goals;
    my @declarations;

    # Parse statements one by one
    while ( $body_str =~ /\S/s ) {

        # 1a. fresh my ($v1, $v2, ...) in [1,4,9,16];
        if ( $body_str =~
            s/^\s*fresh\s+my\s*\(\s*([^)]+?)\s*\)\s+in\s*(\[[^\]]+\])\s*;\s*//s
          )
        {
            my ( $vars_str, $list_str ) = ( $1, $2 );
            my @var_names;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                push @var_names, $1;
            }
            for my $vn (@var_names) {
                push @declarations,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
                push @goals,
                  "Logic::Relational::Goal::Domain->new( \$$vn, $list_str )";
            }
        }

        # 1a2. fresh my ($v1, $v2, ...) in MIN..MAX;
        elsif ( $body_str =~
s/^\s*fresh\s+my\s*\(\s*([^)]+?)\s*\)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)\s*;\s*//s
          )
        {
            my ( $vars_str, $min, $max ) = ( $1, $2, $3 );
            my @var_names;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                push @var_names, $1;
            }
            for my $vn (@var_names) {
                push @declarations,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
                push @goals,
                  "Logic::Relational::Goal::Domain->new( \$$vn, $min, $max )";
            }
        }

        # 1b. fresh my $var in [1,4,9,16];
        elsif ( $body_str =~
            s/^\s*fresh\s+my\s+\$([a-zA-Z_]\w*)\s+in\s*(\[[^\]]+\])\s*;\s*//s )
        {
            my ( $var_name, $list_str ) = ( $1, $2 );
            push @declarations,
              "my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            push @goals,
              "Logic::Relational::Goal::Domain->new( \$$var_name, $list_str )";
        }

        # 1b2. fresh my $var in MIN..MAX;
        elsif ( $body_str =~
s/^\s*fresh\s+my\s+\$([a-zA-Z_]\w*)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)\s*;\s*//s
          )
        {
            my ( $var_name, $min, $max ) = ( $1, $2, $3 );
            push @declarations,
              "my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            push @goals,
              "Logic::Relational::Goal::Domain->new( \$$var_name, $min, $max )";
        }

        # 1c. fresh my ($v1, $v2, ...);
        elsif ( $body_str =~ s/^\s*fresh\s+my\s*\(\s*([^)]+?)\s*\)\s*;\s*//s ) {
            my $vars_str = $1;
            my @var_names;
            while ( $vars_str =~ /\$([a-zA-Z_]\w*)/g ) {
                push @var_names, $1;
            }
            for my $vn (@var_names) {
                push @declarations,
                  "my \$$vn = Logic::Relational::DSL::variable('$vn');";
            }
        }

        # 1d. fresh my $var;
        elsif ( $body_str =~ s/^\s*fresh\s+my\s+\$([a-zA-Z_]\w*)\s*;\s*//s ) {
            my $var_name = $1;
            push @declarations,
              "my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
        }

        # 2. either { ... } or { ... } [ or { ... } ... ]
        elsif ( $body_str =~
s/^\s*either\s*(\{(?:[^{}]++|(?1))*\})((\s*or\s*\{(?:[^{}]++|(?3))*\})+)\s*;?\s*//s
          )
        {
            my $first_raw = $1;
            my $rest_raw  = $2;

            my @raw_blocks = ($first_raw);
            while ( $rest_raw =~ s/^\s*or\s*(\{(?:[^{}]++|(?1))*\})//s ) {
                push @raw_blocks, $1;
            }

            my @trans_blocks = map { translate_body($_) } @raw_blocks;
            my $blocks_code  = join( ", ", @trans_blocks );

            push @goals, "Logic::Relational::Goal::Any->new([ $blocks_code ])";
        }

        # 3. not { ... }
        elsif ( $body_str =~ s/^\s*not\s*(\{(?:[^{}]++|(?1))*\})\s*;?\s*//s ) {
            my $block = translate_body($1);
            push @goals, "Logic::Relational::Goal::Not->new( $block )";
        }

        # 4a. $var in [1,4,9,16];
        elsif (
            $body_str =~ s/^\s*\$([a-zA-Z_]\w*)\s+in\s*(\[[^\]]+\])\s*;\s*//s )
        {
            my ( $var_name, $list_str ) = ( $1, $2 );
            push @goals,
              "Logic::Relational::Goal::Domain->new( \$$var_name, $list_str )";
        }

        # 4b. $var in MIN..MAX;
        elsif ( $body_str =~
            s/^\s*\$([a-zA-Z_]\w*)\s+in\s+(-?\d+)\s*\.\.\s*(-?\d+)\s*;\s*//s )
        {
            my ( $var_name, $min, $max ) = ( $1, $2, $3 );
            push @goals,
              "Logic::Relational::Goal::Domain->new( \$$var_name, $min, $max )";
        }

        # 4b. $target is <expr>;
        elsif ( $body_str =~ s/^\s*\$([a-zA-Z_]\w*)\s+is\s+([^;]+?)\s*;\s*//s )
        {
            my ( $target_name, $expr_str ) = ( $1, $2 );
            my %deps_seen;
            my @deps;
            while ( $expr_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $var_name = $1;
                next if $deps_seen{$var_name}++ || $var_name eq $target_name;
                push @deps, "\$$var_name";
            }
            my $params_code = join( ", ", @deps );
            push @goals,
"Logic::Relational::Goal::Is->new( \$$target_name, [$params_code], sub ($params_code) { return $expr_str; } )";
        }

        # 4b2. $t1 \= $t2; or $t1 !:= $t2; (Non-Unifiability)
        elsif (
            $body_str =~ s/^\s*([^;]+?)\s*(?:\\=|\!\:\=)\s*([^;]+?)\s*;\s*//s )
        {
            my ( $t1, $t2 ) = ( $1, $2 );
            push @goals,
"Logic::Relational::Goal::Not->new( Logic::Relational::Goal::Unify->new( $t1, $t2 ) )";
        }

        # 4b3. $t1 := $t2; (Infix Unification)
        elsif (
            $body_str =~ s/^\s*([^;]+?)\s*(?<!\!) := \s*([^;]+?)\s*;\s*//sx )
        {
            my ( $t1, $t2 ) = ( $1, $2 );
            push @goals, "Logic::Relational::Goal::Unify->new( $t1, $t2 )";
        }

# 4c. label(args) / all_different(args) / guard(args) / unify(args) / is_goal(args) / identical(args) / true_goal / fail_goal
        elsif ( $body_str =~
s/^\s*(all_different|label|guard|unify|is_goal|identical|true_goal|fail_goal)\b\s*( (\((?: (?>[^()]+) | (?2) )*\)) )?\s*;\s*//sx
          )
        {
            my ( $type, $full_parens ) = ( $1, $2 // "" );
            my $args = $full_parens;
            $args =~ s/^\s*\(//;
            $args =~ s/\)\s*$//;
            if ( $type eq 'all_different' ) {
                push @goals,
                  "Logic::Relational::Goal::AllDifferent->new( [$args] )";
            }
            elsif ( $type eq 'label' ) {
                push @goals, "Logic::Relational::Goal::Label->new( [$args] )";
            }
            elsif ( $type eq 'guard' ) {
                push @goals, "Logic::Relational::Goal::Guard->new( $args )";
            }
            elsif ( $type eq 'unify' ) {
                push @goals, "Logic::Relational::Goal::Unify->new( $args )";
            }
            elsif ( $type eq 'is_goal' ) {
                push @goals, "Logic::Relational::Goal::Is->new( $args )";
            }
            elsif ( $type eq 'identical' ) {
                push @goals, "Logic::Relational::Goal::Identical->new( $args )";
            }
            elsif ( $type eq 'true_goal' ) {
                push @goals, "Logic::Relational::Goal::True->new()";
            }
            elsif ( $type eq 'fail_goal' ) {
                push @goals, "Logic::Relational::Goal::Fail->new()";
            }
        }

        # 4d. $t1 \== $t2; (Strict Non-Identity)
        elsif ( $body_str =~ s/^\s*([^;]+?)\s*\\==\s*([^;]+?)\s*;\s*//s ) {
            my ( $t1, $t2 ) = ( $1, $2 );
            push @goals,
"Logic::Relational::Goal::Not->new( Logic::Relational::Goal::Identical->new( $t1, $t2 ) )";
        }

        # 4e. $t1 == $t2; (Strict Identity)
        elsif ( $body_str =~ s/^\s*([^;]+?)\s*==\s*([^;]+?)\s*;\s*//s ) {
            my ( $t1, $t2 ) = ( $1, $2 );
            push @goals, "Logic::Relational::Goal::Identical->new( $t1, $t2 )";
        }

# 4b0. $left (#=, #/=, #!=, #<, #<=, #>, #>=, !=, <, <=, >, >=) $right; (Arithmetic / CLP(FD) Constraint)
        elsif ( $body_str =~
s/^\s*([^;]+?)\s*(#=|#\/=|#!=|#\\=|#<=|#=<|#>=|#<|#>|>=|<=|(?<!=)>(?!=)|(?<!=)<(?!=)|(?<!\!)!=(?!=))\s*([^;]+?)\s*;\s*//s
          )
        {
            my ( $left_expr, $op, $right_expr ) = ( $1, $2, $3 );
            my %seen_vars;
            my @vars;
            for my $e ( $left_expr, $right_expr ) {
                while ( $e =~ /\$([a-zA-Z_]\w*)/g ) {
                    my $vn = $1;
                    next if $seen_vars{$vn}++;
                    push @vars, "\$$vn";
                }
            }
            my $vars_list = join( ", ", @vars );
            my @assigns;
            for my $v (@vars) {
                my $vname = $v;
                $vname =~ s/^\$//;
                push @assigns, "my \$$vname = \$map_ref->{'$vname'};";
            }
            my $assign_code = join( "\n", @assigns );

            push @goals,
"Logic::Relational::Goal::ConstraintFD->new( '$op', [$vars_list], sub (\$map_ref) { $assign_code return ( ($left_expr), ($right_expr) ); } )";
        }

        # 6. General predicate call: name(args); or 0-arity name;
        elsif ( $body_str =~ s/^\s*([a-zA-Z_]\w*)\s*(?:\((.*?)\))?\s*;\s*//s ) {
            my ( $pred, $args ) = ( $1, $2 // '' );
            push @goals,
              "Logic::Relational::Goal::Call->new( '$pred', [$args] )";
        }
        else {
            # Strip trailing comments/whitespace or die on error
            $body_str =~ s/^\s*(?:#.*\n\s*)*\z//s;
            if ( $body_str =~ /\S/s ) {
                croak "Syntax error in logic block near: "
                  . substr( $body_str, 0, 50 ) . "\n";
            }
        }
    }

    # Reconstruct the block as a Perl expression returning the goals
    my $code = "";
    if (@declarations) {
        $code .= join( "\n", @declarations ) . "\n";
    }
    if ( @goals == 0 ) {
        $code .= "Logic::Relational::Goal::True->new";
    }
    elsif ( @goals == 1 ) {
        $code .= $goals[0];
    }
    else {
        $code .= "Logic::Relational::Goal::All->new([\n"
          . join( ",\n", @goals ) . "\n])";
    }

    return "do {\n$code\n}";
}

1;

__END__

=head1 NAME

Logic::Relational::Syntax - Declarative syntax layer for Logic::Relational.

=head1 SYNOPSIS

    use v5.38;
    use Logic::Relational::Syntax;

    logic Graph {
        table path/2;

        facts {
            edge('a', 'b');
            edge('b', 'c');
            edge('c', 'a'); # cyclic graph
        }

        rule path($x, $y) {
            edge($x, $y);
        }
        rule path($x, $z) {
            fresh my $y;
            edge($x, $y);
            path($y, $z);
        }
    }

    query Graph::path('a', fresh my $dest) -> my $q;
    my @reachable = $q->distinct_values($dest);

=head1 DESCRIPTION

Exports declarative keywords (C<logic>, C<fact>, C<facts>, C<table>, C<rule>,
C<fresh>, C<query>, and C<generator>) via L<Keyword::Simple>.

=head1 FUNCTIONS

=head2 translate_body

Internal helper that translates a declarative rule body string into a Perl
expression returning a L<Logic::Relational::Goal> object.

=cut
