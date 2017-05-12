
use Cwd ();

my $CWD = Cwd::getcwd();

sub truncate_file ($;$) {
	my $file = shift;
	local *FILE;
	my $comment = shift;
	if (not defined $comment) {
		$comment = "truncate file [$file] (by opening for write)";
	}
	ok(open(FILE, '>', $file), $comment);
	is(close(FILE), 1, '  and close it');
}

sub append_to_file ($$@) {
	my ($file, $comment) = ( shift, shift );
	local *FILE;
	ok(open(FILE, '>>', $file), $comment);
	my $count = scalar(@_);
	is((print FILE map "$_\n", @_), 1, "  append $count line(s)");
	is(close(FILE), 1, '  and close the file');
}

sub check_status_file ($$$;$) {
	my ($status_file, $expected, $comment, $strict) = @_;
	local *CHECK;
	ok(open(CHECK, $status_file), "open the status file $status_file");
	my $check_status = join '', <CHECK>;
	$expected =~ s!^File \[!File [$CWD/! unless $strict;
	is($check_status, $expected, "  $comment");
	ok(close(CHECK), '  and close it again');
}

1;

