package Dispatch::Declare::Attr;

use strict;
use warnings;

use Attribute::Handlers;

our $VERSION = '0.1.2';

my $stash = {};
my $once  = [];

sub import {
    no strict 'refs';
    *{ caller() . '::run' } = \&run;
}

sub UNIVERSAL::Dispatch : ATTR(CODE) {
    my ( $package, $symbol, $referent, $attr, $data, $phase ) = @_;
    my $name = $data || *$symbol{NAME};
    $stash->{ uc $name } = $referent;
}

sub run {
    my $key = shift;
    if ( exists $stash->{ uc $key } ) {
        return $stash->{ uc $key }->(@_);
    }
    elsif ( exists $stash->{'DEFAULT'} ) {
        return $stash->{'DEFAULT'}->(@_);
    }
}

1;

__END__

=head1 NAME

Dispatch::Declare::Attr - Build a hash based dispatch table with Attributes


=head1 VERSION

This document describes Dispatch::Declare version 0.1.1

=head1 SYNOPSIS

    use Dispatch::Declare::Attr;

    my $action = 'ADD';

    run $action;

    sub repairdb : Dispatch {
        print 'This is a REPAIRDB test' . "\n";
    }

    sub adduser : Dispatch('ADD') {
        print 'This is a ADDUSER test' . "\n";
    }

=head1 DESCRIPTION

    This is another variation on the dispatch table that uses attributes.
    
=head1 Attribute

=over 4

=item Dispatch | Dispatch('name')

    sub repairdb : Dispatch { ... }
    
    sub adduser : Dispatch('ADD') { ... }

=back

=head1 GIT REPOSITORY

http://www.rlb3.com/Dispatch-Declare.git

=head1 CONFIGURATION AND ENVIRONMENT
  
Dispatch::Declare requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

1. The value part of the declare must be a code ref.
2. Only one dispatch table can be used.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-dispatch-declare@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Robert Boone  C<< <rlb@cpan.org> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Robert Boone C<< <rlb@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


    
    
