package File::Feed;

use strict;
use warnings;

use File::Kvpar;
use File::Kit;
use File::Feed::Source;
use File::Feed::Channel;
use File::Feed::Context;
use File::Feed::Sink;
use File::Feed::Util;
use File::Path qw(mkpath);
use File::Copy qw(move copy);
use File::Basename qw(basename dirname);
use String::Expando;

use vars qw($VERSION);

$VERSION = '0.03';

# Feed statuses
use constant IDLE     => '@idle';
use constant FILLING  => '@filling';
use constant DRAINING => '@draining';
use constant ERROR    => '@error';
use constant FROZEN   => '@frozen';

sub new {
    my ($cls, $dir) = @_;
    my $kv = File::Kvpar->new('+<', "$dir/feed.kv");
    open my $lsfh, '+>>', "$dir/files.list" or die "Can't open files.list: $!";
    #seek $lsfh, 0, 0;
    #my @ls = <$lsfh>;
    #chomp @ls;
    my @elems = $kv->elements;
    my ($feed, $source, @etc);
    ($feed,   @etc) = grep { $_->{'@'} eq 'feed'    } @elems; die if !defined $feed   || @etc;
    ($source, @etc) = grep { $_->{'@'} eq 'source'  } @elems; die if !defined $source || @etc;
    my @sinks       = grep { $_->{'@'} eq 'sink'    } @elems;
    my @channels    = grep { $_->{'@'} eq 'channel' } @elems;
    if ($feed->{'perl-class'}) {
        $cls = $feed->{'perl-class'};
        eval "use $cls; 1" or die "Can't use feed class $cls: $!";
    }
    @channels = ({
        '@' => 'channel',
        '#' => 'default',
        'path' => '.',
        'description' => 'default channel',
        'filter' => 'glob:*',
    }) if !@channels;
    my $self = bless {
        '_dir' => $dir,
        %$feed,
        '_feedkv' => $kv,
        '_fileskv' => File::Kvpar->new('+<', "$dir/files.kv"),
        '_random_buf' => '',
        '_lsfh' => $lsfh,
    }, $cls;
    $self->{'_channels'} = [ map {
            $self->_channel_instance(
                '_source' => ($self->{'_source'} ||= $self->_source_instance(%$source)),
                %$_,
            )
        } @channels ];
    my %sinks;
    foreach (@sinks) {
        my $id = $_->{'#'};
        $id = 'default' if !defined $id;
        die "Duplicate sinks: $id" if exists $sinks{$id};
        $sinks{$id} = $_;
    }
    ($sinks{'default'}) = (values %sinks) if scalar(keys %sinks) == 1;
    $self->{'_sinks'} = \%sinks;
    return $self;
}

sub _source_instance {
    my $self = shift;
    return File::Feed::Source->new(@_, '_feed' => $self);
}

sub _sink_instance {
    my $self = shift;
    return File::Feed::Sink->new(@_, '_feed' => $self);
}

sub _channel_instance {
    my $self = shift;
    return File::Feed::Channel->new(@_, '_feed' => $self);
}

sub _file_instance {
    my $self = shift;
    my %arg = @_;
    my $chan = $self->channel($arg{'channel'} || die "Can't determine file channel");
    return File::Feed::File->new(%arg, '_channel' => $chan, '_feed' => $self);
}

sub new_files {
    my ($self, %arg) = @_;
    # What channels should we look at?
    my %chan = map { $_->id => 1 } $self->channels(@{ $arg{'channels'} || [] });
    # Within those channels, what files are new?
    my $new_dir = $self->path('new');
    my @new;
    _crawl($new_dir, \@new);
    s{^$new_dir/}{} for @new;
    my %is_new  = map { $_ => 1 } @new;
    # Instantiate all files meeting those criteria
    return map {
               $self->_file_instance(%$_)
           }
           grep {
               $is_new{$_->{'local-path'}}
               &&
               $chan{$_->{'channel'}}
           }
           $self->files;
}

sub _crawl {
    my ($dir, $list) = @_;
    opendir my $fh, $dir or die;
    my @files = grep { !/^\./ } readdir($fh);
    closedir $fh;
    foreach my $name (@files) {
        my $path = "$dir/$name";
        if (-d $path) {
            _crawl($path, $list);
        }
        elsif (-f _) {
            push @$list, $path;
        }
    }
}

