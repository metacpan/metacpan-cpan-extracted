package Fry::Config::YAML;
use YAML ();	

sub setup {}
sub read {
	my ($class,$file) = @_;	
	return YAML::LoadFile($file) || {}
}
1;

__END__	

=head1 NAME

Fry::Config::YAML - Fry::Shell Config plugin which uses YAML.

=head1 AUTHOR

Me. Gabriel that is.  I welcome feedback and bug reports to cldwalker AT chwhat DOT com .  If you
like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.


=head1 COPYRIGHT & LICENSE

Copyright (c) 2004, Gabriel Horner. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
