package Dezi::CLI;
use Moose;
with 'MooseX::Getopt';

use Types::Standard qw(:all);
use Data::Dump qw( dump );
use Carp;
use Search::Tools::UTF8;
use DateTime::Format::DateParse;
use Time::HiRes;
use Try::Tiny;
use Dezi::App;
use Dezi::InvIndex;

our $VERSION = '0.014';

our $CLI_NAME = 'deziapp';

has 'aggregator' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['S'],
    default     => sub {'fs'},
);
has 'aggregator_opts' => (
    is          => 'rw',
    isa         => HashRef,
    traits      => ['Getopt'],
    cmd_aliases => ['A'],
    default     => sub { {} },
);
has 'begin' => (
    is          => 'rw',
    isa         => Int,
    traits      => ['Getopt'],
    cmd_aliases => ['b'],
    default     => sub {0}
);
has 'config' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['c'],
);

has 'debug' => (
    is          => 'rw',
    isa         => Bool,
    traits      => ['Getopt'],
    cmd_aliases => ['D'],
    lazy        => 1,
    builder     => '_init_debug',
);
sub _init_debug { $ENV{DEZI_DEBUG} || 0 }
has 'expected' => (
    is          => 'rw',
    isa         => Maybe [Int],
    traits      => ['Getopt'],
    cmd_aliases => ['E'],
);
has 'extended_output' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['x'],
);
has 'filter' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['doc_filter'],
);
has 'format' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['F'],
    default     => sub {'lucy'},
);
has 'headers' => (
    is          => 'rw',
    isa         => Int,
    traits      => ['Getopt'],
    cmd_aliases => ['H'],
    lazy        => 1,
    default     => sub {1}
);
has 'index_mode' => (
    is          => 'rw',
    isa         => Bool,
    traits      => ['Getopt'],
    cmd_aliases => ['i'],
);
has 'indexer_opts' => (
    is          => 'rw',
    isa         => HashRef,
    traits      => ['Getopt'],
    cmd_aliases => ['I'],
    default     => sub { {} },
);
has 'inputs' => (
    is  => 'rw',
    isa => ArrayRef,
);
has 'invindex' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['f'],
    default     => sub {$Dezi::InvIndex::DEFAULT_NAME},
);
has 'limits' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['L'],
);
has 'links' => (
    is          => 'rw',
    isa         => Bool,
    traits      => ['Getopt'],
    cmd_aliases => [ 'l', 'follow_symlinks' ],
);
has 'max' => (
    is          => 'rw',
    isa         => Int,
    traits      => ['Getopt'],
    cmd_aliases => ['m'],
);
has 'newer_than' => (
    is          => 'rw',
    isa         => Maybe [Str],
    traits      => ['Getopt'],
    cmd_aliases => ['N'],
);
has 'null_term' => (
    is          => 'rw',
    isa         => Bool,
    traits      => ['Getopt'],
    cmd_aliases => ['n'],
);
has 'query' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => [ 'q', 'w', ],
);
has 'sort_order' => (
    is          => 'rw',
    isa         => Str,
    traits      => ['Getopt'],
    cmd_aliases => ['s'],
    default     => sub {''},
);
has 'verbose' => (
    is          => 'rw',
    isa         => Maybe [Int],
    traits      => ['Getopt'],
    cmd_aliases => ['v'],
);
has 'version' => (
    is          => 'rw',
    isa         => Bool,
    traits      => ['Getopt'],
    cmd_aliases => ['V'],
);
has 'warnings' => (
    is          => 'rw',
    isa         => Int,
    traits      => ['Getopt'],
    cmd_aliases => ['W'],
    lazy        => 1,
    default     => sub {2},
);

=head2 run

Main method. Calls commands passed via @ARGV.

=cut

sub _getopt_full_usage {
    my ( $self, $usage ) = @_;
    $usage->die( { post_text => $self->_commands } );
}

sub _usage_format {
    return "usage: %c command %o";
}

