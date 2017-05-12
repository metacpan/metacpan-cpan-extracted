package Maypole::FormBuilder::Model;
use warnings;
use strict;

use base qw( Maypole::Model::Base Class::DBI );
use Class::DBI::Loader;
use Class::DBI::AbstractSearch;
use Class::DBI::Plugin::RetrieveAll;
use Class::DBI::FormBuilder 0.43;
use List::Util();

use Maypole::FormBuilder;

our $VERSION = $Maypole::FormBuilder::VERSION;

=head1 NAME

Maypole::FormBuilder::Model

=head1 SYNOPSIS

    BeerFB->config->model( 'Maypole::FormBuilder::Model' );

=head1 Major surgery

This class does not inherit from L<Maypole::Model::CDBI|Maypole::Model::CDBI>, for several 
reasons. We don't need to load Class::DBI::Untaint, Class::DBI::AsForm or Class::DBI::FromCGI. 
I wanted to implement a config option to choose which pager to use (see C<do_pager>). And I 
wanted to rename methods that share a name with methods in Class::DBI (C<delete> and C<search> are 
now C<do_delete> and C<do_search>).

Maypole is pretty stable these days and it should be easy enough to keep up with any bug fixes. 

=head1 METHODS

=over 4

=cut
    
{

    my ( $proto, $r, $args, $mode, $mode_args, $pk, %additional );

    # build a dispatch table of coderefs    
    my $Setup = {
        # -------------------------
        LIST => sub 
        {
            $args->{action} = $r->make_path( table  => $proto->table, 
                                             action => 'list',
                                             );
        },
        
        # -------------------------
        ADDNEW => sub 
        {
            $args->{action} = $r->make_path( table  => $proto->table, 
                                             action => 'addnew',
                                             );
                                            
            $args->{fields} = [ $proto->addnew_columns, $proto->addnew_fields ];
            
            $args->{entity} = $r->model_class;
            $args->{reset}  = 'reset';
            $args->{submit} = 'submit';
            $args->{sticky} = 0;
        },
        
        # -------------------------
        SEARCH => sub 
        # Usually, a search form is specified by setting the mode in a template (e.g. the 
        # list template). So it's fine to manually set the mode to 'search'. But if you want 
        # to have a separate search page, don't put it 
        # at $base/$table/search, because that'll execute the CDBI search method. Put 
        # it at $base/$table/do_search, or better yet, create your own modes and templates 
        # for $base/$table/advanced_search, $base/$table/simple_search etc.
        {
            $args->{action} = $r->make_path( table  => $proto->table, # $r->table,
                                            action => 'do_search',
                                            );
                                            
            $args->{fields} ||= [ ( $proto->search_columns, $proto->search_fields ) ];
            
            # Remember search terms *if* the current request is processing a search form
            # (note that normally, the search form is being built in the list template, so the action 
            # is 'list'. If the list template were in 'editable' mode, and an update was submitted, 
            # and the search form was in sticky mode, it would end up populated with the values from 
            # the update).
            $args->{sticky} = $r->action =~ /^(?:do_)?search$/;
            
            # see http://dev.mysql.com/doc/mysql/en/pattern-matching.html for a useful summary of using the 
            # different operators in MySQL
            my $cmp = [ ( '=', '!=', '<', '<=', '>', '>=', 
                        'LIKE', 'NOT LIKE', 
                        'REGEXP', 'NOT REGEXP', 
                        'REGEXP BINARY', 'NOT REGEXP BINARY', 
                        ) ];
                        
            $args->{submit} = 'submit';
            $args->{reset}  = 'reset';
            
            # to just offer a few: $args{search_opt_order_by} = [ 'foo', 'foo DESC', 'bar' ];
            $args->{search_opt_order_by} = 1;
            
            # tr set the cmp operator transparently via a hidden field: $args{search_opt_cmp} = 'LIKE';
            $args->{search_opt_cmp} = $cmp;
            
            my $size = @$cmp + 1;
            
            $args->{process_fields}->{search_opt_cmp}      = [ '+SET_label(Search operator)', "+SET_size($size)" ];
            $args->{process_fields}->{search_opt_order_by} = '+SET_label(Order by)';
        },
        
        # -------------------------
        BUTTON => sub 
        {
            my $button_name = $1;
            
            my %despatch = ( delete => 'do_delete' );
            
            my $maypole_action = $despatch{ $button_name } || $button_name;
            
            $args->{action} = $r->make_path( table      => $proto->table, 
                                             action     => $maypole_action,
                                             %additional, 
                                             );
            
            $args->{fields}   = [];
            $args->{required} = []; # otherwise, CDBI::FB may add required cols, and the button gets a
                                    # heading about 'highlighted fields are required', even though it 
                                    # has no fields
            $args->{submit}   = $button_name;
            $args->{table}    = 0; # don't place the form inside a table
            
            if ( $button_name eq 'delete' )
            {
                $args->{jsfunc} = '
                    if (form._submit.value == "delete") {
                        if (confirm("Really DELETE this entry?")) return true;
                        return false;
                    }';
            }
        },
        
        # -------------------------
        EDITLIST => sub 
        # This is for generating a single form (i.e. row) within the editable list table. 
        # Note that although it's a 'list' action, it is associated with a single object 
        # (specified in %additional). The list() public method does whatever needs to be 
        # done with that object, and then returns via _list(), which regenerates the list 
        # page.
        {
            $args->{action} = $r->make_path( table      => $proto->table, # $r->table
                                            action     => 'editlist',
                                            %additional,
                                            );
                                            
            $args->{fields} = [ $proto->list_columns, $proto->list_fields ];
            
            # Note: turn off stickiness. Otherwise, all the forms will display the values submitted 
            # in the previous action, e.g. addnew.
            $args->{submit}          = [ qw( view update edit delete ) ];
            $args->{reset}           = 'reset';
            $args->{selectnum}       = 2;
            $args->{no_textareas}    = 1;
            $args->{sticky}          = 0;
            
            $args->{jsfunc}          = qq(
                if (form._submit.value == "delete") {
                    if (confirm("Really DELETE this entry?")) return true;
                    return false;
                }
            );
                                    
        },
        
        # -------------------------
        EDIT => sub 
        {
            $args->{action} = $r->make_path( table      => $proto->table,
                                             action     => 'do_edit',
                                             %additional, 
                                             );
                                            
            $args->{reset}  = 'reset';
            $args->{submit} = [ qw/ submit view / ];
            $args->{fields} = [ $proto->edit_columns ]; # $proto->related ];
            
            # see note in EDIT_ALL_HAS_A
            $args->{sticky} = 0;
        },
        
        
        # -------------------------
        # this is basically similar to EDIT, but needs a separate edit_all_has_a() exported method 
        # to return to the parent object's edit template after submitting
        EDIT_ALL_HAS_A => sub
        {
            # If there is no child object yet, then $proto is initialised as an object 
            # with id 0, which generates a form with a different name from the one 
            # generated for the server (the client form includes '_0' at the end).
            if ( ref( $proto ) and $proto->id == 0 )
            {
                $proto = ref $proto;
                %additional = ();
                $args->{entity} = $proto;
            }
        
            $args->{action} = $r->make_path( table      => $proto->table,
                                             action     => 'edit_all_has_a',
                                             %additional, 
                                             );
                                            
            $args->{reset}  = 'reset';
            $args->{submit} = 'submit';
            $args->{fields} = [ $proto->edit_columns ]; #, # $proto->related ];
            
            $args->{process_extras} = [ qw( __parent_class__ __parent_id__ ) ];
            
            # The appropriate setting will depend on your detailed setup and workflows. In the default 
            # setup, the edit page displays multiple forms, and after submitting one, the app returns to 
            # the edit page. If any other forms on the page have fields with the same name as the submitted 
            # form, they will pick up the submitted value if 'sticky' is on.
            # This could probably be fixed by issuing a redirect to the edit page after processing a submission, 
            # rather than using the template switcheroo.
            $args->{sticky} = 0;
                
            if ( my $parent = $mode_args->{parent} )
            {
                # client form
                my $parent_class = ref $parent;
                my $parent_id    = $parent->id;
                
                $args->{process_fields}->{__parent_class__} = [ "+SET_value($parent_class)", '+HIDDEN' ];
                $args->{process_fields}->{__parent_id__}    = [ "+SET_value($parent_id)",    '+HIDDEN' ];
            }
            else
            {   # server form - must ensure the fields exist on the form, so their values can be extracted
                $args->{process_fields}->{__parent_class__} = '+ADD_FIELD'; 
                $args->{process_fields}->{__parent_id__}    = '+ADD_FIELD'; 
            }        
        },
        
        # -------------------------
        EDITRELATED => sub 
        {
            $args->{action} = $r->make_path( table      => $proto->table,
                                            action     => 'editrelated',
                                            %additional, 
                                            );
        },
        
        # -------------------------
        ADDTO => sub 
        {
            $args->{action} = $r->make_path( table      => $proto->table,
                                            action     => 'addto',
                                            );
                                            
            $args->{process_extras} = [ qw( __target_class__ __target_id__ ) ];
                                            
            if ( $mode_args )
            {   # client form
            
                # build a form representing $proto, which is the class at the 'many' end 
                # of a has_many relationship from $add_to, via the field/accessor $field on $add_to 
                # i.e. $add_to->$field returns many $proto's
                
                # the form has 2 extra hidden fields, to identify $add_to 
                
                # so when the submitted form is processed, it will retrieve $add_to by looking up 
                # id $target_id in class $target_class, figure out the appropriate accessor (i.e. 
                # figure out $field from the class of the submitted form i.e. $proto), and use that 
                # information to add a new entry to $add_to
                
                my $add_to = $mode_args->{addto} || die "no parent object for building client form";
                my $field  = $mode_args->{field} || die "don't know which field of \$addto to use";
                
                my $accessor = $add_to->meta_info( has_many => $field )->{args}->{foreign_key};
                
                my $target_class = ref( $add_to );
                my $target_id    = $add_to->id;
                
                # XXX: see ADDMANY for passing arguments in the form action url
                $args->{process_fields}->{__target_class__} = [ "+SET_value($target_class)", '+HIDDEN' ];
                $args->{process_fields}->{__target_id__}    = [ "+SET_value($target_id)",    '+HIDDEN' ];
                $args->{process_fields}->{ $accessor }      = [ "+SET_value($target_id)",    '+HIDDEN' ];
            }
            else
            {   # server form - must ensure the fields exist on the form, so their values can be extracted
                $args->{process_fields}->{__target_class__} = '+ADD_FIELD'; 
                $args->{process_fields}->{__target_id__}    = '+ADD_FIELD'; 
            }
        },
        
        # -------------------------
        ADDHOWMANY => sub 
        {
            $args->{action} = $r->make_path( table      => $proto->table,
                                             action     => 'addhowmany',
                                             );
                                             
            $args->{fields} = [];
            $args->{table}  = 0;
            $args->{submit} = 'add...';
            
            $args->{process_extras} = [ qw( __how_many__ __target_class__ __target_id__ ) ];
            
            if ( $mode_args )
            {
                # client form
                
                my $add_to = $mode_args->{addto} || die "no parent object for building client form";
                
                my $target_class = ref( $add_to );
                my $target_id    = $add_to->id;
                
                my $options = [ 2 .. $mode_args->{how_many} ];
                                                
                $args->{options} = { __how_many__ => $options };
                
                $args->{process_fields} = { __how_many__ => [ "+SET_label(Add several:)", 
                                                              "+SET_value(2)",
                                                              "+SET_style(width:4em)",
                                                              ] };
        
                # XXX: see ADDMANY for passing arguments in the form action url
                $args->{process_fields}->{__target_class__} = [ "+SET_value($target_class)", '+HIDDEN' ];
                $args->{process_fields}->{__target_id__}    = [ "+SET_value($target_id)",    '+HIDDEN' ];
            }
            else
            {
                # server form
                $args->{process_fields}->{__how_many__}     = '+ADD_FIELD'; 
                $args->{process_fields}->{__target_class__} = '+ADD_FIELD'; 
                $args->{process_fields}->{__target_id__}    = '+ADD_FIELD'; 
            }
        },
        
        # -------------------------
        ADDMANY => sub 
        {
            $args->{fields} = [ $proto->addmany_columns, $proto->addmany_fields ];
            
            # set and hide the related item value (i.e. the field in the table at the 'many' end 
            # of the has_many relationship, which points back to the table at the 'has' end 
            # (because the 'many' table also 'has_a' the parent table)
            if ( my $add_to = $mode_args->{addto} )
            {
                # client form
                my $how_many = $mode_args->{how_many} or die "need to know how many";
                
                my $target_id = $add_to->id;
                
                # what field of $proto has_a $addto?
                my $accessor_name;
                foreach my $has_a ( values %{ $proto->meta_info( 'has_a' ) || {} } )
                {
                    next unless $has_a->foreign_class eq ref $add_to;
                    my $accessor = $has_a->accessor; # a CDBI::Column object
                    $accessor_name = $accessor->name;
                    last if $accessor;            
                }
                
                $args->{action} = $r->make_path( table      => $proto->table,
                                                 action     => 'addmany',
                                                 additional => "$accessor_name/$how_many",
                                                 );
                
                $args->{process_fields}->{ $accessor_name } = [ "+SET_value($target_id)", '+HIDDEN' ];
            }
            else
            {
                # server form 
                $args->{action} = $r->make_path( table  => $proto->table,
                                                 action => 'addmany',
                                                 );
        
            }
        },
        
        
    
    }; # / $Setup
    
=item setup_form_mode

This method is responsible for ensuring that the 'server' form and the 'client' form are 
equivalent - see I<Coordinating client and server forms>.

Returns a form spec for the selected form mode. The mode defaults to C<< $r->action >>. 
You can set a different mode in the args hash to the C<as_form> call. 

Override this in model classes to configure custom modes, and call 

    $proto->SUPER::setup_form_mode( $r, $args )
    
in the custom method if it doesn't know the mode.

You can add a C<mode_args> argument to the hashref of arguments that reach C<setup_form_mode>. For 
instance, the C<addto> template uses this to pass 

Modes supported here are:

    list
    addnew
    search
    do_search
    ${action}_button    where $action is any public action on the class
    editlist
    edit
    edit_all_has_a
    do_edit
    editrelated
    addto
    addhowmany
    addmany
    
=cut

    # -----------------------------
    # note - arguments shared with the dispatch table are declared above the table, not here
    sub setup_form_mode
    {
        ( $proto, $r, $args ) = @_;
        
        # the mode is set in _get_form_args
        $mode = delete $args->{mode} || die "no mode for $proto";
        
        $mode_args = delete $args->{mode_args};
        
        $pk = $proto->primary_column;
            
        # this is probably unnecessary, as not used often, and will probably go away soon
        %additional = ref( $proto ) ? ( additional => $proto->$pk ) : ();
        
        CASE:
        {
            $Setup->{LIST}->(),         last CASE if $mode eq 'list';
            $Setup->{ADDNEW}->(),       last CASE if $mode eq 'addnew';
            $Setup->{SEARCH}->(),       last CASE if $mode =~ /^(?:do_)?search$/;
            $Setup->{BUTTON}->(),       last CASE if $mode =~ /^(\w+)_button$/;
            $Setup->{EDITLIST}->(),     last CASE if $mode eq 'editlist';
            $Setup->{EDIT}->(),         last CASE if $mode =~ /^(?:do_)?edit$/;
            $Setup->{EDIT_ALL_HAS_A}->(),last CASE if $mode eq 'edit_all_has_a';
            $Setup->{EDITRELATED}->(),  last CASE if $mode eq 'editrelated';
            $Setup->{ADDTO}->(),        last CASE if $mode eq 'addto';
            $Setup->{ADDHOWMANY}->(),   last CASE if $mode eq 'addhowmany';
            $Setup->{ADDMANY}->(),      last CASE if $mode eq 'addmany';
            
            
            
            die "No form specification found for mode '$mode' on item '$proto'";
        }
        
        # the coderefs all operate on $args
        return $args;
    }
}    

