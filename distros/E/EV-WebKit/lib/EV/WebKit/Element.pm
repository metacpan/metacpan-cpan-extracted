package EV::WebKit::Element;
use v5.10; use strict; use warnings;
use Carp ();
our $VERSION = '0.04';

# $frame is a web-process frame id when this element was found through a frame
# the main-frame script cannot reach; undef is the ordinary main-frame case.
# Every method routes on it (see _call_js), so a handle stays bound to the
# frame it came from.
sub _new {
    my ($class, $browser, $id, $epoch, $frame) = @_;
    bless { b => $browser, id => $id, epoch => $epoch, frame => $frame }, $class;
}

sub frame_id { $_[0]{frame} }

# attr/prop/type bind positionally (my ($s, $n, $cb) = @_), so a caller who omits
# the name leaves the CALLBACK sitting in the name slot -- and since a call with
# no callback is legal here, nothing complains: the coderef is quietly shipped to
# the JSON encoder, the encode dies inside a deferred timer where $EV::DIED only
# warns, and the caller waits forever for a result that is never coming. Croak
# instead, as every other method in this API does for a bad argument.
sub _need_name {
    my ($what, $n) = @_;
    Carp::croak("$what: a name is required") unless defined $n;
    Carp::croak("$what: the name must be a plain string, not a " . ref($n) . ' reference'
              . ($n && ref $n eq 'CODE' ? ' (did you omit the name and pass only a callback?)' : ''))
        if ref $n;
    return;
}

sub _call_js {
    my ($self, $code, $args, $cb) = @_;
    # Same synchronous croak every async EV::WebKit method makes, and for the
    # same reason: a non-coderef callback would only blow up later, deep inside
    # the completion, where the die is swallowed by $EV::DIED -- so the caller's
    # EV::run just hangs, waiting for a callback that can never be invoked.
    # Guarding here covers every method that reaches _call_js at once, rather
    # than once per method. It matters most for find/find_all, which pass their
    # OWN closure down, so the guard below would otherwise never see the
    # caller's callback at all. (An omitted callback stays legal -- _defer no-ops.)
    Carp::croak('callback must be a code reference') if defined $cb && ref $cb ne 'CODE';
    # 'id' and 'epoch' are reserved for this element's registry id/per-
    # document epoch stamp and override any caller key -- epoch lets
    # window.__evwk.get() detect a handle from a page that has since been
    # navigated away from, even if the new page's registry reused the same
    # numeric id (see EV::WebKit's $BOOT script).
    my $a = { %{ $args // {} }, id => $self->{id}, epoch => $self->{epoch} };
    # An element found inside a frame must be operated on IN that frame: its
    # registry entry lives in that frame's world, where the main frame cannot
    # see it -- which is the whole reason the handle carries a frame id.
    return $self->{b}->_call_js_frame($self->{frame}, $code, $a, $cb) if defined $self->{frame};
    $self->{b}->_call_js($code, $a, $cb);
}

sub text  { $_[0]->_call_js('return window.__evwk.get(A.id, A.epoch).textContent;', {}, $_[1]) }
sub html  { $_[0]->_call_js('return window.__evwk.get(A.id, A.epoch).innerHTML;',  {}, $_[1]) }
sub value { $_[0]->_call_js('return window.__evwk.get(A.id, A.epoch).value;',      {}, $_[1]) }
sub tag   { $_[0]->_call_js('return window.__evwk.get(A.id, A.epoch).tagName.toLowerCase();', {}, $_[1]) }
sub attr  { my ($s,$n,$cb)=@_; _need_name(attr => $n); $s->_call_js('return window.__evwk.get(A.id, A.epoch).getAttribute(A.name);', {name=>$n}, $cb) }
sub prop  { my ($s,$n,$cb)=@_; _need_name(prop => $n); $s->_call_js('return window.__evwk.get(A.id, A.epoch)[A.name];',               {name=>$n}, $cb) }

sub is_visible {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch); const s = getComputedStyle(el);'
      . 'return s.display !== "none" && s.visibility !== "hidden" && el.getClientRects().length > 0;',
        {}, $_[1]);
}

