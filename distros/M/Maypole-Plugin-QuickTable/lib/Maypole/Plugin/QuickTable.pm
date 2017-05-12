package Maypole::Plugin::QuickTable;

use warnings;
use strict;

use URI();

use NEXT;

use HTML::QuickTable;

our $VERSION = 0.422;

=head1 NAME

Maypole::Plugin::QuickTable - HTML::QuickTable convenience 

=head1 SYNOPSIS

    use Maypole::Application qw( LinkTools QuickTable );

=head1 METHODS

=over

=item setup 

=cut

sub setup
{
    my $r = shift;
    
    $r->NEXT::DISTINCT::setup( @_ );

    warn "Running " . __PACKAGE__ . " setup for $r" if $r->debug;
    
    my $model = $r->config->model ||
        die "Please configure a model in $r before calling setup()";    
        
    die __PACKAGE__ . " needs Maypole::Plugin::LinkTools"
        unless $r->can( 'maybe_many_link_views' ); 
        
    warn "quicktable_defaults are shared by ALL models - cf. fb_defaults, which had this same bug" 
        if $r->debug > 1;
    $model->mk_classdata( 'quicktable_defaults', {} );
}

=item quick_table

Returns a L<HTML::QuickTable|HTML::QuickTable> object for formatting data. 

    print $request->quick_table( %args )->render( $data );

The method gathers arguments from the C<quicktable_defaults> method on the model class. This 
is a L<Class::Data::Inheritable|Class::Data::Inheritable> method, so you can set global 
defaults on the main model class, and then override them in model subclasses. To preserve 
most settings and override others, say something like

    $sub_model->quicktable_defaults( { %{ $model->quicktable_defaults }, %hash_of_overrides } );

Arguments passed in the method call override those stored on the model.

Arguments are passed directly to C<< HTML::QuickTable->new >>, so see L<HTML::QuickTable> for a 
description. 

Additional arguments are: 

    object  =>  a Maypole/CDBI object

Pass a Maypole/CDBI object in the C<object> slot, and its data will be extracted 
and C<< $qt->render >> called for you:

    print $request->quick_table( %args, object => $object );
    
Related objects will be displayed as links to their view template. 

If no object is supplied, a L<HTML::QuickTable> object is returned. If an object is 
supplied, it is passed to C<tabulate> to extract its data, and the data passed to the 
C<render> method of the L<HTML::QuickTable> object. 

To render a subset of an object's columns, say:

    my @data = $request->tabulate( objects => $object, with_colnames => 1, fields => [ qw( foo bar ) ] );
    
    $request->quick_table( @data );

=cut

sub quick_table
{
    my ( $self, %args ) = @_;
    
    my $object = delete $args{object};
      
    # this allows the caller to pass in some prepackaged data and get a table back 
    return HTML::QuickTable->new( %args ) unless $object;      
    
    my $model_class = ref( $object ) || $object;
    
    %args = ( %{ $model_class->quicktable_defaults }, %args );    
         
    $args{labels} ||= 1;
    
    my $qt = HTML::QuickTable->new( %args );
    
    return $qt->render( [ $self->tabulate( objects => $object, with_colnames => 1 ) ] );
}

=item tabulate( $object|$arrayref_of_objects, %args )

Extract data from a Maypole/CDBI object (or multiple objects), ready to pass to C<< quick_table->render >>. 
Data will start with a row of column names if C<$args{with_colnames}> is true. 

A callback subref can be passed in C<$args{callback}>. It will be called in turn with each object as 
its argument. The result(s) of the call will be added to the row of data for that object. See 
the C<list> template in L<Maypole::FormBuilder|Maypole::FormBuilder>, which uses this technique 
to add C<edit> and C<delete> buttons to each row. 

Similarly, a C<field_callback> coderef will be called during rendering of each field, receiving the 
object and the current field as arguments. See the C<addmany> template for an example.

Arguments:

    callback        coderef
    field_callback  coderef
    with_colnames   boolean
    fields          defaults to ( $request->model_class->display_columns, $request->model_class->related )
    objects         defaults to $request->objects

=cut

# HTML::QuickTable seems to accept an array of arrayrefs, which is undocumented, but 
# simplifies this code - just pass whatever this returns, directly to render(). In fact, 
# HTML::QuickTable::render() puts the data into an arrayref if it's supplied as an array, 
# so it seems safe to rely on.
sub tabulate
{
    my ( $self, %args ) = @_;
    
    my $objects = $args{objects} || $self->objects;
    
    my @objects = ref( $objects ) eq 'ARRAY' ? @$objects : ( $objects );

    # assumes all objects are in the same class
    my $model_class = ref( $objects[0] ) || $objects[0];
    
    # If we're tabulating a set of search results, and the search returned no results, 
    # there are no objects. I'm not sure at the moment whether this will return the correct 
    # class in all cases - there might have been a template switcheroo, which was why this 
    # method looks at the object's class and not the request's model class anyway. But 
    # for the moment there's nothing else available:
    $model_class ||= $self->model_class;
    
    my @fields = $args{fields} ? @{ $args{fields} } : 
                                 ( $model_class->view_columns, $model_class->view_fields );
                                 
    my @data = map { $self->_tabulate_object( $_, \@fields, $args{callback}, $args{field_callback} ) } @objects; 
    
    return @data unless $args{with_colnames};
    
    # If no rows (e.g. no search results), return 1 empty row to cause the table 
    # headers to be printed correctly.
    @data = ( [ ( '' ) x @fields ] ) unless @data; 
    
    my %names = ( $model_class->column_names, $model_class->field_names );
    
    my @headers = $self->action eq 'list' ? $self->_make_linked_headers( $model_class, \@fields ) :
                                            map { $names{ $_ } } @fields;

    unshift @data, \@headers;
    
    return @data;
}

