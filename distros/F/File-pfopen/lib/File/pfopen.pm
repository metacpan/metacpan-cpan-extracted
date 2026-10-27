package File::pfopen;

# Author Nigel Horne: njh@nigelhorne.com
# Copyright (C) 2017-2026 Nigel Horne

# Usage is subject to the GPL2 licence terms.

use strict;
use warnings;
use Carp;
use Config;
use File::Spec;
use Scalar::Util qw(tainted);

require Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = ('pfopen');

=head1 NAME

File::pfopen - Try hard to find a file

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

Find a configuration file in the first of several places, and read it:

    use File::pfopen 'pfopen';

    my $fh = pfopen('/etc/myapp:/usr/local/etc/myapp', 'config', 'yml:json', '<');
    if($fh) {
        my @lines = <$fh>;
        close($fh);
    }

Find out which file was found, by asking for two return values:

    use File::pfopen 'pfopen';

    my ($fh, $filename) = pfopen('/etc/myapp:/usr/local/etc/myapp', 'config', 'yml:json', '<');
    print "Using $filename\n" if($fh);

Build the list of directories as an array, which works the same on every
operating system:

    use File::Spec;
    use File::pfopen 'pfopen';

    my @dirs = (File::Spec->catdir($ENV{'HOME'}, '.myapp'), File::Spec->tmpdir());
    my $fh = pfopen(\@dirs, 'state', 'dat', '<');

Use a full filename, with no list of suffixes:

    use File::pfopen 'pfopen';

    my $fh = pfopen('/var/tmp:/tmp', 'report.csv', undef, '<');

Use drive letters on Windows, where the directories are separated by ';':

    use File::pfopen 'pfopen';

    my $fh = pfopen('C:\myapp;D:\shared\myapp', 'config', 'ini', '<');

Open a found file to add to it, and read text in UTF-8:

    use File::pfopen 'pfopen';

    my $log = pfopen(['/var/log/myapp', '/tmp'], 'activity', 'log', '>>');
    my $text = pfopen(['/usr/share/myapp'], 'messages', 'txt', '<:encoding(UTF-8)');

=head1 DESCRIPTION

This module has one function, C<pfopen>.
You give it a list of directories, a filename, and optionally a list of endings
(called suffixes) for the filename.
It looks for the file in each directory, in order,
and opens the first one that it finds.

For example, with the directories C</etc> and C</tmp>,
the filename C<foo> and the suffixes C<txt:bin>,
it tries these files, in this order, and stops at the first one that it can open:

    /etc/foo.txt
    /etc/foo.bin
    /tmp/foo.txt
    /tmp/foo.bin

It is similar to the way that a shell uses the C<PATH> environment variable to find a program.

The function remembers each file that it finds.
If you ask for the same thing again, it opens the same file again without looking.
See L</COMMON PITFALLS>.

=head1 SUBROUTINES/METHODS

=head2 pfopen($path, $prefix, $suffixes, $mode)

    my $fh = pfopen($path, $prefix);
    my $fh = pfopen($path, $prefix, $suffixes);
    my $fh = pfopen($path, $prefix, $suffixes, $mode);
    my ($fh, $filename) = pfopen($path, $prefix, $suffixes, $mode);

=head3 Purpose

Look in a list of directories for a file, optionally trying a list of suffixes,
and open the first file that it finds.

It only finds files. It never returns a directory.
It looks in the directories in order.
In each directory, it tries the suffixes in order.
So a file in an earlier directory is used before a file with an earlier suffix.

It remembers each successful search until the program ends.
When it is called again with the same C<$path>, C<$prefix> and C<$suffixes>,
it opens the same file again and does not search.
If that file can no longer be opened, it forgets the file and searches again.
A string and an array reference that give the same directories count as the same C<$path>,
so C<['/a', '/b']> and C<'/a:/b'> share one remembered file.

=head3 Arguments

=over 4

=item C<$path> (required)

The directories to look in.
This is one of:

=over 4

=item * A string. The directories are separated by the operating system's path separator.
This is ':' on UNIX and ';' on Windows, the same as in the C<PATH> environment variable.
Perl stores this character in C<$Config{path_sep}>.
Because Windows uses ';', you can use drive letters, for example C<'C:\tmp;D:\data'>.

=item * A reference to an array of directories, for example C<['/etc', '/tmp']>.
Use this when a directory name contains the separator character.

=back

These directories are skipped without an error:
directories that do not exist, names that are not directories,
empty strings, C<undef> values, and names that contain a NUL character.
A relative directory, such as C<'.'>, is relative to the current directory when C<pfopen> is called.