sub find {
    my ($s, $sel, $cb) = @_;
    # These two pass their OWN closure to _call_js, so its callback guard sees a
    # coderef either way and cannot check the caller's -- guard here too, or a
    # non-coderef $cb dies inside the completion below, where $EV::DIED eats it
    # and the caller's EV::run hangs forever.
    Carp::croak('find: last argument must be a callback') if ref $cb ne 'CODE';
    # The same guard the browser's own find() has. Without it a JSON null (or an
    # omitted selector) marshalled through to querySelector, which coerces it to
    # the TYPE selector "null" -- so find(undef) answered "not found" instead of
    # complaining, indistinguishable from a selector that simply did not match.
    # Reachable over the control socket too: el.find with a:[null] is one
    # argument, so the arity guard passes it.
    EV::WebKit::_need_selector(find => $sel);
    # This wrapper closure is captured strongly by the (permanently
    # GI-retained) _call_js completion closure -- but UNLIKE _call_js/
    # EV::WebKit::find's own $self (the browser, always independently held
    # by the caller's own long-lived variable in practice), $s (an Element)
    # is frequently held ONLY via this closure's own capture -- e.g. several
    # sibling calls issued off the same $el, where none of the sibling
    # closures happen to mention $el by name, so nothing else keeps it
    # reachable during the async gap (confirmed: weakening $s here, mirroring
    # the find()/wait_for() fix, broke exactly that pattern -- t/41's 9
    # concurrent $d->... calls). So $s must stay STRONGLY captured while the
    # call is in flight; instead, break the retention at a single resolution
    # point, explicitly undef'ing our OWN copy the instant we're done needing
    # it (same "single resolution point" shape as wait_for's $finish) -- this
    # releases $s (and transitively $s->{b}, the browser) from THIS closure
    # without affecting any sibling closure's own (still-strong) copy.
    $s->_call_js('const el = window.__evwk.get(A.id, A.epoch).querySelector(A.sel); return el ? { evwk_id: window.__evwk.put(el), evwk_epoch: window.__evwk.epoch } : null;',
        { sel => $sel },
        sub {
            my ($r, $err) = @_;
            # A hostile/buggy page can make ANY JS value come back here (e.g.
            # Object.prototype.toJSON polluted to return something else
            # entirely) -- never trust the decoded shape before dereferencing
            # it: an unvalidated $r->{evwk_id} below would die inside
            # _defer's bare EV::timer(0,0,...), which EV's default $EV::DIED
            # swallows to stderr, permanently dropping this callback (a
            # silent hang, not an error) instead of ever reaching the caller.
            if (!$err && defined $r && !(ref $r eq 'HASH' && defined $r->{evwk_id})) {
                $err = 'find: unexpected result from page (registry tampered?)';
            }
            my $result = (!$err && defined $r) ? EV::WebKit::Element->_new($s->{b}, $r->{evwk_id}, $r->{evwk_epoch}, $s->{frame}) : undef;
            undef $s;
            $cb->($result, $err);
        });
}

sub find_all {
    my ($s, $sel, $cb) = @_;
    Carp::croak('find_all: last argument must be a callback') if ref $cb ne 'CODE';
    EV::WebKit::_need_selector(find_all => $sel);
    # same reasoning as find() above.
    $s->_call_js('return [...window.__evwk.get(A.id, A.epoch).querySelectorAll(A.sel)].map(e => ({ evwk_id: window.__evwk.put(e), evwk_epoch: window.__evwk.epoch }));',
        { sel => $sel },
        sub {
            my ($r, $err) = @_;
            # same shape distrust as find() above -- a tampered result (e.g.
            # the whole array replaced, or containing non-descriptor
            # elements) must degrade to a clean error, never dereference
            # blind and die inside _defer's unguarded timer.
            if (!$err && !(ref $r eq 'ARRAY' && !grep { ref $_ ne 'HASH' || !defined $_->{evwk_id} } @$r)) {
                $err = 'find_all: unexpected result from page (registry tampered?)';
            }
            my $result = $err ? undef : [ map { EV::WebKit::Element->_new($s->{b}, $_->{evwk_id}, $_->{evwk_epoch}, $s->{frame}) } @$r ];
            undef $s;
            $cb->($result, $err);
        });
}

