use v5.26;
use warnings;

package Mac::Alias;
# ABSTRACT: Read or create macOS alias files
$Mac::Alias::VERSION = '1.01';

use Carp qw(carp croak);
use Fcntl ':seek';
use Path::Tiny;

use Exporter 'import';
our @EXPORT_OK = qw(
	is_alias
	make_alias
	parse_alias
	read_alias
	read_alias_mac
	read_alias_perl
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);


# Finder alias constants

our $MAGIC = "book\0\0\0\0mark\0\0\0\0";

our %ITEM_TYPES= (
	0x1004 => 'pathComponents',  # POSIX path
	0x1005 => 'fileIDs',         # inode path
	0x1010 => 'resourceProps',
	0x1020 => 'fileName',
	0x1040 => 'creationDate',
	0x1054 => 'relativeDirsUp',
	0x1055 => 'relativeDirsDown',
	0x1056 => 'createdWithRelativeURL',
	0x2000 => 'volInfoDepths',
	0x2002 => 'volPath',
	0x2005 => 'volURL',
	0x2010 => 'volName',
	0x2011 => 'volUUID',
	0x2012 => 'volCapacity',
	0x2013 => 'volCreationDate',
	0x2020 => 'volProps',
	0x2030 => 'volWasBoot',
	0x2050 => 'volMountURL',
	0xc001 => 'volHomeDirRelativePathComponentCount',
	0xc011 => 'userName',
	0xc012 => 'userUID',
	0xd001 => 'wasFileIDFormat',
	0xd010 => 'creationOptions',
	0xf017 => 'displayName',
	0xf020 => 'effectiveIconData',
	0xf022 => 'typeBindingData',
	0xfe00 => 'aliasData',       # 'alis' resource
);

our %CREATION_OPTIONS = (
	kCFURLBookmarkCreationMinimalBookmarkMask              => 1 <<  9,
	kCFURLBookmarkCreationPreferFileIDResolutionMask       => 1 <<  8,
	kCFURLBookmarkCreationSecurityScopeAllowOnlyReadAccess => 1 << 12,
	kCFURLBookmarkCreationSuitableForBookmarkFile          => 1 << 10,
	kCFURLBookmarkCreationWithSecurityScope                => 1 << 11,
	kCFURLBookmarkCreationWithoutImplicitSecurityScope     => 1 << 29,
);

our $EPOCH_OFFSET = 3600 * 24 * (365 * 31 + 8);  # kCFAbsoluteTimeIntervalSince1970


