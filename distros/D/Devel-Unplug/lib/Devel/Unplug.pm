package Devel::Unplug;

use warnings;
use strict;

=head1 NAME

Devel::Unplug - Simulate the non-availability of modules

=head1 VERSION

This document describes Devel::Unplug version 0.03

=cut

use vars qw($VERSION @ISA);

$VERSION = '0.03';

=head1 SYNOPSIS

    $ perl -d:Unplug=Some::Module,Some::Other::Module myprog.pl
    Can't locate Some/Module.pm in @INC (unplugged by Devel::Unplug) at myprog.pl line 5.
    BEGIN failed--compilation aborted at myprog.pl line 5.
  
=head1 DESCRIPTION

Sometimes - particularly during testing - it's useful to be able to find
out how your code behaves when a module it is expecting is unavailable.
This module allows you to simulate the non-availability of a module.

It uses L<Devel::TraceLoad::Hook> to replace C<require> (and hence
C<use>) and intercept attempts to load modules.

=cut

sub _get_module {
    my $file = shift;
    $file =~ s{/}{::}g;
    $file =~ s/[.]pm$//;
    return $file;
}

my %unplugged;

sub _is_unplugged {
    my $module = shift;

    for my $unp ( unplugged() ) {
        return 1
          if ( 'Regexp' eq ref $unp )
          ? $module =~ $unp
          : $module eq $unp;
    }

    return;
}

=head1 INTERFACE 

None of these functions are exportable. Call them using their fully qualified names.

=head2 C<< unplug >>

Unplug one or more modules.

    Devel::Unplug::unplug( 'Some::Module', 'Some::Other::Module' );

Regular expressions may be used:

    Devel::Unplug::unplug( qr{^Some:: (?: Other:: )? Module$}x );

=cut

sub unplug {
    for my $unp ( @_ ) {
        exists $unplugged{$unp} and $unplugged{$unp}->[1]++
          or $unplugged{$unp} = [ $unp, 1 ];
    }
    return;
}

=head2 C<< insert >>

Make an unplugged module available again.

    Devel::Unplug::insert( 'Some::Module' );

You must call C<insert> for a given module as many times as C<unplug>
was called to make it available again.

=cut

sub insert {
    for my $mod ( @_ ) {
        delete $unplugged{$mod}
          if exists $unplugged{$mod} && 0 == --$unplugged{$mod}->[1];
    }
    return;
}

BEGIN {
    use Devel::TraceLoad::Hook qw( register_require_hook );
    register_require_hook(
        sub {
            my ( $when, $depth, $arg, $p, $f, $l, $rc, $err ) = @_;

            return unless $when eq 'before';
            my $module = _get_module( $arg );
            return unless _is_unplugged( $module );

            # Ain't gonna let you load it
            die "Can't locate $arg in \@INC (unplugged by " . __PACKAGE__ . ")";
        }
    );
}

=head2 C<< unplugged >>

Get the list of unplugged modules. The returned array may potentially
contain a mixture of regular expressions and plain strings.

=cut

sub unplugged {
    map { $_->[0] } values %unplugged;
}

sub import {
    my $class = shift;
    unplug( @_ );
}

1;
__END__

=head1 DIAGNOSTICS

=over

=item C<< Can't locate %s in @INC (unplugged by Devel::Unplug) >>

The error message that will be displayed when an attempt is made to load
a module that has been unplugged.

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Devel::Unplug requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-devel-unplug@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 TRIVIA

The 'unplug' name and the choice of C<unplug> and C<insert> as the
function names is based on the Acorn RISC OS commands of the same name.
I'm sure you were wondering.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
