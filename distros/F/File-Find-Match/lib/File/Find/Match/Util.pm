package File::Find::Match::Util;
require 5.008;
use strict;
use warnings;
use Carp;
use base 'Exporter';
use File::Basename ();

our $VERSION = '0.10';
our @EXPORT     = qw( );
our @EXPORT_OK  = qw( filename ext wildcard );

sub filename ($) {
    my $basename = shift or croak 'Usage: filename($basename)';
    
    return sub {
    	croak "filename() predicate passed undef filename!" if not defined $_[0];
        File::Basename::basename($_[0]) eq $basename;
    };
}

sub ext ($) {
	my $ext = shift or croak 'Usage: ext($extension)';

	return sub {
		my $s = shift or croak "predicate ext($ext) called with bad arguments";
		substr($s, rindex($s, '.') + 1) eq $ext;
	};
}

sub wildcard ($) {
	my $pat = shift or croak 'Usage: wildcard($pattern)';
	my $re = quotemeta $pat;
	$re =~ s/\\\*/(.+)/g;
	my $regex = qr/$re/;
	return sub {
		$_[0] =~ $regex;
	};
}


1;
__END__

=head1 NAME

File::Find::Match::Util - Some exportable utility functions for writing rulesets.

=head1 SYNOPSIS

   use File::Find::Match::Util qw( filename );

   $pred = filename('foobar.pl');

   $pred->('foobar.pl')         == 1;
   $pred->('baz/foobar.pl')     == 1;
   $pred->('baz/bar/foobar.pl') == 1;
   $pred->('bazquux.pl')        == 0;

   $pred = ext('pm');

   $pred->('foo.pm')  == 1;
   $pred->('foo.png') == 0;
   $pred->('foo.pmg') == 0;

   $pred = wildcard('*.pod');
   $pred->('foo.pod')     == 1;
   $pred->('foo/bar.pod') == 1;
   $pred->('foo/.pod')    == 1;
   $pred->('Spoon')       == 0;
   
     
=head1 DESCRIPTION

This provides a few handy functions which create predicates
for L<File::Find::Match>.


=head1 FUNCTIONS

The following functions are available for export.

=head2 filename($basename)
  
This function returns a subroutine reference, which takes one argument $file
and returns true if C<File::Basename::basename($file) eq $basename>, false otherwise.
See C<File::Basename> for details.

Essentially, C<filename('foobar')> is equivalent to:

  sub { File::Basename::basename($_[0]) eq 'foobar' }

=head2 ext($extension)

This function returns a subroutine reference, which takes argument $file
and returns true if it ends with C<".$extension">.

=head2 wildcard($pattern)

Perform shell-like wildcard matching.
Currently only * is supported.
* is exactly equivelent to regexp .+, which is possibly incorrect.

Patches are welcome.

=head1 EXPORTS

None by default. 

L</filename($basename)>, L</ext($extension)>, L</wildcard($pattern)>.

=head1 BUGS

None known. Bug reports are welcome. 

Please use the CPAN bug ticketing system at L<http://rt.cpan.org/>.
You can also mail bugs, fixes and enhancements to 
C<< <bug-file-find-match >> at C<< rt.cpan.org> >>.

=head1 CREDITS

Thanks to Andy Wardly for the name, and the Template Toolkit list for inspiration.

=head1 AUTHOR

Dylan William Hardison E<lt>dhardison@cpan.orgE<gt>

L<http://dylan.hardison.net/>

=head1 SEE ALSO

L<File::Find::Match>, L<File::Find>, L<perl(1)>.

=head1 COPYRIGHT and LICENSE

Copyright (C) 2004 Dylan William Hardison.  All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
