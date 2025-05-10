// Test case for jquery-ui.js position bug
var left = 10, top = 20;
var that = { window: {} };

// Original code from jquery-ui.js (line 12509) that breaks when minified
options.position = {
  my: "left top",
  at: "left" + ( left >= 0 ? "+" : "" ) + left + " " +
       "top" + ( top >= 0 ? "+" : "" ) + top,
  of: that.window
};

// Alternative version from minified jquery-ui.min.js
o.position = {
  my: "left top",
  at: "left" + (0 <= s ? "+" : "") + s + " top" + (0 <= i ? "+" : "") + i,
  of: n.window
};