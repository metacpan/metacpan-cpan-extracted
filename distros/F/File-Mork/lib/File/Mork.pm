package File::Mork;

use strict;
use vars qw($VERSION $ERROR);
use POSIX qw(strftime);
use Encode;

$VERSION = "0.4";

=head1 NAME

File::Mork - a module to read Mozilla URL history files

=head1 SYNOPSIS

    my $mork = File::Mork->new($filename, verbose => 1)
        || die $File::Mork::ERROR."\n";


    foreach my $entry ($mork->entries) {
        while (my($key,$val) = each %$entry) {
            printf ("%14s = %s\n", $key, $val);
        }
    }

=head1 DESCRIPTION

This is a module that can read the Mozilla URL history file -- normally
$HOME/.mozilla/default/*.slt/history.dat -- and extract the id, url,
name, hostname, first visted dat, last visited date and visit count.

To find your history file it might be worth using B<Mozilla::Backup>
which has some platform-independent code for finding the profiles of
various Mozilla-isms (including Firefox, Camino, K-Meleon, etc.).

=cut

=head1 METHODS

=head2 new <file> [opts]

Takes a filename and parses that file.

Returns C<undef> on error, setting C<$File::Mork::Error>.

Takes an optional hash of options

=over 4

=item

verbose

A value up to 3 - defines the level of verbosity

=item

age

A ctime which forces C<File::Mork> to only parse entries later than this.

=back

=cut

sub new {
    my ($class, $file, %opts) = @_;
    my $self = bless \%opts, $class;

	$self->{verbose} ||= 0;

    unless ($self->parse($file)) {
        $ERROR = $self->{error};
        return;
    }

    return $self;
}


##########################################################################
# Define the messy regexen up here
##########################################################################

my $top_level_comment = qr@//.*\n@;

my $key_table_re = qr/  < \s* <               # "< <"
                         \( a=c \) >          # "(a=c)>"
                         (?> ([^>]*) ) > \s*  # Grab anything that's not ">"
                     /sx;

my $value_table_re = qr/ < ( .*?\) )> \s* /sx;

my $table_re = qr/ \{ -?          # "{" or "{-"
                    [\da-f]+ :    # hex, ":"
                    (?> .*?\{ )   # Eat up to a {...
                   ((?> .*?\} )   # and then the closing }...
                    (?> .*?\} ))  # Finally, grab the table section
                 \s* /six;

my $row_re = qr/ ( (?> \[ [^]]* \]       # "["..."]"
                         \s*)+ )         # Perhaps repeated many times
                 /sx;

my $section_begin_re = qr/ \@\$\$\{      # "@$${"
                             ([\dA-F]+)  # hex
                             \{\@ \s*    # "{@"
                           /six;


my $crlf = qr/\x0a\x0d|\x0d\x0a|\x0a|\x0d/; # We are liberal in what we accept.
                                            # But then, so is a six dollar whore.

=head2 parse <file>

Internal method to parse the file. Obviously.

=cut

sub parse {
    my ($self, $file) = @_;

    $self->{since}   = ($self->{age} ? time() - $self->{age} : 0);
    $self->{section} = "top level";
    $self->{section_end_re} = undef;



    ##########################################################################
    # Read in the file.
    ##########################################################################

    local $/ = undef;
    local *IN;

    $self->{file}    = $file;
    $self->{total}   = 0;
    $self->{skipped} = 0;

    unless (open (IN, $file)) {
        $self->{error} = "Couldn't open $file : $!";
        return;
    }

    $self->debug("reading ...",1);
    my $body = <IN>;
    close IN;


    $body =~ s/($crlf)/\n/gs; # Windows Mozilla uses \r\n
                              # Presumably Mac Mozilla is similarly dumb

    $body =~ s/\\\\/\$5C/gs;  # Sometimes backslash is quoted with a
                              #  backslash; convert to hex.
    $body =~ s/\\\)/\$29/gs;  # close-paren is quoted with a backslash;
                              #  convert to hex.
    $body =~ s/\\\n//gs;      # backslash at end of line is continuation.

    ##########################################################################
    # Figure out what we're looking at, and parse it.
    ##########################################################################

    $self->debug("parsing ...",1);
    pos($body) = 0;
    my $length = length($body);

    while( pos($body) < $length ) {
        my $section_end_re = $self->{section_end_re};
        # Key table

        if ( $body =~ m/\G$key_table_re/gc ) {
                  return unless $self->parse_key_table($1);

        # Values
        } elsif ( $body =~ m/\G$value_table_re/gco ) {
                  return unless $self->parse_value_table($1);

        # Table
        } elsif ( $body =~ m/\G$table_re/gco ) {
                  return unless $self->parse_table($1);

        # Rows (-> table)
        } elsif ( $body =~ m/\G$row_re/gco ) {
                  return unless $self->parse_table($1);

        # Section begin
        } elsif ( $body =~ m/\G$section_begin_re/gco ) {
                  my $section = $1;
                  $self->{section_end_re} = qr/\@\$\$\}$section\}\@\s*/s;
                  $self->{section} = $section;
        # Section end
        } elsif ( $section_end_re && $body =~ m/\G$section_end_re/gc ) {
                  $self->{section_end_re}  = undef;
                  $self->{section}         = "top level";

        # Comment
        } elsif ( $body =~ m/\G$top_level_comment/gco ) {
                  #no-op

        } else {
                # $body =~ m/\G (.{0,300}) /gcsx; print "<$1>\n";
                  return $self->error($self->{section}.": Cannot parse");
        }
    }

    if($self->{section_end_re}) {
        return $self->error("Unterminated section ".$self->{section});
    }


    $self->debug("sorting...",1);

    my @entries = map  { File::Mork::Entry->new(%$_) }
                  sort { $b->{LastVisitDate} <=>
                         $a->{LastVisitDate} } values(%{$self->{row_hash}});

    $self->debug("done!  (".$self->{total}." total, ".$self->{skipped}." skipped)",1);

    for (qw(key_table val_table row_hash total skipped)) {
        $self->{$_} = undef;
    }

    $self->{entries} = \@entries;
    return 1;
}

