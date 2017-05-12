###############################################################################
#
# LaTeX::TOM::Parser
#
# The parsing class
#
###############################################################################

package LaTeX::TOM::Parser;

use strict;
use base qw(
    LaTeX::TOM::Node
    LaTeX::TOM::Tree
);
use constant true  => 1;
use constant false => 0;

use Carp qw(carp croak);
use File::Basename qw(fileparse);

our $VERSION = '0.07';

my %error_handlers = (
    0 => sub { warn "parse error: $_[0].\n" },
    1 => sub { die  "parse error: $_[0].\n" },
    2 => sub {},
);

# Constructor
#
sub new {
    my $class = shift;

    no strict 'refs';

    my $self = bless {
        config => {
            BRACELESS          => \%{"${class}::BRACELESS"},
            INNERCMDS          => \%{"${class}::INNERCMDS"},
            MATHENVS           => \%{"${class}::MATHENVS"},
            MATHBRACKETS       => \%{"${class}::MATHBRACKETS"},
            PARSE_ERRORS_FATAL =>  ${"${class}::PARSE_ERRORS_FATAL"},
            TEXTENVS           => \%{"${class}::TEXTENVS"},
        },
    };

    $self->_init(@_);

    return $self;
}

# Set/reset "globals"
#
sub _init {
    my $parser = shift;
    my ($parse_errors_fatal, $readinputs, $applymappings) = @_;

    my $retrieve_opt_default = sub
    {
        my ($opt, $default) = @_;
        return $opt if defined $opt;
        return $default;
    };

    # set user options
    #
    $parser->{readinputs}         = $retrieve_opt_default->($readinputs, 0);
    $parser->{applymappings}      = $retrieve_opt_default->($applymappings, 0);
    $parser->{PARSE_ERRORS_FATAL} = $retrieve_opt_default->($parse_errors_fatal, $parser->{config}{PARSE_ERRORS_FATAL});

    # init internal stuff
    #
    $parser->{MATHBRACKETS} = $parser->{config}{MATHBRACKETS};

    # this will hold a running list/hash of commands that have been remapped
    $parser->{MAPPEDCMDS} = {};

    # this will hold a running list/hash of commands that have been used. We dont
    # bother apply mappings except to commands that have been used.
    $parser->{USED_COMMANDS} = {};

    # no file yet
    $parser->{file} = undef;
}

# Parse a LaTeX file, return a tree. You probably want this method.
#
sub parseFile {
    my $parser = shift;
    my $filename = shift;

    # init variables
    #
    $parser->{file} = $filename;        # file name member data
    my $tree = {};                      # init output tree

    # read in text from file or bomb out
    #
    my $text = _readFile($filename, true);

    # do the parse
    #
    $tree = $parser->parse($text);

    return $tree;
}

# main parsing entrypoint
#
sub parse {
    my $parser = shift;
    my ($text) = @_;

    # first half of parsing (goes up to finding commands, reading inputs)
    #
    my ($tree, $bracehash) = $parser->_parseA($text);
    _debug(
        'done with _parseA',
         sub { $tree->_warn() },
    );

    # handle mappings
    #
    $parser->_applyMappings($tree) if $parser->{applymappings};
    _debug(
        'done with _applyMappings',
         sub { $tree->_warn() },
    );

    # second half of parsing (environments)
    #
    $parser->_parseB($tree);
    _debug(
        'done with _parseB',
         sub { $tree->_warn() },
    );

    # once all the above is done we can propegate math/plaintext modes down
    #
    $parser->_propegateModes($tree, 0, 0);   # math = 0, plaintext = 0
    _debug(
        'done with _propegateModes',
         sub { $tree->_warn() },
    );

    # handle kooky \[ \] math mode
    #
    if (not exists $parser->{MAPPEDCMDS}->{'\\['}) {
        # math mode (\[ \], \( \))
        $parser->_stage5($tree, {'\\[' => '\\]', '\\(' => '\\)'}, 1);
        $parser->_propegateModes($tree, 0, 0);     # have to do this again of course
        $parser->{MATHBRACKETS}->{'\\['} = '\\]';  # put back in brackets list for
        $parser->{MATHBRACKETS}->{'\\('} = '\\)';  # printing purposes.
    }
    _debug(
        undef,
        sub { $tree->_warn() },
    );

    $tree->listify;     # add linked-list stuff

    return $tree;
}

# Parsing with no mappings and no externally accessible parser object.
#
sub _basicparse {
    my $parser = shift; # @_ would break code
    my $text   = shift;

    my $parse_errors_fatal = (defined $_[0] ? $_[0] : $parser->{config}{PARSE_ERRORS_FATAL});
    my $readinputs = (defined $_[1] ? $_[1] : 1);

    $parser = LaTeX::TOM::Parser->new($parse_errors_fatal, $readinputs);
    my ($tree, $bracehash) = $parser->_parseA($text); 

    $parser->_parseB($tree);

    $tree->listify; # add linked-list stuff

    return ($tree, $bracehash);
}

# start the tree. separate out comment and text nodes.
#
sub _stage1 {
    my $parser = shift;
    my $text = shift;

    my @nodes = _getTextAndCommentNodes($text, 0, length($text));

    return LaTeX::TOM::Tree->new([@nodes]);
}

