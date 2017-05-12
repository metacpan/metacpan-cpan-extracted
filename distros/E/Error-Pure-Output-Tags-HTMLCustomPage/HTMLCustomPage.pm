package Error::Pure::Output::Tags::HTMLCustomPage;

# Pragmas.
use base qw(Exporter);
use strict;
use warnings;

# Modules.
use HTTP::Headers::Fast;
use Readonly;

# Constants.
Readonly::Array our @EXPORT_OK => qw(err_pretty);
Readonly::Scalar my $EMPTY_STR => q{};
Readonly::Scalar my $SPACE => q{ };

# Version.
our $VERSION = 0.03;

# Pretty print.
sub err_pretty {
	my ($tags_obj, $encoding, $content_type, $xml_version,
		$tags_structure_ar) = @_;

	# Reset.
	$tags_obj->reset;

	my $header = HTTP::Headers::Fast->new;
	$header->header(
		'Cache-Control' => 'no-cache',
		'Content-Type' => $content_type,
	);
	$header->date(time);
	$tags_obj->put(['r', $header->as_string."\n"]);

	# Debug from Tags object.
	my $debug = $tags_obj->{'set_indent'};

	# XML tag.
	$tags_obj->put(
		['i', 'xml', 'version="'.$xml_version.'" encoding="'.$encoding.
			'" standalone="no"'],
	);
	if ($debug) {
		$tags_obj->put(['r', "\n"]);
	}

	# DTD.
	my @dtd = (
		'<!DOCTYPE html',
		'PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"',
		'"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
	);
	my ($separator, $linebreak) = ($SPACE, $EMPTY_STR);
	if ($debug) {
		$separator = "\n".$tags_obj->{'next_indent'};
		$linebreak = "\n";
	}
	$tags_obj->put(['r', (join $separator, @dtd).$linebreak]);

	# Main page.
	my @tmp = @{$tags_structure_ar};
	$tags_obj->put(@tmp);

	# Ok.
	return 1;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Error::Pure::Output::Tags::HTMLCustomPage - Error::Pure HTML output helper.

=head1 SYNOPSIS

 use Error::Pure::Output::Tags::HTMLCustomPage qw(err_pretty);
 err_pretty($tags_obj, $encoding, $content_type, $xml_version, $tags_structure_ar);

=head1 SUBROUTINES

=over 8

=item C<err_pretty($tags_obj, $encoding, $content_type, $xml_version, $tags_structure_ar)>

 Helper routine use Tags $tags_obj object and print output to stdout.

=back

=head1 EXAMPLE1

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Tags::HTMLCustomPage qw(err_pretty);
 use Tags::Output::Indent;

 # Tags object.
 my $tags = Tags::Output::Indent->new(
         'output_handler' => \*STDOUT,
         'auto_flush' => 1,
 );

 # Error.
 err_pretty($tags, 'utf-8', 'application/xhtml+xml', '1.0', [
         ['b', 'html'],
         ['b', 'head'],
         ['b', 'title'],
         ['d', 'Foo'],
         ['e', 'title'],
         ['e', 'head'],
         ['b', 'div'],
         ['d', 'Bar'],
         ['e', 'div'],
         ['e', 'html'],
 ]);

 # Output like:
 # Cache-Control: no-cache
 # Date: Wed, 03 Sep 2014 11:48:37 GMT
 # Content-Type: application/xhtml+xml
 #
 # <?xml version="1.0" encoding="utf-8" standalone="no"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html>
 #   <head>
 #     <title>
 #       Foo
 #     </title>
 #   </head>
 #   <div>
 #     Bar
 #   </div>
 # </html>

=head1 EXAMPLE2

 # Pragmas.
 use strict;
 use warnings;

 # Modules.
 use Error::Pure::Output::Tags::HTMLCustomPage qw(err_pretty);
 use Tags::Output::Raw;

 # Tags object.
 my $tags = Tags::Output::Raw->new(
         'output_handler' => \*STDOUT,
         'auto_flush' => 1,
 );

 # Error.
 err_pretty($tags, 'utf-8', 'application/xhtml+xml', '1.0', [
         ['b', 'html'],
         ['b', 'head'],
         ['b', 'title'],
         ['d', 'Foo'],
         ['e', 'title'],
         ['e', 'head'],
         ['b', 'div'],
         ['d', 'Bar'],
         ['e', 'div'],
         ['e', 'html'],
 ]);

 # Output like:
 # Cache-Control: no-cache
 # Date: Wed, 03 Sep 2014 11:54:37 GMT
 # Content-Type: application/xhtml+xml
 #
 # <?xml version="1.0" encoding="utf-8" standalone="no"?><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html><head><title>Foo</title></head><div>Bar</div></html>

=head1 DEPENDENCIES

L<HTTP::Headers::Fast>,
L<Readonly>.

=head1 SEE ALSO

=over

=item L<Task::Error::Pure>

Install the Error::Pure modules.

=back

=head1 REPOSITORY

L<https://github.com/tupinek/Error-Pure-Output-Tags-HTMLCustomPage>

=head1 AUTHOR

Michal Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

 © 2014-2015 Michal Špaček
 BSD 2-Clause License

=head1 VERSION

0.03

=cut
