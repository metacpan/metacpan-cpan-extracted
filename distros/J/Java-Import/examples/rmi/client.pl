use Java::Import qw(
	java.rmi.Naming
);

eval {
	my $remote_interface = java::rmi::Naming->lookup(jstring("//localhost/Hello"));
	my $bean = $remote_interface->getMessage(jstring("Hello From Perl"));
	print $bean->getValue(), "\n";
};

if ( $@ ) {
	$@->printStackTrace();
}
