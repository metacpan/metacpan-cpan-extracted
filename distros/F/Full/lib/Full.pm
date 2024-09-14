package Full;

our $VERSION = '1.001';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use utf8;
1;
__END__

=encoding utf8

=head1 NAME

Full - simplify common boilerplate for Perl scripts and modules

=head1 SYNOPSIS

 # in your script
 use Full::Script;
 # use strict, warnings, utf8 etc. are all now applied and in scope
 # or in a module that provides a class:
 use Full::Class;
 field $example;
 method example_method { return $example }

=head1 DESCRIPTION

Perl has many modules and features, including some features which are somewhat discouraged
in recent code.

This module attempts to provide a good set of functionality for writing code without too
many lines of boilerplate. It has been extracted from L<Myriad::Class> so that it can be
used in other code without pulling in too many irrelevant dependencies.

For a list of Perl language features and modules applied by this,
please see:

=over 4

=item * L<Full::Pragmata> - base list

=item * L<Full::Class> - OO classes

=item * L<Full::Script> - C<.pl> scripts

=back

=head1 SEE ALSO

There are many modules which provide similar functionality. Here are a few examples, in no particular
order:

=over 4

=item * L<Modern::Perl>

=item * L<common::sense>

=back

=head1 AUTHOR

Original code can be found at https://github.com/deriv-com/perl-Myriad/tree/master/lib/Myriad/Class.pm,
by Deriv Group Services Ltd. C<< DERIV@cpan.org >>. This version has been split out as a way to provide
similar functionality.

=head1 LICENSE

Released under the same terms as Perl itself.

