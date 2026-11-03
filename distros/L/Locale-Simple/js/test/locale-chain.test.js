import { describe, it } from 'node:test';
import assert from 'node:assert';
import { l_lang, ltd, loadTranslations, loadLocaleData, l, ln } from '../src/index.js';

const PF = 'nplurals=2; plural=n != 1;';

// Lookup across the candidate chain, .claude/skills/locale-simple-core/references/mo-reader.md §2. Every test
// uses its own domain; the language strings come from l_lang().
describe('locale chain lookup', () => {
  it('a de bundle answers l_lang("de_DE")', () => {
    loadTranslations('c_base', 'de', { Hello: 'Hallo' });
    ltd('c_base');
    l_lang('de_DE');
    assert.strictEqual(l('Hello'), 'Hallo');
  });

  it('de_AT:fr tries de_AT, de, fr, then the msgid', () => {
    loadTranslations('c_walk', 'de_AT', { A: 'A de_AT' });
    loadTranslations('c_walk', 'de', { A: 'A de', B: 'B de' });
    loadTranslations('c_walk', 'fr', { A: 'A fr', B: 'B fr', C: 'C fr' });
    ltd('c_walk');
    l_lang('de_AT:fr');
    assert.strictEqual(l('A'), 'A de_AT');
    assert.strictEqual(l('B'), 'B de');
    assert.strictEqual(l('C'), 'C fr');
    assert.strictEqual(l('D'), 'D');
  });

  it('an empty translation or a missing plural form falls through', () => {
    loadTranslations('c_empty', 'de', { Hello: '', '%d file': ['%d Datei'] });
    loadTranslations('c_empty', 'fr', { Hello: 'Bonjour', '%d file': ['%d fichier', '%d fichiers'] });
    ltd('c_empty');
    l_lang('de:fr');
    assert.strictEqual(l('Hello'), 'Bonjour');
    assert.strictEqual(ln('%d file', '%d files', 1), '1 Datei');
    assert.strictEqual(ln('%d file', '%d files', 3), '3 fichiers');
    l_lang('de');
    assert.strictEqual(l('Hello'), 'Hello');
    assert.strictEqual(ln('%d file', '%d files', 3), '3 files');
  });

  it('the plural rule comes from the bundle that answered', () => {
    loadTranslations('c_rule', 'de', { Other: 'Andere' }, 'nplurals=2; plural=n != 1;');
    loadTranslations('c_rule', 'fr', { '%d file': ['%d fichier', '%d fichiers'] }, 'nplurals=2; plural=n > 1;');
    ltd('c_rule');
    l_lang('de:fr');
    assert.strictEqual(ln('%d file', '%d files', 0), '0 fichier');
    assert.strictEqual(ln('%d file', '%d files', 2), '2 fichiers');
  });

  it('a bundle without language answers after the last candidate', () => {
    loadLocaleData('c_any', { c_any: { '': { 'Plural-Forms': PF }, Hello: [null, 'Hallo (any)'], Bye: [null, 'Tschüss (any)'] } });
    loadTranslations('c_any', 'fr', { Hello: 'Bonjour' });
    ltd('c_any');
    l_lang('de_AT:fr');
    assert.strictEqual(l('Hello'), 'Bonjour');
    assert.strictEqual(l('Bye'), 'Tschüss (any)');
    l_lang('xx_YY');
    assert.strictEqual(l('Hello'), 'Hallo (any)');
  });

  it('C, POSIX and "" contribute nothing; only the bundle without language answers', () => {
    loadTranslations('c_c', 'de', { Hello: 'Hallo' });
    loadTranslations('c_c', '', { Hello: 'Hello (any)' });
    ltd('c_c');
    for (const lang of ['C', 'POSIX', '', 'C.UTF-8']) {
      l_lang(lang);
      assert.strictEqual(l('Hello'), 'Hello (any)', JSON.stringify(lang));
    }
    l_lang('C:de');
    assert.strictEqual(l('Hello'), 'Hallo');
  });

  it('po2json bundles follow the same chain', () => {
    loadLocaleData('c_po', { c_po: { '': { Language: ' de', 'Plural-Forms': PF }, Hello: [null, 'Hallo'] } });
    ltd('c_po');
    l_lang('de_AT');
    assert.strictEqual(l('Hello'), 'Hallo');
  });

  it('files a bundle under its normalised language (pt-BR, de_DE.UTF-8)', () => {
    loadTranslations('c_norm', 'pt-BR', { Hello: 'Olá' });
    loadLocaleData('c_norm', { c_norm: { '': { Language: ' de_DE.UTF-8', 'Plural-Forms': PF }, Hello: [null, 'Hallo'] } });
    ltd('c_norm');
    l_lang('pt-BR');
    assert.strictEqual(l('Hello'), 'Olá');
    l_lang('pt_BR');
    assert.strictEqual(l('Hello'), 'Olá');
    l_lang('de_DE');
    assert.strictEqual(l('Hello'), 'Hallo');
  });

  it('msgids and languages named like Object.prototype members are plain misses', () => {
    loadTranslations('c_proto', 'de', { Hello: 'Hallo' });
    ltd('c_proto');
    l_lang('de');
    assert.strictEqual(l('constructor'), 'constructor');
    assert.strictEqual(l('toString'), 'toString');
    l_lang('constructor');
    assert.strictEqual(l('name'), 'name');
  });
});
