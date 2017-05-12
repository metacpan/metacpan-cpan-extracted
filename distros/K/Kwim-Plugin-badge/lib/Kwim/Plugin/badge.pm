package Kwim::Plugin::badge;
our $VERSION = '0.0.7';

package
Kwim::Pod;

sub phrase_func_badge {
    my ($self, $args) = @_;
    my @args = split / +/, $args;
    $args = pop @args or return;
    return unless @args;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    my $out = "=for html\n";
    for my $type (@args) {
        my $method = "_badge_$type";
        if ($self->can($method)) {
            $out .= $self->$method($1, $2) . "\n";
        }
    }
    return "$out\n";
}

sub phrase_func_badge_travis {
    my ($self, $args) = @_;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    sprintf "=for html\n%s\n\n", $self->_badge_travis($1, $2);
}

sub phrase_func_badge_coveralls {
    my ($self, $args) = @_;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    sprintf "=for html\n%s\n\n", $self->_badge_coveralls($1, $2);
}

sub _badge_travis {
    my ($self, $owner, $repo) = @_;
    qq{<a href="https://travis-ci.org/$owner/$repo"><img src="https://travis-ci.org/$owner/$repo.png" alt="$repo"></a>};
}

sub _badge_coveralls {
    my ($self, $owner, $repo) = @_;
    qq{<a href="https://coveralls.io/r/$owner/$repo?branch=master"><img src="https://coveralls.io/repos/$owner/$repo/badge.png" alt="$repo"></a>};
}

package
Kwim::Markdown;

sub phrase_func_badge {
    my ($self, $args) = @_;
    my @args = split / +/, $args;
    $args = pop @args or return;
    return unless @args;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    my $out = "";
    for my $type (@args) {
        my $method = "_badge_$type";
        if ($self->can($method)) {
            $out .= $self->$method($1, $2) . "\n";
        }
    }
    chomp $out;
    return $out;
}

sub phrase_func_badge_travis {
    my ($self, $args) = @_;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    $self->_badge_travis($1, $2);
}

sub phrase_func_badge_coveralls {
    my ($self, $args) = @_;
    return unless $args =~ /^(\S+)\/(\S+)$/;
    $self->_badge_coveralls($1, $2);
}

sub _badge_travis {
    my ($self, $owner, $repo) = @_;
    qq{[![Travis build status](https://travis-ci.org/$owner/$repo.png?branch=master)](https://travis-ci.org/$owner/$repo)};
}

sub _badge_coveralls {
    my ($self, $owner, $repo) = @_;
    qq{[![Coverage Status](https://coveralls.io/repos/$owner/$repo/badge.png?branch=master)](https://coveralls.io/r/$owner/$repo?branch=master)};
}

1;
