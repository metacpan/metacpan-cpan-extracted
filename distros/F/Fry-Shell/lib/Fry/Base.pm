package Fry::Base;
use strict;
my ($varClass);

	my %core;
	sub _core { (@_ > 2) ? $core{$_[1]} = $_[2] : $core{$_[1]} }	
	sub listCore { keys %core }

	#core methods
	sub var ($) { __PACKAGE__->_core('var') }
	sub lib ($) { __PACKAGE__->_core('lib') }
	sub cmd ($) { __PACKAGE__->_core('cmd') }
	sub opt ($) { __PACKAGE__->_core('opt') }
	sub sub ($) { __PACKAGE__->_core('sub') }
	sub obj ($) { __PACKAGE__->_core('obj') }
	sub type ($) { __PACKAGE__->_core('type') }
	#sub err ($) { __PACKAGE__->_core('err') }

	#wrappers
	sub Sub ($) { shift->sub->call(@_) }
	sub setVar ($%) { shift->var->setMany('value',@_) }
	sub Var ($) { return  __PACKAGE__->var->Var($_[1])}
	sub Flag ($$) { __PACKAGE__->Var($_[1]) }
	sub setFlag ($$) { __PACKAGE__->var->setOrMake($_[1],$_[2]) }
	sub sh { return __PACKAGE__->var->get('shell_class','value') }

	#plugins
	sub view ($@) { shift->View->view(@_); }
	sub dumper ($@) { shift->Dump->dump(@_); }
	sub Caller ($) { return shift->Var('cmd_class') }
	sub Dump ($) { return shift->Var('plugin_dump') }
	sub View ($) { return shift->Var('plugin_view') }
	sub Rline ($) { return shift->Var('plugin_readline') }
	sub Config ($) { return shift->Var('plugin_config') }
	sub Error ($) { return __PACKAGE__->Var('plugin_error') }
1;
__END__	

=head1 NAME

Fry::Base - Base class providing minimal set of handy methods. Some used to communicate between
shell components and used to communicate between shell components.

=head1 DESCRIPTION 

This class provides a minimal set of handy methods made available to most Fry::* modules. Among
these is &var which contains the variable class.  The variable class facilitates communication
between classes since it contains almost all of the shell's configuration information.

=head1 PUBLIC METHODS

	Core class methods
		var: returns a shell's variable class
		lib: returns a shell's library class
		opt: returns a shell's option class
		sub: returns a shell's subroutine class
		cmd: returns a shell's command class
		obj: returns a shell's object class
		type: returns a shell's type class

	Methods wrapping around core classes' methods
		Sub: calls sub->call
		Var($var): gets variable value
		setVar(%var_to_value): sets variable value
		Flag($var): gets flag value
		setFlag(%var_to_value): sets flag value

	Plugin-related methods	
		Config: returns configuration plugin class
		Error: returns error plugin class
		Rline: returns readline plugin class
		View: returns view plugin class
		Dump: returns dump plugins class
		dumper: Calls dump plugin's &dump.
		view: Calls view plugin's &view. Recommended subroutine for printing output of a command.

	Other methods
		listCore: lists all core classes

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
