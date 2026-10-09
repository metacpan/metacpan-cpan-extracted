package MockAuthMilter;
# A stand-in for the parts of Mail::Milter::Authentication that the DKIM2Sign
# and DKIM2Verify handlers use, so t/milter.t and t/milter-sign-gate.t can
# drive the handlers' callbacks without the real milter installed.  Load it
# (use MockAuthMilter) before the handler modules.
use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(run_sign);

BEGIN {
    # Stub Pragmas (just enables strict/warnings, imports LOG_* constants)
    $INC{'Mail/Milter/Authentication/Pragmas.pm'} = 1;
    package Mail::Milter::Authentication::Pragmas;
    sub import {
        my $caller = caller;
        no strict 'refs';
        *{"${caller}::LOG_DEBUG"} = sub { 'debug' };
        *{"${caller}::LOG_INFO"}  = sub { 'info' };
        *{"${caller}::LOG_ERR"}   = sub { 'err' };
    }

    # Stub base handler
    $INC{'Mail/Milter/Authentication/Handler.pm'} = 1;
    package Mail::Milter::Authentication::Handler;
    sub new {
        my ($class, %args) = @_;
        return bless {
            _config  => $args{config} || {},
            _objects => {},
            _auth_headers => [],
            _pre_headers  => [],
            _prepended    => [],
            _log => [],
            _metrics => {},
        }, $class;
    }
    sub handler_config     { return $_[0]->{_config} }
    sub is_authenticated   { return $_[0]->{_config}{_authenticated} || 0 }
    sub is_local_ip_address { return $_[0]->{_config}{_local} || 0 }
    sub set_object         { $_[0]->{_objects}{$_[1]} = $_[2] }
    sub get_object         { return $_[0]->{_objects}{$_[1]} }
    sub destroy_object     { delete $_[0]->{_objects}{$_[1]} }
    sub check_timeout      { }
    sub handle_exception   { }
    sub dbgout             { push @{$_[0]->{_log}}, [@_[1..$#_]] }
    sub log_error          { push @{$_[0]->{_log}}, ['ERROR', $_[1]] }
    sub metric_count       { $_[0]->{_metrics}{$_[1]} = ($_[0]->{_metrics}{$_[1]} || 0) + 1 }
    sub add_auth_header    { push @{$_[0]->{_auth_headers}}, $_[1] }
    sub prepend_header     { push @{$_[0]->{_prepended}}, { field => $_[1], value => $_[2] } }
    # The framework's header-change call (SMFIR_CHGHEADER: an empty value
    # deletes the index'th field of that name), recorded in call order.
    sub change_header      { push @{$_[0]->{_changed_headers}}, { field => $_[1], index => $_[2], value => $_[3] } }

    # Stub AuthenticationResults classes
    $INC{'Mail/AuthenticationResults/Header/Entry.pm'} = 1;
    package Mail::AuthenticationResults::Header::Entry;
    sub new       { bless {key => '', value => '', children => []}, shift }
    sub set_key   { $_[0]->{key} = $_[1]; $_[0] }
    sub safe_set_value { $_[0]->{value} = $_[1]; $_[0] }
    sub add_child { push @{$_[0]->{children}}, $_[1]; $_[0] }

    $INC{'Mail/AuthenticationResults/Header/Comment.pm'} = 1;
    package Mail::AuthenticationResults::Header::Comment;
    sub new            { bless {value => ''}, shift }
    sub safe_set_value { $_[0]->{value} = $_[1]; $_[0] }

    $INC{'Mail/AuthenticationResults/Header/SubEntry.pm'} = 1;
    package Mail::AuthenticationResults::Header::SubEntry;
    sub new            { bless {key => '', value => ''}, shift }
    sub set_key        { $_[0]->{key} = $_[1]; $_[0] }
    sub safe_set_value { $_[0]->{value} = $_[1]; $_[0] }
}

package MockAuthMilter;
use Mail::Milter::Authentication::Handler::DKIM2Sign;
use DKIM2TestKeys;

# Helper: feed a raw message through milter sign callbacks
sub run_sign {
    my ($raw, %opts) = @_;
    my $env_from = exists $opts{env_from} ? delete $opts{env_from} : '<sender@test1.dkim2.com>';
    my $env_rcpt = exists $opts{env_rcpt} ? delete $opts{env_rcpt} : '<recipient@test2.dkim2.com>';
    my $config = {
        domains => {},
        sign_authenticated => 1,
        sign_local => 1,
        add_message_instance => 1,
        record_smtp_params => 1,
        snapshot_directory => undef,
        _authenticated => 1,
        # Pin t= so the fixtures written to tests/expected/ are identical on
        # every run; otherwise a live timestamp dirties the working tree each
        # time the suite is run.
        signature_timestamp => 1740000000,
        # The gate verifies any upstream chain: keys from the test dns.json,
        # and the pinned upstream t= (above) is long past its 14 days.
        dns_overrides        => DKIM2TestKeys::dns_json(),
        skip_timestamp_check => 1,
        %opts,
    };

    my $handler = Mail::Milter::Authentication::Handler::DKIM2Sign->new(
        config => $config,
    );

    $raw =~ s/\r//gs;
    $raw =~ s/\n/\r\n/gs;

    my ($header_block, $body) = split /\r\n\r\n/, $raw, 2;
    my @header_lines;
    my $current = '';
    for my $line (split /\r\n/, $header_block) {
        if ($line =~ /^\s/ && $current ne '') {
            $current .= "\r\n$line";
        } else {
            push @header_lines, $current if $current ne '';
            $current = $line;
        }
    }
    push @header_lines, $current if $current ne '';

    $handler->envfrom_callback($env_from);
    $handler->envrcpt_callback($env_rcpt);

    for my $hline (@header_lines) {
        my ($name, $value) = $hline =~ /^([^\s:]+)\s*:\s*(.*)/s;
        $handler->header_callback($name, $value, $hline);
    }

    $handler->eoh_callback();

    if (defined $body) {
        my @chunks = ($body =~ /(.{1,256})/gs);
        for my $chunk (@chunks) {
            $handler->body_callback($chunk);
        }
    }

    $handler->eom_callback();

    # Simulate addheader phase
    my $mock_handler = {
        pre_headers    => [],
        add_headers    => [],
        remove_headers => [],
    };
    $handler->addheader_callback($mock_handler);

    return ($handler, $mock_handler);
}

1;
