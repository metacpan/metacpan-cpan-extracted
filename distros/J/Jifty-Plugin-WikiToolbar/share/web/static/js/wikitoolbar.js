(function($){

  window.addWikiFormattingToolbar = function(textarea) {
    if ((document.selection == undefined)
     && (textarea.setSelectionRange == undefined)) {
      return;
    }

    var toolbar = document.createElement("div");
    toolbar.className = "wikitoolbar";

    function addButton(src, title, fn) {
      var image = document.createElement("img");
      image.width = 16;
      image.height = 16;
      image.src = src;
      image.border = 0;
      image.alt = title;
      image.title = title;
      image.style.cursor = "pointer";
      image.onclick = function() { try { fn() } catch (e) { } return false };
      toolbar.appendChild(image);
    }

    function encloseSelection(prefix, suffix) {
      textarea.focus();
      var start, end, sel, scrollPos, subst;
      if (document.selection != undefined) {
        sel = document.selection.createRange().text;
      } else if (textarea.setSelectionRange != undefined) {
        start = textarea.selectionStart;
        end = textarea.selectionEnd;
        scrollPos = textarea.scrollTop;
        sel = textarea.value.substring(start, end);
      }
      if (sel.match(/ $/)) { // exclude ending space char, if any
        sel = sel.substring(0, sel.length - 1);
        suffix = suffix + " ";
      }
      subst = prefix + sel + suffix;
      if (document.selection != undefined) {
        var range = document.selection.createRange().text = subst;
        textarea.caretPos -= suffix.length;
      } else if (textarea.setSelectionRange != undefined) {
        textarea.value = textarea.value.substring(0, start) + subst +
                         textarea.value.substring(end);
        if (sel) {
          textarea.setSelectionRange(start + subst.length, start + subst.length);
        } else {
          textarea.setSelectionRange(start + prefix.length, start + prefix.length);
        }
        textarea.scrollTop = scrollPos;
      }
    }

// overide this addButtons to design your own toolbar
    addButton('/static/img/wt/bold.png', "Bold text: \*\*Example\*\*", function() {
      encloseSelection('\*\*','\*\*');
    });
    addButton('/static/img/wt/italic.png', "Italic text: \_Example\_", function() {
      encloseSelection("\_", "\_");
    });
    addButton('/static/img/wt/empty.png', "", function() {
      encloseSelection("", "");
    });
    addButton('/static/img/wt/h1.png', "Title: Example\n=======", function() {
      encloseSelection("", "\n=======\n", "Title");
    });
    addButton('/static/img/wt/h2.png', "Sub title: Example\n-------", function() {
      encloseSelection("", "\n-------\n", "Sub title");
    });
    addButton('/static/img/wt/h3.png', "Sub sub title: ### Example ###", function() {
      encloseSelection("### ", " ###\n", "Sub sub title");
    });
    addButton('/static/img/wt/empty.png', "", function() {
      encloseSelection("", "");
    });
    addButton('/static/img/wt/link.png', "Link: [Some text](http://www.example.com/)", function() {
      encloseSelection("[", "](http://...)");
    });
    addButton('/static/img/wt/linkextern.png', "URL: <http://www.example.com/>", function() {
      encloseSelection("<", ">");
    });
    addButton('/static/img/wt/empty.png', "", function() {
      encloseSelection("", "");
    });
    addButton('/static/img/wt/ul.png', "List: - element 1", function() {
      encloseSelection("", "\n- element 1\n- element 2\n- element 3\n\n");
    });
    addButton('/static/img/wt/ol.png', "Ordered list: 1. element 1", function() {
      encloseSelection("", "\n1. element 1\n1. element 2\n1. element 3\n\n");
    });

    $(textarea).before(toolbar);
  }

})(jQuery);

// Add the toolbar to all <textarea> elements on the page with the class
// 'toolbar'.
/*jQuery(document).ready(function() {
  jQuery("textarea.toolbar").each(function() { addWikiFormattingToolbar(this) });
});*/

