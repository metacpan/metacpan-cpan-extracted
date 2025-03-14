package Klonk::Env 0.01;
use Klonk::pragma;
use Unicode::UTF8 qw(decode_utf8);

use constant {
    MAX_FORM_BODY_SIZE => 10 * 1024 * 1024,
};

fun _parse_query($query_string) {
    my %param;
    for my $kv (split /&/, $query_string) {
        my ($k, $v) = split /=/, $kv, 2;
        for ($k, $v) {
            defined or next;
            tr/+/ /;
            s/%([[:xdigit:]]{2})/chr hex $1/eg;
            $_ = decode_utf8 $_;
        }
        $param{$k} = $v;
    }
    \%param
}

method new($class: $env) {
    my $qparam = _parse_query $env->{QUERY_STRING};

    my $bparam = {};
    {
        my $verb = $env->{REQUEST_METHOD};
        if ($verb eq 'POST' || $verb eq 'PUT' || $verb eq 'PATCH') {
            my $ctype = $env->{CONTENT_TYPE} // '';
            my $clength = $env->{CONTENT_LENGTH} // 0;
            $clength <= MAX_FORM_BODY_SIZE
                or die "Request size ($clength) exceeds maximum form size";
            if ($ctype eq 'application/x-www-form-urlencoded') {
                my $input = $env->{'psgi.input'};
                my $query = '';
                while ((my $d = $clength - length($query)) > 0) {
                    my $n = $input->read($query, $d, length($query))
                        and next;
                    defined $n
                        and die "Premature end of request body (received ${\length $query} of $clength bytes)";
                    die "Error while reading request body: $!";
                }
                $bparam = _parse_query $query;
            }
        }
    }

    bless {
        %$env,
        'klonk.qparam' => $qparam,
        'klonk.bparam' => $bparam,
    }, $class
}

method DESTROY(@) {}

method vpath($path) {
    $self->{SCRIPT_NAME} . '/' . $path =~ s!^/!!r
}

method qparam($k) {
    $self->{'klonk.qparam'}{$k}
}

method bparam($k) {
    $self->{'klonk.bparam'}{$k}
}

1
__END__

=head1 NAME

Klonk::Env - HTTP request environment

=head1 SYNOPSIS

    use Klonk::Env;
    my $env = Klonk::Env->new($psgi_env);
    my $verb = $env->{REQUEST_METHOD};
    my $q = $env->qparam('q');
    my $name = $env->bparam('name');
    my $path_to_foo = $env->vpath('/foo');

=head1 DESCRIPTION

This class extends a L<PSGI environment|PSGI/The Environment> with some helper
methods. All PSGI environment keys are still present and can be accessed by
treating the object as a hash.

=head2 Constructor

=over

=item C<< Klonk::Env->new($psgi_env) >>

Builds an object from a PSGI environment hash reference.

=back

=head2 Methods

=over

=item C<< $env->qparam($key) >>

Returns the value of the C<$key> query ("GET") parameter in the request
represented by C<$env> or C<undef> if there is no such parameter. If there are
multiple parameters named C<$key>, the last one wins. Strings are automatically
decoded from UTF-8.

=item C<< $env->bparam($key) >>

Returns the value of the C<$key> body ("POST") parameter in the request
represented by C<$env> or C<undef> if there is no such parameter. If there are
multiple parameters named C<$key>, the last one wins. Strings are automatically
decoded from UTF-8.

Currently, only C<application/x-www-form-urlencoded> bodies are supported and
their size is limited to S<10 MiB>.

=item C<< $env->vpath($path) >>

Translates from app-internal to external resource paths. That is, if you have a
resource at the (internal) path C</foo>, but your whole web application is
mounted at C</some/app>, then links to that resource that you hand out to
clients need to prepend the application path in order to resolve. C<vpath>
handles this translation:

    my $external_path = $env->vpath('/foo');
    # returns "/some/app/foo"

=back
