package Log::Dispatch::Dir;

our $DATE = '2019-01-09'; # DATE
our $VERSION = '0.160'; # VERSION

use 5.010001;
use warnings;
use strict;
use Log::Dispatch::Output;
use base qw(Log::Dispatch::Output);

use File::Slurper qw(write_text);
#use File::Stat qw(:stat); # doesn't work in all platforms?
use Params::Validate qw(validate SCALAR CODEREF);
use POSIX;

Params::Validate::validation_options( allow_extra => 1 );

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %p = @_;

    my $self = bless {}, $class;

    $self->_basic_init(%p);
    $self->_make_handle(%p);

    return $self;
}

sub _make_handle {
    my $self = shift;

    my %p = validate(
        @_,
        {
            dirname             => { type => SCALAR },
            permissions         => { type => SCALAR , optional => 1 },
            filename_pattern    => { type => SCALAR , optional => 1 },
            filename_sub        => { type => CODEREF, optional => 1 },
            max_size            => { type => SCALAR , optional => 1 },
            max_files           => { type => SCALAR , optional => 1 },
            max_age             => { type => SCALAR , optional => 1 },
            rotate_probability  => { type => SCALAR , optional => 1 },
        });

    $self->{dirname}            = $p{dirname};
    $self->{permissions}        = $p{permissions};
    $self->{filename_pattern}   = $p{filename_pattern} ||
        '%Y-%m-%d-%H%M%S.pid-%{pid}.%{ext}';
    $self->{filename_sub}       = $p{filename_sub};
    $self->{max_size}           = $p{max_size};
    $self->{max_files}          = $p{max_files};
    $self->{max_age}            = $p{max_age};
    $self->{rotate_probability} = ($p{rotate_probability}) || 0.25;
    $self->_open_dir();
}

sub _open_dir {
    my $self = shift;

    unless (-e $self->{dirname}) {
        my $perm = $self->{permissions} // 0755;
        mkdir($self->{dirname}, $perm)
            or die "Cannot create directory `$self->{dirname}: $!";
        $self->{chmodded} = 1;
    }

    unless (-d $self->{dirname}) {
        die "$self->{dirname} is not a directory";
    }

    if ($self->{permissions} && ! $self->{chmodded}) {
        chmod $self->{permissions}, $self->{dirname}
            or die "Cannot chmod $self->{dirname} to $self->{permissions}: $!";
        $self->{chmodded} = 1;
    }
}

my $default_ext = "log";
my $libmagic;

sub _resolve_pattern {
    my ($self, $p) = @_;
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
        my $p = shift;
        unless (defined $libmagic) {
            if (eval { require File::LibMagic; require Media::Type::Simple }) {
                $libmagic = File::LibMagic->new;
            } else {
                print "err = $@\n";
                $libmagic = 0;
            }
        }
        return $default_ext unless $libmagic;
        my $type = $libmagic->checktype_contents($p->{message} // '');
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
                        $vars{$1}->($p) : $vars{$1} ) :
                            die("Invalid filename_pattern `%$1'")]eg;
    $res;
}

sub log_message {
    my $self = shift;
    my %p = @_;

    my $filename0 = defined($self->{filename_sub}) ?
        $self->{filename_sub}->(%p) :
        $self->_resolve_pattern(\%p);

    my $filename = $filename0;
    my $i = 0;
    while (-e "$self->{dirname}/$filename") {
        $i++;
        $filename = "$filename0.$i";
    }

    write_text("$self->{dirname}/$filename", $p{message});
    $self->_rotate(\%p) if (rand() < $self->{rotate_probability});
}

sub _rotate {
    my ($self, $p) = @_;

    my $ms = $self->{max_size};
    my $mf = $self->{max_files};
    my $ma = $self->{max_age};

    return unless (defined($ms) || defined($mf) || defined($ma));

    my @entries;
    my $d = $self->{dirname};
    my $now = time;
    local *DH;
    opendir DH, $self->{dirname};
    while (my $e = readdir DH) {
        ($e) = $e =~ /(.*)/s; # untaint
        next if $e eq '.' || $e eq '..';
        my @st = stat "$d/$e";
        push @entries, {name => $e, age => ($now-$st[10]), size => $st[7]};
    }
    closedir DH;

    @entries = sort {$a->{age} <=> $b->{age}} @entries;

    # max files
    if (defined($mf) && @entries > $mf) {
        unlink "$d/$_->{name}" for (splice @entries, $mf);
    }

    # max age
    if (defined($ma)) {
        my $i = 0;
        for (@entries) {
            if ($_->{age} > $ma) {
                unlink "$d/$_->{name}" for (splice @entries, $i);
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
                unlink "$d/$_->{name}" for (splice @entries, $i);
                last;
            }
            $i++;
        }
    }
}

