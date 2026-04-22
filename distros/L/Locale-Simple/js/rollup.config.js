import { readFileSync } from 'fs';

const pkg = JSON.parse(readFileSync('./package.json', 'utf8'));

export default [
  // ES Module build
  {
    input: 'src/index.js',
    output: {
      file: 'dist/index.js',
      format: 'es',
      sourcemap: true,
    },
  },
  // CommonJS build
  {
    input: 'src/index.js',
    output: {
      file: 'dist/index.cjs',
      format: 'cjs',
      sourcemap: true,
      exports: 'named',
    },
  },
  // UMD build for browsers (global variable)
  {
    input: 'src/index.js',
    output: {
      file: 'dist/locale-simple.umd.js',
      format: 'umd',
      name: 'LocaleSimple',
      sourcemap: true,
      exports: 'named',
    },
  },
];
