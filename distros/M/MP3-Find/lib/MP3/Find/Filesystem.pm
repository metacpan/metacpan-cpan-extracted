package MP3::Find::Filesystem;

use strict;
use warnings;

use base 'MP3::Find::Base';

use File::Find;
use MP3::Info;
use Scalar::Util qw(looks_like_number);

use MP3::Find::Util qw(get_mp3_metadata);

eval {
    require Sort::Key;
    Sort::Key->import(qw(multikeysorter));
    require Sort::Key::Natural;
};
my $USE_SORT_KEY = $@ ? 0 : 1;


eval { require MP3::Tag };
my $CAN_USE_ID3V2 = $@ ? 0 : 1;

use_winamp_genres();

sub search {
    my $self = shift;
    my ($query, $dirs, $sort, $options) = @_;
    
    # prep the search patterns as regexes
    foreach (keys(%$query)) {
        my $ref = ref $$query{$_};
        # make arrays into 'OR' searches
        if ($ref eq 'ARRAY') {
            $$query{$_} = '(' . join('|', @{ $$query{$_} }) . ')';
        }
        # convert to a regex unless it already IS a regex        
        unless ($ref eq 'Regexp') {
            $$query{$_} = "^$$query{$_}\$" if $$options{exact_match};
            $$query{$_} = $$options{ignore_case} ? qr[$$query{$_}]i : qr[$$query{$_}];
        }
    }
    
    if ($$options{exclude_path}) {
        my $ref = ref $$options{exclude_path};
        if ($ref eq 'ARRAY') {
            $$options{exclude_path} = '(' . join('|', @{ $$options{exclude_path} }) . ')';
        }
        unless ($ref eq 'Regexp') {
            $$options{exclude_path} = qr[$$options{exclude_path}];
        }
    }
    
    if ($$options{use_id3v2} and not $CAN_USE_ID3V2) {
	# they want to use ID3v2, but don't have MP3::Tag
	warn "MP3::Tag is required to search ID3v2 tags\n";
    }
	
    # run the actual find
    my @results;
    find(sub { match_mp3($File::Find::name, $query, \@results, $options) }, $_) foreach @$dirs;
    
    # sort the results
    if (@$sort) {
	if ($USE_SORT_KEY) {
	    # use Sort::Key to do a (hopefully!) faster sort
	    #TODO: profile this; at first glance, it doesn't actually seem to be any faster
	    #warn "Using Sort::Key";
	    my $sorter = multikeysorter(
		sub { my $info = $_; map { $info->{uc $_} } @$sort },
		map { 'natural' } @$sort
	    );
	    @results = $sorter->(@results);
	} else {
	    @results = sort {
		my $compare;
		foreach (map { uc } @$sort) {
		    # use Scalar::Util to do the right sort of comparison
		    $compare = (looks_like_number($a->{$_}) && looks_like_number($b->{$_})) ?
			$a->{$_} <=> $b->{$_} :
			$a->{$_} cmp $b->{$_};
		    # we found a field they differ on
		    last if $compare;
		}
		return $compare;
	    } @results;
	}
    }
    
    return @results
}

sub match_mp3 {
    my ($filename, $query, $results, $options) = @_;
    
    return unless $filename =~ m{[^/]\.mp3$};
    if ($$options{exclude_path}) {
        return if $filename =~ $$options{exclude_path};
    }

    my $mp3 = get_mp3_metadata({
	filename  => $filename,
	use_id3v2 => $options->{use_id3v2},
    });

    for my $field (keys(%{ $query })) {
        my $value = $mp3->{uc($field)};
        return unless defined $value;
        return unless $value =~ $query->{$field};
    }
    
    push @{ $results }, $mp3;
}

# module return
1;

=head1 NAME

MP3::Find::Filesystem - File::Find-based backend to MP3::Find

=head1 SYNOPSIS

    use MP3::Find::Filesystem;
    my $finder = MP3::Find::Filesystem->new;
    
    my @mp3s = $finder->find_mp3s(
        dir => '/home/peter/music',
        query => {
            artist => 'ilyaimy',
            album  => 'myxomatosis',
        },
        ignore_case => 1,
    );

=head1 REQUIRES

L<File::Find>, L<MP3::Info>, L<Scalar::Util>

L<MP3::Tag> is also needed if you want to search using ID3v2 tags.

=head1 DESCRIPTION

This module implements the C<search> method from L<MP3::Find::Base>
using a L<File::Find> based search of the local filesystem.

=head2 Special Options

=over

=item C<exclude_path>

Scalar or arrayref; any file whose name matches any of these paths
will be skipped.

=item C<use_id3v2>

Boolean, defaults to false. If set to true, MP3::Find::Filesystem will
use L<MP3::Tag> to get the ID3v2 tag for each file. You can then search
for files by their ID3v2 data, using the four-character frame names. 
This isn't very useful if you are just search by artist or title, but if,
for example, you have made use of the C<TOPE> ("Orignal Performer") frame,
you could search for all the cover songs in your collection:

    $finder->find_mp3s(query => { tope => '.' });

As with the basic query keys, ID3v2 query keys are converted to uppercase
internally.

=back

=head1 SEE ALSO

L<MP3::Find>, L<MP3::Find::DB>

=head1 AUTHOR

Peter Eichman <peichman@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by Peter Eichman. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
