use strict;
use warnings;
use Dumbbench;
use HTTP::Headers;
use List::Util;
use Text::Table;
use Getopt::Long qw<:config no_ignore_case>;

local $| = 1;

BEGIN {
    local $ENV{'PERL_HTTP_HEADERS_FAST_XS'} = 0;
    require HTTP::Headers::Fast;
}

my %source = (
    'Connection'     => 'close',
    'Date'           => 'Tue, 11 Nov 2008 01:16:37 GMT',
    'Content-Length' => 3744,
    'Content-Type'   => 'text/html',
    'Status'         => 200,
);

my %cases = (
    _standardize_field_name => {
        fast => sub {
            HTTP::Headers::Fast::_standardize_field_name('Foo-Bar')
                for 1 .. 1e6
        },
    },

    push_header => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->push_header('X-Foo' => 1) for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->push_header('X-Foo' => 1) for 1 .. 1e4;
        },
    },

    push_header_many => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->push_header('X-Foo' => 1, 'X-Bar' => 2) for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->push_header('X-Foo' => 1, 'X-Bar' => 2) for 1 .. 1e4;
        },
    },

    get_date => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->date(1226370757);
            $h->date for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->date(1226370757);
            $f->date for 1 .. 1e4;
        },
    },

    set_date => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->date(1226370757) for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->date(1226370757) for 1 .. 1e4;
        },
    },

    scan => {
        orig => sub {
            my $h = HTTP::Headers->new(%source);
            $h->scan(sub { }) for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new(%source);
            $f->scan(sub { }) for 1 .. 1e4;
        },
    },

    get_header => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->header('Content-Length') for 1 .. 3e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->header('Content-Length') for 1 .. 3e4;
        },
    },

    set_header => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->header('Content-Length' => 100) for 1 .. 3e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->header('Content-Length' => 100) for 1 .. 3e4;
        },
    },

    get_content_length => {
        orig => sub {
            my $h = HTTP::Headers->new;
            $h->content_length for 1 .. 3e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new;
            $f->content_length for 1 .. 3e4;
        },
    },

    as_string_without_sort => {
        orig => sub {
            my $h = HTTP::Headers->new(%source);
            $h->as_string for 1 .. 1e4;
        },

        fast_as_str => sub {
            my $f = HTTP::Headers::Fast->new(%source);
            $f->as_string for 1 .. 1e4;
        },

        # fast_as_str_wo
        fast_as_str_wo => sub {
            my $f = HTTP::Headers::Fast->new(%source);
            $f->as_string_without_sort for 1 .. 1e4;
        },
    },

    as_string => {
        orig => sub {
            my $h = HTTP::Headers->new(%source);
            $h->as_string for 1 .. 1e4;
        },

        fast => sub {
            my $f = HTTP::Headers::Fast->new(%source);
            $f->as_string for 1 .. 1e4;
        },
    },
);

my ($verbose);
GetOptions( 'verbose|v' => \$verbose );

$verbose and print "* Running Pure-Perl benchmarks...\n";

my %instances;
foreach my $name ( keys %cases ) {
    my $case_cbs = $cases{$name};

    @ARGV and ( List::Util::any { $name eq $_ } @ARGV or next );

    $verbose and print "  - $name... ";

    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 20,
    );

    $bench->add_instances(
        Dumbbench::Instance::PerlSub->new(
            name => $_,
            code => $case_cbs->{$_},
        )
    ) for sort keys %{$case_cbs};

    $bench->run;
    $instances{$name} = [$bench->instances];
    $verbose and print "done\n";
}

$verbose and print "\n";

require HTTP::Headers::Fast::XS;
print "HTTP::Headers $HTTP::Headers::VERSION, "
    . "HTTP::Headers::Fast $HTTP::Headers::Fast::VERSION, "
    . "HTTP::Headers::Fast::XS $HTTP::Headers::Fast::XS::VERSION\n";

foreach my $name ( sort keys %instances ) {
    my @cb_names = sort keys %{ $cases{$name} };

    # add XS implementation
    my $bench = Dumbbench->new(
        target_rel_precision => 0.005,
        initial_runs         => 20,
    );

    $bench->add_instances(
        Dumbbench::Instance::PerlSub->new(
            name => "${_}_xs",
            code => $cases{$name}{$_},
        )
    ) for grep m{^fast}, @cb_names;

    $bench->run;

    unshift @{ $instances{$name} }, $bench->instances;

    my @instances = @{ $instances{$name} };
    my @col_names = map $_->{'name'}, @instances;
    print "-- $name\n";

    my $table = Text::Table->new( 'Implementation', 'Time', @col_names );
    foreach my $idx ( 0 .. $#instances ) {
        my $my_cb_name = $instances[$idx]{'name'};
        my $my_cb_num  = $instances[$idx]{'result'}{'num'};
        my @items      = ( $my_cb_name, $my_cb_num );

        foreach my $cmp_idx ( 0 .. $#instances ) {
            my $cmp_cb_name = $instances[$cmp_idx]{'name'};
            my $cmp_cb_num  = $instances[$cmp_idx]{'result'}{'num'};

            push @items, $my_cb_name eq $cmp_cb_name
                       ? '--'
                       : sprintf "%.2f%%\n",
                        (
                           $my_cb_num <= $cmp_cb_num
                           ? 100 - $my_cb_num / $cmp_cb_num * 100
                           : $cmp_cb_num / $my_cb_num * -100
                        );
        }

        $table->load([@items]);
    }

    print $table;
    print "\n";
}
