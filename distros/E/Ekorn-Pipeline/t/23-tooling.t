use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Ekorn::Pipeline::Tooling: every name a caller uses to do work, from one
# module, by tags that follow the modules that make them (roadmap
# 2026-0031).

use Ekorn::Pipeline;
use Ekorn::Pipeline::Tooling ();

my $tooling = 'Ekorn::Pipeline::Tooling';

# Each tag that follows a module, and the module.
my %module = (
    core    => [qw(Ekorn::Pipeline::Stop Ekorn::Pipeline::Gather)],
    flow    => ['Ekorn::Pipeline::Stages::Flow'],
    batch   => ['Ekorn::Pipeline::Stages::Batch'],
    taps    => ['Ekorn::Pipeline::Stages::Taps'],
    sources => ['Ekorn::Pipeline::Sources'],
    sinks   => ['Ekorn::Pipeline::Sinks'],
    json    => ['Ekorn::Pipeline::JSON'],
    words   => ['Ekorn::Pipeline::Factories'],
);


# The names a module exports, by default or on request, sorted.
sub exported_by ($module) {
    no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
    my %names = map { $_ => 1 } @{ "${module}::EXPORT" },
        @{ "${module}::EXPORT_OK" };
    my @sorted = sort keys %names;
    return @sorted;
}


sub tag ($name) {
    no warnings 'once';
    return [sort @{ $Ekorn::Pipeline::Tooling::EXPORT_TAGS{$name} }];
}

subtest 'each tag holds every name its modules export' => sub {
    for my $tag (sort keys %module) {
        is tag($tag), [sort map { exported_by($_) } @{ $module{$tag} }], ":$tag";
    }
};

subtest ':stages is :flow, :batch and :taps' => sub {
    is tag('stages'), [sort map { @{ tag($_) } } qw(flow batch taps)];
};

subtest ':all is every tag, each name once' => sub {
    my %every = map { $_ => 1 } map { @{ tag($_) } } keys %module;
    is tag('all'), [sort keys %every];
    is [exported_by($tooling)], [sort keys %every], 'and is what it exports';
};

subtest 'not for callers: is_stage, is_sink and croakf' => sub {
    my %all = map { $_ => 1 } @{ tag('all') };
    ok !$all{$_}, "no $_" for qw(is_stage is_sink croakf);
};

subtest 'nothing by default' => sub {

    package Tooling::Nothing {
        use Ekorn::Pipeline::Tooling;
    }
    ok !Tooling::Nothing->can($_), "no $_" for @{ tag('all') };
};

subtest "each name is its own module's sub" => sub {
    for my $tag (sort keys %module) {
        for my $module (@{ $module{$tag} }) {
            for my $name (exported_by($module)) {
                ref_is $tooling->can($name), $module->can($name), "$name, from $module";
            }
        }
    }
};

subtest 'a tag imports its names, prototypes and all' => sub {

    package Tooling::Some {
        use Ekorn::Pipeline::Tooling qw(:flow :sinks);


        sub first_big (@values) {
            return Ekorn::Pipeline->new(take_if { $_ > 2 }, keep_first)->(@values);
        }
    }
    is scalar Tooling::Some::first_big(1, 3, 5), 3;
    ok !Tooling::Some->can('from_file'), 'and only those';
};

subtest 'names can be asked for one by one' => sub {

    package Tooling::Named {
        use Ekorn::Pipeline::Tooling qw(stage keep_all);


        sub loud (@values) {
            return Ekorn::Pipeline->new(stage { uc }, keep_all)->(@values);
        }
    }
    is [Tooling::Named::loud(qw(a b))], [qw(A B)];
};

subtest ':all, its parts working together' => sub {

    package Tooling::All {
        use Ekorn::Pipeline::Tooling qw(:all);


        sub pairs () {
            my $p = Ekorn::Pipeline->new(drop_if { $_ % 2 }, batch(2), count_items);
            return scalar $p->iterator(from_array(1 .. 8))->();
        }
    }
    is Tooling::All::pairs(), 2;
};

subtest "| isn't in force, though Operators is loaded" => sub {

    package Tooling::NoOperators {
        use Ekorn::Pipeline::Tooling qw(:all);

        sub chained () { return from_array(1, 2) | count_items }
    }
    require Ekorn::Pipeline::Operators;
    like dies { Tooling::NoOperators::chained() },
        qr( \A Expected\ use\ Ekorn::Pipeline::Operators\ in\ scope )x;
};

subtest 'an unknown tag is reported by Exporter' => sub {
    my $died;
    my $warnings = warnings {
        $died = dies { Ekorn::Pipeline::Tooling->import(':nonesuch') }
    };
    like $warnings, [qr( "nonesuch"\ is\ not\ defined )x],
        'it warns of the tag';
    like $died, qr( \A Can't\ continue\ after\ import\ errors )x, 'and dies';
};

done_testing;
