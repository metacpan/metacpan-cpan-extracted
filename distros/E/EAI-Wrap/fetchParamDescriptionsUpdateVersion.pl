# enter new version to update all modules with
print "new version (empty to skip):";
$newVersion = <STDIN>;
chomp $newVersion;
# used for CONFIGURATION REFERENCE, fetches comments from %hashCheck in Common.pm and translates them to pod =items
open (COMMONFILE, "<".'lib\EAI\Common.pm') or die ('can\'t open lib\EAI\Common.pm for reading');
my $insertIntoEAIWrap;
my $return;
while (<COMMONFILE>){
	if (/my %hashCheck = \(/) {
		$startParsing = 1;
		$insertIntoEAIWrap.="=over 4\n\n";
		next;
	}
	next if !$startParsing;
	if (/\t\},/) {
		$insertIntoEAIWrap.="=back\n\n" if $return;
		$return = 0;
	}
	if (/^\t(\S*?) =>.*# (.*?)$/) {
		$insertIntoEAIWrap.="=item $1\n\n$2\n\n=over 4\n\n" if $2;
		$return = $2;
	}

	if (/^\t\t(\S*?) =>.*# (.*?)$/) {
		$insertIntoEAIWrap.="=item $1\n\n$2\n\n" if $2;
	}
	if (/^\);$/) {
		$insertIntoEAIWrap.="=back\n\n";
		last;
	}
}
close COMMONFILE;

my $data = read_file ("lib/EAI/Wrap.pm");
print "updating version and API descriptions for Wrap.pm\n";
$data =~ s/^(.*?)=head2 CONFIGURATION REFERENCE\n\n(.*?)=head1 COPYRIGHT(.*?)$/$1=head2 CONFIGURATION REFERENCE\n\n${insertIntoEAIWrap}=head1 COPYRIGHT$3/s;
$data =~ s/^package EAI::(.*?) (.*?);\n(.*?)/package EAI::$1 $newVersion;\n$3/s if $newVersion;
write_file("lib/EAI/Wrap.pm", $data);

for my $libfile ("Common","File","FTP","DB","DateUtil") {
	print "updating version for $libfile\n";
	my $data = read_file ("lib/EAI/$libfile.pm");
	$data =~ s/^package EAI::(.*?) (.*?);\n(.*?)/package EAI::$1 $newVersion;\n$3/s if $newVersion;
	write_file("lib/EAI/$libfile.pm", $data);
}

sub read_file {
	my ($filename) = @_;

	open my $in, '<:encoding(UTF-8)', $filename or die "Could not open '$filename' for reading $!";
	binmode($in);
	local $/ = undef;
	my $all = <$in>;
	close $in;

	return $all;
}

sub write_file {
	my ($filename, $content) = @_;

	open my $out, '>:encoding(UTF-8)', $filename or die "Could not open '$filename' for writing $!";
	binmode($out);
	print $out $content;
	close $out;

	return;
}
