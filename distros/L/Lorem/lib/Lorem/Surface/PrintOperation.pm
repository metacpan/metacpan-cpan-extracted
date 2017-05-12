package Lorem::Surface::PrintOperation;
{
  $Lorem::Surface::PrintOperation::VERSION = '0.22';
}

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

use Gtk2;

has 'gtk2_po' => (
    is => 'rw',
    isa => 'Gtk2::PrintOperation',
    lazy_build => 1,
);

has 'gtk_window' => (
    is => 'rw',
    isa => 'Gtk2::Window',
);


sub _build_gtk2_po {
    my $po = Gtk2::PrintOperation->new;
    $po->set_unit('points');
    $po->set( 'use-full-page', 1);
    return $po;
}

sub print  {
    
    my ( $self, $doc ) = @_;
    
    my $po = $self->gtk2_po;
    
    $po->signal_connect('begin-print' => sub {
        my ($po, $print_context) = @_;
        
        my $cr = $print_context->get_cairo_context;
        $doc->set_width( $print_context->get_width -  36);
        $doc->set_height( $print_context->get_height - 36);
        
        
        &{$doc->builder_func}( $doc, $cr ) if $doc->builder_func;
        
        my @pages = @{$doc->children};
        $po->set_n_pages( scalar @pages );
    });
    
    $po->signal_connect('draw-page' => sub {
        my ($po, $print_context, $number) = @_;
        my $cr = $print_context->get_cairo_context;
        my @pages = @{$doc->children};
        $pages[$number]->imprint( $cr );
        $cr->show_page;
    });
    
    $po->run('print-dialog', $self->gtk_window);
}


1;
