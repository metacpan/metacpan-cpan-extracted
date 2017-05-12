
var FroodyDocFormatter = function() {
  this.output    = "";
  this.listLevel = 0;
};

FroodyDocFormatter.prototype = {
  toString: function() {
    if (this.listLevel)
      throw Error("unclosed list!");

    return this.output;
  },

  head1: function(title) { return this.head(1,title); },
  head2: function(title) { return this.head(2,title); },

  nodeName: function(node) {
    if (node.nodeKind() == "text")
      return "text";
    else
      return node.localName();
  },

  collapseTextNode: function(node) {
    var text;
    if (typeof node == "string")
      text = node;
    else if (node.nodeKind() == 'text')
      text = node.toString();
    else
      text = node.text().toString();
    return text.replace(/\s+/g, " ");
  },

  text: function(node) { return this.para(this.collapseTextNode(node)); },
  pre:  function(node) { return this.code(node); },
  p: function(node) { return this.para(node); },
  
  ul: function(node) {
    this.beginList();
    for each (var child in node.*) {
      this[child.name()](child);
    }
    this.endList();
    return this;
  },

  li: function(node) {
    if (node.hasSimpleContent()) {
      return this.listItem().para(node);
    }
    
    /* Special case. if the li looks similar to the following:

          <li>Rotate( angle = 90 )
            <p>rotates an image by an angle (in degrees), must be a multiple
            of 90.</p>
          </li>
    
      then the initial text node: "Rotate( angle = 90 )" wants to be the title of the list item
    */
    var first = true;
    for each (var child in node.*) {
      if (first) {
        first = false;
        if (child.nodeKind() == "text") {
          this.listItem(child);
          continue;
        } else {
          this.listItem();
        }
      }

      this[this.nodeName(child)](child);
    }
    return this;
  },

  processXHTML: function(node) {

    this[this.nodeName(node)](node);
  },

};

var PodFormatter = function(apiName) {
  this.head1("NAME").para(apiName);

}

PodFormatter.prototype = {

  __proto__: new FroodyDocFormatter(),
  
  head: function(level, title) {
    this.output += "=head" + level + " " + title + "\n\n";
    return this;
  },

  para: function(node) { 
    if (typeof node == "string" || node.hasSimpleContent()) {
      // contains only text - no other markup
      this.output += this.collapseTextNode(node);
    } else {
      var para = "";
      for each (var child in node.children()) {
        var name = this.nodeName(child);
        println(name);
        switch (name) {
          case 'text':
            println("'" + this.collapseTextNode(child) + "'");
            para += this.collapseTextNode(child);
            break;
          case 'em':
          case 'i':
            para += 'I<< ' + this.collapseTextNode(child) + ' >>'; 
            break;
          default:
            throw new Error("Unhandled node type '"+name +"' in a paragrph: " + node);
        };
      }
      this.output += para;
    }

    this.output += "\n\n";
    return this;
  },

  beginList: function() {
    this.output += "=over\n\n";
    this.listLevel++;
    return this;
  },

  endList: function() {
    if (--this.listLevel < 0)
      throw Error("endList when no list open - idjot");

    this.output += "=back\n\n";
    return this;
  },

  listItem: function(title) {
    if (!title) 
      title = "";
    this.output += "=item " + title + "\n\n";
    return this;
  },

  code: function(text) {
    this.output += "\n" + "  " +text.split(/\n/).join("\n  ") + "\n\n";
    return this;
  },

  processFroodyXML: function (xmlString) {
    var xml = new XML( xmlString.replace(/^<\?xml.*?>/, '') );
    XML.ignoreWhitespace = false;

    this.head1("METHODS");

    for each (var method in xml.methods.method ) {

      this.head2(method.@name);

      var text = method.description.text().toString();

      text = text.replace(/&/g, "&#38;");
      var desc = new XML("<desc>" + text + "</desc>");

      for each (var item in desc.*) {
        this.processXHTML(item);
      }

      this.head(3, "Arguments");
      if (method.arguments.length()) {
        this.beginList();
        for each (var arg in method.arguments.argument) {
          this.listItem(arg.@name + (arg.@optional == 1 ? ' (optional)' : ''))
              .para(this.collapseTextNode(arg.text()));
        }
        this.endList();
      } else {
        this.para("None.");
      }

      this.head(3, "Response")
          .code(method.response.toXMLString());

      if (method.errors.length()) {
        this.head(3, "Errors")
            .beginList();
        for each (var err in method.errors.error) {
          this.listItem(err.@code + " - " + err.@message);
          if (err.text().length())
             this.para(this.collapseTextNode(err.text().toXMLString()));
        }
        this.endList();
      }
    } // End of for each method in methods
    return this;
  }


};

var WikyFormatter = function() {}
WikyFormatter.prototype = {

  __proto__: new FroodyDocFormatter(),
  
  head: function(level, title) {
    var banner = "";
    for (var i =0; i < level; i++)
      banner += "=";
    this.output += banner + " " + title + " " + banner + "\n\n";
    return this;
  },

  para: function(node) { 
    if (typeof node == "string" || node.hasSimpleContent()) {
      // contains only text - no other markup
      this.output += this.collapseTextNode(node);
    } else {
      var para = "";
      for each (var child in node.children()) {
        var name = this.nodeName(child);
        println(name);
        switch (name) {
          case 'text':
            println("'" + this.collapseTextNode(child) + "'");
            para += this.collapseTextNode(child);
            break;
          case 'em':
          case 'i':
            para += '_' + this.collapseTextNode(child) + '_'; 
            break;
          default:
            throw new Error("Unhandled node type '"+name +"' in a paragrph: " + node);
        };
      }
      this.output += para;
    }

    this.output += "\n\n";
    return this;
  },

  beginList: function() {
    this.listLevel++;
    return this;
  },

  endList: function() {
    if (--this.listLevel < 0)
      throw Error("endList when no list open - idjot");

    return this;
  },

  listItem: function(title) {
    if (!title) 
      title = "";
    this.output += "* " + title + "\n\n";
    return this;
  },

  code: function(text) {
    this.output += "[%\n" + text + "\n%]\n\n";
    return this;
  },

  processFroodyXML: function (xmlString) {
    var xml = new XML( xmlString.replace(/^<\?xml.*?>/, '') );
    XML.ignoreWhitespace = false;

    for each (var method in xml.methods.method ) {

      this.head1(method.@name);

      var text = method.description.text().toString();

      text = text.replace(/&/g, "&#38;");
      var desc = new XML("<desc>" + text + "</desc>");

      for each (var item in desc.*) {
        this.processXHTML(item);
      }

      this.head2("Arguments");
      if (method.arguments.length()) {
        var para = "[|Name|Type|Description|Required|";
        for each (var arg in method.arguments.argument) {
          para += ["\n",arg.@name, 
                   (arg.@type.length() ? arg.@type : "string"), 
                   this.collapseTextNode(arg.text()),
                   (arg.@optional == "1" ? 'optional' : 'required'),
                   ""
                  ].join('|');
        }
        this.output += para + "]\n\n";
      } else {
        this.para("None.");
      }

      this.head2("Response")
          .code(method.response.toXMLString());

      if (method.errors.length()) {
        this.head2( "Errors")
            .beginList();
        for each (var err in method.errors.error) {
          var txt = "*" + err.@code + "* - " + err.@message;
          if (err.text().length())
             txt += "\\\\\n\\\\\n"+this.collapseTextNode(err.text().toXMLString());
          this.listItem(txt);
        }
        this.endList();
      }
    } // End of for each method in methods
    return this;
  }

};



