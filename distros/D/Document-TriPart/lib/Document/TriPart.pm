package Document::TriPart;
BEGIN {
  $Document::TriPart::VERSION = '0.024';
}
# ABSTRACT: Read, write & edit a tri-part document (preamble, YAML::Tiny header, and body)


use warnings;
use strict;


use Any::Moose;

use File::AtomicWrite;
use File::Temp qw/tempfile/;
use IO::Scalar;
use Carp::Clan;
use Path::Class();
use YAML::Tiny();

our $TriPart = 1;

has file => qw/is rw/;
has atomic => qw/is rw/, default => 1;

has separator => qw/is rw required 1 isa Str/, default => '---';

has _preamble_content => qw/is rw isa Maybe[ScalarRef]/;
sub preamble_as_string {
    my $self = shift;
    return undef unless $self->_preamble_content;
    return ${ $self->_preamble_content };
}

has _header_content => qw/is rw isa Maybe[ScalarRef]/;
sub header_as_string {
    my $self = shift;
    return undef unless $self->_header_content;
    return ${ $self->_header_content };
}

has _body_content => qw/is rw isa Maybe[ScalarRef]/;
sub body_as_string {
    my $self = shift;
    return undef unless $self->_body_content;
    return ${ $self->_body_content };
}

has _header => qw/is ro lazy_build 1 isa Maybe[HashRef]/;
sub _build__header {
    my $self = shift;
    return {} unless defined $self->_header_content;
    return $self->_parse_header($self->_header_content);
}

sub preamble {
    my $self = shift;
    if (@_) {
        my $value = shift;
        if (defined $value) {
            $value = $$value if ref $value eq "SCALAR";
            $value = \"$value";
        }
        $self->_preamble_content($value);
    }
    return undef unless defined $self->_preamble_content;
    return ${ $self->_preamble_content };
}

sub header {
    my $self = shift;
    if (@_) {
        my $value = shift;
        if (defined $value) {
            $value = $$value if ref $value eq "SCALAR";
            $value = $self->_format_header($value) if ref $value eq "HASH";
            $value = \"$value";
        }
        $self->_header_content($value);
        $self->_clear_header;
    }
    return $self->_header;
}

sub body {
    my $self = shift;
    if (@_) {
        my $value = shift;
        $value = "" unless defined $value;
        $value = $$value if ref $value eq "SCALAR";
        $value = \"$value";
        $self->_body_content( $value );
    }
    return "" unless defined $self->_body_content;
    return ${ $self->_body_content };
}

sub write {
    my $self = shift;
    my $file;
    $file = shift if @_ % 2;
    my %given = @_;
    $file = $given{file} unless defined $file;
    $file = $self->file unless defined $file;
    return $self->write_file( $file, @_ ) if defined $file;
    croak "Can't write without having a file to write to";
}

sub write_file {
    my $self = shift;
    my $file;
    $file = shift if @_ % 2;
    my %given = @_;
    $file = $given{file} unless defined $file;

    croak "Wasn't given file to write to" unless defined $file && length $file;

    $file = Path::Class::File->new( "$file" );
    $file->parent->mkpath unless -d $file->parent; # TODO Should we automatically make?

    my $content = \$self->write_string( @_ );
    if (my $atomic = $self->atomic) {
        my %atomic;
        %atomic = %$atomic if ref $atomic eq 'HASH';
        File::AtomicWrite->write_file({
            file => $file.'',
            input => $content,
            %atomic,
        });
    }
    else {
        $file->openw->print( $$content ) or croak "Unable to write to $file since; $!";
    }
    
#    my $handle = IO::AtomicFile->open("$file", 'w') or croak "Unable to write to $file since: $!";
#    $handle->print( $self->write_string( @_ ) );
#    $handle->close or die "Couldn't atomically write $file since: $!";

}

sub write_string {
    my $self = shift;
    my %given = @_;

    return $self->body || '' if $given{body_only};

    my @part = map { chomp; $_ } grep { defined }
        $self->preamble,
        $self->_format_header($self->_header),
    ;

    my $separator = $self->separator;

    return join "\n$separator\n", @part, ( $self->body || '' );
}

# TODO ($header, $body) = ->parse( \ ... )
sub read_string {
    return shift->read(\shift());
}

sub read {
    my $self = shift;
    return $self->new->read( @_ ) unless blessed $self;
    my $file;
    $file = shift if @_ % 2;
    my %given = @_;
    $file = $given{file} unless defined $file;
    $file = $self->file unless defined $file;
    return $self->read_file( $file, @_ ) if defined $file;
    croak "Can't read without having a file to read from";
}

