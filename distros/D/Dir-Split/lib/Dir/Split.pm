package Dir::Split;

use strict;
use warnings;
use boolean qw(true false);

use Carp qw(croak);
use File::Basename ();
use File::Copy ();
use File::Find ();
use File::Path ();
use File::Spec ();
use Params::Validate ':all';

our $VERSION = '0.81';

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

my %num_presets = (
    verbose   => false,
    override  => false,
    sort      => 'asc',
    limit     => 5,
    prefix    => 'sub',
    separator => '-',
    continue  => false,
    length    => 5,
);
my %char_presets = (
    verbose   => false,
    override  => false,
    prefix    => 'sub',
    separator => '-',
    case      => 'upper',
    length    => 1,
);

sub new
{
    my $class = shift;

    my $self = bless {}, ref($class) || $class;

    $self->_init(@_);

    return $self;
}

sub _init
{
    my $self = shift;
    my %opts = @_;

    validate(@_, {
        source => {
            type => SCALAR,
            callbacks => {
                'directory exists' => sub { -d $_[0] }
            },
        },
        target => {
            type => SCALAR,
            callbacks => {
                'directory exists' => sub { -d $_[0] }
            },
        },
    });

    foreach my $opt (qw(source target)) {
        $self->{ucfirst $opt} = $opts{$opt};
    }
}

sub split_num
{
    my $self = shift;

    $self->_validate_num(@_);

    $self->_init_mode(@_, \%num_presets);

    my ($dirs, $files) = $self->_gather_files;
    $self->_sort_files($files);

    my $suffix = $self->_get_num_suffix;
    $self->_move_num($files, $suffix);
}

sub _validate_num
{
    my $self = shift;

    validate(@_, {
        verbose => {
            type => BOOLEAN,
            optional => true,
        },
        override => {
            type => BOOLEAN,
            optional => true,
        },
        sort => {
            type => SCALAR,
            optional => true,
            regex => qr!^(?:asc|desc)$!,
        },
        limit => {
            type => SCALAR,
            optional => true,
            regex => qr!^\d+$!,
        },
        prefix => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S+$!,
        },
        separator => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S+$!,
        },
        continue => {
            type => BOOLEAN,
            optional => true,
        },
        length => {
            type => SCALAR,
            optional => true,
            regex => qr!^\d+$!,
        },
    });
}

sub split_char
{
    my $self = shift;

    $self->_validate_char(@_);

    $self->_init_mode(@_, \%char_presets);

    my ($dirs, $files) = $self->_gather_files;

    my %suffixes;
    $self->_get_char_suffixes($files, \%suffixes);
    $self->_move_char(\%suffixes);
}

sub _validate_char
{
    my $self = shift;

    validate(@_, {
        verbose => {
            type => BOOLEAN,
            optional => true,
        },
        override => {
            type => BOOLEAN,
            optional => true,
        },
        prefix => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S+$!,
        },
        separator => {
            type => SCALAR,
            optional => true,
            regex => qr!^\S+$!,
        },
        case => {
            type => SCALAR,
            optional => true,
            regex => qr!^(?:lower|upper)$!,
        },
        length => {
            type => SCALAR,
            optional => true,
            regex => qr!^\d+$!,
        },
    });
}

sub _init_mode
{
    my $self = shift;
    my $presets = pop;
    my %opts = @_;

    delete @$self{qw(exists failure track)};

    foreach my $opt (keys %num_presets, keys %char_presets) {
        delete $self->{ucfirst $opt};
    }
    foreach my $opt (keys %$presets) {
        $self->{ucfirst $opt} = $presets->{$opt};
    }
    foreach my $opt (keys %opts) {
        $self->{ucfirst $opt} = $opts{$opt};
    }

    $self->{track}{target}{dirs}  = 0;
    $self->{track}{target}{files} = 0;
}

sub _gather_files
{
    my $self = shift;

    my (@dirs, @files);

    File::Find::find({
        wanted => sub {
            push @dirs,  $File::Find::name if -d $_;
            push @files, $File::Find::name if -f $_;
        },
    }, $self->{Source});

    shift @dirs; # remove top-level directory

    $self->{track}{source}{dirs}  = scalar @dirs;
    $self->{track}{source}{files} = scalar @files;

    return (\@dirs, \@files);
}

