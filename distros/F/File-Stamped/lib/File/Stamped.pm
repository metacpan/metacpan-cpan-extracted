package File::Stamped;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.08';
use Carp ();
use POSIX ();
use SelectSaver ();
use File::Path ();
use File::Basename ();

sub new {
    my $class = shift;
    my %args = @_==1?%{$_[0]}:@_;
    if (exists($args{pattern}) && exists($args{callback})) {
        Carp::croak "Both 'pattern' and 'callback' cannot be specified.";
    }
    unless (exists($args{pattern}) || exists($args{callback})) {
        Carp::croak "You need to specify 'pattern' or 'callback'.";
    }
    if (defined $args{symlink} && ! -l $args{symlink} && -e _) {
        Carp::croak "File '$args{symlink}' already exists (not a symlink)"; 
    }
    my $callback = delete($args{callback}) || _make_callback_from_pattern(delete($args{pattern}));
    my $self = bless \do { local *FH }, $class;
    tie *$self, $class, $self;
    %args = (
        autoflush         => 1,
        close_after_write => 1,
        iomode            => '>>:utf8',
        rotationtime      => 1,
        callback          => $callback,
        auto_make_dir     => 0,
        %args,
    );
    for my $k (keys %args) {
        *$self->{$k} = $args{$k};
    }
    return $self;
}

sub TIEHANDLE {
    (
        ( defined( $_[1] ) && UNIVERSAL::isa( $_[1], __PACKAGE__ ) )
        ? $_[1]
        : shift->new(@_)
    );
}

sub PRINT     { shift->print(@_) }

sub WRITE     { shift->syswrite(@_) }

sub _gen_filename {
    my $self = shift;
    return *$self->{callback}->(*$self);
}

sub _make_callback_from_pattern {
    my ($pattern) = shift;

    return sub {
        my $self = shift;
        my $time = time();
        if ( $time > 1 ) {
            $time = $time - $time % $self->{rotationtime};
        }
        return POSIX::strftime($pattern, localtime($time));
    };
}

sub _gen_symlink {
    my ($self, $fname) = @_;

    if (defined(my $symlink = *$self->{symlink})) {
        if (-l $symlink) {
            my $link = readlink $symlink;
            if (defined $link && $link ne $fname) {
                unlink $symlink;
            }
        }
        symlink $fname, $symlink;
    }
}

sub _output {
    my ($self, $callback) = @_;

    my $fname = $self->_gen_filename();
    if (*$self->{auto_make_dir}) {
        File::Path::make_path(File::Basename::dirname($fname));
    }
    my $fh;
    if (*$self->{fh}) {
        if ($fname eq *$self->{fname} && *$self->{pid}==$$) {
            $fh = delete *$self->{fh};
        } else {
            my $fh = delete *$self->{fh};
            close $fh if $fh;
        }
    }

    $fh = $callback->($fh, $fname);

    if (*$self->{close_after_write}) {
        close $fh;
    } else {
        *$self->{fh}    = $fh;
        *$self->{fname} = $fname;
        *$self->{pid}   = $$;
    }
}

sub print {
    my $self = shift;

    my @msg = @_;

    $self->_output(sub {
        my ($fh, $fname) = @_;
        unless ($fh) {
            open $fh, *$self->{iomode}, $fname or die "Cannot open file($fname): $!";
            if (*$self->{autoflush}) {
                my $saver = SelectSaver->new($fh);
                $|=1;
            }
            $self->_gen_symlink($fname);
        }
        print {$fh} @msg
            or die "Cannot write to $fname: $!";

        $fh;
    });
}

sub syswrite {
    my $self = shift;

    my ($buf, @args) = @_;

    $self->_output(sub {
        my ($fh, $fname) = @_;
        unless ($fh) {
            open $fh, *$self->{iomode}, $fname or die "Cannot open file($fname): $!";
            $self->_gen_symlink($fname);
        }
        my $res = @args == 0 ? CORE::syswrite($fh, $buf)
                : @args == 1 ? CORE::syswrite($fh, $buf, $args[0])
                : @args == 2 ? CORE::syswrite($fh, $buf, $args[0], $args[1])
                : Carp::croak 'Too many arguments for syswrite';
        die "Cannot write to $fname: $!" unless $res;

        $fh;
    });
}

1;
__END__

=encoding utf8

=head1 NAME

File::Stamped - time stamped log file

=head1 SYNOPSIS

    use File::Stamped;
    my $fh = File::Stamped->new(pattern => '/var/log/myapp.log.%Y%m%d.txt');
    $fh->print("OK\n");

    # with Log::Minimal
    use Log::Minimal;
    my $fh = File::Stamped->new(pattern => '/var/log/myapp.log.%Y%m%d.txt');
    local $Log::Minimal::PRINT = sub {
        my ( $time, $type, $message, $trace) = @_;
        print {$fh} "$time [$type] $message at $trace\n";
    };

=head1 DESCRIPTION

File::Stamped is utility library for logging. File::Stamped object mimic file handle.

You can use "myapp.log.%Y%m%d.log" style log file.

=head1 METHODS

=over 4

=item my $fh = File::Stamped->new(%args);

This method creates new instance of File::Stamped. The arguments are followings.

You need to specify one of B<pattern> or B<callback>.

=over 4

=item pattern : Str

This is file name pattern. It is the pattern for filename. The format is POSIX::strftime(), see also L<POSIX>.

=item callback : CodeRef

You can use a CodeRef to generate file name.

File::Stamped pass only one arguments to callback function.

Here is a example code:

    my $pattern = '/path/to/myapp.log.%Y%m%d.log';
    my $f = File::Stamped->new(callback => sub {
        my $file_stamped = shift;
        local $_ = $pattern;
        s/!!/$$/ge;
        $_ = POSIX::strftime($_, localtime());
        return $_;
    });

=item close_after_write : Bool

Default value is 1.

=item iomode: Str

This is IO mode for opening file.

Default value is '>>:utf8'.

=item autoflush: Bool

This attribute changes $|.

=item rotationtime: Int

The time between log file generates in seconds. Default value is 1.

=item auto_make_dir: Bool

If this attribute is true, auto make directry of log file. Default value is false.

=item symlink: Str

generate symlink file for log file.

=back

=item $fh->print($str: Str)

This method prints the $str to the file.

=item $fh->syswrite($str: Str [, $len: Int, $offset: Int])

This method prints the $str to the file.
This method uses syswrite internally. Writing is not buffered.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ gmail.comE<gt>

=head1 SEE ALSO

L<Log::Dispatch::File::Stamped>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
