package Finance::Currency::FiatX;

our $DATE = '2019-01-10'; # DATE
our $VERSION = '0.011'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use List::Util qw(max);

use Exporter qw(import);
our @EXPORT_OK = qw(get_spot_rate get_all_spot_rates list_rate_sources);

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Currency exchange rate library',
};

our %args_db = (
    dbh => {
        schema => ['obj*'],
    },
    table_prefix => {
        schema => 'str*',
        default => 'fiatx_',
    },
);

our %args_caching = (
    max_age_cache => {
        summary => 'Above this age (in seconds), '.
            'we retrieve rate from remote source again',
        schema => 'nonnegint*',
        default => 4*3600,
        cmdline_aliases => {
            no_cache => {is_flag=>1, summary => 'Alias for --max-age-cache 0', code => sub { $_[0]{max_age_cache} = 0 }},
        },
    },
);

our %arg_source = (
    source => {
        summary => 'Ask for a specific remote source',
        schema => ['str*', {
            match=>qr/\A(?:\w+|:(?:any|all|highest|lowest|newest|oldest|average))\z/,
        }],
        default => ':any',
        completion => sub {
            require Complete::Module;
            require Complete::Util;

            my %args = @_;

            my $mods = Complete::Module::complete_module(
                word => $args{word},
                find_pod => 0,
                find_prefix => 0,
                ns_prefix => 'Finance::Currency::FiatX::Source',
            );

            Complete::Util::combine_answers(
                $mods,
                [':any', ':highest', ':lowest', 'newest', ':oldest', ':average'],
            );
        },
        description => <<'_',

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: `:highest` to return highest rate of all sources,
`:lowest` to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

_
    },
);

our %arg_req0_source = (
    source => {
        %{ $arg_source{source} },
        req => 1,
        pos => 0,
    },
);

our %args_spot_rate = (
    from => {
        schema => 'currency::code*',
        req => 1,
        pos => 0,
    },
    to => {
        schema => 'currency::code*',
        req => 1,
        pos => 1,
    },
    type => {
        summary => 'Which rate is wanted? e.g. sell, buy',
        schema => 'str*',
    },
    %arg_source,
);

