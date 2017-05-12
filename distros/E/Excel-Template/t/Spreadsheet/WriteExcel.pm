package Spreadsheet::WriteExcel;

use strict;

use mock;
use Spreadsheet::WriteExcel::Worksheet;

sub new {
    my $self = bless {
    }, shift;

    {
        local $" = "', '";
        push @mock::calls, ref($self) . "::new( '@_' )";
    }

    $self->{file} = shift;

    return $self;
}

sub close {
    my $self = shift;
    {
        local $" = "', '";
        push @mock::calls, ref($self) . "::close( '@_' )";
    }

    if ( ref $self->{file} ) {
        my $fh = $self->{file};
        print $fh join "\n", @mock::calls, ''; 
    }
}

sub add_worksheet {
    my $self = shift;
    {
        local $" = "', '";
        push @mock::calls, ref($self) . "::add_worksheet( '@_' )";
    }
    return Spreadsheet::WriteExcel::Worksheet->new;
}

my $format_num = 1;
sub add_format {
    my $self = shift;
    my %x = @_;
    my @x = map { $_ => $x{$_} } sort keys %x;
    {
        local $" = "', '";
        push @mock::calls, ref($self) . "::add_format( '@x' )";
    }
    return $format_num++;
}

1;
__END__
