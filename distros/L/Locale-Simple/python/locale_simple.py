from gettext import textdomain, dngettext, ngettext, bindtextdomain, dgettext, gettext
try:
    from gettext import bind_textdomain_codeset
except ImportError:
    bind_textdomain_codeset = None
import os, sys, re

__version__ = "0.108"

__all__ = [
    'l_nolocales',
    'l_dry',
    'l_dir',
    'l_lang',
    'ltd',
    'l',
    'ln',
    'lp',
    'lnp',
    'ld',
    'ldn',
    'ldp',
    'ldnp',
]

global dry, nowrite, nolocales, dir 
dry, nowrite, nolocales, dir = None, None, None, None
tds = {}

def l_nolocales(x):
    global nolocales
    nolocales = x
def l_dry(d, n=False):
    global dry, nowrite, nolocales
    dry, nowrite, nolocales = d, n, bool(d)
def l_dir(d): 
    global dir
    if not os.path.isdir(d): raise OSError("%s: No such file or directory" % d)
    dir = d

def _die(msg):
    sys.stderr.write(msg + '\n')
    exit(1)

def gettext_escape(content):
    content = content.replace('\n', '\\n')
    content = content.replace('"', '\"')
    return content

def l_lang(primary):
    for var in 'LANG', 'LANGUAGE', 'LC_ALL':
        os.environ.update({var: primary})

def wd(data):
    if nowrite: return
    f = open(dry, 'a')
    f.write('\n'.join(data) + "\n\n")
    f.close()

def sprintf(string, *args):
    args = list(args)
    for m in re.finditer(r'%(\d+)\$([scboxXuidfegEG])', string):
        substr = m.string[m.start():m.end()]
        groups = m.groups()
        string = string.replace(substr, ('%'+groups[1]) % args[int(groups[0])-1])
    count = len(re.findall(r'%%|%(?:\d+\$)?(?:[-+\'#0 ]*)(?:\*\d+\$|\*|\d+)?(\.(?:\*\d+\$|\*|\d+))?(?:[scboxXuidfegEG])', string))
    args = tuple(args[:count])
    return string % args

def l(id, *args):
    return ldnp('', None, id, None, None, *args)
def ln(id, idp, n, *args):
    return ldnp('', None, id, idp, n, *args)
def lp(ctxt, id, *args):
    return ldnp('', ctxt, id, None, None, *args)
def lnp(ctxt, id, idp, n, *args):
    return ldnp('', ctxt, id, idp, n, *args)
def ld(td, id, *args):
    return ldnp(td, None, id, None, None, *args)
def ldn(td, id, idp, n, *args):
    return ldnp(td, None, id, idp, n, *args)
def ldp(td, ctxt, id, *args):
    return ldnp(td, ctxt, id, None, None, *args)

def ldnp(td, ctxt, id, idp, n, *args):
    if not len(id): return id
    if not dir and not nolocales:
        _die("please set a locale directory with l_dir() before using other translate functions")

    if idp is not None: args = (n,) + args
    is_plural = idp is not None
    out = None
    if dry:
        if not nowrite:
            save = []
            if td: save.append(' # domain: '+td)
            if ctxt: save.append('msgctxt: "'+gettext_escape(ctxt)+'"')
            save.append('msgid "'+gettext_escape(id)+'"')
            if idp: save.append('msgid_plural "'+gettext_escape(idp)+'"')
            wd(save)
        out = (idp if is_plural and n != 1 else id) % args
    else:
        key = (ctxt + '\x04' + id) if ctxt else id
        keyp = (ctxt + '\x04' + idp) if ctxt and idp else idp
        if   td and is_plural:     raw = dngettext(td, key, keyp, n)
        elif td and not is_plural: raw = dgettext(td, key)
        elif is_plural:            raw = ngettext(key, keyp, n)
        else:                      raw = gettext(key)

        # gettext returns the input string untouched when no translation
        # exists, so for a pgettext-style lookup we have to strip the
        # "ctxt\x04" prefix ourselves to fall back to the plain msgid.
        if ctxt and raw.startswith(ctxt + '\x04'):
            raw = raw[len(ctxt) + 1:]

        out = sprintf(raw, *args)
    return out

def ltd(td):
    if td not in tds:
        bindtextdomain(td, dir)
        if bind_textdomain_codeset:
            bind_textdomain_codeset(td, 'utf-8')
        tds[td] = 1
    textdomain(td)
