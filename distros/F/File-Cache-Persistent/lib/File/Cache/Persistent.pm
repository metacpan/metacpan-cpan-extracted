package File::Cache::Persistent;

use strict;

use vars qw($VERSION $CACHE $TIME_CACHE $NO_FILE $NOT_MODIFIED $FILE $PROLONG $TIMEOUT);
$VERSION = 0.3;

$NO_FILE      = 1;
$NOT_MODIFIED = $NO_FILE << 1;
$FILE         = $NOT_MODIFIED << 1;
$PROLONG      = $FILE << 1;
$TIMEOUT      = $PROLONG << 1;
$CACHE        = $TIMEOUT << 1;
$TIME_CACHE   = $CACHE << 1;

sub new {
    my ($class, %args) = @_;

    my $this = {
        prefix => $args{prefix} || undef,
        timeout => $args{timeout} || 0,
        reader => $args{reader} || undef,
	reader_error => undef,
        data => {},
        status => undef,
    };
    bless $this, $class;

    return $this;
}

sub get {
    my ($this, $path) = @_;

    $path = $this->{prefix} . '/' . $path if $this->{prefix};

    my $data;
    my $havecache = defined $this->{data}{$path};

    $this->{status} = undef;    
    unless ($this->{timeout}) {
        # Time caching mode is off.        

        unless (-e $path) {
            # Did not find the file, make an attempt to use cache.
            unless ($havecache) {
                # Nope, failed completely.
                die "Neither file '$path' nor its cache exists\n";
            }
            else {
                # OK, using cache but no file still exists.
                $data = $this->{data}{$path}[0];
                $this->{status} = $CACHE + $NO_FILE;
            }
        }
        else {
            # There is a file. Before using it should test if there is a cached version of it.
            if ($havecache && !$this->_is_modified($path)) {
                # File was not modified, using cache.
                $data = $this->{data}{$path}[0];
                $this->{status} = $CACHE + $NOT_MODIFIED;
            }
            else {
                # No cache found or file was modified. Reading it from disk and saving in cache.
                $data = $this->_read_file($path);
                $this->{status} = $FILE;
            }
        }
    }
    else {
        # Time caching mode is on. No attempts to check whether the file was changed if cache is new enough.        
        
        unless ($havecache) {
            # No cache available. Read the file from disk.
            die "Neither file '$path' nor its cache exists\n" unless -e $path;
            $data = $this->_read_file($path);
            $this->{status} = $FILE;
        }
        elsif (time - $this->{data}{$path}[3] <= $this->{timeout}) {
            # Good cache. Using it.
            $data = $this->{data}{$path}[0];
            $this->{status} = $CACHE + $TIME_CACHE;           
        }
        else {
            # Cache is outdated.
            if (-e $path) {
                # There is a file.
                if (!$this->_is_modified($path)) {                
                    # No changes in file. Thus just prolongating cache time life.
                    $this->{data}{$path}[3] = time;
                    $data = $this->{data}{$path}[0];
                    $this->{status} = $CACHE + $TIME_CACHE + $NOT_MODIFIED + $PROLONG + $TIMEOUT;
                }
                else {
                    # Both cache expired and file changed. Reload.
                    $data = $this->_read_file($path);
                    $this->{status} = $FILE + $TIMEOUT;
                }
            }
            else {
                # No file. No panic but using outdated cached document.
                $data = $this->{data}{$path}[0];
                $this->{status} = $CACHE + $TIME_CACHE + $NO_FILE + $TIMEOUT;
            }
        }
    }
    # Too many elses? Do it yourself otherwise :-)

    return $data;
}

sub remove {
    my ($this, $path) = @_;

    $path = $this->{prefix} . '/' . $path if $this->{prefix};

    $this->{status} = undef;
    delete $this->{data}{$path};
}

sub status {
    my $this = shift;
    
    return $this->{status};
}

sub _timeout {
    my ($this, $path) = @_;

    return $this->{data}{$path}[1] - (stat $path)[9];
}

sub _is_modified {
    my ($this, $path) = @_;

    return
        $this->{data}{$path}[1] != (stat $path)[9] || # mtime
        $this->{data}{$path}[2] != (stat _)[7];       # size
}

sub _update_cache {
    my ($this, $data, $path) = @_;

    $this->{data}{$path} = [
        $data,
        (stat $path)[9],
        (stat _)[7],
        time
    ];
}

sub _read_file {
    my ($this, $path) = @_;

    my $data;
    if (defined $this->{reader}) {
	$this->{reader_error} = undef;
	eval {
            $data = $this->{reader}($path);
	};
	$this->{reader_error} = $@ if $@;
    }
    else {
        local $/;
        undef $/;
        open my $file, '<', $path;
        $data = <$file>;
        close $file;
    }

    $this->_update_cache($data, $path);
    
    return $data;
}

sub reader_error {
    my $this = shift;
    
    return $this->{reader_error};
}

1;

__END__

=head1 NAME

File::Cache::Persistent - Caches file content and allows to use it even after file is deleted

=head1 SYNOPSIS

    use File::Cache::Persistent;
       
    # Reloading cache if the file was modified
    my $cache = new File::Cache::Persistent;
    say $cache->get('index.html');
    . . . # Some code that modifies the file.
    say $cache->get('index.html');
    
    # Using cached copy forever
    my $cache = new File::Cache::Persistent;
    say $cache->get('index.html');
    unlink 'index.html';
    say $cache->get('index.html');
    
    # Checking if the file was modified after timeout
    my $cache = new File::Cache::Persistent(timeout => 30);
    say $cache->get('index.html');
    sleep 40;
    say $cache->get('index.html');
    
    # Remove the file from cache and then reload it    
    $cache->remove('index.html');
    say $cache->get('index.html');
    
    # Learn out what was used
    say $cache->get('index.html');
    warn "Used cached version"
        if $cache->status | $File::Cache::Persistent::CACHE;
    warn "Used cached version but the file is deleted"
        if $cache->status | $File::Cache::Persistent::CACHE
        && $cache->status | $File::Cache::Persistent::NO_FILE;
        
    # Using custom data provider
    my $cache = new File::Cache::Persistent(reader => \&my_reader);
    . . .
    sub reader {
        my $file_path = shift;
        # Read the file, analyse its content
        # and return something that should be cached
        return $data;
    }

