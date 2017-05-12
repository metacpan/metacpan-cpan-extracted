# IUP::Tree example (attributes)

use strict;
use warnings;

use IUP ':all';

my $nodes = {
        TITLE=>"root (0)", STATE=>"EXPANDED",
        child=>[{
                TITLE=>"1.1 (1)", STATE=>"EXPANDED",
                child=>[{
                        TITLE=>"1.1.1 (2)", STATE=>"EXPANDED",
                        child=>[{
                                TITLE=>"1.1.1.1 (3)", STATE=>"EXPANDED",
                                child=>["1.1.1.1.1 (4)","1.1.1.1.2 (5)"],
                        },
                        {
                                TITLE=>"1.1.1.2 (6)", STATE=>"EXPANDED",
                                child=>["1.1.1.2.1 (7)","1.1.1.2.2 (8)"],
                        }], #xxx3
                },
                {
                        TITLE=>"1.1.2 (9)", STATE=>"EXPANDED",
                        child=>[{
                                TITLE=>"1.1.2.1 (10)", STATE=>"EXPANDED",
                                child=>["1.1.2.1.1 (11)","1.1.2.1.2 (12)"],
                        },
                        {
                                TITLE=>"1.1.2.2 (13)", STATE=>"EXPANDED",
                                child=>["1.1.2.2.1 (14)","1.1.2.2.2 (15)"],
                        }],
                }],
        },
        {
                TITLE=>"1.2 (16)", STATE=>"EXPANDED",
                child=>[{
                        TITLE=>"1.2.1 (17)", STATE=>"EXPANDED",
                        child=>[{
                                TITLE=>"1.2.1.1 (18)", STATE=>"EXPANDED",
                                child=>["1.2.1.1.1 (19)","1.2.1.1.2 (20)"],
                        },
                        {
                                TITLE=>"1.2.1.2 (21)", STATE=>"EXPANDED",
                                child=>["1.2.1.2.1 (22)","1.2.1.2.2 (23)"],
                        }],
                },
                {
                        TITLE=>"1.2.2 (24)", STATE=>"EXPANDED",
                        child=>[{
                                TITLE=>"1.2.2.1 (25)", STATE=>"EXPANDED",
                                child=>["1.2.2.1.1 (26)","1.2.2.1.2 (27)"],
                        },
                        {
                                TITLE=>"1.2.2.2 (28)", STATE=>"EXPANDED",
                                child=>["1.2.2.2.1 (29)","1.2.2.2.2 (30)"],
                        }],
                }],
        }],
};

my $tree = IUP::Tree->new( MAP_CB=>sub { my $self=shift; $self->TreeAddNodes($nodes) } );

my $no = IUP::Text->new();

my $attrs = IUP::Text->new( VALUE=>"{ COLOR => '255 0 0' }", SIZE=>"200x" );

my $dlg = IUP::Dialog->new( SIZE=>"QUARTERxHALF", TITLE=>"IUP::Tree Example",
                            child=>IUP::Vbox->new( child=>[
                              $tree,
                              IUP::Hbox->new( child=>[
                                IUP::Fill->new(),
                                IUP::Label->new( TITLE=>"Node:" ),
                                $no,
                                IUP::Fill->new(),
                                IUP::Label->new( TITLE=>"Attributes:" ),
                                $attrs,
                                IUP::Fill->new()
                              ]),
                              IUP::Hbox->new( child=>[
                                IUP::Fill->new(),
                                IUP::Button->new(
                                  TITLE=>"Ancestors",
                                  ACTION=>sub { $tree->TreeSetAncestorsAttributes($no->VALUE, eval $attrs->VALUE) },
                                ),
                                IUP::Fill->new(),
                                IUP::Button->new(
                                  TITLE=>"Descendents",
                                  ACTION=>sub { $tree->TreeSetDescentsAttributes($no->VALUE, eval $attrs->VALUE) },
                                ),
                                IUP::Fill->new(),
                                IUP::Button->new(
                                  TITLE=>"All",
                                  ACTION=>sub {
                                                    for my $node (0..$tree->COUNT-1) {
                                                  $tree->TreeSetNodeAttributes($node, eval $attrs->VALUE);
                                                }
                                              },
                                ),
                                IUP::Fill->new(),
                              ]),
                            ]),
                          );  

$dlg->Show();
$tree->VALUE(15);
$no->VALUE(15);

IUP->MainLoop();