# A bare el.click() dispatches ONLY a click event, so a control whose handler is
# on mousedown/pointerdown -- custom dropdowns, menus, sliders, most
# design-system widgets -- did not respond at all, and this still reported
# success. Press first, then click, using hover's dictionary so the two agree
# about pointerType/isPrimary. Skipped for a disabled control, because no engine
# dispatches mouse events to one and firing them here would let a test drive
# something a person could not.
sub click {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'const r = el.getBoundingClientRect();'
      . 'const at = { bubbles:true, cancelable:true, composed:true, view:window,'
      . '             pointerType:"mouse", pointerId:1, isPrimary:true, button:0,'
      . '             clientX: r.left + r.width/2, clientY: r.top + r.height/2 };'
      . 'const off = el.disabled === true'
      . '         || !!(el.closest && el.closest("fieldset[disabled]") && !el.closest("legend"));'
      . 'if (!off) {'
      . '  const P = window.PointerEvent || MouseEvent;'
      . '  el.dispatchEvent(new P("pointerdown", {...at, buttons:1}));'
      . '  el.dispatchEvent(new MouseEvent("mousedown", {...at, buttons:1}));'
      . '  el.dispatchEvent(new P("pointerup",   {...at, buttons:0}));'
      . '  el.dispatchEvent(new MouseEvent("mouseup",   {...at, buttons:0}));'
      . '}'
      # click() last, and unconditionally: it is what activates a link or submits
      # a form, and on a disabled control the engine makes it the no-op it should be.
      . 'el.click();'
      . 'return true;',
        {}, $_[1]);
}

sub focus { $_[0]->_call_js('window.__evwk.get(A.id, A.epoch).focus(); return true;', {}, $_[1]) }

sub type {
    my ($s, $text, $cb) = @_;
    _need_name(type => $text);   # same positional-binding trap as attr/prop -- see there
    $s->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch); const tag = el.tagName;'
      . 'if (tag === "INPUT" || tag === "TEXTAREA") {'
      . '  el.focus(); el.value = (el.value || "") + A.text;'
      . '  el.dispatchEvent(new Event("input",  {bubbles:true}));'
      . '  el.dispatchEvent(new Event("change", {bubbles:true}));'
      . '} else if (el.isContentEditable) {'
      . '  el.focus(); el.textContent = (el.textContent || "") + A.text;'
      . '  el.dispatchEvent(new InputEvent("input", {bubbles:true}));'
      . '} else { throw new Error("element is not editable"); }'
      . 'return true;',
        { text => $text }, $cb);
}
*send_keys = \&type;

sub clear {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch); const tag = el.tagName;'
      . 'if (tag === "INPUT" || tag === "TEXTAREA") {'
      . '  el.value = "";'
      . '  el.dispatchEvent(new Event("input", {bubbles:true}));'
      . '} else if (el.isContentEditable) {'
      . '  el.textContent = "";'
      . '  el.dispatchEvent(new InputEvent("input", {bubbles:true}));'
      . '} else { throw new Error("element is not editable"); }'
      . 'return true;',
        {}, $_[1]);
}

sub submit {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch); const f = el.form || el;'
      . 'if (f instanceof HTMLFormElement) HTMLFormElement.prototype.submit.call(f);'
      . 'return true;',
        {}, $_[1]);
}

