# Internal module used by FU.pm
package FU::DebugImpl 0.3;
use v5.36;
use experimental 'for_list';
use FU;
use FU::XMLWriter ':html5_', 'fragment', 'xml_escape';
use Time::HiRes 'time';
use POSIX 'strftime';

sub fmtts { strftime '%Y-%m-%d %H:%M:%S UTC', gmtime shift }

sub loc_($loc) {
    txt_ '[internal]' if !@$loc;
    for (0..$#$loc) {
        br_ if $_;
        my $l = $loc->[$_];
        my $f = $_ == $#$loc ? '(main)' : $loc->[$_+1][3];
        txt_ "$l->[1]:$l->[2] $f";
    }
}

sub fmtpre_($code) {
    lit_ xml_escape($code) =~ s/^\s+//r =~ s/\s+$//r =~ s/\n/<br>/rg;
}

sub clean_re($str) {
    # Regex formatting isn't stable, but this cleans up the crap I'm seeing a little bit.
    "$str" =~ s/^\(\?\^u:\^\(\?\^u://r =~ s/\)\$\)$//r;
}

my @tabs = (
    req => sub {
        table_ sub {
            tr_ sub { td_ 'Method'; td_ fu->method };
            tr_ sub { td_ 'Path'; td_ fu->path };
            tr_ sub { td_ 'Query'; td_ fu->query };
            tr_ sub { td_ 'Client IP'; td_ fu->ip };
            tr_ sub { td_ 'Received'; td_ fmtts $FU::REQ->{trace_start} };
        };
        h2_ 'Headers';
        table_ sub {
            tr_ sub {
                td_ $_;
                td_ fu->headers->{$_};
            } for sort keys fu->headers->%*;
        };
        # TODO: Body? Certainly useful for JSON
        ('Request')
    },

    res => sub {
        my $r = $FU::REQ;
        return () if !exists $r->{trace_end};
        table_ sub {
            tr_ sub { td_ 'Status'; td_ $r->{status} };
            tr_ sub {
                td_ 'Handler';
                td_ $r->{trace_han} ? sub {
                    txt_ clean_re $r->{trace_han}[0];
                    br_;
                    loc_ $r->{trace_han}[1];
                } : 'N/A';
            };
            my $exn = $r->{trace_exn};
            tr_ sub {
                td_ 'Exception';
                td_ !defined $exn ? 'N/A' : ref $exn eq 'FU::err' ? sub {
                    txt_ $exn->[0];
                    txt_ " $exn->[1]" if $exn->[1] ne $exn->[0];
                    br_;
                    loc_ $exn->[2];
                } : $exn;
            };
            tr_ sub { td_ 'Timing'; td_ sprintf '%.1f ms', ($r->{trace_end}-$r->{trace_start})*1000 };
        };
        h2_ 'Headers';
        table_ sub {
            tr_ sub {
                td_ $_;
                td_ $r->{reshdr}{$_};
            } for sort keys $r->{reshdr}->%*;
        };
        ('Response')
    },

    sql => sub {
        return () if !$FU::REQ->{trace_sql};
        table_ sub {
            thead_ sub { tr_ sub {
                td_ class => 'num', 'Exec';
                td_ class => 'num', 'Prep';
                td_ class => 'num', 'Rows';
                td_ 'Query';
            } };
            tr_ sub {
                td_ class => 'num', sprintf '%.1f ms', $_->{exec_time}*1000;
                td_ class => 'num', !defined $_->{prepare_time} ? '-' : $_->{prepare_time} ? sprintf '%.1f ms', $_->{prepare_time}*1000 : 'cache';
                td_ class => 'num', $_->{nrows};
                td_ class => 'code', sub { fmtpre_ $_->{query} };
                # TODO: Params, both separate and interpolated
            } for $FU::REQ->{trace_sql}->@*;
        };
        ('Queries', scalar $FU::REQ->{trace_sql}->@*)
    },

    fu => sub {
        return () if !keys fu->%*;
        # TODO: Contents of the 'fu' object
        ('fu obj')
    },

    proc => sub {
        table_ sub {
            tr_ sub { td_ 'PID'; td_ $$ };
            tr_ sub { td_ 'NAME'; td_ $0 };
            tr_ sub { td_ 'ARGV'; td_ join ' ', @ARGV };
            tr_ sub { td_ 'USER'; td_ "$< / $>" };
            tr_ sub { td_ 'GROUP'; td_ "$( / $)" };
            tr_ sub { td_ 'OS'; td_ $^O };
            tr_ sub { td_ 'Perl'; td_ $^V };
            tr_ sub { td_ 'Up for'; td_ sprintf '%.3f seconds', time - $^T };
        };
        ('Process')
    },

    env => sub {
        table_ sub {
            tr_ sub {
                td_ $_;
                td_ $ENV{$_};
            } for sort keys %ENV;
        };
        ('Environment', scalar keys %ENV)
    },

    inc => sub {
        table_ sub {
            tr_ sub {
                td_ $_;
                td_ $INC{$_};
            } for sort keys %INC;
        };
        ('Included files', scalar keys %INC)
    },

    han => sub {
        my $cnt = 0;
        my sub tbl_($title, $lst) {
            return if !@$lst;
            $cnt += @$lst;
            h2_ $title;
            table_ sub {
                tr_ sub {
                    td_ clean_re $_->[0];
                    td_ sub { loc_ $_->[1] };
                } for @$lst;
            };
        }
        for my $meth (qw/GET POST DELETE OPTIONS PUT PATCH QUERY/) {
            my($path, $re) = ($FU::path_routes{$meth}, $FU::re_routes{$meth});
            my @lst = (
                (map [$_, $path->{$_}[1]], $path ? sort keys %$path : ()),
                (map [$_->[0], $_->[2]], $re ? @$re : ())
            );
            tbl_ $meth, \@lst;
        }
        tbl_ before_request => [ map [$_, $FU::before_request[$_][1]], 0..$#FU::before_request ];
        tbl_ after_request => [ map [$_, $FU::after_request[$_][1]], 0..$#FU::after_request ];
        ('Handlers', $cnt)
    },

    pgst => sub {
        return () if !$FU::DB;
        my $lst = eval { $FU::DB->q(
            'SELECT generic_plans + custom_plans, statement FROM pg_prepared_statements ORDER BY generic_plans + custom_plans DESC, statement'
        )->cache(0)->alla } || do { warn "Unable to collect prepared statement list: $@"; return () };
        return () if !@$lst;
        table_ sub {
            thead_ sub { tr_ sub {
                td_ 'Num';
                td_ 'Query';
            } };
            tr_ sub {
                td_ $_->[0];
                td_ class => 'code', sub { fmtpre_ $_->[1] };
            } for @$lst;
        };
        ('Prepared statements', scalar @$lst)
    },
);


sub collect {
    my @t;
    for my ($id, $sub) (@tabs) {
        my($title, $num);
        my $html = fragment { ($title, $num) = $sub->() };
        push @t, { id => $id, title => $title, num => $num, html => $html } if $title;
    }
    \@t
}


sub framework_($data) {
    html_ sub {
        head_ sub {
            title_ 'FU Debugging Interface';
            meta_ name => 'viewport', content => 'width=device-width, initial-scale=1.0, user-scalable=yes';
            style_ type => 'text/css', <<~_;
              html { box-sizing: border-box; color: #000; background: #fff }
              *, *:before, *:after { box-sizing: inherit }
              * { margin: 0; padding: 0; font: inherit; color: inherit }

              body { display: grid; grid: 45px 400px / 220px auto; }
              header { grid-column: 1 / 3; grid-row: 1 / 2 }
              nav { grid-column: 1 / 2; grid-row: 2 / 3 }
              main { grid-column: 2 / 3; grid-row: 2 / 3 }

              header, nav { background: #eee }
              main { border-top: 2px solid #009; border-left: 2px solid #009 }
              nav { border-bottom: 2px solid #009 }

              header { display: flex; justify-content: space-between; padding: 10px }
              header h1 { font-size: 20px; font-weight: bold }
              header menu { list-style-type: none; display: flex; gap: 15px }

              body > input { display: none }
              nav { padding-top: 20px }
              nav menu { list-style-type: none }
              nav label { display: block; width: 100%; padding: 2px 10px; cursor: pointer; white-space: nowrap }
              nav label:hover { background-color: #fff }
              nav label span { float: right; font-size: 80% }

              main { padding: 10px 20px }
              main h2 { margin: 30px 0 5px -10px; font-size: 20px; font-weight: bold }
              main h2:first-child { margin-top: 0 }

              p, pre, table { margin: 5px 0 }
              pre, .code { font-family: monospace; white-space: pre }
              table { border-collapse: collapse }
              td { padding: 1px 10px 1px 0; font-size: 12px; vertical-align: top }
              tr:hover { background-color: #eee }
              thead { font-weight: bold }
              .num { text-align: right; white-space: nowrap }
            _
            style_ type => 'text/css', join "\n", map +(
                "#tab_$_:checked ~ nav menu li label[for=tab_$_] { background-color: #fff }",
                "#tab_$_:not(:checked) ~ main #tabc_$_ { display: none }",
            ), map $_->{id}, @$data;
        };
        body_ sub {
            header_ sub {
                h1_ 'FU Debugging Interface';
                menu_ sub {
                    li_ sub { a_ href => '?last', 'Last' };
                    li_ sub { a_ href => '?cur', 'Current' };
                    li_ sub { a_ href => '?', 'Listing' };
                };
            };
            input_ type => 'radio', name => 'tab', id => "tab_$_->{id}", checked => $_ eq $data->[0] ? 'checked' : undef for @$data;
            nav_ sub {
                menu_ sub {
                    li_ sub {
                        label_ for => "tab_$_->{id}", sub {
                            txt_ $_->{title};
                            span_ $_->{num} if defined $_->{num};
                        }
                    } for @$data;
                };
            } if @$data;
            main_ sub {
                div_ id => "tabc_$_->{id}", sub {
                    h2_ $_->{title};
                    lit_ $_->{html};
                } for @$data;
            };
        };
    };
}

sub listing {
    opendir my $dh, $FU::debug_info->{storage} or do {
        warn "Error opening '$FU::debug_info->{storage}': $!\n";
        return;
    };
    my @f;
    /^fu-([0-9a-f]{22})\.txt$/ && push @f, $1 while (readdir $dh);
    return [sort @f];
}

sub listing_ {
    my $lst = listing;
    return p_ 'Request logging disabled.' if !$FU::debug_info->{storage} || !$FU::debug_info->{history};
    return p_ 'No requests logged.' if !@$lst;
    table_ sub {
        tr_ sub {
            open my $fh, '<:utf8', "$FU::debug_info->{storage}/fu-$_.txt" or return;
            my($ts, $time, $status, $method, $uri) = split / /, scalar <$fh>, 5;
            td_ sub { a_ href => "?$_", $_ };
            td_ class => 'num', fmtts $ts;
            td_ class => 'num', sprintf '%.0f ms', $time*1000;
            td_ class => 'num', $status;
            td_ $method;
            td_ $uri;
        } for reverse @$lst;
    }
}

sub load($id) {
    open my $fn, '<', "$FU::debug_info->{storage}/fu-$id.txt" or fu->notfound;
    scalar <$fn>;
    local $/=undef;
    fu->set_body(scalar <$fn>);
}

sub render {
    my $q = fu->query;
    if (!$q) {
        fu->set_body(framework_ [{id => 'lst', title => 'Recent Requests', html => fragment \&listing_ }]);
    } elsif ($q eq 'cur') {
        fu->set_body(framework_ collect);
    } elsif ($q eq 'last') {
        my $lst = listing;
        fu->notfound if !@$lst;
        load $lst->[$#$lst];
    } elsif ($FU::debug_info->{storage} && $q =~ /^[0-9a-f]{22}$/) {
        load $q;
    } else {
        fu->notfound
    }
}

sub save {
    my $files = listing;
    unlink sprintf '%s/fu-%s.txt', $FU::debug_info->{storage}, shift @$files while @$files >= $FU::debug_info->{history};

    delete $FU::REQ->{txn};

    my $fn = "$FU::debug_info->{storage}/fu-$FU::REQ->{trace_id}.txt";
    open my $fh, '>', $fn or do {
        warn "Error opening '$fn': $!\n";
        return;
    };
    my $line = sprintf "%d %f %s %s %s\n",
        time, time - $FU::REQ->{trace_start}, $FU::REQ->{status},
        fu->method, fu->path.(fu->query?'?'.fu->query:'');
    utf8::encode($line);
    print $fh $line;
    print $fh framework_ collect;
}

1;
