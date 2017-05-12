##- Nanar <nanardon@mandriva.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# $Id: Packdrakeng.pm 225631 2007-08-09 11:45:44Z nanardon $

package MDV::Packdrakeng;

use strict;
use POSIX qw(O_WRONLY O_TRUNC O_CREAT O_RDONLY O_APPEND);
use File::Path qw(mkpath);

our $VERSION = '1.13';

my  ($toc_header, $toc_footer) =
    ('cz[0',      '0]cz');

# File::Temp qw(tempfile) hack to not require it
sub tempfile {
    my ($count, $fname, $handle) = (0, undef, undef);
    do {
        ++$count > 10 and do {
	    warn "Can't create temporary file ($fname)";
	    return (undef, undef);
	};
        $fname = sprintf("%s/packdrakeng.%s.%s",
            $ENV{TMPDIR} || '/tmp',
            $$,
            # Generating an random name
            join("", map { $_=rand(51); $_ += $_ > 25 && $_ < 32 ? 91 : 65 ; chr($_) } (0 .. 4)));
    } while !sysopen($handle, $fname, O_WRONLY | O_APPEND | O_CREAT);
    return ($handle, $fname);
}

sub method_info { "external $_[0]->{compress_method}/$_[0]->{uncompress_method} $VERSION" }

sub _new {
    my ($class, %options) = @_;

    my $pack = {
        filename => $options{archive},

        compress_method => $options{compress},
        uncompress_method => $options{uncompress},
        force_extern => $options{extern} || 0, # Don't use perl-zlib
        noargs => $options{noargs},

        # compression level, aka -X gzip or bzip option
        level => defined($options{comp_level}) ? $options{comp_level} : 6,

        # A compressed block will contain 400k of compressed data
        block_size => defined($options{block_size}) ? $options{block_size} : 400 * 1024,
        bufsize => $options{bufsize} || 65536, # Arbitrary buffer size to read files

        # Internal data
        handle => undef, # Archive handle

        # Toc information
        files => {}, # filename => { off, size, coff, csize }
        dir => {}, # dir => no matter what value
        'symlink' => {}, # file => link

        coff => 0, # end of current compressed data

        # Data we need keep in memory to achieve the storage
        current_block_files => {}, # Files in pending compressed block
        current_block_csize => 0,  # Actual size in pending compressed block
        current_block_coff => 0,   # The block block location (offset)
        current_block_off => 0,    # Actual uncompressed file offset within the pending block

        cstream_data => undef,     # Wrapper data we need to keep in memory (compression)
        ustream_data => undef,     # Wrapper data we need to keep in memory (uncompression)

        # log and verbose function:
        log => $options{quiet}
	    ? sub { our $error = "$_[0]\n" }
	    : sub { our $error = "$_[0]\n"; warn $error },
        debug => $options{debug}
	    ? sub { my @w = @_; $w[0] = "Debug: $w[0]\n"; printf STDERR @w }
	    : sub {},
    };

    bless($pack, $class)
}

sub new {
    my ($class, %options) = @_;
    my $pack = _new($class, %options);
    sysopen($pack->{handle}, $pack->{filename}, O_WRONLY | O_TRUNC | O_CREAT) or do {
	$pack->{log}("Can't open $pack->{filename}: $!");
	return undef;
    };
    $pack->choose_compression_method();
    $pack->{need_build_toc} = 1;
    $pack->{debug}(
        "Creating new archive with %s.",
            $pack->method_info(),
    );
    $pack
}

sub open {
    my ($class, %options) = @_;
    my $pack = _new($class, %options);
    sysopen($pack->{handle}, $pack->{filename}, O_RDONLY) or do {
	$pack->{log}("Can't open $pack->{filename}: $!");
	return undef;
    };
    $pack->read_toc() or return undef;
    $pack->{debug}("Opening archive with %s.",
        $pack->method_info(),
    );
    $pack
}

