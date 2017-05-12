#!/usr/bin/perl

# Typical example of using the module in a presentation...

use Lingua::LinkParser;

{
    local $| = 1;
    print "loading analyser...";
    $parser = new Lingua::LinkParser;
    print "done\n";
}

use IO::Prompt;

$parser->opts(
    'verbosity'           => 0,
    'max_sentence_length' => 70,
    'panic_mode'          => 1,
    'max_parse_time'      => 30,
    'linkage_limit'       => 1000,
    'short_length'        => 10,
    'disjunct_cost'       => 2,
    'min_null_count'      => 0,
    'max_null_count'      => 0,
);

while (prompt "> ", -clearfirst) {
    my $sentence = $parser->create_sentence($_);

    if ($sentence->num_linkages == 0) {
        $parser->opts(
            'min_null_count' => 1,
            'max_null_count' => $sentence->length
        );

        $sentence = $parser->create_sentence($_);
        if ($sentence->num_linkages == 0) {
            $parser->opts(
                'disjunct_cost'        => 3,
                'min_null_count'       => 1,
                'max_null_count'       => 30,
                'max_parse_time'       => 60,
                'islands_ok'           => 1,
                'short_length'         => 6,
                'all_short_connectors' => 1,
                'linkage_limit'        => 100
            );
            my $sentence = $parser->create_sentence($_);
        }
    }

    for $i (1 .. $sentence->num_linkages) {
        $linkage = $sentence->linkage($i);
        $linkage->compute_union;
        $sublinkage = $linkage->sublinkage($linkage->num_sublinkages);
        print $parser->get_diagram($sublinkage), "\n";
    }
}

__DATA__ 
__PROMPT__
The issue of gene patents is a vexing one
Patents on genes are a vexed issue
Gene patenting is an issue that vexes     
The vexacious issue is patented genes
Patentable genes vex the issue
Time flies like an arrow
