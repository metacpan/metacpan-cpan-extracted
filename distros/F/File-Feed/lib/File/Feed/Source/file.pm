package File::Feed::Source::file;

use strict;
use warnings;

use vars qw(@ISA);

@ISA = qw(File::Feed::Source);

use File::Feed::Source;
use File::Feed::File;
use File::Copy qw(copy move);

sub protocol { 'file' }

sub feed { $_[0]->{'_feed'} }
sub destination { $_[0]->{'destination'} }

sub begin {
    my ($self, $feed) = @_;
    my $root = $self->root;
    die "No such directory: $root" if !-d $root;
    return $self;
}

sub end { }

sub id { $_[0]->{'#'} }

sub list {
    my ($self, $path, $recursive) = @_;
    my $root = $self->root;
    my $abspath = defined $path ? "$root/$path" : $root;
    my $ofs = length($abspath) + 1;
    my @files;
    if ($recursive) {
        _crawl($abspath, \@files);
    }
    else {
        @files = fgrep { -f $_ } glob("$abspath/*");
    }
    return map { substr($_, $ofs) } @files;
}

sub _crawl {
    my ($path, $list) = @_;
    my @files = glob("$path/*");
    foreach (@files) {
        if (-d $_) {
            _crawl($path, $list);
        }
        else {
            push @$list, $_;
        }
    }
}

sub fetch_file {
    my ($self, $from, $to) = @_;
    if ($self->{'copy'}) {
        copy($from, $to) or die "Can't fetch $from: $!";
    }
    else {
        move($from, $to) or die "Can't fetch $from: $!";
    }
}

sub basename {
    (my $path = shift) =~ s{^.+/}{};
    return $path;
}

1;

=pod

=head1 NAME

File::Feed::Source::file - fetch files from a filesystem

=cut

