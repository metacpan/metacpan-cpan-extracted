
# NAME

Interact::Later - Delay some tasks for later by dumping their data to disk

# VERSION

Version 0.05

# SYNOPSIS

Can be used, for example, when you receive lots of `POST` requests that you
don't want to proceed right now to save database load.

This module will fastly store the data content on disk (with [Storable](https://metacpan.org/pod/Storable)) without
the need to use a database or a job queue. I believe as Perl is fast at writing
files to disk, we can hope good results. This is an experiment...

    use Interact::Later;

    my $delayer = Interact::Later->new(
      cache_path => 'path/to/cache',
      file_extension => '.dmp'
    );

    $delayer->write_data_to_disk($data);

    # Later...
    # Do it until there are no more files...
    $delayer->get_oldest_file_in_cache();

    # Finally
    $delayer->clean_cache;

# MOTIVATIONS

TODO Telling the story of what happened at work and the situation with
databases, job queues, etc. that got troubled by the large amount of POST
requests.

# EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

# ATTRIBUTES

To instantiate a new `Interacter::Later` delayer, simply pass a hashref
containing a key-value couple containing the following:

## cache\_path

`cache_path` is the relative path to the directory that will contain multiple
cache files. It will be expanded to an absolute path by the [Moose](https://metacpan.org/pod/Moose) trigger and
[Path::Class](https://metacpan.org/pod/Path::Class).

Keep it simple, it don't require a `/` in the beginning nor the end, and you
will be able to access it through `$delayer-`class\_path>.

    $ pwd
    /home/smonff/later/

    my $delayer = Interact::Later->new( cache_path => 'path/to/cache', ... );
    say $delayer->class_path;
    # /home/smonff/later/path/to/cache/
    # Note it add a / in the end

## file\_extension

TODO

# SUBROUTINES/METHODS

## get\_oldest\_cache\_files\_ordered\_by\_date

Retrieve the oldest file in the cache. `$files[0]` is the oldest,
`$files[-1]`the newest.

## clean\_cache

Flush the cache.

## release\_cache

Retrieve a specific file by ID

## generate\_uuid

## write\_data\_to\_disk

Writes the cache files to disk using `Storable`. It also checks that the cache
path exists and if not, it creates it.

Returns the UUID so this way, the caller could re-use it (by placing it in a
queue for example).

## retrieve\_data\_from\_disk

# AUTHOR

Sébastien Feugère, `<smonff at riseup.net>`

# BUGS

Please report any bugs or feature requests to `interact-later at gitlab.com`, or through
the web interface at [https://gitlab.com/smonff/interact-later/issues](https://gitlab.com/smonff/interact-later/issues).  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Interact::Later

You can also look for information at:

- Gitlab: Gitlab issues tracker (report bugs here)

    [http://gitlab.com/smonff/Interact-Later](http://gitlab.com/smonff/Interact-Later)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Interact-Later](http://annocpan.org/dist/Interact-Later)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Interact-Later](http://cpanratings.perl.org/d/Interact-Later)

- Search CPAN

    [http://search.cpan.org/dist/Interact-Later/](http://search.cpan.org/dist/Interact-Later/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2019 Sébastien Feugère.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
