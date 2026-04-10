#!/usr/bin/env node

import fc from 'fast-check';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');
const dashboard = path.join(repoRoot, 'bin', 'dashboard');

function runDashboard(command, input) {
  const result = spawnSync(
    'perl',
    ['-Ilib', dashboard, command],
    {
      cwd: repoRoot,
      encoding: 'utf8',
      input,
      maxBuffer: 10 * 1024 * 1024,
    }
  );

  if (result.status !== 0) {
    throw new Error(
      `dashboard ${command} failed with status ${result.status}\nSTDERR:\n${result.stderr}\nSTDOUT:\n${result.stdout}`
    );
  }

  return result.stdout;
}

fc.assert(
  fc.property(
    fc.string({ maxLength: 256 }),
    (text) => {
      const encoded = runDashboard('encode', text).trimEnd();
      const decoded = runDashboard('decode', `${encoded}\n`);
      return decoded === text;
    }
  ),
  { numRuns: 50 }
);

