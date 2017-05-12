package Lang::Tree::Builder::Tokenizer;

sub new {
    my ($class, $file) = @_;
    my $fh = new FileHandle($file);
    return undef unless $fh;
    bless {
        file => $file,
        lineno => 0,
        error => '',
        line => '',
        fh => $fh,
    }, $class;
}

sub next {
    my ($self) = @_;
    my $token = $self->_next();
    $self->{last_token} = $token;
    return $token;
}

sub _next {
    my ($self) = @_;

    return undef unless defined $self->{line};

    while ($self->{line} =~ /^\s*$/) {
        $self->{line} = $self->{fh}->getline();
        $self->{lineno}++;
        return undef unless defined $self->{line};
        $self->{line} =~ s/^\s+//;
        $self->{line} =~ s/#.*//;
    }

    for ($self->{line}) {
        s/^\(\s*// && return '(';
        s/^\)\s*// && return ')';
        s/^\,\s*// && return ',';
        s/([A-Za-z_][A-Za-z_0-9]*(?:::[A-Za-z_][A-Za-z_0-9]*)*)\s*//
            && return $1;
    }

    $self->{error} = "can't parse: '$self->{line}'"
                   . " in $self->{file}"
                   . " at line $self->{lineno}";
    return undef;
}

sub info {
    my ($self) = @_;
    return "file: $self->{file}"
           . " line: $self->{lineno}"
           . " $self->{lasttoken} <> $self->{line}";
}

1;