# this stage parses the braces ({}) and adds the corresponding structure to
# the tree.
#
sub _stage2 {
    my $parser = shift;

    my $tree = shift;
    my $bracehash = shift || undef;
    my $startidx = shift || 0;      # last two params for starting at some specific
    my $startpos = shift || 0;      # node and offset.

    my %blankhash;

    if (not defined $bracehash) {
        $bracehash = {%blankhash};
    }

    my $leftidx = -1;
    my $leftpos = -1;
    my $leftcount = 0;

    # loop through the nodes
    for (my $i = $startidx; $i < @{$tree->{nodes}}; $i++) {
        my $node = $tree->{nodes}[$i];
        my $spos = $node->{start};	# get text start position 

        # set position placeholder within the text block
        my $pos = ($i == $startidx) ? $startpos : 0;

        if ($node->{type} eq 'TEXT') {

         _debug("parseStage2: looking at text node: [$node->{content}]", undef);

         my ($nextpos, $brace) = _findbrace($node->{content}, $pos);
         while ($nextpos != -1) {

            $pos = $nextpos + 1; # update position pointer

            # handle left brace
            if ($brace eq '{') {
                _debug("found '{' at position $nextpos, leftcount is $leftcount", undef);
                if ($leftcount == 0) {
                    $leftpos = $nextpos;
                    $leftidx = $i
                }
                $leftcount++;
            }

            # handle right brance
            elsif ($brace eq '}') {

                _debug("found '}' at position $nextpos, leftcount is $leftcount", undef);
                my $rightpos = $nextpos;
                $leftcount--;

                # found the corresponding right brace to our starting left brace
                if ($leftcount == 0) {

                    # see if we have to split the text node into 3 parts
                    #
                    if ($leftidx == $i) {

                        my ($leftside, $textnode3) = $node->split($rightpos, $rightpos);
                        my ($textnode1, $textnode2) = $leftside->split($leftpos, $leftpos);

                        # make the new GROUP node
                        my $groupnode = LaTeX::TOM::Node->new(
                            {type => 'GROUP',
                             start => $textnode2->{start} - 1,
                             end => $textnode2->{end} + 1,
                             children => LaTeX::TOM::Tree->new([$textnode2]),
                            });

                        # splice the new subtree into the old location
                        splice @{$tree->{nodes}}, $i, 1, $textnode1, $groupnode, $textnode3;

                        # add to the brace-pair lookup table
                        $bracehash->{$groupnode->{start}} = $groupnode->{end};
                        $bracehash->{$groupnode->{end}} = $groupnode->{start};

                        # recur into new child node
                        $parser->_stage2($groupnode->{children}, $bracehash);

                        $i++; # skip to textnode3 for further processing
                    }

                    # split across nodes
                    #
                    else {

                        my ($textnode1, $textnode2) = $tree->{nodes}[$leftidx]->split($leftpos, $leftpos);
                        my ($textnode3, $textnode4) = $node->split($rightpos, $rightpos);

                        # remove nodes in between the node we found '{' in and the node
                        # we found '}' in
                        #
                        my @removed = splice @{$tree->{nodes}}, $leftidx+1, $i-$leftidx-1;

                        # create a group node that contains the text after the left brace,
                        # then all the nodes up until the next text node, then the text
                        # before the right brace.
                        #
                        my $groupnode = LaTeX::TOM::Node->new(
                            {type => 'GROUP',
                             start => $textnode2->{start} - 1,
                             end => $textnode3->{end} + 1,
                             children => LaTeX::TOM::Tree->new(
                                [$textnode2,
                                 @removed,
                                 $textnode3]),
                            });

                        # replace the two original text nodes with the leftover left and
                        # right portions, as well as the group node with everything in
                        # the middle.
                        #
                        splice @{$tree->{nodes}}, $leftidx, 2, $textnode1, $groupnode, $textnode4;

                        # add to the brace-pair lookup table
                        $bracehash->{$groupnode->{start}} = $groupnode->{end};  
                        $bracehash->{$groupnode->{end}} = $groupnode->{start};

                        # recur into new child nodes
                        $parser->_stage2($groupnode->{children}, $bracehash);

                        # step back to textnode4 on this level for further processing
                        $i -= scalar @removed;
                    }

                    $leftpos = -1; # reset left data
                    $leftidx = -1;
                    last;
                } # $leftcount == 0

                # check for '}'-based error
                #
                if ($leftcount < 0) {
                    $error_handlers{$parser->{PARSE_ERRORS_FATAL}}->("'}' before '{' at " . ($spos + $rightpos));
                    $leftcount = 0; # reset and continue
                }
            } # right brace

            ($nextpos, $brace) = _findbrace($node->{content}, $pos);

         } # while (braces left)

         } # if TEXT

    } # loop over all nodes

    # check for extra '{' parse error
    #
    if ($leftcount > 0) {
        my $spos = $tree->{nodes}[$leftidx]->{start}; # get text start position
        $error_handlers{$parser->{PARSE_ERRORS_FATAL}}->("unmatched '{' at " . ($spos + $leftpos));

        # try to continue on, after the offending brace
        $parser->_stage2($tree, $bracehash, $leftidx, $leftpos + 1);
    }

    return $bracehash;
}

# this stage finds LaTeX commands and accordingly turns GROUP nodes into
# command nodes, labeled with the command
#
sub _stage3 {
    my $parser = shift;

    my $tree = shift;
    my $parent = shift;

    for (my $i = 0; $i< @{$tree->{nodes}}; $i++) {

        my $node = $tree->{nodes}[$i];

        # check text node for command tag
        if ($node->{type} eq 'TEXT') {
            my $text = $node->{content};

            # inner command (such as {\command text text}). our regexp checks to see
            # if this text chunk begins with \command, since that would be the case
            # due to the previous parsing stages. if found, the parent node is
            # promoted to a command.
            #
            if ($text =~ /^\s*\\(\w+\*?)/ && defined $parent && $parser->{config}{INNERCMDS}->{$1}) {
                my $command = $1;

                # if the parent is already a command node, we have to make a new
                # nested command node
                #
                if ($parent->{type} eq 'COMMAND') {

                    # make a new command node
                    my $newnode = LaTeX::TOM::Node->new(
                        {type => 'COMMAND',
                         command => $command,
                         start => $parent->{start},
                         end => $parent->{end},
                         position => 'inner',
                         children => $parent->{children} });

                    # point parent to it
                    $parent->{children} = LaTeX::TOM::Tree->new([$newnode]);

                    # start over at this level (get additional inner commands)
                    $parent = $newnode;
                    $i = -1;

                    $parser->{USED_COMMANDS}->{$newnode->{command}} = 1;
                }

                # parent is a naked group, we can make it into a command node
                #
                elsif ($parent->{type} eq 'GROUP') {
                    $parent->{type} = 'COMMAND';
                    $parent->{command} = $command;
                    $parent->{position} = 'inner';

                    # start over at this level
                    $i = -1;

                    $parser->{USED_COMMANDS}->{$parent->{command}} = 1;
                }

                $node->{content} =~ s/^\s*\\(?:\w+\*?)//o;
            }

            # outer command (such as \command{parameters}). our regexp checks to
            # see if this text chunk ends in \command, since that would be the case
            # due to the previous parsing stages.
            #
            if ($text =~ /(?:^|[^\\])(\\\w+\*?(\s*\[.*?\])?)\s*$/os && 
                    defined $tree->{nodes}[$i+1] &&
                    $tree->{nodes}[$i+1]->{type} eq 'GROUP') {

                my $tag = $1;

                _debug("found text node [$text] with command tag [$tag]", undef);

                # remove the text
                $node->{content} =~ s/\\\w+\*?\s*(?:\[.*?\])?\s*$//os;

                # parse it for command and ops
                $tag =~ /^\\(\w+\*?)\s*(?:\[(.*?)\])?$/os;

                my $command = $1;
                my $opts = $2;

                # make the next node a command node with the above data
                my $next = $tree->{nodes}[$i+1];

                $next->{type} = 'COMMAND';
                $next->{command} = $command;
                $next->{opts} = $opts;
                $next->{position} = 'outer';

                $parser->{USED_COMMANDS}->{$next->{command}} = 1;
            }

            # recognize braceless commands
            #
            if ($text =~ /(\\(\w+\*?)[ \t]+(\S+))/gso || $text =~ /(\\(\w+)(\d+))/gso) {
                my $all = $1;
                my $command = $2;
                my $param = $3;

                if ($parser->{config}{BRACELESS}->{$command}) {
                 # warn "found braceless command $command with param $param";

                    # get location to split from node text
                    my $a = index $node->{content}, $all, 0;
                    my $b = $a + length($all) - 1;

                    # make all the new nodes

                    # new left and right text nodes
                    my ($leftnode, $rightnode) = $node->split($a, $b);

                    # param contents node
                    my $pstart = index $node->{content}, $param, $a;
                    my $newchild = LaTeX::TOM::Node->new(
                        {type => 'TEXT',
                         start => $node->{start} + $pstart,
                         end => $node->{start} + $pstart + length($param) - 1,
                         content => $param });

                    # new command node
                    my $commandnode = LaTeX::TOM::Node->new(
                        {type => 'COMMAND',
                         braces => 0,
                         command => $command,
                         start => $node->{start} + $a,
                         end => $node->{start} + $b,
                         children => LaTeX::TOM::Tree->new([$newchild]),
                        });

                    $parser->{USED_COMMANDS}->{$commandnode->{command}} = 1;

                    # splice these all into the original array  
                    splice @{$tree->{nodes}}, $i, 1, $leftnode, $commandnode, $rightnode;

                    # make the rightnode the node we're currently analyzing
                    $node = $rightnode;

                    # make sure outer loop will continue parsing *after* rightnode
                    $i += 2;
                }
            }
        }

        # recur
        if ($node->{type} eq 'GROUP' ||
            $node->{type} eq 'COMMAND') {

            $parser->_stage3($node->{children}, $node);
        }
    }
}