# look $pack->{(un)compressed_method} and setup functions/commands to use
# Have some facility about detecting we want gzip/bzip
sub choose_compression_method {
    my ($pack) = @_;

    (!defined($pack->{compress_method}) && !defined($pack->{uncompress_method}))
        and $pack->{compress_method} = "gzip";
    my $test_method = $pack->{compress_method} || $pack->{uncompress_method};

    $test_method =~ m/^bzip2|^bunzip2/ and do {
        $pack->{compress_method} ||= "bzip2";
    };
    $test_method =~ m/^gzip|^gunzip/ and do {
        $pack->{compress_method} ||= "gzip";
        if (!$pack->{force_extern}) {
            eval {
		require Compress::Zlib; #- need this to ensure that Packdrakeng::zlib will load properly
		require MDV::Packdrakeng::zlib;

        bless($pack, 'MDV::Packdrakeng::zlib');
            };
        }
    };
    if (!$pack->{noargs}) {
        $pack->{uncompress_method} ||= "$pack->{compress_method} -d";
        $pack->{compress_method} = $pack->{compress_method} ? "$pack->{compress_method} -$pack->{level}" : "";
    }
}

sub DESTROY {
    my ($pack) = @_;
    $pack->{destroyed} and return; #- allow calling DESTROY
    $pack->{destroyed} = 1;

    $pack->uncompress_handle(undef, undef);
    $pack->build_toc() == 1 or die "Can't write toc into archive\n";
    close($pack->{handle}) if $pack->{handle};
    close($pack->{ustream_data}{handle}) if $pack->{ustream_data}{handle};
}

# Flush current compressed block
# Write
sub build_toc {
    my ($pack) = @_;
    $pack->{need_build_toc} or return 1;
    $pack->end_block();
    $pack->end_seek() or do {
	$pack->{log}("Can't seek into archive");
	return 0;
    };
    my ($toc_length, $cf, $cd, $cl) = (0, 0, 0, 0);

    foreach my $entry (keys %{$pack->{'dir'}}) {
	$cd++;
	my $w = syswrite($pack->{handle}, $entry . "\n") or do {
	    $pack->{log}("Can't write toc into archive");
	    return 0;
	};
	$toc_length += $w;
    }
    foreach my $entry (keys %{$pack->{'symlink'}}) {
	$cl++;
	my $w = syswrite($pack->{handle}, sprintf("%s\n%s\n", $entry, $pack->{'symlink'}{$entry})) or do {
	    $pack->{log}("Can't write toc into archive");
	    return 0;
	};
	$toc_length += $w
    }
    foreach my $entry (sort keys %{$pack->{files}}) {
	$cf++;
	my $w = syswrite($pack->{handle}, $entry ."\n") or do {
	    $pack->{log}("Can't write toc into archive");
	    return 0;
	};
	$toc_length += $w;
    }
    foreach my $file (sort keys %{$pack->{files}}) {
	my $entry = $pack->{files}{$file};
	syswrite($pack->{handle}, pack('NNNN', $entry->{coff}, $entry->{csize}, $entry->{off}, $entry->{size})) or do {
	    $pack->{log}("Can't write toc into archive");
	    return 0;
	};
    }
    syswrite($pack->{handle}, pack("a4NNNNa40a4",
    $toc_header,
    $cd, $cl, $cf,
    $toc_length,
    $pack->{uncompress_method},
    $toc_footer)) or do {
	$pack->{log}("Can't write toc into archive");
	return 0;
    };
    1;
}

