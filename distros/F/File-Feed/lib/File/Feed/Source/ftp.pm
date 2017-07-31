package File::Feed::Source::ftp;

use strict;
use warnings;

use vars qw(@ISA);

@ISA = qw(File::Feed::Source);

use File::Feed::Source;
use File::Feed::File;
use Net::FTP;
use Net::Netrc;

sub protocol { 'ftp' }

sub feed { $_[0]->{'_feed'} }

sub begin {
    my ($self, $feed) = @_;
    my $host = $self->host;
    my $user = $self->{'user'}     ||= $self->{'uri'}->user;
    my $pass = $self->{'password'} ||= $self->{'uri'}->password;
    if (!defined $pass) {
        my $mach = Net::Netrc->lookup($host) || die "Can't determine password for $host";
        my $login;
        ($login, $pass) = $mach->lpa;
        die "Looking for $user at $host, found $login" if defined $user && $login ne $user;
    }
    my $root = $self->root;
    my $client = Net::FTP->new($host) or die "Can't connect";
    $client->login($user, $pass)      or die "Can't login: ",     $client->message;
    $client->cwd($self->root)         or die "Can't cwd $root: ", $client->message;
    @$self{qw(_client _feed _list)} = ($client, $feed, {});
    return $self;
}

sub end {
    my ($self) = @_;
    delete @$self{qw(_client _feed _list)};
    return $self;
}

sub list {
    my ($self, $path, $recursive) = @_;
    my $root = $self->root;
    my $abspath = defined $path ? "$root/$path" : $root;
    my $ofs = length($abspath) + 1;
    my $client = $self->{'_client'};
    my $dir = $client->dir($abspath) or return;
    my @files;
    foreach my $line (@$dir) {
        next if $line !~ /^([-d])[-a-z]{9}\s.+\s(\S+)$/;
        my ($type, $file) = ($1, "$abspath/$2");
        if ($type eq 'd') {
            ;
        }
        else {
            push @files, $file;
        }
    }
    return map { substr($_, $ofs) } @files;
}

sub oldlist {
    my ($self, $path, $recursive) = @_;
    goto &rlist if $recursive;
    $path = '.' if !defined $path;
    my $client = $self->{'_client'};
    my $list = $client->ls($path)
        or die "Can't list $path: ", $client->message;
    return @$list;
}

sub rlist {
    my ($self, $path) = @_;
    my $client = $self->{'_client'};
    my @list;
    _crawl($client, $path, \@list);
    return @list;
}

sub _crawl {
    my ($client, $path, $list) = @_;
    my $dir = $client->dir($path) or return;
    foreach my $line (@$dir) {
        next if $line !~ /^([-d])[-a-z]{9}\s.+\s(\S+)$/;
        my ($type, $file) = ($1, "$path/$2");
        if ($type eq 'd') {
            _crawl($client, $file, $list);
        }
        else {
            push @$list, $file;
        }
    }
}

sub fetch_file {
    my ($self, $from, $to) = @_;
    my $client = $self->{'_client'};
    $client->get($from, $to)
        or die "Can't fetch $from: ", $client->message;
}

sub basename {
    (my $path = shift) =~ s{^.+/}{};
    return $path;
}

1;

=pod

=head1 NAME

File::Feed::Source - fetch files from an FTP server

=cut

