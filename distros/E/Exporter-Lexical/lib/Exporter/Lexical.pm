package Exporter::Lexical;
BEGIN {
  $Exporter::Lexical::AUTHORITY = 'cpan:DOY';
}
{
  $Exporter::Lexical::VERSION = '0.02';
}
use strict;
use warnings;
use 5.018;
# ABSTRACT: exporter for lexical subs


use XSLoader;
XSLoader::load(
    __PACKAGE__,
    # we need to be careful not to touch $VERSION at compile time, otherwise
    # DynaLoader will assume it's set and check against it, which will cause
    # fail when being run in the checkout without dzil having set the actual
    # $VERSION
    exists $Exporter::Lexical::{VERSION}
        ? ${ $Exporter::Lexical::{VERSION} } : (),
);

sub import {
    my $package = shift;
    my %opts = @_;

    my $caller = caller;

    my $import = build_exporter(\%opts, $caller);

    {
        no strict 'refs';
        *{ $caller . '::import' } = $import;
    }
}


sub build_exporter {
    my ($opts, $caller) = @_;
    $caller //= caller;

    return sub {
        my $caller_stash = do {
            no strict 'refs';
            \%{ $caller . '::' };
        };
        my %exports;
        if (ref($opts->{'-exports'}) eq 'ARRAY') {
            %exports = map { $_ => \&{ $caller_stash->{$_} } }
                           @{ $opts->{'-exports'} };
        }
        elsif (ref($opts->{'-exports'}) eq 'HASH') {
            %exports = %{ $opts->{'-exports'} };
        }

        for my $export (keys %exports) {
            lexical_import($export, $exports{$export});
        }

        # XXX there is a bug with lexical_import where the pad entry sequence
        # numbers are incorrect when used with 'use', so the first statement
        # after the 'use' statement doesn't see the lexical. hack around this
        # for now by injecting a dummy statement right after the 'use'.
        _lex_stuff(";1;");
    };
}



1;

__END__

=pod

=head1 NAME

Exporter::Lexical - exporter for lexical subs

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  package My::Exporter;
  use Exporter::Lexical -exports => [ 'foo' ]
  sub foo { "FOO" }

  package MyApp;

  {
      use My::Exporter;
      warn foo(); # FOO
  }
  warn foo(); # Undefined subroutine &main::foo called

=head1 DESCRIPTION

This module allows you to export lexical subs from your exporter module. It is
implemented using the new C<lexical_subs> feature in perl 5.18, so the
functions truly are lexical (unlike some of the previous attempts).

This module is quite experimental, and may change a lot in the future as I
figure out how it should work. It is very much a proof of concept for the
moment.

This module takes a hash of C<import> args as configuration, with these keys:

=over 4

=item -exports

The value of this key can either be an arrayref, in which case the elements of
the arrayref will be treated as function names to look for in the current
package and export, or a hashref, in which case the keys will be function names
and the values will be coderefs.

=back

Importing this module will also install an C<import> method into your module,
which will handle the exporting process as configured by the import args.

=head1 FUNCTIONS

=head2 build_exporter(\%opts[, $caller])

  my $import Exporter::Lexical::build_exporter({
      -exports => ['foo'],
  });

This function just creates the method that it would install as your package's
C<import> method, without actually installing it. This lets you write your own
import method that does whatever you want it to do, while still being able to
export from it.

This function takes a hashref of arguments which correspond to the arguments
you would pass to C<import>, followed by an optional package name to get the
subs from, if you're exporting subs by name. The default is to get the subs
from the calling package.

=head2 lexical_import($name, $sub)

Installs C<$sub> as a lexical subroutine into the currently compiling lexical
scope. Throws an error if there is no currently compiling lexical scope (for
instance, if this is called at runtime).

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-exporter-lexical at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Exporter-Lexical>.

=head1 SEE ALSO

L<Sub::Exporter::Lexical>

L<Lexical::Import>

L<feature/The 'lexical_subs' feature>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Exporter::Lexical

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Exporter-Lexical>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Exporter-Lexical>

=item * Github

L<https://github.com/doy/exporter-lexical>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Exporter-Lexical>

=back

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