# Bring the element into the viewport. Not merely a convenience: click() on an
# off-screen element works in the DOM but a page that reacts to scroll position
# (lazy images, sticky headers, infinite scroll) will not have done its work
# yet, so a subsequent read sees the pre-scroll state.
#
# behavior:"instant" is load-bearing: under a page's own CSS
# `scroll-behavior: smooth` the scroll ANIMATES, and this would resolve with the
# viewport still travelling -- so the reads it exists to make correct happen at
# the wrong offset.
sub scroll_into_view {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'el.scrollIntoView({block:"center", inline:"center", behavior:"instant"});'
      . 'return true;',
        {}, $_[1]);
}

# Hover. A real pointer entering an element produces pointerover/mouseover (which
# bubble) AND pointerenter/mouseenter (which do NOT), then a move; menus and
# tooltips variously listen for any of them, so sending only mouseover leaves a
# menu that opens on mouseenter shut. isTrusted is false for all of these -- a
# page checking it is not fooled (documented in the Ceiling).
sub hover {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'const r = el.getBoundingClientRect();'
      # A PointerEvent built without these reports pointerType "" and isPrimary
      # false, so a menu branching on the device takes the wrong branch -- which
      # is the class of menu this method exists to open. MouseEventInit has no
      # such members and WebIDL ignores unknown ones, so one dictionary serves
      # both constructors.
      . 'const at = { bubbles:true, cancelable:true, view:window,'
      . '             pointerType:"mouse", pointerId:1, isPrimary:true,'
      . '             clientX: r.left + r.width/2, clientY: r.top + r.height/2 };'
      . 'for (const t of ["pointerover","mouseover"]) {'
      . '  el.dispatchEvent(new (window.PointerEvent && t[0] === "p" ? PointerEvent : MouseEvent)(t, at)); }'
      . 'for (const t of ["pointerenter","mouseenter"]) {'
      . '  el.dispatchEvent(new (window.PointerEvent && t[0] === "p" ? PointerEvent : MouseEvent)(t, {...at, bubbles:false})); }'
      . 'el.dispatchEvent(new MouseEvent("mousemove", at));'
      . 'return true;',
        {}, $_[1]);
}

# Select an <option> by value, or by visible label when no value matches. Setting
# el.value alone is not enough: every framework binds to input/change, so a
# silent assignment updates the DOM and leaves the application state stale.
sub select_option {
    my ($s, $value, $cb) = @_;
    _need_name(select_option => $value);   # same positional-binding trap as attr/prop
    # Stringify before the JSON bridge: an option's value is always a string in
    # the DOM and the match below is ===, so an integer crossed as a JSON number
    # and select_option(5) failed to find <option value="5">.
    $value = "$value";
    $s->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'if (!(el instanceof HTMLSelectElement)) throw new Error("element is not a <select>");'
      . 'const opts = [...el.options];'
      . 'let i = opts.findIndex(o => o.value === A.value);'
      . 'if (i < 0) i = opts.findIndex(o => (o.label || o.textContent || "").trim() === A.value);'
      . 'if (i < 0) throw new Error("no option with value or label " + JSON.stringify(A.value));'
      . 'el.selectedIndex = i;'
      . 'el.dispatchEvent(new Event("input",  {bubbles:true}));'
      . 'el.dispatchEvent(new Event("change", {bubbles:true}));'
      . 'return opts[i].value;',
        { value => $value }, $cb);
}

# Set a checkbox/radio to $on (default true). click() would TOGGLE, so calling it
# twice to "make sure" silently undoes itself; this is idempotent by construction
# and a no-op (no events) when the box is already in the requested state, which is
# also what a real user clicking an already-checked radio produces.
sub check {
    my ($s, @arg) = @_;
    my $cb  = (@arg && ref $arg[-1] eq 'CODE') ? pop @arg : undef;
    # Two leftover arguments means a mistyped callback in the state position
    # followed by the real one. A SINGLE leftover is the state, whatever it is:
    # decoded-JSON booleans are blessed scalar refs, and croaking on those would
    # reject the most ordinary source of a boolean this API has.
    Carp::croak('check: takes at most a state and a callback') if @arg > 1;
    my $on  = @arg ? ($arg[0] ? 1 : 0) : 1;
    $s->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'if (!(el instanceof HTMLInputElement) || !/^(checkbox|radio)$/.test(el.type))'
      . '  throw new Error("element is not a checkbox or radio");'
      . 'if (el.checked === !!A.on) return !!A.on;'
      . 'el.checked = !!A.on;'
      . 'el.dispatchEvent(new Event("input",  {bubbles:true}));'
      . 'el.dispatchEvent(new Event("change", {bubbles:true}));'
      . 'return !!A.on;',
        { on => $on }, $cb);
}
sub uncheck {
    my ($s, $cb) = @_;
    Carp::croak('uncheck: callback must be a code reference') if defined $cb && ref $cb ne 'CODE';
    $s->check(0, $cb ? ($cb) : ());
}