1;
# ABSTRACT: Log messages to separate files in a directory, with rotate options

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Dir - Log messages to separate files in a directory, with rotate options

=head1 VERSION

This document describes version 0.160 of Log::Dispatch::Dir (from Perl distribution Log-Dispatch-Dir), released on 2019-01-09.

=head1 SYNOPSIS

    use Log::Dispatch::Dir;

    my $dir = Log::Dispatch::Dir->new(
        name => 'dir1',
        min_level => 'info',
        dirname => 'somedir.log',
        filename_pattern => '%Y-%m-%d-%H%M%S.%{ext}',
    );
    $dir->log( level => 'info', message => 'your comment\n" );

    # limit total size
    my $dir = Log::Dispatch::Dir->new(
        # ...
        max_size => 10*1024*1024, # 10MB
    );

    # limit number of files
    my $dir = Log::Dispatch::Dir->new(
        # ...
        max_files => 1000,
    );

    # limit oldest file
    my $dir = Log::Dispatch::Dir->new(
        # ...
        max_age => 10*24*3600, # 10 days
    );

=head1 DESCRIPTION

This module provides a simple object for logging to directories under the
Log::Dispatch::* system, and automatically rotating them according to different
constraints. Each message will be logged to a separate file the directory.

Logging to separate files can be useful for example when dumping whole network
responses (like HTTP::Response content).

=head1 METHODS

=head2 new(%p)

This method takes a hash of parameters. The following options are valid:

=over 4

=item * name ($)

The name of the object (not the dirname!).  Required.

=item * min_level ($)

The minimum logging level this object will accept. See the Log::Dispatch
documentation on L<Log Levels|Log::Dispatch/"Log Levels"> for more information.
Required.

=item * max_level ($)

The maximum logging level this obejct will accept. See the Log::Dispatch
documentation on L<Log Levels|Log::Dispatch/"Log Levels"> for more information.
This is not required. By default the maximum is the highest possible level
(which means functionally that the object has no maximum).

=item * dirname ($)

The directory to write to.

=item * permissions ($)

If the directory does not already exist, the permissions that it should be
created with. Optional. The argument passed must be a valid octal value, such as
0700 or the constants available from Fcntl, like S_IRUSR|S_IWUSR|S_IXUSR.

See L<perlfunc/chmod> for more on potential traps when passing octal values
around. Most importantly, remember that if you pass a string that looks like an
octal value, like this:

 my $mode = '0644';

Then the resulting directory will end up with permissions like this:

 --w----r-T

which is probably not what you want.

=item * callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array reference of
subroutine references. These callbacks will be called in the order they are
given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a single scalar
containing that modified message. These callbacks will be called when either the
C<log> or C<log_to> methods are called and will only be applied to a given
message once.

=item * filename_pattern ($)

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

Try to detect appropriate file extension using L<File::LibMagic>. For example,
if log message looks like an HTML document, then 'html'. If File::LibMagic is
not available or type cannot be detected, defaults to 'log'.

=item %% - literal '%' character

=back

=item * filename_sub (\&)

A more generic mechanism for B<filename_pattern>. If B<filename_sub> is given,
B<filename_pattern> will be ignored. The code will be called with the same
arguments as log_message() and is expected to return a filename. Will die if
code returns undef.

=item * max_size ($)

Maximum total size of files, in bytes. After the size is surpassed, oldest files
(based on ctime) will be deleted. Optional. Default is undefined, which means
unlimited.

=item * max_files ($)

Maximum number of files. After this number is surpassed, oldest files
(based on ctime) will be deleted. Optional. Default is undefined, which means
unlimited.

=item * max_age ($)

Maximum age of files (based on ctime), in seconds. After the age is surpassed,
files older than this age will be deleted. Optional. Default is undefined, which
means unlimited.

=item * rotate_probability ($)

A number between 0 and 1 which specifies the probability that rotate()
will be called after each log_message(). This is a balance between performance
and rotate size accuracy. 1 means always rotate, 0 means never rotate. Optional.
Default is 0.25.

=back

=head2 log_message(message => $)

Sends a message to the appropriate output. Generally this shouldn't be called
directly but should be called through the C<log()> method (in
Log::Dispatch::Output).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Log-Dispatch-Dir>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Log-Dispatch-Dir>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-Dir>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Log::Dispatch>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019, 2017, 2015, 2014, 2013, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