=head2 entries

Return a list of C<File::Mork::Entry> objects sorted by B<LastVisitDate>.

=cut

sub entries {
    return @{$_[0]->{entries}};
}


##########################################################################
# parse a row and column table
##########################################################################

sub parse_table {
    my($self, $table_part) = (@_);

    $self->debug("",3);

    # Assumption: no relevant spaces in values in this section
    $table_part =~ s/\s+//g;

    #  print $table_part; #exit(0);

    # Grab each complete [...] block
    while( $table_part =~ m/\G  [^[]*   \[  # find a "["
                            ( [^]]+ ) \]  # capture up to "]"
                          /gcx ) {
        $_ = $1;

        my ($id, @cells) = split (m/[()]+/s);

        next unless scalar(@cells);

        # Trim junk
        $id =~ s/^-//;
        $id =~ s/:.*//;

        my %hash = ($self->{row_hash}->{$id}) ?  %{$self->{row_hash}->{$id}} :
                                                  ( 'ID'            => $id,
                                                      'LastVisitDate' => 0   );

        foreach (@cells) {
              next unless $_;

              my ($keyi, $which, $vali) =
                m/^\^ ([-\dA-F]+)
                  ([\^=])
                  (.*)
                  $/xi;

              return $self->error("unparsable cell: $_\n") unless defined ($vali);

            # If the key isn't in the key table, ignore it
              #
              my $key = $self->{key_table}->{$keyi};
              next unless defined($key);

              my $val  = ($which eq '='
                          ? $vali
                          : $self->{val_table}->{$vali});

            if ($key eq 'LastVisitDate' || $key eq 'FirstVisitDate') {
                $val = int ($val / 1000000);  # we don't need milliseconds, dude.
              }

              $hash{$key} = $val;
            #print "$id: $key -> $val\n";
        }


        if ($self->{age} && ($hash{LastVisitDate} || $self->{since}) < $self->{since}) {
              $self->debug("skipping old: $hash{LastVisitDate} $hash{URL}",3);
              $self->{skipped}++;
              next;
        }

        $self->{total}++;
        $self->{row_hash}->{$id} = \%hash;
    }
    return 1;
}


##########################################################################
# parse a values table
##########################################################################

sub parse_value_table {
    my($self, $val_part) = (@_);

    return 1 unless $val_part;

    my @pairs = split (m/\(([^\)]+)\)/, $val_part);
    $val_part = undef;

    $self->debug("",3);

    foreach (@pairs) {
        next unless (m/[^\s]/s);
        my ($key, $val) = m/([\dA-F]*)[\t\n ]*=[\t\n ]*(.*)/i;

        if (! defined ($val)) {
              $self->debug($self->{section}.": unparsable val: $_");
              next;
        }

        # recognize the byte order of UTF-16 encoding
        if (! defined ($self->{byte_order}) && $val =~ m/(?:BE|LE)$/) {
            $self->{byte_order} = $val;
        }

        # Assume that URLs and LastVisited are never hexilated; so
        # don't bother unhexilating if we won't be using Name, etc.
        if($val =~ m/\$/) {
            if ( defined $self->{byte_order} ) {
                my $encoding = 'UTF-16' . $self->{byte_order};
                $val =~ s/\$([\dA-F]{2})/chr(hex($1))/ge;
                $val = encode_utf8(decode($encoding, $val));
            }
            else {
                # Approximate wchar_t -> ASCII and remove NULs
                $val =~ s/\$00//g;  # faster if we remove these first
                $val =~ s/\$([\dA-F]{2})/chr(hex($1))/ge;
            }
        }

        $self->{val_table}->{$key} = $val;
        $self->debug($self->{section}.": val $key = \"$val\"", 3);
     }
    return 1;
}


##########################################################################
# parse a key table
##########################################################################

