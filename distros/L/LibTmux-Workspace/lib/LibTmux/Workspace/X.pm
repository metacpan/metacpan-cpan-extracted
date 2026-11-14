package LibTmux::Workspace::X;
use v5.44;
use LibTmux::X;
use MIME::Base64 qw(encode_base64);

sub _error_data ($error, $seen = {}) {
    my $data = {class => ref($error) || undef, message => "$error"};
    return $data unless blessed($error) && $error->isa('LibTmux::X');
    $data->{message} = $error->message;
    if ($seen->{refaddr($error)}++) {
        $data->{cycle} = true;
        return $data;
    }
    $data->{dispatched} = $error->dispatched;
    $data->{path}       = $error->path if defined $error->path;
    my $result = $error->result;
    if (blessed($result) && $result->isa('LibTmux::CommandResult')) {
        $data->{result} = {
            exit_code     => $result->exit_code,
            signal        => $result->signal,
            raw_status    => $result->raw_status,
            stdout_base64 => encode_base64($result->stdout // '', ''),
            stderr_base64 => encode_base64($result->stderr // '', ''),
        };
    }
    if (   $error->isa('LibTmux::X::Creation')
        || $error->isa('LibTmux::Workspace::X::Load'))
    {
        $data->{cause} = _error_data($error->cause, $seen)
            if defined $error->cause;
    }
    return $data;
}

package LibTmux::Workspace::X::Config { use parent -norequire, 'LibTmux::X' }

package LibTmux::Workspace::X::Conflict { use parent -norequire, 'LibTmux::X' }

package LibTmux::Workspace::X::Load {
    use parent -norequire, 'LibTmux::X';
    sub report ($self) { $self->{report} }
    sub cause  ($self) { $self->{cause} }

    sub report_data ($self) {
        my $report = $self->report;
        return {
            %$report,
            (map { $_ => [$report->{$_}->@*] } qw(created skipped steps)),
            cause          => LibTmux::Workspace::X::_error_data($self->cause),
            cleanup_errors => [
                map {
                    +{
                        %$_,
                        error => LibTmux::Workspace::X::_error_data($_->{error})
                    }
                } $report->{cleanup_errors}->@*
            ],
        };
    }
}

=head1 NAME

LibTmux::Workspace::X - Workspace configuration and partial-load failures

=head1 EXCEPTIONS

=head2 Config

Invalid versioned configuration. C<path> identifies the rejected input.

=head2 Conflict

An existing session conflicts with the selected repeat-application policy.
No session is created until all names pass the conflict check.

=head2 Load

C<cause> retains the original exception. C<report> records completed steps,
the failed step, dispatch uncertainty, and typed cleanup outcomes. Rollback affects
only sessions whose creation was proven by returned core handles.
See L<LibTmux::Workspace/load> and L<LibTmux::X>.

=head1 METHODS

=head2 report

For Load exceptions, return the partial-load report. It contains created IDs,
completed and failed steps, dispatch uncertainty, and cleanup failures.
Each C<cleanup_errors> entry contains C<target> (the captured
L<identity|LibTmux::Entity/identity>), C<action> (C<kill_session>), and C<error>
(the original exception). Entries follow rollback attempt order, reversing
creation order. An empty array means no cleanup failure was observed.
The primary L</cause> and secondary exception objects retain their identity.
Inspect their L<dispatched|LibTmux::X/dispatched> and
L<result|LibTmux::X/result> fields without parsing prose. No I/O occurs.

=head2 report_data

For Load exceptions, return a detached, JSON-safe report hashref. The primary
cause and each cleanup error become records with C<class>, C<message>, known
C<path>, and C<dispatched> (null means unknown). Core creation/load causes
retain their cause chain; a repeated exception is marked C<cycle>.
Process results retain exit code, signal, raw wait status, and bounded stdout
and stderr as C<stdout_base64> and C<stderr_base64> using L<MIME::Base64>.
This diagnostic encoding does not serialize entity graphs or arbitrary
exception internals. Other exceptions retain their class and string message.
No I/O occurs; editing the export cannot change L</report> or L</cause>.

    use JSON::PP ();
    my $data = $error->report_data;
    say JSON::PP->new->canonical->encode($data);

The packaged C<libtmux-workspace> CLI uses this export. Use L</report> when
recovery needs the original typed exceptions rather than diagnostic data.

=head2 cause

For Load exceptions, return the original core or orchestration failure object.

=cut
