package Log::Log4perl::NDC::Scoped;

# Log4perl is compatible with perl 5.00503
# but through a source filter when installing
# We won't do that... :)

use 5.006;
use strict;
use warnings;
use Log::Log4perl;
use Carp qw(croak);
use base qw(Exporter);

our $VERSION = '0.02';
our @EXPORT_OK = qw(push_ndc);
our %EXPORT_TAGS = (all => \@EXPORT_OK);
our $SEPARATOR = '|';

sub _push {
    my ($class, @parts) = @_;

    croak "NDC is useless in void context!" unless defined wantarray;

    my $str = join $SEPARATOR, map { defined $_ ? $_ : '' } @parts;
    Log::Log4perl::NDC->push($str);

    return bless { ndc => $str }, $class;
}

sub DESTROY {
    Log::Log4perl::NDC->pop();
    return;
}

sub push_ndc {
    return __PACKAGE__->_push(@_);
}

1;

__END__


=head1 NAME

Log::Log4perl::NDC::Scoped - Scope aware NDC messages 
for Log4perl

=head1 SYNOPSIS

  use Log::Log4perl::NDC::Scoped qw(push_ndc);

  my $ndc = push_ndc('tag1', 'tag2'); 

=head1 SUBROUTINES

This module exports no subroutines by default. The following must be
explicitly imported when loading the module.

=head2 push_ndc($text1, $text2, ...)

Pushes an NDC in the scope where it is called and it pops it
automatically when the scope is abandoned or the variable explicitly
undefined. It separates the texts pushed with the value of 
$Log::Log4perl::NDC::Scoped::SEPARATOR variable (a pipe by default)

=head1 AUTHORS

Joni Salonen

Rafael Porres Molina

=head1 LICENCE AND COPYRIGHT

Copyright (C) 2012-2013 Qindel Formacion y Servicios S.L.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
