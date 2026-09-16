use v5.10; use strict; use warnings;
use Test::More;
use lib 't/lib'; use TWK; TWK::skip_unless_available();
use EV; use EV::WebKit;

# press / scroll (page level) and Element->box.
#
# One instance, one EV::run, queued steps (t/42's constraint).

my $b = EV::WebKit->new(window => [400, 300], timeout => 15);
my %g;
my @steps;
my $run; $run = sub { my $s = shift @steps or return EV::break; $s->() };

my $fixture = <<'HTML';
<style>
  body { margin: 0 }
  #tall { height: 3000px }
  #boxy { position: absolute; left: 40px; top: 60px; width: 120px; height: 30px }
  #hidden { display: none }
</style>
<input id=field>
<div id=boxy>box</div>
<div id=hidden>invisible</div>
<div id=tall></div>
<script>
  window.keys = [];
  window.codes = [];
  document.addEventListener('keydown', e => window.codes.push(e.key + '=' + e.code));
  // a KeyboardEvent is a UIEvent and a real one carries the window. These are
  // built in the isolated world, so this also pins that WebKit maps `view`
  // across to the PAGE's window rather than leaking the other realm's.
  window.viewok = null;
  document.addEventListener('keydown', e => window.viewok = (e.view === window));
  document.addEventListener('keydown', e => window.keys.push(
      [e.key, e.keyCode, e.shiftKey ? 1 : 0, e.ctrlKey ? 1 : 0].join(':')));
  document.addEventListener('keypress', e => window.keys.push('press:' + e.key));
  // a handler that cancels, to prove press() reports cancellation
  document.getElementById('field').addEventListener('keydown', e => {
      if (e.key === 'x') e.preventDefault();
  });
</script>
HTML

# --- press: named key, with modifiers ---
push @steps, sub {
    $b->press('Escape', sub { ($g{esc}, $g{esc_err}) = @_; $run->() });
};
push @steps, sub {
    $b->press('Enter', shift => 1, ctrl => 1, sub { ($g{enter}) = @_; $run->() });
};
# a single character produces keypress as well as keydown/keyup
push @steps, sub {
    $b->press('a', sub { ($g{a}) = @_; $run->() });
};
push @steps, sub {
    $b->script('return JSON.stringify(window.keys)', sub { $g{keys} = $_[0]; $run->() });
};
push @steps, sub {
    $b->script('return String(window.viewok)', sub { $g{viewok} = $_[0]; $run->() });
};
# press does NOT type: the input's value stays empty
push @steps, sub {
    # preventScroll here too -- see the Tab step below for what a stray
    # focus-induced scroll does to the assertions further down
    $b->script('document.getElementById("field").focus({preventScroll:true}); return 1;', sub {
        $b->press('z', sub {
            $b->script('return document.getElementById("field").value', sub {
                $g{typed} = $_[0]; $run->();
            });
        });
    });
};
# a cancelling handler makes press report false
push @steps, sub {
    $b->press('x', sub { ($g{cancelled}) = @_; $run->() });
};
# ...and window.keys must be re-read AFTER that press: the earlier snapshot was
# taken before it, so asserting against that one could never have seen it
push @steps, sub {
    $b->script('return JSON.stringify(window.keys)', sub { $g{keys_after} = $_[0]; $run->() });
};
# event.code: the PHYSICAL key. Not derivable from the character except for
# letters -- deriving it as "Key" + character produced "Key ", "Key5", "Key-",
# so `e.code === "Space"` (the ordinary spelling in shortcut handlers) never
# matched for a key this module lists as supported.
# ...and a key given as a NUMBER must behave exactly like the same key given as
# a string. Unstringified, it crossed the JSON bridge as a number, so A.key.length
# was undefined and press(5) sent no keypress while press('5') did -- the same
# call producing a different event stream depending on how Perl stored the scalar.
push @steps, sub {
    $b->script('window.numev = [];'
             . 'document.addEventListener("keypress", e => window.numev.push("press:" + e.key));'
             . 'return 1', sub {
        $b->press(5, sub {
            $b->script('return JSON.stringify(window.numev)', sub { $g{numkey} = $_[0]; $run->() });
        });
    });
};
# keyCode for punctuation. Taking the character's ordinal did not merely give a
# wrong number, it gave one that IMPERSONATES another key: ord('.') is 46, which
# is Delete; ord("'") is 39, ArrowRight; ord('%') is 37, ArrowLeft. So press('.')
# fired a page's Delete handler, and every alias was a key this module's own
# table lists as supported. The legacy US-layout OEM codes are what a browser
# really sends.
push @steps, sub {
    $b->script('window.kc = {};'
             . 'document.addEventListener("keydown", e => window.kc[e.key] = e.keyCode);'
             . 'return 1', sub {
        my @seq = ('.', "'", '%', ',', ';', '/', '-', 'a', '7');
        my $next; $next = sub {
            my $k = shift @seq
                or return $b->script('return JSON.stringify(window.kc)',
                                     sub { $g{kc} = $_[0]; $run->() });
            $b->press($k, sub { $next->() });
        };
        $next->();
    });
};
push @steps, sub {
    my @seq = (' ', '5', ',', 'q', 'Enter', 'ArrowUp');
    my $next; $next = sub {
        my $k = shift @seq or return $b->script('return JSON.stringify(window.codes)',
                                                sub { $g{codes} = $_[0]; $run->() });
        $b->press($k, sub { $next->() });
    };
    $next->();
};

