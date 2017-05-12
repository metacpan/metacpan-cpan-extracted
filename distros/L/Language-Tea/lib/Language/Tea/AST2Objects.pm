package Language::Tea::AST2Objects;

use strict;
use warnings;

sub ast2objects {

    # select comment, define, dereference, method-apply or function-call
    # set native types
    return bless Language::Tea::Traverse::visit_postfix(
        $_[0],
        sub {
            if ( exists $_[0]{arg_string} ) {
                bless $_[0], 'TeaPart::arg_string';
            }
            if ( exists $_[0]{arg_integer} ) {
                bless $_[0], 'TeaPart::arg_integer';
            }
            if ( exists $_[0]{arg_double} ) {
                bless $_[0], 'TeaPart::arg_double';
            }
            if ( exists $_[0]{arg_do} ) {
                bless $_[0], 'TeaPart::arg_do';
            }
            if ( exists $_[0]{arg_code} ) {
                bless $_[0], 'TeaPart::arg_code';
            }
            if ( exists $_[0]{arg_substitution} ) {
                bless $_[0], 'TeaPart::arg_substitution';
            }
            if ( exists $_[0]{arg_list} ) {
                bless $_[0], 'TeaPart::arg_list';
            }
            if ( exists $_[0]{arg} && ref $_[0]{arg} eq 'ARRAY' ) {
                bless $_[0], 'TeaPart::definition_list';
            }
            if ( exists $_[0]{arg_symbol} && not exists $_[0]{define} ) {
                bless $_[0], 'TeaPart::arg_symbol';
            }
            if ( exists $_[0]{comment} && !exists $_[0]{arg} ) {

                # This is a comment line
                return bless $_[0]{comment}[0], 'TeaPart::Comment';
            }
            if ( exists $_[0]{statement} ) {

                #print ref $_[0]{statement},"\n";
                my @out_statement;
                for my $i ( 0 .. $#{ $_[0]{statement} } ) {
                    my $arg = $_[0]{statement}[$i];
                    if ( exists $arg->{comment} ) {
                        $arg->{comment} = bless $arg->{comment}[0],
                          'TeaPart::Comment';
                    }
                    if ( exists $arg->{define} && $arg->{define} eq "define") {
                        if ( exists $arg->{arg_list} ) {
                            $_[0]{statement}[$i]{arg_list} = { arg => [] }
                              unless ref $_[0]{statement}[$i]{arg_list};
                            bless {
                                arg_code => $_[0]{statement}[$i]{arg_code} },
                              'TeaPart::arg_code';
                            bless {
                                arg_list => $_[0]{statement}[$i]{arg_list} },
                              'TeaPart::arg_list';
                            bless $_[0]{statement}[$i], 'TeaPart::DefineFunc';
                        }
                        else {
                            bless $_[0]{statement}[$i], 'TeaPart::Define';
                        }
                    }
                    elsif ( exists $arg->{define} && $arg->{define} eq "global") {
                        if ( exists $arg->{arg_list} ) {
                            $_[0]{statement}[$i]{arg_list} = { arg => [] }
                              unless ref $_[0]{statement}[$i]{arg_list};
                            bless {
                                arg_code => $_[0]{statement}[$i]{arg_code} },
                              'TeaPart::arg_code';
                            bless {
                                arg_list => $_[0]{statement}[$i]{arg_list} },
                              'TeaPart::arg_list';
                            bless $_[0]{statement}[$i], 'TeaPart::GlobalFunc';
                        }
                        else {
                            bless $_[0]{statement}[$i], 'TeaPart::Global';
                        }
                    }
                    elsif ( exists $arg->{arg} ) {
                        my $first = shift @{ $arg->{arg} };

                        if ( exists $first->{arg_substitution} ) {                  
                            if ( @{ $arg->{arg} } ) {
                                $arg->{invocant} =
                                  $first->{arg_substitution}{arg_symbol};
                                $arg->{method} =
                                  ( shift @{ $arg->{arg} } )->{arg_symbol};
                                bless $_[0]{statement}[$i], 'TeaPart::Call';
                                ####################
                                #   Special case   #
                                ####################  
                                if ($arg->{invocant} eq "stdout" && $arg->{method} eq "writeln") {
                                    $arg->{invocant} = "System.out";
                                    $arg->{method} = "println";
                                }
                                    
                            }
                            else {
                                $arg->{arg_symbol} =
                                  $first->{arg_substitution}{arg_symbol};
                                bless $_[0]{statement}[$i],
                                  'TeaPart::Dereference';
                            }
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'new' )
                        {
                            $arg->{class} =
                              ( shift @{ $arg->{arg} } )->{arg_symbol};
                            $arg->{type}     = $arg->{class};
                            $arg->{arg_list} = $arg->{arg};
                            bless $_[0]{statement}[$i], 'TeaPart::New';
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'method' )
                        {
                            $arg->{class}  = ( shift @{ $arg->{arg} } );
                            $arg->{method} = ( shift @{ $arg->{arg} } );
                            $arg->{arg_list} =
                              ( shift @{ $arg->{arg} } )->{arg_list};

                            #$arg->{type} = $arg->{class};
                            bless $_[0]{statement}[$i], 'TeaPart::Method';
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'class' )
                        {
                            $arg->{class} = ( shift @{ $arg->{arg} } );
                            $arg->{super_class} = (shift @{ $arg->{arg} } )->{arg_symbol} if (defined $arg->{arg}[0]{arg_symbol}); 
                            $arg->{arg_list} =
                              ( shift @{ $arg->{arg} } )->{arg_list};

                            #$arg->{type} = $arg->{class};
                            bless $_[0]{statement}[$i], 'TeaPart::Class';
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'if' )
                        {
                            $arg->{condition} = ( shift @{ $arg->{arg} } );
                            $arg->{then}      = ( shift @{ $arg->{arg} } );
                            $arg->{else}      = ( shift @{ $arg->{arg} } );
                            bless $_[0]{statement}[$i], 'TeaPart::If';
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'cond' )
                        {
                            my $aux = (@{$arg->{arg}}) % 2;
                            for(my $i = 0; $i < (@{$arg->{arg}})-$aux;++$i){
                                $arg->{condition}[$i] = ( shift @{ $arg->{arg} } );
                                $arg->{instructions}[$i]      = ( shift @{ $arg->{arg} } );
                            }
                            $arg->{else}      = ( shift @{ $arg->{arg} } ) if ($aux); 
                            bless $_[0]{statement}[$i], 'TeaPart::Cond';
                        }
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'while' )
                        {
                            if (defined $arg->{arg}[0]{arg_code}{statement}[0]) {
                                $arg->{condition} =
                                ( shift @{ $arg->{arg} } )
                                ->{arg_code}{statement}[0] ;
                            } else {
                                $arg->{condition} =
                                ( shift @{ $arg->{arg} } );
                            }

                            $arg->{block} = ( shift @{ $arg->{arg} } );
                            bless $_[0]{statement}[$i], 'TeaPart::While';
                        } 
                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'foreach' )
                        {
                            $arg->{var1} = ( shift @{ $arg->{arg} } );
                            $arg->{var2} = ( shift @{ $arg->{arg} } );
#->{arg_code}{statement}[0];
                            $arg->{block} = ( shift @{ $arg->{arg} } );
                            bless $_[0]{statement}[$i], 'TeaPart::foreach';
                        }


                        elsif ( exists $first->{arg_symbol}
                            && $first->{arg_symbol} eq 'tea-autoload' )
                        {

                            # tea-autoload name sourceFile
                            die
"sourceFile must be a string, in /tea-autoload name sourceFile/"
                              unless exists $arg->{arg}[1]{'arg_string'};
                            my $filename = $arg->{arg}[1]{'arg_string'};

                            my $root = Main::compile($filename);

                            push @out_statement, @{ $root->{statement} };
                            next;

                        }
                        elsif ( exists $first->{arg_do} ) {
                            $arg->{arg_do} = $first->{arg_do};
                            bless $_[0]{statement}[$i], 'TeaPart::arg_do';
                        }
                        else {
                            $arg->{func} = $first;
                            bless $_[0]{statement}[$i], 'TeaPart::Apply';
                            
                            #########################################
                            # Functions that need special treatment #
                            #########################################
                            
                            if ( exists $first->{arg_symbol}
                                && $first->{arg_symbol} eq 'url-build' )
                            {
                                my @list     = @{$arg->{arg}[1]->{arg_list}{arg}};
                                my @auxiliar;
                                foreach ( @list) {
                                        foreach (@{$_->{arg_list}{arg}}) {
                                                #print  $values[$i]->[$j++] . "\n" ;                                                
                                                push @auxiliar,  $_;
                                        }
                                }
                                $arg->{arg} = [$arg->{arg}[0], @auxiliar];
                            }
                            
                        }
                    }
                    push @out_statement, $_[0]{statement}[$i];
                }
                $_[0]{statement} = \@out_statement;
                return;
            }
            return;
        }
      ),
      "TeaProgram";
}

1;