# this stage finds \begin{x} \end{x} environments and shoves their contents 
#	down into a new child node, with a parent node of ENVIRONMENT type.
# 
# this has the effect of making the tree deeper, since much of the structure
#	is in environment tags and will now be picked up.
# 
# for ENVIRONMENTs, "start" means the ending } on the \begin tag, 
# "end" means the starting \ on the \end tag,
# "ostart" is the starting \ on the "begin" tag,
# "oend" is the ending } on the "end" tag, and
# and "class" is the "x" from above.
#
sub _stage4 {
    my $parser = shift;
    my $tree = shift;

    my $bcount = 0; # \begin "stack count"
    my $class = ""; # environment class
    my $bidx = 0;   # \begin array index.

    for (my $i = 0; $i < @{$tree->{nodes}}; $i++) {
        my $node = $tree->{nodes}->[$i];

        # see if this is a "\begin" command node
        if ($node->{type} eq 'COMMAND' && $node->{command} eq 'begin') {

            _debug("parseStage4: found a begin COMMAND node, $node->{children}->{nodes}[0]->{content} @ $node->{start}", undef);

            # start a new "stack"
            if ($bcount == 0) {
                $bidx = $i;
                $bcount++;
                $class = $node->{children}->{nodes}->[0]->{content}; 
                _debug("parseStage4: opening environment tag found, class = $class", undef);
            }

            # add to the "stack"
            elsif ($node->{children}->{nodes}->[0]->{content} eq $class) {
                $bcount++;
                _debug("parseStage4: incrementing tag count for $class", undef);
            }
        }

        # handle "\end" command nodes
        elsif ($node->{type} eq 'COMMAND' &&
               $node->{command} eq 'end' &&
               $node->{children}->{nodes}->[0]->{content} eq $class) {

            $bcount--;
            _debug("parseStage4: decrementing tag count for $class", undef);

            # we found our closing "\end" tag. replace everything with the proper
            # ENVIRONMENT tag and subtree.
            #
            if ($bcount == 0) {

                _debug("parseStage4: closing environment $class", undef);

                # first we must take everything between the "\begin" and "\end" 
                # nodes and put them in a new array, removing them from the old one
                my @newarray = splice @{$tree->{nodes}}, $bidx+1, $i - ($bidx + 1);

                # make the ENVIRONMENT node
                my $start = $tree->{nodes}[$bidx]->{end};
                my $end = $node->{start};
                my $envnode = LaTeX::TOM::Node->new(
                    {type => 'ENVIRONMENT',
                     class => $class,
                     start => $start, # "inner" start and end
                     end => $end,
                     ostart => $start - length('begin') - length($class) - 2,
                     oend => $end + length('end') + length($class) + 2,
                     children => LaTeX::TOM::Tree->new([@newarray]),
                    });

                if ($parser->{config}{MATHENVS}->{$envnode->{class}}) {
                    $envnode->{math} = 1;
                }

                # replace the \begin and \end COMMAND nodes with the single 
                # environment node
                splice @{$tree->{nodes}}, $bidx, 2, $envnode;

                $class = ""; # reset class.

                # i is going to change by however many nodes we removed
                $i -= scalar @newarray;

                # recur into the children
                $parser->_stage4($envnode->{children});	
            }
        }

        # recur in general
        elsif ($node->{children}) {
            $parser->_stage4($node->{children});
        }
    }

    # parse error if we're missing an "\end" tag.
    if ($bcount > 0) {
        $error_handlers{$parser->{PARSE_ERRORS_FATAL}}->(
            "missing \\end{$class} for \\begin{$class} at position $tree->{nodes}[$bidx]->{end}"
        );
    }
}

# This is the "math" stage: here we grab simple-delimeter math modes from
# the text they are embedded in, and turn those into new groupings, with the
# "math" flag set.
#
# having this top level to go over all the bracket types prevents some pretty
# bad combinatorial explosion
#
sub _stage5 {
    my $parser = shift;

    my $tree = shift;
    my $caremath = shift || 0;

    my $brackets = $parser->{MATHBRACKETS};

    # loop through all the different math mode bracket types
    foreach my $left (sort {length($b) <=> length($a)} keys %$brackets) {
        my $right = $brackets->{$left};

        $parser->_stage5_r($tree, $left, $right, $caremath);
    }
}

