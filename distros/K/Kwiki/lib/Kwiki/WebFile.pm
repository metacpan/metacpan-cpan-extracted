package Kwiki::WebFile;
use Kwiki::Base -Base;
use Spoon::Base 'conf';

our @EXPORT = qw(conf);

field path => [];
field files => [];
const default_path_method => 'default_path';

sub init {
    my $method = $self->default_path_method;
    $self->add_path(@{$self->$method});
}

sub add_file {
    my $file = shift
      or return;
    my $file_path = '';
    for (@{$self->path}) {
        $file_path = "$_/$file", last
          if -f "$_/$file";
    }
    my $files = $self->files;
    @$files = grep { not /\/$file$/ } @$files;
    push @$files, $file_path;
}

sub files_which_exist {
    grep {io->file($_)->exists} @{$self->files};
}

sub add_path {
    unshift @{$self->path}, @_;
}

sub clear_files {
    $self->files([]);
}

__DATA__

=head1 NAME

Kwiki::WebFile - Super Class for CSS & Javascript

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