sub run {
    my $self = shift;

    $self->debug and dump $self;

    if ( $self->version ) {
        printf( "%s %s\n", $CLI_NAME, $VERSION );
        exit(0);
    }

    my @cmds = @{ $self->extra_argv };

    # compat with swish3 which used @argv to store
    # input files/dirs for -i (index) command
    # and -q to indicate 'search' mode
    if ( !$self->inputs ) {
        if ( $self->index_mode ) {
            $self->inputs( [@cmds] );
            @cmds = ('index');
        }
        elsif ( grep { $_ eq 'index' } @cmds ) {
            $self->inputs( [ grep { $_ ne 'index' } @cmds ] );
            @cmds = ('index');
        }
    }
    if ( $self->query ) {
        @cmds = ('search');
    }

    if ( !@cmds or $self->help_flag ) {
        $self->usage->die( { post_text => $self->_commands } );
    }

    for my $cmd (@cmds) {
        if ( !$self->can($cmd) ) {
            warn "No such command $cmd\n";
            $self->usage->die();
        }
        $self->$cmd();
    }

}

sub search {
    my $self  = shift;
    my $query = $self->query;
    if ( !defined $query ) {
        confess "query required to search";
    }
    my $invindex   = Dezi::InvIndex->new( path => $self->invindex );
    my $searcher   = $self->_get_searcher($invindex);
    my $start_time = Time::HiRes::time();
    my $results    = try {
        $searcher->search(
            to_utf8($query),
            {   start => $self->begin,
                max   => $self->max || undef,
                limit => _parse_limits( $self->limits ),
                order => $self->sort_order,
            }
        );
    }
    catch {
        my $errmsg = "$_";
        $errmsg =~ s/ at \/[\w\/\.]+ line \d+\.?.*$//s;
        die "Error: $errmsg\n";
    };
    $self->_display_results(
        results    => $results,
        start_time => $start_time,
        invindex   => $invindex,
    );
}

sub _get_searcher {
    my $self      = shift;
    my $invindex  = shift or confess "invindex required";
    my $invheader = $self->{__invheader} ||= $invindex->get_header();
    my $format    = $invheader->Index->{Format};
    my $sclass    = "Dezi::${format}::Searcher";
    Class::Load::load_class($sclass);
    my %qp_config = (
        dialect          => $format,
        query_class_opts => { debug => $self->debug }
    );
    if ( $self->null_term ) {
        $qp_config{null_term} = 'NULL';
    }
    my $searcher = $sclass->new(
        invindex  => $invindex,
        qp_config => \%qp_config,
        debug     => $self->debug,
    );
    return $searcher;
}

sub _display_results {
    my ( $self, %arg ) = @_;
    my $start_time = $arg{start_time} || 0;
    my $results  = $arg{results}  or confess "results required";
    my $invindex = $arg{invindex} or confess "invindex object required";

    my $invheader   = $self->{__invheader} ||= $invindex->get_header();
    my $format      = $invheader->Index->{Format};
    my $propnames   = $invheader->PropertyNames;
    my $search_time = Time::HiRes::time() - $start_time;

    if ( $self->headers ) {
        printf( "# $CLI_NAME version %s\n", $VERSION );
        printf( "# Format: %s\n",           $self->format );
        printf( "# Query: %s\n",            to_utf8( $self->query ) );
        printf( "# Hits: %d\n",             $results->hits );
        printf( "# Search time: %.4f\n",    $search_time );
    }

    if ( $self->headers > 1 ) {
        printf( "# Parsed Query: %s\n", $results->query );
    }

    my ( $output_format, $output_format_str );

    if ( $self->extended_output ) {
        my @props;
        my $default_properties = SWISH::3::SWISH_DOC_PROP_MAP();
        my $template           = $self->extended_output;
        while ( $template =~ m/<(.+?)>/g ) {
            my $p = $1;
            if (    !exists $propnames->{$p}
                and !exists $default_properties->{$p}
                and $p ne 'swishtitle'
                and $p ne 'swishdescription'
                and $p ne 'swishrank' )
            {
                die "Invalid PropertyName: $p\n";
            }
            else {
                push @props, $p;
            }
        }
        $output_format_str = $template;
        for my $prop (@props) {
            $output_format_str =~ s/<$prop>/\%s/g;    # TODO ints and dates
        }

        # make escaped chars work
        $output_format_str =~ s/\\n/\n/g;
        $output_format_str =~ s/\\t/\t/g;
        $output_format_str =~ s/\\r/\r/g;

        $output_format = \@props;

        #warn "str: $output_format_str\n";
        #warn dump $output_format;
    }

    my $counter = 0;
    while ( my $result = $results->next ) {
        if ($output_format) {
            my @res;
            for my $prop (@$output_format) {
                my $val;
                if ( $prop eq 'swishrank' ) {
                    $val = $result->score;
                }
                else {
                    $val = $result->get_property($prop);
                }
                $val = '' unless defined $val;
                $val =~ s/\003/\\x{03}/g;
                push( @res, to_utf8($val) );
            }
            printf( $output_format_str, @res );
        }
        else {
            printf( qq{%4d %s "%s"\n},
                $result->score, $result->uri, $result->title );
        }
        if ( $self->max ) {
            last if ++$counter >= $self->max;
        }
    }
    print ".\n";
}

