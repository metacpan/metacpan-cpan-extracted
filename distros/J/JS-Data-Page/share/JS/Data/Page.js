var Data;
Data = (function() {
  function Data() {}
  return Data;
})();
Data.Page = (function() {
  function Page(_total_entries, _entries_per_page, _current_page) {
    this._total_entries = _total_entries != null ? _total_entries : 0;
    this._entries_per_page = _entries_per_page != null ? _entries_per_page : 10;
    this._current_page = _current_page != null ? _current_page : 1;
  }
  Page.prototype.total_entries = function(total_entries) {
    if (total_entries) {
      this._total_entries = total_entries;
    }
    return this._total_entries;
  };
  Page.prototype.entries_per_page = function(entries_per_page) {
    if (entries_per_page) {
      this._entries_per_page = entries_per_page;
    }
    return this._entries_per_page;
  };
  Page.prototype.current_page = function(current_page) {
    if (current_page) {
      this._current_page = current_page;
    }
    return this._current_page;
  };
  Page.prototype.first_page = function() {
    return 1;
  };
  Page.prototype.last_page = function() {
    var last_page, pages;
    pages = this._total_entries / this._entries_per_page;
    if (pages === Math.floor(pages)) {
      last_page = pages;
    } else {
      last_page = 1 + Math.floor(pages);
    }
    if (last_page < 1) {
      last_page = 1;
    }
    return last_page;
  };
  Page.prototype.first = function() {
    if (this._total_entries === 0) {
      return 0;
    } else {
      return ((this._current_page - 1) * this._entries_per_page) + 1;
    }
  };
  Page.prototype.last = function() {
    if (this._current_page === this.last_page()) {
      return this._total_entries;
    } else {
      return this._current_page * this._entries_per_page;
    }
  };
  Page.prototype.previous_page = function() {
    if (this._current_page > 1) {
      return this._current_page - 1;
    } else {
      return null;
    }
  };
  Page.prototype.next_page = function() {
    if (this._current_page < this.last_page()) {
      return this._current_page + 1;
    } else {
      return null;
    }
  };
  Page.prototype.splice = function(array) {
    var top;
    if (array.length > this.last()) {
      top = this.last();
    } else {
      top = array.length;
    }
    if (top === 0) {
      return [];
    }
    return array.slice(this.first() - 1, top);
  };
  Page.prototype.skipped = function() {
    var skipped;
    skipped = this.first() - 1;
    if (skipped < 0) {
      return 0;
    } else {
      return skipped;
    }
  };
  Page.prototype.entries_on_this_page = function() {
    if (this._total_entries === 0) {
      return 0;
    } else {
      return this.last() - this.first() + 1;
    }
  };
  return Page;
})();
Data.Page.VERSION = "0.02";