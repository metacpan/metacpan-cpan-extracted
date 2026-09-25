// trace.js - the seventeen CJK glyphs on the tiles, as SVG paths.
//
// Why paths and not text: a <text> in the sprite consults the device's fonts,
// stock Android has no glyphs for the Unicode Mahjong Tiles block and often no
// CJK face at all, and a rack of tofu is a broken game. So the outlines are
// traced ONCE, here, from Noto Sans CJK SC Bold (SIL Open Font License 1.1,
// which permits embedding outlines), and the sprite carries the paths.
//
// The font is not shipped (17 MB). Fetch it and run this to regenerate:
//
//   curl -L -o NotoSansCJKsc-Bold.otf \
//     https://github.com/notofonts/noto-cjk/raw/main/Sans/OTF/SimplifiedChinese/NotoSansCJKsc-Bold.otf
//   npm install opentype.js@1.3.4
//   node xt/faces/trace.js NotoSansCJKsc-Bold.otf > xt/faces/glyphs.json
//
// Each glyph is scaled so the em box is 1000 units wide and flipped to SVG's
// y-down, then rounded to whole units. The sprite builder (build-sprite.pl)
// places each path inside a tile's 60 x 80 viewBox.

'use strict';

const path = process.argv[2];
if (!path) {
  process.stderr.write('usage: node trace.js NotoSansCJKsc-Bold.otf > glyphs.json\n');
  process.exit(2);
}

const opentype = require('opentype.js');
const font = opentype.loadSync(path);
const upm = font.unitsPerEm;

// The characters the tiles carry, and the code each belongs to. The numerals
// and the wan sign for the character suit, the four winds, and the red and
// green dragons. The white dragon is a frame and needs no glyph.
// The Latin digits ride along for the small index in a corner of the
// character tiles (an option the owner's eye decides) and for the number on
// a flower or a season.
const GLYPHS = {
  '一': 'n1', '二': 'n2', '三': 'n3', '四': 'n4', '五': 'n5',
  '六': 'n6', '七': 'n7', '八': 'n8', '九': 'n9', '萬': 'wan',
  '東': 'we', '南': 'ws', '西': 'ww', '北': 'wn',
  '中': 'dr', '發': 'dg',
  '1': 'd1', '2': 'd2', '3': 'd3', '4': 'd4', '5': 'd5',
  '6': 'd6', '7': 'd7', '8': 'd8', '9': 'd9',
};

const out = {};
for (const [ch, key] of Object.entries(GLYPHS)) {
  const glyph = font.charToGlyph(ch);
  if (!glyph || glyph.index === 0) {
    process.stderr.write(`no glyph for ${ch}\n`);
    process.exit(1);
  }
  // opentype's getPath takes x, y (baseline), fontSize; at fontSize == upm the
  // units are the font's own, y already flipped to y-down. We then scale to a
  // 1000-unit em.
  const p = glyph.getPath(0, 0, upm);
  const scale = 1000 / upm;
  const parts = [];
  for (const c of p.commands) {
    const r = (v) => Math.round(v * scale);
    switch (c.type) {
      case 'M': parts.push(`M${r(c.x)} ${r(c.y)}`); break;
      case 'L': parts.push(`L${r(c.x)} ${r(c.y)}`); break;
      case 'C': parts.push(`C${r(c.x1)} ${r(c.y1)} ${r(c.x2)} ${r(c.y2)} ${r(c.x)} ${r(c.y)}`); break;
      case 'Q': parts.push(`Q${r(c.x1)} ${r(c.y1)} ${r(c.x)} ${r(c.y)}`); break;
      case 'Z': parts.push('Z'); break;
    }
  }
  const bb = glyph.getBoundingBox();
  out[key] = {
    char: ch,
    advance: Math.round(glyph.advanceWidth * scale),
    // the bounding box in the same y-down 1000-unit space
    box: [Math.round(bb.x1 * scale), Math.round(-bb.y2 * scale), Math.round(bb.x2 * scale), Math.round(-bb.y1 * scale)],
    d: parts.join(''),
  };
}

process.stdout.write(JSON.stringify({
  font: font.names.fontFamily.en + ' ' + (font.names.fontSubfamily.en || ''),
  license: 'SIL Open Font License 1.1',
  unitsPerEm: 1000,
  glyphs: out,
}, null, 1) + '\n');
