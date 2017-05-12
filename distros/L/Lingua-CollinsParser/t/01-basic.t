use Test::More;
BEGIN { plan tests => 40 };
use Lingua::CollinsParser;
use Module::Build 0.21;
use File::Spec;

ok(1);

my $build = Module::Build->current;
my $cp_home = $build->notes('cp_home');

my $p = Lingua::CollinsParser->new();

ok $p->load_grammar( File::Spec->catfile($cp_home, 'grammar') );

my $events_dump = 'events.out';
if ( -e $events_dump ) {
  $p->undump_events_hash($events_dump);
} else {
  $p->load_events( File::Spec->catfile($cp_home, 'events') );
}

my @words = qw(The bird flies);
my @tags  = qw(DT  NN   VBZ);
my $tree = $p->parse_sentence(\@words, \@tags);

# Note - I'm not quite sure what the precise meaning of the "node_type" entry is.
is_deeply( $tree, {
		   head_child => 0,
		   head_token => 'flies',
		   node_type => 'nonterminal',
		   label => 'TOP',
		   num_children => 1,
		   children => [
				{
				 head_child => 1,
				 head_token => 'flies',
				 node_type => 'unary',
				 label => 'S',
				 num_children => 2,
				 children => [
					      {
					       head_child => 1,
					       head_token => 'bird',
					       node_type => 'unary',
					       label => 'NPB',
					       num_children => 2,
					       children => [
							    {
							     node_type => 'leaf',
							     token => 'The',
							     label => 'DT',
							    },
							    {
							     node_type => 'leaf',
							     token => 'bird',
							     label => 'NN',
							    }
							   ],
					      },
					      {
					       head_child => 0,
					       head_token => 'flies',
					       node_type => 'nonterminal',
					       label => 'VP',
					       num_children => 1,
					       children => [
							    {
							     node_type => 'leaf',
							     token => 'flies',
							     label => 'VBZ',
							    }
							   ],
					      }
					     ],
				}
			       ],
		  }
	 );

is $tree->head_token, 'flies';
is $tree->node_type, 'nonterminal';
is $tree->label, 'TOP';
is $tree->children, 1;
isa_ok $tree->head, 'Lingua::CollinsParser::Node';

my $phrase = $tree->head;

is $phrase->head_token, 'flies';
is $phrase->node_type, 'unary';
is $phrase->label, 'S';
is $phrase->children, 2;

my ($np, $vp) = $phrase->children;

# Check the noun part
{
  is $np->head_token, 'bird';
  is $np->node_type, 'unary';
  is $np->label, 'NPB';
  is $np->children, 2;

  my ($det, $n) = $np->children;

  is $det->node_type, 'leaf';
  is $det->token, 'The';
  is $det->label, 'DT';

  is $n->node_type, 'leaf';
  is $n->token, 'bird';
  is $n->label, 'NN';
}

# Check the verb part
{
  is $vp->node_type, 'nonterminal';
  is $vp->head_token, 'flies';
  is $vp->label, 'VP';
  is $vp->children, 1;
  
  $vp = $vp->head;

  is $vp->node_type, 'leaf';
  is $vp->token, 'flies';
  is $vp->label, 'VBZ', "Check verb label";
}

my $xml = $tree->as_xml;
like $xml, qr{<W TAG="DT">The</W>}, "XML output looks like XML";

$p = Lingua::CollinsParser->new();
ok $p;

# Exercise the accessors
$p->beamsize(10_000);  is $p->beamsize, 10_000;
$p->punc_flag(1);      is $p->punc_flag, 1;
$p->distaflag(1);      is $p->distaflag, 1;
$p->distvflag(1);      is $p->distvflag, 1;
$p->npflag(1);         is $p->npflag, 1,   "npflag can be set correctly";


# Check punctuation
{
  my (@words, @tags);
  {
    no warnings;
    @words = qw(`` Yes , '' said Ken .);
    @tags  = qw(`` UH  , '' VBD  NNP .);
  }
  my $tree = $p->parse_sentence(\@words, \@tags);
  ok $tree, "Parsed tree with punctuation";

  
  use Data::Dumper;
  $Data::Dumper::Sortkeys = 1;

  is_deeply $tree, {
	      'children' => [
			     {
			      'children' => [
					     {
					      'children' => [
							     {
							      'label' => "``",
							      'node_type' => 'leaf',
							      'token' => "``"
							     },
							     {
							      'label' => 'NNP',
							      'node_type' => 'leaf',
							      'token' => 'Yes'
							     },
							     {
							      'label' => ",",
							      'node_type' => 'leaf',
							      'token' => ","
							     },
							     {
							      'label' => "''",
							      'node_type' => 'leaf',
							      'token' => "''"
							     },
							    ],
					      'head_child' => 1,
					      'head_token' => 'Yes',
					      'label' => 'NPB',
					      'node_type' => 'nonterminal',
					      'num_children' => 1
					     },
					     {
                                              'children' => [
							     {
							      'label' => 'VBD',
							      'node_type' => 'leaf',
							      'token' => 'said'
							     },
							     {
							      'children' => [
									     {
									      'label' => 'NNP',
									      'node_type' => 'leaf',
									      'token' => 'Ken'
									     },
									     {
									      'label' => '.',
									      'node_type' => 'leaf',
									      'token' => '.'
									     }
									    ],
							      'head_child' => 0,
							      'head_token' => 'Ken',
							      'label' => 'NPB',
							      'node_type' => 'nonterminal',
							      'num_children' => 1
							     }
                                                            ],
                                              'head_child' => 0,
                                              'head_token' => 'said',
                                              'label' => 'VP',
                                              'node_type' => 'unary',
                                              'num_children' => 2
					     }
					    ],
			      'head_child' => 1,
			      'head_token' => 'said',
			      'label' => 'S',
			      'node_type' => 'unary',
			      'num_children' => 2
			     }
			    ],
	      'head_child' => 0,
	      'head_token' => 'said',
	      'label' => 'TOP',
	      'node_type' => 'nonterminal',
	      'num_children' => 1
	     };
  





}


# Try dumping events hash & restoring
SKIP: {
  skip "Event-hash dumping was tested in a previous run", 2 if -e $events_dump;

  $build->add_to_cleanup($events_dump);
  $p->dump_events_hash($events_dump);
  ok 1;
  $p->undump_events_hash($events_dump);
  ok 1;
}


