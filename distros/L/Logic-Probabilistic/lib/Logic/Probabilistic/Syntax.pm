package Logic::Probabilistic::Syntax;

## no critic (RegularExpressions::RequireExtendedFormatting, ValuesAndVariables::ProhibitLiteralNewlines, ControlStructures::ProhibitCascadingIfElse, RegularExpressions::ProhibitComplexRegexes, Subroutines::ProhibitExcessComplexity)

use v5.38;
use experimental 'signatures';
use Keyword::Simple;
use Carp                      qw(croak);
use Logic::Relational::Syntax ();

our $VERSION = '0.01';

sub import ($class) {
    my ($target_pkg) = caller;
    require Logic::Relational::DSL;
    {
        no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{"${target_pkg}::not_goal"} = \&Logic::Relational::DSL::not_goal;
    }

    # 1. prob_logic keyword
    Keyword::Simple::define 'prob_logic', sub ($src_ref) {
        if ( $$src_ref =~ s/\A\s*([a-zA-Z_]\w*)\s*(\{(?:[^{}]++|(?2))*\})//s ) {
            my ( $name, $body ) = ( $1, $2 );
            $body =~
s/\A\s*\{/{\nrequire Logic::Probabilistic::Program;\nrequire Logic::Relational::Goal::Call;\nrequire Logic::Relational::Goal::Unify;\nrequire Logic::Relational::Goal::Identical;\nrequire Logic::Relational::Goal::Not;\nrequire Logic::Relational::Goal::ConstraintFD;\nrequire Logic::Relational::StdLib;\nour \$PROGRAM = Logic::Probabilistic::Program->new();\nLogic::Relational::StdLib::export_to_program(\$PROGRAM->relational_program);\nuse Logic::Relational::DSL qw(rest slurp term is_goal identical guard save_snapshot load_snapshot variable call all any_goal not_goal);\nsub goal (\$pred, \@args) { require Logic::Relational::Goal::Call; return Logic::Relational::Goal::Call->new(\$pred, \\\@args); }\nour \$AUTOLOAD;\nsub AUTOLOAD (\@args) { my \$sub = \$AUTOLOAD; \$sub =~ s{.*::}{}; require Logic::Relational::Goal::Call; return Logic::Relational::Goal::Call->new(\$sub, \\\@args); }/s;
            my $replacement = "package $name $body\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid prob_logic declaration syntax";
        }
    };

    # 2. pfact keyword
    Keyword::Simple::define 'pfact', sub ($src_ref) {

        # Match: pfact <prob> => <pred>(<args>); or pfact <prob> => <pred>;
        if ( $$src_ref =~
s/\A\s*([0-9.]+(?:\s*\/\s*[0-9.]+)?)\s*=>\s*([a-zA-Z_]\w*)\s*(?:\((.*?)\))?\s*;//s
          )
        {
            my ( $prob, $pred, $args ) = ( $1, $2, $3 // '' );
            my $args_part = ( defined $args && $args =~ /\S/ ) ? ", $args" : "";
            my $replacement =
              "sub $pred;\n\$PROGRAM->pfact( ($prob), '$pred'$args_part );\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid pfact syntax";
        }
    };

    # 2b. pfacts keyword (grouped probabilistic facts block declaration)
    Keyword::Simple::define 'pfacts', sub ($src_ref) {
        if ( $$src_ref =~ s/\A\s*(\{(?:[^{}]++|(?1))*\})//s ) {
            my $block = $1;
            $block =~ s/\A\s*\{//;
            $block =~ s/\}\s*\z//;
            $block =~ s{^\s*#.*$}{}mg;

            my @pfacts_code;
            my %seen_preds;
            while ( $block =~
s/^\s*([0-9.]+(?:\s*\/\s*[0-9.]+)?|\$[a-zA-Z_]\w*)\s*=>\s*([a-zA-Z_]\w*)\s*(?:\((.*?)\))?\s*(?:,\s*(\{.*?\}))?\s*;\s*(?:#[^\n]*)?//s
              )
            {
                my ( $prob, $pred, $args, $opts ) = ( $1, $2, $3 // '', $4 );
                my @call_args = ( "($prob)", "'$pred'" );
                push @call_args, $args if defined $args && $args =~ /\S/;
                push @call_args, $opts if defined $opts && $opts =~ /\S/;
                my $args_str = join( ', ', @call_args );
                push @pfacts_code, "sub $pred;" unless $seen_preds{$pred}++;
                push @pfacts_code, "\$PROGRAM->pfact( $args_str );";
            }

            $block =~ s/^\s+//;
            $block =~ s/\s+$//;
            if ( $block =~ /\S/ ) {
                croak "Invalid pfacts declaration inside block: '$block'";
            }

            my $replacement = join( "\n", @pfacts_code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid pfacts syntax";
        }
    };

    # 3. pchoice keyword
    Keyword::Simple::define 'pchoice', sub ($src_ref) {
        if ( $$src_ref =~
            s/\A\s*([a-zA-Z_]\w*)\s*(?:\((.*?)\))?\s*=>\s*(\[.*?\])\s*;//s )
        {
            my ( $pred, $args, $outcomes ) = ( $1, $2 // '', $3 );
            my $args_part =
              ( defined $args && $args =~ /\S/ ) ? ", [ $args ]" : "";
            my $replacement =
"sub $pred;\n\$PROGRAM->pchoice( '$pred', $outcomes$args_part );\n";
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid pchoice syntax";
        }
    };

    # 4. fact keyword
    Keyword::Simple::define 'fact', sub ($src_ref) {
        if ( $$src_ref =~
            s/\A\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?2))*\)))?\s*;//s )
        {
            my ( $pred, $args ) = ( $1, $2 );
            my $replacement;
            if ( defined $args ) {
                $replacement =
                  "sub $pred;\n\$PROGRAM->fact( '$pred', $args );\n";
            }
            else {
                $replacement = "sub $pred;\n\$PROGRAM->fact( '$pred' );\n";
            }
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid fact syntax";
        }
    };

    # 5. facts keyword (grouped block declaration)
    Keyword::Simple::define 'facts', sub ($src_ref) {
        if ( $$src_ref =~ s/\A\s*(\{(?:[^{}]++|(?1))*\})//s ) {
            my $block = $1;
            $block =~ s/\A\s*\{//;
            $block =~ s/\}\s*\z//;
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

    # 5b. table keyword (subgoal tabling / memoization)
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

    # 6. rule keyword
    Keyword::Simple::define 'rule', sub ($src_ref) {
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

            my $translated_body = _translate_rule_body($body);
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

    # 6b. prule keyword (probabilistic rules / clauses)
    Keyword::Simple::define 'prule', sub ($src_ref) {
        if ( $$src_ref =~
s/\A\s*([0-9.]+(?:\s*\/\s*[0-9.]+)?|\$[a-zA-Z_]\w*)\s*=>\s*([a-zA-Z_]\w*)\s*(?:(\((?:[^()]++|(?3))*\))\s*)?(\{(?:[^{}]++|(?4))*\})\s*;?//s
          )
        {
            my ( $prob, $pred, $params, $body ) = ( $1, $2, $3 // '()', $4 );

            my $param_str = $params;
            $param_str =~ s/^\s*\(\s*//;
            $param_str =~ s/\s*\)\s*$//;
            my @param_vars = grep { /\S/ } split( /\s*,\s*/, $param_str );

            my @param_decls;
            my %seen_vars;
            while ( $param_str =~ /\$([a-zA-Z_]\w*)/g ) {
                my $var_name = $1;
                next if $seen_vars{$var_name}++;
                push @param_decls,
"my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            }

            my $translated_body = _translate_rule_body($body);
            my $decls           = join( "\n", @param_decls );
            my $args            = join( ", ", @param_vars );

            my $replacement = <<~"EOF";
                sub $pred;
                {
                    $decls
                    \$PROGRAM->prule(
                        probability => ($prob),
                        predicate   => '$pred',
                        params      => [ $args ],
                        body        => $translated_body
                    );
                }
            EOF
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid prule syntax";
        }
    };

    # 7. generator keyword
    Keyword::Simple::define 'generator', sub ($src_ref) {
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*\(\s*(\d+)\s*\)\s*,?\s*(sub\s*(?:(\((?:[^()]++|(?4))*\)))?\s*(\{(?:[^{}]++|(?5))*\}))\s*;//s
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

    # 8. fresh keyword
    Keyword::Simple::define 'fresh', sub ($src_ref) {
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
"\$PROGRAM->relational_program->goal(Logic::Relational::Goal::Domain->new( \$$vn, $list_str ));";
            }
            my $replacement = join( "\n", @code ) . "\n";
            $$src_ref = $replacement . $$src_ref;
        }
        elsif ( $$src_ref =~
            s/\A\s*my\s+\$([a-zA-Z_]\w*)\s+in\s*(\[[^\]]+\])\s*;//s )
        {
            my ( $var_name, $list_str ) = ( $1, $2 );
            my $replacement = <<~"EOF";
                my \$$var_name = Logic::Relational::DSL::variable('$var_name');
                \$PROGRAM->relational_program->goal(Logic::Relational::Goal::Domain->new( \$$var_name, $list_str ));
            EOF
            $$src_ref = $replacement . $$src_ref;
        }
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

    # 8. query_prob keyword
    Keyword::Simple::define 'query_prob', sub ($src_ref) {
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*::\s*([a-zA-Z_]\w*)(?:\s*\((.*?)\))?(?:\s*,\s*(.*?))?(?:\s*->\s*([^;]+?))?\s*;//s
          )
        {
            my ( $prog, $pred, $args, $opts, $var ) =
              ( $1, $2, $3 // '', $4 // '', $5 );

            my $arg_str = $args;
            my @decls;
            while ( $arg_str =~ s/fresh\s+my\s+\$([a-zA-Z_]\w*)/\$$1/ ) {
                my $var_name = $1;
                push @decls,
"my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            }
            my $decls_code = join( "\n", @decls );
            my $opts_part = ( defined $opts && $opts =~ /\S/ ) ? ", $opts" : "";

            my $call_code =
"\$${prog}::PROGRAM->query( Logic::Relational::Goal::Call->new( '$pred', [ $arg_str ] ) $opts_part )";
            my $replacement;
            if ($var) {
                $replacement = "$decls_code\n$var = $call_code;\n";
            }
            else {
                $replacement = "do {\n$decls_code\n$call_code;\n};\n";
            }
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid query_prob syntax";
        }
    };

    # 9. query_dist keyword
    Keyword::Simple::define 'query_dist', sub ($src_ref) {
        if ( $$src_ref =~
s/\A\s*([a-zA-Z_]\w*)\s*::\s*([a-zA-Z_]\w*)(?:\s*\((.*?)\))?(?:\s*,\s*(.*?))?(?:\s*->\s*([^;]+?))?\s*;//s
          )
        {
            my ( $prog, $pred, $args, $opts, $var ) =
              ( $1, $2, $3 // '', $4 // '', $5 );

            my $arg_str = $args;
            my @decls;
            while ( $arg_str =~ s/fresh\s+my\s+\$([a-zA-Z_]\w*)/\$$1/ ) {
                my $var_name = $1;
                push @decls,
"my \$$var_name = Logic::Relational::DSL::variable('$var_name');";
            }
            my $decls_code = join( "\n", @decls );
            my $opts_part = ( defined $opts && $opts =~ /\S/ ) ? ", $opts" : "";

            my $call_code =
"\$${prog}::PROGRAM->query_distribution( Logic::Relational::Goal::Call->new( '$pred', [ $arg_str ] ) $opts_part )";
            my $replacement;
            if ($var) {
                $replacement = "$decls_code\n$var = $call_code;\n";
            }
            else {
                $replacement = "do {\n$decls_code\n$call_code;\n};\n";
            }
            $$src_ref = $replacement . $$src_ref;
        }
        else {
            croak "Invalid query_dist syntax";
        }
    };

    return;
}

sub _translate_rule_body ($body_str) {

    # Transform bare 0-arity predicates like "heads;" to "heads();"
    $body_str =~
s/(?:(?<=;)|(?<=\{)|(?<=\n)|(?<=\A))\s*(?!(?:true_goal|fail_goal)\b)([a-zA-Z_]\w*)\s*;/ $1(); /g;
    return Logic::Relational::Syntax::translate_body($body_str);
}

1;

__END__

=head1 NAME

Logic::Probabilistic::Syntax - Declarative hybrid syntax for probabilistic relational logic.

=head1 SYNOPSIS

    use v5.38;
    use Logic::Probabilistic::Syntax;

    prob_logic AlarmNet {
        pfacts {
            0.70 => burglary;
            0.20 => earthquake;
        }

        # First-order and propositional probabilistic rules
        prule 0.90 => alarm { burglary; earthquake; }
        prule 0.80 => alarm { burglary; not { earthquake; } }
        prule 0.10 => alarm { not { burglary; } earthquake; }

        facts {
            person('John');
            person('Mary');
        }

        prule 0.80 => calls($x) { alarm; person($x); }
        prule 0.10 => calls($x) { not { alarm; } person($x); }
    }

    # Point query with evidence conditioning
    my $res;
    query_prob AlarmNet::burglary,
        evidence => [ AlarmNet::calls('John') => 1, AlarmNet::calls('Mary') => 1 ]->$res;
    say "P(burglary | calls) = " . $res->probability;

    # Query discrete probability distributions
    fresh my $who;
    my $dist;
    query_dist AlarmNet::calls($who)->$dist;
    say $dist;

=head1 DESCRIPTION

Exports declarative keywords (C<prob_logic>, C<pfact>, C<pfacts>, C<pchoice>, C<rule>, C<prule>, C<fact>, C<facts>, C<fresh>,
C<table>, C<query_prob>, and C<query_dist>) via L<Keyword::Simple>.

=head1 PROGRAM INSTANCE ACCESS

Inside each C<prob_logic ModelName { ... }> declaration, an instance of
L<Logic::Probabilistic::Program> is automatically instantiated and stored in the package
variable C<our $PROGRAM>.

Just like in L<Logic::Relational>, this instance can be accessed:

=over 4

=item * B<Inside the block:> directly as C<$PROGRAM>.

=item * B<Outside the block:> via the fully qualified package variable C<$ModelName::PROGRAM>.

=back

This allows combining high-level declarative syntax with object-oriented program methods:

    # Direct query via object method
    my $result = $AlarmNet::PROGRAM->query('burglary');

    # Dynamic real-time parameter mutations
    $AlarmNet::PROGRAM->update_pfact(0.05, 'burglary');

    # Access the underlying relational logic engine
    my $rel_prog = $AlarmNet::PROGRAM->relational_program;

=cut
