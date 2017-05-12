###########################################
# File::Comments::Plugin::PHP 
# 2005, Mike Schilli <cpan@perlmeister.com>
###########################################

###########################################
package File::Comments::Plugin::PHP;
###########################################

use strict;
use warnings;
use File::Comments::Plugin;
use File::Comments::Plugin::C;
use Log::Log4perl qw(:easy);

our $VERSION = "0.01";
our @ISA     = qw(File::Comments::Plugin::C);

###########################################
sub init {
###########################################
    my($self) = @_;

    $self->register_suffix(".php");
    $self->register_suffix(".PHP");
}

###########################################
sub type {
###########################################
    my($self, $target) = @_;

    return "php";
}

1;

__END__

=head1 NAME

File::Comments::Plugin::PHP - Plugin to detect comments in PHP source code

=head1 SYNOPSIS

    use File::Comments::Plugin::PHP;

=head1 DESCRIPTION

File::Comments::Plugin::PHP is a plugin for the File::Comments framework.

Both /* ... */ and // style comments are recognized.

This is I<not> a full-blown C parser/preprocessor yet, so it gets easily
confused (e.g. if c strings contain comment sequences).

=head1 LEGALESE

Copyright 2005 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2005, Mike Schilli <cpan@perlmeister.com>
