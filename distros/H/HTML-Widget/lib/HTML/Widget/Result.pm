package HTML::Widget::Result;

use warnings;
use strict;
use base qw/HTML::Widget::Accessor/;
use HTML::Widget::Container;
use HTML::Widget::Error;
use HTML::Element;
use Storable 'dclone';
use Carp qw/carp croak/;

__PACKAGE__->mk_accessors(
    qw/attributes container subcontainer strict submitted
        element_container_class implicit_subcontainer/
);
__PACKAGE__->mk_attr_accessors(qw/action enctype id method empty_errors/);

use overload '""' => sub { return shift->as_xml }, fallback => 1;

*attrs        = \&attributes;
*name         = \&id;
*error        = \&errors;
*has_error    = \&has_errors;
*have_errors  = \&has_errors;
*element      = \&elements;
*parameters   = \&params;
*tag          = \&container;
*subtag       = \&subcontainer;
*is_submitted = \&submitted;

=head1 NAME

HTML::Widget::Result - Result Class

=head1 SYNOPSIS

see L<HTML::Widget>

=head1 DESCRIPTION

Result Class.

=head1 METHODS

=head2 action

Arguments: $action

Return Value: $action

Contains the form action.

=head2 as_xml

Return Value: $xml

Returns xml.

=cut

sub as_xml {
    my $self = shift;

    my $element_container_class = $self->{element_container_class};

    my $c = HTML::Element->new( $self->container );

    $c->attr( $_ => ${ $self->attributes }{$_} )
        for ( keys %{ $self->attributes } );

    my $params = dclone $self->{_params};

    for my $element (
        $self->_get_elements(
            $self->{_elements}, $params, $element_container_class
        ) )
    {
        $c->push_content( $element->as_list ) unless $element->passive;
    }
    return $c->as_XML;
}

=head2 container

Arguments: $tag

Return Value: $tag

Contains the container tag.

=head2 enctype

Arguments: $enctype

Return Value: $enctype

Contains the form encoding type.

=head2 errors

=head2 error

Arguments: $name, $type

Return Value: @errors

Returns a list of L<HTML::Widget::Error> objects.

    my @errors = $form->errors;
    my @errors = $form->errors('foo');
    my @errors = $form->errors( 'foo', 'ASCII' );

L</error> is an alias for L</errors>.

=cut

sub errors {
    my ( $self, $name, $type ) = @_;

    return 0 if $name && !$self->{_errors}->{$name};

    my $errors = [];
    my @names = $name || keys %{ $self->{_errors} };
    for my $n (@names) {
        for my $error ( @{ $self->{_errors}->{$n} } ) {
            next if $type && $error->{type} ne $type;
            push @$errors, $error;
        }
    }
    return @$errors;
}

=head2 elements

=head2 element

Arguments: $name (optional)

Return Value: @elements

If C<$name> argument is supplied, returns a L<HTML::Widget::Container> 
object for the first element matching C<$name>. Otherwise, returns a list 
of L<HTML::Widget::Container> objects for all elements.

    my @form = $f->elements;
    my $age  = $f->elements('age');

L</element> is an alias for L</elements>.

=cut

sub elements {
    my ( $self, $name ) = @_;

    my $params = dclone $self->{_params};

    if ( $self->implicit_subcontainer ) {
        return $self->_get_elements(
            $self->{_elements}->[0]->content, $params,
            $self->{element_container_class}, $name
        );
    }

    return $self->_get_elements( $self->{_elements}, $params,
        $self->{element_container_class}, $name );
}

=head2 elements_ref

Arguments: $name (optional)

Return Value: \@elements

Accepts the same arguments as L</elements>, but returns an arrayref 
of results instead of a list.

=cut

sub elements_ref {
    my $self = shift;

    return [ $self->elements(@_) ];
}

=head2 find_result_element

Arguments: $name

Return Value: @elements

Looks for the named element and returns a L<HTML::Widget::Container> 
object for it if found.

=cut

