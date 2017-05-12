package MP3::Find;

use strict;
use warnings;

use base qw(Exporter);
use vars qw($VERSION @EXPORT);

use Carp;

$VERSION = '0.07';

@EXPORT = qw(find_mp3s);

my $finder;
sub import {
    my $calling_pkg = shift;
    # default to a filesystem search
    my $finder_type = shift || 'Filesystem';
    my $package = "MP3::Find::$finder_type";
    eval "require $package";
    croak $@ if $@;
    $finder = $package->new;
    __PACKAGE__->export_to_level(1, @EXPORT);
}

sub find_mp3s { $finder->find_mp3s(@_) }


# module return
1;

=head1 NAME

MP3::Find - Search and sort MP3 files based on their ID3 tags

=head1 SYNOPSIS

    # select with backend you want
    use MP3::Find qw(Filesystem);
    
    print "$_\n" foreach find_mp3s(
        dir => '/home/peter/cds',
        query => {
            artist => 'ilyaimy',
            title => 'deep in the am',
        },
        ignore_case => 1,
        exact_match => 1,
        sort => [qw(year album tracknum)],
        printf => '%2n. %a - %t (%b: %y)',
    );

=head1 DESCRIPTION

This module allows you to search for MP3 files by their ID3 tags.
You can ask for the results to be sorted by one or more of those
tags, and return either the list of filenames (the deault), a
C<printf>-style formatted string for each file using its ID3 tags,
or the actual Perl data structure representing the results.

There are currently two backends to this module: L<MP3::Find::Filesystem>
and L<MP3::Find::DB>. You choose which one you want by passing its
name as the argument to you C<use> statement; B<MP3::Find> will look for
a B<MP3::Find::$BACKEND> module. If no backend name is given, it will
default to using L<MP3::Find::Filesystem>.

B<Note:> I'm still working out some kinks in the DB backend, so it
is currently not as stable as the Filesystem backend.

B<Note the second>: This whole project is still in the alpha stage, so
I can make no guarentees that there won't be significant interface changes
in the next few versions or so. Also, comments about what about the API
rocks (or sucks!) are appreciated.

=head1 REQUIRES

L<File::Find>, L<MP3::Info>, and L<Scalar::Util> are needed for
the filesystem backend (L<MP3::Find::Filesystem>). In addition,
if L<MP3::Tag> is available, you can search by explicit ID3v2
tag frames.

L<DBI>, L<DBD::SQLite>, and L<SQL::Abstract> are needed for the
database backend (L<MP3::Find::DB>).

=head1 EXPORTS

=head2 find_mp3s

    my @results = find_mp3s(%options);

Takes the following options:

=over

=item C<dir>

Arrayref or scalar; tell C<find_mp3s> where to start the search.
Directories in the arrayref are searched sequentially.

=item C<query>

Hashref of search parameters. Recognized fields are anything that
L<MP3::Info> knows about. Field names can be given in either upper
or lower case; C<find_mp3s> will convert them into upper case for 
you. Value may either be strings, which are converted into regular
exporessions, or may be C<qr/.../> regular expressions already.

=item C<ignore_case>

Boolean, default false; set to a true value to ignore case when
matching search strings to the ID3 tag values.

=item C<exact_match>

Boolean, default false; set to a true value to add an implicit
C<^> and C<$> around each query string. Does nothing if the query
term is already a regular expression.

=item C<sort>

What field or fields to sort the results by. Can either be a single
scalar field name to sort by, or an arrayref of field names. Again,
acceptable field names are anything that L<MP3::Info> knows about;
field names will be converted to upper case as with the C<query>
option.

=item C<printf>

By default, C<find_mp3s> just returns the list of filenames. The 
C<printf> option allows you to provide a formatting string to apply
to the data for each file. The style is roughly similar to Perl's
C<printf> format strings. The following formatting codes are 
recognized:

    %a - artist
    %t - title
    %b - album
    %n - track number
    %y - year
    %g - genre
    %% - literal '%'

Numeric modifers may be used in the same manner as with C<%s> in
Perl's C<printf>.

=item C<no_format>

Boolean, default false; set to a true value to have C<find_mp3s> to
return an array of hashrefs instead of an array of (formatted) strings.
Each hashref consists of the key-value pairs from C<MP3::Info::get_mp3_tag>
and C<MP3::Info::get_mp3_info>, plus the key C<FILENAME> (with the obvious 
value ;-)

    @results = (
        {
            FILENAME => ...,
            TITLE    => ...,
            ARTIST   => ...,
            ...
            SECS     => ...,
            BITRATE  => ...,
            ...
        },
        ...
    );

=back

=head1 BUGS

There are probably some in there; let me know if you find any (patches
welcome).

=head1 TODO

Better tests, using some actual sample mp3 files.

Other backends (a caching filesystem backend, perhaps?)

=head1 SEE ALSO

L<MP3::Find::Filesystem>, L<MP3::Find::DB>

L<mp3find> is the command line frontend to this module (it
currently only uses the filesystem backend).

L<mp3db> is a (currently rather barebones) command line 
frontend for creating and updating a SQLite database for 
use with L<MP3::Find::DB>.

See L<MP3::Info> for more information about the fields you can
search and sort on. See L<http://id3.org/> for information about
ID3v2 tags.

L<File::Find::Rule::MP3Info> is another way to search for MP3
files based on their ID3 tags.

=head1 AUTHOR

Peter Eichman <peichman@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Peter Eichman. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
