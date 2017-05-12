package Document::Maker::Parser;

use Moose;

use Document::Maker::FileFinder::Query;
use Document::Maker::Pattern;

use Document::Maker::Target::Simple;
use Document::Maker::Target::File;
use Document::Maker::Target::PatternFile;
use Document::Maker::Target::PatternFileScan;
use Document::Maker::Target::Group;

use Document::Maker::Dependency;
use Scalar::Util qw/blessed/;

with map { "Document::Maker::Role::$_" } qw/Component/;

sub new_pattern {
    my $self = shift;
    return shift if blessed $_[0] && $_[0]->isa("Document::Maker::Pattern");
    return Document::Maker::Pattern->new(maker => $self->maker, pattern => shift);
}

sub _new_target_maker {
    my $self = shift;
    my $class = shift;
    my $new = shift;
    my $parsed = shift;

    my %new = (%$new, %{ $parsed->{new} });
    $new{dependency} = $new{dependency}->clone;

    my $target_maker = $class->new(maker => $self->maker, %new);

    $self->maker->register_target_maker($target_maker) if $parsed->{register};

    return $target_maker;
}

sub _new_pattern_file_target_scan {
    my $self = shift;
    my $target_pattern = shift;
    my $source_pattern = shift;
    my $finder = shift;

    $source_pattern = $self->new_pattern($source_pattern);
    $target_pattern = $self->new_pattern($target_pattern);

    return $self->_new_target_maker("Document::Maker::Target::PatternFileScan", { finder => $finder,
        target_pattern => $target_pattern, source_pattern => $source_pattern }, @_);
}

sub _new_pattern_file_target {
    my $self = shift;
    my $target_pattern = shift;
    my $source_pattern = shift;
    my $nickname = shift;

    $source_pattern = $self->new_pattern($source_pattern);
    $target_pattern = $self->new_pattern($target_pattern);

    return $self->_new_target_maker("Document::Maker::Target::PatternFile", { nickname => $nickname,
        target_pattern => $target_pattern, source_pattern => $source_pattern }, @_);
}

sub _new_file_target {
    my $self = shift;
    my $name = shift;

    return $self->_new_target_maker("Document::Maker::Target::File", { name => $name }, @_);
}

sub _new_simple_target {
    my $self = shift;
    my $name = shift;

    return $self->_new_target_maker("Document::Maker::Target::Simple", { name => $name }, @_);
}

sub _new_dependency {
    my $self = shift;
    my $dependency = Document::Maker::Dependency->new(maker => $self->maker);
}

sub _new_target_group {
    my $self = shift;
    my $targets = shift;
    $targets = [] unless $targets;
    my $parsed = shift;

    my $alias = delete $parsed->{alias};
    my @alias;
    @alias = ref $alias eq "ARRAY" ? @$alias : ($alias) if defined $alias;
    my $target_group = Document::Maker::Target::Group->new(maker => $self->maker, names => \@alias, targets => $targets);

    if (@alias && $parsed->{register}) {
        $self->maker->register_target_maker($target_group);
    }

    return $target_group;
}

sub parse_pattern_target {
    my $self = shift;
    my @parse = @_;

    my $maker = $self->maker;
    my (@target_name, @source_name, @finder, $target_pattern, $source_pattern);

    my $parse_extra;
    $parse_extra = pop @parse if ref $parse[-1] eq "HASH";
    $parse_extra ||= {};
    my $parsed = $self->parse_extra($parse_extra);

    my $source = [];
    $source = pop @parse if @parse && ref $parse[-1] && ref $parse[-1] eq "ARRAY";

    my $dependency = $parsed->{dependency};
    $dependency->add_dependency($self->parse_requirement($_)) for @$source;

    for (@parse) {
        if (m/%/ && defined $target_pattern) {
            $self->log->debug("Found source pattern: $_");
            $source_pattern = $_;
        }
        elsif (m/%/) {
            $self->log->debug("Found target pattern: $_");
            $target_pattern = $_;
        }
        elsif (! defined $target_pattern) {
            $self->log->debug("Found target name: $_");
            push @target_name, $_;
        }
        elsif (Document::Maker::FileFinder::Query->recognize($_)) {
            $self->log->debug("Found file finder: $_");
            push @finder, $_;
        }
        else {
            $self->log->debug("Found source name: $_");
            push @source_name, $_;
        }
    }

    $source_pattern = $self->new_pattern($source_pattern);
    $target_pattern = $self->new_pattern($target_pattern);

    my @targets;
    for (@target_name, @source_name) {
        push @targets, $self->_new_pattern_file_target($target_pattern, $source_pattern, $_, $parsed);
    }

    for (@finder) {
        push @targets, $self->_new_pattern_file_target_scan($target_pattern, $source_pattern, $_, $parsed);
    }

    my $target_group = $self->_new_target_group(\@targets, $parsed);
    return $target_group;
}

sub parse_target {
    my $self = shift;
    my $target = shift;
    my $source = [];
    $source = shift if @_ && ref $_[0] && ref $_[0] eq "ARRAY";
    my $parse_extra = { @_ };
    my $parsed = $self->parse_extra($parse_extra);

    my (@target_list, @source_list);
    @target_list = ($target) if defined $target;
    @source_list = ($source) if defined $source;

    @target_list = map { ref $_ eq "ARRAY" ? @$_ : $_ } @target_list;
    @source_list = map { ref $_ eq "ARRAY" ? @$_ : $_ } @source_list;

    my $dependency = $parsed->{dependency};
    $dependency->add_dependency($self->parse_requirement($_)) for @source_list;

    my @targets;
    if ($parsed->{type} && $parsed->{type} eq "simple") {
        for (@target_list) {
            push @targets, $self->_new_simple_target($_, $parsed);
        }
    }
    else {
        for (@target_list) {
            push @targets, $self->_new_file_target($_, $parsed);
        }
    }

    my $target_group = $self->_new_target_group(\@targets, $parsed);
    return $target_group;
}

sub parse_simple_target {
    my $self = shift;
    return $self->parse_target(@_, type => "simple");
}

sub parse_requirement {
    my $self = shift;
    my $require = shift;

    return $require if blessed $require;
    return $require if ref $require;

    if (Document::Maker::FileFinder::Query->recognize($require)) {
        return Document::Maker::SourceFileScan(maker => $self->maker, finder => Document::Maker::FileFinder::Query->new(query => $require));
    }

    return $require;
}

sub parse_extra {
    my $self = shift;
    my $parse_extra = shift;

    my %parsed;

    local %_ = %$parse_extra;

    $_{register} = 1 unless exists $_{register};
    $parsed{$_} = $_{$_} for grep { exists $_{$_} } qw/register alias type/;

    my %new = %{ $parse_extra->{new} || {} };
    $parsed{new} = \%new;

    $parsed{script} = $new{script} = $_{do} || $_{script} if ! $new{script} && ($_{do} || $_{script});
    my $dependency = $parsed{dependency} = $new{dependency} = $_{dependency} ? $_{dependency} : $self->_new_dependency;

    my @require;
    for (qw/require requires/) {
        if (my $require = $_{$_}) {
            push @require, ref $require eq "ARRAY" ? @$require : ($require);
        }
    }

    $dependency->add_dependency($self->parse_requirement($_)) for @require;

    return \%parsed;
}

1;