# Geometry, as a hashref: x/y/width/height/top/left/bottom/right plus the
# page-relative page_x/page_y. Viewport-relative like getBoundingClientRect
# itself, which is what a caller comparing against a screenshot wants; page_x/y
# add the scroll offset for anyone who needs absolute document coordinates.
#
# An element that is not rendered at all (display:none, or detached) has a rect
# of all zeros in every browser. Reporting that as a box would be a lie a caller
# could easily divide by, so it comes back undef instead, with is_visible left as
# the way to ask the question directly.
sub box {
    $_[0]->_call_js(
        'const el = window.__evwk.get(A.id, A.epoch);'
      . 'const r = el.getBoundingClientRect();'
      . 'if (!r.width && !r.height && !r.x && !r.y) return null;'
      . 'return { x: r.x, y: r.y, width: r.width, height: r.height,'
      . '         top: r.top, left: r.left, bottom: r.bottom, right: r.right,'
      . '         page_x: r.x + window.scrollX, page_y: r.y + window.scrollY };',
        {}, $_[1]);
}

1;

=pod

=head1 NAME

EV::WebKit::Element - a handle to a DOM element found by EV::WebKit

=head1 SYNOPSIS

    $b->find('#login', sub {
        my ($el, $err) = @_;
        # A die inside an EV callback only reaches $EV::DIED, which warns and
        # keeps going -- break instead.
        if ($err) { warn "find failed: $err\n";      return EV::break }
        if (!$el) { warn "no #login on this page\n"; return EV::break }

        $el->type('alice', sub {
            my (undef, $err) = @_;
            if ($err) { warn "type failed: $err\n"; return EV::break }
            $el->submit(sub {
                my (undef, $err) = @_;
                warn "submit failed: $err\n" if $err;
                EV::break;
            });
        });
    });

=head1 DESCRIPTION

