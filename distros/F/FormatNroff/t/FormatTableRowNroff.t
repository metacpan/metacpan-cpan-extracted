print "1..1\n";

require HTML::FormatTableRowNroff;

my $table_row = new HTML::FormatTableRowNroff(align => 'center');

my $str1 = 'ghi';
my $str2 = 'jkl';

$table_row->add_element();
$table_row->add_text($str1);
$table_row->add_text($str2);

$table_row->end_element();

my $whole_str = $str1 . $str2;

if($table_row->text() eq $whole_str) {
    print "ok\n";
} else {
    print STDERR "text \"$whole_str\" check failed\n";

    print STDERR $table_row->text(), "not equal to \'abcdef\'\n";
    print "not ok\n";
}

1;

