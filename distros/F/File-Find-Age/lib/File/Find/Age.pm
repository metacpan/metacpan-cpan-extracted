package File::Find::Age;

use warnings;
use strict;

use File::Find::Rule;
use File::Spec;

our $VERSION = '0.01';

sub in {
    my $class = shift;
    my @paths =
        map { ref $_ eq 'ARRAY' ? File::Spec->catdir(@$_) : $_ }
        @_;

    return [
        sort { $a->{mtime} <=> $b->{mtime} }
        map { +{ mtime => (stat($_))[9], file => $_ } }    # 9 => mtime
        File::Find::Rule->file->in(@paths)
    ];
}

1;


__END__

=head1 NAME

File::Find::Age - mtime sorted files to easily find newest or oldest

=head1 SYNOPSIS

    my $oldest = shift(File::Find::Age->in('lib/', 't/'))->{file};
    my $newest = pop(File::Find::Age->in('lib/', 't/'))->{file};

    my $oldest_mtime = shift(File::Find::Age->in('lib/', 't/'))->{mtime};
    my $newest_mtime = pop(File::Find::Age->in('lib/', 't/'))->{mtime};

=head1 DESCRIPTION

=head1 METHODS

=head2 in(@folders)

Returns array ref with list of files found in C<@folders> sorted by mtime.

Sorted list includes one hash ref per file. Ex.:

$VAR1 = [
          {
            'mtime' => 1239916327,
            'file' => 't/00_compile.t'
          },
          {
            'mtime' => 1239916327,
            'file' => 't/pod-coverage.t'
          },
          {
            'mtime' => 1239916327,
            'file' => 't/distribution.t'
          },
          {
            'mtime' => 1239916327,
            'file' => 't/pod.t'
          },
          {
            'mtime' => 1284468458,
            'file' => 't/pod-spell.t'
          },
          {
            'mtime' => 1341080967,
            'file' => 'lib/File/Find/Age.pm'
          }
        ];

=head1 USAGE

I'm using it to find newest mtime of static web files and use this number
to invalidate browser cached versions of this files.

    <link href="/static/css/site.css?t=1341080054" rel="stylesheet">
    <script src="/static/js/site.js?t=1341080054"></script>

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<File::Find::Rule>

=head1 AUTHOR

Jozef Kutej

=cut
