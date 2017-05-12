package Hash::Persistent;

our $VERSION = '1.02'; # VERSION
# ABSTRACT: nested hashref serializable to the file


use strict;
use warnings;

use autodie qw( open close chmod rename );

use Data::Dumper;
use Storable qw(thaw nfreeze);
use JSON;
use Carp;

use Lock::File 1.01 qw(lockfile);

my %defaults = (
    read_only => 0,
    auto_commit => 0,
    format => 'auto',
    lock => 1,
    write_only => 0,
);

my $meta = {};

sub new {
    my $class = shift;
    my ($fname, $options, $lock_options) = @_;

    $lock_options ||= {};

    $options ||= {};
    my $_self = {%defaults, %$options};

    if ($options->{read_only} and $options->{auto_commit}) {
        croak "Only one of 'read_only' and 'auto_commit' options can be true";
    }

    if ($_self->{read_only}) {
        $_self->{auto_commit} = 0;
        $_self->{lock} = 0;
    }

    if ($_self->{lock}) {
        $lock_options = $_self->{lock} if ref $_self->{lock};
        my $lock = lockfile("$fname.lock", { mode => $_self->{mode}, blocking => 1, remove => 1, %$lock_options });
        unless (defined $lock) {
            return;
        }
        $_self->{lock} = $lock;
    }
    $_self->{fname} = $fname;

    my $self;
    if (-e $fname and not $_self->{write_only}) {
        open my $fh, '<', $fname;
        my $data;
        local $/;
        my $str = <$fh>;
        if ($str =~ m{^\$data = }) {
            eval $str;
            die "Can't eval $fname: $@" unless $data;
            die "Invalid data in $fname: $data" unless ref $data;
            $self = $data;
            $_self->{format} = 'dumper' if $_self->{format} eq 'auto';
        } elsif ($str =~ /^{/) {
            $self = JSON->new->decode($str);
            $_self->{format} = 'json' if $_self->{format} eq 'auto';
        }
        else {
            $self = thaw($str);
            $_self->{format} = 'storable' if $_self->{format} eq 'auto';
        }
    } else {
        $_self->{format} = 'json' if $_self->{format} eq 'auto'; # default format for new files
        $self = {};
    }

    bless $self => $class;
    $meta->{$self} = $_self;
    return $self;
}

sub commit {
    my $self = shift;
    my $_self = $meta->{$self};

    if ($_self->{removed}) {
        croak "$_self->{fname} is already removed and can't be commited";
    }
    if ($_self->{read_only}) {
        croak "Can't commit to $_self->{fname}, object is read only";
    }

    my $fname = $_self->{fname};
    my $tmp_fname = "$fname.tmp";
    open my $tmp, '>', $tmp_fname;

    my $serialized;
    if ($_self->{format} eq 'dumper') {
        my $dumper = Data::Dumper->new([ { %$self } ], [ qw(data) ]);
        $dumper->Terse(0); # somebody could enable terse mode globally; TODO - explicitly specify other options too?
        $dumper->Purity(1);
        $dumper->Sortkeys(1);
        $serialized = $dumper->Dump;
    }
    elsif ($_self->{format} eq 'json') {
        $serialized = JSON->new->encode({ %$self });
    }
    else {
        $serialized = nfreeze({ %$self });
    }
    print {$tmp} $serialized or die "print failed: $!";

    chmod $_self->{mode}, $tmp_fname if defined $_self->{mode};
    close $tmp;
    rename $tmp_fname => $fname;
}

sub DESTROY {
    local $@;
    my $self = shift;

    my $_self = $meta->{$self};
    if ($_self->{auto_commit} and not $self->{removed}) {
        my $commited = eval {
            $self->commit();
            1;
        };
        delete $meta->{$self}; # delete object anyway, commited or not
        unless ($commited) {
            ERROR $@;
        }
    }
    else {
        delete $meta->{$self};
    }
}

sub remove {
    my $self = shift;

    my $_self = $meta->{$self};
    if ($_self->{read_only}) {
        croak "Can't remove $_self->{fname}, object is read only";
    }
    if (-e $_self->{fname}) {
        unlink $_self->{fname} or die "Can't remove $_self->{fname}: $!";
    }
    if ($_self->{lock}) {
        my $lock_fname = $_self->{lock}->name;
        if (-e $lock_fname) {
            unlink $lock_fname or die "Can't remove $lock_fname: $!";
        }
    }
    $_self->{removed} = 1;
    delete $self->{$_} for keys %$self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Hash::Persistent - nested hashref serializable to the file

=head1 VERSION

version 1.02

=head1 SYNOPSIS

    use Hash::Persistent;

    $obj = Hash::Persistent->new("./obj.state"); # give a file to keep state
    $obj->{string} = "hello world"; # and use just like a regular perl hash
    $obj->commit; # save the data to the state file
    $obj->{string} = "world hello";
    undef $obj; # force destroying; data will not be saved

    $obj = Hash::Persistent->new("./obj.state", { auto_commit => 1 });
    $obj->{string} = "hello world";
    undef $obj; # the last update is commited

    $obj = Hash::Persistent->new("./obj.state", { read_only => 1 }); # do not flock
    print $obj->{string};
    $obj->{string} = "hello"; # ok, local modifications
    $obj->commit; # dies, cannot commit a readonly persistent

    $obj = Hash::Persistent->new("./obj.state", {}, {blocking => 0}); # pass some options to flock call

    $obj = Hash::Persistent->new("./obj.state", {format => "storable"});
    undef $obj; # recode state into storable format

    foreach my $key (%$obj) {} # $obj is guaranteed not to contain any internal keys

=head1 DESCRIPTION

C<Hash::Persistent> serializes its data to the single file using L<Data::Dumper>, L<Storable> or L<JSON>.

The object reads the state from given file when created, and writes the new state when destroyed.
No multithreading - the file is locked with C<flock> while object exists.

=head1 METHODS

=over

=item B<< new($options, $lock_options) >>

These constructor options are supported:

=over

=item I<auto_commit>

If true, state will be commited when object is destroyed.

It is recommended not to turn this option on and call C<commit()> explicitly every time, because perl ignores all exceptions thrown from destructors.

Off by default.

=item I<read_only>

If set, object can't be commited, I<auto_commit> can't be set, and object won't try to obtain a lock.

Off by default.

=item I<write_only>

Supressing the loading of data from an existing file. Useful for generating a new state and avoid failures if the previous one is currupted. It also can be used for minor performance improvements.

Off by default.

=item I<lock>

If true, take the global waiting lock for the whole lifetime of the object.

On by default.

=item I<mode>

If set, it will chmod the output file to the given value after each commit.

=item I<format>

Possible values: B<dumper>, B<storable>, B<json>.

If not specified and file already exists, will be detected automatically. If not specified and file doesn't exist, B<json> will be used as default.

B<json> format is fast, readable and secure, but can't serialize objects.

B<dumper> format is human-readable and can serialize objects, but insecure and slow.

B<storable> format can serialize objects and fast, but unreadable by humans and insecure.

=back

Additionally, any C<Lock::File> options can be passed as a third parameter.

=item B<< commit() >>

Write data on disk.

File will be written in atomic fashion, using tmpfile, so when disk is full, data will not be lost.

=item B<< remove() >>

Remove persistent file.

This method is lock-unsafe, which means that you shouldn't try to create persistent file again soon after this call.

=back

=head1 SEE ALSO

L<Hash::Persistent::Memory>

=head1 AUTHORS

=over 4

=item *

Vyacheslav Matyukhin <me@berekuk.ru>

=item *

Andrei Mishchenko <druxa@yandex-team.ru>

=item *

Artyom V. Kulikov <breqwas@yandex-team.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
