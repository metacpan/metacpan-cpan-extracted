import sys, os

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

from locale_simple import *

@test
def setup():
    l_dir(os.path.dirname(os.path.abspath(__file__)) + '/../t/data/locale')
    ltd('test')
    l_lang('de_DE')

@test
def translate():
    testeq(
            l('Hello'),
            'Hallo'
            )

    testeq(
            ln("You have %d message","You have %d messages",4),
            'Du hast 4 Nachrichten'
            )

    testeq(
            ln("You have %d message","You have %d messages",1),
            'Du hast 1 Nachricht'
            )

    testeq(
            ln("You have %d message of %s","You have %d messages of %s",1,'harry'),
            'Du hast 1 Nachricht von harry'
            )

    testeq(
            ln("You have %d message of %s","You have %d messages of %s",4,'harry'),
            'Du hast 4 Nachrichten von harry'
            )

    testeq(
            ln('%2$s brought %1$d message','%2$s brought %1$d messages',1,'harry'),
            '1 Nachricht gebracht von harry'
            )

    testeq(
            ln('%2$s has %1$d message','%2$s has %1$d messages',4,'harry'),
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

    testeq(
            lp("alien","Hello"),
            "Hallo Ausserirdischer"
            )

exit(err)
