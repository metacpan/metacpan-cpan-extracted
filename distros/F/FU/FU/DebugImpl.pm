# Internal module used by FU.pm
package FU::DebugImpl 1.2;
use v5.36;
use utf8;
use experimental 'for_list';
use FU;
use FU::XMLWriter ':html5_', 'fragment', 'xml_escape';
use Time::HiRes 'time', 'clock_gettime', 'CLOCK_MONOTONIC';
use POSIX 'strftime';

sub fmtts { strftime '%Y-%m-%d %H:%M:%S UTC', gmtime shift }

sub loc_($loc) {
    txt_ '[internal]' if !@$loc;
    for (0..$#$loc) {
        br_ if $_;
        my $l = $loc->[$_];
        my $f = $_ == $#$loc ? '(main)' : $loc->[$_+1][3];
        $f = "$l->[0]::$f" if $f !~ /^\Q$l->[0]/;
        txt_ $f;
        small_ " @ $l->[1]:$l->[2]";
    }
}

sub clean_re($str) {
    # Regex formatting isn't stable, but this cleans up the crap I'm seeing a little bit.
    "$str" =~ s/^\(\?\^u:\^\(\?\^u://r =~ s/\)\$\)$//r;
}

sub raw_data($str) {
    my $d = substr $str, 0, 32*1024;
    my $trunc = length $str > 32*1024 ? ', truncated' : '';
    return utf8::decode($d) ? ("utf8$trunc", $d)
         : ("hex$trunc", unpack('H*', $d) =~ s/(.{128})/$1\n/rg =~ s/(.{16})/$1 /rg);
}

my @sections = (
    req => sub {
        my $r = $FU::REQ;
        table_ sub {
            tr_ sub { td_ 'Method'; td_ fu->method };
            tr_ sub { td_ 'Path'; td_ fu->path };
            tr_ sub { td_ 'Query'; td_ fu->query };
            tr_ sub { td_ 'Client IP'; td_ fu->ip };
            tr_ sub { td_ 'Received'; td_ fmtts(time - (($r->{trace_end}||clock_gettime(CLOCK_MONOTONIC)) - $r->{trace_start})) };
        };
        h2_ 'Headers';
        table_ sub {
            tr_ sub {
                td_ $_;
                td_ fu->headers->{$_};
            } for sort keys fu->headers->%*;
        };
        if ((fu->header('content-length')||0) > 0) {
            h2_ 'Body';
            section_ class => 'tabs', sub {
                my $json = eval { fu->json({type=>'any'}) };
                details_ name => 'reqbody', open => !0, sub {
                    summary_ 'JSON';
                    pre_ FU::Util::json_format($json, pretty => 1, canonical => 1);
                } if $json;
                my $formdata = eval { fu->formdata({type=>'hash'}) };
                details_ name => 'reqbody', open => !0, sub {
                    summary_ 'Form data';
                    table_ sub {
                        for my $k (sort keys %$formdata) {
                            tr_ sub {
                                td_ $k;
                                td_ $_;
                            } for ref $formdata->{$k} ? $formdata->{$k}->@* : ($formdata->{$k});
                        }
                    };
                } if $formdata;
                my $multipart = eval { fu->multipart };
                details_ name => 'reqbody', open => !0, sub {
                    summary_ 'Multipart';
                    pre_ join "\n", map $_->describe, @$multipart;
                } if $multipart;
                details_ name => 'reqbody', open => !0,sub {
                    my($lbl, $data) = raw_data $r->{body};
                    summary_ "Raw ($lbl)";
                    pre_ $data;
                };
            }
        }
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
            for my $k (sort keys $r->{reshdr}->%*) {
                my $v = $r->{reshdr}{$k};
                tr_ sub {
                    td_ $k;
                    td_ $_;
                } for !defined $v ? () : ref $v ? @$v : ($v);
            }
        };
        my $body = $r->{resbody_orig} // $r->{resbody};
        if (length $body) {
            h2_ 'Body';
            section_ class => 'tabs', sub {
                my $json = ($r->{reshdr}{'content-type'}||'') =~ /^application\/json/ && eval { FU::Util::json_parse($body, utf8 => 1) };
                details_ name => 'resbody', open => !0, sub {
                    summary_ 'JSON';
                    pre_ FU::Util::json_format($json, pretty => 1, canonical => 1);
                } if $json;
                details_ name => 'resbody', open => !0,sub {
                    my($lbl, $data) = raw_data $body;
                    summary_ "Raw ($lbl)";
                    pre_ $data;
                };
            }
        }
        ('Response')
    },

    sql => sub {
        my $queries = $FU::REQ->{trace_sql};
        return () if !$queries;

        # Convert binary params to text.
        # For queries with text_params, assume the params are already valid for the text format.
        my @binparams = grep $_->{type} && !exists $_->{text}, map $_->{params}->@*, @$queries;
        my @arg = map +($_->{type}, $_->{bin}), @binparams;
        my @text;
        my $ok = !@arg || eval { @text = $FU::DB->bin2text(@arg); 1 };
        $binparams[$_]{text} = $text[$_] for 0..$#text;
        pre_ "Error converting binary parameters:\n$@" if !$ok;

        input_ type => 'checkbox', id => "row${_}_c" for 0..$#{$queries};
        table_ class => 'sqlt', sub {
            thead_ sub { tr_ sub {
                td_ class => 'num', 'Exec';
                td_ class => 'num', 'Prep';
                td_ class => 'num', 'Rows';
                td_ 'Query';
            } };
            my $rows = 0;
            for my($i, $st) (builtin::indexed $queries->@*) {
                $rows += $st->{nrows};
                tr_ sub {
                    td_ class => 'num', sprintf '%.1f ms', $st->{exec_time}*1000;
                    td_ class => 'num', !defined $st->{prepare_time} ? '-' : $st->{prepare_time} ? sprintf '%.1f ms', $st->{prepare_time}*1000 : 'cache';
                    td_ class => 'num', $st->{nrows};
                    td_ class => 'sum', sub {
                        label_ for => "row${i}_c", sub {
                            span_ class => 'closed', '▶';
                            span_ class => 'open', '▼';
                            txt_ $st->{query} =~ s/[\r\n]/ /rg =~ s/\s\s+/ /rg =~ s/^\s+//r;
                        };
                    };
                };
                tr_ class => 'details', id => "row$i", sub {
                    td_ '';
                    td_ colspan => 3, sub {
                        pre_ $st->{query};
                        if ($st->{params}->@*) {
                            strong_ 'Parameters:';
                            table_ sub {
                                tr_ sub {
                                    td_ class => 'num', sprintf '$%d =', $_+1;
                                    td_ class => 'code', sub {
                                        my $p = $st->{params}[$_]{text};
                                        !defined $p ? em_ 'null' : txt_ $p;
                                    };
                                } for (0..$#{$st->{params}});
                            };
                            # XXX: Buggy when the query contains string literals with $n variables.
                            strong_ 'Interpolated:';
                            pre_ $st->{query} =~ s{\$([1-9][0-9]*)}{
                                my $v = $st->{params}[$1-1]{text};
                                defined $v ? $FU::DB->escape_literal($v) : 'NULL'
                            }egr;
                        }
                    };
                };
            }
            tr_ sub {
                td_ class => 'num', sprintf '%.1f ms', $FU::REQ->{trace_sqlexec}*1000;
                td_ class => 'num', !defined $FU::REQ->{trace_sqlprep} ? '-' : sprintf '%.1f ms', $FU::REQ->{trace_sqlprep}*1000;
                td_ class => 'num', $rows;
                td_ class => 'sum', 'total';
            } if @$queries > 1;
        };
        ('Queries', scalar @$queries)
    },

    fu => sub {
        return () if !keys fu->%*;
        # TODO: This is kinda lazy, an expandable table might be nicer.
        require Data::Dumper;
        pre_ sub {
            lit_ Data::Dumper->new([fu])->Sortkeys(1)->Terse(1)->Dump;
        };
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
                td_ class => 'code', $_->[1];
            } for @$lst;
        };
        ('Prepared stmts', scalar @$lst)
    },
);