sub _sort_files
{
    my $self = shift;
    my ($files) = @_;

    my %sort = (
        asc  => 'lc File::Basename::basename($a) cmp lc File::Basename::basename($b)',
        desc => 'lc File::Basename::basename($b) cmp lc File::Basename::basename($a)',
    );

    my $cmp = $sort{$self->{Sort}};

    @$files = sort { eval $cmp } @$files;
}

sub _get_num_suffix
{
    my $self = shift;

    if ($self->{Continue}) {
        my @dirs;
        $self->_read_dir($self->{Target}, \@dirs);

        # Leave files behind as we need to evaluate names of subdirs.
        @dirs = grep { -d File::Spec->catfile($self->{Target}, $_) } @dirs;

        my $continue = 0;

        foreach my $dir (@dirs) {
            if ($dir =~ /^(.+?)\Q$self->{Separator}\E([0-9]+)$/) {
                my ($prefix, $suffix) = ($1, $2);
                if ($prefix eq $self->{Prefix}
                 && length $suffix == $self->{Length}
                 && $suffix > $continue
                ) {
                    $continue = $suffix;
                }
            }
        }
        return sprintf "%0.$self->{Length}d", ++$continue;
    }
    else {
        return sprintf "%0.$self->{Length}d", 1;
    }
}

sub _get_char_suffixes
{
    my $self = shift;
    my ($files, $suffixes) = @_;

    my %alter = (
        lower => sub { lc $_[0] },
        upper => sub { uc $_[0] },
    );

    foreach my $file (@$files) {
        my $suffix = do {
            local $_ = File::Basename::fileparse($file, qr/(?<=\S)\.[^.]*/); # returns filename
            s/\s//g;
            $_ = substr($_, 0, $self->{Length});
            $alter{$self->{Case}}->($_);
        };
        push @{$suffixes->{$suffix}}, $file;
    }
}

sub _move_num
{
    my $self = shift;
    my ($files, $suffix) = @_;

    while (@$files) {
        my $target_path = $self->_make_path($suffix);
        my $copied = 0;
        my %seen;
        while ($copied < $self->{Limit} && @$files) {
            my $file = shift @$files;
            my $basename = File::Basename::basename($file);
            if ($seen{$basename}) {
                $self->_copy($file, $self->_make_path($suffix, $seen{$basename}));
            }
            else {
                $self->_copy($file, $target_path);
            }
            $seen{$basename}++;
            $copied++;
        }
        $suffix++;
    }
}

sub _move_char
{
    my $self = shift;
    my ($suffixes) = @_;

    foreach my $suffix (sort keys %$suffixes) {
        my $target_path = $self->_make_path($suffix);
        my %seen;
        while (my $file = shift @{$suffixes->{$suffix}}) {
            my $basename = File::Basename::basename($file);
            if ($seen{$basename}) {
                $self->_copy($file, $self->_make_path($suffix, $seen{$basename}));
            }
            else {
                $self->_copy($file, $target_path);
            }
            $seen{$basename}++;
        }
    }
}

sub _make_path
{
    my $self = shift;
    my ($suffix, $seen) = @_;

    my $target_path = File::Spec->catfile($self->{Target}, "$self->{Prefix}$self->{Separator}$suffix", defined $seen ? $seen : ());

    if (-e $target_path) {
        croak "Target path `$target_path' is not a directory" unless -d $target_path;
        return $target_path;
    }

    if (File::Path::mkpath($target_path, $self->{Verbose})) {
        $self->{track}{target}{dirs}++;
    }
    else {
        croak "Target directory `$target_path' cannot be created: $!";
    }

    return $target_path;
}

sub _copy
{
    my $self = shift;
    my ($file, $target_path) = @_;

    my $source_file = $file;
    my $target_file = File::Spec->catfile($target_path, File::Basename::basename($file));

    if (-e $target_file && !$self->{Override}) {
        push @{$self->{exists}}, $target_file;
        return;
    }

    if (File::Copy::copy($source_file, $target_file)) {
        print "copy $source_file -> $target_file\n" if $self->{Verbose};
        $self->{track}{target}{files}++;
    }
    else {
        push @{$self->{failure}{copy}}, $target_file;
    }
}

sub _read_dir
{
    my $self = shift;
    my ($dir, $files) = @_;

    opendir(my $dh, $dir) or croak "Cannot open directory `$dir': $!";
    @$files = grep !/^\.\.?$/, readdir($dh);
    closedir($dh) or croak "Cannot close directory `$dir': $!";
}