sub _get_app {
    my $self = shift;

    # libswish3 parser warnings depend on this env var
    # and not the warnings param to App->new.
    if ( !exists $ENV{SWISH_WARNINGS} ) {
        $ENV{SWISH_WARNINGS}        = $self->warnings;
        $ENV{SWISH_PARSER_WARNINGS} = $self->warnings;
    }
    my %app_args = (
        invindex        => $self->invindex,
        indexer         => $self->format,
        indexer_opts    => $self->indexer_opts,
        aggregator      => $self->aggregator,
        aggregator_opts => $self->aggregator_opts,
        debug           => $self->debug,
        verbose         => $self->verbose,
        warnings        => $self->warnings,          # TODO supported?
    );
    $app_args{filter} = $self->filter if $self->filter;
    $app_args{config} = $self->config if $self->config;

    my $app = Dezi::App->new(%app_args);

    # set some optional flags
    if ( defined $self->newer_than ) {

        if ( !length $self->newer_than ) {
            $self->newer_than(
                $app->indexer->invindex->path->file('swish_last_start') );
        }

        # if it's a file, stat it,
        # otherwise convert to timestamp
        my $ts;
        my $dt = DateTime::Format::DateParse->parse_datetime(
            $self->newer_than );
        if ( !defined $dt ) {
            my $stat = [ stat( $self->newer_than ) ];
            if ( !defined $stat->[9] ) {
                confess
                    "-N option must be a valid date string or a readable file: $!";
            }
            $ts = $stat->[9];
        }
        else {
            $ts = $dt->epoch;
        }
        $app->aggregator->set_ok_if_newer_than($ts);
        $self->verbose
            and printf "Skipping documents older than %s\n",
            scalar localtime($ts);

    }
    if ( $self->links and $self->aggregator eq 'fs' ) {
        $app->aggregator->config->FollowSymLinks(1);
    }
    if ( $self->expected ) {
        $app->aggregator->progress( _progress_bar( $self->expected ) );
    }

    return $app;
}

sub index {
    my $self   = shift;
    my $inputs = $self->inputs
        or confess "Must define inputs in order to index";
    my $app      = $self->_get_app;
    my $start    = time();
    my $num_docs = $app->run(@$inputs);
    my $end      = time();
    my $elapsed  = $end - $start;
    printf(
        "%d document%s in %s\n",
        ( $num_docs || 0 ),
        ( $num_docs == 1 ? '' : 's' ),
        _secs2hms($elapsed)
    );
    return $num_docs;
}

sub delete {

}

sub merge {

}

