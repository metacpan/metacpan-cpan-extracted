package GraphQL::Client::CLI;
# ABSTRACT: Implementation of the graphql CLI program

use warnings;
use strict;

use Encode qw(decode);
use Getopt::Long 2.39 qw(GetOptionsFromArray);
use GraphQL::Client;
use JSON::MaybeXS;
use Text::ParseWords;
use namespace::clean;

our $VERSION = '0.605'; # VERSION

my $JSON = JSON::MaybeXS->new(canonical => 1);

sub _croak { require Carp; goto &Carp::croak }

sub new {
    my $class = shift;
    bless {}, $class;
}

sub main {
    my $self = shift;
    $self = $self->new if !ref $self;

    my $options = eval { $self->_get_options(@_) };
    if (my $err = $@) {
        print STDERR $err;
        _pod2usage(2);
    }

    if ($options->{version}) {
        print "graphql $VERSION\n";
        exit 0;
    }
    if ($options->{help}) {
        _pod2usage(-exitval => 0, -verbose => 99, -sections => [qw(NAME SYNOPSIS OPTIONS)]);
    }
    if ($options->{manual}) {
        _pod2usage(-exitval => 0, -verbose => 2);
    }

    my $url = $options->{url};
    if (!$url) {
        print STDERR "The <URL> or --url option argument is required.\n";
        _pod2usage(2);
    }

    my $variables = $options->{variables};
    my $query = $options->{query};
    my $operation_name = $options->{operation_name};
    my $unpack = $options->{unpack};
    my $outfile = $options->{outfile};
    my $format = $options->{format};
    my $transport = $options->{transport};

    my $client = GraphQL::Client->new(url => $url);

    eval { $client->transport };
    if (my $err = $@) {
        warn $err if $ENV{GRAPHQL_CLIENT_DEBUG};
        print STDERR "Could not construct a transport for URL: $url\n";
        print STDERR "Is this URL correct?\n";
        _pod2usage(2);
    }

    if ($query eq '-') {
        print STDERR "Interactive mode engaged! Waiting for a query on <STDIN>...\n"
            if -t STDIN; ## no critic (InputOutput::ProhibitInteractiveTest)
        binmode(STDIN, 'encoding(UTF-8)');
        $query = do { local $/; <STDIN> };
    }

    my $resp = $client->execute($query, $variables, $operation_name, $transport);
    my $err  = $resp->{errors};
    $unpack = 0 if $err;
    my $data = $unpack ? $resp->{data} : $resp;

    if ($outfile) {
        open(my $out, '>', $outfile) or die "Open $outfile failed: $!";
        *STDOUT = $out;
    }

    if (my $filter = $options->{filter}) {
        eval { require JSON::Path::Evaluator } or die "Missing dependency: JSON::Path\n";
        my @values = JSON::Path::Evaluator::evaluate_jsonpath($data, $filter);
        if (@values == 1) {
            $data = $values[0];
        }
        else {
            $data = \@values;
        }
    }

    binmode(STDOUT, 'encoding(UTF-8)');
    _print_data($data, $format);

    exit($unpack && $err ? 1 : 0);
}

sub _get_options {
    my $self = shift;
    my @args = @_;

    unshift @args, shellwords($ENV{GRAPHQL_CLIENT_OPTIONS} || '');

    # assume UTF-8 args if non-ASCII
    @args = map { decode('UTF-8', $_) } @args if grep { /\P{ASCII}/ } @args;

    my %options = (
        format  => 'json:pretty',
        unpack  => 0,
    );

    GetOptionsFromArray(\@args,
        'version'               => \$options{version},
        'help|h|?'              => \$options{help},
        'manual|man'            => \$options{manual},
        'url|u=s'               => \$options{url},
        'query|mutation=s'      => \$options{query},
        'variables|vars|V=s'    => \$options{variables},
        'variable|var|d=s%'     => \$options{variables},
        'operation-name|n=s'    => \$options{operation_name},
        'transport|t=s%'        => \$options{transport},
        'format|f=s'            => \$options{format},
        'filter|p=s'            => \$options{filter},
        'unpack!'               => \$options{unpack},
        'output|o=s'            => \$options{outfile},
    ) or _pod2usage(2);

    $options{url}   = shift @args if !$options{url};
    $options{query} = shift @args if !$options{query};

    $options{query} ||= '-';

    my $transport = eval { _expand_vars($options{transport}) };
    die "Two or more --transport keys are incompatible.\n" if $@;
    $options{transport} = $transport if ref $transport eq 'HASH' && %$transport;

    if (ref $options{variables}) {
        $options{variables} = eval { _expand_vars($options{variables}) };
        die "Two or more --variable keys are incompatible.\n" if $@;
    }
    elsif ($options{variables}) {
        $options{variables} = eval { $JSON->decode($options{variables}) };
        die "The --variables JSON does not parse.\n" if $@;
    }

    return \%options;
}

sub _stringify {
    my ($item) = @_;
    if (ref($item) eq 'ARRAY') {
        my $first = @$item && $item->[0];
        return join(',', @$item) if !ref($first);
        return join(',', map { $JSON->encode($_) } @$item);
    }
    return $JSON->encode($item) if ref($item) eq 'HASH';
    return $item;
}