sub find_result_element {
    my ( $self, $name ) = @_;

    my @elements = $self->find_elements( name => $name );
    return unless @elements;

    my $params = dclone $self->{_params};

    return $self->_get_elements( [ $elements[0] ],
        $params, $self->{element_container_class}, $name );
}

=head2 elements_for

Arguments: $name

Return Value: @elements

If the named element is a Block or NullContainer element, return a list
of L<HTML::Widget::Container> objects for the contents of that element.

=cut

sub elements_for {
    my ( $self, $name ) = @_;

    my @elements = $self->find_elements( name => $name );
    return unless @elements;

    my $ble = $elements[0];
    return unless $ble->isa('HTML::Widget::Element::NullContainer');

    my $params = dclone $self->{_params};

    return $self->_get_elements( $ble->content, $params,
        $self->{element_container_class} );
}

# code reuse++
sub _get_elements {
    my ( $self, $elements, $params, $element_container_class, $name ) = @_;

    my %javascript;
    for my $js_callback ( @{ $self->{_js_callbacks} } ) {
        my $javascript = $js_callback->( $self->name );
        for my $key ( keys %$javascript ) {
            $javascript{$key} .= $javascript->{$key} if $javascript->{$key};
        }
    }

    # the hashref of args is carried through - recursively as necessary
    #  - to _containerize_elements().
    return $self->_containerize_elements(
        $elements,
        {   name                    => $name,
            params                  => $params,
            element_container_class => $element_container_class,
            javascript              => \%javascript,
            toplevel                => 1,
            submitted               => $self->submitted,
        } );
}

# also called by HTML::Element::Block, so code reuse++ again
sub _containerize_elements {
    my ( $self, $elements, $argsref ) = @_;

    my $args = dclone $argsref;    # make copy to pass on
    my ( $element_container_class, $javascript, $name, $params, $toplevel )
        = @$args{qw(element_container_class javascript name params toplevel)};
    delete $args->{toplevel};

    my @content;
    for my $element (@$elements) {
        local $element->{container_class} = $element_container_class
            if $element_container_class;
        local $element->{_anonymous} = 1
            if ( $self->implicit_subcontainer and $toplevel );
        my ( $value, $error ) = ( undef, undef );
        my $ename = $element->{name};
        $value = $params->{$ename} if ( defined($ename) && $params );
        next if ( defined($name) && defined($ename) && ( $ename ne $name ) );
        $value = $params->{$ename} if ( defined($ename) && $params );
        $error = $self->{_errors}->{$ename} if defined $ename;
        my $container = $element->containerize( $self, $value, $error, $args );
        $container->{javascript} ||= '';
        $container->{javascript} .= $javascript->{$ename}
            if ( $ename and $javascript->{$ename} );
        return $container if defined $name;
        push @content, $container;
    }
    return @content;
}

=head2 find_elements

Return Value: @elements

Exactly the same as L<HTML::Widget/find_elements>

=cut

sub find_elements {

    # WARNING: Not safe for subclassing
    return shift->HTML::Widget::find_elements(@_);
}

=head2 empty_errors

Arguments: $bool

Return Value: $bool

Create spans for errors even when there's no errors.. (For AJAX validation validation)

=head2 has_errors

=head2 has_error

=head2 have_errors

Arguments: $name

Return Value: $bool

Returns a list of element names.

    my @names = $form->has_errors;
    my $error = $form->has_errors($name);

L</has_error> and L</have_errors> are aliases for L</has_errors>.

=cut

sub has_errors {
    my ( $self, $name ) = @_;
    my @names = keys %{ $self->{_errors} };
    return @names unless $name;
    return 1 if grep {/$name/} @names;
    return 0;
}

=head2 id

Arguments: $id

Return Value: $id

Contains the widget id.

=head2 legend

Arguments: $legend

Return Value: $legend

Contains the legend.

=head2 method

Arguments: $method

Return Value: $method

Contains the form method.

=head2 param

Arguments: $name

Return Value (scalar context): $value or \@values

Return Value (list context): @values

Returns valid parameters with a CGI.pm-compatible param method. (read-only)

