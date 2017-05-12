package HTML::Lint::Pluggable::TinyEntitesEscapeRule;
use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.08';

use parent qw/ HTML::Lint::Pluggable::WhiteList /;
use HTML::Entities qw/%char2entity/;

sub init {
    my($class, $lint) = @_;
    $class->SUPER::init($lint => +{
        rule => +{
            'text-use-entity' => sub {
                my $param = shift;
                return 0 if exists $char2entity{$param->{char}};
                return 1;
            }
        }
    });
}

1;
__END__

=head1 NAME

HTML::Lint::Pluggable::TinyEntitesEscapeRule - allow text-use-entity error if not supported by HTML::Entities

=head1 VERSION

This document describes HTML::Lint::Pluggable::TinyEntitesEscapeRule version 0.08.

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

Kenta Sato E<lt>karupa@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
