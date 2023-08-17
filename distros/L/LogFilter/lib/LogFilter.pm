package LogFilter;

use strict;
use warnings;

our $VERSION = '0.13'; # Incremented version number

use File::Tail;
use IO::File;

sub new {
    my ($class, $keywords_file, $exclude_file, $log_file, $interval) = @_;

    my @keywords;
    my @exclude;

    # Open and read keywords file
    my $fh = IO::File->new($keywords_file, 'r');
    if (defined $fh) {
        while (my $keyword = $fh->getline) {
            chomp $keyword;
            push @keywords, $keyword;
        }
        $fh->close;
    } else {
        die "Could not open file '$keywords_file': $!";
    }

    # Open and read exclude file
    $fh = IO::File->new($exclude_file, 'r');
    if (defined $fh) {
        while (my $exclude = $fh->getline) {
            chomp $exclude;
            push @exclude, $exclude;
        }
        $fh->close;
    } else {
        die "Could not open file '$exclude_file': $!";
    }

    my $self = {
        keywords_regex => join('|', map { "(?:$_)" } @keywords),
        exclude_regex => join('|', map { "(?:$_)" } @exclude),
        log_file => $log_file,
        interval => $interval || 1, # default interval is 1 second
    };

    return bless $self, $class;
}

sub filter {
    my ($self) = @_;

    my $file = File::Tail->new(name=>$self->{log_file}, interval=>$self->{interval});
    while (defined(my $line = $file->read)) {
        if ($line =~ /$self->{keywords_regex}/ && $line !~ /$self->{exclude_regex}/) {
            print $line;
        }
    }
}

1;

=head1 NAME

LogFilter - A simple log filtering module

=head1 SYNOPSIS

  use LogFilter;

  my $filter = LogFilter->new($keywords_file, $exclude_file, $log_file, $interval);

  $filter->filter;

=head1 DESCRIPTION

The LogFilter module provides an easy way to filter logs based on keywords and exclude words. 
It continuously reads a log file and prints lines that contain any of the provided keywords 
but do not contain any of the provided exclude words.

=head1 INSTALLATION

You can install this module:
  
  git clone https://github.com/kawamurashingo/LogFilter.git
  perl Makefile.PL
  make
  make test
  make install

=head1 METHODS

=over 4

=item new

Creates a new LogFilter object.

    my $filter = LogFilter->new($keywords_file, $exclude_file, $log_file, $interval);

Arguments:

- C<$keywords_file>: a file containing keywords, one per line.
- C<$exclude_file>: a file containing words to exclude, one per line.
- C<$log_file>: the log file to read.
- C<$interval>: the interval at which to read the log file, in seconds.

=item filter

Starts filtering the log file.

    $filter->filter;

This method will keep running until the program is terminated.

=back

=head1 EXAMPLE

Here is an example of how you might use this module:

  #!/usr/bin/perl

  use strict;
  use warnings;

  use LogFilter;

  my $keywords_file = '/path/to/keywords.txt';
  my $exclude_file = '/path/to/exclude.txt';
  my $log_file = '/path/to/my.log';
  my $interval = 1; # seconds

  my $filter = LogFilter->new($keywords_file, $exclude_file, $log_file, $interval);

  $filter->filter;

This script will now continuously print lines from C<my.log> that contain any of the keywords in C<keywords.txt>,
but do not contain any of the words in C<exclude.txt>.

The C<keywords.txt> and C<exclude.txt> files should contain one word per line. For example:

  # keywords.txt
  error
  warning
  failed

  # exclude.txt
  foobar

This will print lines that contain "error", "warning", or "failed", unless the line also contains "foobar".

=head1 SEE ALSO

L<File::Tail>, L<IO::File>

=head1 AUTHOR

Kawamura Shingo <pannakoota@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

