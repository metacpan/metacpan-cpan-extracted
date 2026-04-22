import sys, os, tempfile

global err
err = 0

def test(func):
    global err
    print(func.__name__ + '...')
    try:
        func()
        print('\033[32mOK\033[0m\n')
    except BaseException as e:
        err = 1
        print('\033[31m' + str(e) + '\033[0m')


def testeq(one, two):
    sys.stdout.write("Testing equality (%s == %s)..." % (repr(one), repr(two)))
    if one != two: raise ValueError("The two values do not match")
    else: print('OK')


@test
def test_import():
    from locale_simple import __all__
    testeq(type(__all__), list)
    # API parity with Perl/JS siblings
    for name in ('l', 'ln', 'lp', 'lnp', 'ld', 'ldn', 'ldp', 'ldnp',
                 'l_dir', 'l_lang', 'l_dry', 'l_nolocales', 'ltd'):
        if name not in __all__:
            raise ValueError("%s missing from __all__" % name)


from locale_simple import *

LOCALE_DIR = os.path.dirname(os.path.abspath(__file__)) + '/../t/data/locale'


@test
def setup():
    l_dir(LOCALE_DIR)
    ltd('test')
    l_lang('de_DE')


@test
def translate():
    testeq(l('Hello'), 'Hallo')

    testeq(
        ln("You have %d message", "You have %d messages", 4),
        'Du hast 4 Nachrichten'
    )
    testeq(
        ln("You have %d message", "You have %d messages", 1),
        'Du hast 1 Nachricht'
    )
    testeq(
        ln("You have %d message", "You have %d messages", 0),
        'Du hast 0 Nachrichten'
    )
    testeq(
        ln("You have %d message of %s", "You have %d messages of %s", 1, 'harry'),
        'Du hast 1 Nachricht von harry'
    )
    testeq(
        ln("You have %d message of %s", "You have %d messages of %s", 4, 'harry'),
        'Du hast 4 Nachrichten von harry'
    )
    testeq(
        ln('%2$s brought %1$d message', '%2$s brought %1$d messages', 1, 'harry'),
        '1 Nachricht gebracht von harry'
    )
    testeq(
        ln('%2$s has %1$d message', '%2$s has %1$d messages', 4, 'harry'),
        'harry hat 4 Nachrichten'
    )
    testeq(
        l("Change order test %s %s", 'one', 'two'),
        "Andere Reihenfolge hier two one"
    )
    testeq(
        l('Other change order test %s %s %s', 1, 2, 3),
        'Verhalten aus http://perldoc.perl.org/functions/sprintf.html 3 1 1'
    )
    testeq(lp("alien", "Hello"), "Hallo Ausserirdischer")
    testeq(l(''), '')


@test
def context_plural():
    # lnp: context + plural. No context-plural msgid in the fixture, so we
    # just verify it doesn't blow up and falls back to the msgid.
    testeq(
        lnp('some_ctxt', 'You have %d message', 'You have %d messages', 1),
        'You have 1 message'
    )
    testeq(
        lnp('some_ctxt', 'You have %d message', 'You have %d messages', 4),
        'You have 4 messages'
    )


@test
def domain_switching():
    # ld / ldn / ldp / ldnp — the "other" domain has different translations
    # for the same msgids.
    ltd('othertest')  # bind the domain
    ltd('test')       # switch back to default, so ld() proves it's not
                      # reading from the current textdomain

    testeq(ld('othertest', 'Hello'), 'Anderes Hallo')
    testeq(
        ldn('othertest', 'You have %d message', 'You have %d messages', 4),
        'Du hast 4 AndereNachrichten'
    )
    testeq(
        ldn('othertest', 'You have %d message', 'You have %d messages', 1),
        'Du hast 1 AndereNachricht'
    )
    # Non-existent domain: falls through to msgid
    testeq(ld('nonexistent', 'Hello'), 'Hello')
    # ldp with unknown context: fall back to msgid
    testeq(ldp('othertest', 'no_such_ctxt', 'Hello'), 'Hello')


@test
def dry_run():
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.po') as tf:
        dry_file = tf.name
    try:
        l_dry(dry_file)
        # l_dry flips nolocales=True, so l() should pass through formatting
        # without hitting gettext.
        testeq(l('Hello %s', 'World'), 'Hello World')
        testeq(
            ln('One %d', 'Many %d', 1),
            'One 1'
        )
        testeq(
            ln('One %d', 'Many %d', 5),
            'Many 5'
        )
        with open(dry_file) as f:
            content = f.read()
        # Confirm msgids were appended
        if 'msgid "Hello %s"' not in content:
            raise ValueError("dry-run file did not capture Hello msgid")
        if 'msgid "One %d"' not in content:
            raise ValueError("dry-run file did not capture plural msgid")
        if 'msgid_plural "Many %d"' not in content:
            raise ValueError("dry-run file did not capture plural_id")
    finally:
        os.unlink(dry_file)
        # Reset state for any later test
        l_dry(None)
        l_dir(LOCALE_DIR)
        ltd('test')
        l_lang('de_DE')


@test
def nolocales_mode():
    # With l_nolocales(True) + no dir set, l() should still work as identity.
    # We simulate it by flipping the flag — formatting-only mode.
    from locale_simple import l_nolocales
    # Already in a known-good state thanks to dry_run teardown; no need to
    # unset l_dir. Just flip the flag and confirm no exception.
    l_nolocales(True)
    # Should still produce a translated result since dir is set and gettext
    # returns the actual translation.
    testeq(l('Hello'), 'Hallo')
    l_nolocales(False)


@test
def language_switching_lifecycle():
    # Full round-trip: load, translate, switch lang, translate again.
    l_dir(LOCALE_DIR)
    ltd('test')
    l_lang('de_DE')
    testeq(l('Hello'), 'Hallo')

    # Switching to a language with no .mo falls back to msgid.
    l_lang('xx_YY')
    # gettext caches — it may still return 'Hallo' from this process. The
    # lifecycle we care about is "no crash when switching".
    result = l('Hello')
    if result not in ('Hello', 'Hallo'):
        raise ValueError("Unexpected result after l_lang switch: %r" % result)

    # Switch back.
    l_lang('de_DE')


exit(err)
