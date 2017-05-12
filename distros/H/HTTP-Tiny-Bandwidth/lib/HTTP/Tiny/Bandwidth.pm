package HTTP::Tiny::Bandwidth;
use strict;
use warnings;
use Time::HiRes ();
use Carp ();

our $VERSION = '0.01';
use parent 'HTTP::Tiny';

our $CHECK_INTERVAL_SECOND = 0.001;

use constant BUFSIZE => 32768;
use constant DEBUG => $ENV{HTTP_TINY_BANDWIDTH_DEBUG};

sub _download_data_callback {
    my ($self, $fh, $limit_bps) = @_;
    if (!$limit_bps) {
        return sub { print {$fh} $_[0] };
    }
    my $previous;
    sub {
        print {$fh} $_[0];
        $previous ||= [ [Time::HiRes::gettimeofday], 0 ];
        my $elapsed = Time::HiRes::tv_interval($previous->[0]);
        return 1 if $elapsed < $CHECK_INTERVAL_SECOND;
        my $sleep = 8 * (tell($fh) - $previous->[1]) / $limit_bps - $elapsed;
        if ($sleep > 0) {
            DEBUG and warn "-> (download) sleep $sleep\n";
            select undef, undef, undef, $sleep;
            $previous->[0] = [Time::HiRes::gettimeofday];
            $previous->[1] = tell($fh);
        }
    };
}

sub _upload_data_callback {
    my ($self, $fh, $limit_bps) = @_;
    if (!$limit_bps) {
        return sub {
            my $len = read $fh, my $buf, BUFSIZE;
            if (!defined $len) {
                die "file read error: $!";
            } elsif ($len == 0) {
                undef; # EOF, finish
            } else {
                $buf;
            }
        };
    }

    my $previous;
    sub {
        $previous ||= [ [Time::HiRes::gettimeofday], 0 ];
        my $len = read $fh, my $buf, BUFSIZE;
        if (!defined $len) {
            die "file read error: $!";
        } elsif ($len == 0) {
            undef; # EOF, finish
        } else {
            $previous->[1] += $len;
            my $elapsed = Time::HiRes::tv_interval($previous->[0]);
            if ($elapsed > $CHECK_INTERVAL_SECOND) {
                my $sleep = 8 * $previous->[1] / $limit_bps - $elapsed;
                if ($sleep > 0) {
                    DEBUG and warn "-> (upload) sleep $sleep\n";
                    select undef, undef, undef, $sleep;
                    $previous->[0] = [Time::HiRes::gettimeofday];
                    $previous->[1] = 0;
                }
            }
            $buf;
        }
    }
}

sub request {
    my ($self, $method, $url, $args) = @_;
    $args ||= +{};
    if ($args->{content_file} || $args->{content_fh}) {
        my $fh = $args->{content_fh};
        unless ($fh) {
            my $file = $args->{content_file};
            open $fh, "<", $file or Carp::croak("Error: Could not open $file: $!");
            binmode $fh;
        }
        my $upload_limit_bps = $args->{upload_limit_bps};
        $args->{content} = $self->_upload_data_callback($fh, $upload_limit_bps);
        ($args->{headers} ||= +{})->{'content-length'} = -s $fh;
        # XXX set content-type via Plack::MIME?
    }

    my $set_bandwidth_data_callback;
    my ($download_content, $download_content_fh);
    if (my $download_limit_bps = $args->{download_limit_bps}) {
        if ($args->{data_callback}) {
            Carp::croak("Error: Can not specify both download_limit_bps "
                . "and data_callback at the same time");
        }
        open $download_content_fh, ">", \$download_content;
        $args->{data_callback}
            = $self->_download_data_callback($download_content_fh, $download_limit_bps);
        $set_bandwidth_data_callback++;
    }

    my $res = $self->SUPER::request($method, $url, $args);
    if ($set_bandwidth_data_callback) {
        close $download_content_fh;
        if (length($res->{content} || '') == 0) {
            $res->{content} = $download_content;
        }
    }
    $res;
}