sub read_toc {
    my ($pack) = @_;
    sysseek($pack->{handle}, -64, 2) ; #or return 0;
    sysread($pack->{handle}, my $buf, 64);# == 64 or return 0;
    my ($header, $toc_d_count, $toc_l_count, $toc_f_count, $toc_str_size, $uncompress, $trailer) =
        unpack("a4NNNNZ40a4", $buf);
    $header eq $toc_header && $trailer eq $toc_footer or do {
        $pack->{log}("Error reading toc: wrong header/trailer");
        return 0;
    };

    $pack->{uncompress_method} ||= $uncompress;
    $pack->choose_compression_method();

    sysseek($pack->{handle}, -64 - ($toc_str_size + 16 * $toc_f_count) ,2);
    sysread($pack->{handle}, my $fileslist, $toc_str_size);
    my @filenames = split("\n", $fileslist);
    sysread($pack->{handle}, my $sizes_offsets, 16 * $toc_f_count);
    my @size_offset = unpack("N" . 4*$toc_f_count, $sizes_offsets);

    foreach (1 .. $toc_d_count) {
        $pack->{dir}{shift(@filenames)} = 1;
    }
    foreach (1 .. $toc_l_count) {
        my $n = shift(@filenames);
        $pack->{'symlink'}{$n} = shift(@filenames);
    }

    foreach (1 .. $toc_f_count) {
        my $f = shift(@filenames);
        $pack->{files}{$f}{coff} = shift(@size_offset);
        $pack->{files}{$f}{csize} = shift(@size_offset);
        $pack->{files}{$f}{off} = shift(@size_offset);
        $pack->{files}{$f}{size} = shift(@size_offset);
        # looking for offset for this archive
        $pack->{files}{$f}{coff} + $pack->{files}{$f}{csize} > $pack->{coff}
	    and $pack->{coff} = $pack->{files}{$f}{coff} + $pack->{files}{$f}{csize};
    }
    $pack->{toc_f_count} = $toc_f_count;
    1;
}

sub sort_files_by_packing {
    my ($pack, @files) = @_;
    sort {
        defined($pack->{files}{$a}) && defined($pack->{files}{$b}) ?
            ($pack->{files}{$a}{coff} == $pack->{files}{$b}{coff} ?
            $pack->{files}{$a}{off} <=> $pack->{files}{$b}{off} :
            $pack->{files}{$a}{coff} <=> $pack->{files}{$b}{coff}) :
        $a cmp $b
    } @files;
}

# Goto to the end of written compressed data
sub end_seek {
    my ($pack) = @_;
    my $seekvalue = $pack->direct_write ? $pack->{coff} + $pack->{current_block_csize} : $pack->{coff};
    sysseek($pack->{handle}, $seekvalue, 0) == $seekvalue
}

#- To terminate a compressed block, flush the pending compressed data,
#- fill toc data still unknown
sub end_block {
    my ($pack) = @_;
    $pack->end_seek() or return 0;
    my (undef, $csize) = $pack->compress_handle(undef);
    $pack->{current_block_csize} += $csize;
    foreach (keys %{$pack->{current_block_files}}) {
        $pack->{files}{$_} = $pack->{current_block_files}{$_};
        $pack->{files}{$_}{csize} = $pack->{current_block_csize};
    }
    $pack->{coff} += $pack->{current_block_csize};
    $pack->{current_block_coff} += $pack->{current_block_csize};
    $pack->{current_block_csize} = 0;
    $pack->{current_block_files} = {};
    $pack->{current_block_off} = 0;
}

#######################
# Compression wrapper #
#######################

# true if wrapper writes directly in archive and not into temp file
sub direct_write { 0; }

sub compress_handle {
    my ($pack, $sourcefh) = @_;
    my ($insize, $outsize) = (0, 0); # aka uncompressed / compressed data length

    if (!defined($sourcefh)) { # bloc flush call
        return 0, $pack->compress_data();
    } else {
        while (my $length = sysread($sourcefh, my $data, $pack->{bufsize})) {
            $outsize += $pack->compress_data($data);
            $insize += $length;
        }
        return ($insize, $outsize)
    }
}

