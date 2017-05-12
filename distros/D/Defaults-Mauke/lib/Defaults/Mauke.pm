package Defaults::Mauke;

use warnings;
use strict;
use utf8;

use feature ();
no bareword::filehandles;
no indirect 0.16;
use Function::Parameters 1.06 qw(:strict);

use Carp qw(croak);

*VERSION = \'0.10';

method import($class: @args) {
    my $caller = caller;

    croak qq{"$_" is not exported by the $class module} for @args;


    strict->import;

    warnings->import;
    warnings->unimport(qw[recursion qw]);

    utf8->import;

    feature->import(':5.16');
    feature->unimport('switch');

    bareword::filehandles->unimport;

    indirect->unimport(':fatal');

    Function::Parameters->import(':strict');
}

1

__END__

=encoding UTF-8

=head1 NAME

Defaults::Mauke - load mauke's favorite modules

=head1 SYNOPSIS

 use Defaults::Mauke;
 
 ## equivalent to
 # use strict;
 # use warnings; no warnings qw[recursion qw];
 # use utf8;
 # use feature ':5.16'; no feature 'switch';
 # no bareword::filehandles;
 # no indirect qw(:fatal);
 # use Function::Parameters qw(:strict);

=head1 DESCRIPTION

I got tired of starting every Perl file I write with loading the same two or three
modules, so I wrote another module that does it for me. If you happen to like the
same set of default modules, feel free to use it; if you don't, maybe you can copy
and adapt the source.

=head1 SEE ALSO

L<strict>, L<warnings>, L<utf8>, L<perllexwarn>, L<bareword::filehandles>,
L<indirect>, L<Function::Parameters>.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 LICENSE

I put this code in the public domain. Do whatever you want with it.

=cut
