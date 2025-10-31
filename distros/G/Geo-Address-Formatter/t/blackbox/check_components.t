use strict;
use warnings;
use lib 'lib';
use feature qw(say);
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use File::Basename;
use File::Find::Rule;
use File::Slurper 'read_text';
use File::Spec;
use Getopt::Long;
use Test::Exception;
use Test::More;
use YAML::XS qw(LoadFile);
use utf8;
use feature "unicode_strings";

# nicer output for diag and failures, see
# http://perldoc.perl.org/Test/More.html#CAVEATS-and-NOTES
my $builder = Test::More->builder;
binmode $builder->output,         ":encoding(UTF-8)";
binmode $builder->failure_output, ":encoding(UTF-8)";
binmode $builder->todo_output,    ":encoding(UTF-8)";

my $af_path = dirname(__FILE__) . '/../../address-formatting';

my $compfile = $af_path . '/conf/components.yaml';
my $verbose = 0;

GetOptions(
    'verbose'   => \$verbose,
);

ok(1);

if (-e $compfile) {
    
    note("found components: $compfile");
    ok(1, 'found components yaml file');
    #my $text = read_text($compfile);
    #say STDERR $text;

    # go through the components file
    # make a list of all components and aliases
    my %found_components;
    
    my @comps = LoadFile($compfile);
    foreach my $rh_comp (@comps){
        foreach my $k (keys %$rh_comp){
            if ($k eq 'name'){
                $found_components{$rh_comp->{name}}++;
            }
            elsif ($k eq 'aliases'){
                my $ra_aliases = $rh_comp->{aliases};
                foreach my $alias (@$ra_aliases){
                    $found_components{$alias}++;
                }
            }
        }
    }

    # did we have any more than once?
    foreach my $c (keys %found_components){
        ok($found_components{$c} == 1, "only found $c once");
    }
    #say STDERR Dumper \@comps;
}

done_testing();

1;
