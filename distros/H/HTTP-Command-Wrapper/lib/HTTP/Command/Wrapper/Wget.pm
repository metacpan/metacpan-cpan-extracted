package HTTP::Command::Wrapper::Wget;
use strict;
use warnings;
use utf8;

sub new {
    my ($class, $opt) = @_;
    return bless { opt => $opt } => $class;
}

sub fetch_able {
    my ($self, $url, $headers) = @_;

    my $command = $self->_build($headers, 1, [ '--server-response', '--spider', qq/"$url"/ ]);
    `$command 2>&1` =~ m/200 OK/;
}

sub fetch {
    my ($self, $url, $headers) = @_;

    my $command = $self->_build($headers, 1, [ qq/"$url"/, '-O', '-' ]);
    `$command`;
}

sub download {
    my ($self, $url, $path, $headers) = @_;

    my $command = $self->_build($headers, 0, [ '--continue', qq/"$url"/, '-O', qq/"$path"/ ]);
    system($command) == 0;
}

sub _build {
    my ($self, $headers, $quiet, $opts) = @_;
    my @args = (
        'wget',
        $self->_headers($headers),
        $quiet        ? undef     : $self->_verbose,
        $quiet        ? '--quiet' : $self->_quiet,
        defined $opts ? @$opts    : undef,
    );
    return join(' ', grep { $_ } @args);
}

sub _headers {
    my ($self, $headers) = @_;
    return unless defined $headers;
    return if @$headers == 0;
    return map { "--header=\"$_\"" } @$headers;
}

sub _verbose {
    my $self = shift;
    return $self->{opt}->{verbose} ? '--verbose' : '';
}

sub _quiet {
    my $self = shift;
    return $self->{opt}->{quiet} ? '--quiet' : '';
}

1;