sub compress_data {
    my ($pack, $data) = ($_[0], \$_[1]);
    my ($outsize) = (0); # aka uncompressed / compressed data length
    my $hout; # handle for gzip

    if (defined($pack->{cstream_data})) {
        $hout = $pack->{cstream_data}{hout};
    }
    if (defined($$data)) {
        if (!defined($pack->{cstream_data})) {
            my $hin;
            ($hin, $pack->{cstream_data}{file_block}) = tempfile();
            close($hin); # ensure the flush
            $pack->{cstream_data}{pid} = CORE::open($hout,
                "|$pack->{compress_method} > $pack->{cstream_data}{file_block}") or do {
                $pack->{log}("Unable to start $pack->{compress_method}");
                return 0;
            };
            $pack->{cstream_data}{hout} = $hout;
            binmode $hout;
        }
        # until we have data to push or data to read
        # pushing data to compressor
        (syswrite($hout, $$data)) == length($$data) or do {
            $pack->{log}("Can't push all data to compressor");
        };
        return 0; # We can't be sure about data really written in the pipe 
                  # because of multitasking and buffer, so nothing has been
                  # written
    } elsif (defined($pack->{cstream_data})) {
        # If $data is not set, this mean we want a flush(), for end_block()
        close($hout);
        waitpid $pack->{cstream_data}{pid}, 0;
        # copy temp bloc to archive
        sysopen(my $hin, $pack->{cstream_data}{file_block}, O_RDONLY) or do {
            $pack->{log}("Can't open temp block file: $!");
            return 0;
        };
        unlink($pack->{cstream_data}{file_block});
        while (my $length = sysread($hin, my $tdata, $pack->{bufsize})) {
            (my $l = syswrite($pack->{handle}, $tdata)) == $length or do {
                $pack->{log}("Can't write all data in archive");
            };
            $outsize += $l;
        }
        close($hin);
        $pack->{cstream_data} = undef;
        # TODO current_block_csize isn't 0 ?
        return $outsize - $pack->{current_block_csize}
    }
}

sub uncompress_handle {
    my ($pack, $destfh, $fileinfo) = @_;

    if (defined($pack->{ustream_data}) && (
            !defined($fileinfo) ||
            ($fileinfo->{coff} != $pack->{ustream_data}{coff} || $fileinfo->{off} < $pack->{ustream_data}{off})
        )) {
        close($pack->{ustream_data}{handle});
        unlink($pack->{ustream_data}{tempname}); # deleting temp file
        $pack->{ustream_data} = undef;
    }

    defined($fileinfo) or return 0;

    # We have to first extract the block to a temp file, burk !
    if (!defined($pack->{ustream_data})) {
        my $tempfh;
        $pack->{ustream_data}{coff} = $fileinfo->{coff};
        $pack->{ustream_data}{read} = 0;

        ($tempfh, $pack->{ustream_data}{tempname}) = tempfile();

        my $cread = 0;
        while ($cread < $fileinfo->{csize}) {
            my $cl = sysread($pack->{handle}, my $data,
                $cread + $pack->{bufsize} > $fileinfo->{csize} ?
                    $fileinfo->{csize} - $cread :
                    $pack->{bufsize}) or do {
                    $pack->{log}("Unexpected end of file");
                    close($tempfh);
                    unlink($pack->{ustream_data}{tempname});
                    $pack->{ustream_data} = undef;
                    return -1;
            };
            $cread += $cl;
            syswrite($tempfh, $data) == length($data) or do {
                $pack->{log}("Can't write all data into temp file");
                close($tempfh);
                unlink($pack->{ustream_data}{tempname});
                $pack->{ustream_data} = undef;
                return -1;
            };
        }
        close($tempfh);

	my $cmd = $pack->{uncompress_method} eq 'gzip -d' || $pack->{uncompress_method} eq 'bzip2 -d' ?
	  "$pack->{uncompress_method} -c '$pack->{ustream_data}{tempname}'" :
	  "$pack->{uncompress_method} <  '$pack->{ustream_data}{tempname}'";
        CORE::open($pack->{ustream_data}{handle}, "$cmd |") or do {
            $pack->{log}("Can't start $pack->{uncompress_method} to uncompress data");
            unlink($pack->{ustream_data}{tempname});
            $pack->{ustream_data} = undef;
            return -1;
        };
        binmode($pack->{ustream_data}{handle});
    }

    my $byteswritten = 0;
    $pack->{ustream_data}{off} = $fileinfo->{off};

    while ($byteswritten < $fileinfo->{size}) {
        my $data = $pack->{ustream_data}{buf};
        $pack->{ustream_data}{buf} = undef;
        my $length;
        if (!defined($data)) {
            $length = sysread($pack->{ustream_data}{handle}, $data, $pack->{bufsize}) or do {
                $pack->{log}("Unexpected end of stream $pack->{ustream_data}{tempname}");
                unlink($pack->{ustream_data}{tempname});
                close($pack->{ustream_data}{handle});
                $pack->{ustream_data} = undef;
                return -1;
            };
        } else {
            $length = length($data);
        }

        if ($pack->{ustream_data}{read} < $fileinfo->{off} && $pack->{ustream_data}{read} + $length > $fileinfo->{off}) {
            $data = substr($data, $fileinfo->{off} - $pack->{ustream_data}{read});
        }
        $pack->{ustream_data}{read} += $length;
        if ($pack->{ustream_data}{read} <= $fileinfo->{off}) { next }

        my $bw;
        if ($byteswritten + length($data) > $fileinfo->{size}) {
            $bw = $fileinfo->{size} - $byteswritten;
            $pack->{ustream_data}{buf} = substr($data, $bw); # keeping track of unwritten uncompressed data
            $pack->{ustream_data}{read} -= length($pack->{ustream_data}{buf});
        } else {
            $bw = length($data);
        }

        syswrite($destfh, $data, $bw) == $bw or do {
            $pack->{log}("Can't write data into dest");
            return -1;
        };
        $byteswritten += $bw;
    }

    $byteswritten

}

