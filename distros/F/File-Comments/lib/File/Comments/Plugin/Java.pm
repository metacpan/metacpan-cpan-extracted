###########################################
# File::Comments::Plugin::Java 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::Java;
###########################################

use strict;
use warnings;
use File::Comments::Plugin::C;
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";
our @ISA     = qw(File::Comments::Plugin::C);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_suffix(".java");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "java";
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

1;

__END__

=head1 NAME

File::Comments::Plugin::Java - Plugin to detect comments in Java source code

=head1 SYNOPSIS

    use File::Comments::Plugin::Java;

=head1 DESCRIPTION

File::Comments::Plugin::Java is a plugin for the File::Comments framework.

Both /* ... */ and // style comments are recognized.

This is I<not> a full-blown C parser/preprocessor yet, so it gets easily
confused (e.g. if c strings contain comment sequences).

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