# ---------------------------------------------------------------------------------- utility -----

=back

=head2 Column and field lists

Standard Maypole defines a few methods to return different lists of columns and column-like 
accessors (C<display_columns>, C<list_columns>, and C<related>). Several more methods are 
added here, and are used in the templates, but in general they will default to return the 
same list as one of the standard methods. 

The rationale is that in general, each template may need to display a different view of the 
object(s) (C<edit>, C<view>, C<list>, C<search> etc.). Your own templates can use these methods,
and you will probably want to define additional column/field listing methods in your custom 
models and templates.

Each C<*_columns> method has a matching <*_fields> method, which can be used to add non-column 
fields (i.e. C<has_many> accessors) to the relevant form. (For C<display_columns>, the relevant 
fields method is C<related>).

=over

=item display_columns

Returns a list of columns, minus primary key columns, which probably don't 
need to be displayed. The templates use this as the default list of columns 
to display. 

Note that L<Class::DBI::FormBuilder|Class::DBI::FormBuilder> will add back in 
B<hidden> fields for the primary key(s), to support lookups done in several of 
its C<*_from_form> methods. 

=item display_fields

Defaults to C<related()>.

=item related

Returns a list of accessors for C<has_many> related classes. These can appear as fields in a 
form, but are not columns in the database. 

