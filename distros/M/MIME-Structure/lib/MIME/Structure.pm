package MIME::Structure;

use strict;

use vars qw($VERSION);

$VERSION = '0.07';

use Text::Balanced qw(extract_delimited);

use constant IN_HEADER   => 1;
use constant IN_BODY     => 2;
use constant IN_PREAMBLE => 3;
use constant IN_EPILOGUE => 4;

use constant PRINT_NONE      => 0;
use constant PRINT_HEADER    => 1;
use constant PRINT_PREAMBLE  => 2;
use constant PRINT_BODY      => 4;
use constant PRINT_EPILOGUE  => 8;

# --- Constructor, accessors, initializer

sub new {
    my $cls = shift;
    my $self = bless {
        'keep_header'    => 0,
        'keep_fields'    => 1,
        'print_header'   => 0,
        'print_preamble' => 0,
        'print_body'     => 0,
        'print_epilogue' => 0,
        @_,
    }, $cls;
    $self->init;
}

sub keep_header { @_ > 1 ? $_[0]->{'keep_header'} = $_[1] : $_[0]->{'keep_header'} }
sub keep_fields { @_ > 1 ? $_[0]->{'keep_fields'} = $_[1] : $_[0]->{'keep_fields'} }
sub print { @_ > 1 ? $_[0]->{'print'} = $_[1] : $_[0]->{'print'} }
sub print_header { @_ > 1 ? $_[0]->{'print_header'} = $_[1] : $_[0]->{'print_header'} }
sub print_body { @_ > 1 ? $_[0]->{'print_body'} = $_[1] : $_[0]->{'print_body'} }
sub print_preamble { @_ > 1 ? $_[0]->{'print_preamble'} = $_[1] : $_[0]->{'print_preamble'} }
sub print_epilogue { @_ > 1 ? $_[0]->{'print_epilogue'} = $_[1] : $_[0]->{'print_epilogue'} }

sub init {
    my ($self) = @_;
    my $print_spec = $self->{'print'};
    my $print;
    if (!defined $print_spec) {
        $print = PRINT_NONE;
    }
    elsif ($print_spec =~ /^\d+$/) {
        $print = $print_spec;
    }
    else {
        if ($print_spec =~ /header/i) {
            $print |= PRINT_HEADER;
        }
        if ($print_spec =~ /body/i) {
            $print |= PRINT_BODY;
        }
        if ($print_spec =~ /preamble/i) {
            $print |= PRINT_PREAMBLE;
        }
        if ($print_spec =~ /epilogue/i) {
            $print |= PRINT_EPILOGUE;
        }
    }
    if ($self->{'print_header'}) {
        $print |= PRINT_HEADER;
    }
    if ($self->{'print_body'}) {
        $print |= PRINT_BODY;
    }
    if ($self->{'print_preamble'}) {
        $print |= PRINT_PREAMBLE;
    }
    if ($self->{'print_epilogue'}) {
        $print |= PRINT_EPILOGUE;
    }
    $self->{'print'} = $print;
    $self;
}

# --- Parsing

