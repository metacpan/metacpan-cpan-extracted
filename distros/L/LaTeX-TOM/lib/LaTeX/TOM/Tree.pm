###############################################################################
#
# LaTeX::TOM::Tree
#
# This package defines a TOM Tree object.
#
###############################################################################

package LaTeX::TOM::Tree;

use strict;

use Carp qw(croak);

our $VERSION = '0.04';

# "constructor"
#
sub new {
    my $class = shift;
    my $nodes = shift || []; # empty array for tree structure

    my $self = {
       nodes => $nodes,
    };

    return bless $self;
}

# make a copy of a tree, recursively
#
sub copy {
    my $tree = shift; # input tree

    my @output; # output array (to become tree)

    foreach my $node (@{$tree->{nodes}}) {

        # make a copy of the node's hash definition
        #
        my $nodecopy = $node->copy();

        # grab a copy of children, if any exist
        #
        if ($node->{children}) {
            my $children = $node->{children}->copy();
            $nodecopy->{children} = $children;
        }

        # add hashref to new node to array for this level
        push @output, $nodecopy;
    }

    # each subtree is a tree
    return __PACKAGE__->new([@output]);
}

sub print {
    shift->_debug_tree(@_, sub { print STDOUT $_[0] });
}
sub _warn {
    shift->_debug_tree(@_, sub { print STDERR $_[0] });
}

# Print out the LaTeX "TOM" tree. Good for debugging our parser.
#
sub _debug_tree {
    my $tree = shift;
    my $output_handler = pop;
    my ($level) = @_;

    $level ||= 0;

    foreach my $node (@{$tree->{nodes}}) {
        my $spacer = ' ' x ($level * 2);

        $output_handler->($spacer);

        # print grouping/command info
        if ($node->{type} eq 'COMMAND') {
            $output_handler->(sprintf
                "($node->{type}) \\$node->{command} %s @ [$node->{start}, $node->{end}]",
                  $node->{opts} ? "[$node->{opts}]" : "\b",
            );
        }

        elsif ($node->{type} eq 'GROUP') {
            $output_handler->("($node->{type}) [$node->{start}, $node->{end}]");
        }

        elsif ($node->{type} eq 'ENVIRONMENT') {
            $output_handler->("($node->{type}) $node->{class} @ inner [$node->{start}, $node->{end}] outer [$node->{ostart}, $node->{oend}]");
        }

        elsif ($node->{type} =~ /^(?:TEXT|COMMENT)$/) {
            my $space_out = do {
                local $_ = "$spacer $node->{type}	|";
                s/[A-Z]/ /go;
                $_;
            };
            my $max_len = 80 - length($space_out);
            my $print_text = do {
                local $_ = $node->{content};
                s/^(.{0,$max_len}).*$/$1/gm;
                s/\n/\n$space_out/gs;
                $_;
            };
            $output_handler->("($node->{type}) |$print_text\"");
        }

        $output_handler->(' ** math mode **') if $node->{math};
        $output_handler->(' ** plaintext **') if $node->{plaintext};

        $output_handler->("\n");

        # recur
        if (defined $node->{children}) {
            my ($wrapper) = (caller(1))[3] =~ /.+::(.+)$/;
            $node->{children}->$wrapper($level + 1);
        }
    }
}

# pull out the plain text (non-math) TEXT nodes. returns an array of strings.
#
sub plainText {
    my $tree = shift;

    my $stringlist = [];

    foreach my $node (@{$tree->{nodes}}) {

        if ($node->{type} eq 'TEXT' && $node->{plaintext}) {
            push @$stringlist, $node->{content};
        }

        if ($node->{children}) {
            push @$stringlist, @{$node->{children}->plainText()};
        }
    }

    return $stringlist;
}

# Get the plaintext of a LaTeX DOM and whittle it down into a word list
# suitable for indexing.
#
sub indexableText {
    my $tree = shift;

    my $pt = $tree->plainText();
    my $text = join (' ', @$pt);

    # kill leftover commands
    $text =~ s/\\\w+\*?//gso;

    # kill nonpunctuation
    $text =~ s/[^\w\-0-9\s]//gso;

    # kill non-intraword hyphens
    $text =~ s/(\W)\-+(\W)/$1 $2/gso;
    $text =~ s/(\w)\-+(\W)/$1 $2/gso;
    $text =~ s/(\W)\-+(\w)/$1 $2/gso;

    # kill small words
    $text =~ s/\b[^\s]{1,2}\b//gso;

    # kill purely numerical "words"
    $text =~ s/\b[0-9]+\b//gso;

    # compress whitespace
    $text =~ s/\s+/ /gso;

    return $text;
}

