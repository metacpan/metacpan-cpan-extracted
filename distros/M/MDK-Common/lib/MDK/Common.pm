package MDK::Common;

=head1 NAME

MDK::Common - miscellaneous functions

=head1 SYNOPSIS

    use MDK::Common;
    # exports all functions, equivalent to

    use MDK::Common::DataStructure qw(:all);
    use MDK::Common::File qw(:all);
    use MDK::Common::Func qw(:all);
    use MDK::Common::Math qw(:all);
    use MDK::Common::String qw(:all);
    use MDK::Common::System qw(:all);
    use MDK::Common::Various qw(:all);

=head1 DESCRIPTION

C<MDK::Common> is a collection of packages containing various simple functions:
L<MDK::Common::DataStructure>,
L<MDK::Common::File>,
L<MDK::Common::Func>,
L<MDK::Common::Math>,
L<MDK::Common::String>,
L<MDK::Common::System>,
L<MDK::Common::Various>.

=head1 EXPORTS from MDK::Common::DataStructure.pm

=over

=item sort_numbers(LIST)

numerical sort (small numbers at beginning)

=item ikeys(HASH)

aka I<sorted integer keys>, as simple as C<sort { $a E<lt>=E<gt> $b } keys>

=item add2hash(HASH REF, HASH REF)

adds to the first hash the second hash if the key/value is not already there

=item add2hash_

adds to the first hash the second hash if the key is not already there

=item put_in_hash

adds to the first hash the second hash, crushing existing key/values

=item member(SCALAR, LIST)

is the value in the list?

=item invbool(SCALAR REF)

toggles the boolean value

=item listlength(LIST)

returns the length of the list. Useful in list (opposed to array) context:

    sub f { "a", "b" } 
    my $l = listlength f();

whereas C<scalar f()> would return "b"

=item deref(REF)

de-reference

=item deref_array(REF)

de-reference arrays:

    deref_array [ "a", "b" ]	#=> ("a", "b")
    deref_array "a" 		#=> "a" 

=item is_empty_array_ref(SCALAR)

is the scalar undefined or is the array empty

=item is_empty_hash_ref(SCALAR)

is the scalar undefined or is the hash empty

=item uniq(LIST)

returns the list with no duplicates (keeping the first elements)

=item uniq_ { CODE } LIST

returns the list with no duplicates according to the scalar results of CODE on each element of LIST (keeping the first elements)

    uniq_ { $_->[1] } [ 1, "fo" ], [ 2, "fob" ], [ 3, "fo" ], [ 4, "bar" ]

gives [ 1, "fo" ], [ 2, "fob" ], [ 4, "bar" ]

=item difference2(ARRAY REF, ARRAY REF)

returns the first list without the element of the second list

=item intersection(ARRAY REF, ARRAY REF, ...)

returns the elements which are in all lists

=item next_val_in_array(SCALAR, ARRAY REF)

finds the value that follow the scalar in the list (circular):
C<next_val_in_array(3, [1, 2, 3])> gives C<1>
(do not use a list with duplicates)

=item group_by2(LIST)

interprets the list as an ordered hash, returns a list of [key,value]:
C<group_by2(1 => 2, 3 => 4, 5 => 6)> gives C<[1,2], [3,4], [5,6]>

=item list2kv(LIST)

interprets the list as an ordered hash, returns the keys and the values:
C<list2kv(1 => 2, 3 => 4, 5 => 6)> gives C<[1,3,5], [2,4,6]>

=back

=head1 EXPORTS from MDK::Common::File.pm

=over

=item dirname(FILENAME)

=item basename(FILENAME)

returns the dirname/basename of the file name

=item cat_(FILES)

returns the files contents: in scalar context it returns a single string, in
array context it returns the lines.

If no file is found, undef is returned

=item cat_or_die(FILENAME)

same as C<cat_> but dies when something goes wrong

=item cat_utf8(FILES)

same as C(<cat_>) but reads utf8 encoded strings

=item cat_utf8_or_die(FILES)

same as C(<cat_or_die>) but reads utf8 encoded strings

=item cat__(FILEHANDLE REF)

returns the file content: in scalar context it returns a single string, in
array context it returns the lines

=item output(FILENAME, LIST)

creates a file and outputs the list (if the file exists, it is clobbered)

