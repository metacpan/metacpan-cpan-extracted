package MasonX::ProcessDir;
BEGIN {
  $MasonX::ProcessDir::VERSION = '0.02';
}
use Mason;
use Moose;
use strict;
use warnings;

extends 'Any::Template::ProcessDir';

has '+ignore_files'         => ( default => sub { sub { $_[0] =~ /Base\.|\.mason|\.mi$/ } } );
has '+template_file_suffix' => ( default => '.mc' );
has 'mason'                 => ( is => 'ro', init_arg => undef, lazy_build => 1 );
has 'mason_options'         => ( is => 'ro', default => sub { {} } );

sub _build_mason {
    my $self = shift;

    my $source_dir = $self->source_dir;
    my %options    = (
        comp_root => $source_dir,
        data_dir  => "$source_dir/.mason",
        %{ $self->mason_options }
    );
    return Mason->new(%options);
}

sub _build_process_file {
    return sub {
        my ( $file, $self ) = @_;
        my $comp_path = substr( $file, length( $self->source_dir ), -3 );
        return $self->mason->run($comp_path)->output;
    };
}

1;



=pod

=head1 NAME

MasonX::ProcessDir - Process a directory of Mason 2 templates

=head1 VERSION

version 0.02

=head1 SYNOPSIS

    use MasonX::ProcessDir;

    # Generate result files in the same directory as the templates
    #
    my $pd = MasonX::ProcessDir->new(
        dir => '/path/to/dir'
    );
    $pd->process_dir();

    # Generate result files in a separate directory
    #
    my $pd = MasonX::ProcessDir->new(
        source_dir => '/path/to/source/dir',
        dest_dir   => '/path/to/dest/dir'
    );
    $pd->process_dir();

=head1 DESCRIPTION

Recursively processes a directory of L<Mason 2|Mason> templates, generating a
set of result files in the same directory or in a parallel directory.

Every file with suffix ".mc" will be processed, and the results placed in a
file of the same name without the suffix. ".mi", autobase and dhandler files
will be used by Mason when processing the templates but will not generate files
themselves.

For example, if the source directory contains

   Base.mc
   httpd.conf.mc
   proxy.conf.mc
   etc/crontab.mc
   blah.mi
   somefile.txt

and we run

    my $pd = MasonX::ProcessDir->new(
        source_dir => '/path/to/source/dir',
        dest_dir   => '/path/to/dest/dir'
    );
    $pd->process_dir();

then afterwards the destination directory will contain files

    httpd.conf
    proxy.conf
    etc/crontab
    somefile.txt

where I<foo> and I<bar> are the results of processing I<foo.mc> and I<bar.mc>
through Mason. I<Base.mc> and I<blah.mi> may be used during Mason processing
but won't generate result files themselves.

This class is a convenience extension of
L<Any::Template::ProcessDir|Any::Template::ProcessDir>.

=head1 CONSTRUCTOR

=head2 Specifying directory/directories

=over

=item *

If you want to generate the result files in the B<same> directory as the
templates, just specify I<dir>.

    my $pd = MasonX::ProcessDir->new(
        dir => '/path/to/dir',
        ...
    );

=item *

If you want to generate the result files in a B<separate> directory from the
templates, specify I<source_dir> and I<dest_dir>.

    my $pd = MasonX::ProcessDir->new(
        source_dir => '/path/to/source/dir',
        source_dir => '/path/to/dest/dir',
        ...
    );

=back

=head2 Mason options

=over

=item mason_options

An optional hash of options to the Mason interpreter. For example, the default
Mason data directory will be ".mason" under the source directory, but you can
override this:

    mason_options => { data_dir => '/path/to/data/dir' }

=back

=head2 Options inherited from Any::Template::ProcessDir

See L<Any::Template::ProcessDir> for other options, such as

    dir_create_mode
    file_create_mode
    readme_filename

=head1 SUPPORT AND DOCUMENTATION

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=MasonX-ProcessDir
    bug-masonx-processdir@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-masonx-processdir
    git clone git://github.com/jonswar/perl-masonx-processdir.git

=head1 SEE ALSO

L<Mason>, L<Any::Template::ProcessDir>

=head1 AUTHOR

Jonathan Swartz <swartz@pobox.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Swartz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

