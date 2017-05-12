package Find::Lib;
use strict;
use warnings;
use lib;

use File::Spec();
use vars qw/$Base $VERSION @base/;
use vars qw/$Script/; # compat

=head1 NAME

Find::Lib - Helper to smartly find libs to use in the filesystem tree

=head1 VERSION

Version 1.01

=cut

$VERSION = '1.04';

=head1 SYNOPSIS

    #!/usr/bin/perl -w;
    use strict;

    ## simple usage
    use Find::Lib '../mylib';

    ## more libraries
    use Find::Lib '../mylib', 'local-lib';

    ## More verbose and backward compatible with Find::Lib < 1.0
    use Find::Lib libs => [ 'lib', '../lib', 'devlib' ];

    ## resolve some path with minimum typing
    $dir  = Find::Lib->catdir("..", "data");
    $path = Find::Lib->catfile("..", "data", "test.yaml");

    $base = Find::Lib->base;
    # or
    $base = Find::Lib::Base;

=head1 DESCRIPTION

The purpose of this module is to replace

    use FindBin;
    use lib "$FindBin::Bin/../bootstrap/lib";

with something shorter. This is specially useful if your project has a lot
of scripts (For instance tests scripts).

    use Find::Lib '../bootstrap/lib';

The important differences between L<FindBin> and L<Find::Lib> are:

=over 4

=item * symlinks and '..'

If you have symlinks in your path it respects them, so basically you can forget
you have symlinks, because Find::Lib will do the natural thing (NOT ignore
them), and resolve '..' correctly. L<FindBin> breaks if you do:

    use lib "$Bin/../lib";

and you currently are in a symlinked directory, because $Bin resolved to the
filesystem path (without the symlink) and not the shell path.

=item * convenience

it's faster too type, and more intuitive (Exporting C<$Bin> always
felt weird to me).

=back

=head1 DISCUSSION

=head2 Installation and availability of this module

The usefulness of this module is seriously reduced if L<Find::Lib> is not
already in your @INC / $ENV{PERL5LIB} -- Chicken and egg problem. This is
the big disavantage of L<FindBin> over L<Find::Lib>: FindBin is distributed
with Perl. To mitigate that, you need to be sure of global availability of
the module in the system (You could install it via your favorite package
managment system for instance).

=head2 modification of $0 and chdir (BEGIN blocks, other 'use')

As soon as L<Find::Lib> is compiled it saves the location of the script and
the initial cwd (current working directory), which are the two pieces of
information the module relies on to interpret the relative path given by the
calling program.

If one of cwd, $ENV{PWD} or $0 is changed before Find::Lib has a chance to do
its job, then Find::Lib will most probably die, saying "The script cannot be
found". I don't know a workaround that. So be sure to load Find::Lib as soon
as possible in your script to minimize problems (you are in control!).