sub _get_db_schema_spec {
    my $table_prefix = shift;

    +{
        latest_v => 5,
        component_name => 'fiatx',
        provides => ["${table_prefix}rate"],
        install => [
            "CREATE TABLE ${table_prefix}rate (
                 id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                 query_time DOUBLE NOT NULL, -- when do we query the source?
                 mtime DOUBLE, -- when is the rate last updated, according to the source?
                 from_currency VARCHAR(10) NOT NULL,
                 to_currency   VARCHAR(10) NOT NULL,
                 rate DECIMAL(21,8) NOT NULL,         -- multiplier to use to convert 1 unit of from_currency to to_currency, e.g. from_currency = USD, to_currency = IDR, rate = 14000
                 source VARCHAR(10) NOT NULL,
                 type VARCHAR(32) NOT NULL DEFAULT '', -- 'sell', 'buy', etc
                 note VARCHAR(255),
                 _key TINYINT -- 1 = get_spot_rate, 2=get_all_spot_rates
             )",
            "CREATE INDEX ${table_prefix}rate_time ON ${table_prefix}rate(query_time)",
        ],
        upgrade_to_v5 => [
            "ALTER TABLE ${table_prefix}rate CHANGE type type VARCHAR(32) NOT NULL DEFAULT ''",
        ],
        upgrade_to_v4 => [
            "ALTER TABLE ${table_prefix}rate ADD _key TINYINT",
        ],
        upgrade_to_v3 => [
            "ALTER TABLE ${table_prefix}rate ADD id INT NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST, CHANGE time query_time DOUBLE NOT NULL, ADD mtime DOUBLE",
        ],
        upgrade_to_v2 => [
            "ALTER TABLE ${table_prefix}rate CHANGE currency1 from_currency VARCHAR(10) NOT NULL, CHANGE currency2 to_currency VARCHAR(10) NOT NULL",
        ],
        install_v4 => [
            "CREATE TABLE ${table_prefix}rate (
                 id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
                 query_time DOUBLE NOT NULL, -- when do we query the source?
                 mtime DOUBLE, -- when is the rate last updated, according to the source?
                 from_currency VARCHAR(10) NOT NULL,
                 to_currency   VARCHAR(10) NOT NULL,
                 rate DECIMAL(21,8) NOT NULL,         -- multiplier to use to convert 1 unit of from_currency to to_currency, e.g. from_currency = USD, to_currency = IDR, rate = 14000
                 source VARCHAR(10) NOT NULL,
                 type VARCHAR(4) NOT NULL DEFAULT '', -- 'sell', 'buy', or empty
                 note VARCHAR(255),
                 _key TINYINT -- 1 = get_spot_rate, 2=get_all_spot_rates
             )",
            "CREATE INDEX ${table_prefix}rate_time ON ${table_prefix}rate(query_time)",
        ],
        install_v3 => [
            "CREATE TABLE ${table_prefix}rate (
                 id INT NOT NULL PRIMARY KEY,
                 query_time DOUBLE NOT NULL, -- when do we query the source?
                 mtime DOUBLE, -- when is the rate last updated, according to the source?
                 from_currency VARCHAR(10) NOT NULL,
                 to_currency   VARCHAR(10) NOT NULL,
                 rate DECIMAL(21,8) NOT NULL,         -- multiplier to use to convert 1 unit of from_currency to to_currency, e.g. from_currency = USD, to_currency = IDR, rate = 14000
                 source VARCHAR(10) NOT NULL,
                 type VARCHAR(4) NOT NULL DEFAULT '', -- 'sell', 'buy', or empty
                 note VARCHAR(255)
             )",
            "CREATE INDEX ${table_prefix}rate_time ON ${table_prefix}rate(query_time)",
        ],
        install_v2 => [
            "CREATE TABLE ${table_prefix}rate (
                 time DOUBLE NOT NULL,
                 from_currency VARCHAR(10) NOT NULL,
                 to_currency   VARCHAR(10) NOT NULL,
                 rate DECIMAL(21,8) NOT NULL,         -- multiplier to use to convert 1 unit of from_currency to to_currency, e.g. from_currency = USD, to_currency = IDR, rate = 14000
                 source VARCHAR(10) NOT NULL,         -- e.g. KlikBCA
                 type VARCHAR(4) NOT NULL DEFAULT '', -- 'sell', 'buy', or empty
                 note VARCHAR(255)
             )",
            "CREATE INDEX ${table_prefix}rate_time ON ${table_prefix}rate(time)",
        ],
        install_v1 => [
            "CREATE TABLE ${table_prefix}rate (
                 time DOUBLE NOT NULL,
                 currency1 VARCHAR(10) NOT NULL,
                 currency2 VARCHAR(10) NOT NULL,
                 rate DECIMAL(21,8) NOT NULL,         -- multiplier to use to convert 1 unit of currency1 to currency2, e.g. currency1 = USD, currency2 = IDR, rate = 14000
                 source VARCHAR(10) NOT NULL,         -- e.g. KlikBCA
                 type VARCHAR(4) NOT NULL DEFAULT '', -- 'sell', 'buy', or empty
                 note VARCHAR(255)
             )",
            "CREATE INDEX ${table_prefix}rate_time ON ${table_prefix}rate(time)",
        ],
    };
}

sub _init {
    require SQL::Schema::Versioned;

    my ($args) = @_;
    $args->{table_prefix} //= 'fiatx_';
    $args->{max_age_cache} //= 4*3600;
    $args->{amount} //= 1;

    my $db_schema_spec = _get_db_schema_spec($args->{table_prefix});

    my $res = SQL::Schema::Versioned::create_or_update_db_schema(
        dbh => $args->{dbh}, spec => $db_schema_spec,
    );
    $res->[0] == 200 or die "Can't initialize FiatX's database schema: $res->[1]";
}