# Enter fires keypress in every engine (it produces "\r", charCode 13), so the
# canonical legacy form handler -- onkeypress checking keyCode 13 -- must see
# it. Gating keypress on a one-character key alone left Enter out, breaking the
# very case press() advertises: "Enter submitting a form that listens for it".
push @steps, sub {
    $b->script('window.submitted = 0;'
             . 'document.addEventListener("keypress", e => { if ((e.keyCode||e.which) === 13) window.submitted = 1 });'
             . 'return 1', sub {
        $b->press('Enter', sub {
            $b->script('return String(window.submitted)', sub { $g{enter_press} = $_[0]; $run->() });
        });
    });
};

# keyup goes where focus is NOW. A keydown handler that moves focus is ordinary
# (Tab and Enter handlers do it), and a real browser delivers keyup to the newly
# focused element; sending it to the blurred one meant that element's keyup
# handler never ran.
push @steps, sub {
    # preventScroll on BOTH focus calls. Focusing an element scrolls it into
    # view, and that scroll is not necessarily done when the call returns -- so
    # under load it landed after the scroll assertions below had already read
    # their position back, and moved the page out from under them. (Two of them
    # failed that way in a parallel suite run while passing every time in
    # isolation.) The test is about where keyup is delivered, not about
    # scrolling, so suppress it.
    $b->script('document.body.insertAdjacentHTML("beforeend", "<input id=one><input id=two>");'
             . 'window.up = "none";'
             . 'one.addEventListener("keydown", e => { if (e.key === "Tab") { e.preventDefault(); two.focus({preventScroll:true}) } });'
             . 'one.addEventListener("keyup", () => window.up = "one");'
             . 'two.addEventListener("keyup", () => window.up = "two");'
             . 'one.focus({preventScroll:true}); return 1', sub {
        $b->press('Tab', sub {
            $b->script('return window.up', sub { $g{keyup_target} = $_[0]; $run->() });
        });
    });
};