sub _group_files {
    my ($self, $stash, @files) = @_;
    my $expando = String::Expando->new;
    my $now = strftime('%Y%m%dT%H%M%S', localtime);
    my ($ymd, $hms) = split 'T', $now;
    my %group;
    foreach my $file (@files) {
        my $chan = $file->channel;
        my $c = $chan->id;
        my %ctx = (
            %$self,
            %$chan,
            'date' => $ymd,
            'time' => $hms,
            'datetime' => $now,
            %$stash,
            %$file,
        );
        my $sink  = $ctx{'sink'};
        $sink = "file:dropoff/" if !defined $sink;
        my $g = $expando->expand($sink, {
            %ctx,
            'feed'    => $self,
            'channel' => $chan,
            'file'    => $file,
        });
        $group{$g} ||= {
            'files' => [],
        };
        push @{ $group{$g}{'files'} }, $file;
    }
    return values %group;
}

sub fill {
    my ($self, %arg) = @_;
    my $source = $self->source;
    my $root = $self->path;
    my @new;
    my $ok = eval {
        # Start filling
        $self->status(FILLING) or die "Can't set status: not a feed?";
        my %logged = map { $_->{'path'} => $_ } $self->files;
        $source->begin($self);
        my @channels = $self->channels(@{ $arg{'channels'} || [] });
        my ($tmpd, $arcd, $newd) = map { $self->path($_) } (FILLING, qw(archive new));
        my %mkpath;
        my $lsfh = $self->{'_lsfh'};
        foreach my $channel (@channels) {
            my $dir  = $channel->path;
            my $ldir = $channel->local_path;
            for ($tmpd) {
                my $d = "$_/$ldir";
                mkpath $d if !$mkpath{$d}++ || !-d $d;
            }
            my @fetched = $source->fetch(
                'channel' => $channel,
                'exclude' => \%logged,
                'destination' => $tmpd,
            );
            foreach my $file (@fetched) {
                my $path  = $file->{'path'};
                print $lsfh $path, "\n";
                my $lpath = $file->{'local-path'};
                my $tmp_path = "$tmpd/$lpath";
                foreach ($arcd, $newd) {
                    my $other_path = "$_/$lpath";
                    my $d = dirname($other_path);
                    mkpath $d if !$mkpath{$d}++ || !-d $d;
                    link $tmp_path, $other_path or die "Can't link $tmp_path into $d";
                }
                unlink "$tmpd/$lpath" or die;
                push @new, $self->_file_instance(
                    %$file,
                    'feed' => $self->id,
                    'source' => $source->uri,
                    'channel' => $channel->id,
                );
            }
        }
        $source->end;
        $self->{'_fileskv'}->append(@new) if @new;
        1;
    };
    $self->_cleanup;
    $self->status($ok ? IDLE : ERROR);
    return @new;
}

sub drain {
    my ($self, %arg) = @_;
    my @new = $self->new_files(%arg);
    return if !@new;
    my @files;
    my $ok = eval {
        # Start draining
        $self->status(DRAINING) or die "Can't set status: not a feed?";
        my $s = $arg{'sink'};
        my $uri_proto = $self->{'_sinks'}{$s || 'default'} || $s || die "Can't determine sink";
        $uri_proto = $uri_proto->{'#'} if ref $uri_proto;  # XXX Hack!
        my %uri2files;
        foreach my $file (@new) {
            my $channel = $file->channel;
            my $ctx = $self->context(
                'source'  => $file->source,
                'channel' => $channel,
                'file'    => $file,
            );
            my $uri = $ctx->expand($uri_proto);
            push @{ $uri2files{$uri} ||= [] }, $file;
        }
        my $new_dir = $self->path('new');
        while (my ($uri, $files) = each %uri2files) {
            my $sink = $self->_sink_instance(
                'uri' => $uri,
                'from' => $new_dir,
            );
            $sink->begin;
            $sink->store(@$files);
            $sink->end;
            push @files, @$files;
        }
        1;
    };
    $self->_cleanup;
    $self->status($ok ? IDLE : ERROR);
    return @files;
}

sub reset {
    my ($self) = @_;
    $self->status(IDLE, 1);
}

sub freeze {
    my ($self) = @_;
    $self->status(FROZEN, 0, IDLE);
}

sub thaw {
    my ($self) = @_;
    $self->status(IDLE, 0, FROZEN);
}

sub context {
    my ($self, %arg) = @_;
    my %ctx;
    _ctxatom($_, $arg{$_}, \%ctx) for qw(source channel sink file);
    return File::Feed::Context->new(%ctx);
}

