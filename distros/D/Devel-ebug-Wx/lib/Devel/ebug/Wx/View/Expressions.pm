package Devel::ebug::Wx::View::Expressions;

use Wx;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

# FIXME: ought to be a service, too
__PACKAGE__->mk_accessors( qw(tree model) );

use Wx qw(:treectrl :textctrl :sizer WXK_DELETE);
use Wx::Event qw(EVT_BUTTON EVT_TREE_ITEM_EXPANDING EVT_TEXT_ENTER
                 EVT_TREE_BEGIN_LABEL_EDIT EVT_TREE_END_LABEL_EDIT
                 EVT_TREE_KEY_DOWN);
use Wx::Perl::TreeView;

sub tag         { 'expressions' }
sub description { 'Expressions' }

# FIXME backport to wxPerl
sub _call_on_idle($&) {
    my( $window, $code ) = @_;

    use Wx::Event qw(EVT_IDLE);
    # Disconnecting like this is unsafe...
    my $callback = sub {
        EVT_IDLE( $window, undef );
        $code->();
    };
    EVT_IDLE( $window, $callback );
}

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    my $tree = Wx::TreeCtrl->new( $self, -1, [-1,-1], [-1,-1],
                                       wxTR_HIDE_ROOT | wxTR_HAS_BUTTONS |
                                       wxTR_EDIT_LABELS );
    $self->{model} = Devel::ebug::Wx::View::Expressions::Model->new
                          ( { _expressions => [],
                              _values      => [],
                              ebug         => $self->ebug } );
    $self->{tree} = Wx::Perl::TreeView->new( $tree, $self->model );

    my $refresh = Wx::Button->new( $self, -1, 'Refresh' );
    my $add = Wx::Button->new( $self, -1, 'Add' );
    my $expression = Wx::TextCtrl->new( $self, -1, '', [-1, -1], [-1, -1],
                                        wxTE_PROCESS_ENTER );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $cntrl = Wx::BoxSizer->new( wxHORIZONTAL );
    $cntrl->Add( $refresh, 0, 0 );
    $cntrl->Add( $add, 0, 0 );
    $cntrl->Add( $expression, 1, 0 );
    $sz->Add( $cntrl, 0, wxGROW );
    $sz->Add( $self->tree->treectrl, 1, wxGROW );
    $self->SetSizer( $sz );

    $self->subscribe_ebug( 'state_changed', sub { $self->_refresh( @_ ) } );
    $self->set_layout_state( $layout_state ) if $layout_state;
    $self->register_view;

    EVT_BUTTON( $self, $refresh, sub { $self->refresh } );
    EVT_BUTTON( $self, $add, sub {
                    $self->add_expression( $expression->GetValue );
                } );
    EVT_TEXT_ENTER( $self, $expression,
                    sub { $self->add_expression( $expression->GetValue ) } );
    EVT_TREE_BEGIN_LABEL_EDIT( $self, $tree, \&_begin_edit );
    EVT_TREE_END_LABEL_EDIT( $self, $tree, \&_end_edit );
    EVT_TREE_KEY_DOWN( $self, $tree, \&_key_down );

    $self->SetSize( $self->default_size );

    return $self;
}

sub get_state {
    my( $self ) = @_;

    return $self->model->_expressions;
}

sub set_state {
    my( $self, $state ) = @_;

    $self->model->{_expressions} = $state; # FIXME check
    $self->refresh;
}

sub add_expression {
    my( $self, $expression ) = @_;

    $self->model->add_expression( $expression );
    $self->refresh;
}

sub _is_expression {
    return $_[0]->GetItemParent( $_[1] ) == $_[0]->GetRootItem;
}

sub _key_down {
    my( $self, $event ) = @_;

    return unless $event->GetKeyCode == WXK_DELETE;
    my $item = $event->GetItem || $self->tree->GetSelection;
    return unless _is_expression( $self->tree, $item );
    $self->model->delete_expression( $self->tree->GetPlData( $item ) );
    _call_on_idle $self, sub { $self->refresh };
}

# only allow editing root items
sub _begin_edit {
    my( $self, $event ) = @_;
    my $tree = $self->tree;

    if( !_is_expression( $tree, $event->GetItem ) ) {
        $event->Veto;
    } else {
        my $expr = $tree->GetPlData( $event->GetItem )->{expression};
        $tree->SetItemText( $event->GetItem, $expr );
    }
}

sub _end_edit {
    my( $self, $event ) = @_;

    $self->tree->GetPlData( $event->GetItem )->{expression} = $event->GetLabel;
    _call_on_idle $self, sub { $self->refresh };
}

sub _refresh {
    my( $self, $ebug, $event, %params ) = @_;

    $self->refresh;
}

sub refresh {
    my( $self ) = @_;

    $self->model->_values( [] );
    $self->tree->refresh;
}

package Devel::ebug::Wx::View::Expressions::Model;

use strict;
use base qw(Wx::Perl::TreeView::Model Class::Accessor::Fast);

__PACKAGE__->mk_accessors( qw(_expressions _values ebug) );

sub expressions { @{$_[0]->_expressions} }

sub add_expression {
    my( $self, $expression ) = @_;

    push @{$self->_expressions}, { expression => $expression,
                                   level      => 0,
                                   };
}

sub delete_expression {
    my( $self, $expression ) = @_;

    $self->_expressions( [ grep $_ ne $expression, $self->expressions ] );
}

sub get_root { return ( '', 'root', undef, undef ) }

sub _get {
    my( $self, $index, $level ) = @_;
    my $e = $self->_expressions->[$index];
    if( $e->{level} < $level ) {
        $e->{level} = $level + 1;
        $self->_values->[$index] = undef;
    }
    my $r = $self->_values->[$index] ||=
        [ reverse
              $self->ebug->eval_level( $e->{expression}, $e->{level} ) ];
    return ( $e, $r );
}

sub _find_node {
    my( $self, $cookie, $more ) = @_;
    my( $expr, @path ) = split /,/, $cookie;
    my( $e, $r ) = _get( $self, $expr, @path + $more );
    return _traverse( $self, $r, @path );
}

sub _traverse {
    my( $self, $r, @path ) = @_;
    return $r if @path == 0;
    return unless ref( $r->[1] ) && $r->[1]{keys};
    my $index = shift @path;
    return $r->[1]{keys}[$index] if @path == 0;
    return _traverse( $self, $r->[1]{keys}[$index], @path );
}

sub get_child_count {
    my( $self, $cookie ) = @_;
    return scalar $self->expressions unless length $cookie;
    my $node = _find_node( $self, $cookie, -1 );
    return 0 if $cookie !~ /,/ && $node->[0];
    return $node->[1]{childs} || scalar @{$node->[1]{keys} || []};
}

sub get_child {
    my( $self, $cookie, $index ) = @_;

    if( !length $cookie ) {
        my( $e, $r ) = _get( $self, $index, 0 );
        if( $r->[0] ) {
            chomp $r->[1];
            return ( $index, "$e->{expression} = $r->[1]", undef, $e );
        } else {
            return ( $index, "$e->{expression} = $r->[1]->{string}", undef, $e );
        }
    } else {
        my $el = _find_node( $self, "$cookie,$index", 0 );
        return ( "$cookie,$index", $el->[0] . ' => ' . $el->[1]->{string} );
    }
}

1;
