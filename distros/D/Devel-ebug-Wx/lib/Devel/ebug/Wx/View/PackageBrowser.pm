package Devel::ebug::Wx::View::PackageBrowser;

use strict;
use base qw(Wx::Panel Devel::ebug::Wx::View::Base);
use Devel::ebug::Wx::Plugin qw(:plugin);

__PACKAGE__->mk_accessors( qw(tree) );

use Wx qw(:treectrl :sizer);
use Wx::Event qw(EVT_TREE_ITEM_ACTIVATED EVT_BUTTON);
use Wx::Perl::TreeView;

sub tag         { 'package_browser' }
sub description { 'Package Browser' }

sub new : View {
    my( $class, $parent, $wxebug, $layout_state ) = @_;
    my $self = $class->SUPER::new( $parent, -1 );

    $self->wxebug( $wxebug );
    my $tree = Wx::TreeCtrl->new( $self, -1, [-1,-1], [-1,-1],
                                  wxTR_HIDE_ROOT | wxTR_HAS_BUTTONS );
    my $model = Devel::ebug::Wx::View::PackageBrowser::Model
                  ->new( { ebug => $self->ebug } );
    $self->{tree} = Wx::Perl::TreeView->new( $tree, $model );

    my $refresh = Wx::Button->new( $self, -1, 'Refresh' );

    my $sz = Wx::BoxSizer->new( wxVERTICAL );
    my $cntrl = Wx::BoxSizer->new( wxHORIZONTAL );
    $cntrl->Add( $refresh, 0, 0 );
    $sz->Add( $cntrl, 0, wxGROW );
    $sz->Add( $self->tree->treectrl, 1, wxGROW );
    $self->SetSizer( $sz );

    $self->register_view;

    EVT_TREE_ITEM_ACTIVATED( $self, $tree, sub { $self->_show_sub( $_[1] ) } );
    EVT_BUTTON( $self, $refresh, sub { $self->_refresh } );

    $self->SetSize( $self->default_size );

    $self->add_subscription( $self->ebug, 'load_program', $self, '_refresh' );

    return $self;
}

sub _refresh {
    my( $self ) = @_;

    $self->tree->model->flush_cache;
    $self->tree->reload;
}

sub _show_sub {
    my( $self, $event ) = @_;

    if( $self->tree->ItemHasChildren( $event->GetItem ) ) {
        $event->Skip;
        return;
    }

    my $cookie = $self->tree->get_cookie( $event->GetItem );
    $cookie =~ s/^&:://;
    my( $filename, $start, $end ) = $self->ebug->subroutine_info( $cookie );
    return unless $filename && $start;
    $self->wxebug->code_display_service
         ->highlight_line( $filename, $start );
}

package Devel::ebug::Wx::View::PackageBrowser::Model;

use strict;
use base qw(Wx::Perl::TreeView::Model Class::Accessor::Fast);

__PACKAGE__->mk_ro_accessors( qw(ebug _last_cookie _last_answer) );

sub get_root { return ( '::main', '' ) }

sub flush_cache {
    my( $self ) = @_;

    $self->{_last_cookie} = $self->{_last_answer} = undef;
}

sub _get_answer {
    my( $self, $cookie ) = @_;

    return $self->_last_answer
      if $self->_last_cookie && $self->_last_cookie eq $cookie;
    return [] unless $self->ebug->can( 'package_list' );
    $self->{_last_cookie} = $cookie;
    my @packages = $self->ebug->package_list( $cookie );
    my @subroutines = map "&$_", $self->ebug->symbol_list( $cookie, [ '&' ] );
    return $self->{_last_answer} = [ @packages, @subroutines ];
}

sub get_child_count {
    my( $self, $cookie ) = @_;

    my $data = $self->_get_answer( $cookie );
    return @$data;
}

sub get_child {
    my( $self, $cookie, $index ) = @_;

    my $data = $self->_get_answer( $cookie );
    my $item = $data->[$index];
    if( substr( $item, 0, 1 ) eq ':' ) {
        return ( $item, substr( $item, length( $cookie ) + 2 ) );
    } else {
        return ( $item, '&' . substr( $item, length( $cookie ) + 3 ) );
    }
}

sub has_children {
    my( $self, $cookie ) = @_;

    return substr( $cookie, 0, 1 ) eq ':';
}

1;