sub _print_data {
    my ($data, $format) = @_;
    $format = lc($format || 'json:pretty');
    if ($format eq 'json' || $format eq 'json:pretty') {
        my %opts = (allow_nonref => 1, canonical => 1);
        $opts{pretty} = 1 if $format eq 'json:pretty';
        print JSON::MaybeXS->new(%opts)->encode($data);
    }
    elsif ($format eq 'yaml') {
        eval { require YAML } or die "Missing dependency: YAML\n";
        print YAML::Dump($data);
    }
    elsif ($format eq 'csv' || $format eq 'tsv' || $format eq 'table') {
        my $sep = $format eq 'tsv' ? "\t" : ',';

        my $unpacked = $data;
        # $unpacked = $data->{data} if !$unpack && !$err;
        $unpacked = $data->{data} if ref $data eq 'HASH' && $data->{data};

        # check the response to see if it can be formatted
        my @columns;
        my $rows = [];
        if (ref $unpacked eq 'HASH') {
            if (keys %$unpacked == 1) {
                my ($val) = values %$unpacked;
                if (ref $val eq 'ARRAY') {
                    my $first = $val->[0];
                    if ($first && ref $first eq 'HASH') {
                        @columns = sort keys %$first;
                        $rows = [
                            map { [map { _stringify($_) } @{$_}{@columns}] } @$val
                        ];
                    }
                    elsif ($first) {
                        @columns = keys %$unpacked;
                        $rows = [map { [map { _stringify($_) } $_] } @$val];
                    }
                }
            }
        }
        elsif (ref $unpacked eq 'ARRAY') {
            my $first = $unpacked->[0];
            if ($first && ref $first eq 'HASH') {
                @columns = sort keys %$first;
                $rows = [
                    map { [map { _stringify($_) } @{$_}{@columns}] } @$unpacked
                ];
            }
            elsif ($first) {
                @columns = qw(column);
                $rows = [map { [map { _stringify($_) } $_] } @$unpacked];
            }
        }

        if (@columns) {
            if ($format eq 'table') {
                eval { require Text::Table::Any } or die "Missing dependency: Text::Table::Any\n";
                my $table = Text::Table::Any::table(
                    header_row  => 1,
                    rows        => [[@columns], @$rows],
                    backend     => $ENV{PERL_TEXT_TABLE},
                );
                print $table;
            }
            else {
                eval { require Text::CSV } or die "Missing dependency: Text::CSV\n";
                my $csv = Text::CSV->new({binary => 1, sep => $sep, eol => $/});
                $csv->print(*STDOUT, [@columns]);
                for my $row (@$rows) {
                    $csv->print(*STDOUT, $row);
                }
            }
        }
        else {
            _print_data($data);
            print STDERR sprintf("Error: Response could not be formatted as %s.\n", uc($format));
            exit 3;
        }
    }
    elsif ($format eq 'string') {
        if (!ref $data) {
            print $data, "\n";
        }
        elsif (ref $data eq 'ARRAY') {
            print join("\n", @$data);
        }
        else {
            _print_data($data);
            print STDERR sprintf("Error: Response could not be formatted as %s.\n", $format);
            exit 3;
        }
    }
    elsif ($format eq 'perl') {
        eval { require Data::Dumper } or die "Missing dependency: Data::Dumper\n";
        print Data::Dumper::Dumper($data);
    }
    else {
        _print_data($data);
        print STDERR "Error: Format not supported: $format\n";
        exit 3;
    }
}

sub _parse_path {
    my $path = shift;

    my @path;

    my @segments = map { split(/\./, $_) } split(/(\[[^\.\]]+\])\.?/, $path);
    for my $segment (@segments) {
        if ($segment =~ /\[([^\.\]]+)\]/) {
            $path[-1]{type} = 'ARRAY' if @path;
            push @path, {
                name  => $1,
                index => 1,
            };
        }
        else {
            $path[-1]{type} = 'HASH' if @path;
            push @path, {
                name => $segment,
            };
        }
    }

    return \@path;
}

sub _expand_vars {
    my $vars = shift;

    my $root = {};

    while (my ($key, $value) = each %$vars) {
        my $parsed_path = _parse_path($key);

        my $curr = $root;
        for my $segment (@$parsed_path) {
            my $name = $segment->{name};
            my $type = $segment->{type} || '';
            my $next = $type eq 'HASH' ? {} : $type eq 'ARRAY' ? [] : $value;
            if (ref $curr eq 'HASH') {
                _croak 'Conflicting keys' if $segment->{index};
                if (defined $curr->{$name}) {
                    _croak 'Conflicting keys' if $type ne ref $curr->{$name};
                    $next = $curr->{$name};
                }
                else {
                    $curr->{$name} = $next;
                }
            }
            elsif (ref $curr eq 'ARRAY') {
                _croak 'Conflicting keys' if !$segment->{index};
                if (defined $curr->[$name]) {
                    _croak 'Conflicting keys' if $type ne ref $curr->[$name];
                    $next = $curr->[$name];
                }
                else {
                    $curr->[$name] = $next;
                }
            }
            else {
                _croak 'Conflicting keys';
            }
            $curr = $next;
        }
    }

    return $root;
}

sub _pod2usage {
    eval { require Pod::Usage };
    if ($@) {
        my $ref  = $VERSION eq '999.999' ? 'master' : "v$VERSION";
        my $exit = (@_ == 1 && $_[0] =~ /^\d+$/ && $_[0]) //
                   (@_ % 2 == 0 && {@_}->{'-exitval'})    // 2;
        print STDERR <<END;
Online documentation is available at:

  https://github.com/chazmcgarvey/graphql-client/blob/$ref/README.md

Tip: To enable inline documentation, install the Pod::Usage module.

END
        exit $exit;
    }
    else {
        goto &Pod::Usage::pod2usage;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GraphQL::Client::CLI - Implementation of the graphql CLI program

=head1 VERSION

version 0.605

=head1 DESCRIPTION

This is the actual implementation of L<graphql>.

The interface is B<EXPERIMENTAL>. Don't rely on it.

=head1 METHODS

=head2 new

Construct a new CLI.

=head2 main

Run the script.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/graphql-client/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