=item list_columns

This method is not defined here, but in L<Maypole::Model::Base|Maypole::Model::Base>, and 
defaults to C<display_columns>. This is used to define the columns displayed in the C<list> 
template. 

=item list_fields

Defaults to C<related>. 

The C<list> template uses C<list_columns> plus C<list_fields> as the default list of fields to 
display, and C<setup_form_mode> sets C<list_columns> plus C<list_fields> in the C<fields> 
argument in C<editlist> mode, so that editable and navigable list views both present the same 
fields. 

=item search_columns

Used to build the search form. Defaults to C<display_columns>.

=item search_fields

Used to build the search form. Defaults to an empty list.

=item edit_columns

Defaults to C<display_columns>.

=item edit_fields

Defaults to  C<related>. Used in the C<edit> template to display values of C<has_many> fields 
and build separate forms for adding more items to a C<has_many>.

=item addnew_columns

Defaults to C<display_columns>.

=item addnew_fields

Defaults to empty list, at least until I add C<addmany> support to C<addnew>.

=item addmany_columns

=item addmany_fields

=item view_columns

=item view_fields

=cut

sub display_columns
{ 
    my ( $proto ) = @_;
    
    my %pk = map { $_ => 1 } $proto->primary_columns;
    
    return grep { ! $pk{ $_ } } Class::DBI::FormBuilder->table_meta( $proto )->columns( 'All' ), 
        $proto->related;
}

