package File::Find::Wanted;

=head1 NAME

File::Find::Wanted - More obvious wrapper around File::Find

=head1 VERSION

Version 1.00

=cut

our $VERSION = '1.00';

use strict;
use File::Find;

our @ISA = qw( Exporter );
our @EXPORT = qw( find_wanted );

=head1 SYNOPSIS

File::Find is a great module, except that it doesn't actually find
anything.  Its C<find()> function walks a directory tree and calls
a callback function.  Unfortunately, the callback function is
deceptively called C<wanted>, which implies that it should return
a boolean saying whether you want the file.  That's not how it
works.

Most of the time you call C<find()>, you just want to build a list
of files.  There are other modules that do this for you, most notably
Richard Clamp's great L<File::Find::Rule>, but in many cases, it's
overkill, and you need to learn a new syntax.

With the C<find_wanted> function, you supply a callback sub and a
list of starting directories, but the sub actually should return a
boolean saying whether you want the file in your list or not.

To get a list of all files ending in F<.jpg>:

    my @files = find_wanted( sub { -f && /\.jpg$/ }, $dir );

For a list of all directories that are not F<CVS> or F<.svn>:

    my @files = find_wanted( sub { -d && !/^(CVS|\.svn)$/ }, $dir ) );

It's easy, direct, and simple.

=head1 WHY DO THIS?

The cynical may say "that's just the same as doing this":

    my @files;
    find( sub { push @files, $File::Find::name if -f && /\.jpg$/ }, $dir );

Sure it is, but File::Find::Wanted makes it more obvious, and saves
a line of code.  That's worth it to me.  I'd like it if find_wanted()
made its way into the File::Find distro, but for now, this will do.

=head1 FUNCTIONS

=head2 find_wanted( I<&wanted>, I<@directories> )

Descends through I<@directories>, calling the I<wanted> function as
it finds each file.  The function returns a list of all the files and
directories for which the I<wanted> function returned a true value.

This is just a wrapper around C<File::Find::find()>.  See L<File::Find>
for details on how to modify its behavior.

=cut

sub find_wanted {
    my $func = shift;
    my @files;

    local $_;
    find( sub { push @files, $File::Find::name if &$func }, @_ );

    return @files;
}

=head1 COPYRIGHT & LICENSE

Copyright 2005-2012 Andy Lester.

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License v2.0.

=cut

1;
