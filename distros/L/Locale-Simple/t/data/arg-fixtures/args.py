# Fixture for t/52-scrape-args.t: what follows the strings is code.
l("PY var %s", name)
y = l("PY assign %s", user.name)
ln("PY count one", "PY count many", n)
ln("PY len %d", "PY lens %d", len(items))
ln("PY attr %d", "PY attrs %d", u.count, items[0])
l("PY paren %s", ")")
l("PY comma %s %s", ",", 'it\'s, (')
l("PY escape %s", "tab\t(")
l("PY nested %s and %s", l("PY Apple"), x)
ldn("PY_dom", "PY dom one", "PY dom many", sum(x for x in xs), {"k": [1, 2]})
l(
    "PY multi %s %s",
    first,
    ", ".join(names),
)
ln("PY nested count one", "PY nested count many", len(l("PY in count")))
l(not_constant, l("PY inside skipped"))
