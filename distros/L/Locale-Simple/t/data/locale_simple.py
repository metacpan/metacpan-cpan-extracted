from gettext import textdomain, lgettext, dngettext, ngettext, bindtextdomain, bind_textdomain_codeset, dgettext, gettext
import os, sys, re

__version__ = 0.1

__all__ = [
    'l_nolocales',
    'l_dry',
    'l_dir',
    'l_lang',
    'ltd',
    'l',
    'ln',
    'lp',
    'ldn',
]

global dry, nowrite, nolocales, dir 
dry, nowrite, nolocales, dir = None, None, None, None
tds = {}

def l_nolocales(x):
    global nolocales
    nolocales = x
def l_dry(d, n): 
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
    return ldnp('',None,id,None,None,*args)
def ln(id, idp, n, *args):
    return ldnp('', None, id, idp, n, *args)
def lp(ctxt, id, *args):
    return ldnp('', ctxt, id, None, None, *args)
def ldn(td, id, idp, n, *args):
    return ldnp(td,None,id,idp,n,*args)

def ldnp(td, ctxt, id, idp, n, *args):
    if not dir or nolocales: _die("please set a locale directory with l_dir() before using other translate functions")

    if idp: args = (n,) + args
    out = None
    if dry:
        if not nowrite:
            save = []
            if td: save.push(' # domain: '+td)
            if ctxt: save.push('msgctxt: "'+gettext_escape(ctxt)+'"')
            save.push('msgid "'+gettext_escape(id)+'"')
            if idp: save.push('msgid_plural "'+gettext_escape(idp)+'"')
            wd(save)
        out = (idp if idp and n != 1 else id) % args
    else:
        if       td and not ctxt and id and     idp and     n: out = sprintf(dngettext(td, id, idp, n), *args)
        elif not td and not ctxt and id and     idp and     n: out = sprintf(ngettext(id, idp, n), *args)
        elif not td and not ctxt and id and not idp and not n: out = sprintf(gettext(id), *args)
        elif     td and not ctxt and id and not idp and not n: out = sprintf(dgettext(td, id), *args)

        # with context magic
        if       td and     ctxt and id and     idp and     n: out = sprintf(dngettext(td, ctxt+'\x04'+id, ctxt+'\x04'+idp, n), *args)
        elif not td and     ctxt and id and     idp and     n: out = sprintf(ngettext(ctxt+'\x04'+id, ctxt+'\x04'+idp, n), *args)
        elif not td and     ctxt and id and not idp and not n: out = sprintf(gettext(ctxt+'\x04'+id), *args)
        elif     td and     ctxt and id and not idp and not n: out = sprintf(dgettext(td, ctxt+'\x04'+id), *args)
    return out

def ltd(td):
    if not tds.__contains__(td):
        bindtextdomain(td,dir)
        bind_textdomain_codeset(td,'utf-8')
        tds[td] = 1
    textdomain(td)
