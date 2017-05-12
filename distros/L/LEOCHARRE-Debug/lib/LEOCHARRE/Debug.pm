package LEOCHARRE::Debug;
use strict;
use Carp;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;



sub import {
   my $caller = scalar(caller);
   no strict 'refs';
   no warnings;   

   # create the variable in caller, 
   # then get a ref to it for debug()
   ### $caller
   my $_flag = 0;
   *{"$caller\:\:DEBUG"} = \$_flag;

   *{"$caller\:\:debug"} = sub { 
      # my $subname = (caller(1))[3] || 'main::debug'; # seems like only reason is if debug() is used in main::debug, then shows  LEOCHARRE::Debug::__ANON__() , of course
      $_flag ? warn( sprintf "%s() @_\n", (caller(1))[3] || 'main::debug' ) : 1
   };
   *{"$caller\::warnf"} = sub { warn( sprintf "%s() @_", (caller(1))[3] || 'main::warnf') };

}







#3 at lib/LEOCHARRE/Debug.pm line 27.




1;

__END__

=pod

=head1 NAME

LEOCHARRE::Debug - debug sub

=head1 SYNOPSIS

   use LEOCHARRE::Debug;

   debug('hey there');

   warnf '%s %s %s\n', 'this', 'is', 'a value';

=head1 SUBS

Exported.

=head2 debug()

Arg is one or more strings to output, prepended with sub name.

=head2 warnf()

Works like 

   warn sprintf '', @args


=head1 CAVEATS

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=head1 LICENSE

This package is free software; you can redistribute it and/or modify it under the same terms as Perl itself, i.e., under the terms of the "Artistic License" or the "GNU General Public License".

=head1 DISCLAIMER

This package is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

See the "GNU General Public License" for more details.

=cut