$SPEC{get_all_spot_rates} = {
    v => 1.1,
    summary => 'Get all spot rates from a source',
    description => <<'_',

This routine will retrieve all available spot rates from a source. You can
either pick a specific source (e.g. `bi` for "Bank of Indonesia") or one of the
special/"pseudo" sources: ':any', ':highest', ':lowest', 'newest', ':oldest',
':average'.

Some source provide rates for a large number of currency pairs, not all of which
you might need. For retrieving rates for a specific currency pair only, use
`get_spot_rate`.

_
    args => {
        %args_db,
        %args_caching,

        %arg_req0_source,
    },
};
sub get_all_spot_rates {
    my %args = @_;
    _get_all_spot_rates_or_get_spot_rate('get_all_spot_rates', %args);
}

$SPEC{get_spot_rate} = {
    v => 1.1,
    summary => 'Get spot rate for a currency pair',
    description => <<'_',

This routine will retrieve spot rate(s) for a specific currency pair from a
source. You can either let the routine pick any one source that is new enough
(':any') or pick a specific source (e.g. `bi` for "Bank of Indonesia"), or one
of the other special/"pseudo" sources: ':highest', ':lowest', 'newest',
':oldest', ':average'.

Note that there might be multiple spot rates for a single currency pair, because
there might be different types of rates, for example: "buy", "sell", or more
specific types or buy and sell rates.

See also `get_all_spot_rates` to retrieve rates for all currency pairs available
from a specific source.

_
    args => {
        %args_db,
        %args_caching,

        %args_spot_rate,
    },
};
sub get_spot_rate {
    my %args = @_;
    _get_all_spot_rates_or_get_spot_rate('get_spot_rate', %args);
}

$SPEC{list_rate_sources} = {
    v => 1.1,
    summary => 'List exchange rate sources installed on the system',
    description => <<'_',

Sources are modules under the namespace `Finance::Currency::FiatX::Source::*`,
for example the source `bi` ("Bank of Indonesia") is implemented in
<pm:Finance::Currency::FiatX::Source::bi>. This routine lists the installed
sources without the namespace prefix.

_
    args => {},
};
sub list_rate_sources {
    my %args = @_;

    require PERLANCAR::Module::List;
    my @res;
    my $mods = PERLANCAR::Module::List::list_modules(
        'Finance::Currency::FiatX::Source::', {list_modules=>1});
    unless (keys %$mods) {
        return [412, "No source modules available"];
    }
    for my $src (sort keys %$mods) {
        $src =~ s/^Finance::Currency::FiatX::Source:://;
        push @res, $src;
    }
    return [200, "OK", \@res];
}

