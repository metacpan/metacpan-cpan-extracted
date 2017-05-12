package HTML::Persistent::HTML;

#
# Importer and exporter of HTML text into/out-of database.
#
# For parsing it needs the HTML::TreeBuilder but converts from treebuilder style of
# objects over to internal style storage.
#
# For export (printing), a fairly simple recursion is used.
#

use strict;
use warnings;
use Carp;

use HTML::Parser ();

sub new
{
	my $class = shift;
	my $self  = {};
	my $node = shift;
	my $p = $self->{parser} = HTML::Parser->new(
		api_version => 3,
		start_h => [ sub { $self->start( @_ )}, "tagname, attr" ],
		end_h   => [ sub { $self->end( @_ )},   "tagname" ],
		text_h  => [ sub { $self->text( @_ )},  "dtext" ],
		marked_sections => 1,
	);
	$p->unbroken_text( 1 );
	$p->empty_element_tags( 1 );
	$self->{stack} = [{ ix => -1, node => $node, tag => '' }];
	bless( $self, $class );
	return $self;
}

sub parse
{
	my $self = shift;
	my $chunk = shift;
	my $p = $self->{parser};
	$p->parse( $chunk );
}

sub eof
{
	my $self = shift;
	my $p = $self->{parser};
	$p->eof();
}

#
# HTML is not guaranteed a perfect tree, but a tree-like structure is useful at times
# so certain tags will stack onto other tags, although the default behaviour is just
# to stack up a long array with no particular structure.
#
# Tags listed here have the effect of always pushing to the stack, and we expect
# that they will always have a closing tag to match them. If closing tags are out
# of order then it will force the thing to match up, so for example:
#
#      <body>xxx<table>yyy</body>zzz</table>
#
# Turns into a nesting like:
#
# <body>xxx
#     <table>yyy
# </body>zzz
# </table>
#
# Where the </table> closing tag is just bolted onto the end. You can detect this
# and barf at the incorrect nesting if you like.
# Other tags, not in this list just degrade to linear tag soup.
#
my $html_nest =
{
	# These are presumed 100% nestable and clean (although some should not be used that way)
	'html' => {},
	'head' => {},
	'body' => {},
	'table' => {},

	# Stuff that should be inside HEAD section
	'link' => { close => [ 'link', 'meta' ], stopat => [ 'html', 'head' ]},
	'meta' => { close => [ 'link', 'meta' ], stopat => [ 'html', 'head' ]},
	'title' => { close => [ 'title', 'meta', 'link' ], stopat => [ 'html', 'head' ]},

	# These are not properly nestable, they exist in a particular heirarchy
	'tbody' => { close => [ 'tbody', 'tr', 'td' ], stopat => [ 'table', 'body', 'html' ]},
	'tr' => { close => [ 'tr', 'td' ], stopat => [ 'table', 'body', 'html' ]},
	'td' => { close => [ 'td' ], stopat => [ 'table', 'body', 'tr', 'html' ]},
	'ul' => {},
	'li' => { close => [ 'li' ], stopat => [ 'ul' ]},

	# These are not nestable, because HTML is spac
	# I think <p> is same as <span>
	'div' => { close => [ 'center', 'div', 'span', 'p' ]},
	'center' => { close => [ 'center', 'div', 'span', 'p' ]},
	'span' => { close => [ 'span', 'p' ], stopat => [ 'div' ]},
	'p' => { close => [ 'span', 'p' ], stopat => [ 'div' ]},
};

#
# Provide a list of restricted tags, if provided then only these tags are allowed
#
sub restrict
{
	my $self = shift;
	my $r = $self->{restrict} = {};
	foreach ( @_ )
	{
		$r->{$_} = 1;
	}
}

#
# Inject fake closing tags to tidy things up a bit.
# Also has the effect of ignoring the real closing tags when we don't like their placement
#
sub fake_close_tags
{
	my $self = shift;
	my $r = $self->{fake_close_tags} = 1;
}

#
# Every node gets fed through the output transformer function,
# then the return value of the transformer can be:
# -- undef : do nothing, output as usual
# -- string or number : output this value instead of the expected output
# -- node : output this (different) node (and sub-nodes) instead of expected output
# -- '' : output nothing (prune the node and all subnodes)
#
# The typical design would be to assign an id="whatever" to the HTML tag,
# and make the transformer trigger a substitution when it meets up with 
# particular id values. This might be a typical usage scenario:
#
# $html->output_transformer( sub {
#	my $node = shift;
#	my $id = $node->{id} || '';
#	return( '<p>replacement</p>' ) if( $id eq 'whatever' );
#	return( '<p>different replacement</p>' ) if( $id eq 'something-else' );
#	return( undef );
#  });
#
# To avoid stress with HTML closer tags, make sure they are subordinate to the opener.
# Actually, that should be default behaviour when reading <---- FIXME
#
sub output_transformer
{
	my $self = shift;
	my $coderef = shift;
	$self->{otran} = $coderef;
}