=item C<$prefix> (required)

The name of the file to find, without its suffix. For example, C<'config'>.
It must not be empty.
The name is used exactly as given.
Characters such as C<|>, C<E<lt>> and C<E<gt>> have no special meaning.

=item C<$suffixes> (optional)

A list of suffixes to try, separated by ':' on all operating systems.
For example, C<'yml:json'> tries C<config.yml> and then C<config.json>.
Do not include the dot: C<pfopen> adds it.

If this is not given, or is C<undef>, C<$prefix> is used as the whole filename.
If this is an empty string, nothing can be found.

=item C<$mode> (optional)

How to open the file. This is the same as the second argument to Perl's C<open> function.
If it is not given, or is false (C<undef>, C<''> or C<0>),
the file is opened to read and write (C<'+E<lt>'>).

Only these modes are allowed:

    <     read
    >     write (the file is emptied first)
    >>    add to the end of the file
    +<    read and write
    +>    read and write (the file is emptied first)
    +>>   read and add to the end of the file

After the mode you can add I/O layers, for example C<'E<lt>:raw'> or C<'E<lt>:encoding(UTF-8)'>.
Other modes, such as the pipe mode C<'-|'>, are not allowed,
so the file that is found can never be run as a program.

=back

=head3 Returns

=over 4

=item * When the file is found and opened, and C<pfopen> is called in scalar context
(one return value), it returns the open file handle.

=item * When the file is found and opened, and C<pfopen> is called in list context
(two return values), it returns the open file handle and the full filename that was opened.
The filename is built from the directory, so it is relative if the directory was relative.

=item * When no file is found, or no file can be opened in C<$mode>,
it returns C<undef> in scalar context and an empty list in list context.
This also happens when C<$prefix> or C<$suffixes> contains a NUL character,
because a filename can never contain one.

=back

=head3 Side Effects

It remembers the filename of each successful search, as described in L</Purpose>.
It also forgets a remembered filename when that file can no longer be opened.
In taint mode, a call with any tainted argument always searches,
and doesn't remember what it finds,
so a remembered filename can't hide or add taint.

It does not change C<$!>, C<$@>, C<$_>, or any of its arguments.

=head3 Errors

It croaks (dies with an error message that gives your file and line number) with:

=over 4

=item C<Usage: pfopen($path, $prefix, [$suffixes, [$mode]])>

when C<$path> or C<$prefix> is missing or C<undef>, or C<$prefix> is an empty string.

=item C<pfopen: path must be a string or an array reference>

when C<$path> is a reference to anything except an array.
This includes an object that is a blessed array.

=item C<pfopen: invalid mode '$mode'>

when C<$mode> is not one of the modes listed in L</Arguments>, for example C<'-|'>.

=back

It does not croak or warn when a file can't be found or can't be opened.

When Perl runs in taint mode (C<-T>) and C<$path> or C<$prefix> is tainted,
a mode that writes, including the default C<'+E<lt>'>,
dies with Perl's own error C<Insecure dependency in open while running with -T switch>.
Use the mode C<'E<lt>'>, or untaint the arguments first.

=head3 Usage Example

    use File::pfopen 'pfopen';

    my ($fh, $filename) = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', 'txt:bin');
    my $fh2 = pfopen('/tmp:/var/tmp:/home/njh/tmp', 'foo', undef, '<');
    my $fh3 = pfopen(['/tmp', '/var/tmp'], 'foo', 'txt');

=head3 API SPECIFICATION

The arguments are positional.
The schemas are in the format of L<Params::Validate::Strict> and L<Return::Set>.
The output schema describes the list that is returned in list context.
In scalar context the return value is the first element of that list, or C<undef>.

=head4 Input

    [
        { name => 'path', type => ['string', 'arrayref'], position => 0 },
        { name => 'prefix', type => 'string', min => 1, position => 1 },
        { name => 'suffixes', type => 'string', optional => 1, position => 2 },
        { name => 'mode', type => 'string', optional => 1, default => '+<', position => 3, matches => qr/\A\+?(?:<|>>?)(?::.*)?\z/s },
    ]

=head4 Output

    {
        type => 'arrayref',
        min => 0,
        max => 2,
        callback => sub { (scalar(@{$_[0]}) == 0) || ((scalar(@{$_[0]}) == 2) && defined(Scalar::Util::openhandle($_[0]->[0])) && !ref($_[0]->[1])) },
    }

