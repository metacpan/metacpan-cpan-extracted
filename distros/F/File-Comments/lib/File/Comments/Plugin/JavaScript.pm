###########################################
# File::Comments::Plugin::JavaScript 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::JavaScript;
###########################################

use strict;
use warnings;
use File::Comments::Plugin::C;
our @ISA     = qw(File::Comments::Plugin::C);
use Log::Log4perl qw(:easy);


###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_suffix(".js");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "javascript";
}

###########################################
sub comments {
###########################################
    my($self, $target) = @_;

    return $self->extract_c_comments($target);
}

###########################################
sub extract_double_slash_comments {
# NOT USED ANYMORE, WE'RE USING C COMMENTS
###########################################
    my($self, $target) = @_;

    my @comments = ();

    while($target->{content} =~ 
            m#^\s*//(.*)
             #mxg) {
        push @comments, $1;
    }

    return \@comments;
}

1;

__END__

=head1 NAME

File::Comments::Plugin::JavaScript - Plugin to detect comments in JavaScript source code

=head1 SYNOPSIS

    use File::Comments::Plugin::JavaScript;

=head1 DESCRIPTION

File::Comments::Plugin::JavaScript is a plugin for the 
File::Comments framework.

// style comments are recognized.

This is I<not> a full-blown C parser/preprocessor yet, so it gets easily
confused (e.g. if c strings contain comment sequences).

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
