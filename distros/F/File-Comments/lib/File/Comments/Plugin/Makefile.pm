###########################################
# File::Comments::Plugin::Makefile 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::Makefile;
###########################################

use strict;
use warnings;
use File::Comments::Plugin;
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";
our @ISA     = qw(File::Comments::Plugin);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_base("Makefile");
    $self->register_base("makefile");
    $self->register_suffix(".make");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "make";
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return $self->extract_hashed_comments($target);
}

###########################################
sub stripped {
###########################################
    my($self, $target) = @_;

    return $self->strip_hashed_comments($target);
}

###########################################
sub extract_hashed_comments {
###########################################
    my($self, $target) = @_;

    my @comments = ();

    while($target->{content} =~ m/^\s*#(.*)/mg) {
        push @comments, $1;
    }

    return \@comments;
}

###########################################
sub strip_hashed_comments {
###########################################
    my($self, $target) = @_;

    my $stripped = $target->{content};

    $stripped =~ s/^\s*#(.*)\n//mg;

    return $stripped;
}

1;

__END__

=head1 NAME

File::Comments::Plugin::Makefile - Plugin to detect comments in makefiles

=head1 SYNOPSIS

    use File::Comments::Plugin::Makefile;

=head1 DESCRIPTION

File::Comments::Plugin::Makefile is a plugin for the File::Comments framework.

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
