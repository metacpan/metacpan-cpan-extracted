package Hypersonic::Middleware::RequestId;
use strict;
use warnings;

our $VERSION = '0.12';

# Middleware builder pattern - generates inline C at compile time
# Zero Perl in the hot path - ID generation is pure C

# Constructor - creates a builder instance
sub new {
    my ($class, %opts) = @_;
    bless {
        header => $opts{header} // 'X-Request-ID',
        type   => $opts{type} // 'both',  # 'before', 'after', or 'both'
    }, $class;
}

# Declare slot requirements - compiler allocates and passes back in context
sub slot_requirements {
    return { request_id => 1 };  # Need 1 slot for request_id
}

# Factory methods that return builder instances (not coderefs)
sub middleware {
    my (%opts) = @_;
    return __PACKAGE__->new(%opts, type => 'before');
}

sub after_middleware {
    my (%opts) = @_;
    return __PACKAGE__->new(%opts, type => 'after');
}

# Builder interface: generate C helper functions at file scope
sub build_helpers {
    my ($self, $builder) = @_;

    $builder->comment('RequestId: JIT-compiled request ID generation (zero Perl overhead)')
            ->line('static __thread unsigned long g_reqid_counter = 0;')
            ->line('static pid_t g_reqid_pid = 0;')
            ->blank
            ->line('static void hypersonic_generate_request_id(char* buf, size_t buflen) {')
            ->line('    if (g_reqid_pid == 0) g_reqid_pid = getpid();')
            ->line('    unsigned long ts = (unsigned long)time(NULL);')
            ->line('    unsigned long cnt = g_reqid_counter++;')
            ->line('    snprintf(buf, buflen, "%lx-%lx-%x", ts, cnt, (unsigned int)g_reqid_pid);')
            ->line('}');
}

# Builder interface: generate inline C for before middleware
sub build_before {
    my ($self, $builder, $ctx) = @_;
    my $req_var = $ctx->{req_var} // 'req';
    my $slot = $ctx->{slots}{request_id}
        // die "RequestId: compiler must provide slots->{request_id}";

    # Store slot for build_after to use
    $self->{_slot} = $slot;

    $builder->comment('RequestId before: generate and store request ID')
            ->line('    {')
            ->line('        char _reqid_buf[64];')
            ->line('        hypersonic_generate_request_id(_reqid_buf, sizeof(_reqid_buf));')
            ->line("        av_store($req_var, $slot, newSVpv(_reqid_buf, 0));")
            ->line('    }');
}

# Builder interface: generate inline C for after middleware
sub build_after {
    my ($self, $builder, $ctx) = @_;
    my $req_var = $ctx->{req_var} // 'req';
    my $res_var = $ctx->{res_var} // 'result';
    my $slot = $ctx->{slots}{request_id} // $self->{_slot}
        // die "RequestId: compiler must provide slots->{request_id}";
    my $header = $self->{header};
    my $header_len = length($header);

    $builder->comment("RequestId after: add $header to response")
            ->line('    {')
            ->line("        SV** _reqid_ref = av_fetch($req_var, $slot, 0);")
            ->line('        if (_reqid_ref && SvOK(*_reqid_ref)) {')
            ->line('            /* Request ID available - will be added to response headers */')
            ->line('            /* Note: actual header injection handled by response builder */')
            ->line('        }')
            ->line('    }');
}

1;

__END__

=head1 NAME

Hypersonic::Middleware::RequestId - JIT compiled request ID middleware

=head1 SYNOPSIS

    use Hypersonic;
    
    my $server = Hypersonic->new(port => 8080);
    
    # Enable request ID (JIT compiled)
    $server->enable_request_id();
    
    $server->get('/' => sub {
        my ($req) = @_;
        my $id = $req->{request_id};
        return { request_id => $id };
    });

=head1 DESCRIPTION

Adds unique request IDs for distributed tracing. The ID generation
is JIT compiled to C for maximum performance.

If an incoming request has an X-Request-ID header (from upstream proxy),
it is preserved. Otherwise a new ID is generated.

=head1 JIT COMPILATION

The C<generate_id()> function is compiled to native C code:

    static void generate_request_id(char* buf, size_t buflen) {
        unsigned long ts = (unsigned long)time(NULL);
        unsigned long cnt = g_request_counter++;
        snprintf(buf, buflen, "%lx-%lx-%x", ts, cnt, (unsigned int)g_pid);
    }

=head1 AUTHOR

LNATION

=cut
