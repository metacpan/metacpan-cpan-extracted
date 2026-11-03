import { describe, it } from 'node:test';
import assert from 'node:assert';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import ts from 'typescript';
import * as api from '../src/index.js';

const root = new URL('../', import.meta.url);
const pkg = JSON.parse(readFileSync(new URL('package.json', root), 'utf8'));
const dts = readFileSync(new URL('src/index.d.ts', root), 'utf8');

describe('package.json', () => {
  it('points TypeScript at a declaration file that exists and ships', () => {
    const types = pkg.types;
    assert.strictEqual(pkg.exports['.'].types, types);
    assert.ok(existsSync(new URL(types, root)), types + ' exists in the source tree');
    const rel = types.replace(/^\.\//, '');
    assert.ok(
      pkg.files.some((f) => rel === f || rel.startsWith(f + '/')),
      types + ' is covered by "files"'
    );
  });
});

describe('src/index.d.ts', () => {
  const named = Object.keys(api).filter((k) => k !== 'default').sort();

  it('the default export carries every named export', () => {
    assert.deepStrictEqual(Object.keys(api.default).sort(), named);
  });

  it('declares every named export', () => {
    for (const name of named) {
      assert.match(dts, new RegExp('export function ' + name + '\\('), name);
    }
  });

  it('declares every named export on the default export', () => {
    for (const name of named) {
      assert.match(dts, new RegExp('\\b' + name + ': typeof ' + name + ';'), name);
    }
  });
});

describe('TypeScript consumer', () => {
  it('test/types/consumer.ts compiles under --strict with nodenext resolution', () => {
    const file = fileURLToPath(new URL('test/types/consumer.ts', root));
    const program = ts.createProgram([file], {
      strict: true,
      noEmit: true,
      module: ts.ModuleKind.NodeNext,
      moduleResolution: ts.ModuleResolutionKind.NodeNext,
      types: [],
    });
    const report = ts.formatDiagnostics(ts.getPreEmitDiagnostics(program), {
      getCanonicalFileName: (f) => f,
      getCurrentDirectory: () => fileURLToPath(root),
      getNewLine: () => '\n',
    });
    assert.strictEqual(report, '');
  });
});
