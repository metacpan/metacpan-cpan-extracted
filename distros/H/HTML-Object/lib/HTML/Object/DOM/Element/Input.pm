##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Input.pm
## Version v0.1.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2021/12/23
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Input;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :input );
    use Nice::Try;
    use POSIX ();
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'input' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property accept is inherited

# Note: property accessKey is inherited

# Note: deprecated property align is inherited

# Note: property allowdirs is inherited

# Note: property alt is inherited

# Note: property autocapitalize is inherited

# Note: property autocomplete is inherited

# Note: property autofocus is inherited

# Note: property checked is inherited

# Note: property defaultChecked is inherited

# Note: property defaultValue is inherited

# Note: property dirName is inherited

# Note: property disabled is inherited

# Note: property files is inherited

# Note: property form read-only is inherited

# Note: property formAction is inherited

# Note: property formEnctype is inherited

# Note: property formMethod is inherited

# Note: property formNoValidate is inherited

# Note: property formTarget is inherited

# Note: property height is inherited

# Note: property indeterminate is inherited

# Note: property inputmode is inherited

# Note: property labels read-only is inherited

# Note: property list read-only is inherited

# Note: property max is inherited

# Note: property maxLength is inherited

# Note: property min is inherited

# Note: property minLength is inherited

sub mozGetFileNameArray { return; }

sub mozSetFileArray { return; }

# Note: property multiple is inherited

# Note: property name is inherited

sub oninput : lvalue { return( shift->on( 'input', @_ ) ); }

sub oninvalid : lvalue { return( shift->on( 'invalid', @_ ) ); }

sub onsearch : lvalue { return( shift->on( 'search', @_ ) ); }

sub onselectionchange : lvalue { return( shift->on( 'selectionchange', @_ ) ); }

# Note: property pattern is inherited

# Note: property placeholder is inherited

# Note: property readOnly is inherited

# Note: property required is inherited

# Note: property selectionDirection is inherited

# Note: property selectionEnd is inherited

# Note: property selectionStart is inherited

# Note: property size is inherited

# Note: property src is inherited

# Note: property step is inherited

sub stepDown { return( shift->_set_up_down( { direction => 'down' }, @_ ) ); }

sub stepUp { return( shift->_set_up_down( { direction => 'up' }, @_ ) ); }

# Note: property type is inherited

# Note: deprecated property useMap is inherited

# Note: property validationMessage read-only is inherited

# Note: property validity read-only is inherited

# Note: property value is inherited

# Note: property valueAsDate is inherited

# Note: property valueAsNumber is inherited

# Note: property webkitEntries is inherited

# Note: property webkitdirectory is inherited

# Note: property width is inherited

# Note: property willValidate read-only is inherited

