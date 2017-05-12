package Language::Tea::ASTRefactor;

use strict;
use warnings;
use Language::Tea::Traverse;
use Language::Tea::StatementContext;
use Language::Tea::NodeUpLinker;
use Scalar::Util qw(blessed);

our $REFACTOR_VARIABLE = 0;

sub refactor {
    my $root = shift;
    Language::Tea::Traverse::visit_prefix(
        $root,
        sub {
            my ( $node, $parent ) = ( shift, shift );
            return if ref $node eq 'HASH';
            for ( ref $node ) {
                /^TeaPart::If$/ && do {

                    #warn "Reached an If...";
                    if ( $node->{context}{rvalue} ) {

                     # if as rvalue: Refactored to defining a variable that will
                     # be setted both in then and in else. This variable will be
                     # used in the place where the if was.
                        warn
"Refactoring rvalue if condition using temporary variable at $node->{info}{file} line $node->{info}{line}\n";

                 # we need to add lines in the code, so let's get to the closest
                 # liner to get its block.
                        my $walker = $node;
                        while ( !$walker->{context}{liner} ) {

                            #warn 'getting to the liner... '.ref $walker;
                            $walker = $walker->{__node_parent__};
                        }
                        my $block = $walker->{__node_parent__};

             #warn 'walker stopped at '.(ref $walker).' block is '.(ref $block);

                        my $name =
                          'refactoring_variable_' . $REFACTOR_VARIABLE++;

                        # Here we do a copy of the node to a new thing, because
                        # we'll re-bless the current node
                        my $ifstatement = bless { %{$node} }, 'TeaPart::If';
                        $ifstatement->{__node_parent__} = $block;
                        $ifstatement->{context}         = {
                            ireturn => 0,
                            rvalue  => 0,
                            liner   => 1
                        };

                        my $define_as_null = 0;

                        $node->{condition}{context}{rvalue} = 1;
                        $node->{condition}{__node_parent__} = $ifstatement;
                        $node->{then}{__node_parent__}      = $ifstatement;
                        my $ireturn_then =
                          $node->{then}{arg_code}{statement}[-1];
                        $ireturn_then->{context}{liner}  = 0;
                        $ireturn_then->{context}{rvalue} = 1;

                        $node->{then}{arg_code}{statement}[-1] = bless {
                            info            => { %{ $node->{info} } },
                            __node_parent__ => $node->{then}{arg_code},
                            context =>
                              { liner => 1, rvalue => 0, ireturn => 0 },
                            func => (
                                bless {
                                    info => { %{ $node->{info} } },
                                    context =>
                                      { liner => 0, rvalue => 0, ireturn => 0 },
                                    arg_symbol => 'set!',
                                },
                                'TeaPart::arg_symbol'
                            ),
                            arg => [
                                (
                                    bless {
                                        info    => { %{ $node->{info} } },
                                        context => {
                                            liner   => 0,
                                            rvalue  => 1,
                                            ireturn => 0
                                        },
                                        arg_symbol => $name
                                    },
                                    'TeaPart::arg_symbol'
                                ),
                                (
                                    bless {
                                        info    => { %{ $node->{info} } },
                                        context => {
                                            liner   => 0,
                                            rvalue  => 1,
                                            ireturn => 0
                                        },
                                        arg_do =>
                                          { statement => [$ireturn_then] },
                                    },
                                    'TeaPart::arg_do'
                                )
                            ]
                          },
                          'TeaPart::Apply';
                        $node->{then}{arg_code}{statement}[-1]{arg}[1]
                          {__node_parent__} =
                          $node->{then}{arg_code}{statement}[-1];

                        if ( exists $node->{else} and blessed $node->{else} ) {
                            $node->{else}{__node_parent__} = $ifstatement;
                            my $ireturn_else =
                              $node->{else}{arg_code}{statement}[-1];
                            $ireturn_else->{context}{liner}        = 0;
                            $ireturn_else->{context}{rvalue}       = 1;
                            $node->{else}{arg_code}{statement}[-1] = bless {
                                __node_parent__ => $node->{else}{arg_code},
                                info            => { %{ $node->{info} } },
                                context =>
                                  { liner => 1, rvalue => 0, ireturn => 0 },
                                func => (
                                    bless {
                                        info    => { %{ $node->{info} } },
                                        context => {
                                            liner   => 0,
                                            rvalue  => 0,
                                            ireturn => 0
                                        },
                                        arg_symbol => 'set!',
                                    },
                                    'TeaPart::arg_symbol'
                                ),
                                arg => [
                                    (
                                        bless {
                                            info    => { %{ $node->{info} } },
                                            context => {
                                                liner   => 0,
                                                rvalue  => 0,
                                                ireturn => 0
                                            },
                                            arg_symbol => $name
                                        },
                                        'TeaPart::arg_symbol'
                                    ),
                                    (
                                        bless {
                                            __node_parent__ =>
                                              $node->{else}{arg_code},
                                            info    => { %{ $node->{info} } },
                                            context => {
                                                liner   => 0,
                                                rvalue  => 1,
                                                ireturn => 0
                                            },
                                            arg_do =>
                                              { statement => [$ireturn_else] },
                                        },
                                        'TeaPart::arg_do'
                                    )
                                ]
                              },
                              'TeaPart::Apply';
                        }
                        else {
                            delete $ifstatement->{else};
                            $define_as_null = bless {}, 'TeaPart::arg_symbol';
                        }

                        $node->{arg_symbol} = $name;
                        delete $node->{condition};
                        delete $node->{then};
                        delete $node->{else};
                        $node->{context}{liner}  = 0;
                        $node->{context}{rvalue} = 1;
                        bless $node, 'TeaPart::arg_symbol';

                   # we know that a parent with a liner contains an entry called
                   # statement which is an array. So, let's find out which index
                   # is the walker in.
                        my $idx = 0;
                        my $arr;
                        $arr = $block->{arg_code}{statement}
                          if exists $block->{arg_code}
                          && ref $block->{arg_code}{statement} eq 'ARRAY';
                        unless ($arr) {
                            $arr = $block->{statement};
                        }
                        for ( @{$arr} ) {
                            if ( $_ == $walker ) {
                                last;
                            }
                            else {
                                $idx++;
                            }
                        }
                        splice @{$arr}, $idx, 0, (

                            # insert a comment explaining what happened
                            (
                                bless {
                                    context =>
                                      { liner => 1, rvalue => 0, ireturn => 0 },
                                    info => { %{ $node->{info} } },
                                    comment_text =>
                                      "Refactored from a rvalue if condition"
                                },
                                'TeaPart::Comment'
                            ),
                            (
                                bless {
                                    context =>
                                      { liner => 1, rvalue => 0, ireturn => 0 },
                                    info => { %{ $node->{info} } },
                                    comment_text =>
"at $node->{info}{file} line $node->{info}{line}"
                                },
                                'TeaPart::Comment'
                            ),

                            # define variable false
                            (
                                bless {
                                    context =>
                                      { liner => 1, rvalue => 0, ireturn => 0 },
                                    info       => { %{ $node->{info} } },
                                    arg_symbol => $name,
                                },
                                'TeaPart::Define'
                            ),

                            # block
                            $ifstatement
                        );
                        Language::Tea::NodeUpLinker::create_links($root);
                        Language::Tea::StatementContext::annotate_context(
                            $root);
                        refactor($root);
                        return $node;
                    }
                    elsif ( ref $node->{condition} eq 'TeaPart::arg_code' ) {
                        if (
                            scalar @{ $node->{condition}{arg_code}{statement} }
                            == 0 )
                        {
                            die
"Empty block in if condition at $node->{info}{file} line $node->{info}{line}\n";
                        }
                        elsif (
                            scalar @{ $node->{condition}{arg_code}{statement} }
                            == 1 )
                        {

                            # We can refactor this case to a arg_do instead of
                            # a arg_code.
                            warn
"Refactoring if condition from code block to substitution at $node->{info}{file} line $node->{info}{line}\n";
                            $node->{condition}{arg_do}{statement}[0] =
                              $node->{condition}{arg_code}{statement}[0];
                            bless $node->{condition}, 'TeaPart::arg_do';
                            $node->{condition}{arg_do}{statement}[0]{context}
                              {liner} = 0;
                        }
                        else {

                            # We can refactor this case to:
                            # a boolean variable declaration
                            # a code block wich sets that variable
                            # use that symbol as condition
                            warn
"Refactoring if condition using temporary variable and outside code block at $node->{info}{file} line $node->{info}{line}\n";
                            my $name =
                              'refactoring_variable_' . $REFACTOR_VARIABLE++;
                            $node->{condition}{arg_symbol} = $name;
                            my $condition = $node->{condition}{arg_code};
                            delete $node->{condition}{arg_code};
                            bless $node->{condition}, 'TeaPart::arg_symbol';

                            my $ireturn = $condition->{statement}[-1];
                            $ireturn->{context}{liner}  = 0;
                            $ireturn->{context}{rvalue} = 1;
                            $condition->{statement}[-1] = bless {
                                info => { %{ $node->{info} } },
                                context =>
                                  { liner => 1, rvalue => 0, ireturn => 0 },
                                func => (
                                    bless {
                                        info    => { %{ $node->{info} } },
                                        context => {
                                            liner   => 0,
                                            rvalue  => 0,
                                            ireturn => 0
                                        },
                                        arg_symbol => 'set!',
                                    },
                                    'TeaPart::arg_symbol'
                                ),
                                arg => [
                                    (
                                        bless {
                                            info    => { %{ $node->{info} } },
                                            context => {
                                                liner   => 0,
                                                rvalue  => 0,
                                                ireturn => 0
                                            },
                                            arg_symbol => $name
                                        },
                                        'TeaPart::arg_symbol'
                                    ),
                                    (
                                        bless {
                                            info    => { %{ $node->{info} } },
                                            context => {
                                                liner   => 0,
                                                rvalue  => 1,
                                                ireturn => 0
                                            },
                                            arg_do =>
                                              { statement => [$ireturn] },
                                        },
                                        'TeaPart::arg_do'
                                    )
                                ]
                              },
                              'TeaPart::Apply';

                        # Now let's get back to the parent, until we get a liner
                        # then get back one more, find where the liner is inside
                        # the parent, and then slice the array adding the new
                        # entries.
                            my $walker = $node;
                            while ( !$walker->{context}{liner} ) {
                                $walker = $walker->{__node_parent__};
                            }
                            my $block = $walker->{__node_parent__};

                            my $codeblock = bless {
                                __node_parent__ => $block,
                                context =>
                                  { liner => 1, rvalue => 0, ireturn => 0 },
                                arg_code => $condition,
                                info     => { %{ $node->{info} } },
                              },
                              'TeaPart::arg_code';

                            $condition->{__node_parent__} = $codeblock;

                   # we know that a parent with a liner contains an entry called
                   # statement which is an array. So, let's find out which index
                   # is the walker in.
                            my $arr;
                            $arr = $block->{arg_code}{statement}
                              if exists $block->{arg_code}
                              and ref $block->{arg_code}{statement} eq 'ARRAY';
                            unless ($arr) {
                                $arr = $block->{statement};
                            }
                            my $idx = 0;
                            for ( @{$arr} ) {
                                if ( $_ == $walker ) {
                                    last;
                                }
                                else {
                                    $idx++;
                                }
                            }

              # It's important to notice that this only works properly because
              # of this offset. As the visit_prefix here is index-based, we need
              # to make sure that it will get again to all of this and to this
              # children.
              # The comment here, besides helping the end user, makes sure the
              # ASTRefactor goes through all items.
                            splice @{$arr}, $idx, 0, (

                                # insert a comment explaining what happened
                                (
                                    bless {
                                        context => {
                                            liner   => 1,
                                            rvalue  => 0,
                                            ireturn => 0
                                        },
                                        info => { %{ $node->{info} } },
                                        comment_text =>
"Refactored from a multi-statements if condition"
                                    },
                                    'TeaPart::Comment'
                                ),
                                (
                                    bless {
                                        context => {
                                            liner   => 1,
                                            rvalue  => 0,
                                            ireturn => 0
                                        },
                                        info => { %{ $node->{info} } },
                                        comment_text =>
"at $node->{info}{file} line $node->{info}{line}"
                                    },
                                    'TeaPart::Comment'
                                ),

                                # define variable false
                                (
                                    bless {
                                        context => {
                                            liner   => 1,
                                            rvalue  => 0,
                                            ireturn => 0
                                        },
                                        info       => { %{ $node->{info} } },
                                        type       => 'Boolean',
                                        arg_symbol => $name,
                                        statement  => [ { type => 'Boolean' } ],
                                    },
                                    'TeaPart::Define'
                                ),

                                # block
                                $codeblock
                            );

                            Language::Tea::NodeUpLinker::create_links($root);
                            Language::Tea::StatementContext::annotate_context(
                                $root);
                            refactor($root);
                            return $node;
                        }
                    }
                    last;
                  }
            }
            return;
        },
        undef
    );
}

1;