sub parse_key_table {
    my ($self, $key_table) = (@_);

    $self->debug("",3);

    $key_table =~ s@\s+//.*$@@gm;

    my @pairs = split (m/\(([^\)]+)\)/s, $key_table);
    $key_table = undef;

    foreach (@pairs) {
        next unless (m/[^\s]/s);
        my ($key, $val) = m/([\dA-F]+)\s*=\s*(.*)/i;
        return $self->error ("unparsable key: $_") unless defined ($val);

        # savie the other fields that we aren't interested in.
        $self->{key_table}->{$key} = $val;
        $self->debug($self->{section}.": key $key = \"$val\"",3);
     }
    return 1;
}


=head2 error <message>

Internal method to set the internal error message

=cut

sub error {
    my ($self, $message) = @_;
    $self->{error} = $self->{file}.": $message";
    return undef;
}

=head2 debug <message> <priority>

Internal method to print out a debug message if it's a higher priority
than the the current verbosity level.

=cut

sub debug {
    my ($self, $message, $level) = @_;
	$level ||= 0;
    return if $self->{verbose} < $level;
    print STDERR "".(($message eq "")? "\n" : $self->{file}.": $message\n" );
}


=head1 THE UGLY TRUTH LAID BARE

I<Extracted from mork.pl>

In Netscape Navigator 1.0 through 4.0, the history.db file was just a
Berkeley DBM file.  You could trivially bind to it from Perl, and pull
out the URLs and last-access time.  In Mozilla, this has been replaced
with a "Mork" database for which no tools exist.

Let me make it clear that McCusker is a complete barking lunatic.
This is just about the stupidest file format I've ever seen.

       http://www.mozilla.org/mailnews/arch/mork/primer.txt
       http://jwz.livejournal.com/312657.html
       http://www.jwz.org/doc/mailsum.html
       http://bugzilla.mozilla.org/show_bug.cgi?id=241438

In brief, let's count its sins:

=over 4

=item

Two different numerical namespaces that overlap.

=item

It can't decide what kind of character-quoting syntax to use:
Backslash?  Hex encoding with dollar-sign?

=item

C++ line comments are allowed sometimes, but sometimes // is just a
pair of characters in a URL.

=item

It goes to all this serious compression effort (two different
string-interning hash tables) and then writes out Unicode strings
without using UTF-8: writes out the unpacked wchar_t characters!

=item

Worse, it hex-encodes each wchar_t with a 3-byte encoding, meaning the
file size will be 3x or 6x (depending on whether whchar_t is 2 bytes or
4 bytes.)

=item

It masquerades as a "textual" file format when in fact it's just
another binary-blob file, except that it represents all its magic
numbers in ASCII.  It's not human-readable, it's not hand-editable, so
the only benefit there is to the fact that it uses short lines and
doesn't use binary characters is that it makes the file bigger. Oh wait,
my mistake, that isn't actually a benefit at all.

=back

Pure comedy.


=head1 AUTHOR

Module-ised by Simon Wistow <simon@thegestalt.org>

based on

    http://www.jwz.org/hacks/mork.pl

Created:  3-Mar-2004 by Jamie Zawinski, Anonymous, and Jacob Post.


=head1 COPYRIGHT

Copyright © 2004 Jamie Zawinski <jwz@jwz.org>

=head1 LICENSE

Permission to use, copy, modify, distribute, and sell this software and its
documentation for any purpose is hereby granted without fee, provided that
the above copyright notice appear in all copies and that both that
copyright notice and this permission notice appear in supporting
documentation.  No representations are made about the suitability of this
software for any purpose.  It is provided "as is" without express or
implied warranty.

=head1 BUGS

Might be a bit memory heavy? Could do with an iterator interface.

Can't write Mork dbs.

=head1 SEE ALSO

http://www.livejournal.com/users/jwz/312657.html

http://www.erys.org/resume/netscape/mork/jwz.html

=cut


package File::Mork::Entry;
use strict;
use vars qw($AUTOLOAD);

=head1 NAME

File::Mork::Entry - an single entry in a mork DB

=head1 METHODS

All methods except C<new> take an optional argument to set them.

=head2 new <%opts>

blesses C<%opts> into the class File::Mork::Entry

=cut

sub new {
    my ($class, %self) = @_;
    return bless \%self, $class;
}


=head2 ID

The internal id of the entry

=head2 URL

The url visited

=head2 NAME

The name of the url visited

=head2 Hostname

The hostname of the url visited

=head2 FirstVisitDate

The first time this url was visited as a C<ctime>

=head2 LastVisitDate

The last time this url was visited as a C<ctime>

=head2 Hidden

Whether this URL is hidden from the history list or not

=head2 VisitCount

The number of times this url has been visited

=head2 ByteOrder

The byte order - this is associated with ID number 1.

=cut

sub DESTROY { }

sub AUTOLOAD  {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*:://;

    $self->{$attr} = $_[0] if @_;
    return $self->{$attr};
}

1;
