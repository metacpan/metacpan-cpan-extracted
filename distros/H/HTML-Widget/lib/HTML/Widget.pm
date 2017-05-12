package HTML::Widget;

use warnings;
use strict;
use base 'HTML::Widget::Accessor';
use HTML::Widget::Result;
use Scalar::Util 'blessed';
use Carp qw/croak/;

# For PAR
use Module::Pluggable::Fast
    search =>
    [qw/HTML::Widget::Element HTML::Widget::Constraint HTML::Widget::Filter/],
    require => 1;

__PACKAGE__->plugins;

__PACKAGE__->mk_accessors(
    qw/container indicator query subcontainer uploads strict empty_errors
        element_container_class xhtml_strict unwrapped explicit_ids/
);
__PACKAGE__->mk_ro_accessors(qw/implicit_subcontainer/);

# Custom attr_accessor for id provided later
__PACKAGE__->mk_attr_accessors(qw/action enctype method/);

use overload '""' => sub { return shift->attributes->{id} }, fallback => 1;

*const         = \&constraint;
*elem          = \&element;
*name          = \&id;
*tag           = \&container;
*subtag        = \&subcontainer;
*result        = \&process;
*indi          = \&indicator;
*constrain_all = \*constraint_all;

our $VERSION = '1.11';

=head1 NAME

HTML::Widget - HTML Widget And Validation Framework

=head1 NOTE

L<HTML::Widget> is no longer under active development and the current 
maintainers are instead pursuing an intended replacement (see the 
L<mailing-list|/SUPPORT> for details).

Volunteer maintainers / developers for L<HTML::Widget>, please contact 
the L<mailing-list|/SUPPORT>.

=head1 SYNOPSIS

    use HTML::Widget;

    # Create a widget
    my $w = HTML::Widget->new('widget')->method('get')->action('/');

    # Add a fieldset to contain the elements
    my $fs = $w->element( 'Fieldset', 'user' )->legend('User Details');

    # Add some elements
    $fs->element( 'Textfield', 'age' )->label('Age')->size(3);
    $fs->element( 'Textfield', 'name' )->label('Name')->size(60);
    $fs->element( 'Submit', 'ok' )->value('OK');

    # Add some constraints
    $w->constraint( 'Integer', 'age' )->message('No integer.');
    $w->constraint( 'Not_Integer', 'name' )->message('Integer.');
    $w->constraint( 'All', 'age', 'name' )->message('Missing value.');

    # Add some filters
    $w->filter('Whitespace');

    # Process
    my $result = $w->process;
    my $result = $w->process($query);


    # Check validation results
    my @valid_fields   = $result->valid;
    my $is_valid       = $result->valid('foo');
    my @invalid_fields = $result->have_errors;
    my $is_invalid     = $result->has_errors('foo');;

    # CGI.pm-compatible! (read-only)
    my $value  = $result->param('foo');
    my @params = $result->param;

    # Catalyst::Request-compatible
    my $value = $result->params->{foo};
    my @params = keys %{ $result->params };


    # Merge widgets (constraints and elements will be appended)
    $widget->merge($other_widget);


    # Embed widgets (as fieldset)
    $widget->embed($other_widget);


    # Get list of elements
    my @elements = $widget->get_elements;

    # Get list of constraints
    my @constraints = $widget->get_constraints;

    # Get list of filters
    my @filters = $widget->get_filters;


    # Complete xml result
    [% result %]
    [% result.as_xml %]


    # Iterate over elements
    <form action="/foo" method="get">
    [% FOREACH element = result.elements %]
        [% element.field_xml %]
        [% element.error_xml %]
    [% END %]
    </form>


    # Iterate over validation errors
    [% FOREACH element = result.have_errors %]
        <p>
        [% element %]:<br/>
        <ul>
        [% FOREACH error = result.errors(element) %]
            <li>
                [% error.name %]: [% error.message %] ([% error.type %])
            </li>
        [% END %]
        </ul>
        </p>
    [% END %]

    <p><ul>
    [% FOREACH element = result.have_errors %]
        [% IF result.error( element, 'Integer' ) %]
            <li>[% element %] has to be an integer.</li>
        [% END %]
    [% END %]
    </ul></p>

    [% FOREACH error = result.errors %]
        <li>[% error.name %]: [% error.message %] ([% error.type %])</li>
    [% END %]


    # XML output looks like this (easy to theme with css)
    <form action="/foo/bar" id="widget" method="post">
        <fieldset>
            <label for="widget_age" id="widget_age_label"
              class="labels_with_errors">
                Age
                <span class="label_comments" id="widget_age_comment">
                    (Required)
                </span>
                <span class="fields_with_errors">
                    <input id="widget_age" name="age" size="3" type="text"
                      value="24" class="Textfield" />
                </span>
            </label>
            <span class="error_messages" id="widget_age_errors">
                <span class="Regex_errors" id="widget_age_error_Regex">
                    Contains digit characters.
                </span>
            </span>
            <label for="widget_name" id="widget_name_label">
                Name
                <input id="widget_name" name="name" size="60" type="text"
                  value="sri" class="Textfield" />
                <span class="error_messages" id="widget_name_errors"></span>
            </label>
            <input id="widget_ok" name="ok" type="submit" value="OK" />
        </fieldset>
    </form>

