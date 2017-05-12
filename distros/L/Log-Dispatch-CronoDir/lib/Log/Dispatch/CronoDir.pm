package Log::Dispatch::CronoDir;
use 5.008001;
use strict;
use warnings;
use parent qw(Log::Dispatch::Output);

our $VERSION = "0.06";

use File::Path qw(make_path);
use Params::Validate qw(validate SCALAR BOOLEAN);
use Scalar::Util qw(openhandle);

Params::Validate::validation_options(allow_extra => 1);

sub new {
    my ($proto, %args) = @_;
    my $class = ref $proto || $proto;
    my $self = bless {}, $class;
    $self->_basic_init(%args);
    $self->_init(%args);
    $self;
}

sub _init {
    my $self = shift;
    my %args = validate(
        @_,
        {   dirname_pattern => { type => SCALAR },
            permissions     => {
                type    => SCALAR,
                optional => 1,
            },
            filename => { type => SCALAR },
            mode     => {
                type    => SCALAR,
                default => '>>',
            },
            binmode => {
                type     => SCALAR,
                optional => 1,
            },
            autoflush => {
                type    => BOOLEAN,
                default => 1,
            },
        }
    );

    my @rules;
    $args{dirname_pattern} =~ s{ \% (\w) }{
        $1 eq 'Y' ? do {
            push @rules, { pos => 5, offset => 1900 };
            '%04d';
        } : $1 eq 'm' ? do {
            push @rules, { pos => 4, offset => 1 };
            '%02d';
        } : $1 eq 'd' ? do {
            push @rules, { pos => 3, offset => 0 };
            '%02d';
        } : '';
    }egx;

    $self->{_rules}           = \@rules;
    $self->{_dirname_pattern} = $args{dirname_pattern};
    $self->{_permissions}     = $args{permissions};
    $self->{_filename}        = $args{filename};
    $self->{_mode}            = $args{mode};
    $self->{_binmode}         = $args{binmode};
    $self->{_autoflush}       = $args{autoflush};

    $self->_get_current_fh;
}

sub _localtime { localtime }

sub _find_current_dir {
    my $self = shift;
    my @now  = _localtime();
    sprintf(
        $self->{_dirname_pattern},
        map { $now[ $_->{pos} ] + $_->{offset} } @{ $self->{_rules} },
    );
}

sub _get_current_fh {
    my $self    = shift;
    my $dirname = $self->_find_current_dir;

    if (!exists $self->{_current_dir} || $dirname ne $self->{_current_dir}) {
        close $self->{_current_fh}
            if $self->{_current_fh} and openhandle($self->{_current_fh});

        make_path $dirname;
        $self->{_current_dir} = $dirname;
        $self->{_current_filepath} = File::Spec->catfile($dirname, $self->{_filename});

        if (defined $self->{_permissions}) {
            chmod $self->{_permissions}, $dirname
                or die "Failed chmod $dirname to $self->{_permissions}: $!";
        }

        open my $fh, $self->{_mode}, $self->{_current_filepath}
            or die "Failed opening file $self->{current_filepath} to write: $!";

        binmode $fh, $self->{_binmode} if $self->{_binmode};

        do {
            my $oldfh = select $fh;
            $| = 1;
            select $oldfh;
        } if $self->{_autoflush};

        $self->{_current_fh} = $fh;
    }

    $self->{_current_fh};
}

sub log_message {
    my ($self, %args) = @_;
    print { $self->_get_current_fh } $args{message}
        or die "Cannot write to file $self->{_current_file}: $!";
}

sub DESTROY {
    my $self = shift;
    close $self->{_current_fh}
        if $self->{_current_fh} and openhandle($self->{_current_fh});
}

1;
__END__

=encoding utf-8

=head1 NAME

Log::Dispatch::CronoDir - Log dispatcher for logging to time-based directories

=head1 SYNOPSIS

    use Log::Dispatch::CronoDir;

    my $log = Log::Dispatch::CronoDir->new(
        dirname_pattern => '/var/log/%Y/%m/%d',
        permissions     => 0777,
        filename        => 'output.log',
        mode            => '>>:unix',
        binmode         => ':utf8',
        autoflush       => 1,
    );

    # Write log to file `/var/log/2000/01/01/output.log`
    $log->log(level => 'error', message => 'Something has happened');

=head1 DESCRIPTION

Log::Dispatch::CronoDir is a file log dispatcher with time-based directory management.

=head1 METHODS

=head2 new(Hash %args)

Creates an instance.  Accepted hash keys are:

=over 4

=item dirname_pattern => Str

Directory name pattern where log files to be written to.
POSIX strftime's conversion characters C<%Y>, C<%m>, and C<%d> are currently accepted.

=item permissions => Octal

Directory permissions when specified directory does not exist. Optional.
When not specified, creating directory's permissions are based on current umask.

Note that this won't work on Windows OS.

=item filename => Str

Log file name to be written in the directory.

=item mode => Str

Mode to be used when opening a file handle.  Default: ">>"

=item binmode => Str

Binmode to specify with C<binmode>.  Optional.  Default: None

=item autoflush => Bool

Enable or disable autoflush.  Default: 1

=back

=head2 log(Hash %args)

Writes log to file.

=over 4

=item level => Str

Log level.

=item message => Str

A message to write to log file.

=back

=head1 SEE ALSO

L<Log::Dispatch>

=head1 LICENSE

Copyright (C) yowcow.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

yowcow E<lt>yowcow@cpan.orgE<gt>

=cut