=item output_utf8(FILENAME, LIST)

same as C(<output>) but writes utf8 encoded strings

=item secured_output(FILENAME, LIST)

likes output() but prevents insecured usage (it dies if somebody try
to exploit the race window between unlink() and creat())

=item append_to_file(FILENAME, LIST)

add the LIST at the end of the file

=item output_p(FILENAME, LIST)

just like C<output> but creates directories if needed

=item output_with_perm(FILENAME, PERMISSION, LIST)

same as C<output_p> but sets FILENAME permission to PERMISSION (using chmod)

=item mkdir_p(DIRNAME)

creates the directory (make parent directories as needed)

=item rm_rf(FILES)

remove the files (including sub-directories)

=item cp_f(FILES, DEST)

just like "cp -f"

=item cp_af(FILES, DEST)

just like "cp -af"

=item cp_afx(FILES, DEST)

just like "cp -afx"

=item linkf(SOURCE, DESTINATION)

=item symlinkf(SOURCE, DESTINATION)

=item renamef(SOURCE, DESTINATION)

same as link/symlink/rename but removes the destination file first

=item touch(FILENAME)

ensure the file exists, set the modification time to current time

=item all(DIRNAME)

returns all the file in directory (except "." and "..")

=item all_files_rec(DIRNAME)

returns all the files in directory and the sub-directories (except "." and "..")

=item glob_(STRING)

simple version of C<glob>: doesn't handle wildcards in directory (eg:
*/foo.c), nor special constructs (eg: [0-9] or {a,b})

=item substInFile { CODE } FILENAME

executes the code for each line of the file. You can know the end of the file
is reached using C<eof>

=item expand_symlinks(FILENAME)

expand the symlinks in the absolute filename:
C<expand_symlinks("/etc/X11/X")> gives "/usr/bin/Xorg"

=item openFileMaybeCompressed(FILENAME)

opens the file and returns the file handle. If the file is not found, tries to
gunzip the file + .gz

=item catMaybeCompressed(FILENAME)

cat_ alike. If the file is not found, tries to gunzip the file + .gz

=back

=head1 EXPORTS from MDK::Common::Func.pm

=over

=item may_apply(CODE REF, SCALAR)

C<may_apply($f, $v)> is C<$f ? $f-E<gt>($v) : $v>

=item may_apply(CODE REF, SCALAR, SCALAR)

C<may_apply($f, $v, $otherwise)> is C<$f ? $f-E<gt>($v) : $otherwise>

=item if_(BOOL, LIST)

special constructs to workaround a missing perl feature:
C<if_($b, "a", "b")> is C<$b ? ("a", "b") : ()>

example of use: C<f("a", if_(arch() =~ /i.86/, "b"), "c")> which is not the
same as C<f("a", arch()=~ /i.86/ && "b", "c")>

=item if__(SCALAR, LIST)

if_ alike. Test if the value is defined

=item fold_left { CODE } LIST

if you don't know fold_left (aka foldl), don't use it ;p

    fold_left { $::a + $::b } 1, 3, 6

gives 10 (aka 1+3+6)

=item mapn { CODE } ARRAY REF, ARRAY REF, ...

map lists in parallel:

    mapn { $_[0] + $_[1] } [1, 2], [2, 4] # gives 3, 6
    mapn { $_[0] + $_[1] + $_[2] } [1, 2], [2, 4], [3, 6] gives 6, 12

=item mapn_ { CODE } ARRAY REF, ARRAY REF, ... 

mapn alike. The difference is what to do when the lists have not the same
length: mapn takes the minimum common elements, mapn_ takes the maximum list
length and extend the lists with undef values

=item find { CODE } LIST

returns the first element where CODE returns true (or returns undef)

    find { /foo/ } "fo", "fob", "foobar", "foobir"

gives "foobar"

=item any { CODE } LIST

returns 1 if CODE returns true for an element in LIST (otherwise returns 0)

    any { /foo/ } "fo", "fob", "foobar", "foobir"

gives 1

=item every { CODE } LIST

returns 1 if CODE returns true for B<every> element in LIST (otherwise returns 0)

    every { /foo/ } "fo", "fob", "foobar", "foobir"

gives 0

=item map_index { CODE } LIST

