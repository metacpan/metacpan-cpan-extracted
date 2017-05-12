package Dist::Zilla::Plugin::CopyTo;
our $VERSION = '0.11';

use Moose;
use File::Glob qw/:glob/;
###use Smart::Comments;
with 'Dist::Zilla::Role::AfterBuild';

has 'dir' => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

sub mvp_multivalue_args { qw/dir/ }

sub after_build {
    my ( $self, $args ) = @_;
	my @dirs = @{ $self->{dir}};
	### @dirs: @dirs
    for my $dir ( @dirs ) {
		### dir: $dir
        $dir = bsd_glob($dir) if $dir =~ /^~/;
		### afterglob: $dir
        my $path = Path::Class::Dir->new($dir);
        for my $file ( @{ $self->zilla->files } ) {
            $self->_write_out_file( $file, $path );
        }
    }
}

sub _write_out_file {
    my ( $self, $file, $build_root ) = @_;

    my $file_path = Path::Class::file( $file->name );
    my $to_dir    = $build_root->subdir( $file_path->dir );
    my $to        = $to_dir->file( $file_path->basename );
    $to_dir->mkpath unless -e $to_dir;
    die "not a directory: $to_dir" unless -d $to_dir;

    #    Carp::croak("attempted to write $to multiple times") if -e $to;

    open my $out_fh, '>', "$to" or die "couldn't open $to to write: $!";
    print {$out_fh} $file->content;
    close $out_fh or die "error closing $to: $!";
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::CopyTo -  Copy to other places plugin for Dist::Zilla

=head1 SYNOPSIS

Used to copy the updated module to other directories. You can specify more
than one directory.

	#dist.ini
    [CopyTo]
	dir = ~/git/Perl-Dist-Zilla-Plugin-CopyTo
	dir = ~/svn/Perl-Dist-Zilla-Pulgin-CopyTo

=head1 AUTHOR
	
	Woosley.Xu 

=head1 COPYRIGHT & LICENSE

Copyright 2009, Woosley.Xu.

This program is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.