sub collect {
    my @t;
    for my ($id, $sub) (@sections) {
        my($title, $num);
        my $html = fragment { ($title, $num) = $sub->() };
        utf8::decode($html);
        push @t, { id => $id, title => $title, num => $num, html => $html } if $title;
    }
    \@t
}


sub framework_($data) {
    html_ sub {
        head_ sub {
            title_ 'FU Debugging Interface';
            meta_ name => 'viewport', content => 'width=device-width, initial-scale=1.0, user-scalable=yes';
            link_ rel => 'stylesheet', type => 'text/css', media => 'all', href => '?css';
            style_ type => 'text/css', <<~_;
            _
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
            nav_ sub {
                menu_ sub {
                    li_ sub {
                        a_ href => "#$_->{id}", sub {
                            txt_ $_->{title};
                            span_ $_->{num} if defined $_->{num};
                        };
                    } for @$data;
                };
            } if @$data;
            main_ sub {
                for (@$data) {
                    h1_ id => $_->{id}, $_->{title};
                    lit_ $_->{html};
                }
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

sub css {
    # Awful CSS row hiding hack. I'm not sorry.
    state $css = join '', <DATA>, map qq{
        #row${_}_c:checked ~ * label[for=row${_}_c] .closed { display: none }
        #row${_}_c:not(:checked) ~ * label[for=row${_}_c] .open { display: none }
        #row${_}_c:not(:checked) ~ * #row${_} { display: none }
    }, 0..1000;
}

sub render {
    my $q = fu->query;
    if (!$q) {
        fu->set_body(framework_ [{id => 'lst', title => 'Recent Requests', html => fragment \&listing_ }]);
    } elsif ($q eq 'css') {
        fu->set_header('content-type', 'text/css');
        fu->set_header('cache-control', 'max-age=86400');
        fu->set_body(css());
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
        time, $FU::REQ->{trace_end} - $FU::REQ->{trace_start}, $FU::REQ->{status},
        fu->method, fu->path.(fu->query?'?'.fu->query:'');
    utf8::encode($line);
    print $fh $line;
    print $fh framework_ collect;
}

1;

__DATA__
html { box-sizing: border-box; color: #000; background: #fff }
*, *:before, *:after { box-sizing: inherit }
* { margin: 0; padding: 0; font: inherit; color: inherit }

/* Ugh, fixed positioning */
header { position: fixed; top: 0; left: 0; width: 100%; height: 40px; z-index: 2 }
nav { position: fixed; top: 38px; left: 0; width: 200px; z-index: 2 }
main { margin: 0 0 0 200px }

header, nav { background: #eee }
header { border-bottom: 2px solid #009 }
nav { border-bottom: 2px solid #009; border-right: 2px solid #009 }

header { display: flex; justify-content: space-between; align-items: baseline; padding: 5px 10px }
header h1 { font-size: 120%; font-weight: bold }
header menu { list-style-type: none; display: flex; gap: 15px }

body > input { display: none }
nav { padding-top: 20px }
nav menu { list-style-type: none }
nav a { display: block; width: 100%; text-decoration: none; padding: 2px 10px; cursor: pointer; white-space: nowrap }
nav a:hover { background-color: #fff }
nav a span { float: right; font-size: 80% }

main { padding: 0 10px 30px 10px }
main h1 { background: #eee; padding: 5px 10px 5px 205px; margin: 40px -10px 10px -210px; scroll-margin-top: 40px; font-size: 130%; font-weight: bold }
main h2 { margin: 20px 0 5px 0; font-size: 120%; font-weight: bold }

p, table, pre { margin: 5px 0 }
pre { border-left: 2px dotted #999; padding-left: 5px; font-family: monospace; white-space: pre; overflow-x: auto; padding-bottom: 15px; /* for the scrollbar, kinda browser-specific */ }
table { border-collapse: collapse }
td { padding: 1px 10px 1px 0; font-size: 12px; vertical-align: top }
td.code { font-family: monospace }
tr:hover { background-color: #eee }
thead { font-weight: bold }
.num { text-align: right; white-space: nowrap }

section.tabs { position: relative; display: flex; flex-wrap: wrap; z-index: 1; }
section.tabs summary { cursor: pointer; order: 0; display: block; padding: 3px 5px; margin-right: 10px; background: #ddd }
section.tabs summary:hover, section.tabs details[open] summary { background: #eee }
section.tabs details { display: contents }
section.tabs details *:nth-child(2) { order: 1; width: 100% }

.sqlt { width: 100%; table-layout: fixed }
.sqlt .num { width: 50px }
.sqlt .num:first-child { width: 75px }
.sqlt .num:nth-child(2) { width: 60px }
.sqlt .sum { white-space: nowrap; font-family: monospace; overflow: hidden; text-overflow: ellipsis }
.sqlt label { cursor: pointer }
.sqlt label span { color: #555; display: inline-block; width: 15px }
.sqlt tr.details { background: #fff }
.sqlt tr.details > td { padding-bottom: 10px }
input[id^=row] { display: none }

small { color: #555; font-size: 90% }
em { font-style: italic }
strong { font-weight: bold }
