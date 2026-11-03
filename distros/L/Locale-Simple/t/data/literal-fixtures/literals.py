# Python: raw and triple-quoted strings are msgids, raw ones keep their
# backslashes; adjacent literals join. f-strings and bytes are not msgids.
l(r"PY raw \n stays \d")
l(R'PY raw single \t stays')
l("""PY triple "quoted" \t tab
and a second line""")
l('''PY triple single 'quoted' ''')
l(r"""PY raw triple \n stays""")
l(u"PY unicode prefix ä")
l("PY adjacent " 'joined ' "three")
l("PY adjacent "
  "over lines")
l("PY adjacent with "  # a comment
  "a comment between")
l("PY adjacent " "and " + "plus")
ln("PY one", r"PY many raw \n", n)
lp(r"PY ctx \d", """PY triple with context""")
l(r"0")
l(f"PY f-string {name} is not read", l("PY inner of f-string"))
l(F"PY upper f-string is not read")
l(b"PY bytes is not read")
l(rb"PY raw bytes is not read")
l(fr"PY raw f-string is not read")
l("PY adjacent " f"{name} is not read")
