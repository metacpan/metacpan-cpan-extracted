package Language::Zcode::Parser::Generic;

use strict;
use warnings;
use IO::File;

use Language::Zcode::Util;

=head1 Language::Zcode::Parser::Generic

Base class for Z-code parsers.

A Parser reads and parses a Z-code file into a big Perl hash.

For finding where the subroutines start and end, you can either depend on
an external call to txd, a 1992 C program, or a beta pure Perl version.

Everything else is done in pure Perl.

=cut

=head2 new (class, args...)

Base class does nothing with args

=cut

sub new {
    my ($class, @arg) = @_;
    bless {}, $class;
}

=head2 find_zfile (filename)

If the input filename is not found AND the user did not enter, e.g., '.z5' at
the end of the filename, the system will try to find a file ending with .z[1-9]
or .dat.

Multiple or no matches -> return false

=cut

sub find_zfile {
    my ($self, $infile) = @_;
    return $infile if -e $infile;

    my $fn = ""; # filename to return
    if ($infile !~ /\.(z[1-9]|dat)$/i) {
	my @files = glob("$infile.z[1-9]");
	push @files, "$infile.dat" if -e "$infile.dat";
	if (@files == 0) {
	    warn "No file $infile.z[1-9] or $infile.dat\n";
	} elsif (@files > 1) {
	    warn "Too many files match $infile.z[1-9] or $infile.dat: @files\n";
	} else {
	    $fn = $files[0];
	}
    } else {
	warn "File '$infile' not found\n";
    }

    return $fn;
}

=head2 read_memory (infile)

Reads the given Z-code file into memory

=cut

sub read_memory {
    my ($self, $infile) = @_;
    # Read in actual Z file
    my $ZFILE = new IO::File "<$infile" or die "Zfile: $!";
    binmode $ZFILE;
    my $size = -s $infile;
    my $q = "";
    # Read it all into one big string, split it into an array
    my $err = read($ZFILE, $q, $size);
    die "Problem reading Z file from Perl: $!" unless defined $err;
    @Language::Zcode::Util::Memory = unpack('C*', $q);
    close($ZFILE);
}

=head2 parse_header

Parse Z-code header. 

Creates %Constants, which stores a bunch of constants
like the Z version number, where in memory things are stored, etc.

=cut

sub parse_header {
    my $self = shift;

    # see spec section 11:
    use constant HEADER_SIZE => 64;

    # These are all addresses in the header of various Z constants
    use constant VERSION_NUMBER => 0x00;
    use constant RELEASE_NUMBER => 0x02;
    use constant PAGED_MEMORY_ADDRESS => 0x04;
    use constant FIRST_INSTRUCTION_ADDRESS => 0x06;
    use constant DICTIONARY_ADDRESS => 0x08;
    use constant OBJECT_TABLE_ADDRESS => 0x0a;
    use constant GLOBAL_VARIABLE_ADDRESS => 0x0c;
    use constant STATIC_MEMORY_ADDRESS => 0x0e;
    use constant SERIAL_CODE => 0x12;
    use constant ABBREV_TABLE_ADDRESS => 0x18;
    use constant FILE_LENGTH => 0x1a;
    use constant CHECKSUM => 0x1c;
    use constant INTERPRETER_NUMBER => 0x1e;
    use constant INTERPRETER_VERSION => 0x1f;
    use constant ROUTINES_OFFSET => 0x28;
    use constant STRINGS_OFFSET => 0x2a;

    # interpreter version name; "P" for Plotz
    use constant INTERPRETER_CODE => ord "P";

    my %info;
    my $version = $Language::Zcode::Util::Memory[VERSION_NUMBER];
    if ($version < 1 or $version > 8) {
        die "This does not appear to be a valid game file.\n";
    } elsif (($version < 3 or $version > 5) and $version != 8) {
        die "Sorry, only z-code versions 3,4,5 and 8 are supported at present...\nAnd even those need work!  :)\n"
    }

    $info{version} = $version;
    $info{release_number} = Language::Zcode::Util::get_word_at(RELEASE_NUMBER);
    $info{paged_memory_address} = Language::Zcode::Util::get_word_at(PAGED_MEMORY_ADDRESS);
    $info{first_instruction_address} = Language::Zcode::Util::get_word_at(FIRST_INSTRUCTION_ADDRESS);
    $info{dictionary_address} = Language::Zcode::Util::get_word_at(DICTIONARY_ADDRESS);
    $info{object_table_address} = Language::Zcode::Util::get_word_at(OBJECT_TABLE_ADDRESS);
    $info{global_variable_address} = Language::Zcode::Util::get_word_at(GLOBAL_VARIABLE_ADDRESS);
    $info{static_memory_address} = Language::Zcode::Util::get_word_at(STATIC_MEMORY_ADDRESS);
    # see zmach06e.txt
    $info{abbrev_table_address} = Language::Zcode::Util::get_word_at(ABBREV_TABLE_ADDRESS);
    my $c = "";
    for (SERIAL_CODE .. SERIAL_CODE + 5) {
	$c .= chr Language::Zcode::Util::get_byte_at($_);
    }
    $info{serial_code} = qq{"$c"};

    #  set object/dictionary "constants" for this version...
    if ($version <= 3) {
	# 13.3, 13.4
	$info{encoded_word_length} = 6;

	# 12.3.1
	$info{object_bytes} = 9;
	$info{attribute_bytes} = 4;
	$info{pointer_size} = 1;
	$info{max_properties} = 31;	# 12.2
	$info{max_objects} = 255;		# 12.3.1
    } else {
	$info{encoded_word_length} = 9;

	# 12.3.2
	$info{object_bytes} = 14;
	$info{attribute_bytes} = 6;
	$info{pointer_size} = 2;
	$info{max_properties} = 63;	# 12.2
	$info{max_objects} = 65535;	# 12.3.2
    }
    die("check your math!")
	if (($info{attribute_bytes} + ($info{pointer_size} * 3) + 2)
	    != $info{object_bytes});
  
    my $flen = Language::Zcode::Util::get_word_at(FILE_LENGTH);
    if ($version <= 3) {
    # see 11.1.6
	$flen *= 2;
    } elsif ($version == 4 || $version == 5) {
	$flen *= 4;
    } else {
	$flen *= 8;
    }
    $info{file_length} = $flen;
  
    $info{file_checksum} = Language::Zcode::Util::get_word_at(CHECKSUM);

    # Packed string/routine calculation
    my %packed_mult = (1=>2, 2=>2, 3=>2, 4=>4, 5=>4, 6=>4, 7=>4, 8=>8);
    $info{packed_multiplier} = $packed_mult{$version};
    if ($version >= 6) {
        $info{routines_offset} = &Language::Zcode::Util::get_word_at(ROUTINES_OFFSET);
        $info{strings_offset} = &Language::Zcode::Util::get_word_at(STRINGS_OFFSET);
    } else {
        $info{routines_offset} = 0;
        $info{strings_offset} = 0;
    }

    %Language::Zcode::Util::Constants = %info;

    # Now set any data that we know will be true in the output program
    # interpreter number
#    &set_byte_at(INTERPRETER_NUMBER, $interpreter_id);
    &Language::Zcode::Util::set_byte_at(INTERPRETER_VERSION, INTERPRETER_CODE);

    return;
}

1;