sub list_fields { }

sub search_columns { shift->display_columns }
sub search_fields  {}

sub edit_columns { shift->display_columns }
sub edit_fields  { shift->related }

sub addnew_columns { shift->display_columns }
sub addnew_fields  { }

sub addmany_columns { shift->display_columns }
sub addmany_fields  { }

sub view_columns { shift->display_columns }
sub view_fields  {  }

=item hasa_columns

=cut

sub hasa_columns
{
    my ( $proto ) = @_;
    
    my $has_a = $proto->meta_info( 'has_a' );
    
    my @ordered = grep { $has_a->{ $_->name } && $has_a->{ $_->name }->foreign_class->isa( 'Class::DBI' ) } 
                  Class::DBI::FormBuilder->table_meta( $proto )->columns( 'All' );
                  
    return @ordered;
}

=item field_names

Counterpart to C<MP::Model::Base::column_names>. Returns a hash of field names to 
field labels.

=cut

sub field_names
{
    my ( $proto ) = @_;
    
    map {
        my $col = $_;
        $col =~ s/_+(\w)?/ \U$1/g;
        $_ => ucfirst $col
    } $proto->related; # has_many accessors

}

=item param

Same interface as CGI's C<param> method, except read-only, for the moment. 

Useful for example with L<HTML::FillInForm>:

    my $cd = My::Music::CD->retrieve( $id );
    
    # $html contains an empty form
    $html = HTML::FillInForm->new->fill( scalarref => \$html, fobject => $cd );