#
# Scan down the stack and pop a matching tag if we find one...
# The "stopat" tag array (can be undef) might reduce the depth of popping.
#
sub pop_matching
{
	my $self = shift;             # Standard OO format
	my $tag = shift;              # Pop any tags that match this one
	my $stopat = shift;           # Array of tags that block our popper
	my $real_close = shift;       # If a real close tag exists, then don't try to fake it
	my $stack = $self->{stack};

	# print STDERR "pop_matching( $tag ) stack of " . scalar( @$stack ) . " elements\n";

	my $flag = 0;
	foreach my $x ( @$stack )
	{
		if( $tag eq $x->{tag} )
		{
			# print STDERR "pop_matching( $tag ) set flag for $x->{tag}\n";
			$flag = 1;
			next;
		}
		if( defined( $stopat ))
		{
			foreach my $y ( @$stopat )
			{
				# print STDERR "pop_matching( $tag ) check stopat $y against $x->{tag}\n";
				if( $y eq $x->{tag} ) { $flag = 0; }
			}
		}
	}

	# print STDERR "pop_matching( $tag ) flag = $flag\n";

	return undef unless( $flag );

	# Thinks stopat is already checked, doesn't need double-checking.
	while( 1 )
	{
		my $x = pop( @$stack );
		
		# print STDERR "pop_matching( $tag ) popping $x->{tag} from stack\n";

		if( $self->{fake_close_tags} and
			( !defined( $real_close ) or $real_close ne $x->{tag}))
		{
			# Inject a closing tag as we pop
			# Note that "fake" close tags can be identified by being subordinate
			# Real close tags are on equal level with the opener.
			# From an output perspective the HTML generated is identical.

			my $ix = $x->{ix};
			my $n = $x->{node};
			++$ix;
			my $tag_node = $n->[ $ix ];
			$tag_node->name( "/$x->{tag}" );
			$x->{ix} = $ix; # Is this useful? Might as well be consistent
		}
		# If closer matches tag exactly then tuck the closer under the existing node
		# This makes the transformer work neatly by pruning the entire block.
		# Only works for cases where we recognize neat nesting (not <b> <i> <em> and similar).
		return( $x ) if( $x->{tag} eq $tag );
	}
	return( undef );
}

#
# Start tag adds a node in the array.
# The name of the tag is given to the node, and the attributes are hashed under that node.
# Value of the node is any text after the start tag.
#
sub start
{
	my $self = shift;
	my $tag = shift;
	my $attr = shift;
	my $prev_node;
	my $prev_tag = '';

	my $restrict = $self->{restrict};
	if( defined( $restrict ))
	{
		unless( $restrict->{ $tag })
		{
			croak( "Illegal opening HTML tag '$tag' discovered\n" );
		}
	}

	# print STDERR "start $tag\n";

	# Sometimes an opening tag actually closes earlier tags implicitly
	my $nest = $html_nest->{ $tag };
	if( defined( $nest ))
	{
		my $close = $nest->{close};
		if( defined( $close ))
		{
			foreach my $x ( @$close )
			{
				$self->pop_matching( $x, $nest->{stopat});
			}
		}
	}

	my $stack = $self->{stack};
	my $stack_top = $stack->[ -1 ];
	die( "Broken stack" ) unless defined( $stack_top );
	my $n = $stack_top->{node};
	my $ix = $stack_top->{ix};
	my $tag_top = $stack_top->{tag};
	if( $ix >= 0 )
	{
		$prev_node = $n->[ $ix ];
		$prev_tag = $prev_node->name();
	}

	# Always chain the current node on the end of the array
	++$ix;
	my $tag_node = $n->[ $ix ];

	foreach my $a ( sort keys %$attr )
	{
		$tag_node->{$a} = $attr->{$a};
	}

	$tag_node->name( $tag );
	$self->{tag_node} = $tag_node;
	$stack_top->{ix} = $ix;

	# Consider pushing the stack down if this tag is a nesting type
	if( defined( $nest ))
	{
		my $new_top = { ix => -1, node => $tag_node, tag => $tag };
		push @$stack, $new_top;
		# print STDERR "pushed stack on $tag\n";
	}

#	use Data::Dumper; my $x = Dumper( $s );
}

