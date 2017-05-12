package Fry::ShellI;
use strict;
#here mainly for plugins like readline
use base 'Fry::Base';

#subs
	sub call { my ($cls,$core,$method) = splice(@_,0,3); $cls->$core->$method(@_) }

	#general
	sub List ($$) {shift->${\$_[0]}->listIds }
	sub listAll ($$) { shift->${\$_[0]}->listAliasAndIds }

	sub saveArray ($@) {shift->setVar(lines=>[@_]) }
	sub varMany ($@) { return shift->var->getMany('value',@_) }  
	sub requireLibraries ($@) { shift->lib->requireLibraries(@_) }

1;
__END__	

=head1 NAME

Fry::ShellI - Extended Fry::Shell interface to be used by libraries and plugins as needed.

=head1 DESCRIPTION 

The public methods of this class are mainly used in library classes. Since this module inherits from
Fry::Base, some of its methods are also encouraged to be used in libraries. These methods are
dumper,view,Var,setVar and listCore as well as the Plugin-related methods. See their documentation
in Fry::Base. 

A word about using methods from a core class, don't rely too heavily on them since
core classes and their methods may change.  Also, don't use core class accessors directly in a
library.

	$cls->lib->initLibs($lib) 

Instead, you should use &call

	$cls->call(lib=>'initLibs',$lib);

=head1 PUBLIC METHODS

	call($core_class,$method): Calls a core class's method to call the library class's &unloadLib:

		call(lib=>'unloadLib',@args);

	List($core_class): Returns list of object ids for given core class. Wrapper around a core class's &listIds.
	listAll($core_class): Returns list of object ids and their aliases for core class. Wrapper around a core class's &listAliasAndIds.
	saveArray(@value): Sets the lines variable to the given array. Used with the menu option.
	varMany(@var): Gets several variable values.
	requireLibraries(@libs): Loads libraries if they're not loaded.

	Note: Valid core classes are the core class accessors in Fry::Base.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