Note that this method always returns scalars. For columns that inflate to non-CDBI 
objects, the object is evaluated in string context. For columns that inflate to a CDBI 
object, the raw column value is returned instead.

=cut

# must not return object - HTML::FillInForm chokes
sub param
{
    my ($self, $key) = @_;
    
    die "param() is an instance method: called on class $self" unless ref $self;
    
    return map {$_->name} $self->columns unless $key;
    
    my $column = $self->find_column($key) || return;
    
    my $accessor = $column->accessor;
    
    my $value = $self->$accessor;
    
    return $value unless ref $value;
    
    return ''.$value unless UNIVERSAL::isa( $value, 'Class::DBI' );
    
    return $value->id;
}

# ------------------------------------------------------------ exported methods -----

=back

=head2 Exported methods

Exported methods have the C<Exported> attribute set. These are the methods that URLs can trigger. 
See the main Maypole documentation for more information. 

As a convenience and a useful convention, all these methods now set the appropriate template, 
so it shouldn't be necessary to set the template and then call the method. This is particularly useful in 
despatching methods, such as C<editlist>.

Some exported methods are defined in L<Maypole::FormBuilder::Model::Base|Maypole::FormBuilder::Model::Base>, 
if they have no dependency on CDBI. But the likelihood of a FormBuilder distribution that doesn't depend 
on L<Class::DBI::FormBuilder|Class::DBI::FormBuilder> is pretty low.

=over 4

=item addnew

The way L<CGI::FormBuilder|CGI::FormBuilder> handles different button clicks (i.e. it handles them), 
means we need a separate method for creating new objects (in standard Maypole, addnew 
posts to C<do_edit>). But L<Class::DBI::FormBuilder|Class::DBI::FormBuilder> keeps things 
simple.

Note this method returns to the C<edit> template, which is useful in some situations, but for many apps, you 
probably want to return the user to the C<view> template instead. Simply override C<addnew> in your model, 
perhaps calling C<< $self->SUPER::addnew >> to perform the update, then return vis C<< $self->view( $r ) >>.

=cut

sub addnew : Exported
{
    my ( $self, $r ) = @_;
    
    my $form = $r->as_form;
    
    return unless $form->submitted && $form->validate;
    
    my $new = $r->model_class->create_from_form( $form ) || die "Unexpected create error";

    # to return to the list view:    
    #return $self->list( $r );
    
    # to return to the view of the new object:
    #$r->objects( [ $new ] );
    #return $self->view( $r );
    
    # to return to the edit template:
    $r->objects( [ $new ] );
    return $self->edit( $r );    
}

=item addto

Adds a new item in a C<has_many> relationship.

=cut

# example: a brewery has_many beers, we're adding a new beer

# Don't need to know anything about the target class (brewery) to create the 
# new related item (beer),  because the id of the target class (brewery) is 
# already supplied in the form submission i.e. the submitted form has details 
# of a new beer, *including* the id of the brewery. 

# The beer has_a brewery, so creating the new beer with the brewery id in place 
# is the same as saying $brewery->add_to_beers( $beer )
sub addto : Exported
{
    my ( $self, $r ) = @_;
    
    my $form = $r->as_form;
    
    # create_from_form tests $form->submitted && $form->validate
    # If the test fails, we get an addto form again, populated with the
    # data in the submission (i.e. sticky), and with validation
    # errors reported by CGI::FB in the form.
    return unless $r->model_class->create_from_form( $form );
    
    my $add_to_class = $form->field( '__target_class__' );
    my $add_to_id    = $form->field( '__target_id__' );
    my $add_to       = $add_to_class->retrieve( $add_to_id );
    
    $r->objects( [ $add_to ] );
    $r->model_class( $add_to_class );
    
    return $add_to->edit( $r ); # or view etc.
} 

=item addhowmany

Receives the number of requested items and forwards to the C<addmany> template.

=cut