# copy from HTTP::Tiny
sub mirror {
    my ($self, $url, $file, $args) = @_;
    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
        or Carp::croak(q/Usage: $http->mirror(URL, FILE, [HASHREF])/ . "\n");
    if ( -e $file and my $mtime = (stat($file))[9] ) {
        $args->{headers}{'if-modified-since'} ||= $self->_http_date($mtime);
    }
    my $tempfile = $file . int(rand(2**31));

    require Fcntl;
    sysopen my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY()
        or Carp::croak(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;
    $args->{data_callback} = $self->_download_data_callback($fh, $args->{download_limit_bps});
    local $args->{download_limit_bps}; # so that request method does not set bandwith data callback
    my $response = $self->request('GET', $url, $args);
    close $fh
        or Carp::croak(qq/Error: Caught error closing temporary file $tempfile: $!\n/);

    if ( $response->{success} ) {
        rename $tempfile, $file
            or Carp::croak(qq/Error replacing $file with $tempfile: $!\n/);
        my $lm = $response->{headers}{'last-modified'};
        if ( $lm and my $mtime = $self->_parse_http_date($lm) ) {
            utime $mtime, $mtime, $file;
        }
    }
    $response->{success} ||= $response->{status} eq '304';
    unlink $tempfile;
    return $response;
}

1;
__END__

=encoding utf-8

=head1 NAME

HTTP::Tiny::Bandwidth - HTTP::Tiny with limitation of download/upload speed

=head1 SYNOPSIS

  use HTTP::Tiny::Bandwidth;

  my $http = HTTP::Tiny::Bandwidth->new;

  # limit download speed
  my $res = $http->get("http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz", {
    download_limit_bps => 5 * (1024**2), # limit 5Mbps
  });

  # you can save memory with mirror method
  my $res = $http->mirror(
    "http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz",
    "/path/to/save/perl-5.22.0.tar.gz",
    { download_limit_bps => 5 * (1024**2) }, # limit 5Mbps
  );

  # limit upload speed
  my $res = $http->post("http://example.com", {
    content_file     => "big-file.txt", # or content_fh
    upload_limit_bps => 5 * (1024**2),  # limit 5Mbps
  });

=head1 DESCRIPTION

HTTP::Tiny::Bandwidth is a subclass of L<HTTP::Tiny> which can limit download/upload speed.

If you want to use LWP::UserAgent with limitation of download/upload speed,
see L<eg|https://github.com/shoichikaji/HTTP-Tiny-Bandwidth/tree/master/eg> directory.

=head2 HOW TO LIMIT DOWNLOAD SPEED

HTTP::Tiny::Bandwidth's C<request/get/...> and C<mirror> methods accepts
C<download_limit_bps> option:

  my $http = HTTP::Tiny::Bandwidth->new;

  my $res = $http->get("http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz", {
    download_limit_bps => 5 * (1024**2),
  });

  my $res = $http->mirror(
    "http://www.cpan.org/src/5.0/perl-5.22.0.tar.gz",
    "/path/to/save/perl-5.22.0.tar.gz",
    { download_limit_bps => 5 * (1024**2) },
  );

=head2 HOW TO LIMIT UPLOAD SPEED

HTTP::Tiny::Bandwidth's C<request/post/put/...> methods accepts
C<content_file>, C<content_fh>, C<upload_limit_bps> options:

  my $http = HTTP::Tiny::Bandwidth->new;

  # content_file
  my $res = $http->post("http://example.com", {
    content_file     => "big-file.txt",
    upload_limit_bps => 5 * (1024**2), # limit 5Mbps
  });

  # or, you can specify content_fh
  open my $fh, "<", "big-file.txt" or die;
  my $res = $http->post("http://example.com", {
    content_fh       => $fh,
    upload_limit_bps => 5 * (1024**2), # limit 5Mbps
  });

=head1 SEE ALSO

L<HTTP::Tiny>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
