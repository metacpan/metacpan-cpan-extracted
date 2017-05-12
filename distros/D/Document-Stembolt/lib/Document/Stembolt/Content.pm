package Document::Stembolt::Content;

use Moose;

use IO::Scalar;
use IO::AtomicFile;
use Carp;
use Path::Class();
use YAML::Tiny();

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
        my $value;
        $value = "" unless defined $value;
        $value = $$value if ref $value eq "SCALAR";
        $value = \"$value";
        $self->_body_content($value);
    }
    return "" unless defined $self->_body_content;
    return ${ $self->_body_content };
}

sub read_string {
    return shift->read(\shift());
}

sub read {
    my $self = shift;
    return $self->new->read(@_) unless blessed $self;
    my $read = shift;

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
        $read = Path::Class::file("$read")->openr;
    }

#    croak "Don't know how to read $read" unless UNIVERSAL::isa($read => 'IO::Handle');

    my @part;
    while (1) {
        my ($more, $content);
        if (2 > @part) {
            ($more, $content) = $self->_read_until_separator($read, qr/^-{3}\s*$/);
        }
        else {
            $content = $self->_read($read);
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

    return $self;
}

sub write {
    my $self = shift;
    my $file = shift;

    croak "Wasn't given file to write to" unless defined $file && length $file;

    $file = Path::Class::file($file);
    $file->parent->mkpath unless -d $file->parent;

    my $handle = IO::AtomicFile->open("$file", 'w') or croak "Unable to write to $file since: $!";
    $handle->print($self->write_string);
    $handle->close or die "Couldn't atomically write $file since: $!";
}

sub write_string {
    my $self = shift;

    my @part = map { chomp; $_ } grep { defined }
        $self->preamble,
        $self->_format_header($self->_header),
    ;

    my $separator = $self->separator;

    return join "\n$separator\n", @part, $self->body;
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

    return YAML::Tiny->read_string($$content)->[0];
}

sub _format_header {
    my $self = shift;
    my $header = shift;

    return undef unless defined $header;

    my $string = YAML::Tiny::Dump($header);
    $string =~ s/^---\s*//;
    return $string;
}

1;
