#!perl 
use warnings;
use strict;

use Data::Dumper;
use Mock::Sub;
use Test::More tests => 151;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

eval {
    require Devel::Trace::Subs;
    import Devel::Trace::Subs qw(trace);
};

SKIP: {

    skip "Devel::Trace::Subs not installed... skipping", 11 if $@;

    $ENV{DES_TRACE} = 1;

    my $des = Devel::Examine::Subs->new(file => 't/sample.data');

    my $trace = trace();

    is (ref $trace, 'HASH', "stack trace is a hash ref");
    is (ref $trace->{flow}, 'ARRAY', "code flow is an array ref");
    is (ref $trace->{stack}, 'ARRAY', "stack is an array ref");

    is (scalar @{ $trace->{flow} }, 8, "code flow has the proper number of entries");
    is (scalar @{ $trace->{stack} }, 8, "stack has the proper number of entries");

    my @stack_items = keys %{ $trace->{stack}->[0] };

    is (@stack_items, 5, "stack trace entries have the proper number of headings");

    my %entries = map {$_ => 1} qw(in filename line package sub);
    
    for my $entry (@stack_items){
        ok ($entries{$entry}, "$entry is in stack trace headings");
    }
};
{
    no strict 'refs';
    $SIG{__WARN__} = sub {};

    $ENV{DES_TRACE} = 1;

    my $mods = _subs();

    my ($sub_count, $called_count);

    for my $file (sort { length($a) <=> length($b) } keys %{ $mods }){

       my $mock = Mock::Sub->new;
       my $trace = $mock->mock($file . "::trace");
       my $obj = $file->new;

        is ($trace->called, 1, "$file new calls trace()");
        
        for my $sub (@{ $mods->{$file} }){
            $sub_count++;
            $trace->reset;
            eval { $obj->$sub(); };
            is ($trace->called, 1, "$file $sub calls trace()");
            $called_count++ if $trace->called;
        }
    }
    is ($sub_count, $called_count, "all subs have a trace() call");
}
{
    no strict 'refs';

    $ENV{TRACE} = 1;

    my $trace_sub;
    my $mods = _subs();

    for my $file (sort { length($a) <=> length($b) } keys %{ $mods }) {

        $trace_sub = $file . "::trace";
        *$trace_sub = sub { die "exiting trace"; };

        my $obj;
        eval { $obj = $file->new; };
        like ($@, qr/exiting trace/, "trace did the right thing in $file new()");

        *$trace_sub = sub {};
        $obj = $file->new;
        *$trace_sub = sub { die "exiting trace"; };

        for my $sub (@{ $mods->{$file} }) {
            eval { $file->$sub; };
            like ($@, qr/exiting trace/, "trace did the right thing in $file $sub");
        }
    }

    *$trace_sub = sub {};
    $ENV{TRACE} = 0;
}

sub _subs {

 return {
          'Devel::Examine::Subs::Postprocessor' => [
                                                         'end_of_last_sub',
                                                         'exists',
                                                         '_dt',
                                                         'objects',
                                                         '_test',
                                                         'file_lines_contain',
                                                         'subs'
                                                       ],
          'Devel::Examine::Subs::Sub' => [
                                               'code',
                                               'name',
                                               'end',
                                               'start',
                                               'lines',
                                               'line_count'
                                             ],
          'Devel::Examine::Subs::Preprocessor' => [
                                                        'inject',
                                                        '_dt',
                                                        'exists',
                                                        'module',
                                                        'remove',
                                                        'replace'
                                                      ],
          'Devel::Examine::Subs::Engine' => [
                                                  'missing',
                                                  'lines',
                                                  '_test',
                                                  'has',
                                                  '_dt',
                                                  'all',
                                                  'objects',
                                                  'inject_after',
                                                  'search_replace',
                                                  'exists'
                                                ],
          'Devel::Examine::Subs' => [
                                           'has',
                                           '_clean_core_config',
                                           'pre_procs',
                                           'replace',
                                           '_config',
                                           '_read_file',
                                           'order',
                                           '_proc',
                                           'run',
                                           '_clean_config',
                                           '_cache_safe',
                                           '_cache_enabled',
                                           'missing',
                                           'lines',
                                           '_run_end',
                                           '_post_proc',
                                           'search_replace',
                                           'post_procs',
                                           'engines',
                                           'inject_after',
                                           'all',
                                           'add_functionality',
                                           '_core',
                                           'module',
                                           '_params',
                                           'valid_params',
                                           '_file',
                                           '_cache',
                                           'inject',
                                           '_run_directory',
                                           'remove',
                                           '_write_file',
                                           '_pre_proc',
                                           '_engine',
                                           'objects'
                                         ]
    };
}
