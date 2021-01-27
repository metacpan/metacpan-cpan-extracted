package File::Find::Rule::BOM;

use base qw(File::Find::Rule);
use strict;
use warnings;

use String::BOM qw(file_has_bom);

our $VERSION = 0.03;

# Detect BOM.
sub File::Find::Rule::bom {
	my $file_find_rule = shift;
	return _bom($file_find_rule);
}

# Detect UTF-8 BOM.
sub File::Find::Rule::bom_utf8 {
	my $file_find_rule = shift;
	return _bom($file_find_rule, 'UTF-8');
}

# Detect UTF-16 BOM.
sub File::Find::Rule::bom_utf16 {
	my $file_find_rule = shift;
	return _bom($file_find_rule, 'UTF-16');
}

# Detect UTF-32 BOM.
sub File::Find::Rule::bom_utf32 {
	my $file_find_rule = shift;
	return _bom($file_find_rule, 'UTF-32');
}

sub _bom {
	my ($file_find_rule, $concrete_bom) = @_;
	my $self = $file_find_rule->_force_object;
	return $self->file->exec(sub{
		my $file = shift;
		my $bom = file_has_bom($file);
		return 0 unless $bom;
		if ($concrete_bom) {
			return $concrete_bom eq $bom ? 1 : 0
		} else {
			return 1;
		}
	});
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

File::Find::Rule::BOM - Common rules for searching for BOM in files.

=head1 SYNOPSIS

 use File::Find::Rule;
 use File::Find::Rule::BOM;

 my @files = File::Find::Rule->bom->in($dir);
 my @files = File::Find::Rule->bom_utf8->in($dir);
 my @files = File::Find::Rule->bom_utf16->in($dir);
 my @files = File::Find::Rule->bom_utf32->in($dir);

=head1 DESCRIPTION

This Perl module contains File::Find::Rule rules for detecting Byte Order Mark
in files.

BOM (Byte Order Mark) is a particular usage of the special Unicode character,
U+FEFF BYTE ORDER MARK, whose appearance as a magic number at the start of a
text stream can signal several things to a program reading the text.

See L<Byte order mark on Wikipedia|https://en.wikipedia.org/wiki/Byte order mark>.

=head1 SUBROUTINES

=head2 C<bom>

 my @files = File::Find::Rule->bom->in($dir);

The C<bom()> rule detect files with BOM.

=head2 C<bom_utf8>

 my @files = File::Find::Rule->bom_utf8->in($dir);

The C<bom_utf8()> rule detect files with UTf-8 BOM.

=head2 C<bom_utf16>

 my @files = File::Find::Rule->bom_utf16->in($dir);

The C<bom_utf16()> rule detect files with UTF-16 BOM.

=head2 C<bom_utf32>

 my @files = File::Find::Rule->bom_utf32->in($dir);

The C<bom_utf32()> rule detect files with UTF-32 BOM.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::BOM;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all files with BOM in directory.
 foreach my $file (File::Find::Rule->bom->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 EXAMPLE2

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::BOM;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all files with UTF-8 BOM in directory.
 foreach my $file (File::Find::Rule->bom_utf8->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 EXAMPLE3

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::BOM;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all files with UTF-16 BOM in directory.
 foreach my $file (File::Find::Rule->bom_utf16->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 EXAMPLE4

 use strict;
 use warnings;

 use File::Find::Rule;
 use File::Find::Rule::BOM;

 # Arguments.
 if (@ARGV < 1) {
         print STDERR "Usage: $0 dir\n";
         exit 1;
 }
 my $dir = $ARGV[0];

 # Print all files with UTF-32 BOM in directory.
 foreach my $file (File::Find::Rule->bom_utf32->in($dir)) {
         print "$file\n";
 }

 # Output like:
 # Usage: qr{[\w\/]+} dir

=head1 DEPENDENCIES

L<File::Find::Rule>,
L<String::BOM>.

=head1 SEE ALSO

=over

=item L<File::Find::Rule>

Alternative interface to File::Find.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/File-Find-Rule-BOM>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2015-2021

BSD 2-Clause License

=head1 VERSION

0.03

=cut
