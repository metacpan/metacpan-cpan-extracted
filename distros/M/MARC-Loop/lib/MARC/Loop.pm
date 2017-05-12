package MARC::Loop;

use strict;
use warnings;

require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);

$VERSION = '0.01';

sub marcloop(&;$%);

use constant TAG    => 0;
use constant VALREF => 1;
use constant DELETE => 2;
use constant IND1   => 3;
use constant IND2   => 4;
use constant SUBS   => 5;

use constant SUB_ID     => 0;
use constant SUB_VALREF => 1;

use constant RECORD_TERMINATOR  => "\x1d";
use constant FIELD_TERMINATOR   => "\x1e";
use constant SUBFIELD_DELIMITER => "\x1f";

@ISA = qw(Exporter);
@EXPORT_OK = qw(marcloop marcparse marcfield marcindicators marcbuild TAG VALREF DELETE IND1 IND2 SUBS SUB_ID SUB_VALREF RECORD_TERMINATOR FIELD_TERMINATOR SUBFIELD_DELIMITER);

sub marcloop(&;$%) {
    my ($sub, $f, %arg) = @_;
    my $fh;
    $arg{'print'} = 1 if $arg{'print_all'};
    my (%drop, %only);
    if ($arg{'drop'}) {
        %drop = map { $_ => 1 } @{ $arg{'drop'} };
    }
    if ($arg{'only'}) {
        %only = map { $_ => 1 } @{ $arg{'only'} };
        die "drop and only are mutually exclusive" if %drop && %only;
    }
    if (defined $f) {
        if (ref $f) {
            $fh = $f;
        }
        elsif ($f eq '-') {
            $fh = \*STDIN;
        }
        else {
            open $fh, '<', $f or die "Can't open file '$f': $!";
        }
    }
    else {
        $f = '-';
        $fh = \*STDIN;
    }
    # --- Set up variables that identify the current record
    my $str;
    my $n = 0;
    my $byte_pos = 0;
    my $bibid;

    my $warning = sub {
        my ($msg) = @_;
        chomp $msg;
        printf STDERR "Warning: %s at record %d (offset %d, bib ID %s) of file %s\n",
            $msg, $n, $byte_pos, (defined $bibid ? $bibid : 'unknown'), $f;
    };
    my $error = $arg{'error'} || sub {
        my ($msg) = @_;
        chomp $msg;
        printf STDERR "Error: %s at record %d (offset %d, bib ID %s) of file %s\n",
            $msg, $n, $byte_pos, (defined $bibid ? $bibid : 'unknown'), $f;
        die "MARC::Loop - $msg";
    };

    RECORD:
    while (1) {
        # --- Read the next MARC record
        {
            local $/ = RECORD_TERMINATOR;
            $str = <$fh>;
        }
        last if !defined $str;
        $n++;
        # --- Parse and process it
        eval {
            if ($str !~ /
                \A
                        # bytes description
                        # ----- -------------------------------------------
                (\d{5}) # 00-04 rec length
                (....)  # 05-08 rec status, rec type, bib level, type of control
                (.)     # 09    character coding
                (..)    # 10-11 indicator count, subfield code count
                (\d{5}) # 12-16 base address = length of leader + directory
                (.{7})  # 17-23 other stuff
            /x) {
                $error->("Not a USMARC record: pathological leader");
            }
            my ($reclen, $baseaddr) = ($1, $5);
            if ($reclen != length $str) {
                $error->("Incorrect record length");
            }
            my $leader    = substr($str, 0, 24);
            my $directory = substr($str, 24, $baseaddr - 24);
            if (length($directory) % 12 != 1) {
                $error->("Directory length not a multiple of 12 bytes");
            }
            if (substr($directory, -1, 1) ne FIELD_TERMINATOR) {
                $error->("Directory not terminated");
            }
            my ($field, @fields);
            # --- Loop through the fields
            while ($directory =~ /(...)(....)(.....)/gc) {
                my ($tag, $len, $ofs) = ($1, $2, $3);
                next if $drop{$tag} || (%only && !$only{$tag});
                my $value = substr($str, $baseaddr + $ofs, $len);
                # --- Make sure the field ends in the field terminator
                if (substr($value, -1) ne FIELD_TERMINATOR) {
                    $error->("Field $tag not terminated");
                }
                else {
                    $value = substr($value, 0, -1);
                }
                if ($tag lt '010') {
                    # --- Control field
                    push @fields, [ $tag, \$value ];
                    if ($tag eq '001') {
                        $bibid = $value;
                    }
                }
                else {
                    # --- Data field
                    my ($i1, $i2) = ($value =~ /\G(.)(.)/gc);
                    my @subfields;
                    pos($value) = 2;  # Shouldn't have to do this to skip past indicators :-(
                    while ($value =~ /\G(?:\x1f([^\x1d-\x1f])([^\x1d-\x1f]*))/gc) {
                        my $subval = $2;
                        push @subfields, [ $1, \$subval ];
                    }
                    if (@subfields == 0) {
                        $error->("Empty field '$tag'");
                    }
                    push @fields, [ $tag, \$value, undef, $i1, $i2, @subfields ];
                }
            }
            if ($arg{'test_build_record'} && $str ne marcbuild($leader, \@fields)) {
                $error->("INTERNAL ERROR: marcbuild() failed");
            }
            eval {
                $sub->($leader, \@fields, \$str);
            };
            if ($@) {
                chomp $@;
                $error->($@);
                last if $arg{'strict'};
            }
            elsif ($arg{'print'}) {
                my $new_str = marcbuild($leader, \@fields);
                if ($arg{'print_all'} || $new_str ne $str) {
                    print $new_str;
                }
            }
        };
        if ($@) {
            # --- Handle exceptions
            last if $arg{'strict'};
        }
    }
    continue {
        $byte_pos += length($str);
    }

    # --- Report results
    if ($arg{'show_results'}) {
        printf STDERR "Results: %d of %d records printed\n"
    }
}