(some programs alter $0 to customize the display line of the process in
the system process-list (C<ps> on unix).

(Note, see L<perlvar> for explanation of $0)

=head1 USAGE

=head2 import

All the work is done in import. So you need to C<'use Find::Lib'> and pass
a list of paths to add to @INC. See L<BACKWARD COMPATIBILITY> section for
more retails on this topic.

The paths given are (should) be relative to the location of the current script.
The paths won't be added unless the path actually exists on disk

=cut

use Carp();
use Cwd();

$Script = $Base = guess_base();

sub guess_base {
    my $base;
    $base = guess_shell_path();
    return $base if $base && -e $base;
    return guess_system_path();
}

## we want to use PWD if it exists (it's not guaranteed on all platforms)
## so that we have a sense of the shell current working dir, with unresolved
## symlinks
sub guess_pwd {
    return $ENV{PWD} || Cwd::cwd();
}

sub guess_shell_path {
    my $pwd = guess_pwd();
    my ($volume, $path, $file) = File::Spec->splitpath($pwd);
    my @path = File::Spec->splitdir($path);
    pop @path unless $path[-1];
    @base = (@path, $file);
    my @zero = File::Spec->splitdir($0);
    pop @zero; # get rid of the script
    ## a clean base is also important for the pop business below
    #@base = grep { $_ && $_ ne '.' } shell_resolve(\@base, \@zero);
    @base = shell_resolve(\@base, \@zero);
    return File::Spec->catpath( $volume, (File::Spec->catdir( @base )), '' );
}

## naive method, but really DWIM from a developer perspective
sub shell_resolve {
    my ($left, $right) = @_;
    while (@$right && $right->[0] eq '.') { shift @$right }
    while (@$right && $right->[0] eq '..') {
        shift @$right;
        ## chop off @left until we removed a significant path part
        my $part;
        while (@$left && !$part) {
            $part = pop @$left;
        }
    }

    return (@$left, @$right);
}

sub guess_system_path {
    my @split = (File::Spec->splitpath( File::Spec->rel2abs($0) ))[ 0, 1 ];
    return File::Spec->catpath( @split, '' );
}

sub import {
    my $class = shift;
    return unless @_;

    Carp::croak("The script/base dir cannot be found") unless -e $Base;

    my @libs;

    if ($_[0] eq 'libs') {
        if ($_[1] && ref $_[1] && ref $_[1] eq 'ARRAY') {
            ## backward compat mode;
            @libs = @{ $_[1] };
        }
    }
    @libs = @_ unless @libs;

    for ( reverse @libs ) {
        my @lib = File::Spec->splitdir($_);
        if (@lib && ! $lib[0]) {
            # '/abs/olute/' path
            lib->import($_);
            next;
        }
        my $dir = File::Spec->catdir( shell_resolve( [ @base ], \@lib ) );
        unless (-d $dir) {
            ## Try the old way (<0.03)
            $dir = File::Spec->catdir($Base, $_);
        }
        next unless -d $dir;
        lib->import( $dir );
    }
}

=head2 base

Returns the detected base (the directory where the script lives in). It's a
string, and is the same as C<$Find::Lib::Base>.

=cut

sub base { return $Base }

=head2 catfile

A shorcut to L<File::Spec::catfile> using B<Find::Lib>'s base.

=cut

sub catfile {
    my $class = shift;
    return File::Spec->catfile($Base, @_);
}

=head2 catdir

A shorcut to L<File::Spec::catdir> using B<Find::Lib>'s base.

=cut

sub catdir {
    my $class = shift;
    return File::Spec->catdir($Base, @_);
}

=head1 BACKWARD COMPATIBILITY

in versions <1.0 of Find::Lib, the import arguments allowed you to specify
a Bootstrap package. This option is now B<removed> breaking backward
compatibility. I'm sorry about that, but that was a dumb idea of mine to
save more typing. But it saves, like, 3 characters at the expense of
readability. So, I'm sure I didn't break anybody, because probabaly no one
was relying on a stupid behaviour.

However, the multiple libs argument passing is kept intact: you can still
use:

    use Find::Lib libs => [ 'a', 'b', 'c' ];


where C<libs> is a reference to a list of path to add to C<@INC>.

The short forms implies that the first argument passed to import is not C<libs>
or C<pkgs>. An example of usage is given in the SYNOPSIS section.


=head1 SEE ALSO

L<FindBin>, L<FindBin::libs>, L<lib>, L<rlib>, L<local::lib>
L<http://blog.cyberion.net/2009/10/ive-done-something-bad-i-broke-backward-compatibility.html>

=head1 AUTHOR

Yann Kerherve, C<< <yann.kerherve at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-find-lib at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Find-Lib>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENT

Six Apart hackers nourrished the discussion that led to this module creation.

Jonathan Steinert (hachi) for doing all the conception of 0.03 shell expansion
mode with me.

=head1 SUPPORT & CRITICS

I welcome feedback about this module, don't hesitate to contact me regarding this
module, usage or code.

You can find documentation for this module with the perldoc command.

    perldoc Find::Lib

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Find-Lib>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Find-Lib>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Find-Lib>

=item * Search CPAN

L<http://search.cpan.org/dist/Find-Lib>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007, 2009 Yann Kerherve, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
