package File::Assets::Filter;

use strict;
use warnings;

use Object::Tiny qw/cfg where signature/;
use File::Assets::Carp;

use Digest;
use Scalar::Util qw/weaken/;

for my $ii (qw/matched mtime assets bucket slice/) {
    no strict 'refs';
    *$ii = sub {
        my $self = shift;
        return $self->stash->{$ii} unless @_;
        return $self->stash->{$ii} = shift;
    };
}

my %default = (qw/
    /,
    output => undef,
);

sub new_parse {
    my $class = shift;
    return unless my $filter = shift;

    $filter =~ s/^yui-compressor\b/yuicompressor/; # A special case
    my $kind = lc $class;
    $kind =~ s/^File::Assets::Filter:://i;
    $kind =~ s/::/-/g;

    my %cfg;
    if (ref $filter eq "") {
        my $cfg = $filter;
        return unless $cfg =~ s/^\s*$kind(?:\s*$|:([^:]))//i;
        $cfg = "$1$cfg" if defined $1;
        %cfg = $class->new_parse_cfg($cfg);
        if (ref $_[0] eq "HASH") {
            %cfg = (%cfg, %{ $_[0] });
            shift;
        }
        elsif (ref $_[0] eq "ARRAY") {
            %cfg = (%cfg, @{ $_[0] });
            shift;
        }
    }
    elsif (ref $filter eq "ARRAY") {
        # TODO? Get rid of this?
        return unless $filter->[0] && $filter->[0] =~ m/^\s*$kind\s*$/i;
        my @cfg = @$filter;
        shift @cfg;
        %cfg = @cfg;
    }

    return $class->new(%cfg, @_);
}

sub new_parse_cfg {
    my $class = shift;
    my $cfg = shift;
    $cfg = "" unless defined $cfg;
    my %cfg;
    %cfg = map { my @itm = split m/=/, $_, 2; $itm[0], $itm[1] } split m/;/, $cfg;
    $cfg{__cfg__} = $cfg;
    return %cfg;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    local %_ = @_;

#    $self->{assets} = $_{assets};
#    weaken $self->{assets};

    $self->{cfg} = {};

    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }

    return $self;
}

sub fit {
    my $self = shift;
    my $bucket = shift;

    return 1 unless $self->{fit};
    return 1 if $bucket->kind->is_better_than_or_equal($self->{fit});
}

sub stash {
    return shift->{stash} ||= {};
}

sub type {
    return shift->where->{type};
}

sub output {
    return shift->cfg->{output};
}

sub begin {
    my $self = shift;
    my $slice = shift;
    my $bucket = shift;
    my $assets = shift;

    $self->stash->{slice} = $slice;
    $self->stash->{bucket} = $bucket;
    $self->stash->{assets} = $assets;
    $self->stash->{mtime} = 0;
}

sub end {
    my $self = shift;
    delete $self->{stash};
}

sub filter {
    my $self = shift;
    my $slice = shift;
    my $bucket = shift;
    my $assets = shift;

    $self->begin($slice, $bucket, $assets);

    return unless $self->pre;

    my @matched;
    $self->matched(\@matched);

    my $count = 0;
    for (my $rank = 0; $rank < @$slice; $rank++) {
        my $asset = $slice->[$rank];

        next unless $self->_match($asset);

        $count = $count + 1;
        push @matched, { asset => $asset, rank => $rank, count => $count };

        my $asset_file_mtime = $asset->file_mtime;
        $self->mtime($asset_file_mtime) if $asset_file_mtime >= $self->mtime;

        $self->process($asset, $rank, $count, scalar @$slice, $slice);
    }
    $self->post;

    $self->end;
}

sub _match {
    my $self = shift;
    my $asset = shift;

    return $self->match($asset, 1);
}

sub match {
    my $self = shift;
    my $asset = shift;
    my $match = shift;

    return $match ? 1 : 0;
}

sub pre {
    return 1;
}

sub process {
}

sub post {
    return 1;
}

sub remove {
    my $self = shift;
    carp __PACKAGE__, "::remove() is deprecated, nothing happens";
    return;
}

sub kind {
    my $self = shift;
    return $self->bucket->kind;
}

1;

__END__

my %default = (qw/
    /,
    output => undef,
);

sub new_parse {
    my $class = shift;
    return unless my $filter = shift;

    my $kind = lc $class;
    $kind =~ s/^File::Assets::Filter:://i;
    $kind =~ s/::/-/g;

    my %cfg;
    if (ref $filter eq "") {
        my $cfg = $filter;
        return unless $cfg =~ s/^\s*$kind(?:\s*$|:([^:]))//i;
        $cfg = "$1$cfg" if defined $1;
        %cfg = $class->new_parse_cfg($cfg);
        if (ref $_[0] eq "HASH") {
            %cfg = (%cfg, %{ $_[0] });
            shift;
        }
        elsif (ref $_[0] eq "ARRAY") {
            %cfg = (%cfg, @{ $_[0] });
            shift;
        }
    }
    elsif (ref $filter eq "ARRAY") {
        return unless $filter->[0] && $filter->[0] =~ m/^\s*$kind\s*$/i;
        my @cfg = @$filter;
        shift @cfg;
        %cfg = @cfg;
    }

    return $class->new(%cfg, @_);
}

sub new_parse_cfg {
    my $class = shift;
    my $cfg = shift;
    $cfg = "" unless defined $cfg;
    my %cfg;
    %cfg = map { my @itm = split m/=/, $_, 2; $itm[0], $itm[1] } split m/;/, $cfg;
    $cfg{__cfg__} = $cfg;
    return %cfg;
}

sub new {
    my $class = shift;
    my $self = $class->SUPER::new;
    local %_ = @_;

    $self->{assets} = $_{assets};
    weaken $self->{assets};

    my $where = $_{where};
    if ($_{type}) {
        croak "You specified a type AND a where clause" if $where;
        $where = {
            type => $_{type},
        };
    }
    if (defined (my $type = $where->{type})) {
        $where->{type} = File::Assets::Util->parse_type($_{type}) or croak "Don't know the type ($type)";
    }
    if (defined (my $path = $where->{path})) {
        if (ref $path eq "CODE") {
        }
        elsif (ref $path eq "Regex") {
            $where->{path} = sub {
                return defined $_ && $_ =~ $path;
            };
        }
        elsif (! ref $path) {
            $where->{path} = sub {
                return defined $_ && $_ eq $path;
            };
        }
        else {
            croak "Don't know what to do with where path ($path)";
        }
    }
    $self->{where} = $where;
    $self->{cfg} = {};

    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }

    return $self;
}