# --- Functions

sub marcindicators {
    if (@_ == 0) {
        return (' ', ' ');
    }
    elsif (@_ == 1 && length($_[0] eq 2)) {
        return split //, $_[0];
    }
    elsif (@_ != 2) {
        die "Wrong number of indicators";
    }
    my $i = 1;
    for (@_) {
        die "Bad indicator $i" unless defined;
        die "Indicator $i too long" if length > 1;
        $_ = ' ' if length == 0;
        $i++;
    }
    return @_;
}

sub marcfield {
    # marcfield('001', 1234567);
    # marcfield('245',
    #     marcindicators(' ', ' '),
    #     'a' => 'Blah blah',
    #     'c' => 'Foo B. Arrrr',
    #     ...
    # );
    my $tag = shift;
    my @field;
    $field[TAG]    = $tag;
    $field[DELETE] = undef;
    if ($tag lt '010') {
        my $val = shift;
        $field[VALREF] = \$val;
    }
    else {
        $field[VALREF] = undef;
        $field[IND1]   = shift;
        $field[IND2]   = shift;
        die "Odd number of subfield (id, val) tuples" if @_ % 2;
        while (@_) {
            my ($id, $val) = splice @_, 0, 2;
            push @field, [ $id, \$val ];
        }
    }
    return \@field;
}