sub _commands {
    my $self  = shift;
    my $usage = <<EOF;
 synopsis:
    $CLI_NAME [-E N] [-i dir file ... ] [-S aggregator] [-c file] [-f invindex] [-l] [-v (num)] [-I name=val]
    $CLI_NAME -q 'word1 word2 ...' [-f file1 file2 ...] 
          [-s sortprop1 [asc|desc] ...] 
          [-H num]
          [-m num] 
          [-x output_format] 
          [-L prop low high]
    $CLI_NAME -N path/to/compare/file or date
    $CLI_NAME -V
    $CLI_NAME -h
    $CLI_NAME -D n

 options: defaults are in brackets
 # commented options are not yet supported

 indexing options:
    -A : name=value passed directly to Aggregator
    -c : configuration file
    -D : Debug mode
   --doc_filter : doc_filter
    -E : next param is total expected files (generates progress bar)
    -f : invindex dir to create or search from [$Dezi::InvIndex::DEFAULT_NAME]
    -F : next param is invindex format (lucy, xapian, or dbi) [lucy]
    -h : print this usage statement
    -i : create an index from the specified files
        for "-S fs" - specify a list of files or directories
        for "-S spider" - specify a list of URLs
    -I : name=value passed directly to Indexer
    -l : follow symbolic links when indexing
    -N : index only files with a modification date newer than path or date
         if no argument, defaults to [indexdir/swish_last_start]
    -S : specify which aggregator to use.
        Valid options are:
         "fs" - local files in your File System
         "spider" - web site files using a web crawler
        The default value is: "fs"
    -v : indexing verbosity level (0 to 3) [-v 1]
    -W : next param is ParserWarnLevel [-W 2]

 search options:
    -b : begin results at this number
    -f : invindex dir to create or search from [$Dezi::InvIndex::DEFAULT_NAME]
    -F : next param is invindex format (ks, lucy, xapian, native, or dbi) [native]
    -h : print this usage statement
    -H : "Result Header Output": verbosity (0 to 9)  [1].
    -L : Limit results to a range of property values
    -m : the maximum number of results to return [defaults to all results]
    -n : query parser special NULL term
    -R : next param is Rank Scheme number (0 to 1)  [0].
    -s : sort by these document properties in the output "prop1 prop2 ..."
    -V : prints the current version
    -v : indexing verbosity level (0 to 3) [-v 1]
    -w : search for words "word1 word2 ..."
    -x : "Extended Output Format": Specify the output format.

             version : $VERSION
  Dezi::App::VERSION : $Dezi::App::VERSION
                docs : http://dezi.org/

EOF
    return $usage;
}

# Functions
sub _secs2hms {
    my $secs  = shift || 0;
    my $hours = int( $secs / 3600 );
    my $rm    = $secs % 3600;
    my $min   = int( $rm / 60 );
    my $sec   = $rm % 60;
    return sprintf( "%02d:%02d:%02d", $hours, $min, $sec );
}

sub _parse_limits {
    my $limits = shift or return [];
    if ( !@$limits ) {
        return $limits;
    }
    my @parsed;
    for my $lim (@$limits) {
        push @parsed, [ split( /\s+/, $lim ) ];
    }
    return \@parsed;

}

sub _progress_bar {
    require Term::ProgressBar;
    my $total = shift;
    my $tpb   = Term::ProgressBar->new(
        {   ETA   => 'linear',
            name  => 'swish3',
            count => $total,
        }
    );
    return $tpb;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Dezi::CLI - command-line interface to Dezi::App

=head1 SYNOPSIS

 use Dezi::CLI;
 my $app = Dezi::CLI->new_with_options();
 $app->run();

=head1 DESCRIPTION

The Dezi::CLI class is a port of the B<swish3> tool to a proper class,
using L<MooseX::Getopt>.

=head1 METHODS

=head2 index

Run the CLI in indexing mode.

=head2 search

Run the CLI in searching mode.

=head2 merge

B<NOT YET IMPLEMENTED> merge 2 or more indexes together.

=head2 delete

B<NOT YET IMPLEMENTED> delete or more URIs from an index.

=head1 AUTHOR

Peter Karman, E<lt>karpet@dezi.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-App>.  
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::CLI

You can also look for information at:

=over 4

=item * Website

L<http://dezi.org/>

=item * IRC

#dezisearch at freenode

=item * Mailing list

L<https://groups.google.com/forum/#!forum/dezi-search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-App>

=item * Search CPAN

L<https://metacpan.org/dist/Dezi-App/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL v2 or later.

=head1 SEE ALSO

L<http://dezi.org/>, L<http://swish-e.org/>, L<http://lucy.apache.org/>
