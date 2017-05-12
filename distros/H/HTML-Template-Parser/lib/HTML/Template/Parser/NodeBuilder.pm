package HTML::Template::Parser::NodeBuilder;

use strict;
use warnings;

sub createNode {
    my($attr) = @_;

    my @attr_list = @$attr;
    my $type = shift @attr_list;
    my($line, $column) = @{shift @attr_list}[0,1];

    if($type eq 'string'){
        HTML::Template::Parser::Node::String->new({ line => $line, column => $column,
                                                    text => shift @attr_list });
    }elsif($type eq 'var'){
        HTML::Template::Parser::Node::Var->new({ line => $line, column => $column,
                                                 name_or_expr => shift @attr_list,
                                                 escape => shift @attr_list,
                                                 default => shift @attr_list,
                                             });
    }elsif($type eq 'include'){
        HTML::Template::Parser::Node::Include->new({ line => $line, column => $column,
                                                     name_or_expr => shift @attr_list });
    }elsif($type eq 'if'){
        HTML::Template::Parser::Node::If->new({ line => $line, column => $column,
                                                 name_or_expr => shift @attr_list,
                                             });
    }elsif($type eq 'elsif'){
        HTML::Template::Parser::Node::ElsIf->new({ line => $line, column => $column,
                                                   name_or_expr => shift @attr_list,
                                               });
    }elsif($type eq 'else'){
        HTML::Template::Parser::Node::Else->new({ line => $line, column => $column });
    }elsif($type eq 'if_end'){
        HTML::Template::Parser::Node::IfEnd->new({ line => $line, column => $column });
    }elsif($type eq 'unless'){
        HTML::Template::Parser::Node::Unless->new({ line => $line, column => $column,
                                                    name_or_expr => shift @attr_list,
                                                });
    }elsif($type eq 'unless_end'){
        HTML::Template::Parser::Node::UnlessEnd->new({ line => $line, column => $column });
    }elsif($type eq 'loop'){
        HTML::Template::Parser::Node::Loop->new({ line => $line, column => $column,
                                                  name_or_expr => shift @attr_list,
                                              });
    }elsif($type eq 'loop_end'){
        HTML::Template::Parser::Node::LoopEnd->new({ line => $line, column => $column });
    }else{
        die "unknown type[$type]\n";
    }
}

package HTML::Template::Parser::Node;

use strict;
use warnings;

use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw( type can_have_child is_end_tag expected_begin_tag is_group_tag is_dont_add_me line column parent children raw_item ));

use Scalar::Util;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->children([]);
    $self->_init();
    $self;
}

sub _init {}

sub add_chidren {
    my($self, $node_list) = @_;

    while(@$node_list){
        my $node = shift @$node_list;
        return unless $node->list_to_tree($self, $node_list);
    }
    if($self->type eq 'group'){
        my $tag = 'TMPL_' . uc($self->sub_type);
        die sprintf("line %d. column %d. missing '</%s>' pared with  <%s>\n",
                    $self->line, $self->column, $tag, $tag);
    }
}

sub list_to_tree {
    my($self, $parent, $node_list) = @_;

    if($self->is_end_tag){
        if(! $parent->is_group_tag){
            if($parent->parent and $parent->parent->is_group_tag){
                # REDO
                unshift @{ $node_list }, $self;
                return;
            }else{
                # tag mismatch
                (my $tag = uc($self->type)) =~ s/_end$//i;
                die sprintf("line %d. column %d. tag doesn't match </TMPL_%s>\n",
                            $self->line, $self->column, $tag);
            }
        }else{
            if($self->expected_begin_tag and $parent->sub_type !~ $self->expected_begin_tag){
                # Ex) <TMPL_IF>...</TMPL_UNLESS>
                die sprintf("line %d. column %d. tag doesn't match </TMPL_%s> [%s]\n",
                            $self->line, $self->column, uc($self->expected_begin_tag), $parent->sub_type);
            }
            if(my $error = $parent->can_accept_this_node($self)){
                die sprintf("line %d. column %d. %s\n",
                            $self->line, $self->column, $error);
            }
        }
    }
    if($self->is_dont_add_me()){
        return;
    }

    $parent->add_a_child($self);

    if($self->can_have_child){
        $self->add_chidren($node_list);
    }
    1;
}

sub add_a_child {
    my($self, $child) = @_;

    push(@{$self->{children}}, $child);
    $child->parent($self);
}

