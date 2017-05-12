# Copyright © 2009-2013 David Caldwell and Jim Radford.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.12.4 or,
# at your option, any later version of Perl 5 you may have available.

package File::HashCache; use warnings; use strict;

our $VERSION = '1.0.2';

use List::Util qw(max);
use Digest::MD5 qw(md5_hex);
use File::Basename;
use File::Slurp qw(read_file write_file);
use JSON qw(to_json from_json);

sub max_timestamp(@) { max map { (stat $_)[9] || 0 } @_ } # Obviously 9 is mtime

# DEPRECATED. This has been subsumed by the concatenation code--It's easier
# to deal with and doesn't make you use a weird dialect of Javscript in your
# code. **This is only here for backwards compatibility. Do Not Use.**
sub pound_include($;$);
sub pound_include($;$) {
    my ($text, $referrer) = @_;
    my ($line, @deps) = (0);
    return (join('', map { $line++;
                         $_ .= "\n";
                         if (/^#include\s+"([^"]+)"/) {
                             my $included = read_file(my $name=$1) or die "include '$1' not found".($referrer?" at $referrer\n":"\n");
                             ($_, my @new_deps) = pound_include($included, $name);
                             push @deps, $name, @new_deps;
                         }
                         $_;
                     } split(/\n/, $text)),
            @deps);
}

sub hash {
    my ($config, @name) = @_;

    my ($dir,@base,$ext);
    for my $name (@name) {
        my ($_base, $_dir, $_ext) = fileparse $name, qr/\.[^.]+/;
        $_ext =~ s/^\.//;
        $_ext eq ($ext //= $_ext) or die  "extentions should be the same when concatenating";
        $dir //= $_dir; # Not quite right but works in most cases.
        push @base, $_base;
    }
    my $base = join '-', @base;
    my $name = "$dir$base.$ext"; # canonical version of the name in the single case, and a merged version in the multiple case

    my $script;
    if (   !($script = $config->{cache}->{$name})
        || ! -f $script->{path}
        || max_timestamp(@{$script->{deps}}) > $script->{timestamp}) {

        my @deps = @name;
        my $processed = join("\n", map { scalar read_file($_) } @name);
        my $process_ext = $config->{"process_$ext"};
        for my $process (@{ref($process_ext) eq 'CODE' ? [$process_ext] : $process_ext}) {
            ($processed, my @new_deps) = $process->($processed);
            push @deps, @new_deps;
        }

        my $hash = md5_hex($processed);
        $config->{cache}->{$name} = $script = { deps => \@deps,
                                                name => "$base-$hash.$ext",
                                                path => "$config->{cache_dir}/$base-$hash.$ext",
                                                hash => $hash,
                                                timestamp => max_timestamp(@deps) };
        if (! -f $script->{path}) {
          mkdir $config->{cache_dir};
          write_file($script->{path},       { atomic => 1 }, $processed) or die "couldn't cache $script->{path}";
          write_file($config->{cache_file}, { atomic => 1 }, to_json($config->{cache}, {pretty => 1})) or warn "Couldn't save cache control file";
        }
    }
    $script->{name};
}

sub new {
    my $class = shift;
    my $config = bless { cache_dir => '.hashcache',
                         @_,
                       }, $class;
    $config->{cache_file} ||= "$config->{cache_dir}/cache.json";
    $config->{cache} = from_json( read_file($config->{cache_file}) ) if -f $config->{cache_file};
    my $cache_file_version = 1;
    # On mismatched versions, just clear out the cache:
    $config->{cache} = { VERSION => $cache_file_version } unless $config->{cache} && ($config->{cache}->{VERSION} || 0) == $cache_file_version;
    $config;
}

1;

__END__

=head1 NAME

File::HashCache - Process and cache files based on the hash of their contents.

=head1 SYNOPSIS

  use File::HashCache;

  my $hc = File::HashCache->new(cache_dir => 'js',
                                process_js => \&JavaScript::Minifier::XS::minify,
                                process_css => \&CSS::Minifier::XS::minify);

  my $hashed_minified_path = $hc->hash("my_javascript_file.js");
  # returns "my_javascript_file-7f4539486f2f6e65ef02fe9f98e68944.js"

  # If you are using Template::Toolkit you may want something like this:
  $template->process('template.tt2', {
      script => sub {
          my $path = $hc->hash($_[0]);
          "<script src=\"js/$path\" type=\"text/javascript\"></script>\n";
      } } ) || die $template->error();

  # And in your template.tt2 file:
  #    [% script("myscript.js") %]
  # which will get replaced with something like:
  #    <script src="js/myscript-708b88f899939c4adedc271d9ab9ee66.js"
  #            type="text/javascript"></script>

=head1 DESCRIPTION

File::HashCache is an automatic versioning scheme for arbitrary files based
on the hash of the contents of the files themselves. It aims to be painless
for the developer and very fast.

File::HashCache solves the problem in web development where you update some
Javascript, CSS, or image files on the server and the end user ends up with
mismatched versions because of browser or proxy caching issues. By
referencing your external files by their MD5 hash, the browser is unable to
to give the end user mismatched versions no matter what the caching policy
is.

=head1 HOW TO USE IT

The best place to use File::HashCache is in your HTML template code. While
generating a page to serve to the user, call the hash() method for each
Javascript, CSS, or image file you are including in your page. The hash()
method will return the name of the newly hashed file. You should use this
name in the rendered contents of the page.

This means that when the browser gets the page you serve, it will have
references to specific versions of the files.

=head1 METHODS

=over 4

=item B<C<new(%options)>>

Initializes a new cache object. Available options and their defaults:

=over 4

=item C<< cache_dir => '.hashcache' >>

Where to put the resulting minified files.

=item C<< process_* => sub { @_[0] } >>

The process_* parameters are subroutine references and will be called for
each file that's passed in based on the file extension. For instance, to
process PNGs you would use 'process_png', javascript files would use
'process_js'. This subroutine will be called with the entire contents of the
file and it should return a modified version to cache.

If the processing needs to add any dependencies so that File::HashCache can
know when it needs to re-process it (other than the original file, which it
automatically kept track of), the processing subroutine should return a list
with the new contents as the first item and the extra dependencies as the
rest of the list.

If the hash() method is called with a filename whose extension does not have
a corresponding process_* subroutine, then the contents of the file are
copied to the hash directory with no modifications.

=item C<< cache_file => "$cache_dir/cache.json" >>

Where to put the cache control file.

=back

=item B<C<hash($path_to_file, ...)>>

This method...

=over

=item 1

Reads the file(s) into memory and concatenates them. This allows you to
group CSS or Javascript sources together in one big bundle. If you pass in
multiple files to be concatentated they must all have the same extension
(otherwise processing the resulting concatenated data would be problematic).

=item 2

Calls the appropriate processing function to process the data.

=item 3

Calculates the MD5 hash of the processed data.

=item 4

Saves the data to a cache directory where it is named based on its hash
value which makes the name globally unique (it also keeps it's original name
as a prefix so debugging is sane).

=item 5

Keeps track of the original file names, the minified file's globally unique
name, and the dependencies used to build the image. This is stored in a hash
table and also saved to the disk for future runs.

=item 6

Returns the name of the minified file that was stored in step 4. This name
does not include the cache directory path because its physical file system
path does not necessarily relate to its virtual server path.

=back

There's actually a step 0 in there too: If the original file name is found
in the hash table then it quickly stats its saved dependencies to see if
they are newer than the saved, already processed, file. If the processed
file is up to date then steps 1 through 5 are skipped.

=back

=head1 FURTHER DISCUSSION ABOUT THIS TECHNIQUE

=head2 It keeps the files you serve in sync

When the user refreshes the page they will either get the page from their
browser cache or they will get it from our site. No matter where it came
from the hashed Javascript, CSS, and image files it references are now
uniquely named so that it is impossible for the files to be out of date from
each other.

That is, if you get the old HTML file you will reference all the old named
files and everything will be mutually consistent (even though it is out of
date). If you get the new HTML file it guarantees you will have to fetch the
latest files because the new HTML only references the new hashed names that
aren't going to be in your browser cache.

=head2 It's fast.

Everything is cached so it only does the minification and hash calculations
once per file. More importantly the cached dir can be statically served by
the web server so it's exactly as fast as it would be if you served the
files without any preprocessing. All this technique adds is a couple
filesystem stats per page load, which isn't much (Linux can do something
like a million stats per second).