=head1 ABSTRACT

File::Cache::Persistent caches file content, controls if the files are changed,
ignores any changes withing predefined timeout and allows to use cache for
files which were removed after entering the cache.

=head1 DESCRIPTION

This module aims to put caching logic to the background and avoid manually
checking conditions of cache expiration. It also is useful when files are not
available after cache timeout and provides cached version although it is
inevitably outdated.

Access to the data is granted through C<get> method. It transparently reads the
file and caches it if it is needed. By default, raw content of the file is
put to the cache. 

=head2 new

Constructor C<new> creates an instance of caching object. It accepts three
named parameters, each of them are optional.

    my $default_cache = new File::Cache::Persistent(
        prefix  => '/www/data/xsl',
        timeout => 30,
        reader  => \&custom_reader
    );

C<prefix> parameter defines a directory where files will be looked for. By
default it is assumed that files are located in the current directory.

C<timeout> specifies how long the instance uses pure cache and makes no attempt
to check whether the file is modified. During that period every call of
C<get> method returns data stored in cache (excluding the first call when
the cache is empty).

C<reader> allows to replace default routine of reading the file. Default
behaviour is getting anyting from (text) file and put it to the cache. Reader
replacer may be a subroutine which accepts a filename and returns something to
put to cache. Returning value may not only be the text: it may, for example, be
a reference to an object which was created with the data from file. Note that
file must exists even if the reader is not going to get the data from it.

Here is an example of custom reader subroutine which calculates the square of an
image and returns it in a hash together with image dimentions.

    use Image::Size;
    . . .
    sub image_metrics {
        my $path = shift;        
        my ($width, $height) = imgsize($path);
        return {
            width  => $width,
            height => $height,
            square => $width * $height,
        };
    }

If the reader encounters an error, its explanation may be found by calling
C<reader_error> method.

    my $data = $cache->get('wrong.xml');
    say $cache->reader_error() unless $data;

It is possible to call C<new> with no parameters, which is equivalent to
calling with defaults:

    my $default_cache = new File::Cache::Persistent(
        prefix  => undef,
        timeout => 0,
        reader  => undef
    );

=head2 get

The only data accessor is a method C<get>. It must be called every time the user
needs data. Return value is built either by default file reader or by custom one.
Method expects to receive a path to the file (relating to the prefix if it was
specified in the constructor).

When C<get> is called for the first time, file is always read from disk and
stored to the cache. Internal behaviour of future calls depends on different
conditions as described in next sections.

If the cache is empty and no file exists, the call C<die>s with an error.

=head3 Time caching mode is off

Timeout check is off by default. In this case each call of C<get> looks if the
file in question was modified. If it was, the cache is updated and a new value
is returned. Otherwise current value is returned without reading the file.

Note that modification is determined by checking modification time and size of
the file. Thus in rear cases modification may be not noticed. For example, if a
copy of two different files are made in a period less than one second, and
between these two copyings C<get> is called. To avoid such situations, C<remove>
method may be used to clear the cache for that file:

    use File::Copy;
    copy('file1', 'file');
    say $cache->get('file');
    unlink 'file';
    $cache->remove('file');
    copy('file2', 'file');
    say $cache->get('file');
    
When the file is deleted and the cache is not cleaned, every C<get> call will
return the value stored in it previously.

=head3 Time caching mode is on

Timeout for the cache is set by C<timeout> parameter in a constructor. The value
is a number of seconds during which physical file on the disk will not be checked.
If it is changed before the timeout, cache will contain initial value.

    # Running under mod_perl
    my $cache = new File::Cache::Persistent(timeout => 600);
    . . .
    sub handler {
        . . .
        say $cache->get('currency_rates.html');
    }    
);

First C<get> call happened after timeout will check if the file was modified and
update the cache if it is necessary. If there were no changes, timeout will be
prolongated for C<timeout> seconds more without re-reading the file.

If the file is deleted, the cache does not suffer even it is asked after timeout.

=head2 status

Module provides special method C<status> which reports where cache data were
get from. This method returns the status of last C<get> call and thus should be
used after calling C<get> and before any other C<get> or C<remove> calls.

Return value is a bitwise combination of the following flags:

B<CACHE> occures when C<get> returns the value from cache. If the cache has a
timeout specified, additional B<TIME_CACHE> flag is set.

B<TIMEOUT> indicates that timeout happened.

B<PROLONG> shows that timeout was reset for the next period and no file was
really read.

B<FILE>, B<NOT_MODIFIED> and B<NO_FILE> correspond to situations when file was
read from disk, or it was not modifed, or was deleted.

Bitwise operator C<|> may be used to determined what happened:

    if ($cache->status | $File::Cache::Persistent::NO_FILE) {
        warn "Unexpectedly absent file";
        rebuild_files;
    }

=head1 AUTHOR

Andrew Shitov, <andy@shitov.ru>

=head1 COPYRIGHT AND LICENSE
  
File::Cache::Persistent module is a free software. 
You may redistribute and (or) modify it under the same terms as Perl itself
whichever version it is.

=cut
