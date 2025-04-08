const fs = require('fs')
const path = require('path')
const babel = require('@rollup/plugin-babel')

const inputFiles = fs.readdirSync('.').filter(file => file.endsWith('.js'));

module.exports = inputFiles.map(file => ({
  input: file,
  output: {
    file: path.join('..','htdocs','static','common','js', file),
    format: 'iife',
    name: path.basename(file, '.js'),
    extend: true,
  },
  plugins: [babel({presets: ['@babel/preset-env'], babelHelpers: 'bundled'})],
}));
