# Copyright (C) 2008 Stephen Vance
# 
# This library is free software; you can redistribute it and/or
# modify it under the terms of the Perl Artistic License.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the Perl
# Artistic License for more details.
# 
# You should have received a copy of the Perl Artistic License along
# with this library; if not, see:
#
#       http://www.perl.com/language/misc/Artistic.html
# 
# Designed and written by Stephen Vance (steve@vance.com) on behalf
# of The MathWorks, Inc.

package Error::Exception::Test::Class;

use strict;
use warnings;

use base qw( Test::Unit::TestCase );

use Error::Exception::Class (
    'MyException' => {
        description => 'Test exception with no base',
    },

    'MyDerivedException' => {
        isa         => 'Test::Unit::TestCase', # Since it's convenient
        description => 'Test exception with non-Error::Exception base',
    },
);

sub new {
    my $self = shift()->SUPER::new(@_);

    return $self;
}

sub set_up {

    return;
}

sub tear_down {

    return;
}

sub test_exception_no_base {
    my $self = shift;

    my $ex = MyException->new();

    $self->assert( $ex->isa( 'Error::Exception' ) );

    return;
}

sub test_exception_with_other_base {
    my $self = shift;

    my $ex = MyDerivedException->new();

    $self->assert( ! $ex->isa( 'Error::Exception' ) );

    return;
}

1;