###################
# Debug functions #
###################

# This function extracts in $dest the whole block containing $file, can be useful for debugging
sub extract_block {
    my ($pack, $dest, $file) = @_;

    sysopen(my $handle, $dest, O_WRONLY | O_TRUNC | O_CREAT) or do {
        $pack->{log}("Can't open $dest: $!");
        return -1;
    };

    sysseek($pack->{handle}, $pack->{files}{$file}->{coff}, 0) == $pack->{files}{$file}->{coff} or do {
        $pack->{log}("Can't seek to offset $pack->{files}{$file}->{coff}");
        close($handle);
        return -1;
    };

    {
	my $l;
	$l = sysread($pack->{handle}, my $buf, $pack->{files}{$file}->{csize}) == $pack->{files}{$file}{csize}
	    or $pack->{log}("Read only $l / $pack->{files}{$file}->{csize} bytes");
	syswrite($handle, $buf);
    }

    foreach ($pack->sort_files_by_packing(keys %{$pack->{files}})) {
        $pack->{files}{$_}{coff} == $pack->{files}{$file}->{coff} or next;
    }

    close($handle);

}

##################################
# Really working functions       #
# Aka function people should use #
##################################

sub add_virtual {
    my ($pack, $type, $filename, $data) = @_;
    $type eq 'l' and do {
        $pack->{'symlink'}{$filename} = $data;
        $pack->{need_build_toc} = 1;
        return 1;
    };
    $type eq 'd' and do {
        $pack->{dir}{$filename}++;
        $pack->{need_build_toc} = 1;
        return 1;
    };
    $type eq 'f' and do {
        # Be sure we are at the end, allow extract + add in only one instance
        $pack->end_seek() or do {
            $pack->{log}("Can't seek to offset $pack->{coff}");
            next;
        };

        my ($size, $csize) = (ref($data) eq 'GLOB') ?
            $pack->compress_handle($data) :
            (length($data), $pack->compress_data($data));
        $pack->{current_block_files}{$filename} = {
            size => $size,
            off => $pack->{current_block_off},
            coff => $pack->{current_block_coff},
            csize => -1, # Still unknown, will be fill by end_block
        }; # Storing in toc structure availlable info

        # Updating internal info about current block
        $pack->{current_block_off} += $size;
        $pack->{current_block_csize} += $csize;
        $pack->{need_build_toc} = 1;
        if ($pack->{block_size} > 0 && $pack->{current_block_csize} >= $pack->{block_size}) {
            $pack->end_block();
        }
        return 1;
    };
    0
}