sub parse {
    my ($self, $fh) = @_;
    my ($ofs, $line) = (0, 1);
    my $message = {
        'kind'   => 'message',
        'offset' => $ofs,
        'line'   => $line,
        'number' => '1',
    };
    my @context = ($message);
    my @entities;
    my @boundaries;

    # --- Parsing options
    my $keep_header    = $self->keep_header;
    my $keep_fields    = $self->keep_fields;
    my $print          = $self->print;
    
    my $state = IN_HEADER;
    my $header = '';
    while (<$fh>) {
        my $len = length $_;
        $ofs += $len;
        $line++;
        if ($state == IN_HEADER) {
            $header .= $_;
            if (/^$/) {
                # --- Parse the header that has just ended
                print $header if $print & PRINT_HEADER;
                my $fields = $self->parse_header($header);
                # @context is (..., $parent, $entity)
                # or ($parent, $entity) if in header of a part of message
                # or ($entity) if in message header itself
                my $entity = $context[-1];
                my $parent;
                my $level = $entity->{'level'} = @context - 1;
                if (@context > 1) {
                    # Current entity is $context[-1]
                    $parent = $entity->{'parent'} = $context[-2];
                }
                my ($content_type) = @{ $fields->{'content-type'} || [] };
                if (!defined $content_type) {
                    if ($parent && "$parent->{'type'}/$parent->{'subtype'}" eq 'multipart/digest') {
                        $content_type = 'message/rfc822'
                    }
                    else {
                        $content_type = 'text/plain; charset=us-ascii';
                    }
                }
                my ($type, $subtype, $type_params) = parse_content_type($content_type);
                $entity->{'type'}        = $type;
                $entity->{'subtype'}     = $subtype;
                $entity->{'type_params'} = $type_params;
                $entity->{'header'}      = $header if $keep_header;
                $entity->{'fields'}      = $fields if $keep_fields;
                $entity->{'body_offset'} = $ofs;
                $header = '';
                ($entity->{'encoding'})  = map lc, @{ $fields->{'content-transfer-encoding'} ||= ['7bit'] };
                if ($type eq 'multipart') {
                    # --- Header is for a multipart entity
                    $state = IN_PREAMBLE;
                    my $boundary = $type_params->{'boundary'};
                    die "No boundary specified for multipart entity with header at $ofs"
                        unless defined $boundary;
                    push @boundaries, $boundary;
                    $entity->{'parts'} = [];
                    $entity->{'parts_boundary'} = $boundary;
                }
                else {
                    # --- Header is for a leaf entity
                    $state = IN_BODY;
                    pop @context;  # The entity whose header we just finished reading
                    if ($level == 0 && !($print & PRINT_BODY)) {
                        # Minor optimization: message is not multipart, so we
                        # can stop if we're not going to be printing the body
                        push @entities, $entity;
                        while (<$fh>) { $ofs += length };
                        last;
                    }
                }
                push @entities, $entity;
            }
        }
        elsif (@boundaries && /^--(.+?)(--)?$/ && $1 eq $boundaries[-1]) {
            print if $print != PRINT_NONE;
            if (defined $2) {
                # End of parent's parts
                pop @boundaries;
                pop @context;
                $state = IN_EPILOGUE;
            }
            else {
                # Another part begins
                $state = IN_HEADER;
                my $part = {
                    'kind'   => 'part',
                    'offset' => $ofs,
                    'line'   => $line,
                };
                my $parent = $context[-1];
                my $parent_parts = $parent->{'parts'};
                push @$parent_parts, $part;
                $part->{'parent'} = $parent;
                $part->{'number'} = $parent->{'number'} . '.' . scalar @$parent_parts;
                push @context, $part;
            }
        }
        elsif ($state == IN_PREAMBLE) {
            # A line within the preamble: ignore per RFC 2049
            print if $print & PRINT_PREAMBLE;
        }
        elsif ($state == IN_EPILOGUE) {
            # A line within the epilogue: ignore per RFC 2049
            print if $print & PRINT_EPILOGUE;
        }
        else {
            # Normal body line
            print if $print & PRINT_BODY;
        }
    }
    # We're all done reading
    if (@context) {
        die "Unfinished parts!";
    }
    $message->{'content_length'} = $ofs - $message->{'body_offset'};
    $message->{'length'} = $ofs;
    
    return wantarray ? @entities : $message;
}

# --- Reporting

sub concise_structure {
    my ($self, $message) = @_;
    # (text/plain:0)
    # (multipart/mixed:0 (text/plain:681) (image/gif:774))
    my $visitor;
    $visitor = sub {
        my ($entity) = @_;
        my $type = $entity->{'type'};
        my $subtype = $entity->{'subtype'};
        my $number = $entity->{'number'};
        my $ofs  = $entity->{'offset'};
        if ($type eq 'multipart') {
            my $str = "($number $type/$subtype:$ofs";
            $str .= ' ' . $visitor->($_) for @{ $entity->{'parts'} };
            return $str . ')';
        }
        else {
            return "($number $type/$subtype:$ofs)";
        }
    };
    $visitor->($message);
}

