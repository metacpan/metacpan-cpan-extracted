// Fixture for t/52-scrape-args.t: what follows the strings is code.
l("JS var %s", name);
const y = l("JS assign %s", user.name);
ln("JS count one", "JS count many", n);
ln("JS member %d", "JS members %d", u.count, items[0]);
ln("JS fn %d", "JS fns %d", count(items));
l("JS paren %s", ")");
l("JS comma %s %s", ",", 'it\'s, (');
l("JS escape %s", "tab\t(");
l("JS nested %s and %s", l("JS Apple"), x);
lnp("JS_ctx", "JS ctx one", "JS ctx many", list.filter((i) => i.ok).length, { a: [1, 2] });
l(
  "JS multi %s %s",
  first,
  list.map((x) => x.name).join(", ")
);
ln("JS nested count one", "JS nested count many", count(l("JS in count")));
l(notConstant, l("JS inside skipped"));
// Last: no code after it could make up for a bracket read wrongly.
l("JS template %s", `(${n} items, ${total}`);