sub parse_alias :prototype($) {
	my ($file) = @_;
	
	open my $fh, '<:raw', $file or croak "$file: $!";
	my $success = read $fh, my $header, 20;
	$success and $MAGIC eq substr $header, 0, 16
		or croak "$file: Not a data fork alias";
	
	my $start = unpack 'V', substr $header, -4
		or croak "$file: Not a data fork alias: Header empty";
	
	seek $fh, 0, SEEK_SET;
	read $fh, $header, $start or die "$!" || "Unexpected EOF in alias header";
	
	read $fh, my $next, 4 or die "$!" || "Unexpected EOF in alias data";
	$next = unpack 'V', $next;
	
	my @data;
	my @toc;
	while ((my $item = pop @toc) || $next) {
		
		my $data = $data[$#data];
		
		my ($item_type, $item_offset, $item_flags, $item_ref);
		
		if (ref $item) {  # path element
			($item_offset, $item_ref) = @$item;
		}
		elsif (defined $item) {
			($item_type, $item_offset, $item_flags) = unpack 'V V V', $item;
		}
		else {  # no item left in queue: read next TOC
			$item_offset = $next;
		}
		
		seek $fh, $start + $item_offset, SEEK_SET;
		read $fh, my $chunk_header, 8 or die "$!" || "Unexpected EOF in alias chunk";
		my ($chunk_size, $chunk_type) = unpack 'V l<', $chunk_header;
		my $bytes = (read $fh, my $chunk_data, $chunk_size);
		$bytes == $chunk_size or die "$!" || "Unexpected EOF in alias file";
		
		my $key = $item_offset;
		if ($item_type) {
			$key = $ITEM_TYPES{$item_type};
			$key //= sprintf '%#x', $item_type;
		}
		my $parsed;
		
		if ($chunk_type == -2) {  # TOC
			my ($level, $count);
			($level, $next, $count) = unpack 'V V V', $chunk_data;
			for my $i (reverse 1 .. $count) {
				# It just so happens that the TOC header is the same
				# length as a TOC item, so we start counting at 1
				my $item = substr $chunk_data, 12 * $i, 12;
				push @toc, $item;
			}
			push @data, $data = {};
			($key, $parsed) = (level => $level);
		}
		
		elsif (0x0101 == ($chunk_type & 0xf7ff)) {  # string / URL
			$parsed = substr $chunk_data, 0, $chunk_size;
			utf8::decode $parsed;
		}
		
		elsif (0x0201 == $chunk_type) {  # structured data
			$parsed = $chunk_data;  # TODO
		}
		
		elsif (0x0303 == $chunk_type) {  # 32-bit integer
			$parsed = unpack 'l<', $chunk_data;
			
			# Make readable names available for creationOptions
			if ($item_type && $item_type == 0xd010) {
				my %options = map  { $_ => $parsed }
				              grep { $CREATION_OPTIONS{$_} & $parsed }
				              keys %CREATION_OPTIONS;
				$parsed = %options ? \%options : { $parsed => $parsed };
			}
		}
		
		elsif (0x0304 == $chunk_type) {  # 64-bit integer
			$parsed = $chunk_data;
			eval { $parsed = unpack 'q<', $chunk_data; };
			# eval because unpack 'q' will fail on 32-bit Perls
		}
		
		elsif (0x0400 == $chunk_type) {  # timestamp
			$parsed = $EPOCH_OFFSET + unpack 'd>', $chunk_data;
		}
		
		elsif (0x0500 == ($chunk_type & 0xff00)) {  # boolean
			$parsed = !! ($chunk_type & 0x00ff);
		}
		
		elsif (0x0601 == $chunk_type) {  # path
			$data->{$key} = [];
			my $path_count = $chunk_size / 4;
			my @path = unpack "V[$path_count]", $chunk_data;
			push @toc, map { [ $_, $data->{$key} ] } reverse @path;
			next;
		}
		
		elsif (0x0a01 == $chunk_type) {  # null
			$parsed = undef;
		}
		
		else {
			croak sprintf 'Alias file chunk type %#06x unsupported at offset %i (item %#x) in file %s',
				$chunk_type, $item_offset, $item_type, $file;
		}
		
		if (ref $item_ref eq 'ARRAY') {
			push @$item_ref, $parsed;
		}
		else {
			$data->{$key} = $parsed;
		}
	}
	
	close $fh;
	
	$data[0]->{header} = $header;
	$_->{path} = '/' . join '/', $_->{pathComponents}->@* for grep { $_->{pathComponents} } @data;
	for my $i (1 .. $#data) {
		$data[$i - 1]->{next} = $data[$i];
	}
	return $data[0];
	
}


sub is_alias :prototype($) {
	my ($file) = @_;
	
	# Try to read data fork alias magic number
	open my $fh, '<:raw', $file or return;
	read $fh, my $data, 16 or return;
	close $fh;
	return $data eq $MAGIC;
}


sub read_alias_perl :prototype($) {
	my ($file) = @_;
	
	open my $fh, '<:raw', $file or return;
	read $fh, my $header, 20 or return;
	$MAGIC eq substr $header, 0, 16 or return;
	
	# read header
	my $start = unpack 'V', substr $header, -4 or return;
	seek $fh, $start, SEEK_SET;
	read $fh, my $toc_offset, 4 or return;
	$toc_offset = unpack 'V', $toc_offset;
	
	# read TOC
	my $path_offset;
	seek $fh, $start + $toc_offset + 20, SEEK_SET;
	while (read $fh, my $item, 12) {
		my $item_type;
		($item_type, $path_offset) = unpack 'V V', $item;
		last if $item_type == 0x1004;  # pathComponents
	}
	$path_offset or return;
	
	# read path list
	seek $fh, $start + $path_offset, SEEK_SET;
	read $fh, my $path_header, 8 or return;
	my ($path_size, $path_type) = unpack 'V l<', $path_header;
	$path_type == 0x0601 or return;
	defined read $fh, my $path_chunk, $path_size or return;
	my $path_count = $path_size / 4;
	my @path_offsets = unpack "V[$path_count]", $path_chunk;
	
	# read path elements
	my $path = path('/');
	while ( my $offset = shift @path_offsets ) {
		seek $fh, $start + $offset, SEEK_SET;
		read $fh, my $chunk_header, 8 or return;
		my ($chunk_size, $chunk_type) = unpack 'V l<', $chunk_header;
		$chunk_type == 0x0101 or return;
		read $fh, my $chunk_data, $chunk_size or return;
		utf8::decode $chunk_data;
		$path = $path->child($chunk_data);
	}
	return $path;
}


our %_osascript;
my %SCRIPT_SRC = (
	resolve_alias => <<'EOF',
on run argv
	set thePath to item 1 of argv
	set theAlias to (POSIX file thePath) as alias
	tell application "Finder"
		if kind of theAlias is "Alias" then
			return POSIX path of ((original item of theAlias) as alias)
		end if
	end tell
end run
EOF
	create_alias => <<'EOF',
on run argv
	set theTarget to item 1 of argv
	set theFolder to item 2 of argv
	set theName to item 3 of argv
	set theAlias to missing value
	try
		tell application "Finder"
			make alias file to (POSIX file theTarget) at (POSIX file theFolder)
			set theAlias to the result
			set name of the result to theName
		end tell
	on error errStr number errNum
		if theAlias is not missing value then
			-- Undo make alias
			set theVolume to output volume of (get volume settings)
			set volume output volume 0 -- Silence UI sound effects
			tell application "System Events" to delete theAlias
			set volume output volume theVolume
		end if
		error errStr number errNum
	end try
end run
EOF
);


# Compile AppleScript just-in-time into a temp file when needed
# (because execution of compiled scripts is slightly faster)
sub _osascript :prototype($) {
	my ($scriptname) = @_;
	
	return unless -x '/usr/bin/osacompile' && -x '/usr/bin/osascript';
	$_osascript{_dir} //= Path::Tiny->tempdir('Mac-Alias-XXXXXXXX');
	my $source = $_osascript{_dir}->child("$scriptname.applescript");
	my $compiled = $_osascript{_dir}->child("$scriptname.scpt");
	$source->spew($SCRIPT_SRC{$scriptname});
	my $out = qx(osacompile -x -o "$compiled" "$source" 2>&1);
	if ($?) {
		chomp $out;
		warn $out;
		return;
	}
	return $_osascript{$scriptname} = $compiled;
}


sub read_alias_mac :prototype($) {
	my ($file) = @_;
	
	$file = path($file)->realpath =~ s/(["`\$\\])/\\$1/gr;
	my $script = $_osascript{resolve_alias} // _osascript 'resolve_alias';
	if ( ! $script ) {
		carp "Failed to read alias using Mac-only function";
		return;
	}
	
	my $out = qx(osascript -so "$script" "$file");
	chomp $out;
	utf8::decode($out);
	if ( ! $out || $? ) {
		carp $out if $out && $out !~ m/\(-1700\)/;  # -1700 = can't find original
		return;
	}
	return path($out);
}


sub read_alias :prototype($) {
	my ($file) = @_;
	
	my $target = read_alias_perl $file;
	return $target if $target && $target->exists;
	
	my $script = $_osascript{resolve_alias} // _osascript 'resolve_alias'
		or return $target;
	$file = path($file)->realpath =~ s/(["`\$\\])/\\$1/gr;
	
	my $out = qx(osascript -so "$script" "$file");
	chomp $out;
	utf8::decode($out);
	return path($out) if $out && ! $?;
	return $target;
}


sub make_alias :prototype($$) {
	my ($target, $alias) = @_;
	
	if ( ! -e $target ) {
		carp "Failed to make alias to $target: File not found";
		return;
	}
	
	my $script = $_osascript{create_alias} // _osascript 'create_alias';
	if ( ! $script ) {
		carp "Failed to make alias using Mac-only function";
		return;
	}
	$target = path($target)->realpath =~ s/(["`\$\\])/\\$1/gr;
	$alias = path($alias)->realpath;
	my $folder = $alias->parent =~ s/(["`\$\\])/\\$1/gr;
	my $name = $alias->basename =~ s/(["`\$\\])/\\$1/gr;
	
	my $out = qx(osascript -so "$script" "$target" "$folder" "$name");
	if ($?) {
		chomp $out;
		carp $out;
		return;
	}
	return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mac::Alias - Read or create macOS alias files

=head1 VERSION

version 1.01

=head1 SYNOPSIS

 # Import functions as needed
 use Mac::Alias qw( :all );
 
 # Check files and follow aliases
 $bool = is_alias('/path/to/file');
 $path = read_alias('/path/to/alias');
 
 # Create new aliases
 make_alias('/path/to/original', '/path/to/alias');  # Mac only
 
 # Parse details from an alias file
 %info = parse_alias('/path/to/alias')->%*;
 
 # More fine-grained control over reading aliases
 $path = read_alias_perl($file);
 $path = read_alias_mac($file);  # Mac only

=head1 DESCRIPTION

This Perl module offers functions to read and write macOS Finder
alias files. It reads alias data directly from alias files using
pure Perl. As such, reading aliases works on any OS and file
system. Creating new aliases is only possible on a Mac though.

Aliases are similar to POSIX symlinks in that they contain the
target path and are marked by a file system flag. Unlike symlinks
however, aliases contain a bunch of additional metadata,
including the target file's inode number. This allows the macOS
Finder to update aliases after their target was moved.

This module is effectively a replacement for MacOSX::Alias.

=head1 FUNCTIONS

=head2 is_alias

 $bool = is_alias $file;

Checks whether the given file looks like a macOS Finder alias.
It does so not by looking at the C<kIsAlias> Finder flag, but
rather inspects the file for its contents, so it works on any
operating system.

=head2 make_alias

 $success = make_alias $target, $alias_file;

Creates a new alias file. Returns a truthy value on success.
Mac-only.

Note that this function will happily create aliases of a target
that itself is an alias. The macOS Finder can't handle such
alias chains and is smart enough to avoid creating them, but
this function will do exactly what you ask of it, even if the
result is useless.

=head2 parse_alias

 $data = parse_alias $file;

Parses the given data fork alias file and returns a reference
to a hash that attempts to describe the alias's contents in
human-readable format.

If you're familiar with Apple's Cocoa framework: The result is
similar to what calling C<[NSURL resourceValuesForKeys]> with
C<NSURLBookmarkDetailedDescription> would get you, except
that it skips most of the low-level technical output and it
works on any operating system. For example:

 $data = {
   pathComponents => [ 'Users', ... ],  # alias target path
   fileIDs        => [  21338 , ... ],  # inode path
   creationDate   => 1627592891.72982514,  # POSIX epoch
   volName        => 'Macintosh HD',
   volPath        => '/',      # volume mount point
   volUUID        => '...',    # unique volume ID
   ...
 }

Older aliases may contain an C<alis> record, accessible via
a C<< $data->{aliasData} >> entry. This record can be further
decoded with L<Mac::Alias::Parse/"unpack_alias">.

=head2 read_alias

 $path = read_alias $file;

Returns the target file system path. If no target path can be
determined, an undefined value is returned instead.

This function will first try to parse the alias file by reading
it directly within Perl, and return the result if the target
path exists in the file system. This gives a very fast result
and works on any operating system. However, the result doesn't
account for the possibility of the target having been moved or
deleted.

If direct parsing didn't yield a path that exists, this function
will therefore try to pass on the alias to the macOS Finder for
resolving its new location. The Finder is contacted through the
C<osascript> utility, which is rather slow. If the Finder fails
to resolve the alias target, too (for example, because the target
was deleted), the non-existing path parsed directly from the
alias file earlier is returned, because this is still the best
information available at that point. The same is true on
non-Mac systems.

=head2 read_alias_mac

 $path = read_alias_mac $file;

Like L</"read_alias">, but will I<always> use the Finder alias
resolution through the C<osascript> utility. Slow and Mac-only.

=head2 read_alias_perl

 $path = read_alias_perl $file;

Like L</"read_alias">, but will I<only> use direct parsing of
the alias file and never go through the Finder. Very fast, but
might be inaccurate.

=head1 SECURITY CONSIDERATIONS

Some uses of aliases have a risk of exposing protected parts of
the file system. This is the same risk as is known from symlinks.
For example, consider a Perl web server that resolves aliases,
with one of these aliases pointing to a target located outside
of the web server's root directory, or to a hidden file. Always
make sure to sanitise the target's path as appropriate before
using it.

Resolving aliases on macOS can have side-effects, such as updating
the alias file itself or the mounting of network volumes. Such
side-effects could unintentionally expose information as well.
To avoid side-effects with C<read_alias()>, you can use the
C<read_alias_perl()> variant instead, which will never use the
Finder API to resolve aliases.

=head1 BUGS AND LIMITATIONS

The C<parse_alias()> function currently does not decode structured
properties (C<resourceProps>, C<volProps>) or alias file headers
into a hash. This will hopefully change in a future version.

For unmounted network volumes, C<read_alias_perl()> will currently
return the file system path read from the alias. It should probably
yield the URI instead. The same is true for the Perl-only part of
C<read_alias()>, if the network volume can't be mounted.

This module currently doesn't handle L<resource fork
aliases|Mac::Alias::Format/"RESOURCE FORK ALIASES"> at all.
Because the last macOS Finder version that created resource fork
aliases was released a long time ago (back in 2007 or so), this
may not be a big deal.

=head1 SEE ALSO

L<Mac::Alias::Format>

L<Dist::Zilla::Plugin::PruneAliases>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
