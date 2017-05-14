print "1..4\n";

require HTML::FormatTableCellNroff;

my $table_cell = new HTML::FormatTableCellNroff(colspan => 2,
						align => 'center');

if($table_cell->colspan() == 2) {
    print "ok\n";
} else {
    print STDERR "colspan check failed\n";
    print "not ok\n";
}

if($table_cell->alignment() eq 'center') {
    print "ok\n";
} else {
    print STDERR "align check failed\n";
    print "not ok\n";
}

$table_cell->add_text('abc');
$table_cell->add_text('def');

if($table_cell->text() eq 'abcdef') {
    print "ok\n";
} else {
    print STDERR "text check failed\n";
    print "not ok\n";
}

my $expected = 'c s';
my $format = $table_cell->format_str();
if($format eq $expected) {
    print "ok\n";
} else {
    print STDERR "format string check failed\n";
    print STDERR "Format string is \"$format\", not \"$expected\"\n";
    print "not ok\n";
}

1;