=head1 DESCRIPTION

Create easy to maintain HTML widgets!

Everything is optional, use validation only or just generate forms,
you can embed and merge them later.

The API was designed similar to other popular modules like
L<Data::FormValidator> and L<FormValidator::Simple>,
L<HTML::FillInForm> is also built in (and much faster).

This Module is very powerful, don't misuse it as a template system!

=head1 METHODS

=head2 new

Arguments: $name, \%attributes

Return Value: $widget

Create a new HTML::Widget object. The name parameter will be used as the 
id of the form created by the to_xml method.

The C<attributes> argument is equivalent to using the L</attributes> 
method.

=cut

sub new {
    my ( $self, $name, $attrs ) = @_;

    $self = bless {}, ( ref $self || $self );
    $self->container('form');
    $self->subcontainer('fieldset');
    $self->name( defined $name ? $name : 'widget' );

    if ( defined $attrs ) {
        croak 'attributes argument must be a hash-reference'
            if ref($attrs) ne 'HASH';

        $self->attributes->{$_} = $attrs->{$_} for keys %$attrs;
    }

    return $self;
}

=head2 action

Arguments: $uri

Return Value: $uri

Get/Set the action associated with the form. The default is no action, 
which causes most browsers to submit to the current URI.

=head2 attributes

=head2 attrs

Arguments: %attributes

Arguments: \%attributes

Return Value: $widget

Arguments: none

Return Value: \%attributes

Accepts either a list of key/value pairs, or a hash-ref.

    $w->attributes( $key => $value );
    $w->attributes( { $key => $value } );

Returns the C<$widget> object, to allow method chaining.

As of v1.10, passing a hash-ref no longer deletes current 
attributes, instead the attributes are added to the current attributes 
hash.

This means the attributes hash-ref can no longer be emptied using 
C<< $w->attributes( { } ); >>. Instead, you may use 
C<< %{ $w->attributes } = (); >>.

As a special case, if no arguments are passed, the return value is a 
hash-ref of attributes instead of the object reference. This provides 
backwards compatability to support:

    $w->attributes->{key} = $value;

L</attrs> is an alias for L</attributes>.

=head2 container

Arguments: $tag

Return Value: $tag

Get/Set the tag used to contain the XML output when as_xml is called on the
HTML::Widget object.
Defaults to C<form>.

=head2 element_container_class

Arguments: $class_name

Return Value: $class_name

Get/Set the container_class override for all elements in this widget. If set to
non-zero value, process will call $element->container_class($class_name) for
each element. Defaults to not set.

See L<HTML::Widget::Element/container_class>.

=head2 elem

=head2 element

Arguments: $type, $name, \%attributes

Return Value: $element

Add a new element to the Widget. Each element must be given at least a type. 
The name is used to generate an id attribute on the tag created for the 
element, and for form-specific elements is used as the name attribute. The 
returned element object can be used to set further attributes, please see 
the individual element classes for the methods specific to each one.

The C<attributes> argument is equivalent to using the 
L<attributes|HTML::Widget::Element/attributes> method.

If the element starts with a name other than C<HTML::Widget::Element::>, 
you can fully qualify the name by using a unary plus:

    $self->element( "+Fully::Qualified::Name", $name );

The type can be one of the following:

=over 4

=item L<HTML::Widget::Element::Block>

    my $e = $widget->element('Block');

Add a Block element, which by default will be rendered as a C<DIV>.

    my $e = $widget->element('Block');
    $e->type('img');

=item L<HTML::Widget::Element::Button>

    my $e = $widget->element( 'Button', 'foo' );
    $e->value('bar');

Add a button element.

    my $e = $widget->element( 'Button', 'foo' );
    $e->value('bar');
    $e->content('<b>arbitrary markup</b>');
    $e->type('submit');

Add a button element which uses a C<button> html tag rather than an 
C<input> tag. The value of C<content> is not html-escaped, so may contain 
html markup.

