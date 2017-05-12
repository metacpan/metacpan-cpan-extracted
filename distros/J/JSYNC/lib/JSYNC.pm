use strict; use warnings;
package JSYNC;
our $VERSION = '0.25';

use JSON;

{
    package JSYNC;

    sub dump {
        my ($object, $config) = @_;
        $config ||= {};
        return JSYNC::Dumper->new(%$config)->dump($object);
    }

    sub load {
        my ($jsync) = @_;
        return JSYNC::Loader->new->load($jsync);
    }

    sub info {
        my ($kind, $id, $class);
        if (ref(\$_[0]) eq 'GLOB') {
            (\$_[0] . "") =~ /^(?:(.+)=)?(GLOB)\((0x.*)\)$/
                or die "Can't get info for '$_[0]'";
            ($kind, $id, $class) = ('glob', $3, $1 || '');
        }
        elsif (not ref($_[0])) {
            $kind = 'scalar';
        }
        else {
            "$_[0]" =~ /^(?:(.+)=)?(HASH|ARRAY)\((0x.*)\)$/
                or die "Can't get info for '$_[0]'";
            ($kind, $id, $class) =
                (($2 eq 'HASH' ? 'map' : 'seq'), $3, $1 || '');
        }
        return ($kind, $id, $class);
    }
};

{
    package JSYNC::Dumper;

    sub new { bless { @_[1..$#_] }, $_[0] }

    sub dump {
        my ($self, $object) = @_;
        $self->{anchor} = 1;
        $self->{seen} = {};
        my $graph = $self->represent($object);
        my $json = 'JSON'->new()->canonical();
        $json->pretty() if $self->{pretty};
        return $json->encode($graph);
    }

    sub represent {
        my ($self, $node) = @_;
        my $seen = $self->{seen};
        my $graph;
        my ($kind, $id, $class) = JSYNC::info($node);
        if ($kind eq 'scalar') {
            if (not defined $node) {
                return undef;
            }
            return $self->escape($node);
        }
        if (my $info = $seen->{$id}) {
            if (not $info->{anchor}) {
                $info->{anchor} = $self->{anchor}++ . "";
                if ($info->{kind} eq 'map') {
                    $info->{graph}{'&'} = $info->{anchor};
                }
                else {
                    unshift @{$info->{graph}}, '&' . $info->{anchor};
                }
            }
            return "*" . $info->{anchor};
        }
        my $tag = $self->resolve_to_tag($kind, $class);
        if ($kind eq 'seq') {
            $graph = [];
            $seen->{$id} = { graph => $graph, kind => $kind };
            @$graph = map { $self->represent($_) } @$node;
            if ($tag) {
                unshift @$graph, "!$tag";
            }
        }
        elsif ($kind eq 'map') {
            $graph = {};
            $seen->{$id} = { graph => $graph, kind => $kind };
            for my $k (keys %$node) {
                $graph->{$self->represent($k)} = $self->represent($node->{$k});
            }
            if ($tag) {
                $graph->{'!'} = $tag;
            }
        }
        # XXX glob should not be a kind.
        elsif ($kind eq 'glob') {
            $class ||= 'main';
            $graph = {};
            $graph->{PACKAGE} = $class;
            $graph->{'!'} = '!perl/glob:';
            for my $type (qw(PACKAGE NAME SCALAR ARRAY HASH CODE IO)) {
                my $value = *{$node}{$type};
                $value = $$value if $type eq 'SCALAR';
                if (defined $value) {
                    if ($type eq 'IO') {
                        my @stats = qw(device inode mode links uid gid rdev size
                                       atime mtime ctime blksize blocks);
                        undef $value;
                        $value->{stat} = {};
                        map {$value->{stat}{shift @stats} = $_} stat(*{$node});
                        $value->{fileno} = fileno(*{$node});
                        {
                            local $^W;
                            $value->{tell} = tell(*{$node});
                        }
                    }
                    $graph->{$type} = $value;
                }
            }

        }
        else {
            # XXX [$id, $kind, $class];
            die "Can't represent kind '$kind'";
        }
        return $graph;
    }

    sub escape {
        my ($self, $string) = @_;
        $string =~ s/^(\.*[\!\&\*\%])/.$1/;
        return $string;
    }

    my $perl_type = {
        map => 'hash',
        seq => 'array',
        scalar => 'scalar',
    };
    sub resolve_to_tag {
        my ($self, $kind, $class) = @_;
        return $class && "!perl/$perl_type->{$kind}\:$class";
    }
};

{
    package JSYNC::Loader;

    sub new { bless { @_[1..$#_] }, $_[0] }

    sub load {
        my ($self, $jsync) = @_;
        $self->{seen} = {};
        my $graph = 'JSON'->new()->decode($jsync);
        return $self->construct($graph);
    }


    sub construct {
        my ($self, $graph) = @_;
        my $seen = $self->{seen};
        my $node;
        my ($kind, $id, $class) = JSYNC::info($graph);
        if ($kind eq 'scalar') {
            if (not defined $graph) {
                return undef;
            }
            if ($graph =~ /^\*(\S+)$/) {
                return $seen->{$1};
            }
            return $self->unescape($graph);
        }
        if ($kind eq 'map') {
            $node = {};
            if ($graph->{'&'}) {
                my $anchor = $graph->{'&'};
                delete $graph->{'&'};
                $seen->{$anchor} = $node;
            }
            if ($graph->{'!'}) {
                my $class = $self->resolve_from_tag($graph->{'!'});
                delete $graph->{'!'};
                bless $node, $class;
            }
            for my $k (keys %$graph) {
                $node->{$self->unescape($k)} = $self->construct($graph->{$k});
            }
        }
        elsif ($kind eq 'seq') {
            $node = [];
            if (@$graph and defined $graph->[0] and $graph->[0] =~ /^!(.*)$/) {
                my $class = $self->resolve_from_tag($1);
                shift @$graph;
                bless $node, $class;
            }
            if (@$graph and $graph->[0] and $graph->[0] =~ /^\&(\S+)$/) {
                $seen->{$1} = $node;
                shift @$graph;
            }
            @$node = map {$self->construct($_)} @$graph;
        }
        return $node;
    }

    sub unescape {
        my ($self, $string) = @_;
        $string =~ s/^\.(\.*[\!\&\*\%])/$1/;
        return $string;
    }

    sub resolve_from_tag {
        my ($self, $tag) = @_;
        $tag =~ m{^!perl/(?:hash|array|object):(\S+)$}
          or die "Can't resolve tag '$tag'";
        return $1;
    }
};

1;
