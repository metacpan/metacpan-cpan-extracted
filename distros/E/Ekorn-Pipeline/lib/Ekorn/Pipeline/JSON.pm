use v5.36;

package Ekorn::Pipeline::JSON;

use experimental qw(builtin try);

use builtin                    qw(blessed);
use Exporter                   qw(import);
use JSON::MaybeXS              qw();
use Ref::Util                  qw(is_plain_arrayref is_plain_hashref);
use Scalar::Util               qw(openhandle);
use Ekorn::Pipeline::Errors    qw(croakf);
use Ekorn::Pipeline::Factories qw(gather sink_one source stage);
use namespace::clean -except => 'import';

our @EXPORT_OK   = qw(from_json from_jsonl to_json to_jsonl);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

# Croak at the line that called Ekorn::Pipeline.
our @CARP_NOT = @Ekorn::Pipeline::Errors::INTERNAL;

# How much a source reads at a time, before reading on to the end of the
# line, so that no number is cut in two; the tests make it small.
our $BLOCK = 65_536;

# A source of one JSON document, read from the file or filehandle: its
# elements, if it's an array, or itself. Given neither, a stage decoding
# each value, one document, the same way.
sub from_json (@options) {
    my %option = _options(@options);
    return _reader(\%option, 'json') if _has_input(\%option);
    my $json = $option{new}->();
    return stage {
        my $document;
        try {
            $document = $json->decode($_);
        }
        catch ($e) {
            _undecodable($json, 'a value', _unplaced($e));
        }
        return is_plain_arrayref($document) ? @$document : $document;
    };
}


# A source of the documents in a file or filehandle of JSON Lines, each
# as it is. Given neither, a stage decoding each value, a text of one or
# more lines, into each line's document.
sub from_jsonl (@options) {
    my %option = _options(@options);
    return _reader(\%option, 'lines') if _has_input(\%option);
    my $new = $option{new};
    return gather {
        my $json = $new->();    # this run's, as its parser holds what it's read
        return sub ($text) {
            my @documents;
            try {
                @documents = $json->incr_parse($text);
            }
            catch ($e) {
                _undecodable($json, 'a value', _unplaced($e));
            }
            _complete($json, 'a value');
            return @documents;
        };
    };
}


# A sink writing every value to the file or filehandle as one JSON
# document, an array, giving how many. Given neither, a stage passing on
# every value as that array's text, once they've all come.
sub to_json (@options) {
    my %option = _options(@options);
    my $json   = $option{new}->();
    return _writer(\%option, 'json', $json) if _has_input(\%option);
    return gather {
        my @values;    # this run's
        return (
            sub ($value) { push @values, $value; return },
            sub () { _encoded($json, \@values) =~ s( \n \z )()xr },
        );
    };
}