# date              1 (day) 	    <input type="date" min="2019-12-25" step="1" />
# month             1 (month) 	    <input type="month" min="2019-12" step="12" />
# week              1 (week) 	    <input type="week" min="2019-W23" step="2" />
# time              60 (seconds) 	<input type="time" min="09:00" step="900" />
# datetime-local 	1 (day) 	    <input type="datetime-local" min="2019-12-25T19:30" step="7" />
# number            1 	            <input type="number" min="0" step="0.1" max="10" />
# range             1 	            <input type="range" min="0" step="2" max="10" />
# 
# HTML::Object::InvalidStateError
sub _set_up_down
{
    my $self = shift( @_ );
    my $opts = shift( @_ );
    my $incr = shift( @_ );
    $incr = 1 if( !defined( $incr ) || !CORE::length( "$incr" ) );
    return( $self->error( "First argument must be an hash reference of parameters." ) ) if( ref( $opts ) ne 'HASH' );
    return( $self->error({
        message => "Incremental value provided ($incr) is not a valid number.",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$self->_is_number( $incr ) );
    # "If the value is a float, the value will increment as if Math.floor(stepDecrement) was passed. If the value is negative, the value will be incremented instead of decremented. "
    # <https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/stepDown>
    $incr = POSIX::floor( "$incr" );
    my $dir = $opts->{direction} // 'down';
    my $val = $self->value;
    $self->message( 4, ( $dir eq 'up' ? 'Increasing' : 'Decreasing' ), " input value by $incr with current value being '", ( $val // '' ), "'." );
    $self->_load_class( 'DateTime' ) || return( $self->pass_error );
    $self->_load_class( 'DateTime::Format::Strptime' ) || return( $self->pass_error );
    $self->_load_class( 'DateTime::Duration' ) || return( $self->pass_error );
    my $type2unit =
    {
    date                => { unit => 'day', pattern => '%Y-%m-%d', default => '1970-01-01', step_re => qr/^\d+$/ },
    month               => { unit => 'month', pattern => '%Y-%m', default => '1970-01', step_re => qr/^\d+$/ },
    week                => { unit => 'week', pattern => '%Y-W%W', default => '1970-W1', step_re => qr/^\d+$/ },
    'time'              => { unit => 'second', pattern => ['%H:%M:%S','%H:%M'], default => '00:00:00', step_re => qr/^\d+$/, dt_format => '%02d:%02d', format => '%H:%M:%S' },
    'datetime-local'    => { unit => 'second', pattern => ['%Y-%m-%dT%H:%M:%S','%Y-%m-%dT%H:%M','%Y-%m-%dT%H'], default => '1970-01-01T00:00', step_re => qr/^\d+$/, format => '%Y-%m-%dT%H:%M:%S' },
    number              => { unit => 1, default => 0, step_re => qr/^\d+(?:\.\d+)?$/ },
    range               => { unit => 1, default => 0, step_re => qr/^\d+(?:\.\d+)?$/ },
    };
    my $type = $self->attr( 'type' ) || return( $self->error({
        message => "This input type has no type attribute.",
        class => 'HTML::Object::SyntaxError',
    }) );
    my $def = $type2unit->{ $type } || return( $self->error({
        message => "This input type \"$type\" is unsupported for " . ( $dir eq 'up' ? 'stepUp' : 'stepDown' ),
        class => 'HTML::Object::InvalidStateError',
    }) );
    $self->message( 4, "Dictionary for type '$type' is: ", sub{ $self->dumper( $def ) } );
    my $min = $self->attr( 'min' );
    my $max = $self->attr( 'max' );
    my $step = $self->attr( 'step' );
    $step = 1 if( !defined( $step ) || !CORE::length( "$step" ) || lc( "$step" ) eq 'any' || "$step" !~ /$def->{step_re}/ );
    return( $self->error({
        message => "This input step value provided ($step) is not a proper number.",
        class => 'HTML::Object::SyntaxError',
    }) ) if( !$self->_is_number( "$step" ) );
    
    local $parse = sub
    {
        my $this = shift( @_ );
        $self->message( 4, "Parsing '$this'" );
        return( $this ) if( $type eq 'week' || $type eq 'number' || $type eq 'range' );
        my( $fmt, $dt );
        if( ref( $def->{pattern} ) eq 'ARRAY' )
        {
            foreach my $pat ( @{$def->{pattern}} )
            {
                $fmt = DateTime::Format::Strptime->new( pattern => $pat );
                $dt = $fmt->parse_datetime( "$this" );
                last if( $dt );
            }
        }
        else
        {
            $fmt = DateTime::Format::Strptime->new( pattern => $def->{pattern} );
            $dt = $fmt->parse_datetime( "$this" );
        }
        if( !defined( $dt ) )
        {
            return( $self->error({
                message => "Unable to parse $type value \"$this\"': " . $fmt->errmsg,
                class => 'HTML::Object::InvalidStateError',
            }) );
        }
        
        if( $def->{format} )
        {
            $dt->set_formatter( DateTime::Format::Strptime->new( pattern => $def->{format} ) );
        }
        else
        {
            $dt->set_formatter( $fmt );
        }
        $self->message( 4, "Returning '$dt'" );
        return( $dt );
    };
    
    $max //= '';
    $self->message( 4, "Minimum value is '", ( $min // '' ), "' and max is '", ( $max // '' ), "' and step is '", ( $step // '' ), "'" );
    if( !defined( $val ) || !CORE::length( "$val" ) )
    {
        $self->message( 4, "No value defined yet." );
        # If min is provided and we are told to go up, min is our starting value and we return immediately.
        # However, the reverse is not true, i.e. if we go down and max is defined, we do not start at max value. We would start at 00:00
        if( $dir eq 'up' && defined( $min ) && CORE::length( "$min" ) )
        {
            if( exists( $type2unit->{ $type } ) )
            {
                my $this = $parse->( $min );
                return( $self->error({
                    message => "Unable to parse $type minimum value \"$min\"': " . $fmt->errmsg,
                    class => 'HTML::Object::InvalidStateError',
                }) ) if( !defined( $this ) );
                $min = $this;
            }
            $self->value = $min;
            $self->message( 4, "stepUp() called, setting value to '$min'" );
            return( $self );
        }
        elsif( $dir eq 'down' && defined( $max ) && CORE::length( "$max" )  )
        {
            if( exists( $type2unit->{ $type } ) )
            {
                my $this = $parse->( $max );
                return( $self->error({
                    message => "Unable to parse $type maximum value \"$max\"': " . $fmt->errmsg,
                    class => 'HTML::Object::InvalidStateError',
                }) ) if( !defined( $this ) );
                $max = $this;
            }
            $self->value = $max;
            $self->message( 4, "stepDown() called, setting value to '$max'" );
            return( $self );
        }
        else
        {
            $val = $def->{default};
        }
    }
    
    try
    {
        my $new;
        if( $type eq 'number' || $type eq 'range' )
        {
            $new = ( $dir eq 'up' )
                ? ( $val + ( $step * $incr ) )
                : ( $val - ( $step * $incr ) );
            if( ( defined( $max ) && CORE::length( "$max" ) && $dir eq 'up' && $new > $max ) ||
                ( defined( $min ) && CORE::length( "$min" ) && $dir eq 'down' && $new < $min ) )
            {
                $self->message( 4, "New computed value '$new' is below minimum (", ( $min // '' ), ") or higher than maximum (", ( $max // '' ), "). Silently rejecting change." );
                return( $self );
            }
            $self->message( 4, "input type is a '$type', setting new value to '$new'" );
        }
        # We manage it ourself, i.e. without using DateTime::Format::Strptime, beecause 
        # the parser does not seem capable of recognising format like 2021-W23 even with 
        # the proper pattern
        elsif( $type eq 'week' )
        {
            if( $val =~ /^(\d{1,})-W(\d{1,2})$/ )
            {
                my( $y, $w ) = ( $1, $2 );
                $self->message( 4, "Found year '$y' and week '$w'." );
                return( $self->error({
                    message => "Week number found \"$w\" is higher than the maximum possible 52",
                    class => 'HTML::Object::InvalidStateError',
                }) ) if( int( $w ) > 52 );
                return( $self->error({
                    message => "Week number found \"$w\" is lower than the minimum possible 1",
                    class => 'HTML::Object::InvalidStateError',
                }) ) if( int( $w ) < 1 );
                my $dt = DateTime->from_day_of_year( year => $y, day_of_year => ( $w * 7 ) );
                my $fmt = DateTime::Format::Strptime->new( pattern => $def->{pattern} );
                $dt->set_formatter( $fmt );
                $self->message( 4, "Current DateTime value is '$dt'" );
                
                if( $dir eq 'up' )
                {
                    $self->message( 4, "Increasing by ", ( $step * $incr ), " weeks." );
                    $dt->add( weeks => ( $step * $incr ) );
                }
                else
                {
                    $self->message( 4, "Decreasing by ", ( $step * $incr ), " weeks." );
                    $dt->subtract( weeks => ( $step * $incr ) );
                }
                
                if( $dir eq 'down' && defined( $min ) && CORE::length( "$min" )  )
                {
                    my( $min_year, $min_week );
                    if( $min =~ /^(\d{1,})-W(\d{1,2})$/ )
                    {
                        ( $min_year, $min_week ) = ( $1, $2 );
                        return( $self->error({
                            message => "Minimum week number found \"$min_week\" is higher than the maximum possible 52",
                            class => 'HTML::Object::InvalidStateError',
                        }) ) if( int( $min_week ) > 52 );
                        return( $self->error({
                            message => "Minimum week number found \"$min_week\" is lower than the minimum possible 1",
                            class => 'HTML::Object::InvalidStateError',
                        }) ) if( int( $min_week ) < 1 );
                        my $dt_min = DateTime->from_day_of_year( year => $min_year, day_of_year => ( $min_week * 7 ) );
                        $dt_min->set_formatter( $fmt );
                        if( $dt < $dt_min )
                        {
                            # Silently refuse to comply, as browsers do
                            $self->message( 4, "Computed week value '$dt' is lower than the minimum allowed '$dt_min'. Silently rejecting change." );
                            return( $self );
                        }
                    }
                    else
                    {
                        return( $self->error({
                            message => "Unable to parse $type minimum value \"$min\"': unsupported format. It should be 2021-W20 for example.",
                            class => 'HTML::Object::InvalidStateError',
                        }) );
                    }
                }
                elsif( $dir eq 'up' && defined( $max ) && CORE::length( "$max" ) )
                {
                    my( $max_year, $max_week );
                    if( $max =~ /^(\d{1,})-W(\d{1,2})$/ )
                    {
                        ( $max_year, $max_week ) = ( $1, $2 );
                        return( $self->error({
                            message => "Maximum week number found \"$max_week\" is higher than the maximum possible 52",
                            class => 'HTML::Object::InvalidStateError',
                        }) ) if( int( $max_week ) > 52 );
                        return( $self->error({
                            message => "Maximum week number found \"$max_week\" is lower than the minimum possible 1",
                            class => 'HTML::Object::InvalidStateError',
                        }) ) if( int( $max_week ) < 1 );
                        my $dt_max = DateTime->from_day_of_year( year => $max_year, day_of_year => ( $max_week * 7 ) );
                        $dt_max->set_formatter( $fmt );
                        if( $dt > $dt_max )
                        {
                            # Silently refuse to comply, as browsers do
                            $self->message( 4, "Computed week value '$dt' is higher than the maximum allowed '$dt_max'. Silently rejecting change." );
                            return( $self );
                        }
                    }
                    else
                    {
                        return( $self->error({
                            message => "Unable to parse $type maximum value \"$max\"': unsupported format. It should be 2021-W20 for example.",
                            class => 'HTML::Object::InvalidStateError',
                        }) );
                    }
                }
                $new = "$dt";
            }
            else
            {
                return( $self->error({
                    message => "Unable to parse $type value \"$val\"': unsupported format. It should be 2021-W20 for example.",
                    class => 'HTML::Object::InvalidStateError',
                }) );
            }
        }
        else
        {
            $self->message( 4, "input type is a '$type', computing using DateTime using pattern '$def->{pattern}'" );
            my $dt = $parse->( $val );
            return( $self->pass_error ) if( !defined( $dt ) );
            # We can pass negative number to duration
            my $interval = DateTime::Duration->new( "$def->{unit}s" => ( $step * $incr ) );
            $self->message( 4, "Created interval object '$interval' with unit '$def->{unit}' and value '", ( $step * $incr ), "'" );
            if( $dir eq 'up' )
            {
                $dt->add_duration( $interval );
            }
            else
            {
                $dt->subtract_duration( $interval );
            }
            
            
            if( $dir eq 'down' && defined( $min ) && CORE::length( "$min" )  )
            {
                my $dt_min = $parse->( "$min" );
                if( !defined( $dt_min ) )
                {
                    return( $self->error({
                        message => "Unable to parse $type minimum value \"$min\"': " . $fmt->errmsg,
                        class => 'HTML::Object::InvalidStateError',
                    }) );
                }
                # $dt_min->set_formatter( $fmt );
                if( $dt < $dt_min )
                {
                    # Silently refuse to comply, as browsers do
                    $self->message( 4, "Computed $type value '$dt' is lower than the minimum allowed '$dt_min'. Silently rejecting change." );
                    return( $self );
                }
            }
            elsif( $dir eq 'up' && defined( $max ) && CORE::length( "$max" ) )
            {
                my $dt_max = $parse->( "$max" );
                if( !defined( $dt_max ) )
                {
                    return( $self->error({
                        message => "Unable to parse $type maximum value \"$max\"': " . $fmt->errmsg,
                        class => 'HTML::Object::InvalidStateError',
                    }) );
                }
                # $dt_max->set_formatter( $fmt );
                if( $dt > $dt_max )
                {
                    # Silently refuse to comply, as browsers do
                    $self->message( 4, "Computed $type value '$dt' is higher than the maximum allowed '$dt_max'. Silently rejecting change." );
                    return( $self );
                }
            }
            $new = "$dt";
            $self->message( 4, "Setting new value to '$new'" );
        }
        $self->value = $new;
        return( $self );
    }
    catch( $e )
    {
        $self->message( 4, "Error occurred while computing new value with DateTime or field type '$type': $e" );
        return( $self->error({
            message => "Error " . ( $opts->{direction} ? 'increasing' : 'decreasing' ) . " the input value: $e",
            class => 'HTML::Object::InvalidStateError',
        }) );
    }
}

1;
# XXX POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Input - HTML Object DOM Input Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Input;
    my $input = HTML::Object::DOM::Element::Input->new || 
        die( HTML::Object::DOM::Element::Input->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface provides special properties and methods for manipulating the options, layout, and presentation of <input> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Input |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element> and the properties exported by L<HTML::Object::DOM::Element::Shared>

=head2 accept

This returns or sets the element's accept HTML attribute, containing comma-separated list of file types accepted by the server when type is file.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/accept>

=head2 accessKey

This returns a string containing a single character that switches input focus to the control when pressed.

Example:

    <button accesskey="s">Some button</button>

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/accessKey>, L<accessKey attribute documentation|https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/accesskey>

=head2 allowdirs

This sets or gets a boolean value. This is part of the non-standard Directory Upload API; indicates whether or not to allow directories and files both to be selected in the file list. Implemented only in Firefox and is hidden behind a preference.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/allowdirs>

=head2 alt

This returns or sets the element's alt attribute, containing alternative text to use when type is image.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/alt>

=head2 autocapitalize

This defines the capitalization behavior for user input. Valid values are none, off, characters, words, or sentences.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/autocapitalize>

=head2 autocomplete

This returns or sets the element's autocomplete attribute, indicating whether the value of the control can be automatically completed by the browser. Ignored if the value of the type attribute is C<hidden>, C<checkbox>, C<radio>, C<file>, or a button type (C<button>, C<submit>, C<reset>, C<image>). Possible values are:

=over 4

=item on

The browser can autocomplete the value using previously stored value

=item off

The user must explicitly enter a value

=back

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/autocomplete>

=head2 autofocus

This returns or sets the element's autofocus attribute, which specifies that a form control should have input focus when the page loads, unless the user overrides it, for example by typing in a different control. Only one form element in a document can have the autofocus attribute. It cannot be applied if the type attribute is set to hidden (that is, you cannot automatically set focus to a hidden control).

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/autofocus>

=head2 checked

This returns a boolean value, which represents the current state of the element when type is checkbox or radio.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/checked>

=head2 defaultChecked

This returns or sets a boolean value, which represents the default state of a radio button or checkbox as originally specified in HTML that
created this object.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/defaultChecked>

=head2 defaultValue

This returns or sets the default value as originally specified in the HTML that created this object.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/defaultValue>

=head2 dirName

This returns or sets a string, which represents the directionality of the element.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/dirName>

=head2 disabled

This returns or sets a boolean value, which represents the element's disabled attribute, indicating that the control is not available for interaction. The input values will not be submitted with the form. See also readonly.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/disabled>

=head2 files

This returns or accepts a L<FileList|HTML::Object::DOM::FileList> object, which contains a list of File objects representing the files selected for upload. However, this being a perl framework, you would have to set the object values yourself.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/files>

=head2 form

Read-only.

L<HTML::Object::DOM::Element::Form> object: this returns a reference to the parent <form> element.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/form>

=head2 formAction

This returns or sets the element's formaction attribute, containing the C<URI> of a program that processes information submitted by the element. This overrides the action attribute of the parent form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/formAction>

=head2 formEnctype

This returns or sets the element's formenctype attribute, containing the type of content that is used to submit the form to the server. This overrides the enctype attribute of the parent form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/formEnctype>

=head2 formMethod

This returns or Sets the element's formmethod attribute, containing the HTTP method that the browser uses to submit the form. This overrides the method attribute of the parent form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/formMethod>

=head2 formNoValidate

This returns or sets a boolean value, which represents the element's C<formnovalidate> HTML attribute, indicating that the form is not to be validated when it is submitted. This overrides the C<novalidate> attribute of the parent form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/formNoValidate>

=head2 formTarget

This returns or sets the element's formtarget attribute, containing a name or keyword indicating where to display the response that is received after submitting the form. This overrides the target attribute of the parent form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/formTarget>

=head2 height

This returns or sets the element's height attribute, which defines the height of the image displayed for the button, if the value of type is image.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/height>

=head2 indeterminate

This returns a boolean value, which represents whether the checkbox or radio button is in indeterminate state. For checkboxes, the effect is that the appearance of the checkbox is obscured/greyed in some way as to indicate its state is indeterminate (not checked but not unchecked). Does not affect the value of the checked attribute, and clicking the checkbox will set the value to false.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/indeterminate>

=head2 inputmode

This provides a hint to browsers as to the type of virtual keyboard configuration to use when editing this element or its contents.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/inputmode>

=head2 labels

Read-only.

This returns an L<array object|Module::Generic::Array> of C<label> elements that are labels for this element.

Example:

    <label id="label1" for="test">Label 1</label>
    <input id="test" />
    <label id="label2" for="test">Label 2</label>

    window->addEventListener( DOMContentLoaded => sub
    {
        my $input = $doc->getElementById( 'test' );
        for( my $i = 0; $i < $input->labels->length; $i++ )
        {
            say( $input->labels->[$i]->textContent ); # "Label 1" and "Label 2"
        }
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/labels>

=head2 list

Read-only.

This returns the L<element|HTML::Object::DOM::Element> pointed by the list attribute. The property may be C<undef> if no HTML element found in the same tree.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/list>

=head2 max

This returns or sets a string, which represents the element's max attribute, containing the maximum (numeric or date-time) value for this item, which must not be less than its minimum (min attribute) value.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/max>

=head2 maxLength

This returns or sets a long, which represents the element's C<maxlength> attribute, containing the maximum number of characters (in Unicode code points) that the value can have. (If you set this to a negative number, an exception will be thrown.)

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/maxLength>

=head2 min

This returns or sets a string, which represents the element's min attribute, containing the minimum (numeric or date-time) value for this item, which must not be greater than its maximum (max attribute) value.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/min>

=head2 minLength

This returns or sets a long, which represents the element's C<minlength> attribute, containing the minimum number of characters (in Unicode code points) that the value can have. (If you set this to a negative number, an exception will be thrown.)

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/minLength>

=head2 multiple

This returns or sets a boolean value, which represents the element's multiple attribute, indicating whether more than one value is possible (e.g., multiple files).

Example:

    # $fileInput is a <input type=$file multiple>
    my $fileInput = $doc->getElementById('myfileinput');

    # If true
    if( $fileInput->multiple )
    {
        for( my $i = 0; $i < $fileInput->files->length; $i++ )
        {
            # Loop $fileInput->files
        }
    }
    # Only one $file available
    else
    {
        my $file = $fileInput->files->item(0);
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/multiple>

=head2 name

This returns or sets a string, which represents the element's name attribute, containing a name that identifies the element when submitting the form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/name>

=head2 pattern

This returns or sets a string, which represents the element's pattern attribute, containing a regular expression that the control's value is checked against. Use the title attribute to describe the pattern to help the user. This attribute applies when the value of the type attribute is C<text>, C<search>, C<tel>, C<url> or C<email>; otherwise it is ignored.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/pattern>

=head2 placeholder

This returns or sets a string, which represents the element's placeholder attribute, containing a hint to the user of what can be entered in the control. The placeholder text must not contain carriage returns or line-feeds. This attribute applies when the value of the type attribute is C<text>, C<search>, C<tel>, C<url> or C<email>; otherwise it is ignored.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/placeholder>

=head2 readOnly

This returns or sets a boolean value, which represents the element's readonly HTML attribute, indicating that the user cannot modify the value of the control.This is ignored if the value of the type attribute is hidden, range, color, checkbox, radio, file, or a button type.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/readOnly>

=head2 required

This returns or sets a boolean value, which represents the element's required attribute, indicating that the user must fill in a value before submitting a form.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/required>

=head2 selectionDirection

This returns or sets a string, which represents the direction in which selection occurred. Possible values are:forward if selection was performed in the start-to-end direction of the current localebackward for the opposite directionnone if the direction is unknown

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/selectionDirection>

=head2 selectionEnd

This returns or sets an unsigned long, which represents the end index of the selected text. When there's no selection, this returns the offset of the character immediately following the current text input cursor position.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/selectionEnd>

=head2 selectionStart

This returns or sets an unsigned long, which represents the beginning index of the selected text. When nothing is selected, this returns the position of the text input cursor (caret) inside of the C<input> element.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/selectionStart>

=head2 size

This returns or sets an unsigned long, which represents the element's size attribute, containing visual size of the control. This value is in pixels unless the value of type is text or password, in which case, it is an integer number of characters. Applies only when type is set to C<text>, C<search>, C<tel>, C<url>, C<email>, or C<password>; otherwise it is ignored.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/size>

=head2 src

This returns or sets a string, which represents the element's src attribute, which specifies a C<URI> for the location of an image to display on the graphical submit button, if the value of type is image; otherwise it is ignored.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/src>

=head2 step

This returns or sets a string, which represents the element's step attribute, which works with min and max to limit the increments at which a numeric or date-time value can be set. It can be the string any or a positive floating point number. If this is not set to any, the control accepts only values at multiples of the step value greater than the minimum.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/step>, L<documentation on step attribute|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/step>

=head2 type

This returns or sets a string, which represents the element's type attribute, indicating the type of control to display. See type attribute of <input> for possible values.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/type>

=head2 validationMessage

Read-only.

This returns or sets a string, which represents a localised message that describes the validation constraints that the control does not satisfy (if any). This is the empty string if the control is not a candidate for constraint validation (willvalidate is false), or it satisfies its constraints. This value can also be set by the L</setCustomValidity> method.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/validationMessage>

=head2 validity

Read-only.

This returns or sets the element's current L<validity state object|HTML::Object::DOM::ValidityState>.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/validity>

=head2 value

This returns or sets a string, which represents the current value of the control.

Note: If the user enters a value different from the value expected, this may return an empty string.

This interface does not enforce proper value, so it is up to you to use the right one. For example, using a value of C<2021-W55> for an input of type C<week> is normally illegal since the week number value should be a number between 1 and 53.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/value>

=head2 valueAsDate

This returns or sets a date, which represents the value of the element, interpreted as a date, or C<undef> if conversion is not possible.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/valueAsDate>

=head2 valueAsNumber

This returns a double, which represents the value of the element, interpreted as one of the following, in order:

=over 4

=item A time value

=item A number

=item NaN (C<undef>) if conversion is impossible

=back

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/valueAsNumber>

=head2 webkitEntries

This always returns C<undef> under perl.

Under JavaScript, this returns an Array of C<FileSystemEntry> objects that describes the currently selected files or directories.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitEntries>

=head2 webkitdirectory

This returns or sets a boolean value, which represents the C<webkitdirectory> HTML attribute; if true, the file system picker interface only accepts directories instead of files.

Example:

    <input type="file" id="filepicker" name="fileList" webkitdirectory multiple />
    <ul id="listing"></ul>

    $doc->getElementById( 'filepicker' )->addEventListener( change => sub
    {
        my $output = $doc->getElementById( 'listing' );
        my $files = event->target->files;

        for( my $i=0; $i < $files->length; $i++ )
        {
            my $item = $doc->createElement( 'li' );
            $item->innerHTML = $files->[$i]->webkitRelativePath;
            $output->appendChild( $item );
        };
    }, { capture => 0 });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/webkitdirectory>

=head2 width

This returns or sets a string, which represents the element's width attribute, which defines the width of the image displayed for the button, if the value of type is image.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/width>

=head2 willValidate

Read-only.

This returns or sets a boolean value, which represents whether the element is a candidate for constraint validation. It is false if any conditions bar it from constraint validation, including: its type is hidden, reset, or button; it has a C<datalist> ancestor; its disabled property is true.

See also L<Mozilla documentation|https://pr11904.content.dev.mdn.mozit.cloud/en-US/docs/Web/API/HTMLInputElement/willValidate>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 mozGetFileNameArray

Since this is a perl environment, this has no effect and always returns C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/mozGetFileNameArray>

=head2 mozSetFileArray

Since this is a perl environment, this has no effect and always returns C<undef>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/mozSetFileArray>

=head2 setCustomValidity

Sets a custom message to display if the input element's value is not valid.

See L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/setCustomValidity>

=head2 stepDown

Decrements the value by (step * n), where n defaults to 1 if not specified. Returns an C<HTML::Object::InvalidStateError> error:

=over 4

=item * if the method is not applicable to for the current type value,

=item * if the value cannot be converted to a number or recognised as a L<DateTime> object when applicable,

=item * if the resulting value is above the L</max> or below the L</min> set by their respective HTML attribute.

=back

If the element has no C<step> value, C<step> defaults to C<1>.

Supported types and equivalent values are:

=over 4

=item * date

Unit is 1 (day).

    <input type="date" min="2019-12-25" step="1" />

This defaults to C<1970-01-01> if not value is set yet, but if a C<max> value is set and L</stepDown> is called, the initial value will be that of C<max> and if C<min> value is set and L</stepUp> is called, the initial value will be that of C<min>

=item * month

Unit is 1 (month).

    <input type="month" min="2019-12" step="12" />

This defaults to C<1970-01> if not value is set yet, but if a C<max> value is set and L</stepDown> is called, the initial value will be that of C<max> and if C<min> value is set and L</stepUp> is called, the initial value will be that of C<min>

=item * week

Unit is 1 (week).

    <input type="week" min="2019-W23" step="2" />

This defaults to C<1970-W1> if not value is set yet, but if a C<max> value is set and L</stepDown> is called, the initial value will be that of C<max> and if C<min> value is set and L</stepUp> is called, the initial value will be that of C<min>

=item * time

Unit is 60 (seconds).

    <input type="time" min="09:00" step="900" />

This defaults to C<00:00> if not value is set yet, but if a C<max> value is set and L</stepDown> is called, the initial value will be that of C<max> and if C<min> value is set and L</stepUp> is called, the initial value will be that of C<min>

=item * datetime-local

Unit is 1 (second).

    <input type="datetime-local" min="2019-12-25T19:30:01" step="7" />

This defaults to C<1970-01-01T00:00:00> if not value is set yet, but if a C<max> value is set and L</stepDown> is called, the initial value will be that of C<max> and if C<min> value is set and L</stepUp> is called, the initial value will be that of C<min>

This also supports the following format C<2019-12-25T19:30>, i.e. without seconds, and C<2019-12-25T19>, i.e. without minutes or seconds

=item * number

Unit is 1.

    <input type="number" min="0" step="0.1" max="10" />

=item * range

Unit is 1.

    <input type="range" min="0" step="2" max="10" />

=back

Interestingly enough, if you have the following HTML:

    <input type="time" min="17:00" step="900" />

and call C<stepUp>, it will set the value the first time to C<17:00>, then the second time to C<17:15>.

However, the other way around is not true, i.e.

    <input type="time" max="17:00" step="900" />

Then a call to C<stepDown> will not yield the value C<17:00>, but instead C<23:45>, the second time to C<17:00> and third time to C<16:45>. A L<bug report No 1749427 was filed to Mozilla|https://bugzilla.mozilla.org/show_bug.cgi?id=1749427> and L<to Chromium|https://bugs.chromium.org/p/chromium/issues/detail?id=1286160> on 2022-01-11 and is preemptively corrected here in this interface.

Example:

    <!--    decrements by intervals of 900 seconds (15 minute) -->
    <input type="time" max="17:00" step="900" />

    <!-- decrements by intervals of 7 days (one week) -->
    <input type="date" max="2019-12-25" step="7" />

    <!-- decrements by intervals of 12 months (one year) -->
    <input type="month" max="2019-12" step="12" />

    $element->stepDown( [ $stepDecrement ] );

Another example:

    <p>
        <label>Enter a number between 0 and 400 that is divisible by 5:
            <input type="number" step="5" id="theNumber" min="0" max="400" />
        </label>
    </p>
    <p>
        <label>Enter how many values of step you would like to decrement by or leave it blank:
            <input type="number" step="1" id="decrementer" min="-2" max="15" />
        </label>
    </p>
    <input type="button" value="Decrement" id="theButton" />

    # make the $button call the function
    my $button = $doc->getElementById('theButton');
    $button->addEventListener( click => sub
    {
        &stepondown();
    });

    sub stepondown
    {
        my $input = $doc->getElementById('theNumber');
        my $val = $doc->getElementById('decrementer')->value;

        # decrement with a parameter
        if( $val )
        {
            $input->stepDown( $val );
        }
        # or without a parameter. Try it with 0, 5, -2, etc.
        else
        {
            $input->stepDown();
        }
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/stepDown>, and L<Mozilla documentation on step|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/step>

=head2 stepUp

Increments the value by (step * n), where n defaults to 1 if not specified. Returns an C<HTML::Object::InvalidStateError> error:

=over 4

=item * if the method is not applicable to for the current type value.,

=item * if the element has no step value,

=item * if the value cannot be converted to a number,

=item * if the resulting value is above the max or below the min.

=back

Supported types and equivalent values are the same as for L</stepDown>:

Example:

    <p>
        <label>Enter a number between 0 and 400 that is divisible by 5:
            <input type="number" step="5" id="theNumber" min="0" max="400" />
        </label>
    </p>
    <p>
        <label>Enter how many values of step you would like to increment by or leave it blank:
            <input type="number" step="1" id="incrementer" min="0" max="25" />
        </label>
    </p>
    <input type="button" value="Increment" id="theButton" />

    # make the $button call the function
    my $button = $doc->getElementById('theButton')
    $button->addEventListener( click => sub
    {
        &steponup();
    })

    sub steponup
    {
        my $input = $doc->getElementById('theNumber');
        my $val = $doc->getElementById('incrementer')->value;
        # increment with a parameter
        if( $val )
        {
            $input->stepUp( $val );
        }
        # or without a parameter. Try it with 0
        else
        {
            $input->stepUp();
        }
    }

Another example:

    <input max="4096" min="1" name="size" step="2" type="number" value="4096" id="foo" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/stepUp>, and L<Mozilla documentation on step|https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/step>

=head1 EVENTS

Event listeners for those events can also be found by prepending C<on> before the event type:

For example, C<input> event listeners can be set also with C<oninput> method:

    $e->oninput(sub{ # do something });
    # or as an lvalue method
    $e->oninput = sub{ # do something };

=head2 input

Fires when the value of an C<input>, C<select>, or C<textarea> element has been changed. Note that this is actually fired on the L<HTML::Object::DOM::Element> interface and also applies to contenteditable elements, but we've listed it here because it is most commonly used with form input elements. Also available via the C<oninput> event handler property.

Example:

    <input placeholder="Enter some text" name="name" />
    <p id="values"></p>

    my $input = $doc->querySelector('input');
    my $log = $doc->getElementById('values');

    $input->addEventListener( input => \&updateValue );

    sub updateValue
    {
        my $e = shift( @_ );
        $log->textContent = $e->target->value;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/input_event>

=head2 invalid

Fired when an element does not satisfy its constraints during constraint validation. Also available via the oninvalid event handler property.

Example:

    <form action="#">
        <ul>
            <li><label>Enter an integer between 1 and 10: <input type="number" min="1" max="10" required></label></li>
            <li><input type="submit" value="submit"></li>
        </ul>
    </form>
    <p id="log"></p>

    my $input = $doc->querySelector('input');
    my $log = $doc->getElementById('log');

    $input->addEventListener( invalid => \&logValue );
    sub logValue
    {
        my $e = shift( @_ )l
        $log->textContent = $e->target->value;
    }

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/invalid_event>

=head2 search

Fired when a search is initiated on an <input> of type="search". Also available via the onsearch event handler property.

Example:

    # addEventListener version
    my $input = $doc->querySelector('input[type="search"]');

    $input->addEventListener( search => sub
    {
        say( "The term searched for was " . $input->value );
    })

    # onsearch version
    my $input = $doc->querySelector( 'input[type="search"]' );

    $input->onsearch = sub
    {
        say( "The term searched for was " + $input->value );
    })

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/search_event>

=head2 selectionchange

Fires when the text selection in a C<input> element has been changed.

Example:

    <div>Enter and select text here:<br />
        <input id="mytext" rows="2" cols="20" />
    /div>
    <div>selectionStart: <span id="start"></span></div>
    <div>selectionEnd: <span id="end"></span></div>
    <div>selectionDirection: <span id="direction"></span></div>

    my $myinput = $doc->getElementById( 'mytext' );

    $myinput->addEventListener( selectionchange => sub
    {
        $doc->getElementById( 'start' )->textContent = $myinput->selectionStart;
        $doc->getElementById( 'end' )->textContent = $myinput->selectionEnd;
        $doc->getElementById( 'direction' )->textContent = $myinput->selectionDirection;
    });

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/selectionchange_event>

=head1 DEPRECATED PROPERTIES

=head2 align

Provided with a string, and this sets or gets the HTML attribute that represents the alignment of the element. It is better to use CSS instead.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/align>

=head2 useMap

A string reflecting the usemap HTML attribute, containing the page-local URL of the C<<map>> element describing the image map to use. The page-local URL is a pound (hash) symbol (#) followed by the ID of the C<<map>> element, such as #my-map-element. The C<<map>> in turn contains C<<area>> elements indicating the clickable areas in the image.

Example:

    <map name="mainmenu-map">
        <area shape="circle" coords="25, 25, 75" href="/index.html" alt="Return to home page">
        <area shape="rect" coords="25, 25, 100, 150" href="/index.html" alt="Shop">
    </map>

    <input usemap="#mainmenu-map" />

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement/useMap>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLInputElement>, L<Mozilla documentation on input element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
