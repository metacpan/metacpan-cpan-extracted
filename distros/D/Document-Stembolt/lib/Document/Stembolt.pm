package Document::Stembolt;

use warnings;
use strict;

=head1 NAME

Document::Stembolt - Read & edit a document with YAML-ish meta-data

=head1 VERSION

Version 0.012

=cut

our $VERSION = '0.012';

=head1 SYNOPSIS

    my $content;
    $content = Document::Stembolt::Content->read_string(<<_END_);
    # vim: #
    ---
    hello: world
    ---
    This is the body
    _END_

    $content->preamble   "# vim: #\n"
    $content->header     { hello => world }
    $content->body       "This is the body\n"

=head1 DESCRIPTION

This distribution is meant to take the headache out of reading, writing, and editing
"interesting" documents. That is, documents with both content and meta-data (via YAML::Tiny)

More documentation coming soon, check out the code and tests for usage and examples. This is pretty beta, so
the interface might change.

=cut

use Moose;

use Document::Stembolt::Content;

use MooseX::Types::Path::Class qw/Dir File/;

has content => qw/is ro lazy_build 1 isa Document::Stembolt::Content/, handles => [qw/preamble header body/];
sub _build_content {
    my $self = shift;
    return Document::Stembolt::Content->new;
}

has file => qw/is ro coerce 1 required 1/, isa => File;

sub BUILD {
    my $self = shift;

    $self->read if -e $self->file;
}

sub read {
    my $self = shift;

    $self->content->read($self->file);
}
sub write {
    my $self = shift;

    $self->content->write($self->file);
}

sub _editor {
	return [ split m/\s+/, ($ENV{VISUAL} || $ENV{EDITOR}) ];
}

sub _edit_file {
	my $file = shift;
	die "Don't know what editor" unless my $editor = _editor;
	my $rc = system @$editor, $file;
	unless ($rc == 0) {
		my ($exit_value, $signal, $core_dump);
		$exit_value = $? >> 8;
		$signal = $? & 127;
		$core_dump = $? & 128;
		die "Error during edit (@$editor): exit value ($exit_value), signal ($signal), core_dump($core_dump): $!";
	}
}

sub edit {
    my $self = shift;

    $self->write;

    _edit_file $self->file;

    $self->read;
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-document-stembolt at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Document-Stembolt>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Document::Stembolt


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Document-Stembolt>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Document-Stembolt>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Document-Stembolt>

=item * Search CPAN

L<http://search.cpan.org/dist/Document-Stembolt>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Document::Stembolt
