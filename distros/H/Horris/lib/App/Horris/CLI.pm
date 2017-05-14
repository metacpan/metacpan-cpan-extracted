package App::Horris::CLI;
# ABSTRACT: Command Line Interface For Horris etc scripts


use Moose;
use namespace::autoclean;
extends 'MooseX::App::Cmd';

1;

__END__
=pod

=encoding utf-8

=head1 NAME

App::Horris::CLI - Command Line Interface For Horris etc scripts

=head1 VERSION

version v0.1.2

=head1 SYNOPSIS

    horris
    # output all available command list & help

=head1 AUTHOR

hshong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by hshong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