sub _get_all_spot_rates_or_get_spot_rate {
    my ($which, %args) = @_;

    _init(\%args);
    my $dbh = $args{dbh};
    # XXX schema
    my $from   = $args{from};
    my $to     = $args{to};
    my $table_prefix = $args{table_prefix} // 'fiatx_';
    my $max_age_cache = $args{max_age_cache} // 4*3600;
    my $type   = $args{type} // 'sell';
    my $source = $args{source} // ':any';

    if ($which eq 'get_spot_rate') {
        $from or return [400, "Please specify from"];
        $to or return [400, "Please specify to"];
        return [400, "Source cannot be :all for get_spot_rate()"]
            if $source eq ':all';
        # in case user does this
        if ($from eq $to) {
            return [304, "OK (identity)", {rate=>1}];
        }
    } else {
        $source or return [400, "Please specify from"];
    }

    my $pair; $pair = "$from/$to" if $from && $to;

    my $sth_insert = $dbh->prepare(
        "INSERT INTO ${table_prefix}rate
           (query_time,mtime, from_currency,to_currency,rate,type, source,note, _key) VALUES
           (?,?, ?,?,?,?, ?,?, ?)"
    );

    my $now = time();

    my $code_query_db_get_spot_rate_from_a_source = sub {
        my ($source) = @_;
        return $dbh->selectrow_hashref(
            "SELECT
               1 cached,
               CONCAT(from_currency,'/',to_currency) pair,
               type,
               rate,
               note,
               source,
               mtime,
               query_time cache_time
             FROM ${table_prefix}rate
             WHERE
               source=? AND
               query_time >= ? AND
               from_currency=? AND
               to_currency=? AND
               type=?
            ORDER BY query_time DESC
            LIMIT 1", {},
            $source, $now - $max_age_cache, $from, $to, $type,
        );
    };
    my $code_query_db_get_all_spot_rates = sub {
        # ugh, mysql 5.x still doesn't support LIMIT in IN subquery, so we need
        # to query once per source
        my @srcs;
        if ($source =~ /\A\w+\z/) {
            @srcs = ($source);
        } else {
            my $sth = $dbh->prepare(
                "SELECT DISTINCT source
                 FROM ${table_prefix}rate
                 WHERE
                   query_time>=?");
            $sth->execute($now - $max_age_cache);
            while (my ($src) = $sth->fetchrow_array) { push @srcs, $src }
        }
        my $sth = $dbh->prepare(
          "SELECT
             1 cached,
             CONCAT(from_currency,'/',to_currency) pair,
             type,
             rate,
             note,
             source,
             mtime,
             query_time cache_time
           FROM ${table_prefix}rate
           WHERE
             query_time >= ? AND
             source=? AND
             _key=2
           ORDER BY query_time, pair, type DESC
           ");
        my @rows;
        # we don't record each caching series, only mtime. 2+ sessions can
        # have the same mtime
        my %seen; # key = source + pair + type
        for my $src (@srcs) {
            $sth->execute(
                $now - $max_age_cache,
                $src,
            );
            while (my $row = $sth->fetchrow_hashref) {
                my $key = "$row->{source} $row->{pair} $row->{type}";
                push @rows, $row unless $seen{$key}++;
            }
        }
        @rows;
    };
    my $code_query_db_get_spot_rate_from_any_source = sub {
        return $dbh->selectrow_hashref(
            "SELECT
               1 cached,
               CONCAT(from_currency,'/',to_currency) pair,
               type,
               rate,
               note,
               source,
               mtime,
               query_time cache_time
             FROM ${table_prefix}rate
             WHERE
               query_time >= ? AND
               from_currency=? AND
               to_currency=? AND
               type=?
            ORDER BY query_time DESC
            LIMIT 1", {},
            $now - $max_age_cache, $from, $to, $type,
        );
    };
    my $code_query_db_get_spot_rates_from_all_sources = sub {
        # ugh, mysql 5.x still doesn't support LIMIT in IN subquery, so we need
        # to query once per source
        my $sth = $dbh->prepare(
            "SELECT DISTINCT source
             FROM ${table_prefix}rate
             WHERE
               query_time>=? AND
               from_currency=? AND
               to_currency=? AND
               type=?");
        $sth->execute($now - $max_age_cache, $from, $to, $type);
        my @srcs;
        while (my ($src) = $sth->fetchrow_array) { push @srcs, $src }
        $sth = $dbh->prepare(
          "SELECT
             1 cached,
             CONCAT(from_currency,'/',to_currency) pair,
             type,
             rate,
             note,
             source,
             mtime,
             query_time cache_time
           FROM ${table_prefix}rate
           WHERE
             source = ? AND
             query_time >= ? AND
             from_currency=? AND
             to_currency=? AND
             type=?
           ORDER BY query_time DESC
           LIMIT 1");
        my @rows;
        for my $src (@srcs) {
            $sth->execute($src, $now - $max_age_cache, $from, $to, $type);
            my $row = $sth->fetchrow_hashref;
            next unless $row; # shouldn't happen but for guard against race condition
            push @rows, $row;
        }
        @rows;
    };

    my @rates;
  GET_RATES:
    {
      QUERY_DB:
        {
            my $rate;
            if ($which eq 'get_all_spot_rates') {
                @rates = $code_query_db_get_all_spot_rates->();
                if (@rates) {
                    last GET_RATES;
                }
            } elsif ($source =~ /\A\w+\z/) {
                $rate = $code_query_db_get_spot_rate_from_a_source->($source);
                if ($rate) {
                    push @rates, $rate;
                    last GET_RATES;
                }
            } elsif ($source eq ':any') {
                $rate = $code_query_db_get_spot_rate_from_any_source->();
                if ($rate) {
                    push @rates, $rate;
                    last GET_RATES;
                }
            } else {
                @rates = $code_query_db_get_spot_rates_from_all_sources->();
                if (@rates) {
                    last GET_RATES;
                }
            }
            log_trace "There are no cached rates that are recent enough, ".
                "querying remote source(s) ...";
        }

        my @sources;
      LIST_SOURCES:
        {
            if ($source =~ /\A\w+\z/) {
                @sources = ($source);
                last;
            }

            require PERLANCAR::Module::List;
            my $mods = PERLANCAR::Module::List::list_modules(
                'Finance::Currency::FiatX::Source::', {list_modules=>1});
            unless (keys %$mods) {
                return [412, "No source modules available"];
            }
            for my $src (sort keys %$mods) {
                $src =~ s/^Finance::Currency::FiatX::Source:://;
                push @sources, $src;
            }
        }

      QUERY_SOURCES:
        {
          SOURCE:
            for my $src (@sources) {
                log_trace "Querying source '$src' ...";
                my $mod = "Finance::Currency::FiatX::Source::$src";
                (my $modpm = "$mod.pm") =~ s!::!/!g;
                require $modpm;

              GET_ALL_SPOT_RATES:
                {
                    last unless $which eq 'get_all_spot_rates';
                    my $time = time();
                    my $res = &{"$mod\::get_all_spot_rates"}();
                    log_trace "Got response from source '%s': %s", $src, $res;
                    if ($res->[0] == 200) {
                        for my $rate (@{ $res->[2] }) {
                            my ($rfrom, $rto) = $rate->{pair} =~ m!(.+)/(.+)!;
                            $sth_insert->execute(
                                $time, $rate->{mtime},
                                $rfrom, $rto, $rate->{rate}, $rate->{type},
                                $src, $rate->{note}, 2);
                            $rate->{source} = $src;
                            if (!$pair || $pair eq $rate->{pair} && $type eq $rate->{type}) {
                                push @rates, $rate;
                            }
                        }
                    } elsif ($res->[0] == 501) {
                        last GET_ALL_SPOT_RATES;
                    } else {
                        next SOURCE;
                    }
                }

              GET_SPOT_RATE:
                {
                    last unless $which eq 'get_spot_rate';
                    my $time = time();
                    my $res = &{"$mod\::get_spot_rate"}(from => $from, to => $to, type => $type);
                    log_trace "Got response from source: %s", $res;
                    if ($res->[0] == 200) {
                        my $rate = $res->[2];
                        $sth_insert->execute(
                            $time, $rate->{mtime},
                            $from, $to, $rate->{rate}, $type,
                            $src, $rate->{note}, 1);
                        $rate->{source} = $src;
                        push @rates, $rate;
                    } elsif ($res->[0] == 501) {
                        last GET_SPOT_RATE;
                    } else {
                        next SOURCE;
                    }
                }

                last if @rates && $source eq ':any';
            } # SOURCE
        } # QUERY_SOURCES
    } # GET_RATES

    if ($source eq ':highest') {
        my %highest_rates; # key = pair+type
        my %sources; # key = pair+type, value = {source1=>1, ...}
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            $sources{$key}{$rate->{source}} = 1;
            $highest_rates{$key} = $rate
                if !$highest_rates{$key} ||
                $highest_rates{$key}{rate} < $rate->{rate};
        }
        @rates = map {$highest_rates{$_}} sort keys %highest_rates;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            my @s = sort keys %{ $sources{$key} };
            if (@s > 1) {
                $rate->{note} = $rate->{note} ?
                    "$rate->{note} (highest of ".join(", ", @s).")" :
                    'highest of '.join(", ", @s);
            }
        }
    } elsif ($source eq ':lowest') {
        my %lowest_rates;
        my %sources;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            $sources{$key}{$rate->{source}} = 1;
            $lowest_rates{$key} = $rate
                if !$lowest_rates{$key} ||
                $lowest_rates{$key}{rate} > $rate->{rate};
        }
        @rates = map {$lowest_rates{$_}} sort keys %lowest_rates;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            my @s = sort keys %{ $sources{$key} };
            if (@s > 1) {
                $rate->{note} = $rate->{note} ?
                    "$rate->{note} (lowest of ".join(", ", @s).")" :
                    'lowest of '.join(", ", @s);
            }
        }
    } elsif ($source eq ':newest') {
        my %newest_rates;
        my %sources;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            $sources{$key}{$rate->{source}} = 1;
            $newest_rates{$key} = $rate
                if !$newest_rates{$key} ||
                $newest_rates{$key}{mtime} < $rate->{mtime};
        }
        @rates = map {$newest_rates{$_}} sort keys %newest_rates;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            my @s = sort keys %{ $sources{$key} };
            if (@s > 1) {
                $rate->{note} = $rate->{note} ?
                    "$rate->{note} (newest of ".join(", ", @s).")" :
                    'newest of '.join(", ", @s);
            }
        }
    } elsif ($source eq ':oldest') {
        my %oldest_rates;
        my %sources;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            $sources{$key}{$rate->{source}} = 1;
            $oldest_rates{$key} = $rate
                if !$oldest_rates{$key} ||
                $oldest_rates{$key}{mtime} > $rate->{mtime};
        }
        @rates = map {$oldest_rates{$_}} sort keys %oldest_rates;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            my @s = sort keys %{ $sources{$key} };
            if (@s > 1) {
                $rate->{note} = $rate->{note} ?
                    "$rate->{note} (oldest of ".join(", ", @s).")" :
                    'oldest of '.join(", ", @s);
            }
        }
    } elsif ($source eq ':average') {
        my %sources;
        my %sums_rates;
        my %sums_mtimes;
        my %notes;
        for my $rate (@rates) {
            my $key = $rate->{pair} . '-' . $rate->{type};
            $sources{$key}{$rate->{source}} = 1;
            $sums_rates {$key} //= 0;
            $sums_rates {$key} += $rate->{rate};
            $sums_mtimes{$key} //= 0;
            $sums_mtimes{$key} += $rate->{mtime};
            $notes{$key} = $rate->{note};
        }
        my @avg_rates;
        for my $key (sort keys %sums_rates) {
            my ($pair, $type) = split /-/, $key;
            my @avg_srcs = sort keys %{ $sources{$key} };
            my $avg_rate = {
                pair => $pair,
                mtime => $sums_mtimes{$key} / @avg_srcs,
                rate  => $sums_rates {$key} / @avg_srcs,
                type => $type,
                source => @avg_srcs > 1 ? undef : $avg_srcs[0],
                note => @avg_srcs > 1 ?
                    "(average of ".join(", ", @avg_srcs).")" : $notes{$key},
            };
            push @avg_rates, $avg_rate;
        }
        @rates = @avg_rates;
    }

    unless (@rates) {
        return [404, "Couldn't find any rates"];
    }

    if ($which eq 'get_spot_rate') {
        [200, "OK", $rates[0]];
    } else {
        my $fnum8 = ['number', {precision=>8}];

        my $resmeta = {};
        $resmeta->{'table.fields'}        = ['source', 'pair', 'type', 'rate',  'mtime',            'note', 'cache_time'];
        $resmeta->{'table.field_formats'} = [undef,    undef,   undef,  $fnum8, 'iso8601_datetime', undef , 'iso8601_datetime'];
        $resmeta->{'table.field_aligns'}  = ['left',   'ldef', 'left', 'right', 'left'];
        $resmeta->{'table.field_align_code'}  = sub { $_[0] =~ /^(buy|sell)/ ? 'right' : undef },
        $resmeta->{'table.field_format_code'} = sub { $_[0] =~ /^(buy|sell)/ ? $fnum8  : undef },
        [200, "OK", \@rates, $resmeta];
    }
}