just like C<map>, but set C<$::i> to the current index in the list:

    map_index { "$::i $_" } "a", "b"

gives "0 a", "1 b"

=item each_index { CODE } LIST

just like C<map_index>, but doesn't return anything

    each_index { print "$::i $_\n" } "a", "b"

prints "0 a", "1 b"

=item grep_index { CODE } LIST

just like C<grep>, but set C<$::i> to the current index in the list:

    grep_index { $::i == $_ } 0, 2, 2, 3

gives (0, 2, 3)

=item find_index { CODE } LIST

returns the index of the first element where CODE returns true (or throws an exception)

    find_index { /foo/ } "fo", "fob", "foobar", "foobir"

gives 2

=item map_each { CODE } HASH

returns the list of results of CODE applied with $::a (key) and $::b (value)

    map_each { "$::a is $::b" } 1=>2, 3=>4

gives "1 is 2", "3 is 4"

=item grep_each { CODE } HASH

returns the hash key/value for which CODE applied with $::a (key) and $::b
(value) is true:

    grep_each { $::b == 2 } 1=>2, 3=>4, 4=>2

gives 1=>2, 4=>2

=item partition { CODE } LIST

alike C<grep>, but returns both the list of matching elements and non matching elements

    my ($greater, $lower) = partition { $_ > 3 } 4, 2, 8, 0, 1

gives $greater = [ 4, 8 ] and $lower = [ 2, 0, 1 ]

=item before_leaving { CODE }

the code will be executed when the current block is finished

    # create $tmp_file
    my $b = before_leaving { unlink $tmp_file };
    # some code that may throw an exception, the "before_leaving" ensures the
    # $tmp_file will be removed

=item cdie(SCALAR)

aka I<conditional die>. If a C<cdie> is catched, the execution continues
B<after> the cdie, not where it was catched (as happens with die & eval)

If a C<cdie> is not catched, it mutates in real exception that can be catched
with C<eval>

cdie is useful when you want to warn about something weird, but when you can
go on. In that case, you cdie "something weird happened", and the caller
decide wether to go on or not. Especially nice for libraries.

=item catch_cdie { CODE1 } sub { CODE2 }

If a C<cdie> occurs while executing CODE1, CODE2 is executed. If CODE2
returns true, the C<cdie> is catched.

=back

=head1 EXPORTS from MDK::Common::Math.pm

=over

=item $PI

the well-known constant 

=item even(INT)

=item odd(INT)

is the number even or odd?

=item sqr(FLOAT)

C<sqr(3)> gives C<9>

=item sign(FLOAT)

returns a value in { -1, 0, 1 }

=item round(FLOAT)

C<round(1.2)> gives C<1>, C<round(1.6)> gives C<2>

=item round_up(FLOAT, INT)

returns the number rounded up to the modulo:
C<round_up(11,10)> gives C<20>

=item round_down(FLOAT, INT)

returns the number rounded down to the modulo:
C<round_down(11,10)> gives C<10>

=item divide(INT, INT)

integer division (which is lacking in perl). In array context, also returns the remainder:
C<($a, $b) = divide(10,3)> gives C<$a is 3> and C<$b is 1>

=item min(LIST)

=item max(LIST)

returns the minimum/maximum number in the list

=item or_(LIST)

is there a true value in the list?

=item and_(LIST)

are all values true in the list?

=item sum(LIST)

=item product(LIST)

returns the sum/product of all the element in the list

=item factorial(INT)

C<factorial(4)> gives C<24> (4*3*2)

=back

=head1 OTHER in MDK::Common::Math.pm

the following functions are provided, but not exported:

=over

=item factorize(INT)

C<factorize(40)> gives C<([2,3], [5,1])> as S<40 = 2^3 + 5^1>

=item decimal2fraction(FLOAT)

C<decimal2fraction(1.3333333333)> gives C<(4, 3)> 
($PRECISION is used to decide which precision to use)

=item poly2(a,b,c)

Solves the a*x2+b*x+c=0 polynomial:
C<poly2(1,0,-1)> gives C<(1, -1)>

=item permutations(n,p)

A(n,p)

=item combinaisons(n,p)

C(n,p)

=back

=head1 EXPORTS from MDK::Common::String.pm

=over

=item bestMatchSentence(STRING, LIST)