sub marcbuild {
    my ($leader, $fields) = @_;
    my $directory = '';
    my $body = '';
    my $ofs = 0;
    foreach my $f (@$fields) {
        my ($tag, $valref, $delete, $i1, $i2, @subfields) = @$f;
        next if $delete;
        my $bodyprevlen = length($body);
        if ($tag lt '010') {
            $body .= $$valref;
        }
        else {
            $body .= $i1 . $i2;
            foreach my $s (@subfields) {
                my ($code, $content) = @$s;
                $body .= SUBFIELD_DELIMITER . $code . $$content if defined $$content;
            }
        }
        $body .= FIELD_TERMINATOR;
        my $fstrlen = length($body) - $bodyprevlen;
        $directory .= sprintf('%3.3s%04d%05d', $tag, $fstrlen, $ofs);
        $ofs += $fstrlen;
    }
    $directory .= FIELD_TERMINATOR;
    my $dirlen = length $directory;
    $body .= RECORD_TERMINATOR;
    substr($leader,  0, 5) = sprintf('%05d', 24 + $dirlen + length $body);
    substr($leader, 12, 5) = sprintf('%05d', 24 + $dirlen);
    return $leader . $directory . $body;
}

sub marcparse {
    my ($strref, %args) = @_;
    my $warning = $args{'warning'} || sub {
        my ($msg) = @_;
        print STDERR "WARNING: $msg\n";
    };
    my $error = $args{'error'} || sub {
        my ($msg) = @_;
        die "marcloop: error: $msg\n";
    };
    my %drop = %{ $args{'drop'} || {} };
    my %only = %{ $args{'only'} || {} };
    my $bibid;
    if ($$strref !~ /
        \A
                # bytes description
                # ----- -------------------------------------------
        (\d{5}) # 00-04 rec length
        (....)  # 05-08 rec status, rec type, bib level, type of control
        (.)     # 09    character coding
        (..)    # 10-11 indicator count, subfield code count
        (\d{5}) # 12-16 base address = length of leader + directory
        (.{7})  # 17-23 other stuff
    /x) {
        $error->("Not a USMARC record: pathological leader");
    }
    my ($reclen, $baseaddr) = ($1, $5);
    if ($reclen != length $$strref) {
        $error->("Incorrect record length");
    }
    my $leader    = substr($$strref, 0, 24);
    my $directory = substr($$strref, 24, $baseaddr - 24);
    if (length($directory) % 12 != 1) {
        $error->("Directory length not a multiple of 12 bytes");
    }
    if (substr($directory, -1, 1) ne FIELD_TERMINATOR) {
        $error->("Directory not terminated");
    }
    my ($field, @fields);
    # --- Loop through the fields
    while ($directory =~ /(...)(....)(.....)/gc) {
        my ($tag, $len, $ofs) = ($1, $2, $3);
        next if $drop{$tag} || (%only && !$only{$tag});
        my $value = substr($$strref, $baseaddr + $ofs, $len);
        # --- Make sure the field ends in the field terminator
        if (substr($value, -1) ne FIELD_TERMINATOR) {
            $error->("Field $tag not terminated");
        }
        # --- Strip the field terminator
        $value = substr($value, 0, -1);
        if ($tag lt '010') {
            # --- Control field
            push @fields, [ $tag, \$value ];
            if ($tag eq '001') {
                $bibid = $value;
            }
        }
        else {
            # --- Data field
            my ($i1, $i2) = ($value =~ /\G(.)(.)/gc);
            my @subfields;
            pos($value) = 2;  # Shouldn't have to do this to skip past indicators :-(
            while ($value =~ /\G(?:\x1f([^\x1d-\x1f])([^\x1d-\x1f]*))/gc) {
                my $subval = $2;
                push @subfields, [ $1, \$subval ];
            }
            if (@subfields == 0) {
                $error->("Empty field '$tag'");
            }
            push @fields, [ $tag, \$value, undef, $i1, $i2, @subfields ];
        }
    }
    return ($leader, \@fields);
}

=head1 NAME

MARC::Loop - process a batch of MARC21 records

