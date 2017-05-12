package Fry::Lib::Inspector;
#use Class::Handle;
use base 'Class::Inspector';
use strict;

#none of this is currently used
sub _default_data {
	return {
		class=>'Class::Inspector',	
		methods=>[qw/installed loaded filename resolved_filename functions methods/],
	}
}
1;

__END__	

=head1 NAME

Fry::Lib::Inspector - Autoloaded library for Class::Inspector's class methods.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