# recursive meat of above
#
sub _stage5_r {
    my $parser = shift;

    my $tree = shift;
    my $left = shift;
    my $right = shift;
    my $caremath = shift || 0; # do we care if we're already in math mode?
                               # this matters for \( \), \[ \]

    my $leftpos = -1; # no text pos for found left brace yet.
    my $leftidx = -1; # no array index for found left brace yet.

        # loop through the nodes
        for (my $i = 0; $i < scalar @{$tree->{nodes}}; $i++) {
            my $node = $tree->{nodes}[$i];
            my $pos = 0; # position placeholder within the text block
            my $spos = $node->{start}; # get text start position

            if ($node->{type} eq 'TEXT' && 
               (!$caremath || (!$node->{math} && $caremath))) {

                # search for left brace if we haven't started a pair yet
                if ($leftidx == -1) {
                    $leftpos = _findsymbol($node->{content}, $left, $pos);

                    if ($leftpos != -1) {
                        _debug("found (left) $left in [$node->{content}]", undef);
                        $leftidx = $i;
                        $pos = $leftpos + 1; # next pos to search from
                    }
                }

                # search for a right brace
                if ($leftpos != -1) {
                    my $rightpos = _findsymbol($node->{content}, $right, $pos);

                    # found
                    if ($rightpos != -1) {

                        # we have to split the text node into 3 parts
                        if ($leftidx == $i) {
                            _debug("splitwithin: found (right) $right in [$node->{content}]", undef);

                            my ($leftnode, $textnode3) = $node->split($rightpos, $rightpos + length($right) - 1);
                            my ($textnode1, $textnode2) = $leftnode->split($leftpos, $leftpos + length($left) - 1);

                            my $startpos = $spos; # get text start position 

                            # make the math ENVIRONMENT node
                            my $mathnode = LaTeX::TOM::Node->new(
                                {type => 'ENVIRONMENT',
                                class => $left,	# use left delim as class
                                math => 1,
                                start => $startpos + $leftpos,
                                ostart => $startpos + $leftpos - length($left) + 1,
                                end => $startpos + $rightpos,
                                oend => $startpos + $rightpos + length($right) - 1,
                                children => LaTeX::TOM::Tree->new([$textnode2]),
                                });

                            splice @{$tree->{nodes}}, $i, 1, $textnode1, $mathnode, $textnode3;

                            $i++; # skip ahead two nodes, so we'll be parsing textnode3
                        }

                        # split across nodes
                        else {

                            _debug("splitacross: found (right) $right in [$node->{content}]", undef);

                            # create new set of 4 smaller text nodes from the original two
                            # that contain the left and right delimeters
                            #
                            my ($textnode1, $textnode2) = $tree->{nodes}[$leftidx]->split($leftpos, $leftpos + length($left) - 1);
                            my ($textnode3, $textnode4) = $tree->{nodes}[$i]->split($rightpos, $rightpos + length($right) - 1);

                            # nodes to remove "from the middle" (between the left and right
                            # text nodes which contain the delimeters)
                            #
                            my @remnodes = splice @{$tree->{nodes}}, $leftidx+1, $i - $leftidx - 1;

                            # create a math node that contains the text after the left brace,
                            # then all the nodes up until the next text node, then the text
                            # before the right brace.
                            #
                            my $mathnode = LaTeX::TOM::Node->new(
                                {type => 'ENVIRONMENT',
                                class => $left,
                                math => 1,
                                start => $textnode2->{start} - 1,
                                end => $textnode3->{end} + 1,
                                ostart => $textnode2->{start} - 1 - length($left) + 1,
                                oend => $textnode3->{end} + 1 + length($right) - 1,
                                children => LaTeX::TOM::Tree->new(
                                [$textnode2,
                                 @remnodes,
                                 $textnode3]),
                                });

                            # replace (TEXT_A, ... , TEXT_B) with the mathnode created above
                            splice @{$tree->{nodes}}, $leftidx, 2, $textnode1, $mathnode, $textnode4;

                            # do all nodes again but the very leftmost
                            #
                            $i = $leftidx;
                        }

                        $leftpos = -1; # reset left data    
                        $leftidx = -1;
                    } # right brace
                } # left brace 
                else {

                    my $rightpos = _findsymbol($node->{content}, $right, $pos);

                    if ($rightpos != -1) {
                        my $startpos = $node->{start}; # get text start position
                        $error_handlers{$parser->{PARSE_ERRORS_FATAL}}->("unmatched '$right' at " . ($startpos + $rightpos));
                    }
                }
            } # if TEXT

            # recur, but not into verbatim environments!
            #
            elsif ($node->{children} && 
                         !(
                             ($node->{type} eq 'COMMAND' && $node->{command} =~ /^verb/) ||
                             ($node->{type} eq 'ENVIRONMENT' && $node->{class} =~ /^verbatim/))) {

                if ($LaTeX::TOM::DEBUG) {
                    my $message  = "Recurring into $node->{type} node ";
                       $message .= $node->{command} if ($node->{type} eq 'COMMAND');
                       $message .= $node->{class}   if ($node->{type} eq 'ENVIRONMENT');
                    _debug($message, undef);
                }

                $parser->_stage5_r($node->{children}, $left, $right, $caremath);
            }

        } # loop over text blocks

        if ($leftpos != -1) {
            my $startpos = $tree->{nodes}[$leftidx]->{start};   # get text start position
            $error_handlers{$parser->{PARSE_ERRORS_FATAL}}->("unmatched '$left' at " . ($startpos + $leftpos));
        }
}