1;
# ABSTRACT: Currency exchange rate library

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Currency::FiatX - Currency exchange rate library

=head1 VERSION

This document describes version 0.011 of Finance::Currency::FiatX (from Perl distribution Finance-Currency-FiatX), released on 2019-01-10.

=head1 SYNOPSIS

The easiest way to use this module is via CLI L<fiatx> from L<App::fiatx>. To
use this module directly, first create a MySQL database, then:

 use Finance::Currency::FiatX qw(get_spot_rate get_all_spot_rates);

 # connect to database
 my $dbh = DBI->connect(...);

 # create a database# get a single spot rate from any source
 my $res = get_spot_rate(dbh => $dbh, from => "USD", to => "IDR");

=head1 DESCRIPTION

FiatX is a library/application to convert one currency to another using several
backend modules ("sources", C<Finance::Currency::FiatX::Source::*>, which in
turns usually utilize C<Finance::Currency::Convert::*>) and store the rates in
L<DBI> database for caching.

=head1 FUNCTIONS


=head2 get_all_spot_rates

Usage:

 get_all_spot_rates(%args) -> [status, msg, payload, meta]

Get all spot rates from a source.

This routine will retrieve all available spot rates from a source. You can
either pick a specific source (e.g. C<bi> for "Bank of Indonesia") or one of the
special/"pseudo" sources: ':any', ':highest', ':lowest', 'newest', ':oldest',
':average'.