finds in the list the best corresponding string

=item formatList(INT, LIST)

if the list size is bigger than INT, replace the remaining elements with "...".

formatList(3, qw(a b c d e))  # => "a, b, c, ..."

=item formatError(STRING)

the string is something like "error at foo.pl line 2" that you get when
catching an exception. formatError will remove the "at ..." so that you can
nicely display the returned string to the user

=item formatTimeRaw(TIME)

the TIME is an epoch as returned by C<time>, the formatted time looks like "23:59:00"

=item formatLines(STRING)

remove "\n"s when the next line doesn't start with a space. Otherwise keep
"\n"s to keep the indentation.

=item formatAlaTeX(STRING)

handle carriage return just like LaTeX: merge lines that are not separated by
an empty line

=item begins_with(STRING, STRING)

return true if first argument begins with the second argument. Use this
instead of regexps if you don't want regexps.

begins_with("hello world", "hello")  # => 1

=item warp_text(STRING, INT)

return a list of lines which do not exceed INT characters
(or a string in scalar context)

=item warp_text(STRING)

warp_text at a default width (80)

=back

=head1 EXPORTS from MDK::Common::System.pm

=over

=item %compat_arch

architecture compatibility mapping (eg: k6 => i586, k7 => k6 ...)

=item %printable_chars

7 bit ascii characters

=item $sizeof_int

sizeof(int)

=item $bitof_int

$sizeof_int * 8

=item arch()

return the architecture (eg: i686, ppc, ia64, k7...)

=item typeFromMagic(FILENAME, LIST)

find the first corresponding magic in FILENAME. eg of LIST:

    [ 'empty', 0, "\0\0\0\0" ],
    [ 'grub', 0, "\xEBG", 0x17d, "stage1 \0" ],
    [ 'lilo', 0x2,  "LILO" ],
    sub { my ($F) = @_;
	  #- standard grub has no good magic (Mageia's grub is patched to have "GRUB" at offset 6)
	  #- so scanning a range of possible places where grub can have its string
	  my ($min, $max, $magic) = (0x176, 0x181, "GRUB \0");
	  my $tmp;
	  sysseek($F, 0, 0) && sysread($F, $tmp, $max + length($magic)) or return;
	  substr($tmp, 0, 2) eq "\xEBH" or return;
	  index($tmp, $magic, $min) >= 0 && "grub";
      },

where each entry is [ magic_name, offset, string, offset, string, ... ].

=item list_passwd()

return the list of users as given by C<getpwent> (see perlfunc)

=item list_home()

return the list of home (eg: /home/foo, /home/pixel, ...)

=item list_skels()

return the directories where we can find dot files: homes, /root and /etc/skel

=item list_users()

return the list of unprivilegied users (aka those whose uid is greater
than 500 and who are not "nobody").

=item syscall_(NAME, PARA)

calls the syscall NAME

=item psizeof(STRING)

useful to know the length of a C<pack> format string. 

    psizeof("I I I C C S") = 4 + 4 + 4 + 1 + 1 + 2 = 16

=item availableMemory()

size of swap + memory

=item availableRamMB()

size of RAM as reported by the BIOS (it is a round number that can be
displayed or given as "mem=128M" to the kernel)

=item gettimeofday()

returns the epoch in microseconds

=item unix2dos(STRING)

takes care of CR/LF translation

=item whereis_binary(STRING)

return the first absolute file in $PATH (similar to which(1) and whereis(1))

=item getVarsFromSh(FILENAME)

returns a hash associating shell variables to their value. useful for config
files such as /etc/sysconfig files

=item setVarsInSh(FILENAME, HASH REF)

write file in shell format association a shell variable + value for each
key/value

=item setVarsInSh(FILENAME, HASH REF, LIST)

restrict the fields that will be printed to LIST

=item setVarsInShMode(FILENAME, INT, HASH REF, LIST)

like setVarsInSh with INT being the chmod value for the config file

=item addVarsInSh(FILENAME, HASH REF)

like setVarsInSh but keeping the entries in the file

=item addVarsInSh(FILENAME, HASH REF, LIST)

like setVarsInSh but keeping the entries in the file

=item addVarsInShMode(FILENAME, INT, HASH REF, LIST)

