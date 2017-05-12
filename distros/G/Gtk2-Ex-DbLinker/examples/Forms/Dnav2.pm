package Forms::Dnav2;
use strict;
use warnings;
use Carp qw( carp croak confess);
use Data::Dumper;
use Gtk2::Ex::DbLinker::Datasheet;
use Scalar::Util qw( weaken );
my %refs = map { $_, 1 }
    qw(Gtk2::Ex::Datasheet::DBI Linker::Datasheet Gtk2::Ex::DbLinker::Datasheet);
my %ref_form =
    map { $_, 1 } qw(Gtk2::Ex::DBI Linker::Form Gtk2::Ex::DbLinker::Form);

sub new {
    my $class = shift;
    my %def   = ( ismain => 1 );
    my %arg   = ( %def, @_ );
    my $self  = \%arg;
    bless $self, $class;
    $self->{msg} = "Dnav";
    my $builder = Gtk2::Builder->new();

#    %INC is another special Perl variable that is used to cache the names of the files and
#    the modules that were successfully loaded and compiled by use(), require() or do() statements.
# my $path= $INC{"Forms/Dnav2.pm"};

# $path =~ s/\/Forms\/Dnav2.pm// ; #Enlever /Forms/Dnav.pm de $path
#$builder->add_from_file( $path . "\\Forms\\dnav.bld")   or die "Couldn't read  glade/dnav.bld";
    my $path;
    $self->{log}       = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{w2hide}    = [];
    $self->{w2disable} = [];

    # $self->{size}=$size_ref;
    if ( $ENV{PAR_TEMP} ) {
        $path = $ENV{PAR_TEMP} . "/inc/" . "gladefiles/dnav.bld";

        #$path = $ENV{PAR_TEMP}. "/inc/" ."glade/dnav.bld";
    }
    else {
        $path = "./gladefiles/dnav2.bld";
    }
    $builder->add_from_file($path);
    $self->{glade_xml} = $builder;
    my $mainw = $self->{glade_xml}->get_object("mainwindow");

    # $self->list_children($mainw);
    # $self->{glade_xml}->connect_signals($self);
    if ( $self->{ismain} ) {

        $mainw->signal_connect( "destroy", \&gtk_main_quit, $self );
        if ( $self->{dbh} ) {
            $self->show_tables( sql => $self->{sql}, dbh => $self->{dbh} );

        }
    }
    $self->{events_id}       = {};
    $self->{events_callback} = {
        "add"    => \&on_add_clicked,
        "del"    => \&on_delete_clicked,
        "cancel" => \&on_cancel_clicked,
        "apply"  => \&on_apply_clicked
    };
    for my $n ( keys %{ $self->{events_callback} } ) {
        my $id =
            $builder->get_object($n)
            ->signal_connect( 'clicked', $self->{events_callback}->{$n},
            $self );
        $self->{events_id}->{$n} = $id;
    }

=for comment
    my %keep = map {$_ => 1} qw(add);
    $self->populate_widgets( $mainw, \%keep, 1 );
   $self->{sensitivity_current} = 0;
    # $self->{data}= $dataref;
    $self->{log}->debug("w2disable ", Dumper (@{$self->{w2disable}}));
=cut

    return $self;
}

sub set_dataref {
    my ( $self, $dataref ) = @_;

#the line below defined on what the button will call the delete, undo, add calls
#it is the main reason of calling this method and giving it Gtk2::Ex::DbLinker::Form instance
#
    $self->{data} = $dataref;

    # show_all($self);
    croak("No instance found for set_dataref ") unless ($dataref);
    my $ref = ref $dataref;

    # if the instance received is a grid, hide a few things:
    if ( $refs{$ref} ) {

        #my $l = $self->{glade_xml}->get_object('lbl_RecordStatus');
        #$l->hide();
        $self->{ismain} = 0;

       #Gtk2::Widget::hide($self->{glade_xml}->get_object('RecordSpinner'));
       #Gtk2::Widget::hide($self->{glade_xml}->get_object('lbl_recordCount'));
       #Gtk2::Widget::hide($self->{glade_xml}->get_object('menubar1'));
        push @{ $self->{w2hide} },
            (
            $self->{glade_xml}->get_object('RecordSpinner'),
            $self->{glade_xml}->get_object('lbl_recordCount'),
            $self->{glade_xml}->get_object('menubar1'),
            $self->{glade_xml}->get_object('lbl_RecordStatus')
            );
    }
    else {

        carp("$ref not found with set_dataref") unless ( $ref_form{$ref} );

    }
}

sub get_builder {
    my $self = shift;
    return $self->{glade_xml};
}

sub add_widgets2hide {
    my ( $self, @allnames ) = @_;
    foreach my $n (@allnames) {
        push @{ $self->{w2hide} }, $self->{glade_xml}->get_object($n);
    }
}

sub connect_signal_for {
    my ( $self, $btn, $sub_ref, $data, $signal ) = @_;
    my $b = $self->{glade_xml}->get_object($btn);
    croak
        "Dnav connect_signal_for failed since no widget instance exists for $btn"
        unless ($b);
    $signal = ( $signal ? $signal : "clicked" );
    if ( exists ${ $self->{events_id} }{$btn} ) {

        #deconnecter
        my $id = $self->{events_id}->{$btn};
        $b->signal_handler_disconnect($id);
    }
    $b->signal_connect( $signal, $sub_ref, $data );
}