=head1 SYNOPSIS

    use MARC::Loop qw(marcloop marcbuild TAG VALREF DEL);
    my $filehandle = \*STDIN;
    my $deleted999 = 0;
    my $fixed035 = 0;
    marcloop {
        my ($leader, $fields, $raw_marc_ref) = @_;
        my $changed;
        foreach my $field (@$fields) {
            if ($field->[TAG] eq '035') {
                # Normalize OCLC numbers
                my $valref = $field->[VALREF];
                $$valref =~ s/\(OCoLC\)oc[mn]0*/(OCoLC)/g;
                $fixed035++;
                $changed = 1;
            }
            elsif ($field->[TAG] eq '999') {
                # Delete 999 fields
                $field->[DEL] = 1;
                $deleted999++;
                $changed = 1;
            }
        }
        # Print only changed records
        print marcbuild($leader, $fields) if $changed;
    } $filehandle;
    print STDERR "$deleted999 999 fields were deleted\n",
                 "$fixed035 035 fields were fixed\n";

=head1 DESCRIPTION

MARC::Loop is an alternative to L<MARC::File|MARC::File> and
L<MARC::Record|MARC::Record> that eschews an object-oriented approach in favor
of a bare-bones procedural one.

=head1 FUNCTIONS

All of these functions are exported upon request.

=head2 marcloop

    # This example prints a MARC record in human-readable form, using a single
    # line for each field no matter how many subfields it might have.
    use MARC::Loop qw(marcloop);
    marcloop {
        my ($leader, $fields, $raw_marc_ref) = @_;
        foreach my $field (@$fields) {
            if ($field->[TAG] lt '010) {
                # Control field
                my $valref = $field->[VALREF];
                print $field->[TAG], '    ', $$valref, "\n";
            }
            else {
                # Data field 
                my ($i1, $i2) = ($field->[IND1], $field->[IND2]);
                print "$field->[TAG] $i1$i2";
                my @subfields  = @{ $field->[SUBS..$#$field] };
                foreach my $subfield (@subfields) {
                    my ($code, $valref) = @$subfield;
                    print '$', $code, ' ', $$valref;
                }
                print "\n";
            }
        }
    } $filehandle, %options;

Options:

=over 4

=item B<print_all>

All MARC records will be printed to STDOUT.  Any changes you make will be
reflected in what is printed.

=item B<drop> I<array_ref>

    'drop' => [ '001', '090' ]

Tags of fields to be dropped unconditionally.

=item B<only> I<array_ref>

    'only' => [ qw(001 004 008 852 856) ]

Tags of fields to be preserved; all other fields will be dropped.  (The leader
is never dropped, of course.)

=item B<error>

A code reference to call when there is an error.

    'error' => sub { exit -1 }

=item B<strict>

    'strict' => 1

Halt processing when an ill-formed MARC record is encountered.

=back

Options will be more fully documented in a future release; in the meantime,
read the source code.

=head2 marcparse

    ($leader, $fields) = marcparse(\$string, %options);

Parses a MARC record into the same data structure that B<marcloop> uses.
Options are mostly the same as for B<marcloop>.

=head2 marcbuild

    print marcbuild($leader, $fields);

Builds a raw MARC record from the same data structure that B<marcloop> uses and
that B<marcparse> produces.

=head2 marcfield

    # Control field
    push $@fields, marcfield(                  
        '001',   # Tag
        1234567, # Content
    );  

    # Data field
    push $@fields, marcfield(                  
        '245',              # Tag
        ' ', ' ',           # Indicators
        'a' => 'Blah blah', # Subfield $a
        'c' => 'Amy Emu',   # Subfield $c
        ...                 # More subfields
    );

A convenience function to build a data structure representing a single MARC21
field.

=head1 BUGS

The documentation is woefully lacking and probably just plain wrong.  Read the
source code -- or, better yet, step through it in the Perl debugger -- to get a
better understanding of what this code does.

Unhandled errors cause ill-formed records to be dropped without notice.  You
must specify an B<error> option to B<marcloop> to get around this.

=head1 AUTHOR

Paul Hoffman E<lt>paul@flo.orgE<gt>.

=head1 COPYRIGHT

Copyright 2009-2010 Fenway Libraries Online.  Released under the GNU Public
License, version 3.
