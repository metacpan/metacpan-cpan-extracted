package HTTP::Command::Wrapper::Curl;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $opt) = @_;
    return bless { opt => $opt } => $class;
}

sub fetch_able {
    my ($self, $url, $headers) = @_;

    my $command = $self->_build($headers, 1, [ '--head', qq/"$url"/ ]);
    `$command` =~ m/200 OK/;
}

sub fetch {
    my ($self, $url, $headers) = @_;

    my $command = $self->_build($headers, 1, [ qq/"$url"/ ]);
    `$command`;
}

sub download {
    my ($self, $url, $path, $headers) = @_;

    my $command = $self->_build($headers, 0, [ qq/"$url"/, '-o', qq/"$path"/ ]);
    system($command) == 0;
}

sub _build {
    my ($self, $headers, $quiet, $opts) = @_;
    my @args = (
        'curl',
        '-L',
        $self->_headers($headers),
        $quiet        ? undef      : $self->_verbose,
        $quiet        ? '--silent' : $self->_quiet,
        defined $opts ? @$opts     : undef,
    );
    return join(' ', grep { $_ } @args);
}

sub _headers {
    my ($self, $headers) = @_;
    return unless defined $headers;
    return if @$headers == 0;
    return map { "-H \"$_\"" } @$headers;
}

sub _verbose {
    my $self = shift;
    return $self->{opt}->{verbose} ? '--verbose' : '';
}

sub _quiet {
    my $self = shift;
    return $self->{opt}->{quiet} ? '--silent' : '';
}

1;
