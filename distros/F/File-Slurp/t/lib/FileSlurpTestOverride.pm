package FileSlurpTestOverride;

use Exporter qw(import);

# older EUMMs turn this on. We don't want to emit warnings.
# also, some of our CORE function overrides emit warnings. Silence those.
local $^W;

BEGIN {
    *CORE::GLOBAL::rename = sub($$) { my ($o, $n) = @_; CORE::rename($o, $n) };
    # we only use the 4-arg version of syswrite
    *CORE::GLOBAL::syswrite = sub($$;$$) { my ($h, $buff, $l, $o) = @_; return CORE::syswrite($h, $buff, $l, $o); };
    # We use the 3 and 4-arg form of sysread.
    *CORE::GLOBAL::sysread = sub($$$;$) { my( $h, $b, $s, $o ) = @_; CORE::sysread $h, $b, $s, $o };
            # sub($$$;$) { my( $h, $b, $s, $o ) = @_; CORE::sysread $h, $b, $s, $o } ;
    # We use the 3 and 4-arg form of sysopen
    *CORE::GLOBAL::sysopen = sub($$$;$) { my( $h, $n, $m, $p ) = @_; CORE::sysopen $h, $n, $m, $p };
    # sub(*$$;$) {
    #     my ($h, $n, $m, $p) = @_;
    #     return CORE::sysopen($h, $n, $m, $p) if defined $p;
    #     CORE::sysopen($h, $n, $m);
    # };
}


our @EXPORT_OK = qw(
    trap_function_override_core
);

sub trap_function_override_core {
    my ($core, $function, @args) = @_;

    my $res;
    my $warn;
    my $err = do { # catch
        no strict 'refs';
        no warnings;
        local $^W;
        local $@;
        local $SIG{__WARN__} = sub {$warn = join '', @_};
        local *{"CORE::GLOBAL::$core"} = sub {};
        eval { # try
            $res = $function->(@args);
            1;
        };
        $@;
    };

    return ($res, $warn, $err);
}

1;
