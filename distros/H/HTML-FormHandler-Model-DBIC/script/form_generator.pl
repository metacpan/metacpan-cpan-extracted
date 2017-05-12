#!/usr/bin/perl
package form_generator;
# ABSTRACT: form generator
use strict;
use warnings;

use HTML::FormHandler::Generator::DBIC;
use lib ('lib');

my $generator = HTML::FormHandler::Generator::DBIC::Cmd->new_with_options();

print $generator->generate_form;

__END__

=pod

=encoding UTF-8

=head1 NAME

form_generator - form generator

=head1 VERSION

version 0.29

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