# This stage propegates the math mode flag and plaintext flags downward.
#
# After this is done, we can make the claim that only text nodes marked with
# the plaintext flag should be printed.	math nodes will have the "math" flag,
# and also plantext = 0.
#
sub _propegateModes {
    my $parser = shift;

    my $tree = shift;
    my $math = shift;       # most likely want to call this with 0
    my $plaintext = shift;  # ditto this-- default to nothing visible.

    foreach my $node (@{$tree->{nodes}}) {

        # handle text nodes on this level. set flags.
        #
        if ($node->{type} eq 'TEXT') {
            $node->{math} = $math;
            $node->{plaintext} = $plaintext;
        }

        # propegate flags downward, possibly modified
        #
        elsif (defined $node->{children}) {

            my $mathflag = $math;    # math propegates down by default
            my $plaintextflag = 0;   # plaintext flag does NOT propegate by default

            # handle math or plain text forcing envs
            #
            if ($node->{type} eq 'ENVIRONMENT' || $node->{type} eq 'COMMAND') {
                if (defined $node->{class} && (
                    $parser->{config}{MATHENVS}->{$node->{class}} ||
                    $parser->{config}{MATHENVS}->{"$node->{class}*"})
                   )
                {
                    $mathflag = 1;
                    $plaintextflag = 0;
                }
                elsif (($node->{type} eq 'COMMAND' && 
                                ($parser->{config}{TEXTENVS}->{$node->{command}} ||
                                 $parser->{config}{TEXTENVS}->{"$node->{command}*"})) ||
                             ($node->{type} eq 'ENVIRONMENT' && 
                                ($parser->{config}{TEXTENVS}->{$node->{class}} ||
                                 $parser->{config}{TEXTENVS}{"$node->{command}*"}))
                            ) {

                    $mathflag = 0;
                    $plaintextflag = 1;
                }
            }

            # groupings change nothing
            #
            elsif ($node->{type} eq 'GROUP') {
                $mathflag = $math;
                $plaintextflag = $plaintext;
            }

            # recur
            $parser->_propegateModes($node->{children}, $mathflag, $plaintextflag);
        }
    }
}

# apply a mapping to text nodes in a tree
#
# for newcommands and defs: mapping is a hash:
#
# {name, nparams, template, type}
#
# name is a string
# nparams is an integer
# template is a tree fragement containing text nodes with #x flags, where
# parameters will be replaced.
# type is "command"
#
# for newenvironments:
#
# {name, nparams, btemplate, etemplate, type}
#
# same as above, except type is "environment" and there are two templates,
# btemplate and etemplate.
#
sub _applyMapping {
    my $parser = shift;

    my $tree = shift;
    my $mapping = shift;
    my $i = shift || 0;  # index to start with, in tree.

    my $applications = 0; # keep track of # of applications

    for (; $i < @{$tree->{nodes}}; $i++) {

        my $node = $tree->{nodes}[$i];

        # begin environment nodes
        #
        if ($node->{type}                            eq 'COMMAND'
         && $node->{command}                         eq 'begin'
         && $node->{children}->{nodes}[0]->{content} eq $mapping->{name}
        ) {
            # grab the nparams next group nodes as parameters
            #
            my @params = ();

            my $remain = $mapping->{nparams};
            my $j = 1;
            while ($remain > 0 && ($i + $j) < scalar @{$tree->{nodes}}) {

                my $node = $tree->{nodes}[$i + $j];

                # grab group node
                if ($node->{type} eq 'GROUP') {
                    push @params, $node->{children};
                    $remain--;
                }

                $j++;
            }

            # if we didn't get enough group nodes, bomb out
            next if $remain;

            # otherwise make new subtree
            my $applied = _applyParamsToTemplate($mapping->{btemplate}, @params);

            # splice in the result
            splice @{$tree->{nodes}}, $i, $j, @{$applied->{nodes}};

            # skip past all the new stuff
            $i += scalar @{$applied->{nodes}} - 1;
        }

        # end environment nodes
        #
        elsif ($node->{type}                            eq 'COMMAND'
            && $node->{command}                         eq 'end'
            && $node->{children}->{nodes}[0]->{content} eq $mapping->{name}
        ) {
            # make new subtree (no params)
            my $applied = $mapping->{etemplate}->copy();

            # splice in the result
            splice @{$tree->{nodes}}, $i, 1, @{$applied->{nodes}};

            # skip past all the new stuff
            $i += scalar @{$applied->{nodes}} - 1;

            $applications++; # only count end environment nodes
        }

        # newcommand nodes
        #
        elsif ($node->{type}       eq 'COMMAND'
            && $node->{command}    eq $mapping->{name}
            && $mapping->{nparams}
        ) {
            my @params = ();

            # children of COMMAND node will be first parameter
            push @params, $node->{children};

            # find next nparams GROUP nodes and push their children onto @params
            my $remain = $mapping->{nparams} - 1;
            my $j = 1;
            while ($remain > 0 && ($i + $j) < scalar @{$tree->{nodes}}) {

                my $node = $tree->{nodes}[$i + $j];

                # grab group node
                if ($node->{type} eq 'GROUP') {
                    push @params, $node->{children};
                    $remain--;
                }

                $j++;
            }

            # if we didn't get enough group nodes, bomb out
            next if ($remain > 0);

            # apply the params to the template
            my $applied = _applyParamsToTemplate($mapping->{template}, @params);

            # splice in the result
            splice @{$tree->{nodes}}, $i, $j, @{$applied->{nodes}};

            # skip past all the new stuff
            $i += scalar @{$applied->{nodes}} - 1;

            $applications++;
        }

        # find 0-param mappings
        elsif ($node->{type} eq 'TEXT' && !$mapping->{nparams}) {

             my $text = $node->{content};
             my $command = $mapping->{name};

             # find occurrences of the mapping command
             #
             my $wordend = ($command =~ /\w$/ ? 1 : 0); 
             while (($wordend && $text =~ /\\\Q$command\E(\W|$)/g) ||
                            (!$wordend && $text =~ /\\\Q$command\E/g)) {

                 _debug("found occurrence of mapping $command", undef);

                 my $idx = index $node->{content}, '\\' . $command, 0;

                 # split the text node at that command
                 my ($leftnode, $rightnode) = $node->split($idx, $idx + length($command));

                 # copy the mapping template
                 my $applied = $mapping->{template}->copy();

                 # splice the new nodes in
                 splice @{$tree->{nodes}}, $i, 1, $leftnode, @{$applied->{nodes}}, $rightnode;

                 # adjust i so we end up on rightnode when we're done
                 $i += scalar @{$applied->{nodes}} + 1;

                 # get the next node
                 $node = $tree->{$node}[$i];

                 # count application
                 $applications++;
             }
        }

        # recur
        elsif ($node->{children}) {

            $applications += $parser->_applyMapping($node->{children}, $mapping);
        }
    }

    return $applications;
}

