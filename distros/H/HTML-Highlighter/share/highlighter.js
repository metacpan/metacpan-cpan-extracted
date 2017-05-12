var HighlightScroller = Class.create({
  initialize: function(container) {
    this.container = container;
    this.highlights = this.getHighlights();
    this.current = 0;
  },

  getHighlights: function() {
    return this.container.select('.highlight');
  },

  reset: function () {
    this.highlights = this.getHighlights();
    this.current = 0;
    this.scrollToCurrent();
  },

  hasHighlights: function () {
    return this.highlights.length > 0;
  },

  next: function() {
    if (!this.hasHighlights()) return;

    this.current++;
    if (!this.highlights[this.current]) {
      this.current = 0;
    }
    this.scrollToCurrent();
  },
  prev: function() {
    if (!this.hasHighlights()) return;

    this.current--;
    if (!this.highlights[this.current]) {
      this.current = this.highlights.lenght - 1;
    }
    this.scrollToCurrent();
  },

  scrollToCurrent: function() {
    this.container.scrollTop = 0;
    this.container.select('.current').invoke("removeClassName", "current");
    this.highlights[this.current].addClassName("current");
    var y = this.highlights[this.current].up('li').positionedOffset().top;
    this.container.scrollTop = y;
  }
});