=head2 It's automatic.

If you hook in through L<Template::Toolkit> then there's no script to
remember to run when you update the site. When the template generates the
HTML, the L<File::HashCache> code lazily takes care of rebuilding any
files that may have gone out of date.

=head2 It's stateless.

It doesn't rely on incrementing numbers ("js/v10/script.js" or even
"js/script-v10.js"). We considered this approach but decided it was actually
harder to implement and had no advantages over the way we chose to do
it. This may have been colored by our choice of version control systems (we
love the current wave of DVCSes) where monotonically increasing version
numbers have no meaning.

=head2 It allows aggressive caching.

Since the files are named by their contents' hash, you can set the cache
time on your web server to be practically infinite.

=head2 It's very simple to understand.

It took less than a page of Perl code to implement the whole thing and it
worked the first time with no bugs. I believe it's taken me longer to write
this than it took to write the code (granted I'd been thinking about it for
a long time before I started coding).

=head2 No files are deleted.

The old files are not automatically deleted (why bother, they are tiny)
so people with extremely old HTML files will not have inconsistent pages
when they reload. However:

=head2 The cache directory is volatile.

It's written so we can delete the entire cache dir at any point and it will
just recreate what it needs to on the next request. This means there's
no extra setup to do in your app.

=head2 You get a bit of history.

Do a quick C<ls -lrt> of the directory and you can see which scripts have
been updated recently and in what order they got built.

=head1 SEE ALSO

This code was adapted from the code we wrote for our site
L<http://greenfelt.net/>. Here is our original blog post talking about the technique:
L<http://blog.greenfelt.net/2009/09/01/caching-javascript-safely/>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2009-2013 David Caldwell and Jim Radford.

=head1 AUTHOR

=over

=item *

David Caldwell <david@porkrind.org>

=item *

Jim Radford <radford@blackbean.org>

=back

=cut