sub show_tables {
    my $self = shift;
    my %arg  = @_;

    #my $dbh = $self->{globals}->{connections}->{dbh};
    my $sth = $arg{dbh}->prepare( $arg{sql} );

    $sth->execute;
    my $menu = $self->{glade_xml}->get_object('menu1');

    # die unless ($menu);
    while ( my @row = $sth->fetchrow_array() ) {

        # print $row[0],"\n";
        my $t = Gtk2::MenuItem->new( $row[0] );
        $t->signal_connect(
            'activate',
            sub {
                $self->display_tbl( { name => $row[0] }, dbh => $arg{dbh} );
            }
        );

        # push @tbl, $t
        $menu->append($t);
        $t->show;
    }

}

sub display_tbl {
    my ( $self, $href ) = @_;
    my $treeview = Gtk2::TreeView->new();

    # a closure where the $self var is sent with $href
    # ref $self is the calling class not Forms::Dnav2
    my $data   = $self->{mibuilder}->($href);
    my $f      = Forms::Dnav2->new( ismain => 0 );
    my $scroll = Gtk2::ScrolledWindow->new;
    $scroll->add($treeview);
    $f->add_ctrl($scroll);

    # print "$name\n";
    my $rs = Gtk2::Ex::DbLinker::Datasheet->new(
        {   treeview     => $treeview,
            data_manager => $data,
        }
    );
    $rs->update;
    $f->set_dataref($rs);

    # $f->test();
    $f->show_all_except( ['menubar1'] );

}

sub show_all_except {
    my ( $self, $ar_ref ) = @_;
    my @size = $self->{size} ? @{ $self->{size} } : ( 800, 400 );
    my $w = $self->{glade_xml}->get_object('mainwindow');
    $w->set_default_size(@size);
    $w->show_all;
    foreach my $name (@$ar_ref) {
        my $w = $self->{glade_xml}->get_object($name);
        $w->hide if ($w);
    }
    foreach my $w ( @{ $self->{w2hide} } ) {
        $w->hide if ($w);
    }
}

sub add_ctrl {
    my ( $self, $ctrl ) = @_;
    my $sfctrl = $self->{glade_xml}->get_object('main');

    #  Gtk2::Widget::reparent($ctrl, $sfctrl);
    # $ctrl->destroy;
    $sfctrl->add($ctrl);
}

#subw is the top frame in the data form that will be place in the main panel (id: main) of the navigation form
#ctrl is the child widget of the data form (usualy a Vbox) (that will be separated from the top level window
#of the dataform) and placed in the main panel of the navigation form
sub reparent {
    my ( $self, $ctrl, $subw ) = @_;

    #get the panel with id=main in the navigation form
    my $sfctrl = $self->{glade_xml}->get_object('main');
    my $title  = $subw->get_title();
    $self->{glade_xml}->get_object('mainwindow')->set_title($title)
        if ($title);
    Gtk2::Widget::reparent( $ctrl, $sfctrl );
    $subw->destroy;
    #my $start = $ctrl->get_parent->get_parent;

    my $start = $self->{glade_xml}->get_object('vbox1_main');
    $self->list_children($start);
    my %keep = map { $_ => 1 } qw(add);

    # $self->populate_widgets( $mainw, \%keep, 1 );
    $self->populate_widgets( $start, \%keep, 1 );
    $self->{sensitivity_current} = 0;

    # $self->{data}= $dataref;
    $self->{log}->debug( "w2disable ", sub {Dumper( @{ $self->{w2disable} })} );
    $self->{top_widget} = $ctrl;

}

sub on_add_clicked    { my ( $b, $self ) = @_; $self->{data}->insert; }
sub on_cancel_clicked { my ( $b, $self ) = @_; $self->{data}->undo; }
sub on_delete_clicked { my ( $b, $self ) = @_; $self->{data}->delete; }
sub on_apply_clicked  { my ( $b, $self ) = @_; $self->{data}->apply; }

sub widgets_set_sensitivity {
    my $self = shift;
    my ($val) = @_;
    return if ( $val == $self->{sensitivity_current} );
    $self->{log}->debug( "set_sensitivity $val size: ",
        scalar @{ $self->{w2disable} } );

    for my $w ( @{ $self->{w2disable} } ) {

        $self->{log}->debug( "set_sensitivity ", $w->get_name );
        $w->set_sensitive($val);
    }
    $self->{sensitivity_current} = $val;

}