# --- Utility functions

sub parse_header {
    my ($self, $str) = @_;
    #my $str = $$hdrref;
    $str =~ s/\n(?=[ \t])//g;
    my @fields;
    while ($str =~ /(.+)/g) {
        push @fields, [split /:\s+/, $1, 2];
    }
    return fields2hash(\@fields);
}

sub fields2hash {
    my ($F) = @_;
    my %F;
    foreach (@$F) {
        my ($name, $value) = @$_;
        push @{ $F{lc $name} ||= [] }, $value;
    }
    return \%F;
}

sub parse_content_type {
    my ($str) = @_;
    my ($type, $subtype, $params_str) = split m{/|;\s*}, $str, 3;
    return (lc $type, lc $subtype, parse_params($params_str));
}

sub parse_params {
    my ($str) = @_;
    $str = '' unless defined $str;
    my %param;
    while ($str =~ s/^([^\s=]+)=//) {
        my $name = lc $1;
        if ($str =~ /^"/) {
            my $value = extract_delimited($str, q{"}, '');
            $value =~ s/^"|"$//g;
            $value =~ s/\\(.)|([^\\"]+)|(.)/$+/g;
            $param{$name} = $value;
            # 
        }
        elsif ($str =~ s/^([^\s()<>@,;:\\"\/\[\]?=]+)//) {
            $param{$name} = $1;
        }
        else {
            die "Bad params: $str";
        }
        die "Bad params: $str" unless $str =~ s/^(\s*;\s*|\s*$)//;
    }
    return \%param;
}


1;

=pod

=head1 NAME

MIME::Structure - determine structure of MIME messages

=head1 SYNOPSIS

    use MIME::Structure;
    $parser = MIME::Structure->new;
    $message = $parser->parse($filehandle);
    print $message->{'header'};
    $parts = $message->{'parts'};
    foreach ($parts) {
        $offset  = $_->{'offset'};
        $type    = $_->{'type'};
        $subtype = $_->{'subtype'};
        $line    = $_->{'line'};
        $header  = $_->{'header'};
    }
    print $parser->concise_structure($message), "\n";

=cut

=head1 METHODS

=over 4

=item B<new>

    $parser = MIME::Structure->new;

=item B<parse>

    $message = $parser->parse($filehandle);
    ($message, @other_entities) = $parser->parse($filehandle);

Parses the message found in the given filehandle.

A MIME message takes the form of a non-empty tree, each of whose nodes is
termed an I<entity> (see RFCs 2045-2049).  The root entity is the message
itself; the children of a multipart message are the parts it contains. (A
non-multipart message has no children.)

When called in list context, the B<parse> method returns a list of references
to hashes; each hash contains information about a single entity in the message.

The first hash represents the message itself; if it is a multipart message,
subsequent entities are its parts and subparts B<in the order in which they
occur in the message> -- in other words, in pre-order.  If called in scalar
context, only a reference to the hash containing information about the message
itself is returned.

The following elements may appear in these hashes:

=over 4

=item B<body_offset>

The offset, in bytes, of the entity's body.

=item B<content_length>

The length, in bytes, of the entity's body.  Currently only set for the message
itself.

=item B<encoding>

The value of the entity's Content-Transfer-Encoding field.

=item B<fields>

If the B<keep_fields> option is set, this will be a reference to a hash
whose keys are the names (converted to lower case) are the names of all fields
present in the entity;s header and whose values xxx.

=item B<header>

The entity's full header as it appeared in the message, not including the final
blank line.  This will be presently only if the B<keep_header> option is set.

=item B<kind>

C<message> if the entity is the message, or C<part> if it is a part within a message
(or within another part).

=item B<length>

The length, in bytes, of the entire entity, including its header and body. 
Currently only set for the message itself.

=item B<level>

The level at which the entity is found.  The message itself is at level 0, its
parts (if any) are at level 1, their parts are at level 2, and so on.

=item B<line>

The line number (1-based) of the first line of the message's header.  The message itself always, by definition,
is at line 1.

=item B<number>

A dotted-decimal notation that indicates the entity's place within the message.
The root entity (the message itself) has number 1; its parts (if it has any any)
are numbered 1.1, 1.2, 1.3, etc., and the numbers of their parts in turn (if
they have any) are constructed in like manner.

=item B<offset>

The offset B<in bytes> of the first line of the entity's header, measured from
the first line of the message's header.  The message itself always, by definition,
is at offset 0.

=item B<parent>

A reference to the hash representing the entity's parent.  If the entity is
the message itself, this is undefined.

=item B<parts>

A reference to an array of the entity's parts.  This will be present only if
the entity is of type B<multipart>.

=item B<parts_boundary>

The string used as a boundary to delimit the entity's parts.  Present only in
multipart entities.

=item B<subtype>

The MIME media subtype of the entity's content, e.g., C<plain> or C<jpeg>.

=item B<type>

The MIME media type of the entity's content, e.g., C<text> or C<image>.

=item B<type_params>

A reference to a hash containing the attributes (if any) found in the
Content-Type: header field.  For example, given the following Content-Type header:

    Content-Type: text/html; charset=UTF-8

The entity's B<type_params> element will be this:

    $entity{'type_params'} = {
        'charset' => 'UTF-8',
    }

=back

Besides parsing the message, this method may also be used to print the message,
or portions thereof, as it parses; the B<print> method (q.v.) may be used to
specify what to print.

=item B<keep_header>

    $keep_header = $parser->keep_header;
    $parser->keep_header(1);

Set (or get) whether headers should be remembered during parsing.

=item B<keep_fields>

Set (or get) whether fields (normalized headers) should be remembered.

=item B<print>

    $print = $parser->print;
    $parser->print($MIME::Structure::PRINT_HEADER | $MIME::Structure::PRINT_BODY);
    $parser->print('header,body');

Set (or get) what should be printed.  This may be specified either as any of the
following symbolic constants, ORed together:

=over 4

=item B<PRINT_NONE>

=item B<PRINT_HEADER>

=item B<PRINT_BODY>

=item B<PRINT_PREAMBLE>

=item B<PRINT_EPILOGUE>

=back

Or using the following string constants concatenated using any delimiter:

=over 4

=item B<none>

=item B<header>

=item B<body>

=item B<preamble>

=item B<epilogue>

=back

=item B<print_header>

    $print_header = $parser->print_header;
    $parser->print_header(1);

Set (or get) whether headers should be printed.

=item B<print_body>

    $print_body = $parser->print_body;
    $parser->print_body(1);

Set (or get) whether bodies should be printed.

=item B<print_preamble>

    $print_preamble = $parser->print_preamble;
    $parser->print_preamble(1);

Set (or get) whether preambles should be printed.

=item B<print_epilogue>

    $print_epilogue = $parser->print_epilogue;
    $parser->print_epilogue(1);

Set (or get) whether epilogues should be printed.

=item B<entities>

    $parser->parse;
    print "$_->{type}/$_->{subtype} $_->{offset}\n"
        for @{ $parser->entities };

Returns a reference to an array of all the entities in a message, in the order
in which they occur in the message.  Thus the first entity is always the root
entity, i.e., the message itself).

=item B<concise_structure>

    $parser->parse;
    print $parser->concise_structure;
    # e.g., '(multipart/alternative:0 (text/html:291) (text/plain:9044))'

Returns a string showing the structure of a message, including the content
type and offset of each entity (i.e., the message and [if it's multipart] all
of its parts, recursively).  Each entity is printed in the form:

    "(" content-type ":" byte-offset [ " " parts... ")"

Offsets are B<byte> offsets of the entity's header from the beginning of the
message.  (If B<parse()> was called with an I<offset> parameter, this is added
to the offset of the entity's header.)

N.B.: The first offset is always 0.

=back

=head1 BUGS

Documentation is sketchy.

=head1 AUTHOR

Paul Hoffman E<lt>nkuitse (at) cpan (dot) orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Paul M. Hoffman. All rights reserved.

This program is free software; you can redistribute it
and modify it under the same terms as Perl itself. 

=cut


