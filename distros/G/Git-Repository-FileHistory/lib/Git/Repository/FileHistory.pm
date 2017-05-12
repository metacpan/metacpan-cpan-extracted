package Git::Repository::FileHistory;
use strict;
use warnings;
use 5.008001;
our $VERSION = '0.06';

use Git::Repository::Log::Iterator;

sub new {
    my ($class, $repo, @files) = @_;

    my $args;
       $args = pop @files if ref $files[-1] eq 'HASH';

    my @cmd = ('--', @files);
    unshift @cmd, $args->{branch} if $args->{branch};

    my $iter = Git::Repository::Log::Iterator->new($repo, @cmd);
    my @logs;
    while ( my $log = $iter->next ){
        push @logs, $log;
    }

    bless {
        file_name => @files == 1 ? $files[0] : \@files,
        logs      => \@logs,
    }, $class;
}

sub file_name { shift->{file_name} }

sub logs {
    my $logs = shift->{logs};
    wantarray ? @$logs : $logs;
}

sub last_log  { shift->logs->[0]  }
sub first_log { shift->logs->[-1] }

sub created_at {
    my $first = shift->first_log;
    $first && $first->author_gmtime;
}

sub last_modified_at {
    my $last = shift->last_log;
    $last && $last->author_gmtime;
}
{
    no warnings 'once';
    *updated_at = *last_modified_at;
}

sub created_by {
    my $first = shift->first_log;
    $first && $first->author_name;
}

sub last_modified_by {
    my $last = shift->last_log;
    $last && $last->author_name;
}

1;
__END__

=for stopwords BooK

=head1 NAME

Git::Repository::FileHistory - Class representing file on git repository

=head1 SYNOPSIS

  # load the File plugin
  use Git::Repository 'FileHistory';
  
  my $repo = Git::Repository->new;
  my $file = $repo->file_history('somefile');
  
  print $file->created_at;
  print $file->created_by;
  print $file->last_modified_at;
  print $file->last_modified_by;

=head1 DESCRIPTION

Git::Repository::FileHistory is class representing file on git repository.

=head1 CONSTRUCTOR

=head2 new( $file_name )

Create a new C<Git::Repository::FileHistory> instance, using the file name
on git repository as parameter.

=head2 ACCESORS

The following accessors methods are recognized.

=over 5

=item created_at

Return epoch.

=item last_modified_at

Return epoch.

=item created_by

Return author name.

=item last_modified_by

Return author name.

=item logs

Return array of Git::Repository::Log objects

=back

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

BooK gives me many advice. Thanks a lot.

=head1 SEE ALSO

L<Git::Repository>
L<Git::Repository::Log>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