An EV::WebKit::Element is a handle to a single DOM node discovered via
L<EV::WebKit>'s C<find>, C<find_all>, C<find_js>, C<find_all_js> or
C<wait_for>, or (scoped to that element's descendants) its own C<find>/
C<find_all> below. Internally it is just a
small page-side registry id, the per-document epoch stamp of the registry
it was created from, and a back-reference to the owning L<EV::WebKit>
browser -- not a live DOM reference held on the Perl side. Every method
runs JavaScript against that node asynchronously, on the same L<EV> loop as
the browser, and follows the browser's own callback convention: a trailing
C<sub { my ($result, $err) = @_; ... }>, C<$err> undef on success. See
L<EV::WebKit/"CALLBACK CONVENTION">.

Instances are only ever returned by L<EV::WebKit> methods; there is no
public constructor.

If the underlying DOM node has since been removed from the document, any
method call on that handle fails with a script error whose message
mentions "stale element". The same happens if navigation has replaced the
page entirely, even though the new page's own registry happens to reuse
the same numeric id the old handle had: each navigation re-injects a fresh
registry with a new epoch stamp, every handle carries the epoch it was
created with, and a mismatch is treated exactly like a removed node.
C<id> and C<epoch> are reserved argument names, always set by this class
internally, for every JavaScript snippet run through these methods.

A handle found through the C<< frame => { url => ... } >> form remembers B<which
frame> it came from, and every call on it runs there -- see
L<EV::WebKit/"Addressing an iframe">. A handle found through the selector form
(C<< frame => '#f' >>) does not: main-frame script walked C<contentDocument> to
reach it, and every call is made the same way.

Neither outlives its frame, but they say so differently: once the frame is
removed or the page navigates away, the first kind fails with C<frame is gone>
and the second with the ordinary C<stale element>.

=head1 METHODS

All methods below take a trailing C<sub { my ($result, $err) = @_; ... }>
callback.

=head2 text

    $el->text($cb);

C<$result> is the node's C<textContent>.

=head2 html

    $el->html($cb);

C<$result> is the node's C<innerHTML>.

=head2 value

    $el->value($cb);

C<$result> is the form control's current C<value>.

=head2 tag

    $el->tag($cb);

C<$result> is the node's lower-cased tag name, e.g. C<"div">.

=head2 attr

    $el->attr($name, $cb);

C<$result> is the HTML attribute C<$name> (via C<getAttribute>), or
C<undef> if the attribute is not present.

=head2 prop

    $el->prop($name, $cb);

C<$result> is the live JavaScript/DOM property C<$name> (e.g.
C<< prop('checked') >>), as opposed to C<attr>'s raw HTML attribute --
useful when the two differ (checkbox C<checked> state, current vs default
C<value>, and so on).

=head2 is_visible

    $el->is_visible($cb);

C<$result> is true if the element's computed C<display> is not C<none>,
its computed C<visibility> is not C<hidden>, and it has at least one client
rect (roughly: it takes up visible space in the rendered page).

=head2 find

    $el->find($selector, $cb);

Scoped C<querySelector> under this element. C<$result> is an
L<EV::WebKit::Element> on a match, or C<undef> if nothing matched --
not-found is not an error.

=head2 find_all

    $el->find_all($selector, $cb);

Scoped C<querySelectorAll> under this element. C<$result> is a (possibly
empty) arrayref of L<EV::WebKit::Element>.

=head2 click

    $el->click($cb);

Presses the element the way a pointer does: C<pointerdown>, C<mousedown>,
C<pointerup>, C<mouseup>, then the node's own C<click()>. The press matters --
plenty of controls (custom dropdowns, menus, sliders) act on C<mousedown> and
never see a bare C<click()> at all. A B<disabled> control gets the C<click()>
only, with no synthetic press, because no engine dispatches mouse events to one
and firing them here would drive something a person could not.

Visibility is not checked: an off-screen or C<display:none> element is clicked
as asked, and reports success. Ask L</is_visible> first if that matters, and
L</scroll_into_view> if the page reacts to scroll position.

=head2 type

    $el->type($text, $cb);

On an C<< <input> >> or C<< <textarea> >>, appends C<$text> to the
element's current C<value> and dispatches C<input> and C<change> events.
On a contenteditable element (C<isContentEditable>), appends C<$text> to
its C<textContent> instead (there is no native C<value> to set) and
dispatches an C<input> event. Either way this sets the content directly and
fires the event(s) once -- it does not simulate individual keydown/keyup
events per character. On anything else (not a form control, not
contenteditable), C<$err> is set to an error mentioning "not editable"
rather than silently doing nothing.

=head2 send_keys

An alias for C<type> above (identical behavior, including the "not really
per-key" caveat and the contenteditable/not-editable handling).

=head2 clear

    $el->clear($cb);

On an C<< <input> >> or C<< <textarea> >>, empties C<value> and dispatches
an C<input> event. On a contenteditable element, empties C<textContent>
instead and dispatches an C<input> event. On anything else, C<$err> is set
to an error mentioning "not editable".

=head2 focus

    $el->focus($cb);

Calls the node's C<focus()>.

=head2 submit

    $el->submit($cb);

Calls the native C<submit()> of the element's owning C<< <form> >>, or of
the element itself if it has no C<form> (e.g. calling C<submit> directly on
a C<< <form> >> element). This bypasses any C<onsubmit> handler and may
navigate the page. Resolves successfully even if there was nothing to
submit (a silent no-op).

=head2 select_option

    $el->select_option($value, $cb);   # $cb->($selected_value, $err)

Selects an C<< <option> >> of a C<< <select> >> by its C<value>, falling back
to matching the visible label when no value matches -- so an option whose
C<value> differs from what the page displays, such as
C<< <option value="b">Beta</option> >>, is still reachable by the text the
user sees. (An option with no C<value> attribute at all takes its value from
its own text, so it already matches on the first pass.) Fires C<input> and C<change> so page code bound to
those actually runs; assigning C<el.value> alone updates the DOM and leaves
application state stale. Errors if the element is not a C<< <select> >>, or if
no option matches.

=head2 check / uncheck

    $el->check($cb);          # ensure checked
    $el->check(0, $cb);       # ensure UNchecked
    $el->uncheck($cb);        # the same thing, spelled out

Sets a checkbox or radio to a definite state and resolves with that state.
Deliberately not C<click>: clicking B<toggles>, so calling it twice "to be
sure" silently undoes itself. These are idempotent -- already in the requested
state means no change and, like a real browser, B<no> C<change> event. Errors
if the element is not a checkbox or radio.

The single-argument form is read as a B<callback> if it is a code reference and
as the B<state> otherwise -- evaluated for truth, so a decoded-JSON boolean
works as well as a plain C<1> or C<0>. C<uncheck> has no state argument, so a
non-coderef there is a mistyped callback and croaks.

=head2 hover

    $el->hover($cb);

Dispatches the pointer/mouse sequence an entering cursor produces:
C<pointerover>/C<mouseover> (which bubble), then C<pointerenter>/C<mouseenter>
(which do not), then C<mousemove>, positioned at the element's centre. Menus
and tooltips listen for various of these, so dispatching only C<mouseover>
leaves a menu that opens on C<mouseenter> shut. These are synthetic events:
C<isTrusted> is false, so a page that checks it is not fooled.

=head2 box

    $el->box($cb);   # $cb->($box, $err)

The element's geometry as a hashref: C<x>, C<y>, C<width>, C<height>, C<top>,
C<left>, C<bottom>, C<right> -- viewport-relative, exactly as
C<getBoundingClientRect> gives them, which is what you want when comparing
against a screenshot -- plus C<page_x> and C<page_y>, the same origin with the
scroll offset added, for absolute document coordinates.

C<$box> is C<undef> for an element that is not rendered (C<display:none>, or
detached from the document). Such an element has an all-zero rect in every
browser, and returning that as a box would be a plausible-looking lie a caller
could divide by; ask L</is_visible> if that is the question.

For an element inside a frame the rect is relative to B<that frame's> viewport,
not the top-level one, since that is the only coordinate space the element's
own document has. Offsetting it into page coordinates would need the frame's
position, which is the parent document's to know.

=head2 frame_id

    my $id = $el->frame_id;

The id of the frame this handle is B<bound> to, or C<undef> if it is not bound
to one. Synchronous; the id itself is opaque and lives only as long as the frame
does.

Note what C<undef> does B<not> mean. Only the C<< frame => { url => ... } >>
form binds a handle to a frame; a handle reached through the selector form
(C<< frame => '#f' >>) is inside an iframe but reports C<undef>, exactly as a
main-frame handle does. So this tells you how the handle will be operated on,
not where the element lives -- it is not a test for "is this inside an iframe".
See L<EV::WebKit/"Addressing an iframe">.

=head2 scroll_into_view

    $el->scroll_into_view($cb);

Scrolls the element to the centre of the viewport. Worth doing before reading
around it: C<click> works on an off-screen element, but a page that reacts to
scroll position (lazy images, infinite scroll, sticky headers) will not have
done that work yet.

=head1 SEE ALSO

L<EV::WebKit>

=head1 AUTHOR

vividsnow

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
