package File::Which::Cached;
use strict;
use File::Which();
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %_cache);
@ISA = qw/ Exporter /;
$VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;
@EXPORT_OK = ('which');

sub which {
   (! defined $_[0] )
      ? croak('missing arg to File::Which::Cached::which()')
      : $_cache{$_[0]} ||= File::Which::which($_[0]);
}

1;

__END__

=pod

=head1 NAME

File::Which::Cached - faster subsequent which lookups

=head1 SYNOPSIS

   use File::Which::Cached 'which';   
   my $perl_bin = which('perl');

   use File::Which::Cached;
   my $perl_bin = File::Which::Cached::which('perl');

=head1 DESCRIPTION

This is a wrapper around File::Which that caches results to a package symbol.
If you have a sub or method that makes multiple calls to which, and maybe the
same executable lookup, you may want to do this.

File::Which does not cache results in the package. That means that if you call 
which twice for the same executable, it performs twice.

This module will save the result, so that if your code is called to lookup an 
executable a thousand times, it takes just as long as one time.

This is desirable in iterations of many calls, etc.
In 2 thousand calls, we save one second.

=head1 SUBS

Not exported by default.

=head2 which()

Argument is name of executable, returs abs path to file.
Takes one argument at a time.
If you provide no argument, croaks.

=head1 SEE ALSO

L<File::Which>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 COPYRIGHT

Copyright (c) 2009 Leo Charre. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

