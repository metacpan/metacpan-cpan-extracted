package Spreadsheet::WriteExcel::Worksheet;

use strict;

use mock;

sub new {
    my $self = bless {
    }, shift;

    {
        local $" = "', '";
        push @mock::calls, __PACKAGE__ . "::new( '@_' )";
    }

    return $self;
}

my @funcs = qw(
    write_string write_number write_blank write_url write_formula write_date_time write
    set_row set_column keep_leading_zeros insert_bitmap freeze_panes
    set_landscape set_portrait merge_range hide_gridlines autofilter write_comment
);

foreach my $func ( @funcs ) {
    no strict 'refs';
    *$func = sub {
        my $self = shift;
        local $" = "', '";
        push @mock::calls, __PACKAGE__ . "::${func}( '@_' )";
    };
}

1;
__END__
