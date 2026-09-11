# PODNAME: Luv::CLI::Registry
# ABSTRACT: local cache of the awesome-love2d library list

use v5.38;
use Object::Pad;

use JSON::PP;
use File::Path qw(make_path);

class Luv::CLI::Registry;

field $cache_path : param;
field %entries;

method cache_path () { return $cache_path; }

method load () {
    return unless -e $cache_path;
    open my $fh, '<', $cache_path or die "Cannot read $cache_path: $!\n";
    local $/;
    my $data = JSON::PP->new->utf8->decode(<$fh>);
    close $fh;
    %entries = %{ $data->{entries} // {} };
    return;
}

method save () {
    File::Path::make_path( $self->cache_dir );
    open my $fh, '>', $cache_path or die "Cannot write $cache_path: $!\n";
    print {$fh} JSON::PP->new->utf8->canonical->pretty->encode(
        {   updated_at => time,
            entries    => \%entries,
        }
    );
    close $fh;
    return;
}

method cache_dir () {
    my ($dir) = $cache_path =~ m{^(.*)/[^/]+$};
    return $dir;
}

method is_stale ( $max_age_seconds = 86400 * 7 ) {
    return 1 unless -e $cache_path;
    return ( time - ( stat($cache_path) )[9] ) > $max_age_seconds;
}

method add_entry ( $name, %info ) {
    $entries{ lc $name } = {
        name        => $name,
        url         => $info{url},
        category    => $info{category},
        description => $info{description},
    };
    return;
}

method search ($term) {
    my @matches;
    for my $name ( keys %entries ) {
        push @matches, { name => $name, %{ $entries{$name} } }
            if $name =~ /\Q$term\E/i
            || ( $entries{$name}{description} // '' ) =~ /\Q$term\E/i;
    }
    return @matches;
}

method find ($name) {
    my ($match) = grep { lc($_) eq lc($name) } keys %entries;
    return $match ? $entries{$match} : undef;
}

method parse_readme ($markdown) {
    my $category = 'Uncategorized';

    for my $line ( split /\n/, $markdown ) {
        if ( $line =~ /^##\s+(.+)/ ) {
            $category = $1;
            next;
        }

        if ( $line =~ /^\s*[-*]\s*\[([^\]]+)\]\(([^)]+)\)\s*-\s*(.+)/ ) {
            my ( $name, $url, $description ) = ( $1, $2, $3 );
            $self->add_entry(
                $name,
                url         => $url,
                category    => $category,
                description => $description
            );
        }
    }

    return;
}

method refresh () {
    my $readme_url
        = 'https://raw.githubusercontent.com/love2d-community/awesome-love2d/master/README.md';

    require IPC::Run;
    my ( $out, $err );
    IPC::Run::run( [ 'curl', '-sL', $readme_url ], \undef, \$out, \$err )
        or die "Failed to fetch awesome-love2d README:\n$err";

    %entries = ();
    $self->parse_readme($out);
    $self->save;

    return scalar keys %entries;
}

method all_entries () {
    return values %entries;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Luv::CLI::Registry - local cache of the awesome-love2d library list

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    my $registry = Luv::CLI::Registry->new(cache_path => $path);
    $registry->refresh;
    my @matches = $registry->search('input');
    my $entry   = $registry->find('baton');

=head1 DESCRIPTION

Parses the C<awesome-love2d> README into a structured index of
libraries, caches it locally as JSON, and serves name/description
searches from that cache rather than re-fetching on every lookup.

=head1 NAME

Luv::CLI::Registry - local cache of the awesome-love2d library list

=head1 METHODS

=head2 cache_path()

Returns the path to the local cache file.

=head2 load()

Loads entries from the cache file, if present.

=head2 save()

Writes the current entries to the cache file as JSON.

=head2 cache_dir()

Returns the directory containing the cache file.

=head2 is_stale($max_age_seconds)

Returns true if the cache file is missing or older than
C<$max_age_seconds> (default one week).

=head2 add_entry($name, %info)

Adds or replaces an entry in the in-memory index. C<%info> may include
C<url>, C<category>, and C<description>.

=head2 search($term)

Returns a list of entries whose name or description matches C<$term>
(case-insensitive).

=head2 find($name)

Returns the entry for C<$name> (case-insensitive), or undef.

=head2 parse_readme($markdown)

Parses awesome-love2d-style markdown into entries, populating the
in-memory index.

=head2 refresh()

Fetches the current awesome-love2d README, parses it, and saves the
result to the cache. Returns the number of entries indexed.

=head2 all_entries()

Returns a list of every entry currently in the index.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Nobunaga <nobunaga@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Ogun.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
