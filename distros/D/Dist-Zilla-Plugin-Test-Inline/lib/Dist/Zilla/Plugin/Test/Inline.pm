use strict;
package Dist::Zilla::Plugin::Test::Inline;
# ABSTRACT: Create test files from inline tests in POD sections
# VERSION
$Dist::Zilla::Plugin::Test::Inline::VERSION = '0.011005';
#pod =head1 SYNOPSIS
#pod
#pod In your C<dist.ini>:
#pod
#pod 	[Test::Inline]
#pod
#pod In your module:
#pod
#pod 	# My/AddressRange.pm
#pod
#pod 	=begin testing
#pod
#pod 	use Test::Exception;
#pod 	dies_ok {
#pod 		My::AddressRange->list_from_range('10.2.3.A', '10.2.3.5')
#pod 	} "list_from_range() complains about invalid address";
#pod
#pod 	=end testing
#pod 	
#pod 	=cut
#pod 	
#pod 	sub list_from_range {
#pod 		# ...
#pod 	}
#pod
#pod This will result in a file C<t/inline-tests/my_addressrange.t> in your distribution.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin integrates L<Test::Inline> into C<Dist::Zilla>.
#pod
#pod It scans all non-binary files in the lib path of your distribution for inline
#pod tests in POD sections that are embedded between the keywords 
#pod
#pod 	=begin testing
#pod 	...
#pod 	=end testing
#pod
#pod These tests are then exported into C<t/inline-tests/*.t> files when
#pod C<Dist::Zilla> builds your module. Multiple of test sections may be specified
#pod within one file.
#pod
#pod Please note that this plugin (in contrast to pure L<Test::Inline>) can also
#pod handle L<Moops>-like class and role definitions.
#pod
#pod =head2 Files to be scanned for inline tests
#pod
#pod Only files already gathered by previous file gatherer plugins are scanned. In
#pod other words: tests will not be extracted for files which have been excluded.
#pod
#pod Example:
#pod
#pod 	[GatherDir]
#pod 	exclude_match = Hidden\.pm
#pod 	[Test::Inline] 
#pod
#pod This will lead to C<Dist::Zilla::Plugin::Test::Inline> ignoring C<Hidden.pm>. 
#pod
#pod =head1 ACKNOWLEDGEMENTS
#pod
#pod The code of this Dist::Zilla file gatherer plugin is based on
#pod L<https://github.com/moose/moose/blob/master/inc/ExtractInlineTests.pm>.
#pod
#pod =for :list
#pod * Dave Rolsky <autarch@urth.org>, who basically wrote most of this but left the
#pod   honor of making a plugin out of it to me ;-)
#pod
#pod =cut

use Moose;
with 
	# FileGatherer: turn this module as a Dist::Zilla plugin 
	'Dist::Zilla::Role::FileGatherer',
	# FileFinderUser: add $self->found_files function to this module  
	'Dist::Zilla::Role::FileFinderUser' => {   # where to take input files from
		default_finders => [ ':InstallModules', ':ExecFiles' ],
	},
	# PrereqSource: allows to register prerequisites
	'Dist::Zilla::Role::PrereqSource',
;

#pod =method gather_files
#pod
#pod Required by role L<Dist::Zilla::Role::FileGatherer>.
#pod
#pod Searches for inline test code in POD sections using L<Test::Inline>, creates
#pod in-memory test files and passes them to L<Dist::Zilla>.
#pod
#pod =cut
sub gather_files {
	my $self = shift;
	my $arg = shift;

	use Test::Inline;

	# give Test::Inline our own extract and output handlers
	my $inline = Test::Inline->new(
		verbose => 0,
		ExtractHandler => 'Dist::Zilla::Plugin::Test::Inline::Extract',
		OutputHandler => Dist::Zilla::Plugin::Test::Inline::Output->new($self),
	);

	# all files in the dist that match above filters (':InstallModules', ':ExecFiles')
	for my $file (@{$self->found_files}) {
		next if $file->is_bytes;
		$inline->add(\$file->content)
		  and $self->log("extracted inline tests from ".$file->name);
	}

	# add test files to Dist::Zilla distribution
	$inline->save;
}

#pod =method register_prereqs
#pod
#pod Required by role L<Dist::Zilla::Role::PrereqSource>.
#pod
#pod Adds L<Test::More> to the list of prerequisites (as L<Test::Inline> inserts
#pod C<use Test::More;>) for the distribution that uses this plugin.
#pod
#pod =cut
sub register_prereqs {
    my $self = shift;
    $self->zilla->register_prereqs(
        {
            type  => 'requires',
            phase => 'test',
        },
        'Test::More' => 0,
    );
}

