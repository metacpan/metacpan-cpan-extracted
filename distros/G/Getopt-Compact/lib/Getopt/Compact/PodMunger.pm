# $Id: PodMunger.pm 15 2006-09-04 20:00:01Z andrew $
# Copyright (c) 2006 Andrew Stewart Williams. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Getopt::Compact::PodMunger;
use strict;
use Pod::Parser;
use base qw/Pod::Parser/;
use vars qw/$VERSION/;

$VERSION = "0.04";

# section ordering.
use constant SECTION_ORDER =>
    (qw/NAME SYNOPSIS USAGE REQUIRES EXPORTS DESCRIPTION METHODS DIAGNOSTICS
     NOTES VERSION AUTHOR/, 'SEE ALSO', qw/BUGS ACKNOWLEDGEMENTS/,
     'COPYRIGHT AND LICENSE');

###################
# Pod::Parser API #
sub command { 
    my($self, $command, $paragraph, $line_num) = @_;
    my($sect) = $paragraph =~ /(\w+)/;
    $self->_addsect($sect) if $command eq 'head1';
    $self->_addpod("=$command $paragraph");
}

sub verbatim {
    my($self, $paragraph, $line_num) = @_;
    $self->_addpod($paragraph);
}

sub textblock { 
    my($self, $paragraph, $line_num) = @_;
    $self->_addpod($paragraph);
}

sub begin_input {
    my $self = shift;
    # use _pod as a scratch space between sections (chunks)
    $self->{_pod} = '';
    $self->{_sections} = {};
    $self->{_chunk} = [];
}

sub end_input {
    my $self = shift;
    $self->_addsect;  # add the final section
}
####################

# return the pod as a single chunk of text.  make sure commands are
# separated by a blank line.
sub as_string {
    my $self = shift;
    my @chunks;
    for my $c ($self->_chunks) {
	$c =~ s/\s+$//s;
	push @chunks, $c;
    }
    return join("\n\n", @chunks);
}

sub print_manpage {
    my $self = shift;
    my $pod = $self->as_string;
    
    require Pod::Simple::Text::Termcap;
    my $pt = new Pod::Simple::Text::Termcap;
    $pt->parse_string_document($pod);
}

sub insert {
    my($self, $section, $content, $is_verbatim) = @_;
    
    $section = uc($section);
    return if $self->_has_section($section); # don't clobber existing sections
    return unless defined $content;          # skip undefined content

    my @chunks = $self->_chunks;
    my %known_section = map { $_ => 1 } SECTION_ORDER;
    my(@newchunks, $pod, $after);
    
    # decide where to insert section
    my @sects = reverse SECTION_ORDER;
    while(@sects) {
	$after = shift @sects;
	# find section we are inserting in reverse section order list.
	next unless $after eq $section || !$known_section{$section};
	# find the next highest existing section.  we will insert after that
	($after) = grep $self->_has_section($_), @sects;
	last;
    }

    $content =~ s/^(\s*\S+)/    $1/gm if $is_verbatim;  # indent
    $pod = qq/=head1 $section\n\n$content/;

    if(defined $after) {
	for my $c (@chunks) {
	    push @newchunks, $c;
	    push @newchunks, $pod if $c =~ /^=head1 $after/;
	}
    } else {
	@newchunks = ($pod, @chunks);
    }
    $self->{_chunk} = \@newchunks;
    $self->{_sections}->{$section} = 1;
}

# private methods

sub _addpod {
    my($self, @text) = @_;
    $self->{_pod} .= join('', @text);
}

sub _addsect {
    my($self, $sect) = @_;
    push @{$self->{_chunk}}, $self->{_pod} if $self->{_pod};
    $self->{_sections}->{$sect} = 1 if defined $sect;
    $self->{_pod} = '';
}

sub _chunks {
    my($self) = @_;
    return @{$self->{_chunk} || []};
}

sub _has_section {
    my($self, $sect) = @_;
    return $self->{_sections}->{$sect} ? 1 : 0;
}

1;

=head1 NAME

Getopt::Compact::PodMunger - script POD munging

=head1 SYNOPSIS

    my $p = new Getopt::Compact::PodMunger();
    $p->parse_from_file('foo.pl');
    $p->insert('USAGE', $usage_string);
    print $p->as_string;

=head1 DESCRIPTION

Getopt::Compact::PodMunger is used internally by Getopt::Compact to
parse POD in command line scripts.  The parsed POD is then munged via
the C<insert> method.  This is only required when the --man option is
used.

=head1 METHODS

=over 4

=item new(), command(), verbatim(), textblock(), begin_input(), end_input()

These methods are inherited from L<Pod::Parser>.  Refer to
L<Pod::Parser> for more information.

=item $p->insert($section, $content, $is_verbatim)

Modifies the parsed pod by inserting a new section as a C<head1> with
$content under it.  Correct ordering of sections (eg. C<NAME>,
C<SYNOPSIS>, C<DESCRIPTION>) is attempted.  If $is_verbatim is true,
the content will be indented by four spaces.

=item $pod = $p->as_string()

Returns the parsed POD as a string.

=item $p->print_manpage()

Prints the parsed POD as a manpage, using Pod::Simple::Text::Termcap.

=back

=head1 VERSION

$Revision: 15 $

=head1 AUTHOR

Andrew Stewart Williams

=head1 SEE ALSO

L<Getopt::Compact>, L<Pod::Parser>

=cut