sub read_file {
    my $self = shift;
    return $self->new->read_file( @_ ) unless blessed $self;
    my $file;
    $file = shift if @_ % 2;
    my %given = @_;
    $file = $given{file} unless defined $file;

    my $read = $file;

    croak "Wasn't given something to read" unless defined $read;

    if (ref $read eq "SCALAR") {
        $read = IO::Scalar->new($read);
    }
    elsif (UNIVERSAL::isa($read => 'IO::Handle')) {
    }
    elsif (ref $read eq "GLOB") {
        my $io = IO::Handle->new;
        $io->fdopen( fileno($read), "r" );
        $read = $io;
    }
    else {
        $read = Path::Class::File->new( "$read" )->openr;
    }

    # croak "Don't know how to read $read" unless UNIVERSAL::isa($read => 'IO::Handle');

    if ( $given{body_only} ) {
        $self->{_body_content} = $self->_read( $read );
    }
    else {
        my @part;
	my $part_limit = $TriPart ? 2 : 1;
        while (1) {
            my ($more, $content);
            if ( $part_limit > @part ) {
                ($more, $content) = $self->_read_until_separator( $read );
            }
            else {
                $content = $self->_read( $read );
            }
                
            push @part, $content;
            last unless $more;
        }

        my $body = pop @part;
        my $header = pop @part;

        my $preamble = pop @part;

        $self->_clear_header;

        $self->{_body_content} = $body;
        $self->{_header_content} = $header;
        $self->{_preamble_content} = $preamble;
    }

    return $self;
}

sub _read_until_separator {
    my $self = shift;
    my $handle = shift;
    my $separator = shift;

    my $content;
    $separator = $self->separator;
    my $match = qr/^$separator\s*$/;
    my $got_separator;
    while (<$handle>) {
        last if $got_separator = $_ =~ $match;
        $content .= $_;
    }
    return ($got_separator => \$content);
}

sub _read {
    my $self = shift;
    my $handle = shift;

    local $/ = undef;
    my $content;
    $content = <$handle>;
    return \$content;
}

sub _parse_header {
    my $self = shift;
    my $content = shift;

    # TODO Parsing of: { "a": "1" } does not work
    chomp $$content if defined $$content && $$content =~ m/^\s*\{/;

    return {} unless my $header = YAML::Tiny->read_string($$content);
    return $header->[0];
}

sub _format_header {
    my $self = shift;
    my $header = shift;

    return undef unless defined $header;

    croak "Header given is not a hash ($header)" unless ref $header eq 'HASH';

    my $string = YAML::Tiny::Dump($header);
    $string =~ s/^---\s*//;
    return $string;
}

sub _editor {
	return [ split m/\s+/, ($ENV{VISUAL} || $ENV{EDITOR}) ];
}

sub _edit_file {
	my $file = shift;
	die "Don't know what editor" unless my $editor = _editor;
	my $rc = system @$editor, $file;
	unless ($rc == 0) {
		my ($exit_value, $signal, $core_dump);
		$exit_value = $? >> 8;
		$signal = $? & 127;
		$core_dump = $? & 128;
		die "Error during edit (@$editor): exit value ($exit_value), signal ($signal), core_dump($core_dump): $!";
	}
}

sub edit {
    my $self = shift;

    my $file;
    $file = shift if @_ % 2;
    my %given = @_;
    $file = $given{file} unless defined $file;
    $file = $self->file unless defined $file || $given{tmp};

    my ($tmp_fh, $tmp_filename);
    unless (defined $file) {
        ($tmp_fh, $tmp_filename) = tempfile;
        $file = $tmp_filename;

        # Only write out the file first if we're using a temporary file
        $self->write( $file, @_ );
    }

    _edit_file $file;

    $self->read( $file, @_ );
}

1;

__END__
=pod

=head1 NAME

Document::TriPart - Read, write & edit a tri-part document (preamble, YAML::Tiny header, and body)

=head1 VERSION

version 0.024

=head1 SYNOPSIS

    my $document;
    $document = Document::TriPart::->read( \<<_END_ ); # Or you can use ->read_string( ... )
    # vim: #
    ---
    hello: world
    ---
    This is the body
    _END_

    $document->preamble   "# vim: #\n"
    $document->header     { hello => world }
    $document->body       "This is the body\n"

=head1 DESCRIPTION

This distribution is meant to take the headache out of reading, writing, and editing
"interesting" documents. That is, documents with both content and meta-data (via YAML::Tiny)

More documentation coming soon, check out the code and tests for usage and examples. This is pretty beta, so
the interface might change.

=head1 AUTHOR

Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

