import { describe, it } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { l_lang, ltd, loadTranslations, loadLocaleData, ln } from '../src/index.js';
import { candidates } from '../src/locale-chain.js';

// Shared with every runtime that has its own .mo reader, see
// .claude/skills/locale-simple-core/references/mo-reader.md
const vectors = JSON.parse(
  readFileSync(new URL('../../t/data/plural-forms.json', import.meta.url), 'utf8')
);

// The one-time fallback warning is a per-process flag; collect every warn call
// of this file and assert the total at the end.
const warnings = [];
const origWarn = console.warn;
console.warn = (...a) => warnings.push(a.join(' '));

function nplurals(header) {
  const m = /nplurals\s*=\s*(\d+)/.exec(header || '');
  return m ? parseInt(m[1], 10) : 2;
}

// Entry whose k-th form reads "form<k>", so the output names the chosen index.
function forms(count) {
  return Array.from({ length: count }, (_, k) => 'form' + k);
}

function setup(tag, header) {
  const domain = 'pf_' + tag;
  const lang = 'x_' + tag;
  const entry = forms(nplurals(header));
  const head = { lang };
  if (header !== null) head['Plural-Forms'] = header.replace(/^Plural-Forms:\s*/, '');
  loadLocaleData(domain, { [domain]: { '': head, one: ['many', ...entry] } });
  ltd(domain);
  l_lang(lang);
}

function check(name, header, cases) {
  setup(name, header);
  for (const [n, idx] of cases) {
    assert.strictEqual(ln('one', 'many', n), 'form' + idx, `${name}: n=${n}`);
  }
}

describe('plural forms from the Plural-Forms header', () => {
  for (const v of vectors.plural_forms) {
    it(`${v.lang}: ${v.header}`, () => check(v.lang, v.header, v.cases));
  }

  for (const v of vectors.plural_edge_cases) {
    it(`edge: ${v.name}`, () => check(v.name, v.header, v.cases));
  }

  it('loadTranslations takes the rule as an optional 4th argument', () => {
    loadTranslations('pf_lt', 'pl_PL', { one: forms(3) }, 'nplurals=3; plural=n==1 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2;');
    ltd('pf_lt');
    l_lang('pl_PL');
    assert.strictEqual(ln('one', 'many', 1), 'form0');
    assert.strictEqual(ln('one', 'many', 3), 'form1');
    assert.strictEqual(ln('one', 'many', 5), 'form2');
  });

  it('loadTranslations without a rule keeps n != 1, silently', () => {
    const before = warnings.length;
    loadTranslations('pf_old', 'de_DE', { one: forms(2) });
    ltd('pf_old');
    l_lang('de_DE');
    assert.strictEqual(ln('one', 'many', 1), 'form0');
    assert.strictEqual(ln('one', 'many', 2), 'form1');
    assert.strictEqual(warnings.length, before);
  });

  it('warns exactly once per process for missing or broken headers', () => {
    console.warn = origWarn;
    assert.strictEqual(warnings.length, 1);
  });
});

describe('locale chain from the language string', () => {
  for (const v of vectors.locale_fallback) {
    it(`${JSON.stringify(v.input)} -> ${JSON.stringify(v.candidates)}`, () => {
      assert.deepStrictEqual(candidates(v.input), v.candidates);
    });
  }
});