sub add {
    my ($pack, $prefix, @files) = @_;
    $prefix ||= "";
    foreach my $file (@files) {
        $file =~ s://+:/:;
        my $srcfile = $prefix ? "$prefix/$file" : $file;
        $pack->{debug}("Adding '%s' as '%s' into archive", $srcfile, $file);

        -l $srcfile and do {
            $pack->add_virtual('l', $file, readlink($srcfile));
            next;
        };
        -d $srcfile and do { # dir simple case
            $pack->add_virtual('d', $file);
            next;
        };
        -f $srcfile and do {
            sysopen(my $htocompress, $srcfile, O_RDONLY) or do {
                $pack->{log}("Can't add $srcfile: $!");
                next;
            };
            $pack->add_virtual('f', $file, $htocompress);
            close($htocompress);
            next;
        };
        $pack->{log}("Can't pack $srcfile");
    }
    1;
}

sub extract_virtual {
    my ($pack, $destfh, $filename) = @_;
    defined($pack->{files}{$filename}) or return -1;
    sysseek($pack->{handle}, $pack->{files}{$filename}->{coff}, 0) == $pack->{files}{$filename}->{coff} or do {
        $pack->{log}("Can't seek to offset $pack->{files}{$filename}->{coff}");
        return -1;
    };
    $pack->uncompress_handle($destfh, $pack->{files}{$filename});
}

sub extract {
    my ($pack, $destdir, @files) = @_;
    foreach my $f ($pack->sort_files_by_packing(@files)) {
        my $dest = $destdir ? "$destdir/$f" : "$f";
        my ($dir) = $dest =~ m!(.*)/.*!;
	$dir ||= ".";
        if (exists($pack->{dir}{$f})) {
            -d $dest || mkpath($dest)
            or $pack->{log}("Unable to create dir $dest: $!");
            next;
        } elsif (exists($pack->{'symlink'}{$f})) {
            -d $dir || mkpath($dir) or
            $pack->{log}("Unable to create dir $dest: $!");
            -l $dest and unlink $dest;
            symlink($pack->{'symlink'}{$f}, $dest)
            or $pack->{log}("Unable to extract symlink $f: $!");
            next;
        } elsif (exists($pack->{files}{$f})) {
	    -d $dir || mkpath($dir) or do {
		$pack->{log}("Unable to create dir $dir");
	    };
	    if (-l $dest) {
		unlink($dest) or do {
		    $pack->{log}("Can't remove link $dest: $!");
		    next; # Don't overwrite a file because where the symlink point to
		};
	    }
	    my $destfh;
	    if (defined $destdir) {
		sysopen($destfh, $dest, O_CREAT | O_TRUNC | O_WRONLY) or do {
		    $pack->{log}("Unable to extract $dest: $!");
		    next;
		};
	    } else {
		$destfh = \*STDOUT;
	    }
	    my $written = $pack->extract_virtual($destfh, $f);
	    $written == -1 and $pack->{log}("Unable to extract file $f");
	    close($destfh);
	    next;
        } else {
            $pack->{log}("Can't find $f in archive");
        }
    }
    1;
}

# Return \@dir, \@files, \@symlink list
sub getcontent {
    my ($pack) = @_;
    return(
        [ keys(%{$pack->{dir}})],
        [ $pack->sort_files_by_packing(keys %{$pack->{files}}) ],
        [ keys(%{$pack->{'symlink'}}) ]
    );
}

