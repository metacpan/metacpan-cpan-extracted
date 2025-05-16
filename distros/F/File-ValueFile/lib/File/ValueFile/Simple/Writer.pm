# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024-2025 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile::Simple::Writer;

use v5.10;
use strict;
use warnings;

use parent 'Data::Identifier::Interface::Userdata';

use Carp;
use URI::Escape qw(uri_escape uri_escape_utf8);
use Data::Identifier v0.03;

use File::ValueFile;

use constant {
    FORMAT_ISE     => '54bf8af4-b1d7-44da-af48-5278d11e8f32',
    SF_ISE         => 'e5da6a39-46d5-48a9-b174-5c26008e208e', # tagpool-source-format
    TLv1_ISE       => 'afdb46f2-e13f-4419-80d7-c4b956ed85fa', # tagpool-taglist-format-v1
    F_M_L_ISE      => 'f06c2226-b33e-48f2-9085-cd906a3dcee0', # tagpool-source-format-modern-limited
    F_M_F_ISE      => '1c71f5b1-216d-4a9b-81a1-54dc22d8a067', # tagpool-source-format-modern-full
    DOT_REPEAT_ISE => '2ec67bbe-4698-4a0c-921d-1f0951923ee6',
};

my %_default_style = (
    generator_hint              => 'auto',
    degenerate_generator_hint   => undef,
    tag_ise_no_ise_retry        => undef,
    tag_ise_no_ise_one          => 1,
    tag_ise_no_ise_no_uriid     => 1,
);

our $VERSION = v0.07;



sub new {
    my ($pkg, $out, %opts) = @_;
    my $fh;
    my $self = bless \%opts;
    my $_is_utf8;
    my %features;

    if (ref $out) {
        $fh = $out;
    } else {
        open($fh, '>', $out) or croak $!;
    }

    {
        my $style = delete $opts{style};
        $self->{style} = {%_default_style};
        $self->style(%{$style}) if defined $style;
    }

    $self->{fh} = $fh;
    $self->{features} = \%features;
    $self->{escape} = \&uri_escape; # set here, so we can write the markers.

    if (defined $opts{format}) {
        my $format = $self->{format} = Data::Identifier->new(from => $opts{format});

        $self->_write_marker(required => 'ValueFile', FORMAT_ISE, $format);
        $_is_utf8 ||= File::ValueFile->_is_utf8($format);
    }

    foreach my $type (qw(required copy optional)) {
        my $list = $opts{$type.'_feature'} // next;
        $list = [$list] unless ref($list) eq 'ARRAY';
        foreach my $entry (@{$list}) {
            my $feature = Data::Identifier->new(from => $entry);

            $self->{dot_repreat} ||= $feature->eq(DOT_REPEAT_ISE);

            $self->_write_marker($type, 'Feature', $feature);
            $_is_utf8 ||= File::ValueFile->_is_utf8($feature);
            $features{$feature->ise} = $feature;
        }
    }

    $opts{utf8} //= 'auto';

    if ($opts{utf8} eq 'auto') {
        $opts{utf8} = $_is_utf8;
    }

    $self->{escape} = $opts{utf8} ? \&uri_escape_utf8 : \&uri_escape;

    return $self;
}


#@returns Data::Identifier
sub format {
    my ($self, %opts) = @_;
    return $self->{format} if defined $self->{format};
    return $opts{default} if exists $opts{default};
    croak 'No value for format';
}


sub features {
    my ($self, %opts) = @_;
    return values %{$self->{features}};
}


sub style {
    my ($self, @args) = @_;

    if (scalar(@args) == 1) {
        return $self->{style}{$args[0]};
    } elsif ((scalar(@args) & 1) == 0) {
        my %merge = @args;
        foreach my $key (keys %merge) {
            croak 'Invalid style: '.$key unless exists $_default_style{$key};
            $self->{style}{$key} = $merge{$key};
        }
        return undef;
    }

    croak 'Invalid call (bad arguments?)';
}

sub _escape {
    my ($self, $in) = @_;

    return '!null' if !defined $in;
    return '!empty' if $in eq '';

    return $self->{escape}->($in);
}

sub _write_marker {
    my ($self, $type, @line) = @_;

    $self->{last_line} = undef;

    if ($type eq 'required') {
        $self->{fh}->print('!!');
    } elsif ($type eq 'copy') {
        $self->{fh}->print('!&');
    } elsif ($type eq 'optional') {
        $self->{fh}->print('!?');
    } else {
        croak 'Bug: Bad marker: '.$type;
    }

    @line = map {$self->_escape($_)} map {ref($_) ? $_->ise : $_} @line;

    local $, = ' ';
    $self->{fh}->say(@line);
}


sub write {
    my ($self, @line) = @_;

    unless (scalar @line) {
        $self->{fh}->say('');
        return;
    }

    @line = map {ref($_) ? $_->ise : $_} @line;

    if ($self->{dot_repreat}) {
        my $line = [@line];
        if (defined(my $last_line = $self->{last_line})) {
            my $x = 0;
            foreach my $e (@line) {
                if (defined $e) {
                    if (defined($last_line->[$x]) && $e eq $last_line->[$x]) {
                        $e = '.';
                    } elsif ($e =~ /^\.+$/) {
                        $e .= '.';
                    }
                } elsif (!defined($last_line->[$x])) {
                    $e = '.';
                }
                $x++;
            }
        } else {
            foreach my $e (@line) {
                if (defined $e) {
                    if ($e =~ /^\.+$/) {
                        $e .= '.';
                    }
                }
            }
        }
        $self->{last_line} = $line;
    }

    @line = map {$self->_escape($_)} @line;

    {
        my $l = length($line[0]);
        $line[0] .= ' ' x (19 - $l) if $l < 19;
    }

    local $, = ' ';
    if ($self->{no_eol}) {
        $self->{fh}->print(@line);
    } else {
        $self->{fh}->say(@line);
    }
}


sub write_with_comment {
    my ($self, @line) = @_;
    my $comment = pop(@line);
    my $valid_comment = defined($comment) && length($comment);

    croak 'Unsupported comment: Bad characters' if $valid_comment && $comment =~ /[\x00-\x1F]/;

    if (scalar(@line)) {
        local $self->{no_eol} = $valid_comment;
        $self->write(@line);
        $self->{fh}->print(' ') if $valid_comment;
    }

    if ($valid_comment) {
        $self->{fh}->say('# ', $comment);
    }
}


sub write_blank {
    my ($self) = @_;
    return $self->write;
}


sub write_comment {
    my ($self, @comment) = @_;

    foreach my $comment_line (map {split /[\r\n]/} grep {defined} @comment) {
        croak 'Unsupported comment: Bad characters' if $comment_line =~ /[\x00-\x1F]/;
        $self->{fh}->say('# ', $comment_line);
    }
}


sub write_hash {
    my ($self, $hash) = @_;

    foreach my $key (keys %{$hash}) {
        my $value = $hash->{$key};

        $value = [$value] unless ref($value) eq 'ARRAY';

        foreach my $entry (@{$value}) {
            $self->write($key => $entry);
        }
    }
}


sub write_taglist {
    my ($self, @list) = @_;
    my $format = $self->format;
    my $mode;

    if ($format->eq(SF_ISE)) { # tagpool-source-format
        if (defined $self->{features}{F_M_L_ISE()}) { # tagpool-source-format-modern-limited
            $mode = 'tag-ise';
        } elsif (defined $self->{features}{F_M_F_ISE()}) { # tagpool-source-format-modern-full
            $mode = 'full';
        } else {
            $mode = 'tag';
        }
    } elsif ($format->eq(TLv1_ISE)) { # tagpool-taglist-format-v1
        $mode = 'tag';
    } else {
        croak 'Unsupported format';
    }

    if ($mode eq 'full') {
        foreach my $sublist (@list) {
            $sublist = [$sublist] unless ref($sublist) eq 'ARRAY';
            foreach my $id (@{$sublist}) {
                $self->write_tag_ise($id);
            }
        }
    } else {
        foreach my $sublist (@list) {
            $sublist = [$sublist] unless ref($sublist) eq 'ARRAY';
            foreach my $id (@{$sublist}) {
                $self->write($mode, Data::Identifier->new(from => $id)->uuid);
            }
        }
    }
}


sub write_tag_ise {
    my ($self, @ids) = @_;
    my $displayname;
    my %collected = (uuid => {}, oid => {}, uri => {});

    @ids = map {ref($_) eq 'ARRAY' ? @{$_} : $_} @ids;

    foreach my $id (@ids) {
        my $found_for_id;

        $id = Data::Identifier->new(ise => $id) unless ref $id;

        $displayname //= $id->displayname(default => undef, no_defaults => 1);

        foreach my $key (qw(uuid oid uri)) {
            my $func = $id->can($key);
            my $value = $id->$func(default => undef, no_defaults => 1, as => $key);
            if (defined $value) {
                $collected{$key}{$value} = undef;
                $found_for_id = 1;
            }
        }

        unless ($found_for_id) {
            if (defined(my $retry = $self->{style}{tag_ise_no_ise_retry})) {
                my @list = map {$_ eq 'all' || $_ eq 'ise' ? qw(uuid oid uri) : ($_)} ref($retry) ? @{$retry} : split(/\s*,\s*|\s+/, $retry);

                foreach my $key (@list) {
                    my $func = $id->can($key) // croak 'Bad value for retry: '.$key;
                    my $value = $id->$func(default => undef, as => $key);
                    if (defined $value) {
                        next if $value =~ m#^https://uriid\.org/# && $self->{style}{tag_ise_no_ise_no_uriid};
                        $collected{$key}{$value} = undef;
                        $found_for_id = 1;
                        last if $self->{style}{tag_ise_no_ise_one};
                    }
                }

                croak 'No ISE found (after retry) for one of the ids' unless $found_for_id;
            } else {
                croak 'No ISE found for one of the ids' unless $found_for_id;
            }
        }
    }

    croak 'No ISEs found' unless scalar(keys(%{$collected{uuid}})) + scalar(keys(%{$collected{oid}})) +  scalar(keys(%{$collected{uri}}));

    $self->write_with_comment('tag-ise', keys(%{$collected{uuid}}), keys(%{$collected{oid}}), keys(%{$collected{uri}}), $displayname);
}


sub write_tag_relation {
    my ($self, @args) = @_;
    my ($tag, $relation, $related, $context, $filter);
    my %opts;
    my $comment;

    if (scalar(@args) == 1) {
        my $ref = ref($args[0]);
        if ($ref eq 'HASH') {
            return $self->write_tag_relation(%{$args[0]});
        } elsif ($ref eq 'ARRAY') {
            return $self->write_tag_relation(@{$args[0]});
        } else {
            $tag        = $args[0]->tag(default => undef, no_defaults => 1);
            $relation   = $args[0]->relation(default => undef, no_defaults => 1);
            $related    = $args[0]->related(default => undef, no_defaults => 1);
            $context    = $args[0]->context(default => undef, no_defaults => 1);
            $filter     = $args[0]->filter(default => undef, no_defaults => 1);
        }
    } elsif (scalar(@args) == 3 || scalar(@args) == 5) {
        ($tag, $relation, $related, $context, $filter) = @args;
    } elsif ((scalar(@args) % 2) == 0) {
        %opts       = @args;

        $tag        = $opts{tag};
        $relation   = $opts{relation};
        $related    = $opts{related};
        $context    = $opts{context};
        $filter     = $opts{filter};
    } else {
        croak 'Invalid argument configuration';
    }

    croak 'No tag given'        unless defined $tag;
    croak 'No relation given'   unless defined $relation;
    croak 'No related given'    unless defined $related;

    # Ensure types and well formatting:
    foreach my $ent ($tag, $relation, $related, $context, $filter) {
        next unless defined $ent;
        $ent = Data::Identifier->new(ise => $ent) unless ref $ent;
    }

    {
        my $displayname_relation = $relation->displayname(default => undef, no_defaults => 1);
        my $displayname_related  = $related->displayname(default => undef, no_defaults => 1);

        if (defined($displayname_relation) && defined($displayname_related)) {
            $comment = sprintf('%s: %s', $displayname_relation, $displayname_related);
        } elsif (defined($displayname_relation)) {
            $comment = $displayname_relation;
        } elsif (defined($displayname_related)) {
            $comment = '?: '.$displayname_related;
        }
    }

    $self->write_with_comment('tag-relation', $tag, $relation, $related, $context, $filter, $comment);
}


sub write_tag_metadata {
    my ($self, @args) = @_;
    my ($tag, $relation, $context, $type, $encoding, $data_raw);
    my %opts;
    my $comment;

    if (scalar(@args) == 1) {
        my $ref = ref($args[0]);
        if ($ref eq 'HASH') {
            return $self->write_tag_metadata(%{$args[0]});
        } elsif ($ref eq 'ARRAY') {
            return $self->write_tag_metadata(@{$args[0]});
        } else {
            $tag        = $args[0]->tag(default => undef, no_defaults => 1);
            $relation   = $args[0]->relation(default => undef, no_defaults => 1);
            $context    = $args[0]->context(default => undef, no_defaults => 1);
            $type       = $args[0]->type(default => undef, no_defaults => 1);
            $encoding   = $args[0]->encoding(default => undef, no_defaults => 1);
            $data_raw   = $args[0]->data_raw(default => undef, no_defaults => 1);
        }
    } elsif (scalar(@args) == 3) {
        ($tag, $relation, $data_raw) = @args;
    } elsif (scalar(@args) == 5) {
        ($tag, $relation, $type, $encoding, $data_raw) = @args;
    } elsif ((scalar(@args) % 2) == 0) {
        %opts       = @args;

        $tag        = $opts{tag};
        $relation   = $opts{relation};
        $context    = $opts{context};
        $type       = $opts{type};
        $encoding   = $opts{encoding};
        $data_raw   = $opts{data_raw};
    } else {
        croak 'Invalid argument configuration';
    }

    croak 'No tag given'        unless defined $tag;
    croak 'No relation given'   unless defined $relation;
    croak 'No data_raw given'   unless defined $data_raw;

    # Ensure types and well formatting:
    foreach my $ent ($tag, $relation, $context, $type, $encoding) {
        next unless defined $ent;
        $ent = Data::Identifier->new(ise => $ent) unless ref $ent;
    }

    $comment = $relation->displayname(default => undef, no_defaults => 1);
    if (defined($comment) && defined($type) && defined(my $type_displayname = $type->displayname(default => undef, no_defaults => 1))) {
        $comment .= '('.$type_displayname.')';
    }

    $self->write_with_comment('tag-metadata', $tag, $relation, $context, $type, $encoding, $data_raw, $comment);
}


sub write_tag_generator_hint {
    my ($self, $tag, $generator, $hint) = @_;

    $generator //= Data::Identifier->new(from => $tag)->generator(default => undef);
    $hint      //= Data::Identifier->new(from => $tag)->request(default => undef);

    if (ref($hint) eq 'ARRAY') {
        $hint = join('--', sort map {$_->uuid} @{$hint});
    }

    if ((!defined($generator) || !defined($hint)) && ($self->{style}{degenerate_generator_hint} // '') eq 'auto') {
        $self->write_tag_ise($tag);
        return;
    }

    croak 'No generator given' unless defined $generator;
    croak 'No hint given' unless defined $hint;

    if (
        $self->{style}{generator_hint} eq 'auto' &&
        (
            defined($self->{features}{F_M_L_ISE()}) ||  # tagpool-source-format-modern-limited
            defined($self->{features}{F_M_F_ISE()})     # tagpool-source-format-modern-full
        )
    ) {
        state $generator_request = Data::Identifier->new(uuid => 'ab573786-73bc-4f5c-9b03-24ef8a70ae45')->register;
        state $generated_by      = Data::Identifier->new(uuid => '8efbc13b-47e5-4d92-a960-bd9a2efa9ccb')->register;

        $self->write_tag_metadata($tag, $generator_request, $hint);
        $self->write_tag_relation($tag, $generated_by, Data::Identifier->new(from => $generator));
    } else {
        $self->write('tag-generator-hint', $tag, $generator, $hint);
    }
}


sub write_tagname {
    my ($self, $tag, $tagname) = @_;

    return unless defined($tagname) && length($tagname);

    if (
        defined($self->{features}{F_M_L_ISE()}) ||  # tagpool-source-format-modern-limited
        defined($self->{features}{F_M_F_ISE()})     # tagpool-source-format-modern-full
    ) {
        state $wk_asi       = Data::Identifier->new(uuid => 'ddd60c5c-2934-404f-8f2d-fcb4da88b633')->register;
        state $wk_tagname   = Data::Identifier->new(uuid => 'bfae7574-3dae-425d-89b1-9c087c140c23')->register;


        $self->write_tag_metadata($tag, $wk_asi, $wk_tagname, undef, $tagname);
    } else {
        $self->write('tag', $tag, $tagname);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile::Simple::Writer - module for reading and writing ValueFile files

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use File::ValueFile::Simple::Writer;

This module provides a simple way to write ValueFile files.

This module inherit from L<Data::Identifier::Interface::Userdata>.

=head1 METHODS

=head2 new

    my $writer = File::ValueFile::Simple::Writer->new($out [, %opts]);

Opens a writer for the given output file.
C<$out> can be an open file handle that must support seeking or a filename.

This method dies on any problem.

In addition the following options (all optional) are supported:

=over

=item C<format>

The format to use. Must be an ISE or an instances of L<Data::Identifier>.

=item C<required_feature>, C<copy_feature>, C<optional_feature>

Features that are used in the file.
Required features need to be supported by the reading entity.
Copy features are safe to be copied, even if not understood.
Optional features do not need to be understood by the reader.

May be a single feature or a list (as array ref).
Each feature is given by the ISE or an instances of L<Data::Identifier>.

=item C<utf8>

The UTF-8 flag for encoding strings.
If set true all data with code points outside the ASCII range is encoded as UTF-8.
If set (non-C<undef>) false all data is encoded as binary (code points outside the 8 bit range are invalid).
If set to C<auto> UTF-8 is enabled based on the set format and features.
This is the default.

=item C<style>

(since v0.07)

A hashref with values as can be passed to L</style>.

=back

=head2 format

    my Data::Identifier $format = $writer->format;
    # or:
    my Data::Identifier $format = $writer->format(default => $def);

Returns the format of the file. This requires the format to be given via L</new>.
If no format is set the default is returned.
If no default is given this method dies.

=head2 features

    my @features = $writer->features;

Returns the list of features of the file. This requires the features to be given via L</new>.

Elements of the list returned are instances L<Data::Identifier>.

=head2 style

    $writer->style($style0 => $value0 [, $style1 = $value1 [, ...] ] );
    # or:
    my $value = $writer->style($style);

(since v0.07)

Gets or sets styles for the current writer.
This method C<die>s if it detects any error.

The following styles are supported:

=over

=item C<degenerate_generator_hint>

Whether or not degenerate to L</write_tag_ise> if a call to L</write_tag_generator_hint> is incomplete (no generator or hint provided).
One of C<undef> (default) or C<'auto'>.

=item C<generator_hint>

The style to use for generator hints (see L</write_tag_generator_hint>).
One of C<'auto'> (default) or C<'tag-generator-hint'>.

=item C<tag_ise_no_ise_retry>

The list of retry values to use if L</write_tag_ise> cannot find a valid ISE for any of the given identifiers.
One of C<undef> (default) to disable retries, C<uuid>, C<oid>, or C<uri> to use the UUID, OID, or URI, or C<all> to try them all.
May also be a arrayref of the values listed above.

=item C<tag_ise_no_ise_one>

Whether or not use only the first usable value if C<tag_ise_no_ise_retry> is active.
Boolean, default true (only use the first).

=item C<tag_ise_no_ise_no_uriid>

Whether or not L<https://uriid.org/> backup values should be skipped if C<tag_ise_no_ise_retry> is active.
Boolean, default true.

=back

=head2 write

    $writer->write(@line);

Writes a single line (record). Correctly escapes the output.

Values in C<@line> may be strings, numbers, or instances of L<Data::Identifier>.

=head2 write_with_comment

    $writer->write_with_comment(@line, $comment);

Write a line alike L</write> but finishes the line with a comment.
The comment must be a single line comment or C<undef>.

If the comment is C<undef> no comment is written.

For writing comments individually see L</write_comment>.

=head2 write_blank

    $writer->write_blank;

Write a blank line. Such lines have no technical meaning, however are sometimes used to make the result more readable.

=head2 write_comment

    $writer->write_comment($comment [, ...]);

Writes one or more comments. Each comment begins a new line.
If a comment contains line breaks it is split into a individual comments.
If any comment is C<undef> it is skipped without any warnings.

=head2 write_hash

    $writer->write_hash($hashref);

Writes a hash as returned by L<File::ValueFile::Simple::Reader/read_as_hash> or L<File::ValueFile::Simple::Reader/read_as_hash_of_arrays>.

Values in C<$hashref> may be strings, numbers, or instances of L<Data::Identifier>.

=head2 write_taglist

    $writer->write_taglist($tag [, ...]);
    # or:
    $writer->write_taglist($arrayref_of_tags);

Writes a taglist using the selected format.
The exact output depends on the selected format and features.

This method takes the tags to be written as arguments.
If any argument is an arrayref then the tags contained in that arrayref
are also written.

A tag here is anything that can be used as input to L<Data::Identifier/new>'s C<from>.
If a given tag uses an identifier that is not supported by the selected format (and features)
this method might try to convert or die.

B<Note:> UUIDs are the only identifier type supported by all formats.

If there is any error, this method dies.

See also:
L<File::ValueFile::Simple::Reader/read_as_taglist>.

=head2 write_tag_ise

    $writer->write_tag_ise(@ids);
    # or:
    $writer->write_tag_ise([@ids]);

Writes a C<tag-ise> line for the given identifiers.
L<@ids> can include raw ISEs or instances of L<Data::Identifier>.

The method will write a most compatible line with a comment if the provided data allows.

=head2 write_tag_relation

    $writer->write_tag_relation($tag, $relation, $related);
    # or:
    $writer->write_tag_relation($tag, $relation, $related, $context, $filter);
    # or:
    $writer->write_tag_relation(tag => $tag, relation => $relation, related => $related [, context => $context ] [, filter => ]);
    # or:
    $writer->write_tag_relation({tag => $tag, relation => $relation, related => $related [, context => $context ] [, filter => ]});
    # or:
    $writer->write_tag_relation($link);

Writes a C<tag-relation> line for the given relation.
This function is smart and will write the most compatible line possible, including a comment.

Each of C<$tag>, C<$relation>, C<$related>, C<$context>, and C<$filter> must be a raw ISE or an instances of L<Data::Identifier>.
C<$context>, and C<$filter> may also be C<undef>.

C<$link> must be any object that implements the methods C<tag>, C<relation>, C<related>, C<context>, and C<filter>.
Each method must return the corresponding value in a format as defined above.
Each method must also tolerable the options C<default>, C<no_defaults>, and C<as> to be passed (with any value).

=head2 write_tag_metadata

    $writer->write_tag_metadata($tag, $relation, $data_raw);
    # or:
    $writer->write_tag_metadata($tag, $relation, $type, $encoding, $data_raw);
    # or:
    $writer->write_tag_metadata(tag => $tag, relation => $relation, data_raw => $data_raw [, type => $type ] [, encoding => $encoding ] [, context => $context ]);
    # or:
    $writer->write_tag_metadata({tag => $tag, relation => $relation, data_raw => $data_raw [, type => $type ] [, encoding => $encoding ] [, context => $context ]});
    # or:
    $writer->write_tag_metadata($link);

Writes a C<tag-metadata> line for the given relation.
This function is smart and will write the most compatible line possible, including a comment.

Each of C<$tag>, C<$relation>, C<$context>, C<$type>, and C<$encoding> must be a raw ISE or an instances of L<Data::Identifier>.
C<$context>, C<$type>, and C<$encoding> may also be C<undef>.

C<$raw_data> must be a value allowed by L</write>.

C<$link> must be any object that implements the methods C<tag>, C<relation>, C<context>, C<type>, and C<encoding>.
Each method must return the corresponding value in a format as defined above.
Each method must also tolerable the options C<default>, C<no_defaults>, and C<as> to be passed (with any value).

=head2 write_tag_generator_hint

    $writer->write_tag_generator_hint($tag, $generator, $hint);
    # or:
    $writer->write_tag_generator_hint($tag); # requires Data::Identifier v0.13

Write a generator hint for the given C<$generator> and C<$hint> values.
C<$tag> and C<$generator> may be an ISE or an instances of L<Data::Identifier>.
C<$hint> is the raw hint.

If only C<$tag> is given the other values will be extracted if $tag is a L<Data::Identifier> and includes them.

This method automatically selects the best command to write depending on the format and features.

=head2 write_tagname

    $writer->write_tagname($tag, $tagname);

Writes the given tagname for the given tag. If C<$tagname> is C<undef> or an empty string this method will
silently return without error.

This method automatically selects the best command to write depending on the format and features.

B<Note:>
The tagname to be written is subject to normal character set rules. Therefore it should be a perl unicode string (not UTF-8 encoded).

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
