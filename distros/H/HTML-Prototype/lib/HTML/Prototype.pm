package HTML::Prototype;

use strict;
use base qw/Class::Accessor::Fast/;
use vars qw/$VERSION $prototype $controls $dragdrop $effects/;

$VERSION = '1.48';

use HTML::Element;
use HTML::Prototype::Js;
use HTML::Prototype::Controls;
use HTML::Prototype::DragDrop;
use HTML::Prototype::Effects;
use HTML::Prototype::Helper;

{
    local $/;
    $prototype = <HTML::Prototype::Js::DATA>;
    close HTML::Prototype::Js::DATA;
    $controls = <HTML::Prototype::Controls::DATA>;
    close HTML::Prototype::Controls::DATA;
    $dragdrop = <HTML::Prototype::DragDrop::DATA>;
    close HTML::Prototype::DragDrop::DATA;
    $effects = <HTML::Prototype::Effects::DATA>;
    close HTML::Prototype::Effects::DATA;
}

my $callbacks    = [qw/uninitialized loading loaded interactive complete/];
my $ajax_options = [qw/url asynchronous method insertion form with/];

=head1 NAME

HTML::Prototype - Generate HTML and Javascript for the Prototype library

=head1 SYNOPSIS

    use HTML::Prototype;

    my $prototype = HTML::Prototype->new;
    print $prototype->auto_complete_field(...);
    print $prototype->auto_complete_result(...);
    print $prototype->auto_complete_stylesheet(...);
    print $prototype->content_tag(...);
    print $prototype->define_javascript_functions;
    print $prototype->draggable_element(...);
    print $prototype->drop_receiving_element(...);
    print $prototype->evaluate_remote_response(...);
    print $prototype->form_remote_tag(...);
    print $prototype->in_place_editor(...);
    print $prototype->in_place_editor_field(...);
    print $prototype->in_place_editor_stylesheet(...);
    print $prototype->javascript_tag(...);
    print $prototype->link_to_function(...);
    print $prototype->link_to_remote(...);
    print $prototype->observe_field(...);
    print $prototype->observe_form(...);
    print $prototype->periodically_call_remote(...);
    print $prototype->sortable_element(...);
    print $prototype->submit_to_remote(...);
    print $prototype->tag(...);
    print $prototype->text_field_with_auto_complete(...);
    print $prototype->update_element_function(...);
    print $prototype->visual_effect(...);

=head1 DESCRIPTION

The module contains some code generators for Prototype, the famous JavaScript
OO library and the script.aculous extensions.