#
# End tag can close off a bunch of earlier tags,
# however, a bogus end tag for no good reason is also possible.
#
sub end
{
	my $self = shift;
	my $tag = shift;
	my $stack = $self->{stack};

	my $restrict = $self->{restrict};
	if( defined( $restrict ))
	{
		unless( $restrict->{ $tag })
		{
			croak( "Illegal opening HTML tag '$tag' discovered\n" );
		}
	}

	# Unwind the stack if we can match against anything on there.
	my $nest = $html_nest->{ $tag };
	my $stack_top = $self->pop_matching( $tag, $nest->{stopat}, $tag );
	unless( defined( $stack_top ))
	{
		$stack_top = $stack->[ -1 ];
	}
	my $n = $stack_top->{node};
	die( "Stack corrupt" ) unless defined( $n );
	my $ix = $stack_top->{ix};
	my $tag_top = $stack_top->{tag};
	++$ix;
	# print STDERR "... ix=$ix n=" . ref( $n ) . "\n";
	my $tag_node = $n->[ $ix ];

	# print STDERR "... " . ref( $tag_node ) . "\n";
	$tag_node->name( "/$tag" );
	$self->{tag_node} = $tag_node;
	$stack_top->{ix} = $ix;
	# print STDERR "end $tag\n";
}

#
# If there is a tag_node, then we add text to that as a value (or append to existing)
#
sub text
{
	my $self = shift;
	my $data = shift;
	my $tag_node = $self->{tag_node};
	if( defined( $tag_node ))
	{
		$tag_node->set_val( $data );
	}
	# print STDERR "text $data\n";
}

sub dump_structure_sub
{
	my $self = shift;
	my $node = shift;
	my $prefix = shift;
	my $val = '';

	return( undef ) unless defined( $node );
	my $name = $node->name();

	# Skip top level node, it is just a container
	if( length( $prefix ))
	{
		my $otran = $self->{otran};
		my $flag = '';
		if( defined( $otran ))
		{
			my $tmp = &$otran( $node );
			if( defined( $tmp )) { $flag = "\t*"; }
		}
		$val .= $prefix . "        <" . $name . ">$flag\n";
	}

	my $s = $node->array_scalar();
	return $val unless defined( $s );
	my $x = 0;
	while( $x < $s )
	{
		my $n2 = $node->[ $x ];
		$val .= $self->dump_structure_sub( $n2, sprintf( "%s[%3d]", $prefix, $x ));
		
		++$x;
	}
	return $val;
}

#
# Mostly for debugging, ignore the attributes of the tags, and ignore
# all the values. Just print a simple indented list.
#
sub dump_structure
{
	my $self = shift;
	my $stack = $self->{stack};
	my $stack_base = $stack->[ 0 ];
	my $node = $stack_base->{node};

	return( $self->dump_structure_sub( $node, '' ));
}

sub encode_quoted_value
{
	my $x = shift;
	return( $x );
}

sub encode_HTML_value
{
	my $x = shift;
	return( $x );
}

sub dump_HTML_sub
{
	my $self = shift;
	my $node = shift;
	my $depth = shift;
	my $val = '';

	return( undef ) unless defined( $node );
	my $name = $node->name();

	# Skip top level node, it is just a container
	if( $depth )
	{
		my $otran = $self->{otran};
		if( defined( $otran ))
		{
			my $tmp = &$otran( $node );
			if( defined( $tmp ))
			{
				if( ref( $tmp ))
				{
					$self->{otran} = undef; # Disable recursive transforms
					$val .= $self->dump_HTML_sub( $tmp, $depth );
					$self->{otran} = $otran; # Re-enable transform
				}
				else
				{
					$val .= $tmp;
				}
				return( $val );     # -- Short circuit !!
			}
		}

		$val .= "<" . $name;

		foreach my $k ( sort( $node->hash_keys()))
		{
			my $n = $node->{$k};
			my $v = $n->val();
			if( defined( $n ) and defined( $v ))
			{
				$val .= " " . $n->name . '="' . encode_quoted_value( $v ) . '"';
			}
		}
		$val .= '>';
		my $v = $node->val();
		if( defined( $v )) { $val .= encode_HTML_value( $v ); }
	}

	++$depth;
	my $s = $node->array_scalar();
	return $val unless defined( $s );
	my $x = 0;
	while( $x < $s )
	{
		my $n2 = $node->[ $x ];
		$val .= $self->dump_HTML_sub( $n2, $depth );
		
		++$x;
	}
	return $val;
}

# Reconstruct something similar to the original HTML
sub dump_HTML
{
	my $self = shift;
	my $stack = $self->{stack};
	my $stack_base = $stack->[ 0 ];
	my $node = $stack_base->{node};

	return( $self->dump_HTML_sub( $node ));
}

1;
__END__

=head1 NAME

HTML::Persistent::HTML - Import/Export HTML

=head1 SYNOPSIS

use HTML::Persistent;

my $db = HTML::Persistent->new( dir => '/tmp/test-directory' );
my $node = $db->{foo}{bar}{baz};
my $html = $node->HTML();

# NOTE: Import only supports writing into an empty node!
$html->import( $chunk1 );
$html->import( $chunk2 );
$html->import( $chunk3 );
$html->eof();
$db->sync();

# Output HTML reconstructed from database.
print $html->export();

=cut

