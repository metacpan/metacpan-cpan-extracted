#!perl
package Test_Pod_Verbatim_Parser;
use warnings;
use strict;

use base 'Pod::Parser';

=head1 Synopsis

I<Disclaimer:> This is not intended to be a full-featured module (yet).

Background: I want all my examples in the POD to be real, executable code.

 use Test_Pod_Verbatim_Parser;
 # inherits from Pod::Parser
 my $parser = Test_Pod_Verbatim_Parser->new;
 $parser->parse_from_file($INPUTFILE, $OUTPUTFILE);

Or, from the shell:

 cat INPUTFILE | perl -MTest_Pod_Verbatim_Parser -e 'Test_Pod_Verbatim_Parser->new->parse_from_file' >OUTPUTFILE

This modle module takes verbatim blocks of POD and turns them into L<Test::More|Test::More>
test code. Try it out to see the details of the generated code.
It also recognizes the following special commands:

C<=begin test> and C<=end test> - between these markers,
any verbatim blocks are turned into code (this is the normal behavior anyway)
and any plain text blocks are turned into comments.
Other POD parsers should normally ignore everything between these markers
(unless they happen to recognize C<test> as a format).

C<=for test [CODE]> - whatever immediately follows (if anything) is added to the
test code. Like C<=begin test>, this should normally be ignored by other POD parsers.

C<=for test cut> - Normally, consecutive but seperate verbatim blocks are
joined into a single test. This command marks the break between two tests.

C<=for test ignore> - Turns on ignore mode; any verbatim and text blocks are ignored
until the next C<=for test [CODE]> (where C<CODE> is optional).

Possible To-Do for Later: Actually make this a real module distribution.

=head1 Author, Copyright, and License

Copyright (c) 2014 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command "C<perldoc perlartistic>" or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

sub initialize {
	my $self = shift;
    $self->SUPER::initialize(@_);
    $self->{_tv_ignoring} = 0;
    $self->{_tv_intestblock} = 0;
    $self->{_tv_buffer} = [];
    $self->{_tv_counter} = 0;
    return;
}

sub command {
	my ($self,$cmd,$text,$line) = @_;
	my ($format,$rest) = split ' ', $text, 2;
	return unless $format && $format eq 'test';
	if ($cmd eq 'for') {
		if ($rest=~/^\s*cut\s*$/) {
			$self->_take();
			return
		}
		if ($rest=~/^\s*ignore\b/) {
			$self->{_tv_ignoring} = 1;
			return
		}
		$self->{_tv_ignoring} = 0;
		$self->_gather($rest,$line);
	}
	elsif ($cmd eq 'begin') {
		$self->{_tv_intestblock} = 1;
		$self->_gather($rest,$line);
	}
	elsif ($cmd eq 'end') {
		$self->{_tv_intestblock} = 0;
	}
	return;
}

sub textblock {
	my ($self,$text,$line) = @_;
	$self->_gather($text,$line,'text') if $self->{_tv_intestblock};
	return;
}

sub verbatim {
	my ($self,$text,$line) = @_;
	$self->_gather($text,$line);
	return;
}

sub _gather {
	my ($self,$text,$line,$type) = @_;
	return if $self->{_tv_ignoring};
	$type ||= 'code';
	my $filename = $self->input_file || 'unknown_file';
	return unless $text=~/\S/;
	warn "wide verbatim block at $filename line $line\n"
		if $text=~/^.{76,}$/m;
	# remove indent based on first line
	my ($indent) = $text =~ /^(\s*)/;
	$text =~ s/^$indent//mg;
	$text =~ s/\s*$/\n/;
	$text =~ s/^/# /mg unless $type eq 'code';
	$text = "#line $line \"$filename\"\n".$text;
	push @{$self->{_tv_buffer}}, $text;
	return;
}

sub begin_pod {
	my $self = shift;
	$self->{_tv_counter} = 0;
	my $filename = $self->input_file || 'unknown_file';
	print {$self->output_handle} <<"END HEAD";
#!/usr/bin/env perl
use warnings FATAL=>'all';
use strict;
use Test::More;
BEGIN { note q{### Begin Tests Generated from "$filename" ###} }
END HEAD
	return;
}

sub _take {
	my ($self) = @_;
	return unless @{$self->{_tv_buffer}};
	my $code = join '', @{$self->{_tv_buffer}};
	$self->{_tv_buffer} = [];
	$code =~ s/^(?!#\s*line)/\t/mg;
	chomp($code);
	# Possible To-Do for Later: just dump code snippets into array so user can generate code themselves?
	# Possible To-Do for Later: It'd be nice if it were possible to reset the #line directive?
	# http://www.perlmonks.org/?node_id=1050862
	print {$self->output_handle} <<"END CODE";
{
	package Test_Pod_Verbatim_Parser::Generated$self->{_tv_counter};
	use Test::More;
${code}
#line 1 "generated code"
	ok 1, "generated test $self->{_tv_counter} executed ok";
}
END CODE
	$self->{_tv_counter}++;
	return;
}

sub end_pod {
	my $self = shift;
	$self->_take();
	my $filename = $self->input_file || 'unknown_file';
	print {$self->output_handle} <<"END FOOT";
done_testing;
note q{### End Tests Generated from "$filename" ###};
1;
END FOOT
	return;
}

1;
