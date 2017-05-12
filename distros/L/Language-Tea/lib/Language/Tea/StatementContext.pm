package Language::Tea::StatementContext;

use strict;
use warnings;
use Language::Tea::Traverse;

sub annotate_context {
    my $root = shift;
    Language::Tea::Traverse::visit_prefix(
        $root,
        sub {
            my $node = shift;
            for ( ref $node ) {
                /^TeaProgram$/ && do {
                    $node->{context}{rvalue}  = 0;
                    $node->{context}{ireturn} = 0;
                    for ( @{ $node->{statement} } ) {
                        $_->{context}{rvalue}  = 0;
                        $_->{context}{ireturn} = 0;
                        $_->{context}{liner}   = 1;
                    }
                    last;
                };
                /^TeaPart::If$/ && do {
                    $node->{condition}{context}{rvalue}  = 1;
                    $node->{condition}{context}{ireturn} = 0;
                    if ( $node->{context}{rvalue} || $node->{context}{ireturn} )
                    {
                        $node->{then}{context}{rvalue} =
                          $node->{context}{rvalue};
                        $node->{else}{context}{rvalue} =
                          $node->{context}{rvalue};
                        $node->{then}{context}{ireturn} =
                          $node->{context}{ireturn};
                        $node->{else}{context}{ireturn} =
                          $node->{context}{ireturn};
                    }
                    last;
                };
                /^TeaPart::arg_code$/ && do {
                    my $last_statement;
                    for ( @{ $node->{arg_code}{statement} } ) {
                        $_->{context}{rvalue}  = 0;
                        $_->{context}{ireturn} = 0;
                        $_->{context}{liner}   = 1;
                        $last_statement        = $_;
                    }
                    if ( $node->{context}{rvalue} || $node->{context}{ireturn} )
                    {
                        $last_statement->{context}{rvalue}  = 0;
                        $last_statement->{context}{ireturn} = 1;
                    }
                    last;
                };
                /^TeaPart::Define$/ && do {
                    $node->{statement}[0]{context}{rvalue} = 1;
                    last;
                };
                /^TeaPart::Apply$/ && do {
                    for ( @{ $node->{arg} } ) {
                        $_->{context}{rvalue}  = 1;
                        $_->{context}{ireturn} = 0;
                    }
                    last;
                };
                /^TeaPart::New$/ && do {
                    unless ( $node->{context}{rvalue}
                        || $node->{context}{ireturn} )
                    {
                        warn
"Useless use of new in void context at $node->{info}{file} line $node->{info}{line}.\n";
                    }
                    for ( @{ $node->{arg} } ) {
                        $_->{context}{rvalue}  = 1;
                        $_->{context}{ireturn} = 0;
                    }
                    last;
                };
                /^TeaPart::arg_do$/ && do {
                    if ( $node->{context}{rvalue} || $node->{context}{ireturn} )
                    {
                        $node->{arg_do}{statement}[0]{context}{rvalue} =
                          $node->{context}{rvalue};
                        $node->{arg_do}{statement}[0]{context}{ireturn} =
                          $node->{context}{ireturn};
                    }
                    else {
                        warn
"Useless use of function substitution at $node->{info}{file} line $node->{info}{line}.\n";
                    }
                    last;
                };
                /^TeaPart::DefineFunc$/ && do {
                    $node->{context}{ireturn} = 1;
                    my $last_statement;
                    for ( @{ $node->{arg_code}{statement} } ) {
                        $_->{context}{rvalue}  = 0;
                        $_->{context}{ireturn} = 0;
                        $_->{context}{liner}   = 1;
                        $last_statement        = $_;
                    }
                    $last_statement->{context}{ireturn} = 1;
                    last;
                };
                /^TeaPart::Method$/ && do {                    
                    $node->{arg}[0]{context}{ireturn} = 1 if ( $node->{method}{arg_symbol} !~ /set.*/i && $node->{method}{arg_symbol} !~ /constructor/i);
                };
            }
            return;
        }
    );
}

1;
