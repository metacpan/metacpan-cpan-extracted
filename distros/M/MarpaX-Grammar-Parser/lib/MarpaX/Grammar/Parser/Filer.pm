package MarpaX::Grammar::Parser::Filer;

use strict;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use File::Basename;	# For basename().
use File::Spec;

use MarpaX::Grammar::Parser;

use Moo;

use Path::Tiny; # For path().

our $VERSION = '2.01';

# ------------------------------------------------

sub get_files
{
	my($self, $dir_name, $type) = @_;

	opendir(my $fh, $dir_name);
	my(@file) = sort grep{/$type$/} readdir $fh;
	closedir $fh;

	my(%file);

	for my $file_name (@file)
	{
		$file{basename($file_name, ".$type")} = $file_name;
	}

	return %file;

} # End of get_files.

# ------------------------------------------------

sub generate_trees
{
	my($self)     = @_;
	my($dir_name) = 'share';
	my(%files)    = $self -> get_files($dir_name, 'bnf');

	my($cooked_tree_file);
	my($marpa_bnf_file);
	my($parser);
	my($raw_tree_file);
	my($user_bnf_file);

	for my $key (keys %files)
	{
		$cooked_tree_file = path($dir_name, "$key.cooked.tree");
		$marpa_bnf_file   = path($dir_name, 'metag.bnf');
		$raw_tree_file    = path($dir_name, "$key.raw.tree");
		$user_bnf_file    = path($dir_name, "$key.bnf");
		$parser           = MarpaX::Grammar::Parser -> new
							(
								cooked_tree_file => "$cooked_tree_file",
								marpa_bnf_file   => "$marpa_bnf_file",
								raw_tree_file    => "$raw_tree_file",
								user_bnf_file    => "$user_bnf_file",
							);
	}

} # End of generate_trees.

# ------------------------------------------------

1;

=pod

=head1 NAME

L<MarpaX::Grammar::Parser::Filer> - Helps generate share/*.(cooked,raw).tree files

=head1 Synopsis

This module is only for use by the author of C<MarpaX::Grammar::Parser>.

See scripts/generate.demo.pl.

=head1 Description

C<MarpaX::Grammar::Parser::Filer> helps generate the share/*.(cooked,raw).tree files.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = MarpaX::Grammar::Parser::Filer -> new() >>.

It returns a new object of type C<MarpaX::Grammar::Parser::Filer>.

=head1 Methods

=head2 get_files($dir_name, $type)

Returns a hash (sic) of files from the given $dir_name, whose type (extension) matches $type.

The hash is keyed by the file's basename. See L<File::Basename>.

=head2 generate_trees()

Converts all share/*.bnf files into their corresponding share/*.(cooked,raw).tree versions using
scripts/generate.trees.pl.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Grammar::Parser>.

=head1 Author

L<MarpaX::Grammar::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
