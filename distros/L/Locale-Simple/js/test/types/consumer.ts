// Type-level checks of src/index.d.ts. test/package.test.js compiles this file
// with --strict and nodenext resolution, through the package's own "exports".
import { l, ln, l_nolocales, loadLocaleData, loadTranslations } from "locale-simple";
import localeSimple from "locale-simple";

l_nolocales(true);
localeSimple.l_nolocales(false);

// bin/po2json output: "" holds the header, the others [msgid_plural | null, msgstr...]
loadLocaleData("d", {
  d: {
    "": { Language: " de_DE", "Plural-Forms": "nplurals=2; plural=n != 1;" },
    Hello: [null, "Hallo"],
    "%d file": ["%d files", "%d Datei", "%d Dateien"],
  },
});
loadLocaleData("d", { d: { Hello: "Hallo" } });

// @ts-expect-error header values are strings
loadLocaleData("d", { d: { "": { Language: 1 } } });
// @ts-expect-error entries are strings or arrays of strings
loadLocaleData("d", { d: { Hello: 42 } });

loadTranslations("d", "de", { Hello: "Hallo", "%d file": ["%d Datei", "%d Dateien"] }, "nplurals=2; plural=n != 1;");

export const hello: string = l("Hello");
export const files: string = ln("%d file", "%d files", 2);
