package Dir::Write::Rotate;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-17'; # DATE
our $DIST = 'Dir-Write-Rotate'; # DIST
our $VERSION = '0.004'; # VERSION

use strict;
use warnings;

use Fcntl qw(:DEFAULT);

sub _debug {
    return unless $ENV{DIR_WRITE_ROTATE_DEBUG};
    warn "[Dir::Write::Rotate] debug: $_[0]\n";
}

sub new {
    my ($pkg, %args) = @_;

    my $self = {};
    if (defined(my $v = delete $args{path})) {
        $self->{path} = $v;
    } else {
        die "Please specify path";
    }
    if (defined(my $v = delete $args{filename_pattern})) {
        $self->{filename_pattern} = $v;
    } else {
        $self->{filename_pattern} = '%Y-%m-%d-%H%M%S.pid-%{pid}.%{ext}';
    }
    if (defined(my $v = delete $args{filename_sub})) {
        $self->{filename_sub} = $v;
    }
    if (defined(my $v = delete $args{max_size})) {
        $self->{max_size} = $v;
    }
    if (defined(my $v = delete $args{max_files})) {
        $self->{max_files} = $v;
    }
    if (defined(my $v = delete $args{max_age})) {
        $self->{max_age} = $v;
    }
    if (defined(my $v = delete $args{rotate_probability})) {
        $self->{rotate_probability} = $v;
    } else {
        $self->{rotate_probability} = 0.25;
    }
    if (keys %args) {
        die "Unknown argument(s): ".join(", ", sort keys %args);
    }
    _debug "instantiated with params: ".
        join(", ", map {"$_=$self->{$_}"} sort keys %$self);
    bless $self, $pkg;
}

my $default_ext = 'log';
my $libmagic;
sub _resolve_pattern {
    my ($self, $content) = @_;

    if ($self->{filename_sub}) {
        return $self->{filename_sub}($self, $content);
    }

    require POSIX;

    my $pat = $self->{filename_pattern};
    my $now = time;

    my @vars = qw(Y y m d H M S z Z %);
    my $strftime = POSIX::strftime(join("|", map {"%$_"} @vars),
                                   localtime($now));
    my %vars;
    my $i = 0;
    for (split /\|/, $strftime) {
        $vars{ $vars[$i] } = $_;
        $i++;
    }

    push @vars, "{pid}";
    $vars{"{pid}"} = $$;

    push @vars, "{ext}";
    $vars{"{ext}"} = sub {
        unless (defined $libmagic) {
            if (eval { require File::LibMagic;
                       require Media::Type::Simple; 1 }) {
                $libmagic = File::LibMagic->new;
            } else {
                $libmagic = 0;
            }
        }
        return $default_ext unless $libmagic;
        my $type = $libmagic->checktype_contents($content);
        return $default_ext unless $type;
        $type =~ s/[; ].*//; # only get the mime type
        my $ext = Media::Type::Simple::ext_from_type($type);
        ($ext) = $ext =~ /(.+)/ if $ext; # untaint
        return $ext || $default_ext;
    };

    my $res = $pat;
    $res =~ s[%(\{\w+\}|\S)]
             [defined($vars{$1}) ?
                  ( ref($vars{$1}) eq 'CODE' ?
                        $vars{$1}->() : $vars{$1} ) :
                            die("Invalid format in filename_pattern `%$1'")]eg;
    $res;
}

sub write {
    my ($self, $content) = @_;

    my $filename0 = $self->_resolve_pattern($content);

    my $filename = "$self->{path}/$filename0";
    my $i = 0;
    my $fh;
    while (1) {
        if (-e $filename) {
            $i++;
            $filename = "$self->{path}/$filename0.$i";
            next;
        }
        # to avoid race condition
        sysopen($fh, $filename, O_WRONLY|O_CREAT|O_EXCL)
            or die "Can't open $filename: $!";
        last;
    }
    print $fh $content or die "Can't print to $filename: $!";
    close $fh or die "Can't write to $filename: $!";
    $self->rotate if (rand() < $self->{rotate_probability});
}

sub rotate {
    my $self = shift;

    my $ms = $self->{max_size};
    my $mf = $self->{max_files};
    my $ma = $self->{max_age};

    return unless (defined($ms) || defined($mf) || defined($ma));

    my @entries;
    my $now = time;
    my $path = $self->{path};
    opendir my $dh, $path or die "Can't open dir $path: $!";
    while (my $e = readdir $dh) {
        ($e) = $e =~ /(.*)/s; # untaint
        next if $e eq '.' || $e eq '..';
        my @st = stat "$path/$e";
        push @entries, {name => $e, age => ($now-$st[10]), size => $st[7]};
    }
    closedir $dh;

    @entries = sort {
        $a->{age} <=> $b->{age} ||
            $b->{name} cmp $a->{name}
    } @entries;

    # max files
    if (defined($mf) && @entries > $mf) {
        for (splice @entries, $mf) {
            my $fpath = "$path/$_->{name}";
            _debug "rotate: unlinking $fpath (max_files $mf exceeded)";
            unlink $fpath or warn "Can't unlink $fpath: $!";
        }
    }

    # max age
    if (defined($ma)) {
        my $i = 0;
        for (@entries) {
            if ($_->{age} > $ma) {
                for (splice @entries, $i) {
                    my $fpath = "$path/$_->{name}";
                    _debug "rotate: unlinking $fpath (age=$_->{age}) (max_age $ma exceeded)";
                    unlink $fpath or warn "Can't unlink $fpath: $!";
                }
                last;
            }
            $i++;
        }
    }

    # max size
    if (defined($ms)) {
        my $i = 0;
        my $tot_size = 0;
        for (@entries) {
            $tot_size += $_->{size};
            if ($tot_size > $ms) {
                for (splice @entries, $i) {
                    my $fpath = "$path/$_->{name}";
                    _debug "rotate: unlinking $fpath (size=$_->{size}) (max_size $ms exceeded)";
                    unlink $fpath or warn "Can't unlink $fpath: $!";
                }
                last;
            }
            $i++;
        }
    }
}