=cut

sub pfopen
{
	my ($path, $prefix, $suffixes, $mode) = @_;

	local $!;	# Failed file tests set it, and the caller hasn't asked for an error code

	if((!defined($path)) || (!defined($prefix)) || (length($prefix) == 0)) {
		croak('Usage: pfopen($path, $prefix, [$suffixes, [$mode]])');
	}
	if(ref($path) && (ref($path) ne 'ARRAY')) {
		croak('pfopen: path must be a string or an array reference');
	}

	$mode ||= '+<';	# defaults to opening RW

	# Allowing other modes would let '-|' or '|-' run the found file as a command
	if($mode !~ /\A\+?(?:<|>>?)(?::.*)?\z/s) {
		croak("pfopen: invalid mode '$mode'");
	}

	# A NUL can never be in a filename, so don't bother looking.
	#	It would only give warnings from the file tests
	return if(index($prefix, "\0") >= 0);
	return if(defined($suffixes) && (index($suffixes, "\0") >= 0));

	my @dirs = grep { defined($_) && length($_) && (index($_, "\0") < 0) }
		(ref($path) ? @{$path} : split(/\Q$Config{path_sep}\E/, $path));

	# NUL can't appear in a filename, so different arguments can't give the same key
	my $candidate = join("\0", $prefix, defined($suffixes) ? $suffixes : '', @dirs);
	our $savedpaths;

	# A remembered name would hide the taint of these arguments, letting a write
	#	succeed that taint mode should stop, or the other way around
	my $remember = !(tainted($candidate) || tainted($mode));

	# Return cached filename if available
	if($remember && (my $rc = $savedpaths->{$candidate})) {
		if((!-d $rc) && open(my $fh, $mode, $rc)) {
			return wantarray ? ($fh, $rc) : $fh;
		}
		delete $savedpaths->{$candidate};	# Failed to open cached file
	}

	foreach my $dir (@dirs) {
		next unless -d $dir;

		foreach my $suffix (defined($suffixes) ? split(/:/, $suffixes) : undef) {
			my $rc = File::Spec->catfile($dir, defined $suffix ? "$prefix.$suffix" : $prefix);

			# Opening a directory with '<' succeeds, but it isn't what was asked for
			next if(-d $rc);
			next unless -r _;

			# In taint mode this dies if $rc is tainted and $mode writes, see "Errors" in the POD
			open(my $fh, $mode, $rc) or next;

			$savedpaths->{$candidate} = $rc if($remember);
			return wantarray ? ($fh, $rc) : $fh;
		}
	}

	return;
}


=head1 COMMON PITFALLS

=over 4

=item * B<The default mode is read and write.>
If you only want to read, give the mode C<'E<lt>'>.
Without it, a file that you can read but not write is skipped,
and C<pfopen> returns nothing even though the file exists.

=item * B<The mode is the fourth argument, not the third.>
To give a mode without suffixes, pass C<undef> as the suffixes:
C<pfopen($path, 'foo.txt', undef, 'E<lt>')>.
C<pfopen($path, 'foo.txt', 'E<lt>')> looks for a file called C<foo.txt.E<lt>>.

=item * B<The modes C<'E<gt>'> and C<'+E<gt>'> empty the file.>
C<pfopen> only finds files that already exist,
so these modes always delete the contents of an existing file.
Use C<'E<gt>E<gt>'> to add to the end of a file instead.

=item * B<Found files are remembered.>
After a file is found, a later call with the same arguments opens the same file without searching.
If you then create the file in an earlier directory, or change to a different current directory,
the remembered file is still used, as long as it can still be opened.

=item * B<Use ';' between directories on Windows.>
On Windows the separator is ';', not ':', so C<'C:\a:C:\b'> is one directory, not two.
To write code that works on all operating systems, pass an array reference.

=item * B<Suffixes are always separated by ':'.>
This is true on Windows too. Do not include the dot: C<'.txt'> looks for C<foo..txt>.

=item * B<C<undef> and an empty string mean different things.>
C<undef> suffixes mean "use C<$prefix> as the whole filename".
An empty string of suffixes means "try no suffixes", so nothing is found.
C<undef> and empty directories in C<$path> are skipped.
A missing C<$path> or C<$prefix> is an error.

=item * B<Check the return value before you use it.>
Nothing is found when the file is missing, unreadable, a directory, or can't be opened in C<$mode>.
There is no warning, and C<$!> is not set, so you can't tell these cases apart.

    my ($fh, $filename) = pfopen($path, 'foo', 'txt', '<');
    die "Can't find foo.txt in $path" unless($fh);