sub set_sensitivity_for {
    my ( $self, $id ) = @_;
    my $w = $self->{glade_xml}->get_object($id);
    confess( "No widget with ID ", $id ) unless defined($w);
    my $p = $w->get_parent;
    my %parents;
    my $order = 0;
    $parents{ $order++ } = $w;
    while ( defined $p ) {
        last if ( $p->is_sensitive );
        $self->{log}->debug( "parent :", ref $p, " ID ", $self->getID($p),
            " sensitive ", $p->is_sensitive );
        $parents{ $order++ } = $p;
        $p = $p->get_parent;
    }

    #$self->{log}->debug( $w->is_sensitive())
    #$self->{log}->debug(Dumper %parents);
    #$self->{log}->debug("last order ", $order);
    my $pos = $order - 1;
    while ( $pos > -1 ) {
        $parents{$pos}->set_sensitive(1);
        $self->{log}
            ->debug( "set_sensitive ", $self->getID( $parents{$pos} ) );
        $pos = $pos - 1;
    }
}

sub populate_widgets {
    my $self = shift;
    my ( $w, $keepit, $no_warn ) = @_;

#print "populate widgtets ", $w->get_name, " " , ref $w, " ", ( $w->isa('Gtk2::Container') ? " is a container" : " is not a container"), "\n";
# print "populate widgets ", join(" ", @{ $self->{w2disable} }), "\n";
    return unless $w->isa('Gtk2::Container');

    my @c = $w->get_children;
    if ( !defined $no_warn && scalar @c == 0 ) {
        carp "populate widgets received a conainer widget with no children";
    }
    for my $c ( $w->get_children ) {
        my $name = $c->get_name;

        # print "populate widgets 1: $name\n";
        my $id = $self->getID($c);
        if (   $c->get_sensitive
            && $c->isa('Gtk2::Buildable')
            && $name ne "GtkVBox"
            && $name ne "GtkHBox"
            && $id ne "" )
        {

            # print "populate widgets 2: $id $name\n";
            unless ( $keepit->{$id} ) {

                # $c->set_sensitive(0);
                push @{ $self->{w2disable} }, $c;
            }
        }
        $self->populate_widgets( $c, $keepit, 1 );
    }

}

sub getID {
    my $self = shift;
    my $w    = $_[0];
    my $ref  = ref $w;
    my $id;

    # get the id
    #print "$ref\n";
    if ($w) {
        $id = ( bless $w, "Gtk2::Buildable" )->get_name;

        # restore package
        bless $w, $ref;
    }
    return ( $id ? $id : "" );
}

sub get_object {
    my ( $self, $ctrl_name ) = @_;
    $self->{glade_xml}->get_object($ctrl_name);
}

sub list_children {
    my ( $self, $w ) = @_;
    return unless defined($w);
    $self->{log}->debug( "list_children :", ref $w, " ", $self->getID($w) );
    return unless $w->isa('Gtk2::Container');
    for my $c ( $w->get_children ) {
        $self->list_children($c);
    }

}

sub test { my $self = shift; print $self->{msg}, " in dnav.pm\n"; }

sub gtk_main_quit {
    my ( $w, $self ) = @_;

    # print Dumper @_;
    weaken $self->{mibuilder};
    Gtk2->main_quit;
}

1;
__END__

=head1 NAME

Package Forms::Dnav

A Navigation toolbar (nvabar for short), that can be used for a mainwindow, and that has two predefinned menu, or that can be used to navigate the records in a subform (and the menu are hidden then).

This module should be placed under a lib directory and the PERL5LIB environment variable should point to it.

=head1 
Depends also on

=over

=item *
Forms::Tools

=item *
a glad xml file with path lib/Forms/dnav.bld and the lib directory beeing define in the PERL5LIB environement variable (ie U:\docs\perl\lib on my pc)

=back

=head1 
SYNOPSIS

	$self->{dnav} = Forms::Dnav->new();
	my $b = $self->{dnav}->get_builder;
	$b->add_from_file( some glade files ) or die "Couldn't read ...";
	$b->connect_signals($self);


Build a navbar around a mainform

	$self->{dnav} =  Forms::Dnav->new(0);

Get a new Dnav object that will be used for a subform navigation. The predefinned menu in the navbar will not show

	$self->{dnav}-connect_signal_for("button name", \&code_ref, $data, $signal);

	$self->{dnav}->connect_signal_for("mainwindow", \&gtk_main_quit, $self, "destroy" ); 

Where

=over

=item *
button name is the button id in the glade file

=item *
&code_ref is a function to be called on click (default) unless a string is given in $signal

=item *
$data a ref to the Dnav object or to the main form object

=back 
	  
	$self->{dnav}->set_dataref($self->{jrn});
 
Where

=over

=item *
C<< $self->{jrn} >> est une ref E<agrave> un recordset issu de C<< Gtk2::Ex::DBI->new () >>

=back


	  my $w =$self->{glade_xml}->get_object('jrn');
  	  my $ctr= $self->{glade_xml}->get_object('vbox1');

	   $self->{dnav}->reparent($ctr, $w);
 
Where

=over

=item  *
C<< $self->{glade_xml}->get_object('jrn'); >> is a ref to the top window of the form

=item *
C<<  $self->{glade_xml}->get_object('vbox1'); >> is a ref to the first vbox that is a child of this top window

=item *
C<< $self->{dnav}->reparent($ctr, $w); >> place the content of the C<$ctr>  widget in the navbar, take the title of C<$w> and place it in the navbar and destroy this window

=back

=cut