sub infofile {
    my ($pack, $file) = @_;
    if (defined($pack->{files}{$file})) {
        return ('f', $pack->{files}{$file}{size});
    } elsif (defined($pack->{'symlink'}{$file})) {
        return ('l', $pack->{'symlink'}{$file});
    } elsif (defined($pack->{dir}{$file})) {
        return ('d', undef);
    } else {
        return(undef, undef);
    }
}

sub list {
    my ($pack, $handle) = @_;
    $handle ||= *STDOUT;
    foreach my $file (keys %{$pack->{dir}}) {
        printf "d %13c %s\n", ' ', $file;
    }
    foreach my $file (keys %{$pack->{'symlink'}}) {
        printf "l %13c %s -> %s\n", ' ', $file, $pack->{'symlink'}{$file};
    }
    foreach my $file ($pack->sort_files_by_packing(keys %{$pack->{files}})) {
        printf "f %12d %s\n", $pack->{files}{$file}{size}, $file;
    }
}

# Print toc info
sub dumptoc {
    my ($pack, $handle) = @_;
    $handle ||= *STDOUT;
    foreach my $file (keys %{$pack->{dir}}) {
        printf $handle "d %13c %s\n", ' ', $file;
    }
    foreach my $file (keys %{$pack->{'symlink'}}) {
        printf $handle "l %13c %s -> %s\n", ' ', $file, $pack->{'symlink'}{$file};
    }
    foreach my $file ($pack->sort_files_by_packing(keys %{$pack->{files}})) {
        printf $handle "f %d %d %d %d %s\n", $pack->{files}{$file}{size}, $pack->{files}{$file}{off}, $pack->{files}{$file}{csize}, $pack->{files}{$file}{coff}, $file;
    }
}

1;

__END__

=head1 NAME

MDV::Packdrakeng - Simple Archive Extractor/Builder

=head1 SYNOPSIS

    use MDV::Packdrakeng;

    # creating an archive
    $pack = MDV::Packdrakeng->new(archive => "myarchive.cz");
    # Adding a few files
    $pack->add("/path/", "file1", "file2");
    # Adding an unamed file
    open($handle, "file");
    $pack->add_virtual("filename", $handle);
    close($handle);

    $pack = undef;

    # extracting an archive
    $pack = MDV::Packdrakeng->open(archive => "myarchive.cz");
    # listing files
    $pack->list();
    # extracting few files
    $pack->extract("/path/", "file1", "file2");
    # extracting data into a file handle
    open($handle, "file");
    $pack->extract_virtual($handle, "filename");
    close($handle);

=head1 DESCRIPTION

C<MDV::Packdrakeng> is a simple indexed archive builder and extractor using
standard compression methods.

=head1 IMPLEMENTATION

Compressed data are stored by block. For example,

 UncompresseddatA1UncompresseddatA2 UncompresseddatA3UncompresseddatA4
 |--- size  1 ---||--- size  2 ---| |--- size  3 ---||--- size  4 ---|
 |<-offset1       |<-offset2        |<-offset3       |<-offset4

gives:

 CompresseD1CompresseD2 CompresseD3CompresseD4
 |--- c. size 1, 2 ---| |--- c. size 3, 4 ---|
 |<-c. offset 1, 2      |<-c. offset 3, 4

A new block is started when its size exceeds the C<block_size> value.

Compressed data are followed by the table of contents (toc), that is, a simple
list of packed files. Each file name is terminated by the C<\n> character:

    dir1
    dir2
    ...
    dirN
    symlink1
    point_file1
    symlink2
    point_file2
    ...
    ...
    symlinkN
    point_fileN
    file1
    file2
    ...
    fileN

The file sizes follows, 4 values are stored for each file:
offset into archive of compressed block, size of compressed block,
offset into block of the file and the file's size.

Finally the archive contains a 64-byte trailer, about the
toc and the archive itself:

    'cz[0', strings 4 bytes
    number of directory, 4 bytes
    number of symlinks, 4 bytes
    number of files, 4 bytes
    the toc size, 4 bytes
    the uncompression command, string of 40 bytes length
    '0]cz', string 4 bytes