like addVarsInShMode but keeping the entries in the file

=item setExportedVarsInCsh(FILENAME, HASH REF, LIST)

same as C<setExportedVarsInSh> for csh format

=item template2file(FILENAME_IN, FILENAME_OUT, HASH)

read in a template file, replace keys @@@key@@@ with value, save it in out
file

=item template2userfile(PREFIX, FILENAME_IN, FILENAME_OUT, BOOL, HASH)

read in a template file, replace keys @@@key@@@ with value, save it in every homes.
If BOOL is true, overwrite existing files. FILENAME_OUT must be a relative filename

=item read_gnomekderc(FILENAME, STRING)

reads GNOME-like and KDE-like config files (aka windows-like).
You must give a category. eg:

    read_gnomekderc("/etc/skels/.kderc", 'KDE')

=item update_gnomekderc(FILENAME, STRING, HASH)

modifies GNOME-like and KDE-like config files (aka windows-like).
If the category doesn't exist, it creates it. eg:

    update_gnomekderc("/etc/skels/.kderc", 'KDE', 
		      kfmIconStyle => "Large")

=item fuzzy_pidofs(REGEXP)

return the list of process ids matching the regexp

=back

=head1 OTHER in MDK::Common::System.pm

=over

=item better_arch(ARCH1, ARCH2)

is ARCH1 compatible with ARCH2?

better_arch('i386', 'ia64') and better_arch('ia64', 'i386') are false

better_arch('k7', 'k6') is true and better_arch('k6', 'k7') is false

=item compat_arch(STRING)

test the architecture compatibility. eg: 

compat_arch('i386') is false on a ia64

compat_arch('k6') is true on a k6 and k7 but false on a i386 and i686

=back

=head1 EXPORTS from MDK::Common::Various.pm

=over 

=item first(LIST)

returns the first value. C<first(XXX)> is an alternative for C<((XXX)[0])>

=item second(LIST)

returns the second value. C<second(XXX)> is an alternative for C<((XXX)[1])>

=item top(LIST)

returns the last value. C<top(@l)> is an alternative for C<$l[$#l]>

=item to_bool(SCALAR)

returns a value in { 0, 1 }

=item to_int(STRING)

extracts the number from the string. You could use directly C<int "11 foo">, but
you'll get I<Argument "11 foo" isn't numeric in int>. It also handles returns
11 for C<"foo 11 bar">

=item to_float(STRING)

extract a decimal number from the string

=item bool2text(SCALAR)

returns a value in { "true", "false" }

=item bool2yesno(SCALAR)

returns a value in { "yes", "no" }

=item text2bool(STRING)

inverse of C<bool2text> and C<bool2yesno>

=item chomp_(STRING)

non-mutable version of chomp: do not modify the argument, returns the chomp'ed
value. Also works on lists: C<chomp_($a, $b)> is equivalent to 
C<chomp($a) ; chomp($b) ; ($a,$b)>

=item backtrace()

returns a string describing the backtrace. eg: 

    sub g { print "oops\n", backtrace() }
    sub f { &g }
    f();

gives

    oops
    main::g() called from /tmp/t.pl:2
    main::f() called from /tmp/t.pl:4


=item internal_error(STRING)

another way to C<die> with a nice error message and a backtrace

=item noreturn()

use this to ensure nobody uses the return value of the function. eg:

    sub g { print "g called\n"; noreturn }
    sub f { print "g returns ", g() }
    f();

gives

    test.pl:3: main::f() expects a value from main::g(), but main::g() doesn't return any value

=back

=head1 COPYRIGHT

Copyright (c) 2001-2005 Mandriva <pixel@mandriva.com>. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


use MDK::Common::DataStructure qw(:all);
use MDK::Common::File qw(:all);
use MDK::Common::Func qw(:all);
use MDK::Common::Math qw(:all);
use MDK::Common::String qw(:all);
use MDK::Common::System qw(:all);
use MDK::Common::Various qw(:all);

use Exporter;
our @ISA = qw(Exporter);
# perl_checker: RE-EXPORT-ALL
our @EXPORT = map { @$_ } map { values %{'MDK::Common::' . $_ . 'EXPORT_TAGS'} } grep { /::$/ } keys %MDK::Common::;

our $VERSION = "1.2.30";

1;
