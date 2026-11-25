#!/usr/bin/env node

import fc from 'fast-check';
import { spawnSync } from 'node:child_process';
import { writeSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, '..', '..');
const dashboard = path.join(repoRoot, 'bin', 'd2');
const perl5opt = process.env.PERL5OPT || '';
const harnessPerlSwitches = process.env.HARNESS_PERL_SWITCHES || '';

function fastCheckRunCount() {
  const explicit = Number.parseInt(process.env.DD_FAST_CHECK_RUNS || '', 10);
  if (Number.isInteger(explicit) && explicit > 0) {
    return explicit;
  }

  if (/Devel::Cover/.test(perl5opt) || /Devel::Cover/.test(harnessPerlSwitches)) {
    return 5;
  }

  return 50;
}

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

// Progress reporting, on only when the Perl wrapper asks for it
// (DD_FAST_CHECK_PROGRESS=1). Each property run starts two Perl processes, so
// the whole suite can take minutes on a busy machine, and a run that prints
// nothing until the end looks stuck to a watcher of the test log. The line is
// written with a synchronous write to stdout: spawnSync blocks the event
// loop, so an ordinary console.log to a pipe could sit unsent until the end.
// It goes to stdout, never stderr, because the wrapper asserts stderr empty.
const reportProgress = process.env.DD_FAST_CHECK_PROGRESS === '1';
const totalRuns = fastCheckRunCount();
let propertyCalls = 0;

function noteProgress() {
  if (!reportProgress) {
    return;
  }
  propertyCalls += 1;
  try {
    writeSync(1, `fast-check property call ${propertyCalls} (planned runs: ${totalRuns})\n`);
  } catch (error) {
    // A full or closed pipe must never fail the property itself; the
    // progress line is only a sign of life.
  }
}

fc.assert(
  fc.property(
    fc.string({ maxLength: 256 }),
    (text) => {
      noteProgress();
      const encoded = runDashboard('encode', text).trimEnd();
      const decoded = runDashboard('decode', `${encoded}\n`);
      return decoded === text;
    }
  ),
  { numRuns: totalRuns }
);