=head1 FUNCTIONS

=over 2

=item B<new(%options)>

Creates a new archive.
Options:

=over 4

=item archive

The file name of the archive. If the file doesn't exist, it will be created,
else it will be owerwritten. See C<open>.

=item compress

The application to use to compress, if unspecified, gzip is used.

=item uncompress

The application used to extract data from archive. This option is useless if
you're opening an existing archive (unless you want to force it).
If unset, this value is based on compress command followed by '-d' argument.

=item extern

If you're using gzip, by default MDV::Packdrakeng will use perl-zlib to save system
ressources. This option forces MDV::Packdrakeng to use the external gzip command. This
has no meaning with other compress programs as internal functions are not implemented
yet.

=item comp_level

The compression level passed as an argument to the compression program. By default,
this is set to 6.

=item block_size

The limit size after which we start a new compressed block. The default value
is 400KB. Set it to 0 to be sure a new block will be started for each packed
files, and -1 to never start a new block. Be aware that a big block size will
slow down the file extraction.

=item quiet

Do not output anything, shut up.

=item debug

Print debug messages.

=back

=item B<open(%options)>

Opens an existing archive for extracting or adding files.

The uncompression command is found into the archive, and the compression
command is deduced from it.

If you add files, a new compressed block will be started even if the last block
is smaller than the value of the C<block_size> option. If some compression
options can't be found in the archive, the new preference will be applied.

Options are the same than for the C<new()> function.

=item B<< MDV::Packdrakeng->add_virtual($type, $filename, $data) >>

Adds a file into archive according passed information.
$type gives the type of the file:

  - 'd', the file will be a directory, store as '$filename'. $data is not used.
  - 'l', the file will be a symlink named $filename, pointing to the file whose path
    is given by the string $data.
  - 'f', the file is a normal file, $filename will be its name, $data is either
         an handle to open file, data will be read from current position to the
         end of file, either a string to push as the content of the file.

=item B<< MDV::Packdrakeng->add($prefix, @files) >>

Adds @files into archive located into $prefix. Only directory, files and symlink
will be added. For each file, the path should be relative to $prefix and is
stored as is.

=item B<< MDV::Packdrakeng->extract_virtual(*HANDLE, $filename) >>

Extracts $filename data from archive into the *HANDLE. $filename should be a
normal file.

=item B<< MDV::Packdrakeng->extract($destdir, @files) >>

Extracts @files from the archive into $destdir prefix.

=item B<< MDV::Packdrakeng->getcontent() >>

Returns three arrayrefs describing files files into archive, respectively
directory list, files list and symlink list.

=item B<< MDV::Packdrakeng->infofile($file) >>

Returns type and information about a given file into the archive; that is:

  - 'f' and the the size of the file for a plain file
  - 'l' and the linked file for a symlink
  - 'd' and undef for a directory
  - undef if the file can't be found into archive.

=item B<< MDV::Packdrakeng->infofile($handle) >>

Print to $handle (STDOUT if not specified) the content of the archive.

=item B<< MDV::Packdrakeng->dumptoc($handle) >>

Print to $handle (STDOUT if not specified) the table of content of the archive.

=back

=head1 CHANGELOG

=head2 1.10

=over 4

=item use an oo code

=item add_virtual() now accept a string as file content

=back

=head1 AUTHOR

Olivier Thauvin <nanardon@mandriva.org>,
Rafael Garcia-Suarez <rgarciasuarez@mandriva.com>

Copyright (c) 2005 Mandriva

This module is a from scratch-rewrite of the original C<packdrake> utility. Its
format is fully compatible with the old packdrake.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

If you do not have a copy of the GNU General Public License write to
the Free Software Foundation, Inc., 675 Mass Ave, Cambridge,
MA 02139, USA.

=cut