# find and apply all mappings in the tree, progressively and recursively.
# a mapping applies to the entire tree and subtree consisting of nodes AFTER
# itself in the level array.
#
sub _applyMappings {
    my $parser = shift;

    my $tree = shift;

    for (my $i = 0; $i < @{$tree->{nodes}}; $i++) {

        my $prev = $tree->{nodes}[$i-1];
        my $node = $tree->{nodes}[$i];

        # find newcommands
        if ($node->{type} eq 'COMMAND' &&
                $node->{command} =~ /^(re)?newcommand$/) {

            my $mapping = _makeMapping($tree, $i); 
            next if (!$mapping->{name}); # skip fragged commands

            if ($parser->{USED_COMMANDS}->{$mapping->{name}}) {
                _debug("applying (nc) mapping $mapping->{name}", undef);
            } else {
                _debug("NOT applying (nc) mapping $mapping->{name}", undef);
                next;
            }

            # add to mappings list
            #
            $parser->{MAPPEDCMDS}->{"\\$mapping->{name}"} = 1;

            _debug("found a mapping with name $mapping->{name}, $mapping->{nparams} params", undef);

            # remove the mapping declaration
            #
            splice @{$tree->{nodes}}, $i, $mapping->{skip} + 1;

            # apply the mapping
            my $count = $parser->_applyMapping($tree, $mapping, $i);

            if ($count > 0) {
                _debug("printing altered subtree", sub { $tree->_warn() });
            }

            $i--; # since we removed the cmd node, check this index again
        }

        # handle "\newenvironment" mappings
        elsif ($node->{type} eq 'COMMAND' &&
                 $node->{command} =~ /^(re)?newenvironment$/) {

            # make a mapping hash
            #
            my $mapping = $parser->_makeEnvMapping($tree, $i);
            next if (!$mapping->{name}); # skip fragged commands.

            _debug("applying (ne) mapping $mapping->{name}", undef);

            # remove the mapping declaration
            #
            splice @{$tree->{nodes}}, $i, $mapping->{skip} + 1;

            # apply the mapping
            #
            my $count = $parser->_applyMapping($tree, $mapping, $i);
        }

        # handle "\def" stype commands.
        elsif ($node->{type} eq 'COMMAND' &&
                 defined $prev &&
                 $prev->{type} eq 'TEXT' &&
                 $prev->{content} =~ /\\def\s*$/o) {

             _debug("found def style mapping $node->{command}", undef);

             # remove the \def
             $prev->{content} =~ s/\\def\s*$//o;

             # make the mapping
             my $mapping = {name => $node->{command},
                nparams => 0,
                template => $node->{children}->copy(),
                type => 'command'};

             next if (!$mapping->{name}); # skip fragged commands

             if ($parser->{USED_COMMANDS}->{$mapping->{name}}) {
                 _debug("applying (def) mapping $mapping->{name}", undef);
             } else {
                 _debug("NOT applying (def) mapping $mapping->{name}", undef);
                 next;
             }

             # add to mappings list
             #
             $parser->{MAPPEDCMDS}->{"\\$mapping->{name}"} = 1;

             _debug("template is", sub { $mapping->{template}->_warn() });

             # remove the command node
             splice @{$tree->{nodes}}, $i, 1;

             # apply the mapping
             my $count = $parser->_applyMapping($tree, $mapping, $i);

             $i--; # check this index again
        }

        # recur
        elsif ($node->{children}) {

            $parser->_applyMappings($node->{children});
        }
    }
}

# read files from \input commands and place into the tree, parsed
#
# also include bibliographies
#
sub _addInputs {
    my $parser = shift;

    my $tree = shift;

    for (my $i = 0; $i < @{$tree->{nodes}}; $i++) {

        my $node = $tree->{nodes}[$i];

        if ($node->{type}    eq 'COMMAND'
         && $node->{command} eq 'input'
        ) {
            my $file = $node->{children}->{nodes}[0]->{content};
            next if $file =~ /pstex/; # ignore pstex images

            _debug("reading input file $file", undef);

            my $contents;
            my $filename = fileparse($file);
            my $has_extension = qr/\.\S+$/;

            # read in contents of file
            if (-e $file && $filename =~ $has_extension) {
                $contents = _readFile($file);
            }
            elsif ($filename !~ $has_extension) {
                $file = "$file.tex";
                $contents = _readFile($file) if -e $file;
            }

            # dump Psfig/TeX files, they aren't useful to us and have
            # nonconforming syntax. Use declaration line as our heuristic.
            #
            if (defined $contents
                     && $contents =~ m!^ \% \s*? Psfig/TeX \s* $!mx
            ) {
                undef $contents;
                carp "ignoring Psfig input `$file'";
            }

            # actually do the parse of the sub-content
            #
            if (defined $contents) {
                # parse into a tree
                my ($subtree,) = $parser->_basicparse($contents, $parser->{PARSE_ERRORS_FATAL});

                # replace \input command node with subtree
                splice @{$tree->{nodes}}, $i, 1, @{$subtree->{nodes}};

                # step back
                $i--;
            }
        }
        elsif ($node->{type}    eq 'COMMAND'
            && $node->{command} eq 'bibliography'
        ) {
             # try to find a .bbl file
             #
             foreach my $file (<*.bbl>) {

                 my $contents = _readFile($file);

                 if (defined $contents) {

                     my ($subtree,) = $parser->_basicparse($contents, $parser->{PARSE_ERRORS_FATAL});
                     splice @{$tree->{nodes}}, $i, 1, @{$subtree->{nodes}};
                     $i--;
                 }
             }
        }

        # recur
        if ($node->{children}) {
            $parser->_addInputs($node->{children});
        }
    }
}

# do pre-mapping parsing
#
sub _parseA {
    my $parser = shift;
    my $text = shift;

    my $tree = $parser->_stage1($text);
    my $bracehash = $parser->_stage2($tree);

    $parser->_stage3($tree);

    $parser->_addInputs($tree) if $parser->{readinputs};

    return ($tree, $bracehash);
}

# do post-mapping parsing (make environments)
#
sub _parseB {
    my $parser = shift;
    my $tree = shift;

    $parser->_stage4($tree);

    _debug("done with parseStage4", undef);

    $parser->_stage5($tree, 0);

    _debug("done with parseStage5", undef);
}

###############################################################################
#
# Parser "Static" Subroutines
#
###############################################################################