=item * B<C<$prefix> can contain directories.>
C<pfopen('/etc', '../tmp/foo')> looks in C</etc/../tmp>.
If C<$prefix> comes from a user, check it before you call C<pfopen>.

=back

=head1 ENCODING

=over 4

=item * B<Directory names, C<$prefix> and C<$suffixes>>

These are filenames, and on UNIX a filename is a string of bytes.
Names in any language, including emojis, work when you pass them as UTF-8 encoded bytes,
which is how most UNIX systems store filenames:

    use Encode qw(encode);
    my $fh = pfopen($dir, encode('UTF-8', $name), 'txt', '<');

If you pass a Perl character string instead,
the result depends on how Perl stores the string internally.
For example, C<"caf\x{e9}"> may or may not find C<cafE<eacute>.txt>.
Encode the name to make the result predictable.

On Windows, Perl's C<open> function uses the system's "ANSI" code page for filenames,
so characters that are not in that code page, such as emojis, can't be used in names there.

A NUL character can't be in any name. See L</Returns>.

=item * B<C<$mode>>

The mode itself must be ASCII.
The layer in the mode can be any layer that Perl supports.

=item * B<The contents of the file>

C<pfopen> does not read the file, so the contents can be in any encoding.
To read or write text as characters, add a layer to the mode,
for example C<'E<lt>:encoding(UTF-8)'>.
Then all of Unicode, including emojis, is read and written correctly.
Without a layer, the file handle reads and writes bytes.

=back

=head1 BUGS

In taint mode, writing to a file with a tainted name dies. See L</Errors>.

Would be better if the mode and suffixes options were the other way around, but it's too late to change that now.

Please report any bugs or feature requests to C<bug-file-pfopen at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-pfopen>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::pfopen

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/File-pfopen>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=File-pfopen>

=item * CPANTS

L<http://cpants.cpanauthors.org/dist/File-pfopen>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=File-pfopen>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=File::pfopen>

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=encoding utf-8

=head1 FORMAL SPECIFICATION

This section describes C<pfopen> in the Z notation.
You do not need to read it to use the module.

=head2 pfopen

    [PATH, NAME, HANDLE]

    FILEMODE == { "<", ">", ">>", "+<", "+>", "+>>" }
    MODE == { m : seq CHAR | (∃ f : FILEMODE; l : seq CHAR • m = f ⁀ l ∧ (l = ⟨⟩ ∨ head l = ':')) }
    KEY == NAME × seq NAME × seq PATH

    isFile, readable : ℙ PATH
    opens : PATH ↔ MODE

    ┌─ PfopenState ───────────────────────────────────────────────────
    │ cache : KEY ⇸ PATH
    └─────────────────────────────────────────────────────────────────

    ┌─ InitPfopenState ───────────────────────────────────────────────
    │ PfopenState'
    ├─────────────────────────────────────────────────────────────────
    │ cache' = ∅
    └─────────────────────────────────────────────────────────────────

    ┌─ PfopenArgs ────────────────────────────────────────────────────
    │ dirs? : seq PATH
    │ prefix? : NAME
    │ suffixes? : seq NAME ∪ {⊥}
    │ mode? : MODE
    │ key : KEY
    │ candidates : seq PATH
    │ usable : ℙ PATH
    ├─────────────────────────────────────────────────────────────────
    │ prefix? ≠ ⟨⟩
    │ '\0' ∉ ran prefix?
    │ key = (prefix?, suffixes?, dirs?)
    │ suffixes? = ⊥ ⇒ candidates = ⟨ d / prefix? | d ← dirs? ⟩
    │ suffixes? ≠ ⊥ ⇒ candidates = ⟨ d / (prefix? ⁀ "." ⁀ s) | d ← dirs?, s ← suffixes? ⟩
    │ usable = { c : PATH | c ∈ isFile ∧ c ∈ readable ∧ (c, mode?) ∈ opens }
    └─────────────────────────────────────────────────────────────────

    ┌─ PfopenRemembered ──────────────────────────────────────────────
    │ ΞPfopenState
    │ PfopenArgs
    │ result! : HANDLE × PATH
    ├─────────────────────────────────────────────────────────────────
    │ key ∈ dom cache ∧ cache(key) ∈ usable
    │ second(result!) = cache(key)
    └─────────────────────────────────────────────────────────────────

    ┌─ PfopenFound ───────────────────────────────────────────────────
    │ ΔPfopenState
    │ PfopenArgs
    │ result! : HANDLE × PATH
    ├─────────────────────────────────────────────────────────────────
    │ ¬(key ∈ dom cache ∧ cache(key) ∈ usable)
    │ ran candidates ∩ usable ≠ ∅
    │ second(result!) = head(candidates ↾ usable)
    │ cache' = cache ⊕ { key ↦ second(result!) }
    └─────────────────────────────────────────────────────────────────

    ┌─ PfopenNotFound ────────────────────────────────────────────────
    │ ΔPfopenState
    │ PfopenArgs
    │ result! : {∅}
    ├─────────────────────────────────────────────────────────────────
    │ ¬(key ∈ dom cache ∧ cache(key) ∈ usable)
    │ ran candidates ∩ usable = ∅
    │ cache' = {key} ⩤ cache
    └─────────────────────────────────────────────────────────────────

    ┌─ PfopenError ───────────────────────────────────────────────────
    │ ΞPfopenState
    │ path?, prefix?, mode? : seq CHAR ∪ {⊥}
    │ error! : seq CHAR
    ├─────────────────────────────────────────────────────────────────
    │ (path? = ⊥ ∨ prefix? = ⊥ ∨ prefix? = ⟨⟩)
    │     ⇒ error! = "Usage: pfopen($path, $prefix, [$suffixes, [$mode]])"
    │ path? is a reference that is not an unblessed array
    │     ⇒ error! = "pfopen: path must be a string or an array reference"
    │ mode? ∉ MODE ∪ {⊥, "", "0"}
    │     ⇒ error! = "pfopen: invalid mode '" ⁀ mode? ⁀ "'"
    └─────────────────────────────────────────────────────────────────

    pfopen ≙ PfopenError ∨ PfopenRemembered ∨ PfopenFound ∨ PfopenNotFound

