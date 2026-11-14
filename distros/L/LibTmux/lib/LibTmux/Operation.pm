package LibTmux::Operation;
use v5.44;
use Scalar::Util qw(blessed);
use LibTmux::X;

sub _copy_request ($request) {
    my %copy = %$request;
    $copy{argv} = [($request->{argv} // [])->@*];
    $copy{env}  = {%{$request->{env}}} if exists $request->{env};
    return \%copy;
}

sub request ($class, %request) {
    LibTmux::X::InvalidArgument->throw(
        message => 'prepared request needs a nonempty argv')
        unless ref($request{argv}) eq 'ARRAY' && $request{argv}->@*;
    for my $arg ($request{argv}->@*) {
        LibTmux::X::InvalidArgument->throw(
            message => 'prepared arguments must be defined NUL-free scalars')
            if !defined($arg) || ref($arg) || index($arg, "\0") >= 0;
    }
    return bless {tag => 'request', request => _copy_request(\%request)},
        $class;
}
sub value ($class, $value) { bless {tag => 'value', value => $value}, $class }

sub then ($self, $callback) {
    LibTmux::X::InvalidArgument->throw(message => 'then needs a coderef')
        unless ref($callback) eq 'CODE';
    bless {tag => 'then', previous => $self, callback => $callback}, ref $self;
}

sub catch ($self, $callback) {
    LibTmux::X::InvalidArgument->throw(message => 'catch needs a coderef')
        unless ref($callback) eq 'CODE';
    bless {tag => 'catch', previous => $self, callback => $callback}, ref $self;
}

sub sequence ($class, $operations) {
    my $op = $class->value([]);
    for my $next (@$operations) {
        $op = $op->then(
            sub ($values) {
                $next->then(sub ($value) { [@$values, $value] });
            }
        );
    }
    return $op;
}

sub run ($self, $executor, $done, $fail) {
    my $state   = {cancelled => false, finished => false, hook => undef};
    my $success = sub ($value) {
        return if $state->{cancelled} || $state->{finished};
        $state->{finished} = true;
        $state->{hook}     = undef;
        $done->($value);
    };
    my $failure = sub ($error) {
        return if $state->{cancelled} || $state->{finished};
        $state->{finished} = true;
        $state->{hook}     = undef;
        $fail->($error);
    };
    _drive($self, $executor, $success, $failure, $state);
    return sub {
        return if $state->{finished} || $state->{cancelled};
        $state->{cancelled} = true;
        my $hook = delete $state->{hook};
        $hook->() if $hook;
    };
}

sub _drive ($op, $executor, $done, $fail, $state) {
    return if $state->{cancelled};
    if ($op->{tag} eq 'value') { $done->($op->{value}); return }
    if ($op->{tag} eq 'request') {
        my $settled = false;
        my $success = sub ($value) {
            return if $state->{cancelled} || $settled;
            $settled = true;
            $state->{hook} = undef;
            $done->($value);
        };
        my $failure = sub ($error) {
            return if $state->{cancelled} || $settled;
            $settled = true;
            $state->{hook} = undef;
            $fail->($error);
        };
        try {
            my $hook =
                $executor->(_copy_request($op->{request}), $success, $failure);
            $state->{hook} = $hook unless $settled || $state->{cancelled};
        }
        catch ($error) { $failure->($error) }
        return;
    }
    my $transform = sub ($value) {
        return if $state->{cancelled};
        try {
            my $next = $op->{callback}->($value);
            if (blessed($next) && $next->isa(__PACKAGE__)) {
                _drive($next, $executor, $done, $fail, $state);
            }
            else { $done->($next) }
        }
        catch ($error) { $fail->($error) }
    };
    if ($op->{tag} eq 'then') {
        _drive($op->{previous}, $executor, $transform, $fail, $state);
    }
    else { _drive($op->{previous}, $executor, $done, $transform, $state) }
}

=head1 NAME

LibTmux::Operation - Executor-independent prepared command continuations

=head1 METHODS

=head2 request

C<request(argv =E<gt> [...], stdin =E<gt> $octets, ...)> owns its input
arguments. Execution is explicit through L</run>; preparation performs no I/O.

=head2 value

Wrap one local value, including undef for a documented void operation.

=head2 then

Compose a local transformation returning one value or another Operation.
Exceptions retain their original identity.

=head2 catch

Recover a failure with one value or another Operation.

=head2 sequence

Execute an array of Operations in order, returning one arrayref of results.

=head2 run

C<run($executor, $on_done, $on_fail)> supplies requests and two one-argument
completion callbacks to the executor. The executor returns a cancellation
hook. C<run> returns a cancellation coderef suppressing further submissions.
Each request settles once; the complete operation yields one value or error.

The synchronous L<LibTmux::Server> and optional async distribution use the
same preparation, codecs, and graph semantics. Core has no Future dependency.

=cut
