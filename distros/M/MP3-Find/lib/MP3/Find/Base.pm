package MP3::Find::Base;

use strict;
use warnings;

use Carp;

my %format_codes = (
    a => 'ARTIST',
    t => 'TITLE',
    b => 'ALBUM',
    n => 'TRACKNUM',
    y => 'YEAR',
    g => 'GENRE',
);

sub new {
    my $invocant = shift;
    my $class = ref $invocant || $invocant;
    my %options = @_;
    my $self = \%options;
    bless $self, $class;
}

sub find_mp3s {
    my $self = shift;
    my %opt = @_;
    
    my $dir = $opt{dir} || $ENV{HOME};
    my @DIRS = ref $dir eq 'ARRAY' ? @$dir : ($dir);
    
    my %QUERY = %{ $opt{query} || {} };
    
    # array ref for multiple sort fields, but allow
    # a simple scalar for single values
    my @SORT = $opt{sort} ? 
        (ref $opt{sort} eq 'ARRAY' ? @{ $opt{sort} } : ($opt{sort})) :
        ();
    
    foreach (keys %QUERY) {
        if (defined $QUERY{$_}) {
            # package everything uniformly, so subclasses don't need to unpack it
            $QUERY{$_} = [ $QUERY{$_} ] unless ref $QUERY{$_} eq 'ARRAY';
        } else {
            # so we don't have spurious warnings when trying to match against undef        
            delete $QUERY{$_};
        }
    }
    
    # do the search
    my @results = $self->search(\%QUERY, \@DIRS, \@SORT, \%opt);
    
    # maybe they want the unformatted data
    return @results if $opt{no_format};
    
    if ($opt{printf}) {
        # printf style output format
        foreach (@results) {
            my $output = $opt{printf};
            for my $code (keys %format_codes) {
                
                while ($output =~ m/%((-\d)?\d*)$code/g) {
                    # field size modifier
                    my $modifier = $1 || '';
                    # figure out the size of the formating code
                    my $code_size = 2 + length($modifier);
                    my $value = sprintf("%${modifier}s", $_->{$format_codes{$code}} || '');
                    substr($output, pos($output) - $code_size, $code_size, $value);
                }
            }
            # to allow literal '%'
            $output =~ s/%%/%/g;        
            $_ = $output;
        }
    } else {
        # just the filenames, please
        @results = map { $_->{FILENAME} } @results;
    }
    
    return @results;
}

sub search {
    croak "Method 'search' not implemented in " . __PACKAGE__;
}

# module return
1;

=head1 NAME

MP3::Find::Base - Base class for MP3::Find backends

=head1 SYNOPSIS

    package MyFinder;
    use base 'MP3::Find::Base';
    
    sub search {
        my $self = shift;
        my ($query, $dirs, $sort, $options) = @_;
        
        # do something to find and sort the mp3s...
        my @results = do_something(...);
        
        return @results;
    }
    
    package main;
    my $finder = MyFinder->new;
    
    # see MP3::Find for details about %options
    print "$_\n" foreach $finder->find_mp3s(\%options);        

=head1 DESCRIPTION

This is the base class for the classes that actually do the
searching and sorting for L<MP3::Find>.

=head1 METHODS

=head2 new

Really simple constructor. If you pass it a hash of options, it
will hang on to them for you.

=head2 search

This is the one you should override in your subclass. If you
don't, the base class C<search> method will croak.

The C<search> method is called by the C<find_mp3s> method with
the following arguments: the finder object, a hashref of query
parameters, an arrayref of directories to search, and a hashref
of miscellaneous options.

The search method should return a list of hashrefs representing
the results of the search. Each hashref should have the following
keys (all except C<FILENAME> are derived from the keys returned
by the C<get_mp3tag> and C<get_mp3Info> functions from L<MP3::Info>):

    FILENAME
    
    TITLE
    ARTIST
    ALBUM
    YEAR
    COMMENT
    GENRE
    TRACKNUM
    
    VERSION         -- MPEG audio version (1, 2, 2.5)
    LAYER           -- MPEG layer description (1, 2, 3)
    STEREO          -- boolean for audio is in stereo
    
    VBR             -- boolean for variable bitrate
    BITRATE         -- bitrate in kbps (average for VBR files)
    FREQUENCY       -- frequency in kHz
    SIZE            -- bytes in audio stream
    OFFSET          -- bytes offset that stream begins
    
    SECS            -- total seconds
    MM              -- minutes
    SS              -- leftover seconds
    MS              -- leftover milliseconds
    TIME            -- time in MM:SS
    
    COPYRIGHT       -- boolean for audio is copyrighted
    PADDING         -- boolean for MP3 frames are padded
    MODE            -- channel mode (0 = stereo, 1 = joint stereo,
                    -- 2 = dual channel, 3 = single channel)
    FRAMES          -- approximate number of frames
    FRAME_LENGTH    -- approximate length of a frame
    VBR_SCALE       -- VBR scale from VBR header


=head2 find_mp3s

The method that should be called by the program doing the searching.

See L<MP3::Find> for an explanation of the options that can be passed
to C<find_mp3s>.

=head1 TODO

More format codes? Possibly look into using L<String::Format>

=head1 SEE ALSO

L<MP3::Find>, L<MP3::Find::Filesystem>, L<MP3::Find::DB>

See L<MP3::Info> for more information about the fields you can
search and sort on.

=head1 AUTHOR

Peter Eichman <peichman@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Peter Eichman. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