=cut

sub param {
    my $self = shift;

    carp 'param method is readonly' if @_ > 1;

    if ( @_ == 1 ) {

        my $param = shift;

        my $valid = $self->valid($param);
        if ( !$valid || ( !exists $self->{_params}->{$param} ) ) {
            return wantarray ? () : undef;
        }

        if ( ref $self->{_params}->{$param} eq 'ARRAY' ) {
            return (wantarray)
                ? @{ $self->{_params}->{$param} }
                : $self->{_params}->{$param}->[0];
        }
        else {
            return (wantarray)
                ? ( $self->{_params}->{$param} )
                : $self->{_params}->{$param};
        }
    }

    return $self->valid;
}

=head2 params

=head2 parameters

Return Value: \%params

Returns validated params as hashref.

L</parameters> is an alias for L</params>.

=cut

sub params {
    my $self  = shift;
    my @names = $self->valid;
    my %params;
    for my $name (@names) {
        my @values = $self->param($name);
        if ( @values > 1 ) {
            $params{$name} = \@values;
        }
        else {
            $params{$name} = $values[0];
        }
    }
    return \%params;
}

=head2 subcontainer

Arguments: $tag

Return Value: $tag

Contains the subcontainer tag.

=head2 strict

Arguments: $bool

Return Value: $bool

Only consider parameters that pass at least one constraint valid.

=head2 submitted

=head2 is_submitted

Return Value: $bool

Returns true if C<< $widget->process >> received a C<$query> object.

L</is_submitted> is an alias for L</submitted>.

=head2 valid

Return Value: @names

Arguments: $name

Return Value: $bool

Returns a list of element names. Returns true/false if a name is given.

    my @names = $form->valid;
    my $valid = $form->valid($name);

=cut

sub valid {
    my ( $self, $name ) = @_;
    my @errors = $self->has_errors;
    my @names;
    if ( $self->strict ) {
        for my $constraint ( @{ $self->{_constraints} } ) {
            my $names = $constraint->names;
            push @names, @$names if $names;
        }
    }
    else {
        @names = keys %{ $self->{_params} };
    }
    my %valid;
CHECK: for my $name (@names) {
        for my $error (@errors) {
            next CHECK if $name eq $error;
        }
        $valid{$name}++;
    }
    my @valid = keys %valid;
    return @valid unless $name;
    return 1 if grep {/\Q$name/} @valid;
    return 0;
}

=head2 add_valid

Arguments: $key, $value

Return Value: $value

Adds another valid value to the hash.

=cut 

sub add_valid {
    my ( $self, $key, $value ) = @_;
    $self->{_params}->{$key} = $value;
    return $value;
}

=head2 add_error

Arguments: \%attributes

Return Value: $error

    $result->add_error({ name => 'foo' });

This allows you to add custom error messages after the widget has processed
the input params.

Accepts 'name', 'type' and 'message' arguments.
The 'name' argument is required. The default value for 'type' is 'Custom'.
The default value for 'message' is 'Invalid Input'.

An example of use.

    if ( ! $result->has_errors ) {
        my $user = $result->valid('username');
        my $pass = $result->valid('password');
        
        if ( ! $app->login( $user, $pass ) ) {
            $result->add_error({
                name => 'password',
                message => 'Incorrect Password',
            });
        }
    }

In this example, the C<$result> initially contains no errors. If the login()
is unsuccessful though, add_error() is used to add an error to the password
Element. If the user is shown the form again using C<< $result->as_xml >>,
they will be shown an appropriate error message alongside the password
field.

=cut 

sub add_error {
    my ( $self, $args ) = @_;

    croak "name argument required" unless defined $args->{name};

    $args->{type}    = 'Custom'        if not exists $args->{type};
    $args->{message} = 'Invalid Input' if not exists $args->{message};

    my $error = HTML::Widget::Error->new($args);

    push @{ $self->{_errors}->{ $args->{name} } }, $error;

    return $error;
}

=head1 AUTHOR

Sebastian Riedel, C<sri@oook.de>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