# --- scroll ---
# The steps above leave #two, at the bottom of the page, focused, and under load
# WebKit can still be revealing it when these start; it landed after scroll(y =>
# 500) once and moved the page to its end. Blur it and wait for scrollY to hold.
push @steps, sub {
    $b->script('document.activeElement && document.activeElement.blur();'
             . 'let last = -1, still = 0;'
             . 'for (let i = 0; i < 150 && still < 5; i++) {'
             . '  await new Promise(r => setTimeout(r, 20));'
             . '  if (window.scrollY === last) still++; else { still = 0; last = window.scrollY }'
             . '} return 1', sub { $run->() });
};
push @steps, sub {
    $b->scroll(y => 500, cb => sub { ($g{abs}) = @_; $run->() });
};
push @steps, sub {
    $b->scroll(by => 1, y => 100, cb => sub { ($g{rel}) = @_; $run->() });
};
# A relative offset given as a STRING must ADD, not concatenate. Un-numified it
# crossed the bridge as a JSON string, and `x += A.x` in JS is then string
# concatenation: from scrollY 100, scroll(by => 1, y => '50') computed
# "100" + "50" and scrolled to 10050. Invisible from the origin, where
# "0" + "50" is right by accident -- so it only shows up on the second relative
# scroll, and an offset out of a config file or @ARGV is a string.
push @steps, sub {
    $b->scroll(by => 1, y => '50', cb => sub { ($g{relstr}) = @_; $run->() });
};
push @steps, sub {
    $b->scroll(to => 'bottom', cb => sub { ($g{bottom}) = @_; $run->() });
};
push @steps, sub {
    $b->scroll(to => 'top', cb => sub { ($g{top}) = @_; $run->() });
};

# --- Element->box ---
push @steps, sub {
    $b->find('#boxy', sub {
        my ($el) = @_;
        $el->box(sub { ($g{box}, $g{box_err}) = @_; $run->() });
    });
};
push @steps, sub {
    $b->find('#hidden', sub {
        my ($el) = @_;
        # $g{hidden_called} exists because this is the LAST step in the queue, so
        # the chain-stall anchor every other assertion here relies on does not
        # apply: if box() never called back, $g{hidden_box} would be undef simply
        # because nothing assigned it -- which is exactly what the assertion
        # compares against, and the test could not fail.
        $el->box(sub { ($g{hidden_box}, $g{hidden_err}) = @_; $g{hidden_called} = 1; $run->() });
    });
};

$b->load_html($fixture, sub { $run->() });
TWK::run_with_timeout(40);

