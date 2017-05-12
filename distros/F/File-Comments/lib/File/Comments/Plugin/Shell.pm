###########################################
# File::Comments::Plugin::Shell 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::Shell;
###########################################

use strict;
use warnings;
use File::Comments::Plugin;
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";
our @ISA     = qw(File::Comments::Plugin);

###########################################
sub applicable {
###########################################
    my($self, $target, $cold_call) = @_;

    return 1 unless $cold_call;

    return 1 if $target->{content} =~ m{^#!.*/(sh|bash|tcsh|csh|zsh)\b};

    return 0;
}

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_suffix(".sh");
    $self->register_suffix(".csh");
    $self->register_suffix(".tcsh");
    $self->register_suffix(".bash");
    $self->register_suffix(".zsh");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "shell";
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return File::Comments::Plugin::Makefile->extract_hashed_comments($target);
}

###########################################
sub stripped {
###########################################
    my($self, $target) = @_;

    return File::Comments::Plugin::Makefile->strip_hashed_comments($target);
}

1;

__END__

=head1 NAME

File::Comments::Plugin::Shell - Plugin to detect comments in shell scripts

=head1 SYNOPSIS

    use File::Comments::Plugin::Shell;

=head1 DESCRIPTION

File::Comments::Plugin::Shell is a plugin for the File::Comments framework.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