sub addhowmany : Exported
{
    my ( $self, $r ) = @_;
    
    my $form = $r->as_form;
    
    return unless $form->submitted && $form->validate;
        
    my $add_to_class = $form->field( '__target_class__' );
    my $add_to_id    = $form->field( '__target_id__' );
    
    my $add_to = $add_to_class->retrieve( $add_to_id );
    
    $r->template_args->{how_many} = $form->field( '__how_many__' );
    $r->template_args->{add_to}   = $add_to;
    
    $r->template( 'addmany' );    
}

=item addmany

Add several items to the target, where <target_class has_many items>.

=cut

# e.g. a brewery has_many beers

# $self is Beer (i.e. the class name of the 'many')
# $accessor is the has_a accessor on Beer i.e. Beer->brewery
# $owner is the item that has_many i.e. $brewery

# - split the submitted data into groups
# - munge column names, and send each group to $self->create
# - note that since the value of the has_a field is supplied, we don't 
#       need to identify the target object in order to set up the has_a 
#       relationship
sub addmany : Exported
{
    my ( $self, $r ) = @_;
    
    # the form action supplies these as additional path-info in the form 'action':
    my ( $accessor, $how_many ) = @{ $r->args };
    
    my $form = $r->as_multiform( how_many => $how_many );
    
    return unless $form->submitted && $form->validate;
    
    my @new = $self->create_from_multiform( $form );
    
    # set up the view of the parent object
    
    my $parent = $new[0]->$accessor;
    
    $r->objects( [ $parent ] );
    
    $r->model_class( ref $parent );    
    
    return $self->edit( $r );
}

=item edit

Sets the C<edit> template. 

Also sets the C<action> to C<edit>. This is necessary 
to support forwarding to the C<edit> template from the C<edit> button on the C<editlist> 
template.

=cut

sub edit : Exported
{
    my ( $self, $r ) = @_;
    
    $r->action( 'edit' );
    
    $r->template( 'edit' );
}

=item edit_all_has_a

=cut

# Handles a form submitted to the related object at the far end of a has_a relationship.
# Returns to the edit template for the parent object, not the related object.
sub edit_all_has_a : Exported
{
    my ( $self, $r ) = @_;
    
    my $form = $r->as_form;
    
#    use Data::Dumper;
#    
#    my $oks = $form->submitted;
#    my $okv = $form->validate;
#    die $form->name . " submitted: $oks validated: $okv " . Dumper( scalar $form->field );
    
    return unless $form->submitted && $form->validate;
    
    my $parent_class = $form->field( '__parent_class__' );
    my $parent_id    = $form->field( '__parent_id__' );
    
    my $parent = $parent_class->retrieve( $parent_id );
    
    my $child = $self->update_or_create_from_form( $form );
    
    my $has_a = $parent->meta_info( 'has_a' );
    my $meta = List::Util::first { $_->foreign_class eq ref( $child ) } values %$has_a;
    my $column = $meta->accessor;
    my $mutator = $column->mutator;
    
    $parent->$mutator( $child );
    
    $r->action( 'edit' );
    $r->template( 'edit' );
    $r->model_class( $parent_class );
    $r->objects( [ $parent ] );
}

=item do_edit

Implements update operations on submitted forms.

=cut

sub do_edit : Exported
{
    my ( $self, $r ) = @_;
    
    my $caller = (caller(1))[3];
    
    # the mode of the generated form must match the mode of the submitted from, 
    # so that the submit button can be detected accurately
    my $form_mode = $caller =~ 'editlist' ? 'editlist' : 'edit';
    
    my $form = $r->as_form( mode => $form_mode ); 
    
    # default template for this action
    $r->template('edit');
    
    # Do nothing if no form submitted, or failed validation. If the latter, 
    # errors will be displayed by magic in the form. Note that if coming from 
    # editlist, any form errors will divert us to the edit template (showing errors), 
    # rather than returning to the editlist template. Which seems like the right behaviour.
    #return unless $form->submitted && $form->validate;
    my $button = $form->submitted;
     
    return $self->view($r) if $button eq 'view';
     
    if ( ! $form->validate )
    {
        my $object = $r->objects->[0];
        $r->template_args->{form_failed_validation}->{edit}->{ $object->table }->{ $object->id } = 1;
        return;
    }
    
    #return unless $button;
    
    Carp::croak "Unknown button: $button" unless $button eq 'submit';
    
    # This assumes the primary keys in the form (hidden fields) identify 
    # the same object as in the URL, which will already be in $r->objects->[0].
    # They should be, because the form was generated either from a specific object 
    # (so C::DBI::FB inserted the hidden fields), or was generated from the class, 
    # and therefore has no pk data and will result in a create.
    
    # If for some reason, the model_class is different from the class of $r->objects->[0], 
    # then use ref( $r->objects->[0] ) instead. But that shouldn't happen...
    
    my $model = $r->model_class;
    
    # dunno why I was getting this error, probably don't need to check this now
    Carp::croak( "model ($model) is not a class name!" ) if ref $model;

    my $obj = $model->update_from_form($form) || 
        die "Unexpected update error"; # Don't you just hate this kind of message?
    
    $r->objects( [ $obj ] );
    
    my $return_method = $caller =~ /editlist/ ? 'list' : 'view';
    
    $self->$return_method( $r );
}

