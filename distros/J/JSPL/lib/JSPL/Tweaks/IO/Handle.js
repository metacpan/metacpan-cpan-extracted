// Sys.say("Loading tweaks for IO::Handle:"+ this.__PACKAGE__);
({
    'fieldSeparator': " ",
    'recordSeparator': "\n",
    'print': function() {
	    var exp = [];
	    for(var i = 0; i < arguments.length; i++) {
		if(arguments[i] instanceof Array) {
		    Array.prototype.push.apply(exp, arguments[i]);
		} else {
		    exp.push(arguments[i]);
		}
	    }
	    var printer = this['&print'] || this.__proto__.__proto__.print;
	    printer.call(this, exp.join(this.fieldSeparator) + this.recordSeparator);
	},
    'read': new PerlSub(
	'my($fd, $len) = @_; my $buf; $len ||= 4096; read($fd, $buf, $len); $buf'
	),
    'readLine': new PerlSub(
	'my($self, $sep) = @_; local $/ = $sep || JSPL->_this->{recordSeparator}; $self->getline'
	),
    'readWhole': new PerlSub(
	'local $/ = undef; $_[0]->getline'
	),
})