# find next unescaped char in some text
#
sub _uindex {
    my $text = shift;
    my $char = shift;
    my $pos = shift;

    my $realbrace = 0;
    my $idx = -1;

    # get next opening brace
    do {
        $realbrace = 1;
        $idx = index $text, $char, $pos; 

        if ($idx != -1) {
            $pos = $idx + 1;
            my $prevchar = substr $text, $idx - 1, 1;
            if ($prevchar eq '\\') {
                $realbrace = 0;
                $idx = -1;
            }
        }
    } while (!$realbrace);

    return $idx;
}

# support function: find the next occurrence of some symbol which is 
# not escaped.
#
sub _findsymbol {
    my $text = shift;
    my $symbol = shift;
    my $pos = shift;

    my $realhit = 0; 
    my $index = -1;

    # get next occurrence of the symbol
    do {
        $realhit = 1;
        $index = index $text, $symbol, $pos; 

        if ($index != -1) {
            $pos = $index + 1;

            # make sure this occurrence isn't escaped. this is imperfect.
            #
            my $prevchar = ($index - 1 >= 0) ? 
                                             (substr $text, $index - 1, 1) : '';
            my $pprevchar = ($index - 2 >= 0) ?
                                             (substr $text, $index - 2, 1) : '';
            if ($prevchar eq '\\' && $pprevchar ne '\\') {
                $realhit = 0;
                $index = -1;
            }
        }
    } while (!$realhit);

    return $index;
}

# support function: find the earliest next brace in some (flat) text
#
sub _findbrace {
    my $text = shift;
    my $pos = shift;

    my $realbrace = 0;
    my $index_o = -1;
    my $index_c = -1;

    my $pos_o = $pos;
    my $pos_c = $pos;

    # get next opening brace
    do {
        $realbrace = 1;
        $index_o = index $text, '{', $pos_o;

        if ($index_o != -1) {
            $pos_o = $index_o + 1;

            # make sure this brace isn't escaped. this is imperfect.
            #
            my $prevchar = ($index_o - 1 >= 0) ? 
                (substr $text, $index_o - 1, 1) : '';
            my $pprevchar = ($index_o - 2 >= 0) ?
                (substr $text, $index_o - 2, 1) : '';

            if ($prevchar eq '\\' && $pprevchar ne '\\') {
                $realbrace = 0;
                $index_o = -1;
            }
        }
    } while (!$realbrace);

    # get next closing brace
    do {
        $realbrace = 1;
        $index_c = index $text, '}', $pos_c;

        if (($index_c - 1) >= 0 && substr($text, $index_c - 1, 1) eq ' ') {
            $pos_c = $index_c + 1;
            $index_c = -1;
        }

        if ($index_c != -1) {
            $pos_c = $index_c + 1;

            # make sure this brace isn't escaped. this is imperfect.
            #
            my $prevchar = ($index_c - 1 >= 0) ? 
                (substr $text, $index_c - 1, 1) : '';
            my $pprevchar = ($index_c - 2 >= 0) ?
                (substr $text, $index_c - 2, 1) : '';

            if ($prevchar eq '\\' && $pprevchar ne '\\') {
                $realbrace = 0;
                $index_c = -1;
            }
        }
    } while (!$realbrace);

    # handle all find cases
    return (-1, '') if ($index_o == -1 && $index_c == -1);
    return ($index_o, '{') if ($index_c == -1 || 
        ($index_o != -1 && $index_o < $index_c));

    return ($index_c, '}') if ($index_o == -1 || $index_c < $index_o);
}


# skip "blank nodes" in a tree, starting at some position. will finish 
# at the first non-blank node. (ie, not a comment or whitespace TEXT node.
#
sub _skipBlankNodes {
    my $tree = shift;
    my $i = shift;

    while ($tree->{nodes}[$i]->{type} eq 'COMMENT' ||
        ($tree->{nodes}[$i]->{type} eq 'TEXT' &&
        $tree->{nodes}[$i]->{content} =~ /^\s*$/s)) { 

        $i++;
    }

    return $i;
}

# is the passed-in node a valid parameter node? for this to be true, it must
# either be a GROUP or a position = inner command.
#
sub _validParamNode {
    my $node = shift;

    return 1 if ($node->{type} eq 'GROUP' || 
        ($node->{type} eq 'COMMAND' && $node->{position} eq 'inner'));

    return 0;
}

# duplicate a valid param node.	This means for a group, copy the child tree.
# for a command, make a new tree with just the command node and its child tree.
#
sub _duplicateParam {
    my $parser = shift;
    my $node = shift;

    if ($node->{type} eq 'GROUP') {
        return $node->{children}->copy();
    }
    elsif ($node->{type} eq 'COMMAND') {

        my $subtree = $node->{children}->copy(); # copy child subtree
        my $nodecopy = $node->copy(); # make a new node with old data
        $nodecopy->{children} = $subtree; # set the child pointer to new subtree

        # return a new tree with the new node (subtree) as its only element
        return LaTeX::TOM::Tree->new([$nodecopy]);
    }

    return undef;
}

# make a mapping from a newenvironment fragment
#
# newenvironments have the following syntax:
#
# \newenvironment{name}[nparams]?{beginTeX}{endTeX}
#
sub _makeEnvMapping {
    my $parser = shift;
    my $tree   = shift;
    my $i      = shift;

    return undef if ($tree->{nodes}[$i]->{type} ne 'COMMAND' ||
        ($tree->{nodes}[$i]->{command} ne 'newenvironment' &&
        $tree->{nodes}[$i]->{command} ne 'renewenvironment'));

    # figure out command (first child, text node)
    my $command = $tree->{nodes}[$i]->{children}->{nodes}[0]->{content};
    if ($command =~ /^\s*\\(\S+)\s*$/) {
        $command = $1;
    }

    my $next = $i+1;

    # figure out number of params
    my $nparams = 0;
    if ($tree->{nodes}[$next]->{type} eq 'TEXT') {
        my $text = $tree->{nodes}[$next]->{content};

        if ($text =~ /^\s*\[\s*([0-9])+\s*\]\s*$/) {
            $nparams = $1;
        }

        $next++;
    }

    # default templates-- just repeat the declarations
    #
    my ($btemplate) = $parser->_basicparse("\\begin{$command}", 2, 0);
    my ($etemplate) = $parser->_basicparse("\\end{$command}", 2, 0);

    my $endpos = $next;

    # get two group subtrees... one for the begin and one for the end 
    # templates. we only ignore whitespace TEXT nodes and comments
    #
    $next = _skipBlankNodes($tree, $next);
    if (_validParamNode($tree->{nodes}[$next])) {
        $btemplate = $parser->_duplicateParam($tree->{nodes}[$next]);
        $next++;

        $next = _skipBlankNodes($tree, $next);

        if (_validParamNode($tree->{nodes}[$next])) {
            $etemplate = $parser->_duplicateParam($tree->{nodes}[$next]);
            $endpos = $next;
        }
    }

    # build and return the mapping hash
    #
    return {name => $command,
        nparams => $nparams,
        btemplate => $btemplate,    # begin template
        etemplate => $etemplate,    # end template
        skip => $endpos - $i,
        type => 'environment'};
}