# --- press ---
ok($g{esc},      'press(Escape) reports not-cancelled');
is($g{esc_err}, undef, 'press: no error');
require Cpanel::JSON::XS;
my $keys = eval { Cpanel::JSON::XS::decode_json($g{keys} // '[]') } || [];
ok((grep { $_ eq 'Escape:27:0:0' } @$keys), 'the page saw Escape with keyCode 27');
ok((grep { $_ eq 'Enter:13:1:1' } @$keys),  'modifiers reach the page (shift+ctrl+Enter)');
ok((grep { $_ eq 'press:a' } @$keys),       'a character key also produces keypress');
ok(!(grep { $_ eq 'press:Escape' } @$keys), '...and a named key does NOT (as in a real browser)');
is($g{viewok}, 'true', 'the event carries the PAGE window as e.view, as a real UIEvent does');

# The honest limitation, pinned so the POD cannot drift from it: a synthetic
# key event does not perform text insertion in any engine.
is($g{typed}, '', 'press does NOT type into an input (use Element->type)');
ok(!$g{cancelled}, 'press reports false when a handler calls preventDefault');
# ...and no keypress is sent for it. A real browser skips keypress entirely when
# keydown was cancelled; sending it anyway would let a form submit on a key the
# page had just refused.
my $keys_after = eval { Cpanel::JSON::XS::decode_json($g{keys_after} // '[]') } || [];
ok((grep { /^x:/ } @$keys_after), 'precondition: the cancelled press really reached the page')
    or diag('the snapshot does not contain the x keydown at all');
ok(!(grep { $_ eq 'press:x' } @$keys_after),
   '...and sends NO keypress for a cancelled keydown');

# --- event.code ---
my $codes = eval { Cpanel::JSON::XS::decode_json($g{codes} // '[]') } || [];
my %code = map { my ($k, $c) = split /=/, $_, 2; ($k => $c) } @$codes;
is($code{' '},      'Space',    'press(" ") reports code Space, not "Key "');
is($code{'5'},      'Digit5',   'press("5") reports code Digit5, not "Key5"');
is($code{','},      'Comma',    'press(",") reports code Comma, not "Key,"');
is($code{'q'},      'KeyQ',     'a letter still reports KeyQ');
is($code{'Enter'},  'Enter',    'a named key is already its own code');
is($code{'ArrowUp'},'ArrowUp',  '...including the arrows');
is($g{numkey}, '["press:5"]', 'press(5) behaves as press("5") -- a number still produces keypress');

# --- keyCode ---
my $kc = eval { Cpanel::JSON::XS::decode_json($g{kc} // '{}') } || {};
is($kc->{'.'},  190, "press('.') sends keyCode 190, NOT 46 (which is Delete)");
is($kc->{"'"},  222, "press(\"'\") sends keyCode 222, NOT 39 (which is ArrowRight)");
is($kc->{','},  188, "press(',') sends keyCode 188");
is($kc->{';'},  186, "press(';') sends keyCode 186");
is($kc->{'/'},  191, "press('/') sends keyCode 191");
is($kc->{'-'},  189, "press('-') sends keyCode 189");
# a shifted character names no physical key by itself, so report the pair a
# browser uses for one it cannot identify rather than inventing an alias
is($kc->{'%'},  0,   "press('%') sends keyCode 0, NOT 37 (which is ArrowLeft)");
is($kc->{'a'},  65,  'a letter still sends its uppercase ordinal');
is($kc->{'7'},  55,  'a digit still sends its ordinal');
is($g{enter_press}, '1', 'press("Enter") fires keypress, as every engine does')
    or diag('a form listening on keypress for keyCode 13 -- the case press() advertises -- never ran');
is($g{keyup_target}, 'two', 'keyup goes to whatever is focused NOW, not what was focused at keydown');

# --- scroll ---
is($g{abs}{y}, 500, 'scroll(y => 500) moves to an absolute offset');
is($g{rel}{y}, 600, 'scroll(by => 1, y => 100) is relative to the current offset');
is($g{relstr}{y}, 650, "a relative offset given as the STRING '50' adds, it does not concatenate")
    or diag('a JSON string on the JS side makes x += A.x a concatenation');
cmp_ok($g{bottom}{y}, '>', 600, 'scroll(to => "bottom") reaches the document end');
is($g{top}{y}, 0,    'scroll(to => "top") returns to the origin');

# --- box ---
is($g{box_err}, undef, 'box: no error');
is($g{box}{left},   40,  'box reports the left offset');
is($g{box}{top},    60,  'box reports the top offset');
is($g{box}{width},  120, 'box reports the width');
is($g{box}{height}, 30,  'box reports the height');
ok(exists $g{box}{page_x}, 'box also carries page-relative coordinates');

# a display:none element has an all-zero rect in every browser; reporting that
# as a box would be a lie a caller could divide by
ok($g{hidden_called}, 'precondition: box() on the hidden element actually answered');
is($g{hidden_err}, undef, '...without an error');
is($g{hidden_box}, undef, 'box is undef for an element that is not rendered');

# --- validation ---
{
    my $b2 = EV::WebKit->new(window => [200,150]);
    eval { $b2->press(undef, sub {}) };
    like($@, qr/key name is required/, 'press requires a key');
    eval { $b2->press('a', bogus => 1, sub {}) };
    like($@, qr/unknown option/, 'press rejects an unknown modifier');
    eval { $b2->scroll(nope => 1) };
    like($@, qr/unknown option/, 'scroll rejects an unknown option');
    eval { $b2->scroll(to => 'sideways') };
    like($@, qr/top.*bottom/, 'scroll validates the to option');
    # a non-CODE cb is truthy, so it sails past the option filter into _call_js
    # and only dies inside the deferred completion, where $EV::DIED swallows it
    # -- leaving the caller's EV::run hung on a callback that cannot be invoked
    eval { $b2->scroll(y => 10, cb => 'not-a-code-ref') };
    like($@, qr/code reference/, 'scroll croaks on a non-coderef cb, rather than hanging later');
    eval { $b2->scroll(y => 'soon') };
    like($@, qr/y must be a number/, 'scroll rejects a non-numeric offset');

    # The positional-binding trap the Element atoms already guard. find(sub{})
    # bound the callback to the SELECTOR and left $cb undef, so the encode error
    # went to a no-op and the caller's callback was never invoked at all -- a
    # silent hang. find(undef) marshalled a JSON null, which querySelector
    # coerces to the type selector "null": indistinguishable from "not found".
    eval { $b2->find(sub { }) };
    like($@, qr/did you omit the selector/, 'find(sub{}) names the mistake instead of hanging');
    eval { $b2->find(undef, sub { }) };
    like($@, qr/selector is required/,      'find(undef) croaks rather than silently matching nothing');
    eval { $b2->find('', sub { }) };
    like($@, qr/must not be empty/,         'find("") croaks');
    eval { $b2->find_all(sub { }) };
    like($@, qr/did you omit the selector/, 'find_all guards the same way');
    $b2->quit;
}

# --- scrolling on a page with CSS `scroll-behavior: smooth` ---
#
# That one CSS line turns scrollTo and scrollIntoView into ANIMATIONS. The
# scroll then has not happened yet when the next statement reads the offset
# back, so scroll() reported the position it started from (y == 0 for a scroll
# to 1000) and scroll_into_view() resolved with the viewport still travelling --
# both wrong, and wrong only on pages that use the property, which is the worst
# kind of intermittent. Fixed by asking for behavior:"instant" explicitly, which
# overrides the CSS.
{
    my $b2 = EV::WebKit->new(window => [400, 300], timeout => 15);
    my %s;
    my @st;
    my $nx; $nx = sub { my $t = shift @st or return EV::break; $t->() };

    push @st, sub { $b2->scroll(y => 1000, cb => sub { $s{reported} = $_[0]; $nx->() }) };
    # the REAL offset, read separately: a scroll() that merely echoed its own
    # argument back would pass the assertion above while the page never moved
    push @st, sub { $b2->script('return window.scrollY', sub { $s{real} = $_[0]; $nx->() }) };
    push @st, sub { $b2->scroll(to => 'top', cb => sub { $nx->() }) };
    push @st, sub {
        $b2->find('#target', sub {
            $_[0]->scroll_into_view(sub {
                $b2->script('return window.scrollY', sub { $s{siv} = $_[0]; $nx->() });
            });
        });
    };

    $b2->load_html(<<'HTML', sub { $nx->() });
<style>
  html { scroll-behavior: smooth }
  body { margin: 0 }
  #tall   { height: 5000px }
  #target { position: absolute; top: 3000px; height: 20px }
</style>
<div id=tall></div>
<div id=target>T</div>
HTML
    TWK::run_with_timeout(40);
    $b2->quit;

    is($s{reported}{y}, 1000, 'scroll() reports the position it actually reached, not the one it left');
    is($s{real},        1000, '...and the page really is there when the callback runs');
    cmp_ok($s{siv}, '>', 1000, 'scroll_into_view() has finished scrolling before it calls back');
}

# box's page_x/page_y are the viewport coordinates PLUS the scroll offset, and
# nothing pinned the difference: every existing box check runs at scroll 0,
# where the two spaces coincide, so dropping the offset left them all green.
{
    my $b = EV::WebKit->new(window => [300,200], timeout => 10);
    my %g;
    $b->load_html('<html><body style="margin:0">'
                . '<div style="height:1200px"></div>'
                . '<div id=target style="height:40px;background:#333"></div>'
                . '</body></html>', sub {
        $b->scroll(y => 600, cb => sub {
            $g{scrolled} = $_[0] && $_[0]{y};
            $b->find('#target', sub {
                my ($el, $err) = @_;
                return do { $g{err} = $err // 'not found'; EV::break } if $err || !$el;
                $el->box(sub { ($g{box}, $g{box_err}) = @_; EV::break });
            });
        });
    });
    TWK::run_with_timeout(25);
    is($g{box_err}, undef, 'box on a scrolled page succeeds') or diag $g{box_err};
    cmp_ok($g{scrolled} // 0, '>', 0, 'precondition: the page really scrolled');
    SKIP: {
        skip 'no box', 2 unless ref $g{box} eq 'HASH';
        is($g{box}{page_y}, $g{box}{y} + $g{scrolled},
           'page_y is the viewport coordinate plus the scroll offset');
        isnt($g{box}{page_y}, $g{box}{y},
             '...which at a nonzero scroll is a different number from y');
    }
    $b->quit;
}

done_testing;
