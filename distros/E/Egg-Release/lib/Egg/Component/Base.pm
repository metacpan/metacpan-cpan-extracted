package Egg::Component::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 337 2008-05-14 12:30:09Z lushe $
#
use strict;
use warnings;

our $VERSION= '3.01';

sub _import         { @_ }
sub _startup        { @_ }
sub _setup          { @_ }
sub _setup_comp     { @_ }
sub _prepare        { @_ }
sub _dispatch       { @_ }
sub _action_start   { @_ }
sub _action_end     { @_ }
sub _finalize       { @_ }
sub _finalize_error { @_ }
sub _output         { @_ }
sub _finish         { @_ }
sub _result         { @_ }

1;

__END__

=head1 NAME

Egg::Component::Base - Base class for component.

=head1 SYNOPSIS

  package MyApp::Component;
  use base qw/
    MyApp::Component::Hoge
    MyApp::Component::Booo
    Egg::Component::Base
    /;
  
  __PACKAGE__->_setup;

=head1 DESCRIPTION

It is a convenient base class to construct the component of the L<Class::C3> base.

It has the method of the terminal for the following hook calls assumed beforehand.

_import, _startup, _setup, _prepare, _dispatch, _action_start, _action_end,
_finalize, _finalize_error, _output, _finish, _result

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Component>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