# Convert tree to LaTeX. If our output doesn't compile to the same final
# document, something is amiss (we don't, however, guarantee that the output
# TeX will be identical to the input, due to certain normalizations.)
#
sub toLaTeX {
    my $tree = shift;
    my $parent = shift;

    my $str = "";

    foreach my $node (@{$tree->{nodes}}) {

        if ($node->{type} eq 'TEXT' ||
                $node->{type} eq 'COMMENT') {

            $str .= $node->{content};
        }

        elsif ($node->{type} eq 'GROUP') {
            $str .= '{' . $node->{children}->toLaTeX($node) . '}';
        }

        elsif ($node->{type} eq 'COMMAND') {
            if ($node->{position} eq 'outer') {
                $str .= "\\$node->{command}" . '{' . $node->{children}->toLaTeX($node) . '}';
            }
            elsif ($node->{position} eq 'inner') {
                if (defined $parent && # dont add superfluous braces
                        $parent->{start} == $node->{start} &&
                        $parent->{end} == $node->{end}) {
                    $str .= "\\$node->{command}" . ' ' . $node->{children}->toLaTeX($node);
                } else {
                    $str .= '{' . "\\$node->{command}" . $node->{children}->toLaTeX($node) . '}';
                }
            }
            elsif ($node->{braces} == 0) {
                $str .= "\\$node->{command}" . ' ' . $node->{children}->toLaTeX($node);
            }
        }

        elsif ($node->{type} eq 'ENVIRONMENT') {
            # handle special math mode envs
            my $MATHBRACKETS = \%LaTeX::TOM::MATHBRACKETS;
            if (defined $MATHBRACKETS->{$node->{class}}) {
                # print with left and lookup right brace.
                $str .= $node->{class} . $node->{children}->toLaTeX($node) . $MATHBRACKETS->{$node->{class}};
            }

            # standard \begin/\end envs
            else {
                $str .= "\\begin{$node->{class}}" . $node->{children}->toLaTeX($node) . "\\end{$node->{class}}";
            }
        }
    }

    return $str;
}

# Augment the nodes in the tree with pointers to all neighboring nodes, so 
# traversal is easier for the user who is given a lone node.	This is a hack,
# we should really be maintaining this all along.
#
# Note that child pointers are already taken care of.
#
sub listify {
    my $tree = shift;
    my $parent = shift;

    for (my $i = 0; $i < scalar @{$tree->{nodes}}; $i++) {

        my $prev = undef;
        my $next = undef;

        $prev = $tree->{nodes}[$i - 1] if ($i > 0);
        $next = $tree->{nodes}[$i + 1] if ($i + 1 < scalar @{$tree->{nodes}});

        $tree->{nodes}[$i]->{'prev'} = $prev;
        $tree->{nodes}[$i]->{'next'} = $next;
        $tree->{nodes}[$i]->{'parent'} = $parent;

        # recur, with parent info
        if ($tree->{nodes}[$i]->{children}) {
            $tree->{nodes}[$i]->{children}->listify($tree->{nodes}[$i]);
        }
    }
}

###############################################################################
# "Tree walking" methods.
#

sub getTopLevelNodes {
    my $tree = shift;

    return @{$tree->{nodes}};
}

sub getAllNodes {
    my $tree = shift;

    my @nodelist;

    foreach my $node (@{$tree->{nodes}}) {

        push @nodelist, $node;

        if ($node->{children}) {
            push @nodelist, @{$node->{children}->getAllNodes()};
        }
    }

    return [@nodelist];
}

sub getNodesByCondition {
    my $tree = shift;
    my $condition = shift;

    # XXX rt #48551 - string eval no longer supported (12/08/2009)
    unless (ref $condition eq 'CODE') {
        croak 'getNodesByCondition(): code reference expected';
    }

    my @nodelist;

    foreach my $node (@{$tree->{nodes}}) {

        # evaluate the perl code condition and if the result evaluates to true,
        # push this node
        #
        if ($condition->($node)) {
            push @nodelist, $node;
        }

        if ($node->{children}) {
            push @nodelist, @{$node->{children}->getNodesByCondition($condition)};
        }
    }

    return [@nodelist];
}

sub getCommandNodesByName {
    my $tree = shift;
    my $name = shift;

    return $tree->getNodesByCondition(
        sub { my $node = shift; return ($node->{type} eq 'COMMAND' && $node->{command} eq $name); }
    );
}

sub getEnvironmentsByName {
    my $tree = shift;
    my $name = shift;

    return $tree->getNodesByCondition(
        sub { my $node = shift; return ($node->{type} eq 'ENVIRONMENT' && $node->{class} eq $name); }
    );
}

sub getFirstNode {
    my $tree = shift;
    return $tree->{nodes}[0];
}

1;