sub print_summary
{
    my $self = shift;

    return unless exists $self->{track};

    my %track = %{$self->{track}};

    my @output = (
        [ 'dirs',  $track{source}{dirs},  $track{target}{dirs}  ],
        [ 'files', $track{source}{files}, $track{target}{files} ],
    );

    format STDOUT_TOP =
Type      Source    Target
==========================
.
    foreach my $line (@output) {
        format STDOUT =
@<<<<<    @<<<<<    @<<<<<
@$line
.
        write;
    }
    print "\n";

    if (@{$self->{exists} || []}) {
        print <<'EOT';
Existing files
==============
EOT
        foreach my $file (@{$self->{exists}}) {
            print $file, "\n";
        }
        print "\n";
    }
    if (@{$self->{failure}{copy} || []}) {
        print <<'EOT';
Copy failures
=============
EOT
        foreach my $file (@{$self->{failure}{copy}}) {
            print $file, "\n";
        }
    }
}

1;
__END__

=head1 NAME

Dir::Split - Split files of a directory to subdirectories

=head1 SYNOPSIS

 use Dir::Split;

 $dir = Dir::Split->new(
     source => $source_dir,
     target => $target_dir,
 );

 $dir->split_num;

 # or

 $dir->split_num(
     verbose => 1,
     ...
 );

 $dir->print_summary;

=head1 DESCRIPTION

C<Dir::Split> splits files of a directory to subdirectories with a number or characters as suffix.

=head1 CONSTRUCTOR

=head2 new

Creates a new C<Dir::Split> object.

 $dir = Dir::Split->new(
     source => $source_dir,
     target => $target_dir,
 );

=over 4

=item * C<source>

Path to source directory.

=item * C<target>

Path to target directory.

=back

=head1 METHODS

=head2 split_num

Splits to subdirectories with number as suffix. Arguments to C<split_num()> are options
and not necessarily required.

 $dir->split_num(
     verbose   => [0|1],
     override  => [0|1],
     sort      => 'asc',
     limit     => 5,
     prefix    => 'sub',
     separator => '-',
     continue  => [0|1],
     length    => 5,
 );

=over 4

=item * C<verbose>

Be verbose. Accepts a boolean, defaults to false.

=item * C<override>

Replace existing files. Accepts a boolean, defaults to false.

=item * C<sort>

Sort mode. Accepts 'asc' for ascending, 'desc' for descending; defaults to ascending.

=item * C<limit>

Maximum of files per subdirectory. Accepts a number, defaults to 5.

=item * C<prefix>

Prefix of subdirectories. Accepts a string, defaults to 'sub'.

=item * C<separator>

Separator between prefix and suffix of subdirectory. Accepts a string, defaults to '-'.

=item * C<continue>

Resume suffix from ones already existing. Accepts a boolean, defaults to false.

=item * C<length>

Length of suffix. Accepts a number, defaults to 5.

=back

=head2 split_char

Splits to subdirectories with characters as suffix. Arguments to C<split_char()> are options
and not necessarily required.

 $dir->split_char(
     verbose   => [0|1],
     override  => [0|1],
     prefix    => 'sub',
     separator => '-',
     case      => 'upper',
     length    => 1,
 );

=over 4

=item * C<verbose>

Be verbose. Accepts a boolean, defaults to false.

=item * C<override>

Replace existing files. Accepts a boolean, defaults to false.

=item * C<prefix>

Prefix of subdirectories. Accepts a string, defaults to 'sub'.

=item * C<separator>

Separator between prefix and suffix of subdirectory. Accepts a string, defaults to '-'.

=item * C<case>

Case of suffix. Accepts 'lower' for lower case, 'upper' for upper case; defaults to upper case.

=item * C<length>

Length of suffix. Accepts a number, defaults to 1.

=back

=head2 print_summary

Prints a summary.

=head1 EXAMPLES

Assume the source directory contains following files:

 +- _123
 +- abcd
 +- efgh
 +- ijkl
 +- mnop

Splitting the source to the target directory could result in:

B<number as suffix>

 +- sub-00001
 +-- _123
 +-- abcd
 +- sub-00002
 +-- efgh
 +-- ijkl
 +- sub-00003
 +-- mnop

B<characters as suffix>

 +- sub-_
 +-- _123
 +- sub-A
 +-- abcd
 +- sub-E
 +-- efgh
 +- sub-I
 +-- ijkl
 +- sub-M
 +-- mnop

=head1 BUGS & CAVEATS

As of C<v0.80_01>, currently no value is returned from the splitting methods.
Also, direct access to global tracking and debug variables has been removed.
Furthermore, unlinking of source files and directories must be handled manually.

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