# build clickable column headers to control sorting - from Ron McClain
sub _make_linked_headers
{
    my ( $self, $model_class, $fields ) = @_;

    my @headers;
    
    foreach my $field ( @$fields ) 
    {
        push @headers, $self->orderby_link( $field, $model_class );
    }
    return @headers;
}

=item orderby_link( $field, [ $model_class ] )

Build a link for a column header. Controls whether the table should be sorted by that 
column. Toggles sort direction. 

The C<$model_class> parameter is only necessary when building a table for a class different 
from the current model class for the request.

=cut

# build clickable column headers to control sorting - from Ron McClain
sub orderby_link 
{
    my ( $self, $field, $model_class )  = @_; 
    
    $model_class ||= $self->model_class;
    
    my %names = $model_class->column_names;

    # take a copy so we can delete things from it without removing data used elsewhere
    my %params = %{ $self->params };
    
    # these come from the search form on the initial search
    my($order_by, $order_dir);
    ( $order_by, $order_dir ) = split /\s+/, $params{search_opt_order_by} if $params{search_opt_order_by};

    # otherwise, from the header links
    $order_by = $params{order} if $params{order};
    $order_dir ||= $params{o2} || 'desc';
    $order_dir = ( $order_dir eq 'desc' ) ? 'asc' : 'desc';
    delete $params{search_opt_order_by};
    delete $params{order_by};
    delete $params{o2};
    delete $params{page};

    # is this a column? - it might be a has_many field instead
    if ( $names{ $field } )
    {
        my $uri = URI->new;
        
        if ( $self->action eq 'do_search' ) 
        {
            $params{search_opt_order_by} = "$field $order_dir"
        } 
        elsif ( $self->action eq 'list' ) 
        {
            $params{order} = $field;
            $params{o2}    = $order_dir;
        } 
        else 
        {
            %params = ( order => $field,
                        o2    => $order_dir
                        );
        }
            
        $uri->query_form( %params );
        
        my $arrow = '';
            
        if ( $order_by and $order_by eq $field )
        {
            $arrow = $order_dir eq 'asc' ? '&nbsp;&darr;' : '&nbsp;&uarr;';
        }
                
        my $args = "?".$uri->equery;
        
        return $self->link( table      => $self->model_class->table,
                            action     => $self->action,
                            additional => $args,
                            label      => $names{ $field } . $arrow,
                            );
    }
    else
    {
        # has_many, might_have fields
        my $related_class = $self->model_class->related_class( $self, $field );
        my $field_name = $related_class->plural_moniker;
        return ucfirst( $field_name );
    }
}

# Return an arrayref of values for a single object, which will be passed to 
# QuickTable and rendered as a row in the table. The callback is optional, and 
# can be used to add extra entries to the row. Column values that inflate to CDBI 
# objects will be rendered as links to the view template. Column values that inflate 
# to non-CDBI objects will be returned as the object, which will presumably be evaluated 
# in string context at some point in QT render.
sub _tabulate_object
{
    my ( $self, $object, $cols, $callback, $field_callback ) = @_;
    
    my $str_col = $object->stringify_column || ''; # '' to silence warnings in the map
    
    if ( $self->debug && ! $str_col )
    {
        warn sprintf "No stringify_column specified in %s - please define a 'Stringify' column " .
            "group with a single column", ref( $object );
    }
    
    my $lister = sub 
    {
        return '' unless @_;
        return @_ if @_ == 1;
        #return join( "\n", '<ol>', ( map { "<li>$_</li>" } @_ ), '</ol>' );
        return join ', ', @_ if @_ < 3 or $self->template =~ /view/;
        return join ', ', $_[0], $_[1], @_ - 2 . ' more...';
    };
    
    # XXX: getting a 'Use of uninitialized value in string eq warning' - looks like 
    # $object->stringify_column can return undef?
    my @data = map { $self->maybe_link_view( $_ ) } 
    
               # for the stringification column (e.g. 'name'), return the object, which 
               # will be translated into a link to the 'view' template by 
               # maybe_link_view. Otherwise, return the value, which will be rendered 
               # verbatim, unless it is an object in a related class, in which case 
               # it will be rendered as a link to the view template.
               map { $_ eq $str_col ? $object : $lister->( $self->maybe_many_link_views( $object->$_ ) ) } 
               @$cols;
               
    if ( $field_callback )
    {
        @data = map { [ $_, $field_callback->( $object, shift( @$cols ) ) ] } @data;    
    }
                 
    push( @data, $callback->( $object ) ) if $callback;
                 
    return \@data;
}

=back

=head1 AUTHOR

David Baird, C<< <cpan@riverside-cms.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-maypole-plugin-quicktable@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Maypole-Plugin-QuickTable>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 David Baird, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Maypole::Plugin::QuickTable