=item do_search

Runs a C<search_where> search. 

Does not implement search ordering yet, and there are various other
modifications that could make this better, such as allowing C<LIKE> comparisons (% and _ wildcards) 
etc. 

=cut

sub do_search : Exported 
{
    my ( $self, $r ) = @_;

    my $form = $r->search_form;
    
    return $self->list( $r ) unless $form->submitted && $form->validate; 
    
    $r->template( 'list' );
    
    # self becomes the pager
    $self = $self->do_pager( $r );
    
    $r->objects( [ $self->search_where_from_form( $form ) ] );
}

=item editlist

Detects which submit button was clicked, and despatches to the appropriate method. 

=cut

sub editlist : Exported
{
    my ( $self, $r ) = @_;
    
    my $form = $r->as_form;
    
    my $button = $form->submitted if $form->validate;
    
    return $self->do_edit  ( $r )   if $button eq 'update';
    return $self->edit     ( $r )   if $button eq 'edit';
    return $self->do_delete( $r )   if $button eq 'delete';
    return $self->view     ( $r )   if $button eq 'view';
    
    return $self->list     ( $r );
}

=item list 

Does not implement ordering yet.

=cut

sub list : Exported
{
    my ( $self, $r ) = @_;

    $r->template( 'list' );
    
    # something like "my_col DESC" or just "my_col" (for ASC)
    my $order = $self->order( $r );
    
    $self = $self->do_pager( $r );
    
    if ( $order ) 
    {
        $r->objects( [ $self->retrieve_all_sorted_by( $order ) ] );
    }
    else 
    {
        $r->objects( [ $self->retrieve_all ] );
    }    
}

=item do_delete

Deletes a single object. 

=cut

sub do_delete : Exported 
{
    my ( $self, $r ) = @_;
    
    my $goner = @{ $r->objects || [] }[0];
    
    $goner && $goner->delete;
    
    $self->list( $r );
}

=item view

Just sets the C<view> template.

=cut

sub view : Exported
{
    my ( $self, $r ) = @_;

    $r->template( 'view' );
}

=item switchlistmode

If sessions are enabled, this switches the default list mode between C<editlist> and C<list>.

=cut

sub switchlistmode : Exported
{
    my ( $self, $r ) = @_;
    
    my %switch_from = ( list => 'editlist',
                        editlist => 'list',
                        );
                   
    my $old_mode = $r->listviewmode;
    
    $r->listviewmode( $switch_from{ $old_mode } );
    
    # set this so forms built on the list page don't look for a switchlistmode 
    # form mode
    $r->action( 'list' );
    
    return $self->list( $r );
}

=item editrelated

Basic support for the C<editrelated> template. This is currently under development 
in C<Class::DBI::FormBuilder::as_form_with_related()>.

=cut

sub editrelated : Exported
{
    my ( $self, $r ) = @_;

    my $form = $r->as_form_with_related( debug => 2 );
    
    warn "START";
    
    return $self->edit( $r ) unless $form->submitted && $form->validate;
    
    warn "GOT FORM";
    
    $r->objects( [ $self->update_from_form_with_related( $form ) ] );
    
    warn "DONE UPDATING: $self $r @{ $r->{objects} }";
    
    $self->view( $r );
}



# -------------------------------------------------------- other Maypole::Model::CDBI methods -----

=back 

=head2 Coordinating client and server forms

Every form is used in two circumstances, and the forms must be built with equivalent properties in 
each. In the first, a form object is constructed and used to generate an HTML form to be sent to the 
client. In the second, a form object is constructed and is used to receive data sent in a form 
submission from the client. These may be loosely termed the 'server' and 'client' forms (although they are 
both built on the server). 

The forms built in these two situations must have equivalent properties, such as the 
same field lists, the same option lists for multi-valued fields, etc. 

The point of co-ordination is the C<setup_form_mode> method. This supplies the set of characteristics 
that must be synchronised by both versions of the form. C<setup_form_mode> selects a set of form 
parameters based on the current C<action> of the Maypole request. 

=head3 Gotchas

=over 4 

=item form mode

Sometimes you need to set the form mode in these methods, sometimes not. If 
the mode matches the action, you don't need to set it. 
So to get searching working, the C<do_search> mode needs to be set. Similarly for C<do_edit>, 
except here the C<edit> mode needs to be set. Elsewhere the mode is automatically set to the 
Maypole action. 

=item submit button name

If you insert a line in C<CGI::FormBuilder::submitted()> to 
C<warn> the value of C<$smtag>, that needs to match the name of the submit button in 
C<< $request->params >> (i.e. C<< $request->params->{$smtag} >> needs to be true). 

