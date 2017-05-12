# check core module: parser node

use strict;
use warnings;

use Test::More tests => 9;

#=== Dependencies
#none

#Parser Node
use Konstrukt::Parser::Node;

my $root_node = Konstrukt::Parser::Node->new({ type => "root" });
is($root_node->tree_to_string(), "* root\n", "new root node");

#create text node
my $text_node = Konstrukt::Parser::Node->new({ type => "plaintext", content => "text" });

#create tag node
my $tag_node = Konstrukt::Parser::Node->new({ type => "tag", handler_type  => "plugin", tag => { type => "upcase" } });

#create tree
$root_node->add_child($tag_node);
$tag_node->add_child($text_node);

is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
    children below this tag:
    * plaintext: text
EOT
, "tree");

#append node
$text_node->append(Konstrukt::Parser::Node->new({ type => "plaintext", content => "text2" }));
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
    children below this tag:
    * plaintext: text
    * plaintext: text2
EOT
, "append");

#prepend node
$text_node->prepend(Konstrukt::Parser::Node->new({ type => "plaintext", content => "text0" }));
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
    children below this tag:
    * plaintext: text0
    * plaintext: text
    * plaintext: text2
EOT
, "prepend");

#children_to_string
is($tag_node->children_to_string(), "text0texttext2", "children_to_string");

#move_children
#create another tag node
my $tag_node2 = Konstrukt::Parser::Node->new({ type => "tag", handler_type  => "plugin", tag => { type => "upcase" } });
$root_node->add_child($tag_node2);
$tag_node->move_children($tag_node2);
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
    children below this tag:
    * plaintext: text0
    * plaintext: text
    * plaintext: text2
EOT
, "move_children");

#delete
$tag_node->delete();
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * tag: (final) - type: plugin upcase - dynamic: 0 - executionstage: (not defined - no dynamic tag)
    children below this tag:
    * plaintext: text0
    * plaintext: text
    * plaintext: text2
EOT
, "delete");

#replace_by_children
$tag_node2->replace_by_children();
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * plaintext: text0
  * plaintext: text
  * plaintext: text2
EOT
, "replace_by_children");

#replace_by_node
$text_node->replace_by_node(Konstrukt::Parser::Node->new({ type => "plaintext", content => "text1" }));
is($root_node->tree_to_string(),
<<EOT
* root
  children below this tag:
  * plaintext: text0
  * plaintext: text1
  * plaintext: text2
EOT
, "replace_by_node");

exit;
