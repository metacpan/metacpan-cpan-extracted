package Spreadsheet::WriteExcel::Big;

use strict;

use vars qw/ @ISA /;
@ISA = qw( Spreadsheet::WriteExcel );

use Spreadsheet::WriteExcel;

use mock;

sub new {
    my $self = bless {
    }, shift;

    {
        local $" = "', '";
        push @mock::calls, ref($self) . "::new( '@_' )";
    }

    return $self;
}

1;
__END__