Some source provide rates for a large number of currency pairs, not all of which
you might need. For retrieving rates for a specific currency pair only, use
C<get_spot_rate>.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

=item * B<max_age_cache> => I<nonnegint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<source>* => I<str> (default: ":any")

Ask for a specific remote source.

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: C<:highest> to return highest rate of all sources,
C<:lowest> to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

=item * B<table_prefix> => I<str> (default: "fiatx_")

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 get_spot_rate

Usage:

 get_spot_rate(%args) -> [status, msg, payload, meta]

Get spot rate for a currency pair.

This routine will retrieve spot rate(s) for a specific currency pair from a
source. You can either let the routine pick any one source that is new enough
(':any') or pick a specific source (e.g. C<bi> for "Bank of Indonesia"), or one
of the other special/"pseudo" sources: ':highest', ':lowest', 'newest',
':oldest', ':average'.

Note that there might be multiple spot rates for a single currency pair, because
there might be different types of rates, for example: "buy", "sell", or more
specific types or buy and sell rates.

See also C<get_all_spot_rates> to retrieve rates for all currency pairs available
from a specific source.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<dbh> => I<obj>

=item * B<from>* => I<currency::code>

=item * B<max_age_cache> => I<nonnegint> (default: 14400)

Above this age (in seconds), we retrieve rate from remote source again.

