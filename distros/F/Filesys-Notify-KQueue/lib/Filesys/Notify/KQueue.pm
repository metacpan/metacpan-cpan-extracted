package Filesys::Notify::KQueue;
use strict;
use warnings;
our $VERSION = '0.11';

use File::Find ();
use IO::KQueue;

sub default_timeout { 1000 }

sub new {
    my $class = shift;
    my $args  = (@_ == 1) ? $_[0] : +{ @_ };
    my $self  = bless(+{} => $class);

    $self->timeout(exists $args->{timeout} ? $args->{timeout} : $class->default_timeout);
    $self->{_kqueue} = $args->{kqueue} if exists($args->{kqueue});
    $self->add(@{$args->{path}})       if exists($args->{path});

    return $self;
}

sub kqueue {
    my $self = shift;
    $self->{_kqueue} ||= IO::KQueue->new;
}

sub timeout {
    my $self = shift;
    (@_ == 1) ? ($self->{_timeout} = shift) : $self->{_timeout};
}

sub add {
    my $self = shift;

    foreach my $path (@_) {
        next if exists($self->{_files}{$path});
        if (-f $path) {
            $self->add_file($path);
        }
        elsif (-d $path) {
            $self->add_dir($path);
        }
        else {
            die "Unknown file '$path'";
        }
    }
}

sub add_file {
    my($self, $file) = @_;

    $self->{_files}{$file} = do {
        open(my $fh, '<', $file) or die("Can't open '$file': $!");
        die "Can't get fileno '$file'" unless defined fileno($fh);

        # add to watch
        $self->kqueue->EV_SET(
            fileno($fh),
            EVFILT_VNODE,
            EV_ADD | EV_CLEAR,
            NOTE_DELETE | NOTE_WRITE | NOTE_RENAME | NOTE_REVOKE,
            0,
            $file,
        );

        $fh;
    };
}

sub add_dir {
    my($self, $dir) = @_;

    $self->add_file($dir);
    File::Find::find +{
        wanted => sub { $self->add($File::Find::name) },
        no_chdir => 1,
    } => $dir;
}

sub files        { keys   %{shift->{_files}} }
sub file_handles { values %{shift->{_files}} }
sub get_fh       {
    my %files = %{shift->{_files}};
    @files{@_};
}

sub unwatch {
    my $self = shift;
    my @path = @_;

    foreach my $path (@_) {
        close($self->{_files}{$path});
        delete($self->{_files}{$path});
    }
}

sub wait {
    my ($self, $cb) = @_;

    my $events = $self->get_events;
    if ($self->timeout) {
        until (@$events) {
            $events = $self->get_events;
        }
    }

    $cb->(@$events);
}

sub get_events {
    my $self = shift;

    my @kevents = $self->kqueue->kevent($self->timeout);

    my @events;
    foreach my $kevent (@kevents) {
        my $path  = $kevent->[KQ_UDATA];
        my $flags = $kevent->[KQ_FFLAGS];

        if(($flags & NOTE_DELETE) or ($flags & NOTE_RENAME)) {
            my $event = ($flags & NOTE_DELETE) ? 'delete' : 'rename';

            if (-d $path) {
                my @stored_paths = grep { m{^${path}/} } $self->files;
                $self->unwatch(@stored_paths);
                push @events => map {
                    +{
                        event => $event,
                        path  => $_,
                    }
                } @stored_paths;
            }

            $self->unwatch($path);
            push @events => +{
                event => $event,
                path  => $path,
            };
        }
        elsif ($flags & NOTE_WRITE) {
            if (-f $path) {
                push @events => +{
                    event => 'modify',
                    path  => $path,
                };
            }
            elsif (-d $path) {
                File::Find::finddepth +{
                    wanted => sub {
                        return if exists($self->{_files}{$File::Find::name});
                        push @events => +{
                            event => 'create',
                            path  => $File::Find::name,
                        };
                        $self->add($File::Find::name);
                    },
                    no_chdir => 1,
                } => $path;
            }
        }
    }

    return \@events;
}

1;
__END__

=encoding utf-8

=for stopwords KQueue's

=head1 NAME

Filesys::Notify::KQueue - Wrap IO::KQueue for watching file system.

=head1 SYNOPSIS

  use Filesys::Notify::KQueue;

  my $notify = Filesys::Notify::KQueue->new(
      path    => [qw(~/Maildir/new)],
      timeout => 1000,
  );
  $notify->wait(sub {
      my @events = @_;

      foreach my $event (@events) {
          ## ....
      }
  });

=head1 DESCRIPTION

Filesys::Notify::KQueue is IO::KQueue wrapper for watching file system.

=head1 METHODS

=head2 new - Hash or HashRef

This is constructor method.

=over 4

=item path - ArrayRef[Str]

Watch files or directories.

=item timeout - Int

KQueue's timeout. (millisecond)

=back

=head2 wait - CodeRef

There is no file name based filter. Do it in your own code.
You can get types of events (create, modify, rename, delete).

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 SEE ALSO

L<IO::KQueue> L<Filesys::Notify::Simple> L<AnyEvent::Filesys::Notify> L<File::ChangeNotify> L<Mac::FSEvents> L<Linux::Inotify2>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