# A sink writing each value to the file or filehandle as a line of JSON
# Lines, giving how many. Given neither, a stage passing on each value
# as its line, without its newline.
sub to_jsonl (@options) {
    my %option = _options(@options);
    my $json   = $option{new}->();
    croakf q(Expected an encoder that doesn't indent, to write JSON Lines)
        if _indents($json);
    return _writer(\%option, 'lines', $json) if _has_input(\%option);
    return stage { _encoded($json, $_) };
}


# Return the options given, checked, with "new", a sub returning the
# encoder: one made from json's options, over the defaults, or json's
# object, as it is.
sub _options (@given) {
    croakf 'Expected options as name => value pairs' if @given % 2;
    my %option  = @given;
    my @unknown = sort grep { !m( \A (?: file | fh | json ) \z )x } keys %option;
    croakf 'Expected the options file, fh and json, not %s', join ', ', @unknown
        if @unknown;
    croakf 'Expected file to be a path'
        if exists $option{file} && !defined $option{file};
    croakf 'Expected a file or a filehandle, not both'
        if defined $option{file} && exists $option{fh};
    croakf 'Expected an open filehandle'
        if exists $option{fh} && !defined openhandle($option{fh});
    my $json = $option{json};
    if (blessed($json)) {
        $option{new} = sub () { $json };
        return %option;
    }
    croakf 'Expected json to be a hash reference of options, or an encoder object'
        if defined $json && !is_plain_hashref($json);
    my %settings = (utf8 => 1, allow_nonref => 1, %{ $json // {} });
    try {
        JSON::MaybeXS->new(%settings);
    }
    catch ($e) {
        croakf 'Expected json options the encoder knows: %s', _unplaced($e);
    }
    $option{new} = sub () { JSON::MaybeXS->new(%settings) };
    return %option;
}


# Return true if the options name a file or a filehandle.
sub _has_input ($option) {
    return defined $option->{file} || !!$option->{fh};
}


# Return true if the encoder indents, so writes a document over many
# lines.
sub _indents ($json) {
    return $json->can('get_indent') && $json->get_indent;
}


# Return an error's message without the place it was raised, as a
# message of ours says where.
sub _unplaced ($error) {
    return "$error" =~ s( ,? \s+ at \s+ \S+ \s+ line \s+ \d+ \.? \s* \z )()xr;
}


# Croak that what's read from $from can't be decoded, and why. The
# decoder is reset, for the next run, if it's the caller's.
sub _undecodable ($json, $from, $why) {
    $json->incr_reset;
    return croakf q(Can't decode JSON from %s: %s), $from, $why;
}


# Croak unless the decoder has a whole number of documents: it croaks,
# asked for the text it holds, if it's inside one.
sub _complete ($json, $from) {
    try {
        $json->incr_text;
    }
    catch ($e) {
        _undecodable($json, $from, 'it ends inside a document');
    };    # the ; ends the statement for Perl::Critic, which doesn't know try
    return;
}


# Return a source of the documents in the file or filehandle: as they
# come, for JSON Lines; or, for one document, its elements, if it's an
# array, or itself, once the input has ended.
sub _reader ($option, $format) {
    my($path, $given, $new) = @{ $option }{qw(file fh new)};
    my $from = $path // 'the filehandle';
    return source {
        my $fh = $given;
        unless ($fh) {
            # Open for the run, and closed by its end.
            open $fh, '<:raw', $path    ## no critic (InputOutput::RequireBriefOpen)
                or croakf q(Can't read %s: %s), $path, $!;
        }
        my $json = $new->();            # this run's, or the caller's, reset
        $json->incr_reset;
        my(@documents, $ended);
        my $step = sub () {
            while (1) {
                return splice @documents if @documents && $format eq 'lines';
                if ($ended) {
                    return unless @documents;
                    my($only) = splice @documents;
                    return is_plain_arrayref($only) ? @$only : $only;
                }
                my $chunk = _chunk($fh, $from);
                unless (defined $chunk) {
                    _complete($json, $from);
                    $ended = 1;
                    next;
                }
                my @read;
                try {
                    @read = $json->incr_parse($chunk);
                }
                catch ($e) {
                    _undecodable($json, $from, _unplaced($e));
                }
                push @documents, @read;
                _undecodable(
                    $json, $from,
                    'it holds more than one document; read JSON Lines with from_jsonl',
                ) if $format eq 'json' && @documents > 1;
            }
        };
        return {step => $step, end => $path ? sub ($how) { close $fh } : undef};
    };
}


# Return the next chunk of $fh, read from $from: up to $BLOCK, and on to
# the end of its line; nothing at its end.
sub _chunk ($fh, $from) {
    my $chunk;
    my $read = read $fh, $chunk, $BLOCK;
    croakf q(Can't read %s: %s), $from, $! unless defined $read;
    return unless $read;
    local $/ = "\n";
    if (substr($chunk, -1) ne "\n") {
        my $rest = readline $fh;
        $chunk .= $rest if defined $rest;
    }
    return $chunk;
}


# Return $value encoded.
sub _encoded ($json, $value) {
    my $text;
    try {
        $text = $json->encode($value);
    }
    catch ($e) {
        croakf q(Can't encode a value as JSON: %s), _unplaced($e);
    };    # the ; ends the statement for Perl::Critic, which doesn't know try
    return $text;
}


# Return a sink writing each value, encoded, to the file or filehandle,
# as the format says, giving how many. One document is an array,
# written as the values come: an encoder that indents has its values'
# lines indented in it.
sub _writer ($option, $format, $json) {
    my($path, $given) = @{ $option }{qw(file fh)};
    my $to     = $path // 'the filehandle';
    my $indent = _indents($json);
    my($before, $between, $after)
        = $indent ? ("[\n", ",\n", "\n]\n") : ('[', ',', "]\n");
    return sink_one {
        my $fh = $given;
        unless ($fh) {
            # Open for the run, and closed by its end.
            open $fh, '>:raw', $path    ## no critic (InputOutput::RequireBriefOpen)
                or croakf q(Can't write %s: %s), $path, $!;
        }
        my $n     = 0;
        my $write = sub (@text) {
            print { $fh } @text or croakf q(Can't write %s: %s), $to, $!;
        };
        my $step
            = $format eq 'lines'
            ? sub ($value) { $write->(_encoded($json, $value), "\n"); $n++ }
            : sub ($value) {
                my $text = _encoded($json, $value) =~ s( \n \z )()xr;
                $text =~ s( ^ )(   )xmg if $indent;
                $write->($n++ ? $between : $before, $text);
            };
        return {
            step  => $step,
            flush => sub () {
                $write->($n ? $after : "[]\n") if $format eq 'json';
                return $n;
            },
            end => $path
            ? sub ($how) { close $fh or croakf q(Can't write %s: %s), $path, $! }
            : undef,
        };
    };
}
1;

__END__

=encoding utf8

=for stopwords JSON JSONL NDJSON jsonl fh

=head1 NAME

Ekorn::Pipeline::JSON - read and write JSON and JSON Lines, as sources, stages or sinks

=head1 SYNOPSIS

    use Ekorn::Pipeline::JSON qw(:all);

    # Sources: one document, an array giving its elements; or JSON
    # Lines, a document a line.
    my $next  = Ekorn::Pipeline->new(@stages)->iterator(from_json(file => 'tracks.json'));
    my $lines = Ekorn::Pipeline->new(@stages)->iterator(from_jsonl(file => 'events.jsonl'));

    # Sinks: one array of every value; or a value a line. Each gives how
    # many it wrote.
    my $n = Ekorn::Pipeline->new(@stages, to_json(file => 'out.json'))->(@values);
    my $m = Ekorn::Pipeline->new(@stages, to_jsonl(file => 'out.jsonl'))->(@values);

    # Stages: decoding texts, and encoding values.
    my @rows  = Ekorn::Pipeline->new(from_jsonl())->(@texts);
    my @lines = Ekorn::Pipeline->new(to_jsonl(json => {canonical => 1}))->(@rows);

=head1 DESCRIPTION

Four functions, one for each direction and format, each making a
different part by the options it's given. Given a C<file> or an C<fh>,
a C<from_> function makes a source and a C<to_> function a sink; given
neither, each makes a stage. Each part is made afresh for each run.

The C<json> functions read and write one JSON document; the C<jsonl>
functions JSON Lines, also called NDJSON: a document a line. A stage
passes on what a file of its format would hold, so C<to_json> and
C<from_json> undo each other, as C<to_jsonl> and C<from_jsonl> do.

The encoder is L<JSON::MaybeXS>'s: L<Cpanel::JSON::XS> where it's
installed, L<JSON::PP> otherwise. Text is UTF-8 bytes, as
C<encode_json> and C<decode_json> have it, and files are opened
C<:raw>. A file is opened as the run starts, emptied if it's written,
and closed once the run has ended, however it ended; a filehandle is
left open, for its opener to close.

Nothing is exported by default; ask for each, or for C<:all>, or import
them from L<Ekorn::Pipeline::Tooling>'s C<:json>. L<JSON> exports a
C<from_json> and a C<to_json> of its own by default, so a module using
both needs to import one under another name, or call it by its full
name.

=head1 FUNCTIONS

=head2 from_json

    from_json(file => $path, %options)
    from_json(fh => $fh, %options)
    from_json(%options)

Given a C<file> or an C<fh>, a source of the one document read from
it: its elements, if it's an array, or itself. An empty input gives
none. The input is read whole before the first value is given, and one
holding more than one document croaks, pointing to L</from_jsonl>.

Given neither, a stage decoding each value, one JSON text, the same
way: an array gives its elements, and anything else itself.

=head2 from_jsonl

    from_jsonl(file => $path, %options)
    from_jsonl(fh => $fh, %options)
    from_jsonl(%options)

Given a C<file> or an C<fh>, a source of the documents read from it,
JSON Lines, each as it is: an array is one value. The input is read a
block at a time, as values are pulled, so a stage that stops the run
early stops the reading too. Documents simply written one after
another, on a line or not, are read the same.

Given neither, a stage decoding each value, a text of one or more
lines, into each line's document.

=head2 to_json

    to_json(file => $path, %options)
    to_json(fh => $fh, %options)
    to_json(%options)

Given a C<file> or an C<fh>, a sink writing every value as one JSON
document, an array, written as the values come, and giving how many.
An encoder that indents, such as with C<pretty>, has each value
indented in the array.

Given neither, a stage gathering every value, and passing on one text,
the array, once they've all come.

=head2 to_jsonl

    to_jsonl(file => $path, %options)
    to_jsonl(fh => $fh, %options)
    to_jsonl(%options)

Given a C<file> or an C<fh>, a sink writing each value as a line of
JSON Lines, and giving how many.

Given neither, a stage passing on each value as its line, without its
newline, ready for L<Ekorn::Pipeline::Sinks/to_file>. JSON Lines can't
be indented, so it croaks given an encoder that indents.

=head1 OPTIONS

=over

=item file

The path of a file to read or write.

=item fh

An open filehandle to read or write. It should be C<:raw>, as the text
is bytes, unless the encoder's C<utf8> is off.

=item json

The encoder: a hash reference of options for L<JSON::MaybeXS>'s C<new>,
such as C<< {canonical => 1, pretty => 1} >>, given over the defaults
C<utf8> and C<allow_nonref>; or an object of your own, such as a
L<Cpanel::JSON::XS> or L<JSON::PP> you've set up, used as it is. An
object reading a source, or decoding with L</from_jsonl>'s stage, has
its incremental parser reset for each run, so mustn't serve two at
once.

=back

=head1 DIAGNOSTICS

=over

=item Expected options as name => value pairs

A function was given an odd number of arguments.

=item Expected the options file, fh and json, not %s

A function was given an option it doesn't know, named after "not".

=item Expected file to be a path

C<file> was undefined.

=item Expected a file or a filehandle, not both

A function was given both C<file> and C<fh>.

=item Expected an open filehandle

C<fh> was something other than an open filehandle.

=item Expected json to be a hash reference of options, or an encoder object

C<json> was something else.

=item Expected json options the encoder knows: %s

C<json>'s options included one the encoder doesn't have; the rest of
the message is the encoder's.

=item Expected an encoder that doesn't indent, to write JSON Lines

L</to_jsonl> was given an encoder that indents, such as with
C<pretty>.

=item Can't decode JSON from %s: %s

What was read wasn't JSON: the first part is the file's path, "the
filehandle", or "a value", for a stage, and the second the decoder's
reason. It's "it ends inside a document" if the input ended part way
through one, and "it holds more than one document; read JSON Lines
with from_jsonl" if L</from_json> read more than one.

=item Can't encode a value as JSON: %s

A value couldn't be encoded, such as an object, by default; the second
part is the encoder's reason.

=item Can't read %s: %s

=item Can't write %s: %s

A file couldn't be opened, read, written or closed, or a filehandle
read or written; the second part says why.

=back

=head1 SEE ALSO

L<Ekorn::Pipeline>, L<Ekorn::Pipeline::Sources> and
L<Ekorn::Pipeline::Sinks>, for files of lines, and L<JSON::MaybeXS>.

The user guide's "Walk through a module of parts" builds a smaller
C<from_jsonl> and C<to_jsonl>, step by step.

=head1 AUTHOR

Iain Campbell E<lt>cpanic@cpan.orgE<gt>

=head1 LICENSE

Copyright (c) 2026 by Iain Campbell.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=cut
