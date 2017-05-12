###########################################
# File::Comments::Plugin::C 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::C;
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

    $self->register_suffix(".c");
    $self->register_suffix(".cpp");
    $self->register_suffix(".cc");
    $self->register_suffix(".CC");
    $self->register_suffix(".C");
    $self->register_suffix(".h");
    $self->register_suffix(".H");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "c";
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return $self->extract_c_comments($target);
}

###########################################
sub stripped {
###########################################
    my($self, $target) = @_;

    return $self->strip_c_comments($target);
}

###########################################
sub extract_c_comments {
###########################################
    my($self, $target) = @_;

    my @comments = ();

        # This will get confused with c strings containing things
        # like "/*", but good enough for now until we can hook in a full 
        # C parser/preprocessor.
    while($target->{content} =~ 
            m#/\*(.*?)\*/|
              //(.*?)$
             #mxsg) {
        push @comments, defined $1 ? $1 : $2;
    }

    return \@comments;
}

###########################################
sub strip_c_comments {
###########################################
    my($self, $target) = @_;

    my @comments = ();

        # This will get confused with c strings containing things
        # like "/*", but good enough for now until we can hook in a full 
        # C parser/preprocessor.
    my $stripped = $target->{content};

    $stripped =~ 
            s#^\s*/\*.*?\*/(\s*\n)?|
              /\*.*?\*/|
              ^\s*//.*?\n|
              \s*//.*?$
             ##mxsg;

    return $stripped;
}

1;

__END__

=head1 NAME

File::Comments::Plugin::C - Plugin to detect comments in C/C++ source code

=head1 SYNOPSIS

    use File::Comments::Plugin::C;

=head1 DESCRIPTION

File::Comments::Plugin::C is a plugin for the File::Comments framework.

Both /* ... */ and // style comments are recognized.

This is I<not> a full-blown C parser/preprocessor yet, so it gets easily
confused (e.g. if c strings contain comment sequences).

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