#
# Used to connect Test::Inline to Dist::Zilla
# (write generated test code into in-memory files)
#
{
	package Dist::Zilla::Plugin::Test::Inline::Output;
$Dist::Zilla::Plugin::Test::Inline::Output::VERSION = '0.011005';
sub new {
		my $class = shift;
		my $dzil = shift;

		return bless { dzil => $dzil }, $class;
	}

	sub write {
		my $self = shift;
		my $name = shift;
		my $content = shift;

		use Dist::Zilla::File::InMemory;

		$self->{dzil}->add_file(
			Dist::Zilla::File::InMemory->new(
				name => "t/inline-tests/$name",
				content => $content,
			)
		);

		return 1;
	}
}
#
# Taken from https://github.com/moose/Moose/blob/master/inc/MyInline.pm
#
{
	package Dist::Zilla::Plugin::Test::Inline::Extract;
$Dist::Zilla::Plugin::Test::Inline::Extract::VERSION = '0.011005';
use parent 'Test::Inline::Extract';
	
	# Extract code specifically marked for testing
	our $search = qr/
		(?:^|\n)						   # After the beginning of the string, or a newline
		(								  # ... start capturing
										   # EITHER
			package\s+							# A package
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*	# ... with a name
			\s*;								  # And a statement terminator
		|								  # OR
			class\s+							# A class
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*	# ... with a name
			($|\s+|\s*{)						  # And some spaces or an opening bracket
		|								  # OR
			role\s+							# A role
			[^\W\d]\w*(?:(?:\'|::)[^\W\d]\w*)*	# ... with a name
			($|\s+|\s*{)						  # And some spaces or an opening bracket
		|								  # OR
			=for[ \t]+example[ \t]+begin\n		# ... when we find a =for example begin
			.*?								   # ... and keep capturing
			\n=for[ \t]+example[ \t]+end\s*?	  # ... until the =for example end
			(?:\n|$)							  # ... at the end of file or a newline
		|								  # OR
			=begin[ \t]+(?:test|testing)\b		# ... when we find a =begin test or testing
			.*?								   # ... and keep capturing
			\n=end[ \t]+(?:test|testing)\s*?	  # ... until an =end tag
			(?:\n|$)							  # ... at the end of file or a newline
		)								  # ... and stop capturing
		/isx;
	
	sub _elements {
		my $self	 = shift;
		my @elements = ();
		while ( $self->{source} =~ m/$search/go ) {
			my $element = $1;
			# rename "role" or "class" to "package" so Test::Inline understands
			$element =~ s/^(role|class)(\s+)/package$2/;
			$element =~ s/\n\s*$//;
			push @elements, $element;
		}
		
		(List::Util::first { /^=/ } @elements) ? \@elements : '';
	}
	
}


1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::Test::Inline - Create test files from inline tests in POD sections

=head1 VERSION

version 0.011005

=head1 SYNOPSIS

In your C<dist.ini>:

	[Test::Inline]

In your module:

	# My/AddressRange.pm

	=begin testing

	use Test::Exception;
	dies_ok {
		My::AddressRange->list_from_range('10.2.3.A', '10.2.3.5')
	} "list_from_range() complains about invalid address";

	=end testing
	
	=cut
	
	sub list_from_range {
		# ...
	}

This will result in a file C<t/inline-tests/my_addressrange.t> in your distribution.

=head1 DESCRIPTION

This plugin integrates L<Test::Inline> into C<Dist::Zilla>.

It scans all non-binary files in the lib path of your distribution for inline
tests in POD sections that are embedded between the keywords 

	=begin testing
	...
	=end testing

These tests are then exported into C<t/inline-tests/*.t> files when
C<Dist::Zilla> builds your module. Multiple of test sections may be specified
within one file.

Please note that this plugin (in contrast to pure L<Test::Inline>) can also
handle L<Moops>-like class and role definitions.

=head2 Files to be scanned for inline tests

Only files already gathered by previous file gatherer plugins are scanned. In
other words: tests will not be extracted for files which have been excluded.

Example:

	[GatherDir]
	exclude_match = Hidden\.pm
	[Test::Inline] 

This will lead to C<Dist::Zilla::Plugin::Test::Inline> ignoring C<Hidden.pm>. 

=head1 METHODS

=head2 gather_files

Required by role L<Dist::Zilla::Role::FileGatherer>.

Searches for inline test code in POD sections using L<Test::Inline>, creates
in-memory test files and passes them to L<Dist::Zilla>.

=head2 register_prereqs

Required by role L<Dist::Zilla::Role::PrereqSource>.

Adds L<Test::More> to the list of prerequisites (as L<Test::Inline> inserts
C<use Test::More;>) for the distribution that uses this plugin.

=head1 ACKNOWLEDGEMENTS

The code of this Dist::Zilla file gatherer plugin is based on
L<https://github.com/moose/moose/blob/master/inc/ExtractInlineTests.pm>.

=over 4

=item *

Dave Rolsky <autarch@urth.org>, who basically wrote most of this but left the honor of making a plugin out of it to me ;-)

=back

=head1 AUTHOR

Jens Berthold <jens.berthold@jebecs.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jens Berthold.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
