import { describe, it, before, after } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import { l, l_dry } from '../src/index.js';

// Shared with every runtime, see t/data/sprintf.json and
// .claude/skills/locale-simple-core/references/mo-reader.md §5. Every runtime
// runs "rows"; "perl_python_rows" are the Perl and Python extras.
const vectors = JSON.parse(
  readFileSync(new URL('../../t/data/sprintf.json', import.meta.url), 'utf8')
);

describe('sprintf - shared rows of t/data/sprintf.json', () => {
  // Dry-run mode without output returns the msgid formatted with the arguments.
  before(() => l_dry(true, true));
  after(() => l_dry(false));

  for (const row of vectors.rows) {
    it(row.format + ' ' + JSON.stringify(row.args), () => {
      assert.strictEqual(l(row.format, ...row.args), row.want);
    });
  }
});