# make a mapping from a newcommand fragment 
# takes tree pointer and index of command node
#
# newcommands have the following syntax:
#
# \newcommand{\name}[nparams]?{anyTeX}
#
sub _makeMapping {
    my $tree = shift;
    my $i = shift;

    return undef if ($tree->{nodes}[$i]->{type} ne 'COMMAND' ||
        ($tree->{nodes}[$i]->{command} ne 'newcommand' &&
        $tree->{nodes}[$i]->{command} ne 'renewcommand'));

    # figure out command (first child, text node)
    my $command = $tree->{nodes}[$i]->{children}->{nodes}[0]->{content}; 
    if ($command =~ /^\s*\\(\S+)\s*$/) {
        $command = $1;
    }

    my $next = $i+1;

    # figure out number of params
    my $nparams = 0;
    if ($tree->{nodes}[$next]->{type} eq 'TEXT') {
        my $text = $tree->{nodes}[$next]->{content};

        if ($text =~ /^\s*\[\s*([0-9])+\s*\]\s*$/) {
            $nparams = $1;
        }

        $next++;
    }

    # grab subtree template (array ref)
    #
    my $template;
    if ($tree->{nodes}[$next]->{type} eq 'GROUP') {
        $template = $tree->{nodes}[$next]->{children}->copy();
    } else {
        return undef;
    }

    # build and return the mapping hash
    #
    return {name => $command,
        nparams => $nparams,
        template => $template,
        skip => $next - $i,
        type => 'command'};
}

# this sub is the main entry point for the sub that actually takes a set of
# parameter trees and inserts them into a template tree. the return result,
# newly allocated, should be plopped back into the original tree where the
# parameters (along with the initial command invocation)
#
sub _applyParamsToTemplate {
    my $template = shift;
    my @params = @_;

    # have to copy the template to a freshly allocated tree
    #
    my $applied = $template->copy();

    # now recursively apply the params.
    #
    _applyParamsToTemplate_r($applied, @params);

    return $applied;
}

# recursive helper for above
#
sub _applyParamsToTemplate_r {
    my $template = shift;
    my @params = @_;

    for (my $i = 0; $i < @{$template->{nodes}}; $i++) {

        my $node = $template->{nodes}[$i];

        if ($node->{type} eq 'TEXT') {

            my $text = $node->{content};

            # find occurrences of the parameter flags
            #
            if ($text =~ /(#([0-9]+))/) {

                my $all = $1;
                my $num = $2;

                # get the index of the flag we just found
                #
                my $idx = index $text, $all, 0;

                # split the node on the location of the flag
                #
                my ($leftnode, $rightnode) = $node->split($idx, $idx + length($all) - 1);

                # make a copy of the param we want
                #
                my $param = $params[$num - 1]->copy();

                # splice the new text nodes, along with the parameter subtree, into
                # the old location
                #
                splice @{$template->{nodes}}, $i, 1, $leftnode, @{$param->{nodes}}, $rightnode;

                # skip forward to where $rightnode is in $template on next iteration
                #
                $i += scalar @{$param->{nodes}};
            }
        }

        # recur
        elsif (defined $node->{children}) {

            _applyParamsToTemplate_r($node->{children}, @params);
        }
    }
}


# This sub takes a chunk of the document text between two points and makes 
# it into a list of TEXT nodes and COMMENT nodes, as we would expect from 
# '%' prefixed LaTeX comment lines
#
sub _getTextAndCommentNodes {
    my ($text, $begins, $ends) = @_;

    my $node_text = substr $text, $begins, $ends - $begins;

    _debug("getTextAndCommentNodes: looking at [$node_text]", undef);

    my $make_node = sub {
        my ($mode_type, $begins, $start_pos, $output) = @_;

        return LaTeX::TOM::Node->new({
            type    => uc $mode_type,
            start   => $begins + $start_pos,
            end     => $begins + $start_pos + length($output) - 1,
            content => $output,
        });
    };

    my @lines = split (/(
       (?:\s*     # whitespace
         (?<!\\)  # unescaped
         \%[^\n]* # comment
       \n)+       # newline
    )/mx, $node_text);

    my @nodes;

    my $start_pos = 0;
    my $output;
    my $mode_type;
    my $first = true;

    foreach my $line (@lines) {

         my $line_type = (
                 $line =~ /^\s*\%/
         && $node_text !~ /
                           \\begin\{verbatim\}
                             .* \Q$line\E .*
                           \\end\{verbatim\}
                          /sx
        ) ? 'comment' : 'text';

        # if type stays the same, add to output and do nothing
        if ($first || $line_type eq $mode_type) {

            $output .= $line;

            # handle turning off initialization stuff
            $first &&= false;
            $mode_type ||= $line_type;
        }

        # if type changes, make new node from current chunk, change mode type
        # and start a new chunk
        else {
            push @nodes, $make_node->($mode_type, $begins, $start_pos, $output);

            $start_pos += length($output); # update start position
            $output = $line;

            $mode_type = $line_type;
        }
    }

    push @nodes, $make_node->($mode_type, $begins, $start_pos, $output) if defined $output;

    return @nodes;
}

# Read in the contents of a text file on disk. Return in string scalar.
#
sub _readFile {
    my ($file, $raise_error) = @_;

    $raise_error ||= false;

    my $opened = open(my $fh, '<', $file);

    unless ($opened) {
        croak "Cannot open $file: $!" if $raise_error;
        return undef;
    }

    my $contents = do { local $/; <$fh> };
    close($fh);

    return $contents;
}

sub _debug {
    my ($message, $code) = @_;

    my $DEBUG = $LaTeX::TOM::DEBUG;

    return unless $DEBUG >= 1 && $DEBUG <= 2;

    my ($filename, $line) = (caller)[1,2];
    my $caller = join ':', (fileparse($filename))[0], $line;

    warn "$caller: $message\n" if $DEBUG >= 1 && defined $message;
    $code->()                  if $DEBUG == 2 && defined $code;
}

1;