=back

=head2 Maypole::Model::CDBI methods

These methods are copied verbatim from L<Maypole::Model::CDBI|Maypole::Model::CDBI>. 
See that module for documentation. 

=over 4

=item related

=item related_class

=item stringify_column

=item adopt

=item do_pager

The default pager is L<Class::DBI::Pager|Class::DBI::Pager>. Use a different pager 
by setting the C<pager_class> config item:

    BeerFB->config->pager_class( 'Class::DBI::Plugin::Pager' );

=item order

This method is not used in the C<Maypole::Plugin::FormBuilder> templates at the moment. 
Probably, ordering will be implemented directly in L<Class::DBI::FormBuilder|Class::DBI::FormBuilder> 
and this method can disappear. 

=item setup_database

=item class_of

=item fetch_objects

=back

=cut

sub related {
    my ( $self, $r ) = @_;
    return keys %{ $self->meta_info('has_many') || {} };
}



sub related_class {
    my ( $self, $r, $accessor ) = @_;

    my $related = $self->meta_info( has_many => $accessor ) ||
                  $self->meta_info( has_a    => $accessor ) ||
                  return;

    my $mapping = $related->{args}->{mapping};
    if ( @$mapping ) {
        return $related->{foreign_class}->meta_info('has_a')->{ $$mapping[0] }
          ->{foreign_class};
    }
    else {
        return $related->{foreign_class};
    }
}

sub stringify_column {
    my $class = shift;
    return (
        $class->columns("Stringify"),
        ( grep { /^(name|title)$/i } $class->columns ),
        ( grep { /(name|title)/i } $class->columns ),
        ( grep { !/id$/i } $class->primary_columns ),
    )[0];
}

sub adopt {
    my ( $self, $child ) = @_;
    $child->autoupdate(1);
    if ( my $col = $child->stringify_column ) {
        $child->columns( Stringify => $col );
    }
}

sub do_pager {
    my ( $self, $r ) = @_;
    
    my $page = $r->query->{page};
     
    if ( $r->can( 'session' ) )
    {
        # The user asks for a specific page by clicking a link, which 
        # puts the page in the query. So move it into the session. 
        # If the user doesn't specifically ask for a page, see if they 
        # previously asked for one. Wherever $page comes from, put it 
        # in the session.
        $page ||= $r->session->{current_page}->{ $r->model_class };
        $r->session->{current_page}->{ $r->model_class } = $page;
    }
    
    if ( my $rows = $r->config->rows_per_page ) {
        return $r->{template_args}{pager} =
          $self->pager( $rows, $page );
    }
    else { return $self }
}

# 2.10 - much better!
sub order {
    my ( $self, $r ) = @_;
    my %ok_columns = map { $_ => 1 } $self->columns;
    my $q = $r->query;
    my $order = $q->{order};
    return unless $order and $ok_columns{$order};
    $order .= ' DESC' if $q->{o2} and $q->{o2} eq 'desc';
    return $order;
}

# 2.09
#sub order {
#    my ( $self, $r ) = @_;
#    my $order;
#    my %ok_columns = map { $_ => 1 } $self->columns;
#    if ( $order = $r->query->{order} and $ok_columns{$order} ) {
#        $order .= ( $r->query->{o2} eq "desc" && " DESC" );
#    }
#    $order;
#}

sub setup_database {
    my ( $class, $config, $namespace, $dsn, $u, $p, $opts ) = @_;
    $dsn  ||= $config->dsn;
    $u    ||= $config->user;
    $p    ||= $config->pass;
    $opts ||= $config->opts;
    $config->dsn($dsn);
    warn "No DSN set in config" unless $dsn;
    $config->loader || $config->loader(
        Class::DBI::Loader->new(
            namespace => $namespace,
            dsn       => $dsn,
            user      => $u,
            password  => $p,
            %$opts,
        )
    );
    $config->{classes} = [ $config->{loader}->classes ];
    $config->{tables}  = [ $config->{loader}->tables ];
    warn( 'Loaded tables: ' . join ',', @{ $config->{tables} } )
      if $namespace->debug;
}

sub class_of {
    my ( $self, $r, $table ) = @_;
    return $r->config->loader->_table2class($table);
}

sub fetch_objects {
    my ($class, $r)=@_;
    my @pcs = $class->primary_columns;
    if ( $#pcs ) {
    my %pks;
        @pks{@pcs}=(@{$r->{args}});
        return $class->retrieve( %pks );
    }
    return $class->retrieve( $r->{args}->[0] );
}
 
=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 TODO

I think splitting modes into search and do_search, and edit and do_edit, is 
probably unnecessary.

Pairs of methods like search and do_search, edit and do_edit are probably 
unnecessary, as FB makes it easy to distinguish between rendering a form 
and processing a form - see editrelated().

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-formbuilder@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-FormBuilder>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;