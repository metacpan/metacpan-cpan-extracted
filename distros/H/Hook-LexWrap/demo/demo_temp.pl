use Hook::LexWrap;

my $temp;
sub set_temp {
	my $oldtemp = $temp;
	$temp = shift;
	print "Temp now $temp\n";
	return $oldtemp;
}

print "Setting temp to 73 F...\n";
my $prev = set_temp(73);
print "Temp was ", $prev||"undef", " F\n";

print "Setting temp to 98 F...\n";
$prev = set_temp(98);
print "Temp was ", $prev, " F\n";
	
{
        my $lexical = wrap set_temp,
                pre   => sub { splice @_, 0, 1, $_[0] * 1.8 + 32 },
                post  => sub { $_[-1] = ($_[0] - 32) / 1.8 };

	print "Setting temp to 73 C...\n";
	my $prev = set_temp(73);
	print "Temp was ", $prev, " C\n";
}

print "Setting temp to 98 F...\n";
$prev = set_temp(98);
print "Temp was ", $prev, " F\n";
