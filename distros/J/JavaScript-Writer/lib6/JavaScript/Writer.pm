
class JavaScript::Writer-0.0.1 {
    has $!object;
    has @!statements;

    method call($function, @args) {
        @!statements.push({
            object => $!object,
            call => $function,
            args => @args
        });
        $!object = undef;
    }

    method object($o) {
        $!object = $o;
        return self
    }

    method append($code) {
        @!statements.push({ code => $code })
    }

    method as_string {
        my $ret = "";
        for @!statements -> my %s {
            if (%s{'call'}) {
                if (%s{'object'}) {
                    $ret ~= %s{'object'} ~ ".";
                }
                # Should use JSON to build arglist.
                my $args = %s{'args'}.join(",");
                $ret ~= %s{'call'} ~ "(\"$args\");";
            }
            elsif (%s{'code'}) {
                $ret ~= %s{'code'} ~ ";"
            }
        }
        return $ret;
    }
}