1;
# ABSTRACT: Write files to a directory, with rotate options

__END__

=pod

=encoding UTF-8

=head1 NAME

Dir::Write::Rotate - Write files to a directory, with rotate options

=head1 VERSION

This document describes version 0.004 of Dir::Write::Rotate (from Perl distribution Dir-Write-Rotate), released on 2020-11-17.

=head1 SYNOPSIS

 use Dir::Write::Rotate;

 my $dwr = Dir::Write::Rotate->new(
     path               => 'somedir.log',            # required
     filename_pattern   => '%Y-%m-%d-%H%M%S.pid-%{pid}.%{ext}', # optional
     filename_sub       => sub { ... },              # optional
     max_size           => undef,                    # optional
     max_files          => undef,                    # optional
     max_age            => undef,                    # optional
     rotate_probability => 0.25,                     # optional
 );

 # will write to a file in the dir and return its name
 $dwr->write("some\ncontents\n");

To limit total size of files in the directory, e.g. 10MB, set C<max_size> to
10*1024*1024. To limit number of files, e.g. 5000, set C<max_files> to 5000. To
keep only files that are at most 10 days old, set C<max_age> to 10*24*3600.

=head1 DESCRIPTION

This module provides a simple object for writing files to directory. There are
options to delete older files to keep the size of the directory in check.

=head1 METHODS

=head2 new

Syntax: $dwr = Dir::Write::Rotate->new(%args);

Constructor. Arguments:

=over

=item * path => str

The directory path to write to. Must already exist.

=item * filename_pattern => str

Names to give to each file, expressed in pattern a la strftime()'s. Optional.
Default is '%Y-%m-%d-%H%M%S.pid-%{pid}.%{ext}'. Time is expressed in local time.

If file of the same name already exists, a suffix ".1", ".2", and so on will be
appended.

Available pattern:

=over 8

=item %Y - 4-digit year number, e.g. 2009

=item %y - 2-digit year number, e.g. 09 for year 2009

=item %m - 2-digit month, e.g. 04 for April

=item %d - 2-digit day of month, e.g. 28

=item %H - 2-digit hour, e.g. 01

=item %M - 2-digit minute, e.g. 57

=item %S - 2-digit second, e.g. 59

=item %z - the time zone as hour offset from GMT

=item %Z - the time zone or name or abbreviation

=item %{pid} - Process ID

=item %{ext} - Guessed file extension

Try to detect appropriate file extension based on the content using
L<File::LibMagic> (if that module is available). For example, if message message
looks like an HTML document, then 'html'. If File::LibMagic is not available or
type cannot be detected, defaults to 'log'.

=item %% - literal '%' character

=back

=item * filename_sub => code

A more generic mechanism for B<filename_pattern>. If B<filename_sub> is given,
B<filename_pattern> will be ignored. The code will be called with the same
arguments as log_message() and is expected to return a filename. Will die if
code returns undef.

=item * max_size => num

Maximum total size of files, in bytes. After the size is surpassed, oldest files
(based on ctime) will be deleted. Optional. Default is undefined, which means
unlimited.

=item * max_files => int

Maximum number of files. After this number is surpassed, oldest files (based on
ctime) will be deleted. Optional. Default is undefined, which means unlimited.

=item * max_age => num

Maximum age of files (based on ctime), in seconds. After the age is surpassed,
files older than this age will be deleted. Optional. Default is undefined, which
means unlimited.

=item * rotate_probability => num

A number between 0 and 1 which specifies the probability that write() will call
rotate(). This is a balance between performance and rotate size accuracy. 1
means always rotate, 0 means never rotate. Optional. Default is 0.25.

=back

=head2 write

Syntax: $dwr->write($msg) => $filename

Write a file with content C<$msg>.

=head2 rotate

Will be called automatically by write.

=head1 ENVIRONMENT

=head2 DIR_WRITE_ROTATE_DEBUG

Bool. If set to true, will print debug messages to stderr (particularly when
instantiated and when deleting rotated files).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dir-Write-Rotate>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dir-Write-Rotate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dir-Write-Rotate>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Write::Rotate>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2017 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
