package Devel::QuickCover::Report::Html;

use strict;
use warnings;
use autodie qw(open close chdir);

use Devel::QuickCover::Report;
use Devel::QuickCover::Report::Fetcher::Git;
use File::Copy;
use File::ShareDir;
use File::Spec::Functions;
use IO::Compress::Gzip;
use POSIX qw(strftime);
use Text::MicroTemplate;

our $VERSION = '0.01';

my %TEMPLATES = (
    file      => _get_template('file.tmpl'),
    index     => _get_template('index.tmpl'),
    header    => _get_template('header.tmpl'),
);

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        files       => [],
        directory   => $args{directory},
        compress    => $args{compress},
    }, $class;

    return $self;
}

sub add_report {
    my ($self, $report, $repositories) = @_;
    my $files = $report->filenames;
    my $lines = $report->coverage;
    my $subs = $report->subs;
    my ($prefix_rx, %prefix_map);

    if ($repositories && @$repositories) {
        my $prefix_pattern = join '|', map quotemeta($_->{prefix}), @$repositories;
        %prefix_map = map +($_->{prefix} => $_), @$repositories;
        $prefix_rx = qr{^($prefix_pattern)};
    }

    for my $file (@$files) {
        if ($prefix_rx && $file =~ $prefix_rx) {
            my $repository = $prefix_map{$1};

            $self->add_file(
                file_name       => $file,
                line_coverage   => $lines->{$file},
                sub_coverage    => $subs->{$file},
                git_repository  => $repository->{repository},
                git_commit      => $repository->{commit},
                git_prefix      => $repository->{prefix},
            );
        } else {
            $self->add_file(
                file_name       => $file,
                line_coverage   => $lines->{$file},
                sub_coverage    => $subs->{$file},
            );
        }
    }
}

sub add_file {
    my ($self, %args) = @_;
    my $item = $self->_make_item(\%args);

    push @{$self->{files}}, $item;
}

sub render {
    my ($self) = @_;
    my $date = POSIX::strftime('%c', localtime(time));
    my @existing;

    for my $item (@{$self->{files}}) {
        push @existing, $item if $self->_render_file($date, $item);
    }
    $self->render_main($date, \@existing);

    # copy CSS/JS
    File::Copy::copy(
        File::ShareDir::dist_file('Devel-QuickCover', 'quickcover.css'),
        File::Spec::Functions::catfile($self->{directory}, 'quickcover.css'));
    File::Copy::copy(
        File::ShareDir::dist_file('Devel-QuickCover', 'sorttable.js'),
        File::Spec::Functions::catfile($self->{directory}, 'sorttable.js'));
}

sub render_file {
    my ($self, %args) = @_;
    my $item = $self->_make_item(\%args);

    $self->_render_file($args{date}, $item);
}

sub render_main {
    my ($self, $date, $items) = @_;
    my @files = sort {
        $a->{display_name} cmp $b->{display_name}
    } @{$items || $self->{files}};

    $self->_write_template(
        $TEMPLATES{index},
        {
            date        => $date,
            files       => \@files,
            include     => \&_include,
            format_ratio=> \&_format_ratio,
            color_code  => \&_color_code,
        },
        $self->{directory},
        'index.html',
        $self->{compress},
    );
}

sub _make_item {
    my ($self, $args) = @_;
    my %item = (
        file_name       => $args->{file_name},
        report_name     => $args->{report_name} || $args->{file_name},
        display_name    => $args->{display_name} || $args->{file_name},
        line_coverage   => $args->{line_coverage},
        sub_coverage    => $args->{sub_coverage},
        git_repository  => $args->{git_repository},
        git_commit      => $args->{git_commit},
        git_prefix      => $args->{git_prefix},
    );
    my $line_covered = grep $_, values %{$item{line_coverage}};
    if (keys %{$item{line_coverage}}) {
        $item{line_percentage} = $line_covered / keys %{$item{line_coverage}};
    } else {
        $item{line_percentage} = 'NA';
    }
    if (keys %{$item{sub_coverage}}) {
        my $sub_covered = grep $_, values %{$item{sub_coverage}};
        $item{sub_percentage} = $sub_covered / keys %{$item{sub_coverage}};
    } else {
        $item{sub_percentage} = 'NA';
    }
    $item{report_name} =~ s{\W}{-}g;
    $item{report_name} .= '.html';

    return \%item;
}

sub _render_file {
    my ($self, $date, $item) = @_;
    my $source = $self->_fetch_source($item);

    return unless $source;
    my $lines = ['I hope you never see this...', split /\n/, $source];

    $self->_write_template(
        $TEMPLATES{file},
        {
            display_name    => $item->{display_name},
            line_coverage   => $item->{line_coverage},
            include         => \&_include,
            lines           => $lines,
            date            => $date,
        },
        $self->{directory},
        $item->{report_name},
        $self->{compress},
    );
    return 1;
}

sub _fetch_source {
    my ($self, $item) = @_;

    if ($item->{git_repository}) {
        my $fetcher = $self->{fetchers}{_fetcher_key($item)} ||= Devel::QuickCover::Report::Fetcher::Git->new(
            $item->{git_prefix}, $item->{git_repository}, $item->{git_commit},
        );
        my $source = $fetcher->fetch($item->{file_name});
        return $source ? $$source : undef;
    }

    return undef unless -f $item->{file_name};
    open my $fh, '<', $item->{file_name};
    local $/;
    return scalar readline $fh;
}

sub _fetcher_key {
    my ($item) = @_;

    return join "\x00",
        $item->{git_repository},
        $item->{git_commit},
        $item->{git_prefix};
}

sub _get_template {
    my ($basename) = @_;
    my $path = File::ShareDir::dist_file('Devel-QuickCover', $basename);
    my $tmpl = do {
        local $/;
        open my $fh, '<:encoding(UTF-8)', $path or die "Unable to open '$path': $!";
        readline $fh;
    };

    return Text::MicroTemplate::build_mt($tmpl);
}

sub _write_template {
    my ($self, $sub, $data, $dir, $file, $compress) = @_;
    my $text = $sub->($data) . "";
    my $target = File::Spec::Functions::catfile($dir, $file);

    utf8::encode($text) if utf8::is_utf8($text);
    open my $fh, '>', $compress ? "$target.gz" : $target;
    if ($compress) {
        IO::Compress::Gzip::gzip(\$text, $fh)
              or die "gzip failed: $IO::Compress::Gzip::GzipError";
    } else {
        print $fh $text;
    }
    close $fh;
}

sub _include {
    $TEMPLATES{$_[0]}->($_[1]);
}

sub _format_ratio {
    my ($ratio) = @_;
    return $ratio if $ratio eq 'NA';

    my $perc = $ratio * 100;
    if ($perc >= 0.01) {
        return sprintf '%.02f%%', $perc;
    } elsif ($perc >= 0.0001) {
        return sprintf '%.04f%%', $perc;
    } else {
        return '0';
    }
}

sub _color_code {
    my ($ratio) = @_;
    return $ratio if $ratio eq 'NA';

    if ($ratio < .75) {
        return 'coverage-red';
    } elsif ($ratio < .90) {
        return 'coverage-orange';
    } elsif ($ratio < 1) {
        return 'coverage-yellow';
    } else {
        return 'coverage-green';
    }
}

1;

__END__

=head1 NAME

Devel::QuickCover::Report::Html - Simple Devel::QuickCover report generator

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the MIT License.

=cut
