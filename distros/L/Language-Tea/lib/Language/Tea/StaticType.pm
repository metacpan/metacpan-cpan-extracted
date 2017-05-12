package Language::Tea::StaticType;

use strict;
use warnings;

sub annotate_types {
    my ( $root, $Env ) = ( shift, shift );

    # add lexical scopes
    #print "\n\n\nAdd lexical scopes\n\n\n";
    {
        my $visitor;
        $visitor = sub {
            my ( $root, $parent, $outer ) = @_;

            #print "visit ",ref($_[0]),"\n";
            #print ref($root),"\n";

            $root->{pad} = \$outer;

            if (   ref($root) eq 'TeaPart::Define'
                || ref($root) eq 'TeaPart::DefineFunc' 
                || ref($root) eq 'TeaPart::Global'
                || ref($root) eq 'TeaPart::GlobalFunc' )
            {
                my $name = Language::Tea::Pad::mangle( $root->{arg_symbol} );

                #print "*** DEFINE $name \n";
                ${ $root->{pad} }->add_lexicals(
                    [ '$' . $name . "_TYPE_", '$' . $name . "_NAME_", ] );
            }

            if ( exists $root->{statement} ) {

                #die unless $outer->isa( 'Language::Tea::Pad' );
                my $inner = Language::Tea::Pad->new( outer => $outer );


                for my $key ( keys %$root ) {
                    next if $key eq '__node_parent__';

                    #print "visit $key\n";
                    Language::Tea::Traverse::visit_prefix( $root->{$key},
                        $visitor, $root, $inner );
                }

                #die;
                return $root;
            }

            return;
        };
        $root =
          Language::Tea::Traverse::visit_prefix( $root, $visitor, undef, $Env,
          );
    }


    #print "\n\n\nTipagem\n\n\n";

    $root = Language::Tea::Traverse::visit_postfix(
        $root,
        sub {

            #print "visit ",ref($_[0]),"\n";
            if ( ref $_[0] eq 'TeaPart::arg_string' ) {
                $_[0]->{type} = 'String';
            }
            if ( ref $_[0] eq 'TeaPart::arg_integer' ) {
                $_[0]->{type} = 'Integer';
            }
            if ( ref $_[0] eq 'TeaPart::arg_double' ) {
                $_[0]->{type} = 'Double';
            }
            if ( ref( $_[0] ) eq 'TeaPart::arg_code' ) {
                $_[0]->{type} = $_[0]->{arg_code}{statement}[-1]{type};
            }
            if ( ref( $_[0] ) eq 'TeaPart::arg_do' ) {
                $_[0]->{type} = $_[0]->{arg_do}{statement}[-1]{type};
            }
            if ( ref( $_[0] ) eq 'TeaPart::arg_list' ) {
                $_[0]->{type} = 'List';
            }
            if ( ref( $_[0] ) eq 'TeaPart::Apply' ) {
                my $func = $_[0]{func};

                my $result_type;
                if ( exists $func->{type} ) {
                    $result_type = $func->{type};
                }
                else {

                    # get arg types
                    my @args = @{ $_[0]{arg} };

                    my $func_name = $func->{arg_symbol};
                    if (   $func_name eq 'if'
                        || $func_name eq 'while'
                        || $func_name eq 'foreach' )
                    {
                        $result_type = $args[-1]{type};
                    }
                    else {

                        #print "func args @args \n";
                        my @types = ();
                        for (@args) {
                            push @types, $_->{type} || 'Object';
                        }

                        #print "func = $func_name  types = @types \n";
                        $result_type =
                          ${ $_[0]{pad} }->get_type( $func_name, @types );
                    }
                }

                #print "result_type = $result_type \n";
                #return $_[0];
                #$func->{type} = $result_type;
                $_[0]->{type} = $result_type;
            }
            if ( ref( $_[0] ) eq 'TeaPart::Define' || ref( $_[0] ) eq 'TeaPart::Global' ) {

                #my $old_type = ${$_[0]{pad}}->get_type( $_[0]->{arg_symbol} );

                # For variables defined without a value, assume TeaUnknowType
                # TODO: Inspect code to see the actual type.
                my $new_type;
                if ( exists $_[0]->{statement} && exists $_[0]->{statement}[0] )
                {
                    $new_type = $_[0]->{statement}[0]{type};
                }
                else {
                    $new_type = 'TeaUnknownType';
                }

                $_[0]->{type} = $new_type;

          #print "Define symbol: ",$_[0]->{arg_symbol}," ", $_[0]->{type} ,"\n";
          #print "in pad: ${$_[0]{pad}}\n";
                ${ $_[0]{pad} }->add_type( $_[0]->{arg_symbol}, $_[0]->{type} );

       #print "Define: name = ", ${$_[0]{pad}}->get_name( $_[0]->{arg_symbol} );
       #print "get name\n";
                $_[0]->{mangled} =
                  ${ $_[0]{pad} }->get_name( $_[0]->{arg_symbol} );
            }
            if ( ref( $_[0] ) eq 'TeaPart::DefineFunc' || ref( $_[0] ) eq 'TeaPart::GlobalFunc' ) {
                
                #my $old_type = ${$_[0]{pad}}->get_type( $_[0]->{arg_symbol} );               
                return unless ( exists $_[0]->{arg_code}{statement}[0]{type});  
                my $new_type = $_[0]->{arg_code}{statement}[-1]{type}; 
                $_[0]->{type} = $new_type;

            #print "Define func: ",$_[0]->{arg_symbol}," ", $_[0]->{type} ,"\n";
                ${ $_[0]{pad} }->add_type( $_[0]->{arg_symbol}, $_[0]->{type} );
                $_[0]->{mangled} =
                  ${ $_[0]{pad} }->get_name( $_[0]->{arg_symbol} );
            }
            if ( ref( $_[0] ) eq 'TeaPart::Dereference' ) {
                $_[0]->{type} =
                  ${ $_[0]{pad} }->get_type( $_[0]->{arg_symbol} );
                $_[0]->{mangled} =
                  ${ $_[0]{pad} }->get_name( $_[0]->{arg_symbol} );
            }
            if ( ref( $_[0] ) eq 'TeaPart::arg_symbol' ) {
                $_[0]->{mangled} =
                  ${ $_[0]{pad} }->get_name( $_[0]->{arg_symbol} );
            }
            if ( ref( $_[0] ) eq 'TeaPart::Method' ) {
                $_[0]->{type} = $_[0]->{arg}[-1]{type};

                # _class_method_METHOD
                my $symbol =
                    $_[0]->{class}{arg_symbol} . '_'
                  . $_[0]->{method}{arg_symbol}
                  . '_METHOD';

                #print "Add symbol: $symbol = ",$_[0]->{type},"\n";
                ${ $_[0]{pad} }->add_type( $symbol, $_[0]->{type} );
            }
            if ( ref( $_[0] ) eq 'TeaPart::Call' ) {

                #print "Call: \n";
                my $invocant = $_[0]->{invocant};
                my $method   = $_[0]->{method};
                my $class    = ${ $_[0]{pad} }->get_type( $_[0]->{invocant} );

                #print "Call: class $class\n";
                # _class_method_METHOD
                my $symbol = $class . '_' . $method . '_METHOD';
                #print $symbol."  Aki ta o symbol\n";
                $_[0]->{type} = ${ $_[0]{pad} }->get_type($symbol);
            }
            return;
        }
    );

    return $root;
}

1;
