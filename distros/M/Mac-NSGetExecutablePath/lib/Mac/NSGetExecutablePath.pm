package Mac::NSGetExecutablePath;

use 5.006;

use strict;
use warnings;

=head1 NAME

Mac::NSGetExecutablePath - Perl interface to the _NSGetExecutablePath darwin (OS X) system call.

=head1 VERSION

Version 0.03

=cut

our $VERSION;
BEGIN {
 $VERSION = '0.03';
}

=head1 SYNOPSIS

    sub get_perl_path {
     if ($^O eq 'darwin') {
      require Cwd;
      require Mac::NSGetExecutablePath;
      return Cwd::abs_path(Mac::NSGetExecutablePath::NSGetExecutablePath());
     } else {
      return $^X;
     }
    }

=head1 DESCRIPTION

This module provides a Perl interface to the C<_NSGetExecutablePath> darwin system call.
It will only build on darwin systems.

Note that if you are using L<perl> 5.16 or greater, then the value of C<$^X> is already computed from the return value of C<_NSGetExecutablePath>, making this module mostly irrelevant.

=cut

BEGIN {
 require XSLoader;
 XSLoader::load(__PACKAGE__, $VERSION);
}

=head1 FUNCTIONS

=head2 C<NSGetExecutablePath>

    my $path = NSGetExecutablePath();

Returns a string representing the path to the current executable.
This path may rightfully point to a symlink.

This function may throw exceptions, see L</DIAGNOSTICS> for details.

=head1 DIAGNOSTICS

=head2 C<NSGetExecutablePath() wants to return a path too large>

This exception is thrown when C<_NSGetExecutablePath> requires an outrageously large buffer to return the path to the current executable.

=head1 EXPORT

The function L</NSGetExecutablePath> is only exported on request, either individually or by the tags C<':funcs'> and C<':all'>.

=cut

use base qw<Exporter>;

our @EXPORT         = ();
our %EXPORT_TAGS    = (
 'funcs' => [ qw<NSGetExecutablePath> ],
);
our @EXPORT_OK      = map { @$_ } values %EXPORT_TAGS;
$EXPORT_TAGS{'all'} = [ @EXPORT_OK ];

=head1 DEPENDENCIES

L<perl> 5.6.

A C compiler.
This module may happen to build with a C++ compiler as well, but don't rely on it, as no guarantee is made in this regard.

L<Exporter> (core since perl 5), L<XSLoader> (since 5.6.0), L<base> (since 5.004_05).

=head1 SEE ALSO

C<dyld(3)>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-mac-nsgetexecutablepath at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Mac-NSGetExecutablePath>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Mac::NSGetExecutablePath

=head1 ACKNOWLEDGEMENTS

The implementation of this module is inspired by Nicholas Clark's work of adding this feature to perl 5.16.

=head1 COPYRIGHT & LICENSE

Copyright 2012,2013 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Mac::NSGetExecutablePath