sub can_accept_this_node {
    '';
}

sub remove_empty_block {
    my $self = shift;

    my @children;
    foreach my $child (@{ $self->{children} }){
        if(not $child->is_empty){
            push(@children, $child);
        }
    }
    $self->{children} = \@children;
}

sub is_empty {
    my $self = shift;

    $self->remove_empty_block();
    if($self->can_have_child and @{$self->{children}} == 0){
        return 1;
    }
    return 0;
}

package HTML::Template::Parser::Node::Root;

use strict;
use warnings;

sub _init {
    my $self = shift;
    $self->type('root');
    $self->can_have_child(1);
}

use base qw(HTML::Template::Parser::Node);

package HTML::Template::Parser::Node::String;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( text ));

sub _init {
    my $self = shift;
    $self->type('string');
}

package HTML::Template::Parser::Node::Var;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( name_or_expr escape default ));

sub _init {
    my $self = shift;
    $self->type('var');
}

package HTML::Template::Parser::Node::Include;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( name_or_expr ));

sub _init {
    my $self = shift;
    $self->type('include');
}

package HTML::Template::Parser::Node::If;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( name_or_expr else_seen ));

sub _init {
    my $self = shift;
    $self->type('if');
    $self->can_have_child(1);
}

sub can_accept_this_node {
    my($self, $node) = @_;

    return if($node->type eq 'group_end');

    if($self->else_seen){
        # accept 'if_end' only
        if($node->type ne 'if_end'){
            return sprintf("can't accept <TMPL_%s>, since already seen <TMPL_ELSE>. accept </TMPL_IF> only.",
                           uc($node->type));
        }
    }
    if($node->type eq 'else'){
        $self->else_seen(1);
    }
    return;
}

package HTML::Template::Parser::Node::ElsIf;
__PACKAGE__->mk_accessors(qw( name_or_expr ));

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('elsif');
    $self->can_have_child(1);
    $self->is_end_tag(1);
    $self->expected_begin_tag(qr/if|unless/);
}

package HTML::Template::Parser::Node::Else;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('else');
    $self->can_have_child(1);
    $self->is_end_tag(1);
    $self->expected_begin_tag(qr/if|unless/);
}

package HTML::Template::Parser::Node::IfEnd;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('if_end');
    $self->is_end_tag(1);
    $self->expected_begin_tag('if');
}

package HTML::Template::Parser::Node::Unless;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( name_or_expr else_seen ));

sub _init {
    my $self = shift;
    $self->type('unless');
    $self->can_have_child(1);
}

sub can_accept_this_node {
    my($self, $node) = @_;

    return if($node->type eq 'group_end');

    if($self->else_seen){
        # accept 'if_end' only
        if($node->type ne 'unless_end'){
            return sprintf("can't accept <TMPL_%s>, since already seen <TMPL_ELSE>. accept </TMPL_UNLESS> only.",
                           uc($node->type));
        }
    }
    if($node->type eq 'else'){
        $self->else_seen(1);
    }
    return;
}

package HTML::Template::Parser::Node::UnlessEnd;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('unless_end');
    $self->is_end_tag(1);
    $self->expected_begin_tag('unless');
}

package HTML::Template::Parser::Node::Loop;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( name_or_expr ));

sub _init {
    my $self = shift;
    $self->type('loop');
    $self->can_have_child(1);
}

package HTML::Template::Parser::Node::LoopEnd;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('loop_end');
    $self->is_end_tag(1);
    $self->expected_begin_tag('loop');
}

package HTML::Template::Parser::Node::Group;

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);
__PACKAGE__->mk_accessors(qw( sub_type ));

sub _init {
    my $self = shift;
    $self->type('group');
    $self->can_have_child(1);
    $self->is_group_tag(1);
}

sub can_accept_this_node {
    my($self, $node) = @_;

    if(0 < @{$self->children}){
        return $self->children->[0]->can_accept_this_node($node);
    }
    return '';
}

package HTML::Template::Parser::Node::GroupEnd;
__PACKAGE__->mk_accessors(qw( sub_type ));

use strict;
use warnings;

use base qw(HTML::Template::Parser::Node);

sub _init {
    my $self = shift;
    $self->type('group_end');
    $self->is_end_tag(1);
    $self->is_dont_add_me(1);
}

1;
