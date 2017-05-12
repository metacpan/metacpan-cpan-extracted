package GappX::FileTree;

our $VERSION = 0.03;

use Moose;
extends 'Gapp::TreeView';

use Gapp::TreeStore;
use Gapp::TreeViewColumn;

use File::Find;

has '+columns' => (
    default => sub {
        [
            Gapp::TreeViewColumn->new(
                title => 'Files',
                name => 'files',
                renderer => undef,
                customize => sub {
                    my ( $self ) = @_;
                    
                    my $pixrender = Gtk2::CellRendererPixbuf->new();
                    $self->gobject->pack_start( $pixrender, 0);
                    $self->gobject->set_attributes( $pixrender, 'stock-id', 2 );
                    
                    my $textrender = Gtk2::CellRendererText->new();
                    $self->gobject->pack_start( $textrender, 1 );
                    $self->gobject->set_attributes( $textrender, 'markup', 1 );
                    
                },
            )
        ]
    },
    lazy => 1,
);

has 'filter_func' => (
    is => 'rw',
    isa => 'Maybe[CodeRef]',
);

has '+model' => (
    default => sub {
        Gapp::TreeStore->new(
            columns => [qw( Glib::String Glib::String Glib::String Glib::Boolean )],
            customize => sub {
                $_[0]->gobject->set_sort_func( 0, sub {
                    my ( $model, $itera, $iterb, $self ) = @_;
                    
                    my $dira = $model->get( $itera, 3 );
                    my $dirb = $model->get( $iterb, 3 );
                    my $texta = $model->get( $itera, 1 );
                    my $textb = $model->get( $iterb, 1 );
                    
                    no warnings;
                    $dirb <=> $dira || lc $texta cmp lc $textb;
                } );
                
                $_[0]->gobject->set_sort_column_id( 0, 'ascending' );
            },
        )
    },
    lazy => 1,
);

has 'path' => (
    is => 'rw',
    isa => 'Str',
    default => '.',
    trigger => sub {
        my ( $self, $newval, $oldval ) = @_;
        
        if ( $newval ne $oldval ) {
            $self->update if $self->has_gobject;
        }
        
    }
);

after _build_gobject => sub {
    #$_[0]->update;
};


sub update {
    my ( $self ) = @_;
    
    
    $self->model->gobject->clear;
    
    my $m = $self->model->gobject;
    
    my $base = $self->path;
    $base =~ s/(\/|\\)\s*$//; # remov trailing slash
    my $baserx = quotemeta $base;
    
    my @path;
    
    my $iter = undef;
    
    find (
        sub {
            return if $_ eq '.';
            
            if ( $self->filter_func ) {
                return if $self->filter_func->( $self, $_, $File::Find::name, $File::Find::dir );
            }
            
            my $dir = $File::Find::dir;
            $dir =~ s/^$baserx//;
            my @dirs = split /\/|\\/, $dir;
            shift @dirs if @dirs && ! $dirs[0];
            
            # if this is a directory
            if ( -d $_ ) {
                
                if ( @path ) {

                    if ( ! @dirs ) {
                        while ( @path ) {
                            $iter = $m->iter_parent( $iter ) if $iter;
                            pop @path;
                        }
                        
                    }
                    else {
                        no warnings;
                        while ( $path[-1] ne $dirs[-1] ) {
                            $iter = $m->iter_parent( $iter ) if $iter ;
                            pop @path;
                        }
                        
                        
                    }
                }
                
                
                if ( @path && ( ! @dirs || $path[-1] ne $dirs[-1] ) ) {
                    $iter = $m->iter_parent( $iter ) if $iter ;
                    pop @path;
                }
                
                my $i = $m->append( $iter );
                $m->set( $i, 0 => $File::Find::name , 1 => $_, 2 => 'gtk-directory', 3 => 1 );
                $iter = $i;
                push @path, $_;
            }
            # if this is a file
            else {
                my $i = $m->append( $iter );
                $m->set( $i, 0 => $File::Find::name , 1 => $_, 2 => 'gtk-new', 3 => 0 );
            }
        },
        $self->path
    );

}

sub _get_selected_data {
    my ( $self ) = @_;
    my $iter =  $self->view->gobject->get_selection->get_selected;
    return if ! $iter;
    my $model = $self->view->gobject->get_model;
    return [$model->get( $iter, 0, 1, 2, 3 )];
}


sub selected_is_dir {
    my ( $self ) = @_;
    my $iter =  $self->gobject->get_selection->get_selected;
    return if ! $iter;
    my $model = $self->gobject->get_model;
    return $model->get( $iter, 3 ) ? 1 : 0;
}

package Gapp::Layout::Default;
use Gapp::Layout;

build 'GappX::FileTree', sub {
    my ( $l, $w ) = @_;
    my $gtkw = $w->gobject;
    $gtkw->set_model( $w->model->isa('Gapp::Object') ? $w->model->gobject : $w->model ) if $w->model;
};

1;


__END__

=pod

=head1 NAME

GappX::FileTree - FileTree widget for Gapp

=head1 SYNOPSIS


    use GappX::FileTree;

    $w = GappX::FileTree->new( path => 'path/to/view/ );

    $w->refresh;

    Gapp->main;

=head1 DESCRIPTION

GappX::FileTree is a TreeView widget for displaying the structure of a file
system. Directories expand and collapse and each item is displayed with an
icon.
  
=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::TreeView>

=item ........+-- L<Gapp::FileTree>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<filter_func>

=over 4

=item is rw

=item isa CodeRef|Undef

=item default .

=back

Use this function to filter the files displayed in the view.

=item B<path>

=over 4

=item is rw

=item isa Str

=item default .

=back

The directory path to display in the widget.

=back

=head PROVIDED METHODS

=over 4

=item B<update>

Refresh the contents of the display. Call this after setting the C<path> attribute
or after changes have been made to the file system.

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut


