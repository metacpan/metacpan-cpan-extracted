# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile::Simple::Writer;

use v5.10;
use strict;
use warnings;

use Carp;
use URI::Escape qw(uri_escape_utf8);
use Data::Identifier v0.03;

use constant FORMAT_ISE => '54bf8af4-b1d7-44da-af48-5278d11e8f32';

our $VERSION = v0.02;



sub new {
    my ($pkg, $out, %opts) = @_;
    my $fh;
    my $self = bless \%opts;

    if (ref $out) {
        $fh = $out;
    } else {
        open($fh, '>', $out) or croak $!;
    }

    $self->{fh} = $fh;

    if (defined $opts{format}) {
        $self->_write_marker(required => 'ValueFile', FORMAT_ISE, $opts{format});
    }

    foreach my $type (qw(required copy optional)) {
        my $list = $opts{$type.'_feature'} // next;
        $list = [$list] unless ref($list) eq 'ARRAY';
        foreach my $entry (@{$list}) {
            $self->_write_marker($type, 'Feature', $entry);
        }
    }

    return $self;
}

sub _escape {
    my ($in) = @_;

    return '!null' if !defined $in;
    return '!empty' if $in eq '';

    return uri_escape_utf8($in);
}

sub _write_marker {
    my ($self, $type, @line) = @_;
    if ($type eq 'required') {
        $self->{fh}->print('!!');
    } elsif ($type eq 'copy') {
        $self->{fh}->print('!&');
    } elsif ($type eq 'optional') {
        $self->{fh}->print('!?');
    } else {
        croak 'Bug: Bad marker: '.$type;
    }

    @line = map {_escape($_)} map {ref($_) ? $_->ise : $_} @line;

    local $, = ' ';
    $self->{fh}->say(@line);
}


sub write {
    my ($self, @line) = @_;

    unless (scalar @line) {
        $self->{fh}->say('');
        return;
    }

    @line = map {_escape($_)} map {ref($_) ? $_->ise : $_} @line;

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


sub write_tag_ise {
    my ($self, @ids) = @_;
    my $displayname;
    my %collected = (uuid => {}, oid => {}, uri => {});

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
        croak 'No ISE found for one of the ids' unless $found_for_id;
    }

    croak 'No ISEs found' unless scalar(keys(%{$collected{uuid}})) + scalar(keys(%{$collected{oid}})) +  scalar(keys(%{$collected{uri}}));

    local $self->{no_eol} = defined($displayname);
    $self->write('tag-ise', keys(%{$collected{uuid}}), keys(%{$collected{oid}}), keys(%{$collected{uri}}));
    say ' # '.$displayname if defined $displayname;
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

    local $self->{no_eol} = defined($comment);
    $self->write('tag-relation', $tag, $relation, $related, $context, $filter);
    say ' # '.$comment if defined $comment;
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
        ($tag, $relation, $type, $encoding, $data_raw) = @_;
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

    local $self->{no_eol} = defined($comment);
    $self->write('tag-metadata', $tag, $relation, $context, $type, $encoding, $data_raw);
    say ' # '.$comment if defined $comment;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile::Simple::Writer - module for reading and writing ValueFile files

=head1 VERSION

version v0.02

=head1 SYNOPSIS

    use File::ValueFile::Simple::Writer;

This module provides a simple way to write ValueFile files.

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

=back

=head2 write

    $writer->write(@line);

Writes a single line (record). Correctly escapes the output.

Values in C<@line> may be strings, numbers, or instances of L<Data::Identifier>.

=head2 write_hash

    $writer->write_hash($hashref);

Writes a hash as returned by L<File::ValueFile::Simple::Reader/read_as_hash> or L<File::ValueFile::Simple::Reader/read_as_hash_of_arrays>.

Values in C<$hashref> may be strings, numbers, or instances of L<Data::Identifier>.

=head2 write_tag_ise

    $writer->write_tag_ise(@ids);

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

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