The Prototype library (http://prototype.conio.net/) is designed to make
AJAX easy.  Catalyst::Plugin::Prototype makes it easy to connect to the
Prototype library.

This is mostly a port of the Ruby on Rails helper tags for JavaScript
for use in L<Catalyst>.

=head2 METHODS

=over 4

=item $prototype->in_place_editor( $field_id, \%options )

Makes an HTML element specified by the DOM ID C<$field_id> become an in-place
editor of a property.

A form is automatically created and displayed when the user clicks the element,
something like this:

	<form id="myElement-in-place-edit-form" target="specified url">
		<input name="value" text="The content of myElement"/>
		<input type="submit" value="ok"/>
		<a onClick="javascript to cancel the editing">cancel</a>
	</form>

The form is serialized and sent to the server using an Ajax call, the action
on the server should process the value and return the updated value in the
body of the reponse. The element will automatically be updated with the
changed value (as returned from the server).

Required options are:

C<url>: Specifies the url where the updated value should be sent after the
user presses "ok".

Addtional options are:

C<rows>: Number of rows (more than 1 will use a TEXTAREA)

C<cols>: The number of columns the text area should span (works for both single line or multi line).

C<size>: Synonym for ‘cols’ when using single-line (rows=1) input

C<cancel_text>: The text on the cancel link. (default: "cancel")

C<form_class_name>: CSS class used for the in place edit form. (default: "inplaceeditor-form")

C<save_text>: The text on the save link. (default: "ok")

C<saving_class_name>: CSS class added to the element while displaying "Saving..."
(removed when server responds). (default: "inplaceeditor-saving")

C<load_text_url>: Will cause the text to be loaded from the server (useful if
your text is actually textile and formatted on the server)

C<loading_text>: If the C<load_text_url> option is specified then this text is
displayed while the text is being loaded from the server. (default: "Loading...")

C<click_to_edit_text>: The text on the click-to-edit link. (default: "click to edit")

C<external_control>: The id of an external control used to enter edit mode.

C<ajax_options>: Pass through options to the AJAX call (see prototype's Ajax.Updater)

C<with>: JavaScript snippet that should return what is to be sent in the
Ajax call, C<form> and C<value> are implicit parameters

=cut

sub in_place_editor {
    my ( $self, $id, $options ) = @_;

    my %to_options = (
        'cancel_text'        => \'cancelText',
        'save_text'          => \'okText',
        'rows'               => 'rows',
        'external_control'   => \'externalControl',
        'ajax_options'       => 'ajaxOptions',
        'saving_text'        => \'savingText',
        'saving_class_name'  => \'savingClassName',
        'form_id'            => \'formId',
        'cols'               => 'cols',
        'size'               => 'size',
        'load_text_url'      => \'loadTextURL',
        'loading_text'       => \'loadingText',
        'form_class_name'    => \'formClassName',
        'click_to_edit_text' => \'clickToEditText',
    );

    my $function = "new Ajax.InPlaceEditor( '$id', '" . $options->{url} . "'";

    my $js_options = _options_to_js_options( \%to_options, $options );
    $js_options->{callback} =
      ( 'function ( form, value ) { return ' . $options->{with} . ' }' )
      if $options->{with};

    $function .= ',' . _options_for_javascript($js_options)
      if keys %{$js_options};
    $function .= ')';

    return $self->javascript_tag($function);
}

=item $prototype->in_place_editor_field( $object, $method, \%tag_options, \%in_place_editor_options )

Renders the value of the specified object and method with in-place editing capabilities.

=cut

sub in_place_editor_field {
    my ( $self, $object, $method, $tag_options, $in_place_editor_options ) = @_;

    $tag_options             ||= {};
    $in_place_editor_options ||= {};

    my $tag = HTML::Prototype::Helper::Tag->new( $object, $method, $self );
    $tag_options = {
        tag   => 'span',
        id    => "$object\_$method\_" . $tag->object->id . '_in_place_editor',
        class => 'in_place_editor_field',
        %{$tag_options},
    };

    return $tag->to_content_tag( delete $tag_options->{tag}, $tag_options )
      . $self->in_place_editor( $tag_options->{id}, $in_place_editor_options );
}

=item $prototype->in_place_editor_stylesheet

Returns the in_place_editor stylesheet.

=cut

sub in_place_editor_stylesheet {
    my $self = shift;
    return $self->content_tag( 'style', <<"");
    .inplaceeditor-saving {
        background: url(wait.gif) bottom right no-repeat;
    }

}

=item $prototype->auto_complete_field( $field_id, \%options )

Adds Ajax autocomplete functionality to the text input field with the
DOM ID specified by C<$field_id>.

This function expects that the called action returns a HTML <ul> list,
or nothing if no entries should be displayed for autocompletion.

Required options are:

C<url>: Specifies the URL to be used in the AJAX call.


Addtional options are:

C<update>: Specifies the DOM ID of the element whose  innerHTML should
be updated with the autocomplete entries returned by the Ajax request.
Defaults to field_id + '_auto_complete'.

C<with>: A Javascript expression specifying the parameters for the
XMLHttpRequest.
This defaults to 'value', which in the evaluated context refers to the
new field value.

C<indicator>: Specifies the DOM ID of an elment which will be displayed
Here's an example using L<Catalyst::View::Mason> with an indicator against the auto_complete_result example below on the server side.  Notice the 'style="display:none"' in the indicator <span>.

	<% $c->prototype->define_javascript_functions %>

	<form action="/bar" method="post" id="baz">
	<fieldset>
        	<legend>Type search terms</legend>
        	<label for="acomp"><span class="field">Search:</span></label>
        	<input type="text" name="acomp" id="acomp"/>
		<span style="display:none" id="acomp_stat">Searching...</span><br />
	</fieldset>
	</form>

        <span id="acomp_auto_complete"></span><br/>

	<% $c->prototype->auto_complete_field( 'acomp', { url => '/autocomplete', indicator => 'acomp_stat' } ) %>

while autocomplete is running.

C<tokens>: A  string or an array of strings containing separator tokens for
tokenized incremental autocompletion. Example: C<<tokens => ','>> would
allow multiple autocompletion entries, separated by commas.

C<min_chars>: The minimum number of characters that should be in the input
field before an Ajax call is made to the server.

C<on_hide>: A Javascript expression that is called when the autocompletion
div is hidden. The expression should take two variables: element and update.
Element is a DOM element for the field, update is a DOM element for the div
from which the innerHTML is replaced.

C<on_show>: Like on_hide, only now the expression is called then the div
is shown.

C<select>: Pick the class of the element from which the value for
insertion should be extracted. If this is not specified,
the entire element is used


=cut

sub auto_complete_field {
    my ( $self, $id, $options ) = @_;

    my %to_options = (
        'on_show'   => 'onShow',
        'on_hide'   => 'onHide',
        'min_chars' => 'minChars',
        'indicator' => \'indicator',
        'select'    => \'select',
    );
    $options ||= {};
    my $update = ( $options->{update} || "$id" ) . '_auto_complete';
    my $function =
      "new Ajax.Autocompleter( '$id', '$update', '"
      . ( $options->{url} || '' ) . "'";

    my $js_options = _options_to_js_options( \%to_options, $options );
    $js_options->{tokens} =
      _array_or_string_for_javascript( $options->{tokens} )
      if $options->{tokens};
    $js_options->{callback} =
      ( 'function ( element, value ) { return ' . $options->{with} . ' }' )
      if $options->{with};

    $function .= ', ' . _options_for_javascript($js_options)
      if keys %{$js_options};
    $function .= ' )';

    return $self->javascript_tag($function);
}

=item $prototype->auto_complete_result(\@items, $fieldname, [$phrase])

Returns a list, to communcate with the Autocompleter.

Here's an example for L<Catalyst>:

    sub autocomplete : Global {
        my ( $self, $c ) = @_;
        my @items = qw/foo bar baz/;
        $c->res->body( $c->prototype->auto_complete_result(\@items) );
    }

=cut

sub auto_complete_result {
    my ( $self, $entries, $field, $phrase ) = @_;
    my @elements;
    for my $entry ( @{$entries} ) {
        my $item;
        if ( ref($entry) eq 'HASH' ) {
            my $e = $entry->{$field};
            $item = $phrase ? _highlight( $e, $phrase ) : $e;
        }
        else {
            $item = $entry;
        }
        push @elements, HTML::Element->new('li')->push_content($item);
    }

    @elements = _unique(@elements);

    return $self->content_tag( 'ul', \@elements );
}

=item $prototype->text_field_with_auto_complete($method, [\%tag_options], [\%completion_options])

Wrapper for text_field with added Ajax autocompletion functionality.

In your controller, you'll need to define an action called
auto_complete_for_object_method to respond the AJAX calls,

=cut

sub text_field_with_auto_complete {
    my ( $self, $object, $method, $tag_options, $completion_options ) = @_;

    $tag_options        ||= {};
    $completion_options ||= {};

    my $style =
      $completion_options->{skip_style}
      ? ''
      : $self->auto_complete_stylesheet();
    my $text_field = $self->text_field( $object, $method, $tag_options );
    my $content_tag =
      $self->content_tag( 'div', '',
        { id => "$object\_$method\_auto_complete", class => 'auto_complete' } );
    my $auto_complete_field = $self->auto_complete_field(
        "$object\_$method",
        {
            url => { action => "auto_complete_for_$object\_$method" },
            %{$completion_options}
        }
    );

    return $style . $text_field . $content_tag . $auto_complete_field;
}

=item $prototype->auto_complete_stylesheet

Returns the auto_complete stylesheet.

=cut

sub auto_complete_stylesheet {
    my $self = shift;
    return $self->content_tag( 'style', <<"");
    div.auto_complete {
        width: 350px;
        background: #fff;
    }
    div.auto_complete ul {
        border:1px solid #888;
        margin:0;
        padding:0;
        width:100%;
        list-style-type:none;
    }
    div.auto_complete ul li {
        margin:0;
        padding:3px;
    }
    div.auto_complete ul li.selected {
        background-color: #ffb;
    }
    div.auto_complete ul strong.highlight {
        color: #800;
        margin:0;
        padding:0;
    }

}

=item $prototype->content_tag( $name, $content, \%html_options )

Returns a block with opening tag, content, and ending tag. Useful for
autogenerating tags like B<<a href="http://catalyst.perl.org">Catalyst
Homepage</a>>. The first parameter is the tag name, i.e. B<'a'> or
B<'img'>.

=cut

sub content_tag {
    my ( $self, $name, $content, $html_options ) = @_;

    return HTML::Prototype::Helper::Tag->_content_tag( $name, $content,
        $html_options );
}

=item $prototype->text_field( $name, $method, $html_options )

Returns an input tag of the "text" type tailored for accessing a specified
attribute (identified by I<$method>) on an object assigned to the template
(identified by I<$object>). Additional options on the input tag can be passed
as a hash ref with I<$html_options>.

=cut

sub text_field {
    my ( $self, $object_name, $method, $html_options ) = @_;
    $html_options ||= {};
    return HTML::Prototype::Helper::Tag->new( $object_name, $method, $self,
        undef, delete $html_options->{object} )
      ->to_input_field_tag( "input", $html_options );
}

=item $prototype->define_javascript_functions

Returns the library of JavaScript functions and objects, in a script block.

Notes for L<Catalyst> users:

You can use C<script/myapp_create.pl Prototype> to generate a static JavaScript
file which then can be included via remote C<script> tag.

=cut

sub define_javascript_functions {
    return shift->javascript_tag("$prototype$controls$dragdrop$effects");
}

=item $prototype->draggable_element( $element_id, \%options )

Makes the element with the DOM ID specified by C<element_id> draggable.

Example:

    $prototype->draggable_element( 'my_image', { revert => 'true' } );

The available options are:

=over 4

=item handle

Default: none. Sets whether the element should only be draggable by an
embedded handle. The value is a string referencing a CSS class. The
first child/grandchild/etc. element found within the element that has
this CSS class will be used as the handle.

=item revert

Default: false. If set to true, the element returns to its original
position when the drags ends.

=item constraint

Default: none. If set to 'horizontal' or 'vertical' the drag will be
constrained to take place only horizontally or vertically.

=item change

Javascript callback function called whenever the Draggable is moved by
dragging. It should be a string whose contents is a valid JavaScript
function definition. The called function gets the Draggable instance
as its parameter. It might look something like this:

    'function (element) { // do something with dragged element }'

=back

See http://script.aculo.us for more documentation.

=cut

sub draggable_element {
    my ( $self, $element_id, $options ) = @_;
    $options ||= {};
    my $js_options = _options_for_javascript($options);
    return $self->javascript_tag("new Draggable( '$element_id', $js_options )");
}

=item $prototype->drop_receiving_element( $element_id, \%options )

Makes the element with the DOM ID specified by C<element_id> receive
dropped draggable elements (created by draggable_element).

And make an AJAX call.

By default, the action called gets the DOM ID of the element as parameter.

Example:
    $prototype->drop_receiving_element(
      'my_cart', { url => 'http://foo.bar/add' } );

Required options are:

=over 4

=item url

The URL for the AJAX call.

=back

Additional options are:

=over 4

=item accept

Default: none. Set accept to a string or an array of
strings describing CSS classes. The Droppable will only accept
Draggables that have one or more of these CSS classes.

=item containment

Default: none. The droppable will only accept the Draggable if the
Draggable is contained in the given elements (or element ids). Can be a
single element or an array of elements. This is option is used by
Sortables to control Drag-and-Drop between Sortables.

=item overlap

Default: none. If set to 'horizontal' or 'vertical' the droppable will
only react to a Draggable if it overlaps by more than 50% in the given
direction. Used by Sortables.

Additionally, the following JavaScript callback functions can be used
in the option parameter:

=item onHover

Javascript function called whenever a Draggable is moved over the
Droppable and the Droppable is affected (would accept it). The
callback gets three parameters: the Draggable, the Droppable element,
and the percentage of overlapping as defined by the overlap
option. Used by Sortables. The function might look something like
this:

    'function (draggable, droppable, pcnt) { // do something }'

=back

See http://script.aculo.us for more documentation.

=cut

sub drop_receiving_element {
    my ( $self, $element_id, $options ) = @_;
    $options ||= {};

    # needs a hoverclass if it is to function!
    # FIXME probably a bug in scriptaculous!
    $options->{hoverclass} ||= 'hoversmocherpocher';
    $options->{with}       ||= "'id=' + encodeURIComponent(element.id)";
    $options->{onDrop}     ||=
      "function(element){" . _remote_function($options) . "}";
    for my $option ( @{$ajax_options} ) {
        delete $options->{$option};
    }
    $options->{accept} = ( "'" . $options->{accept} . "'" )
      if $options->{accept};
    $options->{hoverclass} = ( "'" . $options->{hoverclass} . "'" )
      if $options->{hoverclass};
    my $js_options = _options_for_javascript($options);
    return $self->javascript_tag(
        "Droppables.add( '$element_id', $js_options )");
}

=item $prototype->evaluate_remote_response

Returns 'eval(request.responseText)' which is the Javascript function
that form_remote_tag can call in :complete to evaluate a multiple
update return document using update_element_function calls.

=cut

sub evaluate_remote_response {
    return "eval(request.responseText)";
}

=item $prototype->form_remote_tag(\%options)

Returns a form tag that will submit in the background using XMLHttpRequest,
instead of the regular reloading POST arrangement.

Even though it is using JavaScript to serialize the form elements, the
form submission will work just like a regular submission as viewed by
the receiving side.

The options for specifying the target with C<url> and defining callbacks
are the same as C<link_to_remote>.

=cut

sub form_remote_tag {
    my ( $self, $options ) = @_;
    $options->{form} = 1;
    $options->{html_options} ||= {};
    $options->{html_options}->{action} ||= $options->{url} || '#';
    $options->{html_options}->{method} ||= 'post';
    $options->{html_options}->{onsubmit} =
      _remote_function($options) . '; return false';
    return $self->tag( 'form', $options->{html_options}, 1 );
}

=item $prototype->javascript_tag( $content, \%html_options )

Returns a javascript block with opening tag, content and ending tag.

=cut

sub javascript_tag {
    my ( $self, $content, $html_options ) = @_;
    $html_options ||= {};
    my %html_options =
      ( type => 'text/javascript', %$html_options, entities => '' );

    # my $tag = HTML::Element->new( 'script', %html_options );
    # $tag->push_content("\n<!--\n$content\n//-->\n");
    # return $tag->as_HTML('<>&');

    my $tag_content =
      $self->content_tag( 'script', "\n<!--\n$content\n//-->\n",
        \%html_options );
    return $tag_content;
}

=item $prototype->link_to_function( $name, $function, \%html_options )

Returns a link that will trigger a JavaScript function using the onClick
handler and return false after the fact.

Examples:

    $prototype->link_to_function( "Greeting", "alert('Hello world!') )
    $prototype->link_to_function( '<img src="really.png"/>', 'do_delete()', { entities => '' } )

=cut

sub link_to_function {
    my ( $self, $name, $function, $html_options, $fallback ) = @_;
    $html_options ||= {};
    my %html_options = (
        href    => $fallback,
        onclick => "$function; return false",
        %$html_options
    );
    return $self->content_tag( 'a', $name, \%html_options );
}

=item $prototype->link_to_remote( $content, \%options, \%html_options )

Returns a link to a remote action defined by options C<url> that's
called in the background using XMLHttpRequest.

The result of that request can then be inserted into a DOM object whose
id can be specified with options->{update}.

Examples:

    $prototype->link_to_remote( 'Delete', {
        update => 'posts',
        url    => 'http://localhost/posts/'
    } )

    $prototype->link_to_remote( '<img src="refresh.png"/>', {
        update => 'emails',
        url    => 'http://localhost/refresh/'
    } )

By default, these remote requests are processed asynchronously, during
which various callbacks can be triggered (e.g. for progress indicators
and the like).

Example:

    $prototype->link_to_remote( 'count', {
        url => 'http://localhost/count/',
        complete => 'doStuff(request)'
    } )

The callbacks that may be specified are:

C<loading>: Called when the remote document is being loaded with data
by the browser.

C<loaded>: Called when the browser has finished loading the remote document.

C<interactive>: Called when the user can interact with the remote document,
even though it has not finished loading.

C<complete>: Called when the XMLHttpRequest is complete.

If you do need synchronous processing
(this will block the browser while the request is happening),
you can specify $options->{type} = 'synchronous'.

You can customize further browser side call logic by passing
in Javascript code snippets via some optional parameters. In
their order of use these are:

C<confirm>: Adds confirmation dialog.

C<condition>:  Perform remote request conditionally by this expression.
Use this to describe browser-side conditions when request should not be
initiated.

C<before>: Called before request is initiated.

C<after>: Called immediately after request was initiated and before C<loading>.

=cut

sub link_to_remote {
    my ( $self, $id, $options, $html_options ) = @_;
    $self->link_to_function( $id, _remote_function($options),
        $html_options, $$options{url} );
}

=item $prototype->observe_field( $id, \%options)

Observes the field with the DOM ID specified by $id and makes an
Ajax when its contents have changed.

Required options are:

C<frequency>: The frequency (in seconds) at which changes to this field
will be detected.

C<url>: url to be called when field content has changed.

Additional options are:

C<update>: Specifies the DOM ID of the element whose innerHTML
should be updated with the XMLHttpRequest response text.

C<with>: A JavaScript expression specifying the parameters for the
XMLHttpRequest.
This defaults to value, which in the evaluated context refers to the
new field value.

Additionally, you may specify any of the options documented in
C<link_to_remote>.

Example TT2 template in L<Catalyst>:

    [% c.prototype.define_javascript_functions %]
    <h1>[% page.title %]</h1>
    <div id="view"></div>
    <textarea id="editor" rows="24" cols="80">[% page.body %]</textarea>
    [% url = base _ 'edit/' _ page.title %]
    [% c.prototype.observe_field( 'editor', {
        url    => url,
        with   => "'body='+value",
        update => 'view'
    } ) %]

=cut

sub observe_field {
    my ( $self, $id, $options ) = @_;
    $options ||= {};
    if ( $options->{frequency} ) {
        return $self->_build_observer( 'Form.Element.Observer', $id, $options );
    }
    else {
        return $self->_build_observer( 'Form.Element.EventObserver', $id,
            $options );
    }
}

=item $prototype->observe_form( $id, \%options )

Like C<observe_field>, but operates on an entire form identified by
the DOM ID $id.

Options are the same as C<observe_field>, except the default value of
the C<with> option evaluates to the serialized (request string) value
of the form.

=cut

sub observe_form {
    my ( $self, $id, $options ) = @_;
    $options ||= {};
    if ( $options->{frequency} ) {
        return $self->_build_observer( 'Form.Observer', $id, $options );
    }
    else {
        return $self->_build_observer( 'Form.EventObserver', $id, $options );
    }
}

=item $prototype->periodically_call_remote( \%options )

Periodically calls the specified url $options->{url}  every
$options->{frequency} seconds (default is 10).

Usually used to update a specified div $options->{update} with the
results of the remote call.

The options for specifying the target with C<url> and defining
callbacks is the same as C<link_to_remote>.

=cut

sub periodically_call_remote {
    my ( $self, $options ) = @_;
    my $frequency = $options->{frequency} || 10;
    my $code = _remote_function($options);
    $options->{html_options} ||= { type => 'text/javascript' };
    return $self->javascript_tag( <<"", $options->{html_options} );
new PeriodicalExecuter( function () { $code }, $frequency );

}

=item $prototype->sortable_element( $element_id, \%options )

Makes the element with the DOM ID specified by C<$element_id> sortable
by drag-and-drop and make an Ajax call whenever the sort order has
changed. By default, the action called gets the serialized sortable
element as parameters.

Example:
    $prototype->sortable_element( 'my_list', { url => 'http://foo.bar/baz' } );

In the example, the action gets a "my_list" array parameter
containing the values of the ids of elements the sortable consists
of, in the current order.

You can change the behaviour with various options, see
http://script.aculo.us for more documentation.

=cut

sub sortable_element {
    my ( $self, $element_id, $options ) = @_;
    $options             ||= {};
    $options->{with}     ||= "Sortable.serialize('$element_id')";
    $options->{onUpdate} ||=
      'function () { ' . _remote_function($options) . ' }';
    for my $option ( @{$ajax_options} ) {
        delete $options->{$option};
    }
    my $js_options = _options_for_javascript($options);
    return $self->javascript_tag(
        "Sortable.create( '$element_id', $js_options )");
}

=item $prototype->submit_to_remote( $name, $value, \%options )

Returns a button input tag that will submit a form using XMLHttpRequest
in the background instead of a typical reloading via POST.

C<options> argument is the same as in C<form_remote_tag>

=cut

sub submit_to_remote {
    my ( $self, $name, $value, $options ) = @_;
    $options->{html_options} ||= {};
    $options->{html_options}->{onclick} =
      _remote_function($options) . '; return false';
    $options->{html_options}->{type}  = 'button';
    $options->{html_options}->{name}  = $name;
    $options->{html_options}->{value} = $value;
    return $self->tag( 'input', $options->{html_options} );
}

=item $prototype->tag( $name, \%options, $starttag );

Returns a opening tag.

=cut

sub tag {
    my ( $self, $name, $options, $starttag ) = @_;
    return HTML::Prototype::Helper::Tag->_tag( $name, $options, $starttag );
}

=item $prototype->update_element_function( $element_id, \%options, \&code )

Returns a Javascript function (or expression) that'll update a DOM element
according to the options passed.

C<content>: The content to use for updating.
Can be left out if using block, see example.

C<action>: Valid options are C<update> (assumed by default), :empty, :remove

C<position>: If the :action is :update, you can optionally specify one
of the following positions: :before, :top, :bottom, :after.

Example:
    $prototype->javascript_tag( $prototype->update_element_function(
        'products', { position => 'bottom', content => '<p>New product!</p>'
    ) );

This method can also be used in combination with remote method call
where the result is evaluated afterwards to cause multiple updates
on a page.

Example:
     # View
    $prototype->form_remote_tag( {
        url      => { "http://foo.bar/buy" },
        complete => $prototype->evaluate_remote_response
    } );

    # Returning view
    $prototype->update_element_function( 'cart', {
        action   => 'update',
        position => 'bottom',
        content  => "<p>New Product: $product_name</p>"
    } );
    $prototype->update_element_function( 'status',
        { binding => "You've bought a new product!" } );

=cut

sub update_element_function {
    my ( $self, $element_id, $options, $code ) = @_;
    $options ||= {};
    my $content = $options->{content} || '';
    $content = &$code if $code;
    my $action = $options->{action} || $options->{update};
    my $javascript_function = '';
    if ( $action eq 'update' ) {
        if ( my $position = $options->{position} ) {
            $position            = ucfirst $position;
            $javascript_function =
              "new Insertion.$position( '$element_id', '$content' )";
        }
        else {
            $javascript_function = "\$('$element_id').innerHTML = '$content'";
        }
    }
    elsif ( $action eq 'empty' ) {
        $javascript_function = "\$('#$element_id').innerHTML = ''";
    }
    elsif ( $action eq 'remove' ) {
        $javascript_function = "Element.remove('$element_id')";
    }
    else {
        die "Invalid action, choose one of :update, :remove, :empty";
    }
    $javascript_function .= "\n";
    return $options->{binding}
      ? ( $javascript_function . $options->{binding} )
      : $javascript_function;
}

=item $prototype->visual_effect( $name, $element_id, \%js_options )

Returns a JavaScript snippet to be used on the Ajax callbacks for starting
visual effects.

    $prototype->link_to_remote( 'Reload', {
        update   => 'posts',
        url      => 'http://foo.bar/baz',
        complete => $prototype->visual_effect( 'highlight', 'posts', {
            duration => '0.5'
        } )
    } );

=cut

sub visual_effect {
    my ( $self, $name, $element_id, $js_options ) = @_;
    $js_options ||= {};
    $name = ucfirst $name;
    my $options = _options_for_javascript($js_options);
    return "new Effect.$name( '$element_id', $options )";
}

sub _build_callbacks {
    my $options = shift;
    my %callbacks;
    for my $callback (@$callbacks) {
        if ( my $code = $options->{$callback} ) {
            my $name = 'on' . ucfirst $callback;
            $callbacks{$name} = "function(request){$code}";
        }
    }
    return \%callbacks;
}

sub _build_observer {
    my ( $self, $class, $name, $options ) = @_;
    $options->{with} ||= 'value' if $options->{update};
    my $freq     = $options->{frequency};
    my $callback = _remote_function($options);
    if ($freq) {
        return $self->javascript_tag(
            "new $class( '$name',
                           $freq,
                           function( element, value ) {
                               $callback
                            } );"
        );
    }
    else {
        return $self->javascript_tag(
            "new $class( '$name',
                           function( element, value ) {
                               $callback
                            } );"
        );
    }
}

sub _options_for_ajax {
    my $options    = shift;
    my $js_options = _build_callbacks($options);
    $options->{type} ||= "''";
    $js_options->{asynchronous} = $options->{type} eq 'synchronous' ? 0 : 1;
    $js_options->{method} = $options->{method} if $options->{method};
    $js_options->{evalScripts} = $options->{evalScripts}
      if $options->{evalScripts};
    $js_options->{postBody} = $options->{postBody} if $options->{postBody};
    my $position = $options->{position};
    $js_options->{insertion} = "Insertion.$position" if $position;

    if ( $options->{form} ) {
        $js_options->{parameters} = 'Form.serialize(this)';
    }
    elsif ( $options->{with} ) {
        $js_options->{parameters} = $options->{with};
    }
    return '{ '
      . join( ',', map { "$_: " . $js_options->{$_} } keys %$js_options )
      . ' }';
}

sub _options_for_javascript {
    my $options = shift;
    my @options = ();
    while ( my ( $key, $value ) = each %{$options} ) {
        push @options, "$key:$value";
    }
    return '{ ' . join( ', ', sort(@options) ) . ' }';
}

sub _options_to_js_options {
    my ( $to_options, $options ) = @_;

    $to_options ||= {};
    $options    ||= {};

    my $js_options = {};
    while ( my ( $key, $js_key ) = each %{$to_options} ) {
        if ( $options->{$key} ) {
            if ( ref $js_key eq 'SCALAR' ) {
                $js_options->{ ${$js_key} } = "'" . $options->{$key} . "'";
            }
            else {
                $js_options->{$js_key} = $options->{$key};
            }
        }
    }

    return $js_options;
}

sub _remote_function {
    my $options    = shift;
    my $js_options = _options_for_ajax($options);
    my $update     = $options->{update};
    my $function   =
      $update ? " new Ajax.Updater( '$update', " : ' new Ajax.Request( ';
    my $url = $options->{url} || '';
    $function .= " '$url', $js_options ) ";
    my $before = $options->{before};
    $function = "$before; $function " if $before;
    my $after = $options->{after};
    $function = "$function; $after;" if $after;

    my $condition = $options->{condition};
    my $confirm   = $options->{confirm};
    if ( $condition && $confirm ) {
        $function = "if (($condition) && ($confirm)) { $function; }";
    }
    elsif ($condition) {
        $function = "if ($condition) { $function; }";
    }
    elsif ($confirm) {
        $function = "if ($confirm) { $function; }";
    }

    return $function;
}

sub _array_or_string_for_javascript {
    my $options = shift;
    my $retval;
    if ( ref($options) eq 'ARRAY' ) {
        $retval = "['" . join( "','", @{$options} ) . "']";
    }
    else {
        $retval = "'$options'";
    }
    return $retval;
}

sub _unique {
    my %h = ();
    return grep { !$h{$_}++ } @_;
}

sub _highlight {
    my ( $text, $phrase, $highlighter ) = @_;

    $highlighter ||= '<strong class="highlight">\1</strong>';
    return $text unless $phrase;

    $text =~
s{(\Q$phrase\E)}{my $h = $highlighter; my $r = $1; $h =~ s/\\1/$r/g; $h}gei;

    return $text;
}

=back

=head1 SEE ALSO

L<Catalyst::Plugin::Prototype>, L<Catalyst>.
L<http://prototype.conio.net/>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>
Sebastian Riedel, C<sri@oook.de>
Marcus Ramberg, C<mramberg@cpan.org>

Built around Prototype by Sam Stephenson.
Much code is ported from Ruby on Rails javascript helpers.

=head1 THANK YOU

Drew Taylor, Leon Brocard, Andreas Marienborg

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as perl itself.

=cut

1;