The errors are checked in the order shown, and the first one that applies is raised.
A C<$prefix> or C<$suffixes> containing NUL gives C<PfopenNotFound> without changing C<cache>.
In taint mode, a call with a tainted argument behaves as if C<key> were not in C<dom cache>, and C<cache' = cache>.

=head1 STATE DIAGRAM

C<pfopen> keeps one piece of state for each different set of arguments (C<$path>, C<$prefix>, C<$suffixes>):
either it remembers a filename for them, or it doesn't.
All lookups start in the FORGOTTEN state when the program starts.
The labels T1 to T7 are explained in the table below.

                    program starts
                          |
                          v
                   +-------------+
            +----->|  FORGOTTEN  |<-----+
            |      +-------------+      |
            |        |    |    |        |
            +--------+    |    |        |
            T1, T2        |    |        |
                          |    | T3     |
                          |    v        |
                   +-------------+      |
            +----->| REMEMBERED  |------+
            |      +-------------+   T7
            |        |    |
            +--------+    |
            T4, T5, T6    |

    Label  From        Trigger (a call to pfopen)       Action                       To
    -----  ----------  -------------------------------  ---------------------------  ----------
    T1     FORGOTTEN   bad argument                     croak with an error          FORGOTTEN
    T2     FORGOTTEN   search finds no usable file      return nothing               FORGOTTEN
    T3     FORGOTTEN   search finds a usable file       open it, remember the        REMEMBERED
                                                        filename, return the handle
    T4     REMEMBERED  bad argument                     croak with an error          REMEMBERED
    T5     REMEMBERED  remembered file opens            open it, return the handle;  REMEMBERED
                                                        don't search
    T6     REMEMBERED  remembered file fails, and a     open it, remember the new    REMEMBERED
                       search finds another usable file filename, return the handle
    T7     REMEMBERED  remembered file fails, and a     forget the filename,         FORGOTTEN
                       search finds no usable file      return nothing

"Return nothing" means C<undef> in scalar context and an empty list in list context.

Notes:

=over 4

=item * "Bad argument" means one of the croaks in L</Errors>.
It is checked before anything else, so it never changes the state.

=item * A C<$prefix> or C<$suffixes> containing a NUL character returns nothing in either state, and doesn't change the state.

=item * In taint mode, a call with a tainted argument always searches, as if in the FORGOTTEN state, and never changes the state.

=item * "Fails" means the remembered file is gone, is now a directory, or can't be opened in the C<$mode> of this call.

=item * There is no way to forget all the remembered files, except by ending the program.

=back

=head1 LICENCE AND COPYRIGHT

Copyright 2017-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
