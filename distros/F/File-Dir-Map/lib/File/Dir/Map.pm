package File::Dir::Map;
use common::sense;
use File::Copy;
use File::Find;
use File::Path qw(make_path remove_tree);
use English '-no_match_vars';
use base qw(Exporter);

our @EXPORT_OK = qw(dirmap);

=head1 NAME

File::Dir::Map - Map a directory recursively

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

The following snippet summarizes what File::Dir::Map does.

Files are copied from src to build dirs such that files
with extension ignore will not be copied, files with extension
markdown will get processed by markdown and saved in build dir,
and files with extension raw are guaranteed to be copied without
processing but stripped of the raw extension.

    use File::Dir::Map qw(dirmap);
    use Text::MultiMarkdown qw(markdown);
    
    dirmap src => build => {
        ignore => sub{ [] },
        raw    => sub{
            my( $name, $content ) = @_;
            [ $name, $content ];
        },
        markrown => sub{
            my( $name, $contnet ) = @_;
            [ "$name.html", markdown $content ]
        },
    };

So this before the map:

  src/pages/todo.ignore
  src/pages/index.markdown
  src/pages/about.html
  src/pages/index.markdown.raw
  src/files/
  build/some/junk/here.txt

Will be this after the map:

  src/pages/todo.ignore
  src/pages/index.markdown
  src/pages/about.html
  src/pages/index.markdown.raw
  src/files/
  build/pages/index.html
  build/pages/about.html
  build/pages/index.markdown
  build/files/

Note that old build directory is purged!

=head1 EXPORT

dirmap

=head1 SUBROUTINES/METHODS

=cut

sub inventory ($$) {
    my ( $dir, $familiar ) = @_;
    my $inv;
    find(
        sub {
            $File::Find::name =~ m{^$dir/(.*?)(?:\.(.*?))?$};
            if (-d) {
                push @{ $inv->{dirs} }, $1 if $1;
            }
            elsif ( grep { $_ eq $2 } @$familiar ) {
                $inv->{items}->{$1}->{$2} = $File::Find::name;
            }
            else {
                $inv->{files}->{ $1 . ( $2 ? ".$2" : '' ) } = $File::Find::name;
            }
        },
        $dir
    );
    $inv;
}

=head2 dirmap $dir_from, $dir_to, $funcs

$funcs is a hashref with file extensions as keys and mapping functions as
values.

Each mapping function takes two arguments: filename stripped of the extension
and file contents.

Each mapping function should return a listref that's either empty or contains
two elements: new filename and new content.  In case the listref is empty,
file will not be saved in the destination directory.

=cut

sub dirmap ($$$) {
    my ( $dir_from, $dir_to, $funcs ) = @_;
    my $inv = inventory $dir_from => [ keys %$funcs ];
    remove_tree( $dir_to, { keep_root => 1, safe => 1 } );
    make_path( map { join '/', $dir_to, $_ } sort @{ $inv->{dirs} } );
    copy( $inv->{files}->{$_}, join '/', $dir_to, $_ )
      for keys %{ $inv->{files} };

    for my $item ( keys %{ $inv->{items} } ) {
        for my $type ( keys %{ $inv->{items}->{$item} } ) {
            open my $fh, '<', $inv->{items}->{$item}->{$type};
            local $INPUT_RECORD_SEPARATOR = undef;
            my $content_in = <$fh>;
            close $fh;

            my ( $filename, $content_out ) =
              @{ $funcs->{$type}->( $item, $content_in ) };

            if ($filename) {
                open my $fh, '>', join '/', $dir_to, $filename or die $ERRNO;
                print $fh $content_out;
                close $fh;
            }
        }
    }
}

=head1 AUTHOR

Eugene Grigoriev, C<< <perl at sizur.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-dir-map at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Dir-Map>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Dir::Map


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Dir-Map>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Dir-Map>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Dir-Map>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Dir-Map/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Eugene Grigoriev.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of File::Dir::Map