=item L<HTML::Widget::Element::Checkbox>

    my $e = $widget->element( 'Checkbox', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->checked('checked');
    $e->value('bar');

Add a standard checkbox element.

=item L<HTML::Widget::Element::Fieldset>

    my $e = $widget->element( 'Fieldset', 'foo' );
    $e->legend('Personal details');
    $e->element('Textfield', 'name');
    $e->element('Textarea', 'address');

Adds a nested fieldset element, which can contain further elements.

=item L<HTML::Widget::Element::Hidden>

    my $e = $widget->element( 'Hidden', 'foo' );
    $e->value('bar');

Add a hidden field. This field is mainly used for passing previously gathered
data between multiple page forms.

=item L<HTML::Widget::Element::Password>

    my $e = $widget->element( 'Password', 'foo' );
    $e->comment('(Required)');
    $e->fill(1);
    $e->label('Foo');
    $e->size(23);
    $e->value('bar');

Add a password field. This is a text field that will not show the user what
they are typing, but show asterisks instead.

=item L<HTML::Widget::Element::Radio>

    my $e = $widget->element( 'Radio', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->checked('checked');
    $e->value('bar');

Add a radio button to a group. Radio buttons with the same name will work as
a group. That is, only one item in the group will be "on" at a time.

=item L<HTML::Widget::Element::RadioGroup>

    my $e = $widget->element( 'RadioGroup', 'name' );
    $e->comment('(Required)');
    $e->label('Foo'); # Label for whole radio group
    $e->value('bar'); # Currently selected value
    $e->labels([qw/Fu Bur Garch/]); # default to ucfirst of values

This is a shortcut to add multiple radio buttons with the same name at the
same time. See above.

=item L<HTML::Widget::Element::Reset>

    $e = $widget->element( 'Reset', 'foo' );
    $e->value('bar');

Create a reset button. The text on the button will default to "Reset", unless
you call the value() method. This button resets the form to its original
values.

=item L<HTML::Widget::Element::Select>

    my $e = $widget->element( 'Select', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->size(23);
    $e->options( foo => 'Foo', bar => 'Bar' );
    $e->selected(qw/foo bar/);

Create a dropdown  or multi-select list element with multiple options. Options 
are supplied in a key => value list, in which the keys are the actual selected
IDs, and the values are the strings displayed in the dropdown.

=item L<HTML::Widget::Element::Span>

    my $e = $widget->element( 'Span' );
    $e->content('bar');

Create a simple span tag, containing the given content. Spans cannot be
constrained as they are not entry fields.

The content may be a string, an L<HTML::Element|HTML::Element> object, 
or an array-ref of L<HTML::Element|HTML::Element> objects.

=item L<HTML::Widget::Element::Submit>

    $e = $widget->element( 'Submit', 'foo' );
    $e->value('bar');

Create a submit button. The text on the button will default to "Submit", unless
you call the value() method. 

    $e = $widget->element( 'Submit', 'foo' );
    $e->value('bar');
    $e->src('image.png');
    $e->width(100);
    $e->height(35);

Create an image submit button. The button will be displayed as an image, 
using the file at url C<src>.

=item L<HTML::Widget::Element::Textarea>

    my $e = $widget->element( 'Textarea', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->cols(30);
    $e->rows(40);
    $e->value('bar');
    $e->wrap('wrap');

Create a textarea field. This is a multi-line input field for text.

=item L<HTML::Widget::Element::Textfield>

    my $e = $widget->element( 'Textfield', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->size(23);
    $e->maxlength(42);
    $e->value('bar');

Create a single line text field.

=item L<HTML::Widget::Element::Upload>

    my $e = $widget->element( 'Upload', 'foo' );
    $e->comment('(Required)');
    $e->label('Foo');
    $e->accept('text/html');
    $e->maxlength(1000);
    $e->size(23);

Create a field for uploading files. This will probably be rendered as a
textfield, with a button for choosing a file.

Adding an Upload element automatically calls
C<< $widget->enctype('multipart/form-data') >> for you.

=back

=cut

sub element {
    my ( $self, $type, $name, $attrs ) = @_;

    my $abs = $type =~ s/^\+//;
    $type = "HTML::Widget::Element::$type" unless $abs;

    my $element = $self->_instantiate( $type, { name => $name } );

    $element->{_anonymous} = 1 if !defined $name;

    if ( $element->isa('HTML::Widget::Element::Block')
        and not $element->{_pseudo_block} )
    {

        push @{ $self->{_elements} }, $element;

    }
    else {
        croak "'$type' element not permitted at top level in xhtml_strict mode"
            if $self->xhtml_strict;

        my $implicit_subcontainer = $self->_get_implicit_subcontainer;
        $implicit_subcontainer->push_content($element);
    }

    if ( defined $attrs ) {
        croak 'attributes argument must be a hash-reference'
            if ref($attrs) ne 'HASH';

        $element->attributes->{$_} = $attrs->{$_} for keys %$attrs;
    }

    return $element;
}

sub _first_element {
    return $_[0]->{_elements}->[0];
}

sub _get_implicit_subcontainer {
    my $self = shift;
    return $self->_first_element if ( $self->implicit_subcontainer );

    if ( $self->_first_element ) {
        croak
            "already a top-level container when trying to setup implicit container";
    }

    $self->{implicit_subcontainer} = 1;
    my $container;
    if ( $self->subcontainer eq 'fieldset' ) {
        $container = $self->_instantiate('HTML::Widget::Element::Fieldset');
    }
    else {
        $container = $self->_instantiate('HTML::Widget::Element::Block');
        $container->type( $self->subcontainer );
    }

    # Save away the parent widget's name for possible later use in
    # H::W::Element::Block.
    $container->name( '_implicit_' . $self->name );
    push @{ $self->{_elements} }, $container;
    return $container;
}

=head2 id

=head2 name

Arguments: $name

Return Value: $name

Get or set the widget id.

L</name> is an alias for L</id>.

=cut

# Yuck - the name bodge above requires this nasty if uncommonly used fixup
sub id {
    my $self = shift;
    if (    $self->implicit_subcontainer
        and $_[0]
        and $_[0] ne $self->{attributes}->{id} )
    {
        my $curr = $self->{attributes}->{id};

        # fix up legacy widget names
        map { $_->name( '_implicit_' . $_[0] ); }
            grep { $_->name =~ /^_implicit_$curr/; } @{ $self->{_elements} };
    }
    return ( $self->{attributes}->{id} || $self ) unless @_ > 0;
    $self->{attributes}->{id} = ( @_ == 1 ? $_[0] : [@_] );
    return $self;
}

=head2 get_elements

Arguments: %options

Return Value: @elements

    my @elements = $self->get_elements;
    
    my @elements = $self->get_elements( type => 'Textfield' );
    
    my @elements = $self->get_elements( name => 'username' );

Returns a list of all elements added to the widget.

If a 'type' argument is given, only returns the elements of that type.

If a 'name' argument is given, only returns the elements with that name.

=cut

sub get_elements {
    my ( $self, %opt ) = @_;

    my @elements;
    @elements = @{ $self->{_elements} } if $self->{_elements};
    @elements = @{ $self->_first_element->content }
        if $self->implicit_subcontainer;

    return _search_elements( \%opt, @elements );
}

sub _search_elements {
    my ( $opt, @elements ) = @_;

    if ( exists $opt->{type} ) {
        my $type = "HTML::Widget::Element::" . $opt->{type};

        @elements = grep { $_->isa($type) } @elements;
    }

    if ( exists $opt->{name} ) {
        @elements = grep {
            defined($_->name) && $_->name eq $opt->{name}
        } @elements;
    }

    return @elements;
}

=head2 get_elements_ref

Arguments: %options

Return Value: \@elements

Accepts the same arguments as L</get_elements>, but returns an arrayref 
of results instead of a list.

=cut

sub get_elements_ref {
    my $self = shift;

    return [ $self->get_elements(@_) ];
}

=head2 get_element

Arguments: %options

Return Value: $element

    my $element = $self->get_element;
    
    my $element = $self->get_element( type => 'Textfield' );
    
    my $element = $self->get_element( name => 'username' );

Similar to get_elements(), but only returns the first element in the list.

Accepts the same arguments as get_elements().

=cut

sub get_element {
    my ( $self, %opt ) = @_;

    return ( $self->get_elements(%opt) )[0];
}

=head2 find_elements

Arguments: %options

Return Value: @elements

Similar to L</get_elements>, and accepts the same arguments, but performs a
recursive search through block-level elements.

=cut

sub find_elements {
    my ( $self, %opt ) = @_;

    my @elements = map { $_->find_elements } @{ $self->{_elements} };

    return _search_elements( \%opt, @elements );
}

=head2 const

=head2 constraint

Arguments: $type, @field_names

Return Value: $constraint

Set up a constraint on one or more elements. When process() is called on the
Widget object, with a $query object, the parameters of the query are checked 
against the specified constraints. The L<HTML::Widget::Constraint> object is 
returned to allow setting of further attributes to be set. The string 'Not_' 
can be prepended to each type name to negate the effects. Thus checking for a 
non-integer becomes 'Not_Integer'.

If the constraint package name starts with something other than 
C<HTML::Widget::Constraint::>, you can fully qualify the name by using a 
unary plus:

    $self->constraint( "+Fully::Qualified::Name", @names );

Constraint checking is done after all L<HTML::Widget::Filter> have been 
applied.

@names should contain a list of element names that the constraint applies to. 
The type of constraint can be one of:

=over 4

=item L<HTML::Widget::Constraint::All>

    my $c = $widget->constraint( 'All', 'foo', 'bar' );

The fields passed to the "All" constraint are those which are required fields
in the form.

=item L<HTML::Widget::Constraint::AllOrNone>

    my $c = $widget->constraint( 'AllOrNone', 'foo', 'bar' );

If any of the fields passed to the "AllOrNone" constraint are filled in, then 
they all must be filled in.

=item L<HTML::Widget::Constraint::Any>

    my $c = $widget->constraint( 'Any', 'foo', 'bar' );

At least one or more of the fields passed to this constraint must be filled.

=item L<HTML::Widget::Constraint::ASCII>

    my $c = $widget->constraint( 'ASCII', 'foo' );

The fields passed to this constraint will be checked to make sure their 
contents contain ASCII characters.

=item L<HTML::Widget::Constraint::Bool>

    my $c = $widget->constraint( 'Bool', 'foo' );

The fields passed to this constraint will be checked to make sure their 
contents contain a C<1> or C<0>.

=item L<HTML::Widget::Constraint::Callback>

    my $c = $widget->constraint( 'Callback', 'foo' )->callback(sub { 
        my $value=shift;
        return 1;
    });

This constraint allows you to provide your own callback sub for validation. 
The callback sub is called once for each submitted value of each named field.

=item L<HTML::Widget::Constraint::CallbackOnce>

    my $c = $widget->constraint( 'CallbackOnce', 'foo' )->callback(sub { 
        my $value=shift;
        return 1;
    });

This constraint allows you to provide your own callback sub for validation. 
The callback sub is called once per call of L</process>.

=item L<HTML::Widget::Constraint::Date>

    my $c = $widget->constraint( 'Date', 'year', 'month', 'day' );

This constraint ensures that the three fields passed in are a valid date.

=item L<HTML::Widget::Constraint::DateTime>

    my $c =
      $widget->constraint( 'DateTime', 'year', 'month', 'day', 'hour',
        'minute', 'second' );

This constraint ensures that the six fields passed in are a valid date and 
time.

=item L<HTML::Widget::Constraint::DependOn>

    my $c =
      $widget->constraint( 'DependOn', 'foo', 'bar' );

If the first field listed is filled in, all of the others are required.

=item L<HTML::Widget::Constraint::Email>

    my $c = $widget->constraint( 'Email', 'foo' );

Check that the field given contains a valid email address, according to RFC
2822, using the L<Email::Valid> module.

=item L<HTML::Widget::Constraint::Equal>

    my $c = $widget->constraint( 'Equal', 'foo', 'bar' );
    $c->render_errors( 'foo' );

The fields passed to this constraint must contain the same information, or
be empty.

=item L<HTML::Widget::Constraint::HTTP>

    my $c = $widget->constraint( 'HTTP', 'foo' );

This constraint checks that the field(s) passed in are valid URLs. The regex
used to test this can be set manually using the ->regex method.

=item L<HTML::Widget::Constraint::In>

    my $c = $widget->constraint( 'In', 'foo' );
    $c->in( 'possible', 'values' );

Check that a value is one of a specified set.

=item L<HTML::Widget::Constraint::Integer>

    my $c = $widget->constraint( 'Integer', 'foo' );

Check that the field contents are an integer.

=item L<HTML::Widget::Constraint::Length>

    my $c = $widget->constraint( 'Length', 'foo' );
    $c->min(23);
    $c->max(50);

Ensure that the contents of the field are at least $min long, and no longer
than $max.

=item L<HTML::Widget::Constraint::Number>

    my $c = $widget->constraint( 'Number', 'foo' );

Ensure that the content of the field is a number.

=item L<HTML::Widget::Constraint::Printable>

    my $c = $widget->constraint( 'Printable', 'foo' );

The contents of the given field must only be printable characters. The regex
used to test this can be set manually using the ->regex method.

=item L<HTML::Widget::Constraint::Range>

    my $c = $widget->constraint( 'Range', 'foo' );
    $c->min(23);
    $c->max(30);

The contents of the field must be numerically within the given range.

=item L<HTML::Widget::Constraint::Regex>

    my $c = $widget->constraint( 'Regex', 'foo' );
    $c->regex(qr/^\w+$/);

Tests the contents of the given field(s) against a user supplied regex.

=item L<HTML::Widget::Constraint::String>

    my $c = $widget->constraint( 'String', 'foo' );

The field must only contain characters in \w. i.e. [a-zaZ0-9_]

=item L<HTML::Widget::Constraint::Time>

    my $c = $widget->constraint( 'Time', 'hour', 'minute', 'second' );

The three fields passed to this constraint must constitute a valid time.

=back

=cut

sub constraint {
    my ( $self, $type, @names ) = @_;
    croak('constraint requires a constraint type') unless $type;

    my $abs = $type =~ s/^\+//;

    my $not = 0;
    if ( $type =~ /^Not_(\w+)$/i ) {
        $not++;
        $type = $1;
    }

    $type = "HTML::Widget::Constraint::$type" unless $abs;

    my $constraint = $self->_instantiate( $type, { names => \@names } );
    $constraint->not($not);
    push @{ $self->{_constraints} }, $constraint;
    return $constraint;
}

=head2 constraint_all

=head2 constrain_all

Arguments: @constraint_types

Return Value: @constraints

    $w->element( Textfield => 'name' );
    $w->element( Textfield => 'password' );
    $w->constraint_all( 'All' );

For each named type, add a constraint to all elements currently defined.

Does not add a constraint for elements which return false for 
L<HTML::Widget::Element/allow_constraint>; this includes 
L<HTML::Widget::Element::Span> and any element that inherits from 
L<HTML::Widget::Element::Block>.

=cut

sub constraint_all {
    my $self = shift;
    my @constraint;

    for my $element ( $self->find_elements ) {
        if ( $element->allow_constraint ) {
            for (@_) {
                push @constraint, $self->constraint( $_, $element->name );
            }
        }
    }

    return @constraint;
}

=head2 get_constraints

Arguments: %options

Return Value: @constraints

    my @constraints = $self->get_constraints;
    
    my @constraints = $self->get_constraints( type => 'Integer' );

Returns a list of all constraints added to the widget.

If a 'type' argument is given, only returns the constraints of that type.

=cut

sub get_constraints {
    my ( $self, %opt ) = @_;

    if ( exists $opt{type} ) {
        my $type = "HTML::Widget::Constraint::$opt{type}";

        return grep { $_->isa($type) } @{ $self->{_constraints} };
    }

    return @{ $self->{_constraints} };
}

=head2 get_constraints_ref

Arguments: %options

Return Value: \@constraints

Accepts the same arguments as L</get_constraints>, but returns an arrayref 
of results instead of a list.

=cut

sub get_constraints_ref {
    my $self = shift;

    return [ $self->get_constraints(@_) ];
}

=head2 get_constraint

Arguments: %options

Return Value: $constraint

    my $constraint = $self->get_constraint;
    
    my $constraint = $self->get_constraint( type => 'Integer' );

Similar to L</get_constraints>, but only returns the first constraint in the 
list.

Accepts the same arguments as L</get_constraints>.

=cut

sub get_constraint {
    my ( $self, %opt ) = @_;

    return ( $self->get_constraints(%opt) )[0];
}

=head2 embed

Arguments: @widgets

Arguments: $element, @widgets

Insert the contents of another widget object into this one. Each embedded
object will be represented as another set of fields (surrounded by a fieldset
tag), inside the created form. No copy is made of the widgets to embed, thus
calling as_xml on the resulting object will change data in the widget objects.

With an element argument, the widgets are embedded into the provided element.
No checks are made on whether the provided element belongs to $self.

Note that without an element argument, embed embeds into the top level
of the widget, and NOT into any subcontainer (whether created by you
or implicitly created).  If this is not what you need, you can choose
one of:

    # while building $self:
    $in_here = $self->element('Fieldset', 'my_fieldset');
    # later:
    $self->embed($in_here, @widgets);

    # these are equivalent: 
    $self->embed(($self->find_elements)[0], @widgets);
    $self->embed_into_first(@widgets); # but this is faster!

If you are just building a widget and do not need to import constraints
and filters from another widget, do not use embed at all, simply
assemble using the methods provided by L<HTML::Widget::Element::Fieldset>.

=cut

sub embed {
    my ( $self, @widgets ) = @_;

    my $dest;
    if ( $widgets[0]->isa('HTML::Widget::Element') ) {
        croak "destination element is not a container"
            unless $widgets[0]->isa('HTML::Widget::Element::NullContainer');
        $dest = shift @widgets;
    }

    for my $widget (@widgets) {

        if ($dest) {
            $dest->push_content( @{ $widget->{_elements} } );
        }
        else {
            push @{ $self->{_elements} }, @{ $widget->{_elements} }
                if $widget->{_elements};
        }

        push @{ $self->{_constraints} }, @{ $widget->{_constraints} }
            if $widget->{_constraints};
        push @{ $self->{_filters} }, @{ $widget->{_filters} }
            if $widget->{_filters};
    }
    return $self;
}

=head2 embed_into_first

Arguments: @widgets

As for L</embed>, but embed into the first subcontainer (fieldset) rather than
into the top level form.

=cut

sub embed_into_first {
    my $self = shift;
    my $dest = $self->_first_element;
    return $self->embed( $dest, @_ );
}

=head2 empty_errors

Arguments: $bool

Return Value: $bool

After validation, if errors are found, a span tag is created with the id 
"fields_with_errors". Set this value to cause the span tag to always be 
generated.

=head2 enctype

Arguments: $enctype

Return Value: $enctype

Set/Get the encoding type of the form. This can be either 
"application/x-www-form-urlencoded" which is the default, or 
"multipart/form-data".
See L<http://www.w3.org/TR/html4/interact/forms.html#h-17.13.4>.

If the widget contains an Upload element, the enctype is automatically set to
'multipart/form-data'.

=head2 explicit_ids

Argument: $bool

Return Value: $bool

When true; elements, fieldsets and blocks will not be given DOM id's, unless 
explicitly set with L<attributes|HTML::Widget::Accessor/attributes>.

    $w->element( 'Textfield', 'foo', {id => 'my_id'} )

The form itself will always be given an L</id>, which is C<widget> by default.

=head2 filter

Arguments: $type, @field_names

Return Value: $filter

Add a filter. Like constraints, filters can be applied to one or more elements.
These are applied to actually change the contents of the fields, supplied by
the user before checking the constraints. It only makes sense to apply filters
to fields that can contain text - Password, Textfield, Textarea, Upload.

If the filter starts with a name other than C<HTML::Widget::Filter::>, 
you can fully qualify the name by using a unary plus:

    $self->filter( "+Fully::Qualified::Name", @names );

There are currently two types of filter:

=over 4

=item L<HTML::Widget::Filter::Callback>

    my $f = $widget->filter( 'Callback', 'foo' );
    $f->callback( \&my_callback );

Filter given field(s) using a user-defined subroutine.

=item L<HTML::Widget::Filter::HTMLEscape>

    my $f = $widget->filter( 'HTMLEscape', 'foo' );

Escapes HTML entities in the given field(s).

=item L<HTML::Widget::Filter::HTMLStrip>

    my $f = $widget->filter( 'HTMLStrip', 'foo' );

Strips HTML tags from the given field(s).

    my $f = $widget->filter( 'HTMLStrip', 'foo' );
    $f->allow( 'p', 'br' );

Specify a list of HTML tags which shouldn't be stripped.

=item L<HTML::Widget::Filter::LowerCase>

    my $f = $widget->filter( 'LowerCase', 'foo' );

Make given field(s) all lowercase.

=item L<HTML::Widget::Filter::TrimEdges>

    my $f = $widget->filter( 'TrimEdges', 'foo' );

Removes whitespace from the beginning and end of the given field(s).

=item L<HTML::Widget::Filter::UpperCase>

    my $f = $widget->filter( 'UpperCase', 'foo' );

Make given field(s) all uppercase.

=item L<HTML::Widget::Filter::Whitespace>

    my $f = $widget->filter( 'Whitespace', 'foo' );

Removes all whitespace from the given field(s).

=back

=cut

sub filter {
    my ( $self, $type, @names ) = @_;

    my $abs = $type =~ s/^\+//;
    $type = "HTML::Widget::Filter::$type" unless $abs;

    my $filter = $self->_instantiate( $type, { names => \@names } );
    $filter->init($self);
    push @{ $self->{_filters} }, $filter;
    return $filter;
}

=head2 filter_all

Arguments: @filter_types

Return Value: @filters

    $w->element( Textfield => 'name' );
    $w->element( Textfield => 'age' );
    $w->filter_all( 'Whitespace' );

For each named type, add a filter to all elements currently defined.

Does not add a filter for elements which return false for 
C<HTML::Widget::Element/allow_filter>; this includes 
L<HTML::Widget::Element::Span> and any element that inherits from 
L<HTML::Widget::Element::Block>.

=cut

sub filter_all {
    my $self = shift;
    my @filter;

    for my $element ( $self->find_elements ) {
        if ( $element->allow_filter ) {
            for (@_) {
                push @filter, $self->filter( $_, $element->name );
            }
        }
    }

    return @filter;
}

=head2 get_filters

Arguments: %options

Return Value: @filters

    my @filters = $self->get_filters;
    
    my @filters = $self->get_filters( type => 'Integer' );

Returns a list of all filters added to the widget.

If a 'type' argument is given, only returns the filters of that type.

=cut

sub get_filters {
    my ( $self, %opt ) = @_;

    if ( exists $opt{type} ) {
        my $type = "HTML::Widget::Filter::$opt{type}";

        return grep { $_->isa($type) } @{ $self->{_filters} };
    }

    return @{ $self->{_filters} };
}

=head2 get_filters_ref

Arguments: %options

Return Value: \@filters

Accepts the same arguments as L</get_filters>, but returns an arrayref 
of results instead of a list.

=cut

sub get_filters_ref {
    my $self = shift;

    return [ $self->get_filters(@_) ];
}

=head2 get_filter

Arguments: %options

Return Value: $filter

    my @filters = $self->get_filter;
    
    my @filters = $self->get_filter( type => 'Integer' );

Similar to L</get_filters>, but only returns the first filter in the 
list.

Accepts the same arguments as L</get_filters>.

=cut

sub get_filter {
    my ( $self, %opt ) = @_;

    return ( $self->get_filters(%opt) )[0];
}

=head2 indi

=head2 indicator

Arguments: $field_name

Return Value: $field_name

Set/Get a boolean field. This is a convenience method for the user, so they 
can keep track of which of many Widget objects were submitted. It is also
used by L<Catalyst::Plugin::HTML::Widget>

=head2 legend

Arguments: $legend

Return Value: $legend

Set/Get a legend for this widget. This tag is used to label the fieldset. 

=cut

sub legend {
    my ( $self, $legend ) = @_;

    croak "'legend' not permitted at top level in xhtml_strict mode"
        if $self->xhtml_strict;

    my $top_level = $self->_get_implicit_subcontainer;
    unless ( $top_level->can('legend') ) {
        croak "implicit subcontainer does not support 'legend'";
    }

    $top_level->legend($legend);
    return $self;
}

=head2 merge

Arguments: @widgets

Arguments: $element, @widgets

Merge elements, constraints and filters from other widgets, into this one. The
elements will be added to the end of the list of elements that have been set
already.

Without an element argument, and with standard widgets, the contents of the
first top-level element of each widget will be merged into the first
top-level element of this widget.
This emulates the previous behaviour.

With an element argument, the widgets are merged into the named element.
No checks are made on whether the provided element belongs to $self.

=cut

sub merge {
    my ( $self, @widgets ) = @_;

    my $dest;
    if ( $widgets[0]->isa('HTML::Widget::Element') ) {
        croak "destination element is not a container"
            unless $widgets[0]->isa('HTML::Widget::Element::NullContainer');
        $dest = shift @widgets;
    }
    else {
        $dest = $self->_first_element;
        croak "merge only supported if destination first element is container"
            if $dest
            and not $dest->isa('HTML::Widget::Element::NullContainer');

        $dest = $self->_get_implicit_subcontainer unless $dest;
    }

    for my $widget (@widgets) {

        my $source = $widget->_first_element;
        croak "merge only supported if source first element is container"
            unless $source
            and $source->isa('HTML::Widget::Element::NullContainer');

        $dest->push_content( @{ $source->content } );

        push @{ $self->{_constraints} }, @{ $widget->{_constraints} }
            if $widget->{_constraints};
        push @{ $self->{_filters} }, @{ $widget->{_filters} }
            if $widget->{_filters};
    }
    return $self;
}

=head2 method

Arguments: $method

Return Value: $method

Set/Get the method used to submit the form. Can be set to either "post" or
"get". The default is "post".

=head2 result

=head2 process

Arguments: $query, \@uploads

Return Value: $result

After finishing setting up the widget and all its elements, call to create 
an L<HTML::Widget::Result>. If passed a C<$query> it will run filters and 
validation on the parameters. The L<Result|HTML::Widget::Result> object can 
then be used to produce the HTML.

L</result> is an alias for L</process>.

=cut

sub process {
    my ( $self, $query, $uploads ) = @_;

    my $errors = {};
    $query   ||= $self->query;
    $uploads ||= $self->uploads;

    # Some sane defaults
    if ( $self->container eq 'form' ) {
        $self->attributes->{method} ||= 'post';
    }

    for my $element ( @{ $self->{_elements} } ) {
        $element->prepare($self);
        $element->init($self) unless $element->{_initialized};
        $element->{_initialized}++;
    }
    for my $filter ( @{ $self->{_filters} } ) {
        $filter->prepare($self);
        $filter->init($self) unless $filter->{_initialized};
        $filter->{_initialized}++;
    }
    for my $constraint ( @{ $self->{_constraints} } ) {
        $constraint->prepare($self);
        $constraint->init($self) unless $constraint->{_initialized};
        $constraint->{_initialized}++;
    }

    my @js_callbacks;
    for my $constraint ( @{ $self->{_constraints} } ) {
        push @js_callbacks, sub { $constraint->process_js( $_[0] ) };
    }
    my %params;
    if ($query) {
        croak "Invalid query object"
            unless blessed($query)
            and $query->can('param');
        my @params = $query->param;
        for my $param (@params) {
            my @values = $query->param($param);
            $params{$param} = @values > 1 ? \@values : $values[0];
        }
        for my $filter ( @{ $self->{_filters} } ) {
            $filter->process( \%params, $uploads );
        }
        for my $element ( @{ $self->{_elements} } ) {
            my $results = $element->process( \%params, $uploads );
            for my $result ( @{$results} ) {
                my $name  = $result->name;
                my $class = ref $element;
                $class =~ s/^HTML::Widget::Element:://;
                $class =~ s/::/_/g;
                $result->type($class) if not defined $result->type;
                push @{ $errors->{$name} }, $result;
            }
        }
        for my $constraint ( @{ $self->{_constraints} } ) {
            my $results = $constraint->process( $self, \%params, $uploads );
            my $render = $constraint->render_errors;
            my @render =
                  ref $render     ? @{$render}
                : defined $render ? $render
                :                   ();

            for my $result ( @{$results} ) {
                my $name  = $result->name;
                my $class = ref $constraint;
                $class =~ s/^HTML::Widget::Constraint:://;
                $class =~ s/::/_/g;
                $result->type($class);
                $result->no_render(1)
                    if @render && !grep { $name eq $_ } @render;
                push @{ $errors->{$name} }, $result;
            }
        }
    }

    return HTML::Widget::Result->new( {
            attributes              => $self->attributes,
            container               => $self->container,
            _constraints            => $self->{_constraints},
            _elements               => $self->{_elements},
            _errors                 => $errors,
            _js_callbacks           => \@js_callbacks,
            _params                 => \%params,
            subcontainer            => $self->subcontainer,
            strict                  => $self->strict,
            empty_errors            => $self->empty_errors,
            submitted               => ( $query ? 1 : 0 ),
            element_container_class => $self->element_container_class,
            implicit_subcontainer   => $self->implicit_subcontainer,
            explicit_ids            => $self->explicit_ids,
        } );
}

=head2 query

Arguments: $query

Return Value: $query

Set/Get the query object to use for validation input. The query object can also
be passed to the process method directly.

=head2 strict

Arguments: $bool

Return Value: $bool

Only consider parameters that pass at least one constraint valid.

=head2 subcontainer

Arguments: $tag

Return Value: $tag

Set/Get the subcontainer tag to use.
Defaults to C<fieldset>.

=head2 uploads

Arguments: \@uploads

Return Value: \@uploads

Contains an arrayref of L<Apache2::Upload> compatible objects.

=head2 xhtml_strict

Arguments: $bool

Return Value: $bool

When C<true>, it is an error to have any element at the top-level of the 
widget which is not derived from L<HTML::Widget::Element::Block>. 
Currently, the only valid element supplied is the  
L<HTML::Widget::Element::Fieldset>.

When C<true>, the top-level widget may not have a L/legend>.

=head1 Frequently Asked Questions (FAQ)

=head2 How do I add an onSubmit handler to my form?

    $widget->attributes( onsubmit => $javascript );

See L<HTML::Widget/attributes>.

=head2 How do I add an onChange handler to my form field?

    $element->attributes( onchange => $javascript );

See L<HTML::Widget::Element/attributes>.

=head2 Element X does not have an accessor for Y!

You can add any arbitrary attributes with 
L<HTML::Widget::Element/attributes>.

=head2 How can I add a tag which isn't included?

You can either create your own element module files, and use them as you 
would a standard element, or alternatively...

You can call L<type|HTML::Widget::Element::Block/type> on a 
L<HTML::Widget::Element::Block> element to change the rendered tag.

    $w->element('Block')->type('br');
    # will render as
    <br />

=head2 How can I render some elements in a HTML list?

    my $ul = $w->element('Block')->type('ul');
    $ul->element('Block')->type('li')
        ->element( Textfield => foo' );
    $ul->element('Block')->type('li')
        ->element( Textfield => 'bar' );
    
    # will render as
    <ul>
    <li>
    <input class="textfield" id="widget_foo" name="foo" type="text" />
    </li>
    <li>
    <input class="textfield" id="widget_bar" name="bar" type="text" />
    </li>
    </ul>

=head1 SUPPORT

Mailing list:

L<http://lists.rawmode.org/cgi-bin/mailman/listinfo/html-widget>

=head1 SUBVERSION REPOSITORY

The publicly viewable subversion code repository is at 
L<http://dev.catalyst.perl.org/repos/Catalyst/trunk/HTML-Widget/>.

=head1 SEE ALSO

L<Catalyst> L<Catalyst::Plugin::HTML::Widget> L<HTML::Element>

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