=item * B<source> => I<str> (default: ":any")

Ask for a specific remote source.

If you want a specific remote source, you can specify it here. The default is
':any' which is to pick the first source that returns a recent enough current
rate.

Other special values: C<:highest> to return highest rate of all sources,
C<:lowest> to return lowest rate of all sources, ':newest' to return rate from
source with the newest last update time, ':oldest' to return rate from source
with the oldest last update time, ':average' to return arithmetic average of all
sources.

=item * B<table_prefix> => I<str> (default: "fiatx_")

=item * B<to>* => I<currency::code>

=item * B<type> => I<str>

Which rate is wanted? e.g. sell, buy.

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)


=head2 list_rate_sources

Usage:

 list_rate_sources() -> [status, msg, payload, meta]

List exchange rate sources installed on the system.

Sources are modules under the namespace C<Finance::Currency::FiatX::Source::*>,
for example the source C<bi> ("Bank of Indonesia") is implemented in
L<Finance::Currency::FiatX::Source::bi>. This routine lists the installed
sources without the namespace prefix.

This function is not exported by default, but exportable.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 BUGS

Please report all bug reports or feature requests to L<mailto:stevenharyanto@gmail.com>.

=head1 SEE ALSO

C<Finance::Currency::Convert::*> modules.

L<App::fiatx> and L<fiatx> which provides CLI for this module.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