sub _ctxatom {
    my ($key, $val, $h) = @_;
    return if !defined $val;
    if (ref $val) {
        eval {
            $h->{$key} = $val->{'#'} if defined $val->{'#'};
            while (my ($k, $v) = each %$val) {
                _ctxatom("$key.$k", $v, $h) if $k =~ /^[^[:punct:]]/;
            }
            1;
        } or $h->{$key} = $val;
    }
    else {
        $h->{$key} = $val;
    }
}

sub path {
    my $self = shift;
    return join '/', $self->dir, @_;
}

sub status {
    my ($self, $new_status, $error_ok, $old_status_must_be) = @_;
    my $dir = $self->dir;
    my ($old_status, @etc) = map { basename($_) } glob($self->path('@*'));
    die "No status set for feed $self->{'@'}" if !defined $old_status;
    die "Multiple statuses set for feed $self->{'@'}" if @etc;
    return $old_status if !defined $new_status;
    if (defined $old_status_must_be) {
        die "Feed is not ".substr($old_status_must_be,1) if $old_status ne $old_status_must_be;
    }
    elsif ($new_status ne IDLE) {
        die "Feed is frozen" if $old_status eq FROZEN;
    }
    die "Feed is in error state" if $old_status eq ERROR && !$error_ok;
    return $new_status if $old_status eq $new_status;
    rename $self->path($old_status), $self->path($new_status)
        or die "Can't set status for feed $self->{'@'}: $!";
    return $old_status;
}

sub id          { $_[0]->{'#'}           }
sub host        { $_[0]->source->host    }
sub root        { $_[0]->source->root    }
sub from        { $_[0]->{'from'} || $_[0]->id }
sub to          { $_[0]->{'to'} || $_[0]->id }
sub description { $_[0]->{'description'} }
sub user        { $_[0]->{'user'}        }
sub repeat      { $_[0]->{'repeat'}      }

sub dir         { $_[0]->{'_dir'}        }
sub source      { $_[0]->{'_source'}     }

sub channel {
    my ($self, $chan) = @_;
    my ($channel) = grep { $_->id eq $chan } $self->channels;
    die "No such channel: $chan" if !defined $channel;
    return $channel;
}

sub channels {
    my $self = shift;
    my @chan = @{ $self->{'_channels'} };
    return @chan if !@_;
    my %chan;
    foreach my $spec (@_) {
        my $rx = File::Feed::Util::pat2rx($spec);
        %chan = ( %chan, map { my $c = $_->id; $c =~ $rx ? ($c => $_) : () } @chan );
    }
    return values %chan;
    #return grep { $chan{$_->id} } @chan;
}

sub files {
    my ($self) = @_;
    return $self->{'_fileskv'}->elements;
}

sub _shadow {
    my ($self, $file) = @_;
    my $n = 4;
    my ($rand, $shadow);
    my $dir = $self->path('shadow');
    -d $dir or mkdir $dir or die "Can't mkdir $dir $!";
    while (defined($rand = $self->_random_hex(8)) && !link $file, $shadow = $self->path('shadow', "shadow.$rand")) {
        die "Can't create shadow file $shadow for $file: $!"
            if --$n == 0;
    }
    push @{ $self->{'_shadow'} ||= [] }, [ $shadow, $file ];
    return $shadow, $file;
}

sub _cleanup {
    my ($self) = @_;
    my $shadow = $self->{'_shadow'};
    foreach (@$shadow) {
        my ($shadow, $original) = @$_;
        unlink $shadow or link($shadow, $original) or die "Can't remove shadow file $shadow or relink it to $original: $!";
    }
}

sub _fill_random_buffer {
    my ($self) = @_;
    my $fh;
    open $fh, '<', '/dev/urandom' or
    open $fh, '<', '/dev/random'  or die "Can't open /dev/*random: $!";
    sysread $fh, $self->{'_random_buf'}, 32 or die "Can't read random bytes: $!";
}

sub _random_hex {
    my ($self, $n) = @_;
    $n ||= 8;
    $n = 16 if $n > 16;
    $self->_fill_random_buffer if length($self->{'_random_buf'}) < $n;
    return lc unpack('H*', substr($self->{'_random_buf'}, 0, $n, ''));
}

1;

=pod

=head1 NAME

File::Feed - gather files from an FTP server or other source

=cut
